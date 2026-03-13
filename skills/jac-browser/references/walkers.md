# Walker Reference - jac_browser

Complete reference for all 145 walkers in `jac_browser.walkers`.

## Navigation

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `launch` | `headless: bool = True` | `{success, session_id, page_id}` |
| `navigate` | `url: str` | `{success, url, title}` |
| `go_back` | - | `{success}` |
| `go_forward` | - | `{success}` |
| `reload` | - | `{success}` |
| `close_browser` | - | `{success, closed}` |

## Snapshot & Observation

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `snapshot` | - | `{success, snapshot, refs, origin}` |
| `get_title` | - | `{success, title}` |
| `get_url` | - | `{success, url}` |
| `get_text` | `selector: str` | `{success, text, selector}` |
| `inner_html` | `selector: str` | `{success, html, selector}` |
| `get_html_content` | - | `{success, html}` |
| `get_attribute` | `selector: str, attribute: str` | `{success, value, attribute, selector}` |
| `get_value` | `selector: str` | `{success, value, selector}` |
| `element_count` | `selector: str` | `{success, count, selector}` |
| `bounding_box` | `selector: str` | `{success, box, selector}` |
| `is_visible` | `selector: str` | `{success, visible, selector}` |
| `is_enabled` | `selector: str` | `{success, enabled, selector}` |
| `is_checked` | `selector: str` | `{success, checked, selector}` |

## Interaction

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `click` | `selector: str = "", ref: str = ""` | `{success, clicked, url}` |
| `fill` | `selector: str = "", ref: str = "", value: str = ""` | `{success, filled, value}` |
| `type_text` | `selector: str = "", ref: str = "", text: str = ""` | `{success, typed}` |
| `select_option` | `selector: str = "", value: str = ""` | `{success, selected, selector}` |
| `check_element` | `selector: str = ""` | `{success, checked}` |
| `uncheck_element` | `selector: str = ""` | `{success, unchecked}` |
| `hover` | `selector: str = ""` | `{success, hovered}` |
| `focus` | `selector: str = ""` | `{success, focused}` |
| `scroll` | `direction: str = "down", amount: int = 300, selector: str = ""` | `{success}` |
| `drag_and_drop` | `source: str = "", target: str = ""` | `{success}` |

## Keyboard & Mouse

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `press_key` | `key: str = ""` | `{success, key}` |
| `key_down` | `key: str = ""` | `{success}` |
| `key_up` | `key: str = ""` | `{success}` |
| `mouse_move` | `x: int = 0, y: int = 0` | `{success}` |
| `mouse_down` | `button: str = "left"` | `{success}` |
| `mouse_up` | `button: str = "left"` | `{success}` |
| `mouse_wheel` | `delta_x: int = 0, delta_y: int = 0` | `{success}` |
| `triple_click` | `selector: str = ""` | `{success}` |
| `tap` | `selector: str = ""` | `{success}` |
| `swipe` | `direction: str = "up", distance: int = 300` | `{success}` |

## Screenshots & Capture

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `screenshot` | `full_page: bool = False, selector: str = ""` | `{success, base64, format}` |
| `pdf` | `path: str = ""` | `{success, path}` |
| `screencast_start` | - | `{success}` |
| `screencast_stop` | - | `{success}` |
| `response_body` | `url: str = ""` | `{success, body}` |

## Waiting

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `wait_for` | `selector: str = "", state: str = "visible", timeout: int = 30000` | `{success, selector, state}` |
| `wait_for_url` | `url: str = ""` | `{success, url}` |
| `wait_for_load_state` | `state: str = "load"` | `{success, state}` |
| `wait_for_function` | `expression: str = ""` | `{success}` |
| `wait_for_download` | `path: str = ""` | `{success}` |

## Cookies & Storage

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `cookies_get` | `url: str = ""` | `{success, cookies}` |
| `cookies_set` | `cookies: list = []` | `{success, set}` |
| `cookies_clear` | - | `{success}` |
| `storage_get` | `key: str = "", storage_type: str = "local"` | `{success, key, value}` or `{success, data}` |
| `storage_set` | `key: str = "", value: str = "", storage_type: str = "local"` | `{success, set, key}` |
| `storage_clear` | `storage_type: str = "local"` | `{success}` |

## State Management

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `state_save` | `path: str = ""` | `{success, path}` |
| `state_load` | `path: str = ""` | `{success, loaded, path, page_id}` |
| `state_list` | `directory: str = "."` | `{success, files, count}` |
| `state_show` | `path: str = ""` | `{success, ...}` |
| `state_delete` | `path: str = ""` | `{success}` |
| `state_rename` | `old_path: str = "", new_path: str = ""` | `{success}` |
| `state_clear` | `prefix: str = ""` | `{success}` |
| `state_clean` | `days: int = 7` | `{success}` |

## Dialog Handling

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `dialog` | `response: str = "accept", prompt_text: str = ""` | `{success, handler, response}` |
| `confirm` | - | `{success, handler}` |
| `deny` | - | `{success, handler}` |

## Network

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `route` | `url: str = "", action: str = "block"` | `{success}` |
| `unroute` | `url: str = ""` | `{success}` |
| `get_requests` | - | `{success, requests}` |

## Tabs & Frames

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `new_tab` | `url: str = ""` | `{success, page_id}` |
| `switch_tab` | `page_id: str = ""` | `{success}` |
| `close_tab` | `page_id: str = ""` | `{success}` |
| `list_tabs` | - | `{success, tabs}` |
| `switch_frame` | `selector: str = ""` | `{success}` |
| `switch_main_frame` | - | `{success}` |

## Page Configuration

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `set_viewport` | `width: int = 1280, height: int = 720` | `{success}` |
| `set_content` | `html: str = ""` | `{success, set}` |
| `set_media` | `media: str = ""` | `{success}` |
| `set_offline` | `offline: bool = True` | `{success}` |
| `set_headers` | `headers: dict = {}` | `{success}` |
| `device` | `device_name: str = ""` | `{success, note, device}` |
| `geolocation` | `latitude: float = 0.0, longitude: float = 0.0` | `{success}` |
| `timezone` | `timezone_id: str = ""` | `{success}` |

## JavaScript

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `evaluate` | `script: str = ""` | `{success, result}` |
| `eval_handle` | `script: str = ""` | `{success, result}` |
| `add_init_script` | `script: str = ""` | `{success}` |
| `add_script_tag` | `url: str = "", content: str = ""` | `{success}` |
| `add_style_tag` | `url: str = "", content: str = ""` | `{success}` |
| `expose_function` | `name: str = "", script: str = ""` | `{success}` |

## Semantic Locators

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `get_by_text` | `text: str = "", exact: bool = False` | `{success, text}` |
| `get_by_role` | `role: str = "", name: str = ""` | `{success}` |
| `get_by_label` | `label: str = ""` | `{success}` |
| `get_by_placeholder` | `placeholder: str = ""` | `{success}` |
| `get_by_alt` | `alt: str = ""` | `{success}` |
| `get_by_title` | `title: str = ""` | `{success}` |
| `get_by_test_id` | `test_id: str = ""` | `{success}` |

## Visual Diff

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `diff_snapshot` | `snapshot1: str = "", snapshot2: str = ""` | `{success, match, snapshot1_len, snapshot2_len}` |
| `diff_screenshot` | `selector1: str = "", selector2: str = ""` | `{success, diff}` |
| `diff_url` | `expected_url: str = ""` | `{success, match, current, expected}` |

## Tracing & Profiling

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `trace_start` | `name: str = ""` | `{success, tracing}` |
| `trace_stop` | `path: str = ""` | `{success, tracing, path}` |
| `profiler_start` | `categories: str = ""` | `{success}` |
| `profiler_stop` | `path: str = ""` | `{success, path}` |

## Console & Errors

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `console_get` | `do_clear: bool = False` | `{success, messages}` or `{success, cleared}` |
| `errors` | - | `{success, errors}` |

## Auth Vault

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `auth_save` | `name, url, username, password, username_selector, password_selector, submit_selector` | `{success}` |
| `auth_login` | `name: str = ""` | `{success}` |
| `auth_list` | - | `{success, profiles}` |
| `auth_show` | `name: str = ""` | `{success}` |
| `auth_delete` | `name: str = ""` | `{success}` |

## Advanced Elements

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `highlight` | `selector: str = ""` | `{success}` |
| `nth_element` | `selector: str = "", index: int = 0` | `{success}` |
| `multi_select` | `selector: str = "", values: list = []` | `{success}` |
| `get_computed_styles` | `selector: str = "", properties: list = []` | `{success}` |
| `clipboard_read` | - | `{success, text}` |
| `clipboard_write` | `text: str = ""` | `{success}` |

## File Operations

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `upload_file` | `selector: str = "", path: str = ""` | `{success}` |
| `download` | `selector: str = "", path: str = ""` | `{success}` |

## Recording

| Walker | Parameters | Returns |
|--------|-----------|---------|
| `recording_start` | - | `{success, note}` |
| `recording_stop` | - | `{success, note}` |
| `har_start` | `path: str = ""` | `{success}` |
| `har_stop` | - | `{success}` |
