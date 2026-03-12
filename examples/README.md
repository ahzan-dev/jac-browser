# jac-browser Examples

25 example applications demonstrating all browser automation capabilities.

## Prerequisites

```bash
pip install jac-browser
playwright install chromium
```

## Examples

| # | File | Description | Key Walkers |
|---|------|-------------|-------------|
| 01 | `01_hello_browser.jac` | Launch, navigate, snapshot, close | launch, navigate, snapshot, get_url, get_title, close_browser |
| 02 | `02_form_automation.jac` | Fill forms, check boxes, select dropdowns | fill, type_text, clear_input, check_element, uncheck_element, select_option, press, input_value |
| 03 | `03_web_scraping.jac` | Extract text, HTML, attributes from pages | get_text, inner_text, inner_html, get_html_content, get_attribute, element_count, evaluate, bounding_box |
| 04 | `04_screenshot_pdf.jac` | Screenshots and PDF generation | screenshot, pdf, viewport |
| 05 | `05_multi_tab.jac` | Open, switch, and manage tabs | tab_new, tab_list, tab_switch, tab_close, window_new, bring_to_front |
| 06 | `06_keyboard_mouse.jac` | Low-level keyboard and mouse control | keyboard, key_down, key_up, mouse_move, mouse_click, mouse_dblclick, wheel, scroll, swipe, insert_text, input_keyboard, input_mouse |
| 07 | `07_network_intercept.jac` | Block, mock, and log requests | route, unroute, requests_get |
| 08 | `08_state_management.jac` | Save/load cookies, storage, state files | cookies_set, cookies_get, cookies_clear, storage_set, storage_get, storage_clear, state_save, state_load, state_list, state_show, state_rename, state_delete, state_clear, state_clean |
| 09 | `09_semantic_locators.jac` | Find elements by role, text, label | get_by_text, get_by_role, get_by_label, get_by_placeholder, get_by_alt_text, get_by_title, get_by_test_id |
| 10 | `10_device_emulation.jac` | Mobile devices, geolocation, timezone | device, device_list, geolocation, permissions, timezone, locale, useragent, emulate_media |
| 11 | `11_dialog_handling.jac` | Handle alert, confirm, prompt dialogs | dialog, confirm, deny |
| 12 | `12_file_upload_download.jac` | Upload and download files | upload, download, wait_for_download |
| 13 | `13_iframe_frames.jac` | Execute code inside iframes | frame, mainframe |
| 14 | `14_tracing_recording.jac` | Playwright traces, HAR, action recording | trace_start, trace_stop, har_start, har_stop, recording_start, recording_stop, recording_restart, video_path |
| 15 | `15_visual_diff.jac` | Compare screenshots, snapshots, URLs | diff_screenshot, diff_snapshot, diff_url |
| 16 | `16_console_errors.jac` | Monitor console messages and JS errors | console_get, errors_get |
| 17 | `17_auth_vault.jac` | Save and manage auth profiles | auth_save, auth_list, auth_show, auth_delete, auth_login, credentials, headers |
| 18 | `18_script_injection.jac` | Inject JavaScript and CSS | add_init_script, add_script, add_style |
| 19 | `19_advanced_elements.jac` | Highlight, nth, multi-select, styles | highlight, nth, set_checked, select_all, multi_select, styles, set_value, dispatch_event |
| 20 | `20_ai_agent_loop.jac` | AI agent snapshot-ref cycle pattern | snapshot (ref_map), click (by ref), fill (by ref) |
| 21 | `21_page_config.jac` | Viewport, content, media, offline mode | viewport, set_content, emulate_media, offline, wait_for_load_state |
| 22 | `22_clipboard_touch.jac` | Clipboard, touch, drag-and-drop, swipe | clipboard, tap, drag, swipe |
| 23 | `23_advanced_js.jac` | eval_handle, expose, wait functions | evaluate, eval_handle, expose, pause_page, wait_for, wait_for_url, wait_for_function |
| 24 | `24_profiler_screencast.jac` | Performance profiling and screen capture | profiler_start, profiler_stop, screencast_start, screencast_stop, response_body |
| 25 | `25_rest_api_server.jac` | Use jac-browser as a REST API | All walkers via `jac serve` |

## Running Examples

```bash
# Run any example
cd jac-browser
jac run examples/01_hello_browser.jac

# Run the REST API server
jac serve examples/25_rest_api_server.jac
```

## Walker Coverage

These 25 examples collectively demonstrate all 145 walkers across every category:
core navigation, form interaction, content extraction, screenshots/PDF, tabs,
keyboard/mouse, network interception, state management, semantic locators,
device emulation, dialogs, file I/O, iframes, tracing, visual diff, console
monitoring, auth vault, script injection, advanced elements, AI agent patterns,
page configuration, clipboard/touch, advanced JS, profiling, and REST API usage.
