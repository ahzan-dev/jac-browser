# Architecture

How jac-browser works under the hood.

## Overview

jac-browser is a pure-Jac library that wraps Playwright for browser automation. It uses Jac's graph-native walker pattern, where browser actions are walkers that traverse a session graph and report results as JSON.

```
Your Jac Code
     |
     v
  Walkers (145 public walkers in walkers.jac)
     |
     v
  PlaywrightBridge (browser_bridge.jac)
     |
     v
  Playwright (Python, runs on background thread)
     |
     v
  Chromium Browser (headless or headed)
```

## Session Graph

When you call `launch()`, jac-browser creates a graph structure:

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

- **BrowserSession**: One per browser instance. Tracks whether the browser is launched and its headless mode.
- **PageNode**: One per tab/page. Tracks the URL, title, and whether this is the active tab.
- **SnapshotNode**: Created by the `snapshot` walker. Stores the ARIA accessibility tree and element refs.
- **ElementRef**: Individual interactive elements from a snapshot. Each has a ref ID (e1, e2, ...) that maps to a Playwright locator.

## Thread-Safe Bridge

Playwright requires all API calls to run on the same thread. Since Jac uses asyncio, jac-browser solves this with a **background thread worker pattern**:

```
Jac Event Loop (main thread)
     |
     | _exec(_do_navigate, url)
     |      |
     |      +----> Queue -----> Worker Thread
     |                              |
     |                              v
     |                         Playwright API
     |                              |
     |      <---- Result -----------+
     |
     v
  Continue execution
```

The `PlaywrightBridge` class manages this:

1. `_exec(fn, *args)` puts work onto a queue and blocks the calling thread
2. A dedicated worker thread picks up the work and calls the Playwright API
3. The result (or exception) is passed back via a future/event
4. The calling code resumes with the result

This means all 145 walkers are thread-safe and can be used from any context.

## ARIA Snapshot System

The `snapshot` walker is the primary way to "see" a page. It generates an ARIA accessibility tree, similar to what a screen reader would see:

```
- heading "Quotes to Scrape" [level=1]:
  - link [e1] "Quotes to Scrape":
    - /url: /
- paragraph:
  - link [e2] "Login":
    - /url: /login
- text: "The world as we have created it..."
- link [e3] "(about)":
  - /url: /author/Albert-Einstein
```

Each interactive element gets a **ref** (`e1`, `e2`, `e3`, ...) that maps to a Playwright locator. This enables:

- AI agents to "see" the page structure without parsing HTML
- Efficient element targeting without CSS selectors
- Consistent identification across page changes

Refs are invalidated when the page changes (navigation, DOM mutations). Always re-snapshot after actions that modify the page.

## Walker Pattern

All 145 walkers follow the same pattern:

```jac
walker some_action :pub: {
    has param1: str = "";
    has param2: int = 0;

    can action with `root entry {
        # 1. Get the browser bridge
        bridge = _get_bridge();

        # 2. Call the bridge function
        result = bridge._exec(bridge._do_some_action, self.param1, self.param2);

        # 3. Report the result as JSON
        report result;
    }
}
```

Usage:

```jac
w = root spawn some_action(param1="value", param2=42);
result = w.reports[0];  # {"success": true, ...}
```

## File Structure

```
jac_browser/
  __init__.py           # Python package init (ensures jaclang is available)
  main.jac              # Entry point, imports and re-exports all walkers
  walkers.jac           # 145 walker definitions
  browser_bridge.jac    # PlaywrightBridge class + all _do_* implementations
  helpers.jac           # Shared utility functions
  nodes.jac             # Graph node type definitions
```

## Data Flow Example

Here's what happens when you run a simple program:

```jac
root spawn launch(headless=True);
root spawn navigate(url="https://example.com");
w = root spawn snapshot();
root spawn click(selector="e1");
root spawn close_browser();
```

1. **`launch`**: Creates a `PlaywrightBridge`, starts background thread, launches Chromium, creates `BrowserSession` and `PageNode` on the graph
2. **`navigate`**: Gets the active `PageNode`, calls `page.goto(url)` via the bridge
3. **`snapshot`**: Calls `page.accessibility.snapshot()`, parses the tree, assigns refs, creates `SnapshotNode` with `ElementRef` children, reports the tree + ref map
4. **`click("e1")`**: Looks up `e1` in the ref map, gets the corresponding Playwright locator, calls `locator.click()`
5. **`close_browser`**: Closes all pages, closes the browser context, stops the background thread, removes graph nodes

## REST API Mode

When you run `jac serve jac_browser/main.jac`, Jac's built-in server exposes every `:pub:` walker as a POST endpoint:

```
POST /walker/launch        -> launch walker
POST /walker/navigate      -> navigate walker
POST /walker/snapshot      -> snapshot walker
POST /walker/click         -> click walker
...
```

Walker `has` fields become JSON body parameters. Walker `report` values become the JSON response. This means the same walkers work both as a library (via `root spawn`) and as an API (via HTTP).
