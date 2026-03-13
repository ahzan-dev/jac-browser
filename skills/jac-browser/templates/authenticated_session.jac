"""Template: Authenticated Session - Login once, save state, reuse.

Demonstrates saving browser state after login so subsequent runs
skip the login flow entirely.

Usage:
    jac run skills/jac-browser/templates/authenticated_session.jac
"""

import from os.path {exists}

import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot, click, fill,
    state_save, state_load,
    get_url, get_title, wait_for_load_state,
    cookies_get
}


with entry {
    state_path = "/tmp/jac_auth_state.json";

    print("=== Authenticated Session Template ===\n");
    root spawn launch(headless=True);

    # Check if we have saved state
    if exists(state_path) {
        print("Found saved state, loading...");
        root spawn state_load(path=state_path);
        root spawn navigate(url="https://quotes.toscrape.com");
        print("State loaded - skipped login!");
    } else {
        print("No saved state found, performing login...");

        # --- Login flow ---
        root spawn navigate(url="https://quotes.toscrape.com/login");
        root spawn fill(selector="#username", value="testuser");
        root spawn fill(selector="#password", value="testpassword");
        root spawn click(selector="input[type='submit']");
        root spawn wait_for_load_state(state="load");

        w = root spawn get_url();
        print("Post-login URL:", w.reports[0]["url"]);

        # Save state for reuse
        root spawn state_save(path=state_path);
        print("State saved to:", state_path);
    }

    # --- Authenticated work ---
    print("\n--- Authenticated Work ---");

    w = root spawn get_title();
    print("Page:", w.reports[0]["title"]);

    w = root spawn get_url();
    print("URL:", w.reports[0]["url"]);

    w = root spawn cookies_get();
    cookies = w.reports[0]["cookies"];
    print("Cookies:", len(cookies));
    for c in cookies {
        val = c["value"];
        print("  -", c["name"], "=", val[:20]);
    }

    w = root spawn snapshot();
    snap = w.reports[0]["snapshot"];
    print("\nPage snapshot (first 300 chars):");
    print(snap[:300]);

    w = root spawn screenshot();
    print("\nScreenshot:", len(w.reports[0]["base64"]), "base64 chars");

    root spawn close_browser();

    # Cleanup state file for demo
    if exists(state_path) {
        import from os {remove};
        remove(state_path);
        print("Cleaned up state file.");
    }

    print("\nDone.");
}
