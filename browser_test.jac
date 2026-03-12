"""Integration tests for jac-browser Phase 2+3+4 (135 walkers)."""

import from os.path {abspath, join}
import from os {getcwd}
import from tempfile {mkdtemp}
import from jac_browser.browser_bridge {PlaywrightBridge}
import from jac_browser.nodes {BrowserSession, PageNode, SnapshotNode, ElementRef}
import from jac_browser.helpers {
    get_or_create_session,
    get_active_page_node,
    get_page_object,
    store_page_object,
    get_latest_snapshot,
    remove_old_snapshots,
    get_ready_page,
    get_ref_map_for_page
}
import from jac_browser.walkers {
    launch,
    navigate,
    snapshot,
    click,
    fill,
    type_text,
    screenshot,
    scroll,
    get_text,
    close_browser,
    back,
    forward,
    reload,
    get_url,
    get_title,
    hover,
    dblclick,
    press,
    check_element,
    uncheck_element,
    select_option,
    clear_input,
    get_attribute,
    is_visible,
    is_enabled,
    is_checked,
    evaluate,
    wait_for,
    wait_for_url,
    cookies_get,
    cookies_set,
    cookies_clear,
    element_count,
    tab_new,
    tab_list,
    tab_switch,
    tab_close,
    dialog,
    upload,
    download,
    focus,
    drag,
    scroll_into_view,
    storage_get,
    storage_set,
    storage_clear,
    console_get,
    errors_get,
    inner_text,
    inner_html,
    input_value,
    bounding_box,
    get_html_content,
    dispatch_event,
    mouse_move,
    mouse_down,
    mouse_up,
    keyboard,
    key_down,
    key_up,
    route,
    unroute,
    requests_get,
    wait_for_load_state,
    wait_for_function,
    viewport,
    set_content,
    emulate_media,
    offline,
    state_save,
    state_load,
    frame,
    mainframe,
    get_by_text,
    get_by_role,
    get_by_label,
    get_by_placeholder,
    get_by_alt_text,
    get_by_title,
    get_by_test_id,
    geolocation,
    permissions,
    timezone,
    locale,
    useragent,
    device,
    device_list,
    credentials,
    headers,
    add_init_script,
    add_script,
    add_style,
    highlight,
    set_checked,
    select_all,
    multi_select,
    nth,
    clipboard,
    mouse_click,
    mouse_dblclick,
    wheel,
    tap,
    bring_to_front,
    window_new,
    trace_start,
    trace_stop,
    eval_handle,
    expose,
    pause_page,
    confirm,
    deny,
    diff_screenshot,
    diff_snapshot,
    diff_url,
    state_list,
    state_show,
    state_delete,
    state_rename,
    state_clear,
    input_keyboard,
    input_mouse,
    insert_text,
    set_value,
    styles,
    state_clean,
    swipe,
    recording_restart,
    auth_save,
    auth_list,
    auth_show,
    auth_delete
}


glob TEST_PAGE: str = "file://" + abspath(join(join(getcwd(), "tests"), "test_page.html"));


test "phase 2 core" {
    # --- Launch ---
    w = root spawn launch(headless=True);
    res = w.reports[0];
    assert res["success"] == True, "launch failed";

    # --- Navigate ---
    w = root spawn navigate(url=TEST_PAGE);
    res = w.reports[0];
    assert res["success"] == True, "navigate failed";

    # --- Snapshot ---
    w = root spawn snapshot();
    res = w.reports[0];
    assert res["success"] == True, "snapshot failed";
    assert "Test Page" in str(res["snapshot"]);

    # --- get_url / get_title ---
    w = root spawn get_url();
    assert "test_page.html" in str(w.reports[0]["url"]);
    w = root spawn get_title();
    assert w.reports[0]["title"] == "jac-browser Test Page";

    # --- Fill + type ---
    w = root spawn fill(selector="#text-input", value="hello");
    assert w.reports[0]["success"] == True;
    w = root spawn type_text(selector="#text-input", text="typed", clear=True, delay=10);
    assert w.reports[0]["success"] == True;

    # --- Click ---
    w = root spawn click(selector="#btn-click");
    assert w.reports[0]["success"] == True;
    w = root spawn get_text(selector="#output");
    assert w.reports[0]["text"] == "clicked";

    # --- Hover + dblclick ---
    w = root spawn hover(selector="#btn-click");
    assert w.reports[0]["success"] == True;
    w = root spawn dblclick(selector="#btn-dblclick");
    assert w.reports[0]["success"] == True;

    # --- Press ---
    w = root spawn press(selector="#text-input", key="End");
    assert w.reports[0]["success"] == True;

    # --- Check / uncheck ---
    w = root spawn check_element(selector="#check1");
    assert w.reports[0]["success"] == True;
    w = root spawn is_checked(selector="#check1");
    assert w.reports[0]["checked"] == True;
    w = root spawn uncheck_element(selector="#check1");
    assert w.reports[0]["success"] == True;

    # --- Select ---
    w = root spawn select_option(selector="#color-select", value="green");
    assert w.reports[0]["success"] == True;

    # --- Clear input ---
    root spawn fill(selector="#text-input", value="x");
    w = root spawn clear_input(selector="#text-input");
    assert w.reports[0]["success"] == True;

    # --- Get attribute ---
    w = root spawn get_attribute(selector="#data-el", attribute="data-testid");
    assert w.reports[0]["value"] == "abc123";

    # --- Visibility / enabled ---
    w = root spawn is_visible(selector="#visible-div");
    assert w.reports[0]["visible"] == True;
    w = root spawn is_visible(selector="#hidden-div");
    assert w.reports[0]["visible"] == False;
    w = root spawn is_enabled(selector="#btn-click");
    assert w.reports[0]["enabled"] == True;
    w = root spawn is_enabled(selector="#btn-disabled");
    assert w.reports[0]["enabled"] == False;

    # --- Element count ---
    w = root spawn element_count(selector="input[type='checkbox']");
    assert w.reports[0]["count"] == 2;

    # --- Evaluate ---
    w = root spawn evaluate(script="window.testValue + 1");
    assert w.reports[0]["result"] == 101;

    # --- Wait for ---
    w = root spawn wait_for(selector="#main-heading", state="visible", timeout=5000);
    assert w.reports[0]["success"] == True;

    # --- Back / forward / reload ---
    root spawn navigate(url=TEST_PAGE + "#page2");
    w = root spawn back();
    assert w.reports[0]["success"] == True;
    w = root spawn forward();
    assert w.reports[0]["success"] == True;
    w = root spawn reload();
    assert w.reports[0]["success"] == True;

    # --- Screenshot ---
    w = root spawn screenshot();
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["format"] == "png";

    # --- Scroll ---
    w = root spawn scroll(direction="down", amount=200);
    assert w.reports[0]["success"] == True;

    # --- Cookies ---
    w = root spawn cookies_set(cookies=[
        {"name": "tc", "value": "tv", "domain": "example.com", "path": "/"}
    ]);
    assert w.reports[0]["success"] == True;
    w = root spawn cookies_get();
    cookie_found = False;
    for c in w.reports[0]["cookies"] {
        if c["name"] == "tc" { cookie_found = True; }
    }
    assert cookie_found;
    w = root spawn cookies_clear();
    assert w.reports[0]["success"] == True;

    # --- Tabs ---
    w = root spawn tab_new(url=TEST_PAGE);
    assert w.reports[0]["success"] == True;
    new_pid = w.reports[0]["page_id"];
    w = root spawn tab_list();
    assert w.reports[0]["success"] == True;
    w = root spawn tab_close(page_id=str(new_pid));
    assert w.reports[0]["success"] == True;

    # --- Close ---
    w = root spawn close_browser();
    assert w.reports[0]["success"] == True;
}


test "phase 3 features" {
    # --- Launch + navigate ---
    w = root spawn launch(headless=True);
    assert w.reports[0]["success"] == True;
    w = root spawn navigate(url=TEST_PAGE);
    assert w.reports[0]["success"] == True;

    # --- 3A: Dialog ---
    w = root spawn dialog(response="accept");
    assert w.reports[0]["success"] == True;
    # Trigger alert - dialog handler auto-accepts
    w = root spawn click(selector="#btn-alert");
    assert w.reports[0]["success"] == True;

    # --- 3A: Focus ---
    w = root spawn focus(selector="#text-input");
    assert w.reports[0]["success"] == True;

    # --- 3A: Scroll into view ---
    w = root spawn scroll_into_view(selector="#below-fold");
    assert w.reports[0]["success"] == True;

    # --- 3A: Upload (set empty files clears) ---
    w = root spawn upload(selector="#file-upload", files=[]);
    assert w.reports[0]["success"] == True;

    # --- 3B: Storage ---
    w = root spawn storage_set(key="test-key", value="test-val", storage_type="local");
    assert w.reports[0]["success"] == True;

    w = root spawn storage_get(key="test-key", storage_type="local");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["value"] == "test-val";

    w = root spawn storage_get(storage_type="local");
    assert w.reports[0]["success"] == True;

    w = root spawn storage_clear(storage_type="local");
    assert w.reports[0]["success"] == True;

    w = root spawn storage_get(key="test-key", storage_type="local");
    assert w.reports[0]["value"] is None;

    # --- 3C: Console capture ---
    w = root spawn console_get();
    assert w.reports[0]["success"] == True;
    # Trigger console.log
    w = root spawn click(selector="#btn-console");
    assert w.reports[0]["success"] == True;
    w = root spawn console_get();
    assert w.reports[0]["success"] == True;
    found_log = False;
    for m in w.reports[0]["messages"] {
        if "test-log-msg" in str(m["text"]) {
            found_log = True;
        }
    }
    assert found_log, "console message not captured";

    w = root spawn console_get(do_clear=True);
    assert w.reports[0]["cleared"] == True;

    # --- 3C: Error capture ---
    w = root spawn errors_get();
    assert w.reports[0]["success"] == True;

    # --- 3D: Inner text ---
    w = root spawn inner_text(selector="#description");
    assert w.reports[0]["success"] == True;
    assert "integration tests" in str(w.reports[0]["text"]);

    # --- 3D: Inner HTML ---
    w = root spawn inner_html(selector="#html-el");
    assert w.reports[0]["success"] == True;
    assert "<strong>" in str(w.reports[0]["html"]);

    # --- 3D: Input value ---
    root spawn fill(selector="#text-input", value="iv-test");
    w = root spawn input_value(selector="#text-input");
    assert w.reports[0]["value"] == "iv-test";

    # --- 3D: Bounding box ---
    w = root spawn bounding_box(selector="#main-heading");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["box"] is not None;

    # --- 3D: Get HTML content ---
    w = root spawn get_html_content();
    assert w.reports[0]["success"] == True;
    assert "Test Page" in str(w.reports[0]["html"]);

    w = root spawn get_html_content(selector="#html-el");
    assert "<em>" in str(w.reports[0]["html"]);

    # --- 3D: Dispatch event ---
    w = root spawn dispatch_event(selector="#btn-click", event="click");
    assert w.reports[0]["success"] == True;

    # --- 3E: Mouse control ---
    w = root spawn mouse_move(x=100.0, y=100.0);
    assert w.reports[0]["success"] == True;
    w = root spawn mouse_down(button="left");
    assert w.reports[0]["success"] == True;
    w = root spawn mouse_up(button="left");
    assert w.reports[0]["success"] == True;

    # --- 3E: Keyboard ---
    root spawn focus(selector="#text-input");
    root spawn clear_input(selector="#text-input");
    w = root spawn keyboard(subaction="type", text="kb-test", delay=10);
    assert w.reports[0]["success"] == True;
    w = root spawn input_value(selector="#text-input");
    assert w.reports[0]["value"] == "kb-test";

    w = root spawn keyboard(subaction="press", keys="Enter");
    assert w.reports[0]["success"] == True;

    # --- 3E: Key down / up ---
    w = root spawn key_down(key="Shift");
    assert w.reports[0]["success"] == True;
    w = root spawn key_up(key="Shift");
    assert w.reports[0]["success"] == True;

    # --- 3E: Wait for load state ---
    w = root spawn wait_for_load_state(state="load", timeout=5000);
    assert w.reports[0]["success"] == True;

    # --- 3E: Wait for function ---
    w = root spawn wait_for_function(expression="() => document.title.length > 0", timeout=5000);
    assert w.reports[0]["success"] == True;

    # --- 3F: Viewport ---
    w = root spawn viewport(width=800, height=600);
    assert w.reports[0]["success"] == True;

    # --- 3F: Set content ---
    w = root spawn set_content(html="<h1 id='injected'>Injected</h1>");
    assert w.reports[0]["success"] == True;
    w = root spawn inner_text(selector="#injected");
    assert w.reports[0]["text"] == "Injected";

    # Navigate back so other tests work
    root spawn navigate(url=TEST_PAGE);

    # --- 3F: Emulate media ---
    w = root spawn emulate_media(color_scheme="dark");
    assert w.reports[0]["success"] == True;

    # --- 3F: State save ---
    tmp_dir = mkdtemp();
    state_path = tmp_dir + "/state.json";
    w = root spawn state_save(path=state_path);
    assert w.reports[0]["success"] == True;

    # --- 3F: State load ---
    w = root spawn state_load(path=state_path);
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["loaded"] == True;

    # --- Close ---
    w = root spawn close_browser();
    assert w.reports[0]["success"] == True;
}


test "phase 4 features" {
    # --- Launch + navigate ---
    w = root spawn launch(headless=True);
    assert w.reports[0]["success"] == True;
    w = root spawn navigate(url=TEST_PAGE);
    assert w.reports[0]["success"] == True;

    # --- Mainframe ---
    w = root spawn mainframe();
    assert w.reports[0]["success"] == True;
    assert "test_page.html" in str(w.reports[0]["url"]);

    # --- Frame evaluate ---
    w = root spawn frame(selector="#test-iframe", script="document.getElementById('frame-heading').textContent");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["result"] == "Frame Content";

    # --- Semantic locators: get_by_text ---
    w = root spawn snapshot();
    assert w.reports[0]["success"] == True;
    w = root spawn get_by_text(text="Semantic Button", exact=True, action="count");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["count"] >= 1;

    # --- get_by_role ---
    w = root spawn get_by_role(role="heading", name="Test Page", action="count");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["count"] >= 1;

    # --- get_by_label ---
    w = root spawn get_by_label(text="Labeled Field:", exact=True, action="count");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["count"] >= 1;

    # --- get_by_placeholder ---
    w = root spawn get_by_placeholder(text="Enter value", exact=True, action="count");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["count"] >= 1;

    # --- get_by_title ---
    w = root spawn get_by_title(text="Input with title", exact=True, action="count");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["count"] >= 1;

    # --- get_by_test_id ---
    w = root spawn get_by_test_id(test_id="semantic-test-el", action="count");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["count"] >= 1;

    # --- Emulation: geolocation ---
    w = root spawn geolocation(latitude=37.7749, longitude=-122.4194);
    assert w.reports[0]["success"] == True;

    # --- Permissions ---
    w = root spawn permissions(grant=["geolocation"]);
    assert w.reports[0]["success"] == True;
    w = root spawn permissions(do_clear=True);
    assert w.reports[0]["success"] == True;

    # --- Timezone / locale / useragent / device (informational) ---
    w = root spawn timezone(timezone_id="America/New_York");
    assert w.reports[0]["success"] == True;
    w = root spawn locale(locale_str="en-US");
    assert w.reports[0]["success"] == True;
    w = root spawn useragent();
    assert w.reports[0]["success"] == True;
    w = root spawn device(device_name="iPhone 12");
    assert w.reports[0]["success"] == True;
    w = root spawn device_list();
    assert w.reports[0]["success"] == True;

    # --- Auth & HTTP ---
    w = root spawn credentials(username="user", password="pass");
    assert w.reports[0]["success"] == True;
    w = root spawn headers(headers_dict={"X-Custom": "test-val"});
    assert w.reports[0]["success"] == True;

    # --- Script injection ---
    w = root spawn add_script(content="window.__injectedScript = true;");
    assert w.reports[0]["success"] == True;
    w = root spawn add_style(content="body { background: white; }");
    assert w.reports[0]["success"] == True;
    w = root spawn add_init_script(script="window.__initScript = true;");
    assert w.reports[0]["success"] == True;

    # --- Advanced element ops: set_checked ---
    w = root spawn set_checked(selector="#check1", checked=True);
    assert w.reports[0]["success"] == True;
    w = root spawn is_checked(selector="#check1");
    assert w.reports[0]["checked"] == True;
    w = root spawn set_checked(selector="#check1", checked=False);
    assert w.reports[0]["success"] == True;

    # --- Select all ---
    root spawn fill(selector="#text-input", value="select-me");
    root spawn focus(selector="#text-input");
    w = root spawn select_all();
    assert w.reports[0]["success"] == True;

    # --- Multi select ---
    w = root spawn multi_select(selector="#multi-select", values=["apple", "cherry"]);
    assert w.reports[0]["success"] == True;

    # --- Nth ---
    w = root spawn nth(selector=".list-item", index=1, action="text");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["text"] == "Item Two";

    # --- Mouse click at coordinates ---
    w = root spawn mouse_click(x=100.0, y=100.0, button="left", click_count=1);
    assert w.reports[0]["success"] == True;

    # --- Mouse dblclick at coordinates ---
    w = root spawn mouse_dblclick(x=100.0, y=100.0);
    assert w.reports[0]["success"] == True;

    # --- Wheel ---
    w = root spawn wheel(delta_x=0.0, delta_y=100.0);
    assert w.reports[0]["success"] == True;

    # --- Bring to front ---
    w = root spawn bring_to_front();
    assert w.reports[0]["success"] == True;

    # --- Window new ---
    w = root spawn window_new(url=TEST_PAGE);
    assert w.reports[0]["success"] == True;
    new_pid = w.reports[0]["page_id"];
    # Switch back
    w = root spawn tab_list();
    for t in w.reports[0]["tabs"] {
        if str(t["page_id"]) != str(new_pid) {
            root spawn tab_switch(page_id=str(t["page_id"]));
        }
    }
    root spawn tab_close(page_id=str(new_pid));

    # --- Eval handle ---
    w = root spawn eval_handle(script="({a: 1, b: 2})");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["result"]["a"] == 1;

    # --- Expose (informational) ---
    w = root spawn expose(name="testFn");
    assert w.reports[0]["success"] == True;

    # --- Pause page (informational) ---
    w = root spawn pause_page();
    assert w.reports[0]["success"] == True;

    # --- Confirm / Deny ---
    w = root spawn confirm();
    assert w.reports[0]["success"] == True;
    w = root spawn click(selector="#btn-confirm");
    assert w.reports[0]["success"] == True;
    w = root spawn get_text(selector="#confirm-output");
    assert w.reports[0]["text"] == "confirmed";

    # --- Diff URL ---
    w = root spawn diff_url(expected_url=TEST_PAGE);
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["match"] == True;

    # --- Diff snapshot ---
    w = root spawn snapshot();
    snap_text = w.reports[0]["snapshot"];
    w = root spawn diff_snapshot(snapshot1=str(snap_text), snapshot2=str(snap_text));
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["match"] == True;

    # --- State management extras ---
    tmp_dir = mkdtemp();
    state_path = tmp_dir + "/test_state.json";
    w = root spawn state_save(path=state_path);
    assert w.reports[0]["success"] == True;

    w = root spawn state_list(directory=tmp_dir);
    assert w.reports[0]["success"] == True;
    assert "test_state.json" in w.reports[0]["files"];

    w = root spawn state_show(path=state_path);
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["data"] is not None;

    new_path = tmp_dir + "/renamed_state.json";
    w = root spawn state_rename(old_path=state_path, new_path=new_path);
    assert w.reports[0]["success"] == True;

    w = root spawn state_delete(path=new_path);
    assert w.reports[0]["success"] == True;

    # --- Input keyboard ---
    root spawn focus(selector="#text-input");
    root spawn clear_input(selector="#text-input");
    w = root spawn input_keyboard(text="input-kb");
    assert w.reports[0]["success"] == True;
    w = root spawn input_value(selector="#text-input");
    assert w.reports[0]["value"] == "input-kb";

    # --- Input mouse ---
    w = root spawn input_mouse(x=50.0, y=50.0, action="click");
    assert w.reports[0]["success"] == True;

    # --- Insert text ---
    root spawn focus(selector="#text-input");
    root spawn clear_input(selector="#text-input");
    w = root spawn insert_text(text="inserted");
    assert w.reports[0]["success"] == True;
    w = root spawn input_value(selector="#text-input");
    assert w.reports[0]["value"] == "inserted";

    # --- Set value ---
    w = root spawn set_value(selector="#text-input", value="set-val");
    assert w.reports[0]["success"] == True;
    w = root spawn input_value(selector="#text-input");
    assert w.reports[0]["value"] == "set-val";

    # --- Tracing ---
    tmp_dir2 = mkdtemp();
    trace_path = tmp_dir2 + "/trace.zip";
    w = root spawn trace_start(name="test-trace");
    assert w.reports[0]["success"] == True;
    root spawn navigate(url=TEST_PAGE);
    w = root spawn trace_stop(path=trace_path);
    assert w.reports[0]["success"] == True;

    # --- Styles (computed CSS) ---
    w = root spawn styles(selector="#main-heading", properties=["font-size", "color"]);
    assert w.reports[0]["success"] == True;
    assert "font-size" in w.reports[0]["styles"];

    # --- State clean ---
    tmp_dir3 = mkdtemp();
    w = root spawn state_clean(directory=tmp_dir3, max_age_days=0);
    assert w.reports[0]["success"] == True;

    # --- Swipe ---
    w = root spawn swipe(direction="down", start_x=200.0, start_y=300.0, distance=200.0);
    assert w.reports[0]["success"] == True;

    # --- Recording restart ---
    w = root spawn recording_restart();
    assert w.reports[0]["success"] == True;

    # --- Auth vault ---
    w = root spawn auth_save(
        name="test-profile",
        url="https://example.com/login",
        username="testuser",
        password="testpass"
    );
    assert w.reports[0]["success"] == True;

    w = root spawn auth_list();
    assert w.reports[0]["success"] == True;
    found_profile = False;
    for p in w.reports[0]["profiles"] {
        if p["name"] == "test-profile" {
            found_profile = True;
        }
    }
    assert found_profile, "auth profile not found in list";

    w = root spawn auth_show(name="test-profile");
    assert w.reports[0]["success"] == True;
    assert w.reports[0]["profile"]["username"] == "testuser";

    w = root spawn auth_delete(name="test-profile");
    assert w.reports[0]["success"] == True;

    # Verify deletion
    w = root spawn auth_show(name="test-profile");
    assert w.reports[0]["success"] == False;

    # --- Close ---
    w = root spawn close_browser();
    assert w.reports[0]["success"] == True;
}
