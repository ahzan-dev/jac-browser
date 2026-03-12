"""Example 18: Script and Style Injection - Inject JS and CSS into pages.

Demonstrates injecting custom JavaScript and CSS into pages, including
init scripts that run on every navigation and one-time injections.

Usage:
    jac run examples/18_script_injection.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    add_init_script, add_script, add_style,
    evaluate, screenshot,
    set_content
}


with entry {
    root spawn launch(headless=True);

    # --- Init Script (runs on every page load) ---
    print("--- Init Script ---");

    # Add a script that runs on every new page/navigation
    init_js = "window.__jacBrowser = true; window.__pageLoadTime = Date.now(); window.__customGreeting = 'Hello from init script!';";
    w = root spawn add_init_script(script=init_js);
    print("Init script added:", w.reports[0]["success"]);

    # Navigate - init script runs automatically
    root spawn navigate(url="https://example.com");

    # Verify init script ran
    w = root spawn evaluate(script="window.__jacBrowser");
    print("Init script active:", w.reports[0]["result"]);

    w = root spawn evaluate(script="window.__customGreeting");
    print("Custom greeting:", w.reports[0]["result"]);

    # Navigate to another page - init script runs again
    root spawn navigate(url="https://httpbin.org/get");
    w = root spawn evaluate(script="window.__jacBrowser");
    print("Init script on new page:", w.reports[0]["result"]);

    # --- Inject Script Tag ---
    print("\n--- Script Injection ---");

    root spawn navigate(url="https://example.com");

    # Inject inline JavaScript
    inject_js = "document.body.setAttribute('data-enhanced', 'true'); var banner = document.createElement('div'); banner.id = 'injected-banner'; banner.textContent = 'This banner was injected by jac-browser'; banner.style.cssText = 'background: #333; color: white; padding: 10px; text-align: center;'; document.body.prepend(banner);";
    w = root spawn add_script(content=inject_js);
    print("Script injected:", w.reports[0]["success"]);

    # Verify
    w = root spawn evaluate(script="document.getElementById('injected-banner').textContent");
    print("Banner text:", w.reports[0]["result"]);

    w = root spawn evaluate(script="document.body.getAttribute('data-enhanced')");
    print("Data attribute:", w.reports[0]["result"]);

    # --- Inject Style Tag ---
    print("\n--- Style Injection ---");

    # Inject custom CSS
    css = "body { font-family: 'Courier New', monospace !important; background: #f0f0f0 !important; } h1 { color: #e74c3c !important; border-bottom: 3px solid #e74c3c !important; padding-bottom: 10px !important; } p { color: #2c3e50 !important; line-height: 1.8 !important; }";
    w = root spawn add_style(content=css);
    print("Styles injected:", w.reports[0]["success"]);

    # Take a screenshot to see the result
    w = root spawn screenshot();
    print("Screenshot of styled page:", w.reports[0]["success"]);

    # --- Practical: Add analytics-like tracking ---
    print("\n--- Practical: Click Tracking ---");

    page_html = "<h1>Click Tracking Demo</h1><button id='btn1'>Button 1</button><button id='btn2'>Button 2</button><button id='btn3'>Button 3</button><div id='tracker'>Clicks: none</div>";
    root spawn set_content(html=page_html);

    # Inject click tracking script
    track_js = "window.__clicks = []; document.addEventListener('click', function(e) { if (e.target.tagName === 'BUTTON') { window.__clicks.push({id: e.target.id, text: e.target.textContent, time: Date.now()}); document.getElementById('tracker').textContent = 'Clicks: ' + window.__clicks.length; } });";
    root spawn add_script(content=track_js);

    # Simulate some clicks
    root spawn evaluate(script="document.getElementById('btn1').click()");
    root spawn evaluate(script="document.getElementById('btn2').click()");
    root spawn evaluate(script="document.getElementById('btn1').click()");
    root spawn evaluate(script="document.getElementById('btn3').click()");

    # Read tracked clicks
    w = root spawn evaluate(script="JSON.stringify(window.__clicks)");
    print("Tracked clicks:", w.reports[0]["result"]);

    root spawn close_browser();
    print("\nDone.");
}
