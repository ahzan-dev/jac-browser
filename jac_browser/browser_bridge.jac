"""Playwright bridge for jac-browser - pure Jac implementation.

All Playwright operations run on a single dedicated background thread
to avoid conflicts with jac's asyncio event loop. State is stored in
a glob dict so it persists across walker invocations.
"""

import re;
import json;
import time;
import from os {listdir, remove, rename, makedirs}
import from os.path {exists, join, isfile, basename, expanduser}
import from queue {Queue}
import from threading {Thread}
import from hashlib {sha256}
import from base64 {b64encode as _b64encode, b64decode as _b64decode}
import from playwright.sync_api {sync_playwright}


# ---------------------------------------------------------------------------
# Shared mutable state (glob reassignment doesn't work from functions,
# so we use dict mutation instead)
# ---------------------------------------------------------------------------

glob _state: dict = {
    "pw": None,
    "browser": None,
    "context": None,
    "pages": {},
    "cmd_queue": None,
    "thread": None,
    "initialized": False,
    "console_messages": [],
    "page_errors": [],
    "request_log": [],
    "routes": {},
    "listeners_installed": {}
};

glob _ref_state: dict = {"counter": 0};

glob INTERACTIVE_ROLES: frozenset = frozenset([
    "link", "button", "textbox", "checkbox", "radio",
    "combobox", "menuitem", "option", "searchbox",
    "slider", "spinbutton", "switch", "tab", "treeitem"
]);

glob LINE_RE: object = re.compile(
    r"^(?P<indent>\s*)-\s+"
    + r"(?P<role>\w+)"
    + r'(?:\s+"(?P<name_dq>[^"]*)")?'
    + r"(?:\s+'(?P<name_sq>[^']*)')?"
);


# ---------------------------------------------------------------------------
# Playwright thread -- worker loop
# ---------------------------------------------------------------------------

def _worker_loop() -> None {
    while True {
        item = _state["cmd_queue"].get();
        if item is None {
            break;
        }
        fn = item[0];
        args = item[1];
        result_q = item[2];
        try {
            result = fn(args);
            result_q.put(("ok", result));
        } except Exception as e {
            result_q.put(("error", e));
        }
    }
}

def _ensure_thread() -> None {
    if not _state["initialized"] {
        _state["cmd_queue"] = Queue();
        t = Thread(target=_worker_loop, daemon=True);
        t.start();
        _state["thread"] = t;
        _state["initialized"] = True;
    }
}

"""Submit fn(args) to the Playwright thread and block for the result."""
def _exec(fn: object, args: list) -> object {
    _ensure_thread();
    result_q = Queue();
    _state["cmd_queue"].put((fn, args, result_q));
    pair = result_q.get();
    if pair[0] == "error" {
        raise pair[1];
    }
    return pair[1];
}


# ---------------------------------------------------------------------------
# Thread-safe operation functions (each takes a single list of args)
# ---------------------------------------------------------------------------

# -- Lifecycle ---------------------------------------------------------------

def _do_launch(args: list) -> object {
    headless = args[0];
    pw = sync_playwright().start();
    browser = pw.chromium.launch(headless=headless);
    context = browser.new_context();
    _state["pw"] = pw;
    _state["browser"] = browser;
    _state["context"] = context;
    _state["console_messages"] = [];
    _state["page_errors"] = [];
    _state["request_log"] = [];
    _state["routes"] = {};
    _state["listeners_installed"] = {};
    return None;
}

def _do_new_page(args: list) -> object {
    page = _state["context"].new_page();
    return page;
}

def _do_close(args: list) -> object {
    if _state["context"] {
        _state["context"].close();
        _state["context"] = None;
    }
    if _state["browser"] {
        _state["browser"].close();
        _state["browser"] = None;
    }
    if _state["pw"] {
        _state["pw"].stop();
        _state["pw"] = None;
    }
    _state["pages"] = {};
    _state["console_messages"] = [];
    _state["page_errors"] = [];
    _state["request_log"] = [];
    _state["routes"] = {};
    _state["listeners_installed"] = {};
    return None;
}

def _do_close_page(args: list) -> object {
    page = args[0];
    page.close();
    return None;
}

def _do_list_pages(args: list) -> list {
    pages_dict = _state["pages"];
    result: list = [];
    for page_id in pages_dict {
        page = pages_dict[page_id];
        try {
            result.append({
                "page_id": page_id,
                "url": page.url,
                "title": page.title()
            });
        } except Exception {
            result = result;
        }
    }
    return result;
}

# -- Navigation --------------------------------------------------------------

def _do_goto(args: list) -> object {
    page = args[0];
    url = args[1];
    wait_until = args[2];
    page.goto(url, wait_until=wait_until);
    return None;
}

def _do_go_back(args: list) -> object {
    page = args[0];
    page.go_back();
    return None;
}

def _do_go_forward(args: list) -> object {
    page = args[0];
    page.go_forward();
    return None;
}

def _do_reload(args: list) -> object {
    page = args[0];
    page.reload();
    return None;
}

# -- Page info ---------------------------------------------------------------

def _do_get_url(args: list) -> str {
    page = args[0];
    return page.url;
}

def _do_get_title(args: list) -> str {
    page = args[0];
    return page.title();
}

# -- Snapshot ----------------------------------------------------------------

def _do_snapshot(args: list) -> dict {
    page = args[0];
    selector = args[1];
    if selector == "page" {
        locator = page.locator("body");
    } else {
        locator = page.locator(selector);
    }
    try {
        raw_tree = locator.aria_snapshot();
    } except Exception as exc {
        return {"tree": "[snapshot error: " + str(exc) + "]", "refs": {}};
    }
    return _process_aria_tree(raw_tree);
}

# -- Locator -----------------------------------------------------------------

def _do_get_locator(args: list) -> object {
    page = args[0];
    selector_or_ref = args[1];
    ref_map = args[2];
    ref_id = _parse_ref(selector_or_ref);
    if ref_id and ref_id in ref_map {
        data = ref_map[ref_id];
        role = data["role"];
        name = data.get("name", "");
        loc = page.get_by_role(role, name=name, exact=True);
        nth = data.get("nth");
        if nth is not None {
            loc = loc.nth(nth);
        }
        return loc;
    }
    return page.locator(selector_or_ref);
}

# -- Interaction -------------------------------------------------------------

def _do_click(args: list) -> object {
    locator = args[0];
    locator.click();
    return None;
}

def _do_dblclick(args: list) -> object {
    locator = args[0];
    locator.dblclick();
    return None;
}

def _do_fill(args: list) -> object {
    locator = args[0];
    value = args[1];
    locator.fill(value);
    return None;
}

def _do_type(args: list) -> object {
    locator = args[0];
    text = args[1];
    delay = args[2];
    locator.press_sequentially(text, delay=delay);
    return None;
}

def _do_hover(args: list) -> object {
    locator = args[0];
    locator.hover();
    return None;
}

def _do_press(args: list) -> object {
    locator = args[0];
    key = args[1];
    locator.press(key);
    return None;
}

def _do_check(args: list) -> object {
    locator = args[0];
    locator.check();
    return None;
}

def _do_uncheck(args: list) -> object {
    locator = args[0];
    locator.uncheck();
    return None;
}

def _do_select_option(args: list) -> object {
    locator = args[0];
    value = args[1];
    locator.select_option(value);
    return None;
}

def _do_clear(args: list) -> object {
    locator = args[0];
    locator.fill("");
    return None;
}

def _do_focus(args: list) -> object {
    locator = args[0];
    locator.focus();
    return None;
}

def _do_set_input_files(args: list) -> object {
    locator = args[0];
    files = args[1];
    locator.set_input_files(files);
    return None;
}

def _do_drag(args: list) -> object {
    page = args[0];
    source = args[1];
    target = args[2];
    page.drag_and_drop(source, target);
    return None;
}

def _do_scroll_into_view(args: list) -> object {
    locator = args[0];
    locator.scroll_into_view_if_needed();
    return None;
}

def _do_dispatch_event(args: list) -> object {
    locator = args[0];
    event = args[1];
    event_init = args[2];
    if event_init {
        locator.dispatch_event(event, event_init);
    } else {
        locator.dispatch_event(event);
    }
    return None;
}

# -- Screenshot --------------------------------------------------------------

def _do_screenshot(args: list) -> object {
    page = args[0];
    full_page = args[1];
    selector = args[2];
    if selector {
        target = page.locator(selector);
        return target.screenshot();
    }
    return page.screenshot(full_page=full_page, type="png");
}

# -- Scroll ------------------------------------------------------------------

def _do_mouse_wheel(args: list) -> object {
    page = args[0];
    delta_x = args[1];
    delta_y = args[2];
    page.mouse.wheel(delta_x, delta_y);
    return None;
}

def _do_scroll_element(args: list) -> object {
    locator = args[0];
    delta_x = args[1];
    delta_y = args[2];
    locator.scroll_into_view_if_needed();
    locator.evaluate(
        "el => el.scrollBy(" + str(delta_x) + ", " + str(delta_y) + ")"
    );
    return None;
}

# -- Text content ------------------------------------------------------------

def _do_text_content(args: list) -> str {
    locator = args[0];
    result = locator.text_content();
    if result is None {
        return "";
    }
    return result;
}

def _do_inner_text(args: list) -> str {
    locator = args[0];
    return locator.inner_text();
}

def _do_inner_html(args: list) -> str {
    locator = args[0];
    return locator.inner_html();
}

def _do_input_value(args: list) -> str {
    locator = args[0];
    return locator.input_value();
}

def _do_bounding_box(args: list) -> object {
    locator = args[0];
    return locator.bounding_box();
}

def _do_get_content(args: list) -> str {
    page = args[0];
    selector = args[1];
    if selector {
        return page.locator(selector).inner_html();
    }
    return page.content();
}

# -- Element queries ---------------------------------------------------------

def _do_get_attribute(args: list) -> object {
    locator = args[0];
    attribute = args[1];
    return locator.get_attribute(attribute);
}

def _do_is_visible(args: list) -> bool {
    locator = args[0];
    return locator.is_visible();
}

def _do_is_enabled(args: list) -> bool {
    locator = args[0];
    return locator.is_enabled();
}

def _do_is_checked(args: list) -> bool {
    locator = args[0];
    return locator.is_checked();
}

def _do_element_count(args: list) -> int {
    locator = args[0];
    return locator.count();
}

# -- JavaScript execution ---------------------------------------------------

def _do_evaluate(args: list) -> object {
    page = args[0];
    script = args[1];
    return page.evaluate(script);
}

# -- Wait commands -----------------------------------------------------------

def _do_wait_for(args: list) -> object {
    locator = args[0];
    state = args[1];
    timeout = args[2];
    locator.wait_for(state=state, timeout=timeout);
    return None;
}

def _do_wait_for_url(args: list) -> object {
    page = args[0];
    url = args[1];
    timeout = args[2];
    page.wait_for_url(url, timeout=timeout);
    return None;
}

def _do_wait_for_load_state(args: list) -> object {
    page = args[0];
    state = args[1];
    timeout = args[2];
    page.wait_for_load_state(state, timeout=timeout);
    return None;
}

def _do_wait_for_function(args: list) -> object {
    page = args[0];
    expression = args[1];
    timeout = args[2];
    page.wait_for_function(expression, timeout=timeout);
    return None;
}

# -- Cookies -----------------------------------------------------------------

def _do_cookies_get(args: list) -> list {
    context = _state["context"];
    url = args[0];
    if url {
        return context.cookies(url);
    }
    return context.cookies();
}

def _do_cookies_set(args: list) -> object {
    context = _state["context"];
    cookies = args[0];
    context.add_cookies(cookies);
    return None;
}

def _do_cookies_clear(args: list) -> object {
    context = _state["context"];
    context.clear_cookies();
    return None;
}

# -- Storage -----------------------------------------------------------------

def _do_storage_get(args: list) -> object {
    page = args[0];
    key = args[1];
    storage_type = args[2];
    if key {
        return page.evaluate(storage_type + "Storage.getItem('" + key + "')");
    }
    script = ("(function() { var s = " + storage_type + "Storage; var r = {};"
              + " for (var i = 0; i < s.length; i++) {"
              + " var k = s.key(i); r[k] = s.getItem(k); } return r; })()");
    return page.evaluate(script);
}

def _do_storage_set(args: list) -> object {
    page = args[0];
    key = args[1];
    value = args[2];
    storage_type = args[3];
    page.evaluate(storage_type + "Storage.setItem('" + key + "', '" + value + "')");
    return None;
}

def _do_storage_clear(args: list) -> object {
    page = args[0];
    storage_type = args[1];
    page.evaluate(storage_type + "Storage.clear()");
    return None;
}

# -- Dialog handling ---------------------------------------------------------

def _do_set_dialog_handler(args: list) -> object {
    page = args[0];
    response = args[1];
    prompt_text = args[2];

    def _handle_dialog(dialog: object) -> None {
        if response == "accept" {
            if prompt_text {
                dialog.accept(prompt_text);
            } else {
                dialog.accept();
            }
        } else {
            dialog.dismiss();
        }
    }

    page.on("dialog", _handle_dialog);
    _state["dialog_handler"] = _handle_dialog;
    return None;
}

# -- Console / Error listeners -----------------------------------------------

def _do_install_console_listener(args: list) -> object {
    page = args[0];
    page_id = args[1];

    def _on_console(msg: object) -> None {
        _state["console_messages"].append({
            "type": msg.type,
            "text": msg.text
        });
    }

    page.on("console", _on_console);
    _state["listeners_installed"].setdefault(page_id, []);
    _state["listeners_installed"][page_id].append("console");
    return None;
}

def _do_install_error_listener(args: list) -> object {
    page = args[0];
    page_id = args[1];

    def _on_error(err: object) -> None {
        _state["page_errors"].append({
            "message": str(err)
        });
    }

    page.on("pageerror", _on_error);
    _state["listeners_installed"].setdefault(page_id, []);
    _state["listeners_installed"][page_id].append("pageerror");
    return None;
}

# -- Network interception ---------------------------------------------------

def _do_install_request_listener(args: list) -> object {
    page = args[0];
    page_id = args[1];

    def _on_request(request: object) -> None {
        _state["request_log"].append({
            "url": request.url,
            "method": request.method,
            "resource_type": request.resource_type
        });
    }

    page.on("request", _on_request);
    _state["listeners_installed"].setdefault(page_id, []);
    _state["listeners_installed"][page_id].append("request");
    return None;
}

def _do_add_route(args: list) -> object {
    page = args[0];
    url_pattern = args[1];
    should_abort = args[2];
    status = args[3];
    body = args[4];
    content_type = args[5];

    if should_abort {
        def _abort_handler(route: object) -> None {
            route.abort();
        }
        page.route(url_pattern, _abort_handler);
    } else {
        def _fulfill_handler(route: object) -> None {
            route.fulfill(status=status, body=body, content_type=content_type);
        }
        page.route(url_pattern, _fulfill_handler);
    }
    _state["routes"][url_pattern] = True;
    return None;
}

def _do_remove_route(args: list) -> object {
    page = args[0];
    url_pattern = args[1];
    if url_pattern {
        page.unroute(url_pattern);
        _state["routes"].pop(url_pattern, None);
    } else {
        for pattern in list(_state["routes"].keys()) {
            page.unroute(pattern);
        }
        _state["routes"] = {};
    }
    return None;
}

# -- Download ----------------------------------------------------------------

def _do_download(args: list) -> dict {
    page = args[0];
    locator = args[1];
    save_path = args[2];
    with page.expect_download() as download_info {
        locator.click();
    }
    download = download_info.value;
    suggested = download.suggested_filename;
    if save_path {
        download.save_as(save_path);
    }
    return {"suggested_filename": suggested, "path": save_path};
}

# -- Mouse control -----------------------------------------------------------

def _do_mouse_move(args: list) -> object {
    page = args[0];
    x = args[1];
    y = args[2];
    page.mouse.move(x, y);
    return None;
}

def _do_mouse_down(args: list) -> object {
    page = args[0];
    button = args[1];
    page.mouse.down(button=button);
    return None;
}

def _do_mouse_up(args: list) -> object {
    page = args[0];
    button = args[1];
    page.mouse.up(button=button);
    return None;
}

# -- Keyboard control --------------------------------------------------------

def _do_keyboard_type(args: list) -> object {
    page = args[0];
    text = args[1];
    delay = args[2];
    page.keyboard.type(text, delay=delay);
    return None;
}

def _do_keyboard_press(args: list) -> object {
    page = args[0];
    keys = args[1];
    page.keyboard.press(keys);
    return None;
}

def _do_keyboard_insert_text(args: list) -> object {
    page = args[0];
    text = args[1];
    page.keyboard.insert_text(text);
    return None;
}

def _do_key_down(args: list) -> object {
    page = args[0];
    key = args[1];
    page.keyboard.down(key);
    return None;
}

def _do_key_up(args: list) -> object {
    page = args[0];
    key = args[1];
    page.keyboard.up(key);
    return None;
}

# -- Page configuration ------------------------------------------------------

def _do_set_viewport(args: list) -> object {
    page = args[0];
    width = args[1];
    height = args[2];
    page.set_viewport_size({"width": width, "height": height});
    return None;
}

def _do_set_content(args: list) -> object {
    page = args[0];
    html = args[1];
    page.set_content(html);
    return None;
}

def _do_emulate_media(args: list) -> object {
    page = args[0];
    media = args[1];
    color_scheme = args[2];
    reduced_motion = args[3];
    kwargs: dict = {};
    if media {
        kwargs["media"] = media;
    }
    if color_scheme {
        kwargs["color_scheme"] = color_scheme;
    }
    if reduced_motion {
        kwargs["reduced_motion"] = reduced_motion;
    }
    page.emulate_media(**kwargs);
    return None;
}

def _do_set_offline(args: list) -> object {
    context = _state["context"];
    is_offline = args[0];
    context.set_offline(is_offline);
    return None;
}

# -- State persistence -------------------------------------------------------

def _do_state_save(args: list) -> object {
    context = _state["context"];
    path = args[0];
    context.storage_state(path=path);
    return None;
}

def _do_state_load(args: list) -> object {
    path = args[0];
    if _state["context"] {
        _state["context"].close();
    }
    context = _state["browser"].new_context(storage_state=path);
    _state["context"] = context;
    _state["pages"] = {};
    _state["listeners_installed"] = {};
    return None;
}

# -- Frames ------------------------------------------------------------------

def _do_frame_locator(args: list) -> object {
    page = args[0];
    selector = args[1];
    return page.frame_locator(selector);
}

def _do_frame_evaluate(args: list) -> object {
    page = args[0];
    frame_selector = args[1];
    script = args[2];
    fl = page.frame_locator(frame_selector);
    return fl.locator("body").evaluate(script);
}

def _do_main_frame_url(args: list) -> str {
    page = args[0];
    return page.main_frame.url;
}

# -- Semantic locators -------------------------------------------------------

def _do_get_by_text(args: list) -> object {
    page = args[0];
    text = args[1];
    exact = args[2];
    return page.get_by_text(text, exact=exact);
}

def _do_get_by_role(args: list) -> object {
    page = args[0];
    role = args[1];
    name = args[2];
    return page.get_by_role(role, name=name);
}

def _do_get_by_label(args: list) -> object {
    page = args[0];
    text = args[1];
    exact = args[2];
    return page.get_by_label(text, exact=exact);
}

def _do_get_by_placeholder(args: list) -> object {
    page = args[0];
    text = args[1];
    exact = args[2];
    return page.get_by_placeholder(text, exact=exact);
}

def _do_get_by_alt_text(args: list) -> object {
    page = args[0];
    text = args[1];
    exact = args[2];
    return page.get_by_alt_text(text, exact=exact);
}

def _do_get_by_title(args: list) -> object {
    page = args[0];
    text = args[1];
    exact = args[2];
    return page.get_by_title(text, exact=exact);
}

def _do_get_by_test_id(args: list) -> object {
    page = args[0];
    test_id = args[1];
    return page.get_by_test_id(test_id);
}

# -- PDF export --------------------------------------------------------------

def _do_pdf(args: list) -> bytes {
    page = args[0];
    kwargs: dict = {};
    if args[1] {
        kwargs["format"] = args[1];
    }
    if args[2] {
        kwargs["landscape"] = args[2];
    }
    if args[3] {
        kwargs["print_background"] = args[3];
    }
    return page.pdf(**kwargs);
}

# -- Emulation ---------------------------------------------------------------

def _do_set_geolocation(args: list) -> object {
    context = _state["context"];
    lat = args[0];
    lon = args[1];
    accuracy = args[2];
    context.set_geolocation({"latitude": lat, "longitude": lon, "accuracy": accuracy});
    return None;
}

def _do_grant_permissions(args: list) -> object {
    context = _state["context"];
    permissions = args[0];
    context.grant_permissions(permissions);
    return None;
}

def _do_clear_permissions(args: list) -> object {
    context = _state["context"];
    context.clear_permissions();
    return None;
}

def _do_set_extra_http_headers(args: list) -> object {
    context = _state["context"];
    headers = args[0];
    context.set_extra_http_headers(headers);
    return None;
}

# -- Script injection --------------------------------------------------------

def _do_add_init_script(args: list) -> object {
    page = args[0];
    script = args[1];
    page.add_init_script(script);
    return None;
}

def _do_add_script_tag(args: list) -> object {
    page = args[0];
    kwargs: dict = {};
    if args[1] {
        kwargs["url"] = args[1];
    }
    if args[2] {
        kwargs["content"] = args[2];
    }
    return page.add_script_tag(**kwargs);
}

def _do_add_style_tag(args: list) -> object {
    page = args[0];
    kwargs: dict = {};
    if args[1] {
        kwargs["url"] = args[1];
    }
    if args[2] {
        kwargs["content"] = args[2];
    }
    return page.add_style_tag(**kwargs);
}

# -- Advanced element ops ----------------------------------------------------

def _do_highlight(args: list) -> object {
    locator = args[0];
    locator.highlight();
    return None;
}

def _do_set_checked(args: list) -> object {
    locator = args[0];
    checked = args[1];
    locator.set_checked(checked);
    return None;
}

def _do_select_all(args: list) -> object {
    page = args[0];
    page.keyboard.press("Control+a");
    return None;
}

def _do_multi_select(args: list) -> object {
    locator = args[0];
    values = args[1];
    locator.select_option(values);
    return None;
}

def _do_locator_nth(args: list) -> object {
    locator = args[0];
    index = args[1];
    return locator.nth(index);
}

# -- Clipboard ---------------------------------------------------------------

def _do_clipboard_read(args: list) -> str {
    page = args[0];
    return page.evaluate("navigator.clipboard.readText()");
}

def _do_clipboard_write(args: list) -> object {
    page = args[0];
    text = args[1];
    page.evaluate("navigator.clipboard.writeText('" + text.replace("'", "\\'") + "')");
    return None;
}

# -- Mouse extras ------------------------------------------------------------

def _do_mouse_click(args: list) -> object {
    page = args[0];
    x = args[1];
    y = args[2];
    button = args[3];
    click_count = args[4];
    page.mouse.click(x, y, button=button, click_count=click_count);
    return None;
}

def _do_mouse_dblclick(args: list) -> object {
    page = args[0];
    x = args[1];
    y = args[2];
    page.mouse.dblclick(x, y);
    return None;
}

# -- Touch -------------------------------------------------------------------

def _do_tap(args: list) -> object {
    locator = args[0];
    locator.tap();
    return None;
}

# -- Browser window ----------------------------------------------------------

def _do_bring_to_front(args: list) -> object {
    page = args[0];
    page.bring_to_front();
    return None;
}

# -- Tracing -----------------------------------------------------------------

def _do_tracing_start(args: list) -> object {
    context = _state["context"];
    kwargs: dict = {"screenshots": True, "snapshots": True};
    if args[0] {
        kwargs["name"] = args[0];
    }
    context.tracing.start(**kwargs);
    return None;
}

def _do_tracing_stop(args: list) -> object {
    context = _state["context"];
    path = args[0];
    context.tracing.stop(path=path);
    return None;
}

# -- HAR recording -----------------------------------------------------------

def _do_har_start(args: list) -> object {
    page = args[0];
    path = args[1];
    page.route_from_har(path, update=True);
    return None;
}

# -- Video recording ---------------------------------------------------------

def _do_video_path(args: list) -> str {
    page = args[0];
    if page.video {
        return page.video.path();
    }
    return "";
}

# -- Expose function ---------------------------------------------------------

def _do_expose_function(args: list) -> object {
    page = args[0];
    name = args[1];
    fn = args[2];
    page.expose_function(name, fn);
    return None;
}

# -- Evaluate handle ---------------------------------------------------------

def _do_evaluate_handle(args: list) -> object {
    page = args[0];
    script = args[1];
    handle = page.evaluate_handle(script);
    result = handle.json_value();
    handle.dispose();
    return result;
}

# -- Advanced page -----------------------------------------------------------

def _do_bring_to_front_page(args: list) -> object {
    page = args[0];
    page.bring_to_front();
    return None;
}

def _do_set_http_credentials(args: list) -> object {
    context = _state["context"];
    username = args[0];
    password = args[1];
    if username {
        context.set_extra_http_headers({
            "Authorization": "Basic " + __import__("base64").b64encode(
                (username + ":" + password).encode()
            ).decode()
        });
    }
    return None;
}

# -- State management extras -------------------------------------------------

def _do_state_list(args: list) -> list {
    directory = args[0];
    files: list = [];
    if exists(directory) {
        for f in listdir(directory) {
            if f.endswith(".json") {
                files.append(f);
            }
        }
    }
    return files;
}

def _do_state_delete(args: list) -> object {
    path = args[0];
    if exists(path) {
        remove(path);
    }
    return None;
}

def _do_state_rename(args: list) -> object {
    old_path = args[0];
    new_path = args[1];
    if exists(old_path) {
        rename(old_path, new_path);
    }
    return None;
}

def _do_state_show(args: list) -> object {
    path = args[0];
    if exists(path) {
        with open(path, "r") as f {
            return json.load(f);
        }
    }
    return None;
}

# -- Visual diff -------------------------------------------------------------

def _do_diff_screenshots(args: list) -> dict {
    img1 = args[0];
    img2 = args[1];
    if len(img1) != len(img2) {
        return {"match": False, "reason": "size_mismatch", "size1": len(img1), "size2": len(img2)};
    }
    diff_bytes = 0;
    total = len(img1);
    for i in range(total) {
        if img1[i] != img2[i] {
            diff_bytes = diff_bytes + 1;
        }
    }
    pct = (diff_bytes * 100.0) / max(total, 1);
    return {"match": pct < 1.0, "diff_percent": pct, "diff_bytes": diff_bytes};
}

# -- Confirmation dialog (different from generic dialog) ---------------------

def _do_set_confirm_handler(args: list) -> object {
    page = args[0];
    accept = args[1];

    def _handle(dialog: object) -> None {
        if dialog.type == "confirm" {
            if accept {
                dialog.accept();
            } else {
                dialog.dismiss();
            }
        } else {
            dialog.accept();
        }
    }

    page.on("dialog", _handle);
    return None;
}

# -- Locator operations with text content ------------------------------------

def _do_locator_text_content(args: list) -> list {
    locator = args[0];
    result: list = [];
    count = locator.count();
    for i in range(count) {
        result.append(locator.nth(i).text_content());
    }
    return result;
}

def _do_locator_all_inner_texts(args: list) -> list {
    locator = args[0];
    return locator.all_inner_texts();
}

# -- Computed styles ---------------------------------------------------------

def _do_get_computed_styles(args: list) -> dict {
    locator = args[0];
    properties = args[1];
    if properties {
        script = "(el) => { var s = window.getComputedStyle(el); var r = {}; ";
        for p in properties {
            script = script + "r['" + p + "'] = s.getPropertyValue('" + p + "'); ";
        }
        script = script + "return r; }";
    } else {
        script = "(el) => { var s = window.getComputedStyle(el); var r = {}; for (var i = 0; i < s.length; i++) { r[s[i]] = s.getPropertyValue(s[i]); } return r; }";
    }
    return locator.evaluate(script);
}

# -- State clean (delete old files) -----------------------------------------

def _do_state_clean(args: list) -> int {
    directory = args[0];
    max_age_days = args[1];
    now = time.time();
    cutoff = now - (max_age_days * 86400);
    deleted = 0;
    if exists(directory) {
        for f in listdir(directory) {
            fpath = join(directory, f);
            if f.endswith(".json") and isfile(fpath) {
                import from os {stat}
                st = stat(fpath);
                if st.st_mtime < cutoff {
                    remove(fpath);
                    deleted = deleted + 1;
                }
            }
        }
    }
    return deleted;
}

# -- Wait for download -------------------------------------------------------

def _do_wait_for_download(args: list) -> dict {
    page = args[0];
    action_fn = args[1];
    save_path = args[2];
    timeout = args[3];
    with page.expect_download(timeout=timeout) as download_info {
        if action_fn {
            action_fn();
        }
    }
    dl = download_info.value;
    suggested = dl.suggested_filename;
    if save_path {
        dl.save_as(save_path);
    }
    return {"suggested_filename": suggested, "path": save_path};
}

# -- Swipe (touch gesture) --------------------------------------------------

def _do_swipe(args: list) -> object {
    page = args[0];
    start_x = args[1];
    start_y = args[2];
    end_x = args[3];
    end_y = args[4];
    steps = args[5];
    # Simulate swipe via mouse drag (works without has_touch context)
    page.mouse.move(start_x, start_y);
    page.mouse.down();
    page.mouse.move(end_x, end_y, steps=steps);
    page.mouse.up();
    return None;
}

# -- Recording restart -------------------------------------------------------

def _do_recording_restart(args: list) -> object {
    # In Playwright, there's no direct restart; we note it as a marker
    return None;
}

# -- Auth vault --------------------------------------------------------------

glob AUTH_DIR: str = join(expanduser("~"), ".jac-browser", "auth");

def _ensure_auth_dir() -> None {
    if not exists(AUTH_DIR) {
        makedirs(AUTH_DIR, mode=0o700, exist_ok=True);
    }
}

def _auth_path(name: str) -> str {
    return join(AUTH_DIR, name + ".json");
}

def _do_auth_save(args: list) -> dict {
    name = args[0];
    url = args[1];
    username = args[2];
    password = args[3];
    username_sel = args[4];
    password_sel = args[5];
    submit_sel = args[6];
    _ensure_auth_dir();

    profile = {
        "name": name,
        "url": url,
        "username": username,
        "password": password,
        "username_selector": username_sel,
        "password_selector": password_sel,
        "submit_selector": submit_sel,
        "created_at": time.strftime("%Y-%m-%dT%H:%M:%S")
    };

    path = _auth_path(name);
    with open(path, "w") as f {
        json.dump(profile, f);
    }
    return {"name": name, "url": url};
}

def _do_auth_list(args: list) -> list {
    _ensure_auth_dir();
    profiles: list = [];
    for f in listdir(AUTH_DIR) {
        if f.endswith(".json") {
            path = join(AUTH_DIR, f);
            try {
                with open(path, "r") as fh {
                    data = json.load(fh);
                    profiles.append({
                        "name": data.get("name", f[:-5]),
                        "url": data.get("url", ""),
                        "username": data.get("username", ""),
                        "created_at": data.get("created_at", "")
                    });
                }
            } except Exception {
                profiles = profiles;
            }
        }
    }
    return profiles;
}

def _do_auth_show(args: list) -> dict {
    name = args[0];
    path = _auth_path(name);
    if not exists(path) {
        return {"error": "Profile not found: " + name};
    }
    with open(path, "r") as f {
        data = json.load(f);
    }
    return {
        "name": data.get("name", name),
        "url": data.get("url", ""),
        "username": data.get("username", ""),
        "created_at": data.get("created_at", ""),
        "last_login_at": data.get("last_login_at", "")
    };
}

def _do_auth_delete(args: list) -> object {
    name = args[0];
    path = _auth_path(name);
    if exists(path) {
        remove(path);
    }
    return None;
}

def _do_auth_login(args: list) -> dict {
    name = args[0];
    page = args[1];
    path = _auth_path(name);
    if not exists(path) {
        return {"error": "Profile not found: " + name};
    }
    with open(path, "r") as f {
        profile = json.load(f);
    }

    # Navigate to login page
    page.goto(profile["url"], wait_until="load");

    # Find username field
    usel = profile.get("username_selector", "");
    if not usel {
        for sel in [
            "input[autocomplete='username']:visible",
            "input[type='email']:visible",
            "input[name='username']:visible",
            "input[name='email']:visible"
        ] {
            try {
                loc = page.locator(sel);
                if loc.count() > 0 {
                    usel = sel;
                    break;
                }
            } except Exception {
                usel = usel;
            }
        }
    }

    # Find password field
    psel = profile.get("password_selector", "");
    if not psel {
        psel = "input[type='password']:visible";
    }

    # Find submit button
    ssel = profile.get("submit_selector", "");
    if not ssel {
        for sel in ["button[type='submit']:visible", "input[type='submit']:visible"] {
            try {
                loc = page.locator(sel);
                if loc.count() > 0 {
                    ssel = sel;
                    break;
                }
            } except Exception {
                ssel = ssel;
            }
        }
    }

    # Fill and submit
    if usel {
        page.locator(usel).fill(profile["username"]);
    }
    page.locator(psel).fill(profile["password"]);
    if ssel {
        page.locator(ssel).click();
    }
    page.wait_for_load_state("load");

    # Update last login
    profile["last_login_at"] = time.strftime("%Y-%m-%dT%H:%M:%S");
    with open(path, "w") as f {
        json.dump(profile, f);
    }

    return {"url": page.url, "title": page.title()};
}


# ---------------------------------------------------------------------------
# ARIA snapshot processing
# ---------------------------------------------------------------------------

def _reset_refs() -> None {
    _ref_state["counter"] = 0;
}

def _next_ref() -> str {
    _ref_state["counter"] = _ref_state["counter"] + 1;
    return "e" + str(_ref_state["counter"]);
}

"""Walk ARIA snapshot lines, assign refs to interactive elements."""
def _process_aria_tree(raw: str) -> dict {
    _reset_refs();
    lines = raw.splitlines();
    enhanced_lines: list = [];
    ref_map: dict = {};
    role_name_counts: dict = {};
    role_name_refs: dict = {};

    for line in lines {
        m = LINE_RE.match(line);
        if not m {
            enhanced_lines.append(line);
            continue;
        }
        role = m.group("role");
        name_dq = m.group("name_dq");
        name_sq = m.group("name_sq");
        name = "";
        if name_dq {
            name = name_dq;
        } elif name_sq {
            name = name_sq;
        }

        if role not in INTERACTIVE_ROLES {
            enhanced_lines.append(line);
            continue;
        }

        ref_id = _next_ref();
        key = role + ":" + name;

        idx = role_name_counts.get(key, 0);
        role_name_counts[key] = idx + 1;
        role_name_refs.setdefault(key, []).append(ref_id);

        ref_map[ref_id] = {
            "role": role,
            "name": name,
            "selector": "getByRole('" + role + "', name='" + name + "', exact=True)",
            "nth": idx
        };

        indent = m.group("indent");
        rest = line[m.end():];
        enhanced_line = indent + "- " + role + " [" + ref_id + "]";
        if name {
            enhanced_line = enhanced_line + ' "' + name + '"';
        }
        enhanced_line = enhanced_line + rest;
        enhanced_lines.append(enhanced_line);
    }

    # Remove nth from non-duplicate entries
    for key in role_name_refs {
        refs = role_name_refs[key];
        if len(refs) == 1 {
            if refs[0] in ref_map {
                ref_map[refs[0]].pop("nth", None);
            }
        }
    }

    return {"tree": "\n".join(enhanced_lines), "refs": ref_map};
}

"""Parse ref formats: @e1, ref=e1, e1. Returns ref_id or empty string."""
def _parse_ref(arg: str) -> str {
    arg = arg.strip();
    if arg.startswith("@") {
        return arg[1:];
    }
    if arg.startswith("ref=") {
        return arg[4:];
    }
    if re.match(r"^e\d+$", arg) {
        return arg;
    }
    return "";
}


# ---------------------------------------------------------------------------
# PlaywrightBridge obj -- thin wrapper around glob state + thread execution
# ---------------------------------------------------------------------------

obj PlaywrightBridge {
    has _tag: int = 0;

    def is_launched() -> bool {
        return _state["browser"] is not None;
    }

    def launch(headless: bool = True) -> None {
        if self.is_launched() {
            return;
        }
        _exec(_do_launch, [headless]);
    }

    def new_page() -> object {
        if not self.is_launched() {
            raise RuntimeError("Browser not launched. Call launch() first.");
        }
        return _exec(_do_new_page, []);
    }

    def close_browser() -> None {
        _exec(_do_close, []);
    }

    def close_page(page: object) -> None {
        _exec(_do_close_page, [page]);
    }

    def list_pages() -> list {
        return _exec(_do_list_pages, []);
    }

    def store_page(page_id: str, page: object) -> None {
        _state["pages"][page_id] = page;
    }

    def remove_page(page_id: str) -> None {
        _state["pages"].pop(page_id, None);
    }

    def get_page(page_id: str) -> object {
        return _state["pages"].get(page_id, None);
    }

    def goto(page: object, url: str, wait_until: str = "load") -> None {
        _exec(_do_goto, [page, url, wait_until]);
    }

    def go_back(page: object) -> None {
        _exec(_do_go_back, [page]);
    }

    def go_forward(page: object) -> None {
        _exec(_do_go_forward, [page]);
    }

    def reload_page(page: object) -> None {
        _exec(_do_reload, [page]);
    }

    def get_url(page: object) -> str {
        return _exec(_do_get_url, [page]);
    }

    def get_title(page: object) -> str {
        return _exec(_do_get_title, [page]);
    }

    def take_snapshot(page: object, selector: str = "page") -> dict {
        return _exec(_do_snapshot, [page, selector]);
    }

    def get_locator(page: object, selector_or_ref: str, ref_map: dict) -> object {
        return _exec(_do_get_locator, [page, selector_or_ref, ref_map]);
    }

    def click_element(locator: object) -> None {
        _exec(_do_click, [locator]);
    }

    def dblclick_element(locator: object) -> None {
        _exec(_do_dblclick, [locator]);
    }

    def fill_element(locator: object, value: str) -> None {
        _exec(_do_fill, [locator, value]);
    }

    def type_element(locator: object, text: str, delay: int = 50) -> None {
        _exec(_do_type, [locator, text, delay]);
    }

    def hover_element(locator: object) -> None {
        _exec(_do_hover, [locator]);
    }

    def press_key(locator: object, key: str) -> None {
        _exec(_do_press, [locator, key]);
    }

    def check_element(locator: object) -> None {
        _exec(_do_check, [locator]);
    }

    def uncheck_element(locator: object) -> None {
        _exec(_do_uncheck, [locator]);
    }

    def select_option(locator: object, value: str) -> None {
        _exec(_do_select_option, [locator, value]);
    }

    def clear_element(locator: object) -> None {
        _exec(_do_clear, [locator]);
    }

    def focus_element(locator: object) -> None {
        _exec(_do_focus, [locator]);
    }

    def set_input_files(locator: object, files: list) -> None {
        _exec(_do_set_input_files, [locator, files]);
    }

    def drag_and_drop(page: object, source: str, target: str) -> None {
        _exec(_do_drag, [page, source, target]);
    }

    def scroll_into_view(locator: object) -> None {
        _exec(_do_scroll_into_view, [locator]);
    }

    def dispatch_event(locator: object, event: str, event_init: dict = {}) -> None {
        _exec(_do_dispatch_event, [locator, event, event_init]);
    }

    def download_file(page: object, locator: object, save_path: str = "") -> dict {
        return _exec(_do_download, [page, locator, save_path]);
    }

    def take_screenshot(page: object, full_page: bool = False, selector: str = "") -> object {
        return _exec(_do_screenshot, [page, full_page, selector]);
    }

    def mouse_wheel(page: object, delta_x: int, delta_y: int) -> None {
        _exec(_do_mouse_wheel, [page, delta_x, delta_y]);
    }

    def scroll_element(locator: object, delta_x: int, delta_y: int) -> None {
        _exec(_do_scroll_element, [locator, delta_x, delta_y]);
    }

    def get_text_content(locator: object) -> str {
        return _exec(_do_text_content, [locator]);
    }

    def inner_text(locator: object) -> str {
        return _exec(_do_inner_text, [locator]);
    }

    def inner_html(locator: object) -> str {
        return _exec(_do_inner_html, [locator]);
    }

    def input_value(locator: object) -> str {
        return _exec(_do_input_value, [locator]);
    }

    def bounding_box(locator: object) -> object {
        return _exec(_do_bounding_box, [locator]);
    }

    def get_content(page: object, selector: str = "") -> str {
        return _exec(_do_get_content, [page, selector]);
    }

    def get_attribute(locator: object, attribute: str) -> object {
        return _exec(_do_get_attribute, [locator, attribute]);
    }

    def is_visible(locator: object) -> bool {
        return _exec(_do_is_visible, [locator]);
    }

    def is_enabled(locator: object) -> bool {
        return _exec(_do_is_enabled, [locator]);
    }

    def is_checked(locator: object) -> bool {
        return _exec(_do_is_checked, [locator]);
    }

    def element_count(locator: object) -> int {
        return _exec(_do_element_count, [locator]);
    }

    def evaluate(page: object, script: str) -> object {
        return _exec(_do_evaluate, [page, script]);
    }

    def wait_for(locator: object, state: str = "visible", timeout: int = 30000) -> None {
        _exec(_do_wait_for, [locator, state, timeout]);
    }

    def wait_for_url(page: object, url: str, timeout: int = 30000) -> None {
        _exec(_do_wait_for_url, [page, url, timeout]);
    }

    def wait_for_load_state(page: object, state: str = "load", timeout: int = 30000) -> None {
        _exec(_do_wait_for_load_state, [page, state, timeout]);
    }

    def wait_for_function(page: object, expression: str, timeout: int = 30000) -> None {
        _exec(_do_wait_for_function, [page, expression, timeout]);
    }

    def cookies_get(url: str = "") -> list {
        return _exec(_do_cookies_get, [url]);
    }

    def cookies_set(cookies: list) -> None {
        _exec(_do_cookies_set, [cookies]);
    }

    def cookies_clear() -> None {
        _exec(_do_cookies_clear, []);
    }

    def storage_get(page: object, key: str = "", storage_type: str = "local") -> object {
        return _exec(_do_storage_get, [page, key, storage_type]);
    }

    def storage_set(page: object, key: str, value: str, storage_type: str = "local") -> None {
        _exec(_do_storage_set, [page, key, value, storage_type]);
    }

    def storage_clear(page: object, storage_type: str = "local") -> None {
        _exec(_do_storage_clear, [page, storage_type]);
    }

    def set_dialog_handler(page: object, response: str = "accept", prompt_text: str = "") -> None {
        _exec(_do_set_dialog_handler, [page, response, prompt_text]);
    }

    def install_console_listener(page: object, page_id: str) -> None {
        installed = _state["listeners_installed"].get(page_id, []);
        if "console" not in installed {
            _exec(_do_install_console_listener, [page, page_id]);
        }
    }

    def get_console_messages() -> list {
        return list(_state["console_messages"]);
    }

    def clear_console_messages() -> None {
        _state["console_messages"] = [];
    }

    def install_error_listener(page: object, page_id: str) -> None {
        installed = _state["listeners_installed"].get(page_id, []);
        if "pageerror" not in installed {
            _exec(_do_install_error_listener, [page, page_id]);
        }
    }

    def get_page_errors() -> list {
        return list(_state["page_errors"]);
    }

    def clear_page_errors() -> None {
        _state["page_errors"] = [];
    }

    def install_request_listener(page: object, page_id: str) -> None {
        installed = _state["listeners_installed"].get(page_id, []);
        if "request" not in installed {
            _exec(_do_install_request_listener, [page, page_id]);
        }
    }

    def get_request_log(filter_str: str = "") -> list {
        if filter_str {
            filtered: list = [];
            for r in _state["request_log"] {
                if filter_str in r["url"] {
                    filtered.append(r);
                }
            }
            return filtered;
        }
        return list(_state["request_log"]);
    }

    def clear_request_log() -> None {
        _state["request_log"] = [];
    }

    def add_route(page: object, url: str, abort: bool = False,
                  status: int = 200, body: str = "", content_type: str = "text/plain") -> None {
        _exec(_do_add_route, [page, url, abort, status, body, content_type]);
    }

    def remove_route(page: object, url: str = "") -> None {
        _exec(_do_remove_route, [page, url]);
    }

    def mouse_move(page: object, x: float, y: float) -> None {
        _exec(_do_mouse_move, [page, x, y]);
    }

    def mouse_down(page: object, button: str = "left") -> None {
        _exec(_do_mouse_down, [page, button]);
    }

    def mouse_up(page: object, button: str = "left") -> None {
        _exec(_do_mouse_up, [page, button]);
    }

    def keyboard_type(page: object, text: str, delay: int = 0) -> None {
        _exec(_do_keyboard_type, [page, text, delay]);
    }

    def keyboard_press(page: object, keys: str) -> None {
        _exec(_do_keyboard_press, [page, keys]);
    }

    def keyboard_insert_text(page: object, text: str) -> None {
        _exec(_do_keyboard_insert_text, [page, text]);
    }

    def key_down(page: object, key: str) -> None {
        _exec(_do_key_down, [page, key]);
    }

    def key_up(page: object, key: str) -> None {
        _exec(_do_key_up, [page, key]);
    }

    def set_viewport(page: object, width: int, height: int) -> None {
        _exec(_do_set_viewport, [page, width, height]);
    }

    def set_content(page: object, html: str) -> None {
        _exec(_do_set_content, [page, html]);
    }

    def emulate_media(page: object, media: str = "", color_scheme: str = "",
                      reduced_motion: str = "") -> None {
        _exec(_do_emulate_media, [page, media, color_scheme, reduced_motion]);
    }

    def set_offline(is_offline: bool = True) -> None {
        _exec(_do_set_offline, [is_offline]);
    }

    def state_save(path: str) -> None {
        _exec(_do_state_save, [path]);
    }

    def state_load(path: str) -> None {
        _exec(_do_state_load, [path]);
    }

    # -- Phase 4: Frames -------------------------------------------------

    def frame_locator(page: object, selector: str) -> object {
        return _exec(_do_frame_locator, [page, selector]);
    }

    def frame_evaluate(page: object, frame_selector: str, script: str) -> object {
        return _exec(_do_frame_evaluate, [page, frame_selector, script]);
    }

    def main_frame_url(page: object) -> str {
        return _exec(_do_main_frame_url, [page]);
    }

    # -- Phase 4: Semantic locators --------------------------------------

    def get_by_text(page: object, text: str, exact: bool = False) -> object {
        return _exec(_do_get_by_text, [page, text, exact]);
    }

    def get_by_role(page: object, role: str, name: str = "") -> object {
        return _exec(_do_get_by_role, [page, role, name]);
    }

    def get_by_label(page: object, text: str, exact: bool = False) -> object {
        return _exec(_do_get_by_label, [page, text, exact]);
    }

    def get_by_placeholder(page: object, text: str, exact: bool = False) -> object {
        return _exec(_do_get_by_placeholder, [page, text, exact]);
    }

    def get_by_alt_text(page: object, text: str, exact: bool = False) -> object {
        return _exec(_do_get_by_alt_text, [page, text, exact]);
    }

    def get_by_title(page: object, text: str, exact: bool = False) -> object {
        return _exec(_do_get_by_title, [page, text, exact]);
    }

    def get_by_test_id(page: object, test_id: str) -> object {
        return _exec(_do_get_by_test_id, [page, test_id]);
    }

    # -- Phase 4: PDF ----------------------------------------------------

    def pdf_export(page: object, format: str = "", landscape: bool = False,
                   print_background: bool = False) -> bytes {
        return _exec(_do_pdf, [page, format, landscape, print_background]);
    }

    # -- Phase 4: Emulation ----------------------------------------------

    def set_geolocation(lat: float, lon: float, accuracy: float = 0.0) -> None {
        _exec(_do_set_geolocation, [lat, lon, accuracy]);
    }

    def grant_permissions(permissions: list) -> None {
        _exec(_do_grant_permissions, [permissions]);
    }

    def clear_permissions() -> None {
        _exec(_do_clear_permissions, []);
    }

    def set_extra_http_headers(headers: dict) -> None {
        _exec(_do_set_extra_http_headers, [headers]);
    }

    # -- Phase 4: Script injection ---------------------------------------

    def add_init_script(page: object, script: str) -> None {
        _exec(_do_add_init_script, [page, script]);
    }

    def add_script_tag(page: object, url: str = "", content: str = "") -> object {
        return _exec(_do_add_script_tag, [page, url, content]);
    }

    def add_style_tag(page: object, url: str = "", content: str = "") -> object {
        return _exec(_do_add_style_tag, [page, url, content]);
    }

    # -- Phase 4: Advanced element ops -----------------------------------

    def highlight_element(locator: object) -> None {
        _exec(_do_highlight, [locator]);
    }

    def set_checked(locator: object, checked: bool) -> None {
        _exec(_do_set_checked, [locator, checked]);
    }

    def select_all(page: object) -> None {
        _exec(_do_select_all, [page]);
    }

    def multi_select(locator: object, values: list) -> None {
        _exec(_do_multi_select, [locator, values]);
    }

    def locator_nth(locator: object, index: int) -> object {
        return _exec(_do_locator_nth, [locator, index]);
    }

    # -- Phase 4: Clipboard ----------------------------------------------

    def clipboard_read(page: object) -> str {
        return _exec(_do_clipboard_read, [page]);
    }

    def clipboard_write(page: object, text: str) -> None {
        _exec(_do_clipboard_write, [page, text]);
    }

    # -- Phase 4: Mouse extras -------------------------------------------

    def mouse_click(page: object, x: float, y: float, button: str = "left",
                    click_count: int = 1) -> None {
        _exec(_do_mouse_click, [page, x, y, button, click_count]);
    }

    def mouse_dblclick(page: object, x: float, y: float) -> None {
        _exec(_do_mouse_dblclick, [page, x, y]);
    }

    # -- Phase 4: Touch --------------------------------------------------

    def tap_element(locator: object) -> None {
        _exec(_do_tap, [locator]);
    }

    # -- Phase 4: Browser window -----------------------------------------

    def bring_to_front(page: object) -> None {
        _exec(_do_bring_to_front, [page]);
    }

    # -- Phase 4: Tracing ------------------------------------------------

    def tracing_start(name: str = "") -> None {
        _exec(_do_tracing_start, [name]);
    }

    def tracing_stop(path: str) -> None {
        _exec(_do_tracing_stop, [path]);
    }

    # -- Phase 4: HAR ---------------------------------------------------

    def har_start(page: object, path: str) -> None {
        _exec(_do_har_start, [page, path]);
    }

    # -- Phase 4: Video --------------------------------------------------

    def video_path(page: object) -> str {
        return _exec(_do_video_path, [page]);
    }

    # -- Phase 4: Expose function ----------------------------------------

    def expose_function(page: object, name: str, fn: object) -> None {
        _exec(_do_expose_function, [page, name, fn]);
    }

    # -- Phase 4: Evaluate handle ----------------------------------------

    def evaluate_handle(page: object, script: str) -> object {
        return _exec(_do_evaluate_handle, [page, script]);
    }

    # -- Phase 4: HTTP credentials ---------------------------------------

    def set_http_credentials(username: str, password: str) -> None {
        _exec(_do_set_http_credentials, [username, password]);
    }

    # -- Phase 4: State management extras --------------------------------

    def state_list(directory: str) -> list {
        return _exec(_do_state_list, [directory]);
    }

    def state_delete(path: str) -> None {
        _exec(_do_state_delete, [path]);
    }

    def state_rename(old_path: str, new_path: str) -> None {
        _exec(_do_state_rename, [old_path, new_path]);
    }

    def state_show(path: str) -> object {
        return _exec(_do_state_show, [path]);
    }

    # -- Phase 4: Visual diff -------------------------------------------

    def diff_screenshots(img1: bytes, img2: bytes) -> dict {
        return _exec(_do_diff_screenshots, [img1, img2]);
    }

    # -- Phase 4: Confirm/Deny ------------------------------------------

    def set_confirm_handler(page: object, accept: bool = True) -> None {
        _exec(_do_set_confirm_handler, [page, accept]);
    }

    # -- Phase 4: Locator text operations --------------------------------

    def locator_all_text_contents(locator: object) -> list {
        return _exec(_do_locator_text_content, [locator]);
    }

    def locator_all_inner_texts(locator: object) -> list {
        return _exec(_do_locator_all_inner_texts, [locator]);
    }

    # -- Phase 4 gap: Computed styles -----------------------------------

    def get_computed_styles(locator: object, properties: list = []) -> dict {
        return _exec(_do_get_computed_styles, [locator, properties]);
    }

    # -- Phase 4 gap: State clean ---------------------------------------

    def state_clean(directory: str, max_age_days: int = 30) -> int {
        return _exec(_do_state_clean, [directory, max_age_days]);
    }

    # -- Phase 4 gap: Wait for download ---------------------------------

    def wait_for_download(page: object, action_fn: object = None,
                          save_path: str = "", timeout: int = 30000) -> dict {
        return _exec(_do_wait_for_download, [page, action_fn, save_path, timeout]);
    }

    # -- Phase 4 gap: Swipe ---------------------------------------------

    def swipe(page: object, start_x: float, start_y: float,
              end_x: float, end_y: float, steps: int = 10) -> None {
        _exec(_do_swipe, [page, start_x, start_y, end_x, end_y, steps]);
    }

    # -- Phase 4 gap: Recording restart ---------------------------------

    def recording_restart() -> None {
        _exec(_do_recording_restart, []);
    }

    # -- Phase 4 gap: Auth vault ----------------------------------------

    def auth_save(name: str, url: str, username: str, password: str,
                  username_selector: str = "", password_selector: str = "",
                  submit_selector: str = "") -> dict {
        return _exec(_do_auth_save, [name, url, username, password,
                                      username_selector, password_selector, submit_selector]);
    }

    def auth_list() -> list {
        return _exec(_do_auth_list, []);
    }

    def auth_show(name: str) -> dict {
        return _exec(_do_auth_show, [name]);
    }

    def auth_delete(name: str) -> None {
        _exec(_do_auth_delete, [name]);
    }

    def auth_login(name: str, page: object) -> dict {
        return _exec(_do_auth_login, [name, page]);
    }
}
