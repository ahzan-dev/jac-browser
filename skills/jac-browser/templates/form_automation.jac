"""Template: Form Automation - Fill and submit web forms.

Demonstrates the snapshot -> identify refs -> fill -> submit -> verify pattern.

Usage:
    jac run skills/jac-browser/templates/form_automation.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot, click, fill, select_option,
    check_element, get_text, get_url, wait_for_load_state
}


with entry {
    root spawn launch(headless=True);

    # --- Step 1: Navigate to form ---
    root spawn navigate(url="https://quotes.toscrape.com/login");
    print("=== Form Automation Template ===\n");

    # --- Step 2: Snapshot to discover form elements ---
    w = root spawn snapshot();
    snap = w.reports[0]["snapshot"];
    refs = w.reports[0]["refs"];
    print("Form structure:");
    print(snap);
    print("\nAvailable refs:");
    for (k, v) in refs.items() {
        print("  ", k, "->", v["role"], v["name"]);
    }

    # --- Step 3: Fill form fields ---
    print("\n--- Filling form ---");
    root spawn fill(selector="#username", value="testuser");
    print("Filled username");

    root spawn fill(selector="#password", value="testpassword");
    print("Filled password");

    # --- Step 4: Submit ---
    root spawn click(selector="input[type='submit']");
    print("Submitted form");

    # --- Step 5: Verify result ---
    root spawn wait_for_load_state(state="load");
    w = root spawn get_url();
    print("\nResult URL:", w.reports[0]["url"]);

    w = root spawn snapshot();
    print("Result page:");
    print(w.reports[0]["snapshot"][:500]);

    # Take evidence screenshot
    w = root spawn screenshot();
    print("\nScreenshot captured:", len(w.reports[0]["base64"]), "base64 chars");

    root spawn close_browser();
    print("\nDone.");
}
