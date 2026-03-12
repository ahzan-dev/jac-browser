"""Example 23: Advanced JavaScript - eval_handle, expose functions, wait functions.

Demonstrates advanced JavaScript execution: eval_handle for complex return
values, exposing functions to page context, waiting for conditions, and
using wait_for_function.

Usage:
    jac run examples/23_advanced_js.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    set_content,
    evaluate, eval_handle, expose, pause_page,
    wait_for, wait_for_url, wait_for_function, wait_for_load_state
}


with entry {
    root spawn launch(headless=True);

    page_html = "<h1 id='title'>JS Playground</h1><div id='output'>Ready</div><div id='delayed' style='display: none;'>I appeared!</div><button id='btn' onclick=\"setTimeout(function() { document.getElementById('delayed').style.display = 'block'; }, 500);\">Show Delayed</button>";
    root spawn set_content(html=page_html);

    # --- evaluate: Basic JS execution ---
    print("--- evaluate ---");

    w = root spawn evaluate(script="2 + 2");
    print("2 + 2 =", w.reports[0]["result"]);

    w = root spawn evaluate(script="document.title");
    print("Page title:", w.reports[0]["result"]);

    js = "Array.from({length: 5}, function(_, i) { return {id: i, square: i * i}; })";
    w = root spawn evaluate(script=js);
    print("Generated array:", w.reports[0]["result"]);

    # --- eval_handle: Returns structured data ---
    print("\n--- eval_handle ---");

    w = root spawn eval_handle(script="({name: 'jac-browser', version: '0.1.0', features: ['snapshot', 'click', 'fill']})");
    print("Handle result:", w.reports[0]["result"]);
    print("  name:", w.reports[0]["result"]["name"]);
    print("  features:", w.reports[0]["result"]["features"]);

    # Complex DOM inspection via eval_handle
    js2 = "({elements: document.querySelectorAll('*').length, title: document.querySelector('h1').textContent, bodySize: document.body.innerHTML.length})";
    w = root spawn eval_handle(script=js2);
    print("DOM info:", w.reports[0]["result"]);

    # --- expose: Make a function available in page context ---
    print("\n--- expose ---");

    w = root spawn expose(name="jacNotify");
    print("Exposed function 'jacNotify':", w.reports[0]["success"]);

    # --- wait_for: Wait for element state ---
    print("\n--- wait_for ---");

    # Wait for an element that's already visible
    w = root spawn wait_for(selector="#title", state="visible", timeout=5000);
    print("Title visible:", w.reports[0]["success"]);

    # Wait for the hidden element to remain hidden
    w = root spawn wait_for(selector="#delayed", state="hidden", timeout=1000);
    print("Delayed element hidden:", w.reports[0]["success"]);

    # --- wait_for_function: Wait for JS expression to be truthy ---
    print("\n--- wait_for_function ---");

    # Set up a delayed value
    root spawn evaluate(script="window.dataReady = false; setTimeout(function() { window.dataReady = true; }, 300);");

    w = root spawn wait_for_function(expression="() => window.dataReady === true", timeout=5000);
    print("Data ready:", w.reports[0]["success"]);

    # Wait for DOM condition
    w = root spawn wait_for_function(expression="() => document.querySelectorAll('div').length >= 2", timeout=5000);
    print("DOM condition met:", w.reports[0]["success"]);

    # --- wait_for_load_state ---
    print("\n--- wait_for_load_state ---");

    w = root spawn wait_for_load_state(state="load", timeout=5000);
    print("Page loaded:", w.reports[0]["success"]);

    w = root spawn wait_for_load_state(state="domcontentloaded", timeout=5000);
    print("DOM content loaded:", w.reports[0]["success"]);

    # --- pause_page (informational in headless mode) ---
    print("\n--- pause_page ---");
    w = root spawn pause_page();
    print("Pause page:", w.reports[0]["success"]);

    root spawn close_browser();
    print("\nDone.");
}
