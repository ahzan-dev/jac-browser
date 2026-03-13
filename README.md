# jac-browser

Headless browser automation for Jac -- 145 walkers wrapping Playwright.

`jac-browser` is a pure-Jac library that gives AI agents and Jac applications full browser control through graph-native walkers. Every browser action (navigate, click, fill, screenshot, etc.) is a walker that traverses a session graph and reports results as JSON.

## Installation

```bash
pip install jac-browser
playwright install chromium
```

**Requirements:** Python 3.11+, jaclang >= 0.6.1, Playwright >= 1.40.0

## Quick Start

### As a Jac Server (REST API)

```bash
# Start the server
jac serve jac_browser/main.jac

# Launch a headless browser
curl -X POST localhost:8000/walker/launch \
  -H 'Content-Type: application/json' \
  -d '{"headless": true}'

# Navigate to a URL
curl -X POST localhost:8000/walker/navigate \
  -H 'Content-Type: application/json' \
  -d '{"url": "https://example.com"}'

# Take an ARIA snapshot (returns accessibility tree + element refs)
curl -X POST localhost:8000/walker/snapshot \
  -H 'Content-Type: application/json' -d '{}'

# Click an element by ref (from snapshot)
curl -X POST localhost:8000/walker/click \
  -H 'Content-Type: application/json' \
  -d '{"selector": "e3"}'

# Take a screenshot
curl -X POST localhost:8000/walker/screenshot \
  -H 'Content-Type: application/json' -d '{}'

# Close the browser
curl -X POST localhost:8000/walker/close_browser \
  -H 'Content-Type: application/json' -d '{}'
```

### As a Jac Library

```jac
import from jac_browser.walkers {launch, navigate, snapshot, click, close_browser}

with entry {
    # Launch headless browser
    root spawn launch(headless=True);

    # Navigate and interact
    root spawn navigate(url="https://example.com");

    # Get accessibility snapshot with element refs
    w = root spawn snapshot();
    print(w.reports[0]);

    # Click using ref from snapshot
    root spawn click(selector="e1");

    # Clean up
    root spawn close_browser();
}
```

## Architecture

```
Root
 |
 +--> BrowserSession (id, headless, is_launched)
       |
       +--> PageNode (page_id, url, title, is_active)
       |     |
       |     +--> SnapshotNode (tree, ref_map, taken_at)
       |           |
       |           +--> ElementRef (ref_id, role, name, selector)
       |           +--> ElementRef ...
       |
       +--> PageNode (tab 2) ...
```

**Thread-safe bridge:** All Playwright calls run on a dedicated background thread via `PlaywrightBridge`, avoiding conflicts with Jac's asyncio event loop. The bridge uses a Queue-based worker pattern where `_exec(_do_*, args)` submits work and blocks until completion.

**ARIA snapshot refs:** The `snapshot` walker generates an accessibility tree and assigns refs (`e1`, `e2`, ...) to interactive elements. These refs map to Playwright locators, enabling efficient element targeting without CSS selectors.

## Walker Reference

All walkers are public (`:pub`) and report JSON results with `{"success": true/false, ...}`.

### Core (10)

| Walker | Fields | Description |
|--------|--------|-------------|
| `launch` | `headless: bool = True` | Launch browser, create session + first page |
| `navigate` | `url: str` | Navigate active page to URL |
| `snapshot` | -- | Take ARIA accessibility snapshot, returns tree + ref_map |
| `click` | `selector: str` | Click element (supports refs like "e3" or CSS selectors) |
| `fill` | `selector: str, value: str` | Clear and fill an input field |
| `type_text` | `selector: str, text: str, delay: int = 0` | Type text character by character |
| `screenshot` | `path: str = "", full_page: bool = False` | Take screenshot, returns base64 |
| `scroll` | `x: int = 0, y: int = 0, direction: str = "down", amount: int = 3` | Scroll the page |
| `get_text` | `selector: str` | Get text content of an element |
| `close_browser` | -- | Close browser and clean up session |

### Navigation (5)

| Walker | Fields | Description |
|--------|--------|-------------|
| `back` | -- | Go back in browser history |
| `forward` | -- | Go forward in browser history |
| `reload` | `wait_until: str = "load"` | Reload current page |
| `get_url` | -- | Get current page URL |
| `get_title` | -- | Get current page title |

### Interaction (7)

| Walker | Fields | Description |
|--------|--------|-------------|
| `hover` | `selector: str` | Hover over element |
| `dblclick` | `selector: str` | Double-click element |
| `press` | `selector: str, key: str` | Press keyboard key on element |
| `check_element` | `selector: str` | Check a checkbox |
| `uncheck_element` | `selector: str` | Uncheck a checkbox |
| `select_option` | `selector: str, value: str` | Select dropdown option by value |
| `clear_input` | `selector: str` | Clear an input field |

### Element Queries (4)

| Walker | Fields | Description |
|--------|--------|-------------|
| `get_attribute` | `selector: str, attribute: str` | Get element attribute value |
| `is_visible` | `selector: str` | Check if element is visible |
| `is_enabled` | `selector: str` | Check if element is enabled |
| `is_checked` | `selector: str` | Check if checkbox/radio is checked |

### JavaScript, Waits, Cookies (7)

| Walker | Fields | Description |
|--------|--------|-------------|
| `evaluate` | `script: str` | Execute JavaScript, returns result |
| `wait_for` | `selector: str, state: str = "visible", timeout: int = 30000` | Wait for element state |
| `wait_for_url` | `url: str, timeout: int = 30000` | Wait for URL match |
| `cookies_get` | `url: str = ""` | Get cookies for URL |
| `cookies_set` | `cookies: list = []` | Set cookies |
| `cookies_clear` | -- | Clear all cookies |
| `element_count` | `selector: str` | Count matching elements |

### Tabs (4)

| Walker | Fields | Description |
|--------|--------|-------------|
| `tab_new` | `url: str = ""` | Open new tab, optionally navigate |
| `tab_list` | -- | List all tabs with URLs and active status |
| `tab_switch` | `page_id: str` | Switch to a specific tab |
| `tab_close` | `page_id: str = ""` | Close a tab (default: active tab) |

### Dialog, Upload, Download (6)

| Walker | Fields | Description |
|--------|--------|-------------|
| `dialog` | `action: str = "accept", text: str = ""` | Handle browser dialogs (alert/confirm/prompt) |
| `upload` | `selector: str, files: list = []` | Upload files to file input |
| `download` | `selector: str, save_path: str = ""` | Click to download, returns file path |
| `focus` | `selector: str` | Focus an element |
| `drag` | `source: str, target: str` | Drag from source to target element |
| `scroll_into_view` | `selector: str` | Scroll element into viewport |

### Storage (3)

| Walker | Fields | Description |
|--------|--------|-------------|
| `storage_get` | `key: str = "", storage_type: str = "local"` | Get localStorage/sessionStorage value |
| `storage_set` | `key: str, value: str, storage_type: str = "local"` | Set storage value |
| `storage_clear` | `storage_type: str = "local"` | Clear storage |

### Console & Errors (2)

| Walker | Fields | Description |
|--------|--------|-------------|
| `console_get` | -- | Get captured console messages |
| `errors_get` | -- | Get captured page errors |

### Content Inspection (6)

| Walker | Fields | Description |
|--------|--------|-------------|
| `inner_text` | `selector: str` | Get inner text of element |
| `inner_html` | `selector: str` | Get inner HTML of element |
| `input_value` | `selector: str` | Get current value of input element |
| `bounding_box` | `selector: str` | Get element bounding box (x, y, width, height) |
| `get_html_content` | `selector: str = "html"` | Get outer HTML of element |
| `dispatch_event` | `selector: str, event_type: str, event_init: dict = {}` | Dispatch DOM event |

### Mouse, Keyboard, Network (11)

| Walker | Fields | Description |
|--------|--------|-------------|
| `mouse_move` | `x: int, y: int` | Move mouse to coordinates |
| `mouse_down` | `button: str = "left"` | Press mouse button down |
| `mouse_up` | `button: str = "left"` | Release mouse button |
| `keyboard` | `action: str, key: str = "", text: str = ""` | Keyboard action (press/down/up/type) |
| `key_down` | `key: str` | Press key down |
| `key_up` | `key: str` | Release key |
| `route` | `url_pattern: str, handler_type: str = "abort"` | Intercept network requests |
| `unroute` | `url_pattern: str` | Remove network route |
| `requests_get` | -- | Get captured network requests |
| `wait_for_load_state` | `state: str = "load"` | Wait for page load state |
| `wait_for_function` | `expression: str, timeout: int = 30000` | Wait for JS expression to be truthy |

### Page Config & State (6)

| Walker | Fields | Description |
|--------|--------|-------------|
| `viewport` | `width: int, height: int` | Set viewport size |
| `set_content` | `html: str` | Set page HTML content |
| `emulate_media` | `media: str = "", color_scheme: str = ""` | Emulate media type/color scheme |
| `offline` | `enabled: bool = True` | Toggle offline mode |
| `state_save` | `name: str = "default"` | Save browser state (cookies + storage) |
| `state_load` | `name: str = "default"` | Load saved browser state |

### Frames (2)

| Walker | Fields | Description |
|--------|--------|-------------|
| `frame` | `name: str = "", url: str = ""` | Switch to iframe by name or URL |
| `mainframe` | -- | Switch back to main frame |

### Semantic Locators (7)

| Walker | Fields | Description |
|--------|--------|-------------|
| `get_by_text` | `text: str, exact: bool = False` | Find element by text content |
| `get_by_role` | `role: str, name: str = ""` | Find element by ARIA role |
| `get_by_label` | `text: str, exact: bool = False` | Find element by label text |
| `get_by_placeholder` | `text: str, exact: bool = False` | Find element by placeholder text |
| `get_by_alt_text` | `text: str, exact: bool = False` | Find element by alt text |
| `get_by_title` | `text: str, exact: bool = False` | Find element by title attribute |
| `get_by_test_id` | `test_id: str` | Find element by data-testid |

### PDF (1)

| Walker | Fields | Description |
|--------|--------|-------------|
| `pdf` | `path: str = "", format: str = "Letter", landscape: bool = False` | Generate PDF of page |

### Emulation (7)

| Walker | Fields | Description |
|--------|--------|-------------|
| `geolocation` | `latitude: float, longitude: float, accuracy: float = 0.0` | Set geolocation |
| `permissions` | `permissions_list: list = [], origin: str = ""` | Grant browser permissions |
| `timezone` | `tz: str` | Set timezone (informational) |
| `locale` | `loc: str` | Set locale (informational) |
| `useragent` | `ua: str` | Set user agent string |
| `device` | `name: str` | Emulate device viewport + user agent |
| `device_list` | -- | List available device presets |

### Auth & HTTP (2)

| Walker | Fields | Description |
|--------|--------|-------------|
| `credentials` | `username: str, password: str` | Set HTTP authentication credentials |
| `headers` | `headers_dict: dict = {}` | Set extra HTTP headers |

### Script Injection (3)

| Walker | Fields | Description |
|--------|--------|-------------|
| `add_init_script` | `script: str` | Add script to run on every navigation |
| `add_script` | `url: str = "", content: str = ""` | Inject script tag |
| `add_style` | `url: str = "", content: str = ""` | Inject style tag |

### Advanced Element Ops (5)

| Walker | Fields | Description |
|--------|--------|-------------|
| `highlight` | `selector: str` | Highlight element with red border |
| `set_checked` | `selector: str, checked: bool = True` | Set checkbox/radio state |
| `select_all` | `selector: str` | Select all text in input |
| `multi_select` | `selector: str, values: list = []` | Select multiple options in multi-select |
| `nth` | `selector: str, index: int = 0` | Get nth matching element's text |

### Clipboard (1)

| Walker | Fields | Description |
|--------|--------|-------------|
| `clipboard` | `action: str = "read", text: str = ""` | Read/write clipboard |

### Mouse Extras (3)

| Walker | Fields | Description |
|--------|--------|-------------|
| `mouse_click` | `x: int, y: int, button: str = "left"` | Click at coordinates |
| `mouse_dblclick` | `x: int, y: int` | Double-click at coordinates |
| `wheel` | `delta_x: int = 0, delta_y: int = 0` | Scroll with mouse wheel |

### Touch (1)

| Walker | Fields | Description |
|--------|--------|-------------|
| `tap` | `selector: str` | Tap element (touch event) |

### Browser Window (2)

| Walker | Fields | Description |
|--------|--------|-------------|
| `bring_to_front` | -- | Bring page to front |
| `window_new` | `url: str = ""` | Open new browser window |

### Tracing & Recording (7)

| Walker | Fields | Description |
|--------|--------|-------------|
| `trace_start` | `name: str = "trace"` | Start Playwright tracing |
| `trace_stop` | `path: str = "trace.zip"` | Stop tracing, save to file |
| `har_start` | `path: str = "network.har"` | Start HAR recording |
| `har_stop` | -- | Stop HAR recording |
| `video_path` | -- | Get path to page video recording |
| `recording_start` | `path: str = ""` | Start recording session actions |
| `recording_stop` | -- | Stop recording, returns actions |

### Advanced JS (3)

| Walker | Fields | Description |
|--------|--------|-------------|
| `eval_handle` | `script: str` | Evaluate JS, returns handle info |
| `expose` | `name: str` | Expose a function to page JS |
| `pause_page` | -- | Pause page execution (Playwright inspector) |

### Confirmation (2)

| Walker | Fields | Description |
|--------|--------|-------------|
| `confirm` | -- | Pre-accept next confirm dialog |
| `deny` | -- | Pre-deny next confirm dialog |

### Visual Diff (3)

| Walker | Fields | Description |
|--------|--------|-------------|
| `diff_screenshot` | `path1: str, path2: str` | Compare two screenshot files |
| `diff_snapshot` | `snap1: str = "", snap2: str = ""` | Compare two ARIA snapshots |
| `diff_url` | `url1: str, url2: str` | Navigate to two URLs and diff their snapshots |

### State Management (5)

| Walker | Fields | Description |
|--------|--------|-------------|
| `state_list` | -- | List all saved states |
| `state_show` | `name: str` | Show saved state contents |
| `state_delete` | `name: str` | Delete a saved state |
| `state_rename` | `old_name: str, new_name: str` | Rename a saved state |
| `state_clear` | -- | Delete all saved states |

### Input Injection (3)

| Walker | Fields | Description |
|--------|--------|-------------|
| `input_keyboard` | `keys: list = []` | Inject sequence of key events |
| `input_mouse` | `actions: list = []` | Inject sequence of mouse events |
| `input_touch` | `actions: list = []` | Inject touch events (informational) |

### Network Extras (3)

| Walker | Fields | Description |
|--------|--------|-------------|
| `response_body` | `url_pattern: str` | Get response body for URL |
| `screencast_start` | `options: dict = {}` | Start screencast (informational) |
| `screencast_stop` | -- | Stop screencast (informational) |

### Profiler (2)

| Walker | Fields | Description |
|--------|--------|-------------|
| `profiler_start` | -- | Start profiler (informational) |
| `profiler_stop` | -- | Stop profiler (informational) |

### Misc (2)

| Walker | Fields | Description |
|--------|--------|-------------|
| `insert_text` | `selector: str, text: str` | Insert text at cursor position |
| `set_value` | `selector: str, value: str` | Set input value via JavaScript |

### Final (10)

| Walker | Fields | Description |
|--------|--------|-------------|
| `styles` | `selector: str, properties: list = []` | Get computed CSS styles |
| `state_clean` | -- | Remove all saved state files and clear in-memory state |
| `wait_for_download` | `selector: str, save_path: str = ""` | Click and wait for download |
| `swipe` | `selector: str, direction: str = "up", distance: int = 200` | Swipe gesture via mouse drag |
| `recording_restart` | `path: str = ""` | Stop and restart recording |
| `auth_save` | `name: str, url: str = "", username: str = "", password: str = ""` | Save auth profile |
| `auth_list` | -- | List saved auth profiles |
| `auth_show` | `name: str` | Show auth profile details |
| `auth_delete` | `name: str` | Delete auth profile |
| `auth_login` | `name: str` | Apply saved auth credentials to browser |

## Composite Walkers (8)

Multi-step automation patterns unique to jac-browser. These combine multiple primitive operations into single, higher-level walkers.

| Walker | Fields | Description |
|--------|--------|-------------|
| `login` | `url, username_selector, password_selector, username, password, submit_selector, save_state_path` | Navigate to login page, fill credentials, submit, optionally save state |
| `fill_form` | `fields: dict, checks: list, selects: dict, submit_selector` | Fill multiple form fields, check boxes, select dropdowns in one call |
| `scrape` | `url, extract_script, wait_selector, include_screenshot` | Navigate, wait, extract data via JS, optionally screenshot |
| `paginate` | `url, extract_script, next_selector, max_pages, wait_state` | Extract data across multiple pages by clicking "next" |
| `smart_click` | `text, role, index` | Find element by text/role from snapshot, click it (no selector needed) |
| `crawl` | `url, link_pattern, extract_script, max_pages, max_depth` | Follow links matching a regex, extract data from each page |
| `retry` | `script, retries, delay_ms` | Evaluate JS expression with retries until it returns truthy |
| `observe` | `include_screenshot, include_html` | Combined snapshot + screenshot + metadata in one call |

### Composite Walker Examples

```jac
import from jac_browser.composites {login, scrape, paginate, smart_click, observe}

with entry {
    root spawn launch(headless=True);

    # Login in one call
    root spawn login(
        url="https://example.com/login",
        username="user", password="pass",
        save_state_path="/tmp/auth.json"
    );

    # Click by text, not CSS selector
    root spawn smart_click(text="Dashboard", role="link");

    # Scrape structured data
    w = root spawn scrape(
        url="https://example.com/data",
        extract_script="Array.from(document.querySelectorAll('tr')).map(r => r.textContent)"
    );

    # Paginate automatically
    w = root spawn paginate(
        url="https://example.com/list",
        extract_script="Array.from(document.querySelectorAll('.item')).map(e => e.textContent)",
        next_selector=".next-page",
        max_pages=5
    );

    # Full page observation for AI agents
    w = root spawn observe(include_screenshot=True);
    print(w.reports[0]["snapshot"]);

    root spawn close_browser();
}
```

## Usage Patterns

### AI Agent Loop (Snapshot-Ref Cycle)

The primary pattern for AI agents:

```jac
import from jac_browser.walkers {launch, navigate, snapshot, click, fill, close_browser}

with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://example.com/form");

    # 1. Take snapshot to see the page
    w = root spawn snapshot();
    snap = w.reports[0];
    # snap["tree"] = ARIA accessibility tree
    # snap["ref_map"] = {"e1": {"role": "link", "name": "Home"}, "e2": ...}

    # 2. Use refs to interact (AI picks the right ref)
    root spawn click(selector="e3");
    root spawn fill(selector="e5", value="hello@example.com");

    # 3. Re-snapshot to see updated state
    w2 = root spawn snapshot();

    root spawn close_browser();
}
```

### Multi-Tab Workflow

```jac
import from jac_browser.walkers {launch, navigate, tab_new, tab_list, tab_switch, tab_close, close_browser}

with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://example.com");

    # Open a second tab
    root spawn tab_new(url="https://google.com");

    # List all tabs
    w = root spawn tab_list();
    tabs = w.reports[0]["tabs"];

    # Switch back to first tab
    root spawn tab_switch(page_id=tabs[0]["page_id"]);

    # Close the second tab
    root spawn tab_close(page_id=tabs[1]["page_id"]);

    root spawn close_browser();
}
```

### Save and Restore State

```jac
import from jac_browser.walkers {launch, navigate, state_save, state_load, close_browser}

with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://example.com");

    # Save cookies + storage
    root spawn state_save(name="logged-in");

    root spawn close_browser();

    # Later: restore state
    root spawn launch(headless=True);
    root spawn state_load(name="logged-in");
    # Cookies and storage are restored
}
```

### Network Interception

```jac
import from jac_browser.walkers {launch, navigate, route, unroute, close_browser}

with entry {
    root spawn launch(headless=True);

    # Block images
    root spawn route(url_pattern="**/*.png", handler_type="abort");
    root spawn route(url_pattern="**/*.jpg", handler_type="abort");

    root spawn navigate(url="https://example.com");

    # Remove routes
    root spawn unroute(url_pattern="**/*.png");

    root spawn close_browser();
}
```

## Using with jac serve (REST API)

Start the Jac server:

```bash
jac serve jac_browser/main.jac
```

All 145 walkers are available as POST endpoints at `localhost:8000/walker/<walker_name>`. Walker fields become JSON body parameters.

```bash
# Launch browser
curl -X POST localhost:8000/walker/launch -H 'Content-Type: application/json' -d '{"headless": true}'

# Navigate
curl -X POST localhost:8000/walker/navigate -H 'Content-Type: application/json' -d '{"url": "https://example.com"}'

# Snapshot
curl -X POST localhost:8000/walker/snapshot -H 'Content-Type: application/json' -d '{}'

# Click by ref
curl -X POST localhost:8000/walker/click -H 'Content-Type: application/json' -d '{"selector": "e1"}'

# Fill input
curl -X POST localhost:8000/walker/fill -H 'Content-Type: application/json' -d '{"selector": "e5", "value": "test"}'

# Screenshot
curl -X POST localhost:8000/walker/screenshot -H 'Content-Type: application/json' -d '{"full_page": true}'

# Close
curl -X POST localhost:8000/walker/close_browser -H 'Content-Type: application/json' -d '{}'
```

## Examples

The `examples/` directory contains 31 complete Jac applications covering every use case:

```bash
jac run examples/01_hello_browser.jac      # Basic launch, navigate, snapshot
jac run examples/02_form_automation.jac     # Fill forms, checkboxes, dropdowns
jac run examples/03_web_scraping.jac        # Extract text, HTML, attributes
jac run examples/04_screenshot_pdf.jac      # Screenshots and PDF generation
jac run examples/05_multi_tab.jac           # Tab management
jac run examples/06_keyboard_mouse.jac      # Low-level input control
jac run examples/07_network_intercept.jac   # Block, mock, log requests
jac run examples/08_state_management.jac    # Save/load cookies and storage
jac run examples/09_semantic_locators.jac   # Find elements by role, text, label
jac run examples/10_device_emulation.jac    # Mobile, geolocation, timezone
jac run examples/11_dialog_handling.jac     # Alert, confirm, prompt dialogs
jac run examples/12_file_upload_download.jac # Upload and download files
jac run examples/13_iframe_frames.jac       # Work with iframes
jac run examples/14_tracing_recording.jac   # Playwright traces, HAR, recording
jac run examples/15_visual_diff.jac         # Compare screenshots and snapshots
jac run examples/16_console_errors.jac      # Monitor console and JS errors
jac run examples/17_auth_vault.jac          # Save and manage auth profiles
jac run examples/18_script_injection.jac    # Inject JavaScript and CSS
jac run examples/19_advanced_elements.jac   # Highlight, nth, multi-select
jac run examples/20_ai_agent_loop.jac       # AI agent snapshot-ref cycle
jac run examples/21_page_config.jac         # Viewport, offline, media emulation
jac run examples/22_clipboard_touch.jac     # Clipboard, touch, drag, swipe
jac run examples/23_advanced_js.jac         # eval_handle, expose, wait functions
jac run examples/24_profiler_screencast.jac # Performance profiling
jac serve examples/25_rest_api_server.jac   # REST API server (all 145 walkers)
jac run examples/26_headed_mode.jac         # Visible browser for debugging
jac run examples/27_session_persistence.jac # Save/load login state across runs
jac run examples/28_real_world_scraper.jac  # Multi-page scraping with pagination
jac run examples/29_multi_step_form.jac     # Multi-step form wizard
jac run examples/30_visual_regression.jac   # Visual regression testing
jac run examples/31_composite_walkers.jac  # Multi-step composite walkers
```

See [`examples/README.md`](examples/README.md) for the full walker coverage table.

## Documentation

Detailed guides are in the [`docs/`](docs/) directory:

- [Getting Started](docs/getting-started.md) -- Installation, first program, core concepts
- [Tutorials](docs/tutorials.md) -- 10 step-by-step guides (scraping, forms, screenshots, state, tabs, headed mode, AI agent loop, network interception, device emulation, visual regression)
- [Composite Walkers](docs/composite-walkers.md) -- 8 multi-step walkers unique to jac-browser (login, scrape, paginate, crawl, etc.)
- [Jac Syntax Guide](docs/jac-syntax-guide.md) -- Jac language patterns and common gotchas
- [REST API Reference](docs/api-reference.md) -- Using jac-browser as an HTTP API with `jac serve`
- [Architecture](docs/architecture.md) -- How jac-browser works (session graph, thread-safe bridge, ARIA snapshots)
- [Troubleshooting](docs/troubleshooting.md) -- Common errors and fixes

## Testing

```bash
# Run the integration test suite
cd jac-browser
jac test browser_test.jac -v
```

The test suite covers all 145 walkers across three test blocks (Phase 2 core, Phase 3 features, Phase 4 features) using a local HTML fixture.

## Project Structure

```
jac-browser/
  pyproject.toml           # Package config
  README.md                # This file
  LICENSE                  # MIT
  jac_browser/             # Python package
    __init__.py            # Lazy jaclang loader
    main.jac               # Entry point, imports all walkers
    browser_bridge.jac     # PlaywrightBridge + all _do_* functions
    walkers.jac            # 145 walker definitions
    helpers.jac            # Shared helper functions
    nodes.jac              # Graph node types
  docs/                    # Documentation
    getting-started.md     # Installation and first program
    tutorials.md           # Step-by-step guides
    jac-syntax-guide.md    # Jac language tips
    api-reference.md       # REST API reference
    architecture.md        # How it works internally
    troubleshooting.md     # Common errors and fixes
  examples/                # 30 example applications
  skills/                  # AI agent skill definitions
    jac-browser/           # Core browser automation skill
    dogfood/               # QA testing skill
    electron/              # Desktop app automation skill
    slack/                 # Slack automation skill
  tests/
    test_page.html         # HTML fixture for integration tests
  browser_test.jac         # Integration test suite
```

## License

MIT
