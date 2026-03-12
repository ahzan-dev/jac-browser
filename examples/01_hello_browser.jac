"""Example 01: Hello Browser - Basic browser launch, navigate, snapshot, and close.

This is the simplest possible jac-browser program. It launches a headless
browser, navigates to a URL, takes an accessibility snapshot to see the page,
and closes the browser.

Usage:
    jac run examples/01_hello_browser.jac
"""

import from jac_browser.walkers {launch, navigate, snapshot, get_url, get_title, close_browser}


with entry {
    # Launch a headless Chromium browser
    w = root spawn launch(headless=True);
    print("Browser launched:", w.reports[0]["success"]);

    # Navigate to a website
    w = root spawn navigate(url="https://example.com");
    print("Navigated:", w.reports[0]["success"]);

    # Get current URL and title
    w = root spawn get_url();
    print("URL:", w.reports[0]["url"]);

    w = root spawn get_title();
    print("Title:", w.reports[0]["title"]);

    # Take an ARIA accessibility snapshot - this is how AI agents "see" the page
    w = root spawn snapshot();
    print("\n--- Page Snapshot ---");
    print(w.reports[0]["snapshot"]);

    # Clean up
    w = root spawn close_browser();
    print("\nBrowser closed:", w.reports[0]["success"]);
}
