"""jac-browser: Headless browser automation via graph-native walkers."""

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
    # Phase 1: Core (10)
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
    # Phase 2A: Navigation + Page info (5)
    back,
    forward,
    reload,
    get_url,
    get_title,
    # Phase 2A: Interaction (7)
    hover,
    dblclick,
    press,
    check_element,
    uncheck_element,
    select_option,
    clear_input,
    # Phase 2A: Element queries (4)
    get_attribute,
    is_visible,
    is_enabled,
    is_checked,
    # Phase 2B: JS, Waits, Cookies, Count (7)
    evaluate,
    wait_for,
    wait_for_url,
    cookies_get,
    cookies_set,
    cookies_clear,
    element_count,
    # Phase 2C: Tabs (4)
    tab_new,
    tab_list,
    tab_switch,
    tab_close,
    # Phase 3A: Dialog, Upload, Download, Focus, Drag, Scroll (6)
    dialog,
    upload,
    download,
    focus,
    drag,
    scroll_into_view,
    # Phase 3B: Storage (3)
    storage_get,
    storage_set,
    storage_clear,
    # Phase 3C: Console, Errors (2)
    console_get,
    errors_get,
    # Phase 3D: Content inspection (6)
    inner_text,
    inner_html,
    input_value,
    bounding_box,
    get_html_content,
    dispatch_event,
    # Phase 3E: Mouse, Keyboard, Network, Waits (10)
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
    # Phase 3F: Page config, State (6)
    viewport,
    set_content,
    emulate_media,
    offline,
    state_save,
    state_load,
    # Phase 4: Frames (2)
    frame,
    mainframe,
    # Phase 4: Semantic locators (7)
    get_by_text,
    get_by_role,
    get_by_label,
    get_by_placeholder,
    get_by_alt_text,
    get_by_title,
    get_by_test_id,
    # Phase 4: PDF (1)
    pdf,
    # Phase 4: Emulation (7)
    geolocation,
    permissions,
    timezone,
    locale,
    useragent,
    device,
    device_list,
    # Phase 4: Auth & HTTP (2)
    credentials,
    headers,
    # Phase 4: Script injection (3)
    add_init_script,
    add_script,
    add_style,
    # Phase 4: Advanced element ops (5)
    highlight,
    set_checked,
    select_all,
    multi_select,
    nth,
    # Phase 4: Clipboard (1)
    clipboard,
    # Phase 4: Mouse extras (3)
    mouse_click,
    mouse_dblclick,
    wheel,
    # Phase 4: Touch (1)
    tap,
    # Phase 4: Browser window (2)
    bring_to_front,
    window_new,
    # Phase 4: Tracing & Recording (7)
    trace_start,
    trace_stop,
    har_start,
    har_stop,
    video_path,
    recording_start,
    recording_stop,
    # Phase 4: Advanced JS (3)
    eval_handle,
    expose,
    pause_page,
    # Phase 4: Confirmation (2)
    confirm,
    deny,
    # Phase 4: Visual diff (3)
    diff_screenshot,
    diff_snapshot,
    diff_url,
    # Phase 4: State management extras (5)
    state_list,
    state_show,
    state_delete,
    state_rename,
    state_clear,
    # Phase 4: Input injection (3)
    input_keyboard,
    input_mouse,
    input_touch,
    # Phase 4: Network extras (3)
    response_body,
    screencast_start,
    screencast_stop,
    # Phase 4: Profiler (2)
    profiler_start,
    profiler_stop,
    # Phase 4: Misc (2)
    insert_text,
    set_value,
    # Phase 4 gap: Final 10
    styles,
    state_clean,
    wait_for_download,
    swipe,
    recording_restart,
    auth_save,
    auth_list,
    auth_show,
    auth_delete,
    auth_login
}

# Phase 5: Composite walkers (8) - multi-step automation patterns
import from jac_browser.composites {
    login,
    fill_form,
    scrape,
    paginate,
    smart_click,
    crawl,
    retry,
    observe
}


with entry {
    print("jac-browser: Ready. 153 walkers loaded (145 primitive + 8 composite).");
}
