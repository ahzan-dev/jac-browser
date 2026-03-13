"""Example 27: Session Persistence - Save and restore browser state across pages.

Demonstrates saving browser state (cookies, storage) to a file and loading
it back to resume where you left off. Useful for maintaining login sessions.

Usage:
    jac run examples/27_session_persistence.jac
"""

import from os.path {exists}
import from os {remove}

import from jac_browser.walkers {
    launch, navigate, close_browser,
    state_save, state_load, state_list,
    cookies_set, cookies_get, storage_set, storage_get,
    get_title, evaluate
}


with entry {
    state_path = "/tmp/jac_browser_state.json";

    # --- Phase 1: Create state and save it ---
    print("=== Phase 1: Create browser state ===");
    root spawn launch(headless=True);

    root spawn navigate(url="https://example.com");
    w = root spawn get_title();
    print("Page:", w.reports[0]["title"]);

    # Set some cookies (cookies_set takes a list of cookie dicts)
    cookie1 = {"name": "session_token", "value": "abc123", "domain": "example.com", "path": "/"};
    cookie2 = {"name": "user_pref", "value": "dark_mode", "domain": "example.com", "path": "/"};
    root spawn cookies_set(cookies=[cookie1, cookie2]);
    print("Set 2 cookies");

    # Set localStorage
    root spawn storage_set(key="username", value="jac_user");
    root spawn storage_set(key="last_visit", value="2026-03-13");
    print("Set 2 localStorage items");

    # Verify cookies are set
    w = root spawn cookies_get();
    cookies = w.reports[0]["cookies"];
    print("Cookies before save:", len(cookies));
    for c in cookies {
        print("  -", c["name"], "=", c["value"]);
    }

    # Save state to file
    w = root spawn state_save(path=state_path);
    print("\nState saved to:", w.reports[0]["path"]);

    # Close browser
    root spawn close_browser();
    print("Browser closed.\n");

    # --- Phase 2: Load saved state in a new session ---
    print("=== Phase 2: Restore browser state ===");
    root spawn launch(headless=True);

    # Load the saved state
    w = root spawn state_load(path=state_path);
    print("State loaded:", w.reports[0]);

    # Navigate to same site to check cookies
    root spawn navigate(url="https://example.com");

    # Check cookies are restored
    w = root spawn cookies_get();
    cookies = w.reports[0]["cookies"];
    print("Cookies after restore:", len(cookies));
    for c in cookies {
        print("  -", c["name"], "=", c["value"]);
    }

    # Check localStorage is restored
    w = root spawn storage_get(key="username");
    print("localStorage username:", w.reports[0]["value"]);
    w = root spawn storage_get(key="last_visit");
    print("localStorage last_visit:", w.reports[0]["value"]);

    # List saved states
    w = root spawn state_list(directory="/tmp");
    print("\nSaved states in /tmp:", w.reports[0]);

    root spawn close_browser();

    # Cleanup
    if exists(state_path) {
        remove(state_path);
        print("Cleaned up state file.");
    }

    print("\nDone.");
}
