"""Example 26: Headed Mode - Launch a visible browser window.

Demonstrates launching the browser in headed (visible) mode so you can
watch automation happen in real time. Useful for debugging and demos.

Usage:
    jac run examples/26_headed_mode.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot, click,
    fill, evaluate, get_title
}


with entry {
    # Launch with visible browser window
    root spawn launch(headless=False);
    print("Browser launched in HEADED mode (visible window)");

    # Navigate to a site
    root spawn navigate(url="https://example.com");
    w = root spawn get_title();
    print("Page title:", w.reports[0]["title"]);

    # Take a snapshot
    w = root spawn snapshot();
    snap = w.reports[0]["snapshot"];
    print("Snapshot (first 300 chars):", snap[:300]);

    # Small pause so user can see the browser
    root spawn evaluate(script="new Promise(r => setTimeout(r, 1000))");

    # Navigate to another page
    root spawn navigate(url="https://quotes.toscrape.com");
    w = root spawn get_title();
    print("\nNavigated to:", w.reports[0]["title"]);

    # Click the Login link
    root spawn click(selector="a[href='/login']");
    w = root spawn get_title();
    print("After click:", w.reports[0]["title"]);

    # Fill in the login form (visible in browser window)
    root spawn fill(selector="#username", value="testuser");
    root spawn fill(selector="#password", value="testpass");
    print("Filled login form (visible in browser)");

    # Take screenshot of the filled form
    w = root spawn screenshot();
    img_len = len(w.reports[0]["base64"]);
    print("Screenshot captured:", img_len, "base64 chars");

    # Small pause to see result
    root spawn evaluate(script="new Promise(r => setTimeout(r, 1000))");

    root spawn close_browser();
    print("\nDone. Browser window closed.");
}
