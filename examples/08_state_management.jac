"""Example 08: State Management - Save and restore browser state.

Demonstrates saving cookies and storage to disk, loading them back,
listing saved states, and cleaning up old state files.

Usage:
    jac run examples/08_state_management.jac
"""

import from tempfile {mkdtemp}
import from jac_browser.walkers {
    launch, navigate, close_browser,
    cookies_set, cookies_get, cookies_clear,
    storage_set, storage_get, storage_clear,
    state_save, state_load,
    state_list, state_show, state_rename, state_delete, state_clear, state_clean
}


with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://example.com");

    # --- Cookies ---
    print("--- Cookies ---");

    # Set cookies
    root spawn cookies_set(cookies=[
        {"name": "session_id", "value": "abc123", "domain": "example.com", "path": "/"},
        {"name": "user_pref", "value": "dark_mode", "domain": "example.com", "path": "/"}
    ]);

    # Read cookies back
    w = root spawn cookies_get();
    print("Cookies:");
    for c in w.reports[0]["cookies"] {
        print("  " + str(c["name"]) + "=" + str(c["value"]));
    }

    # --- Local Storage ---
    print("\n--- Local Storage ---");

    root spawn storage_set(key="app_theme", value="dark", storage_type="local");
    root spawn storage_set(key="language", value="en", storage_type="local");

    w = root spawn storage_get(key="app_theme", storage_type="local");
    print("app_theme:", w.reports[0]["value"]);

    # Get all storage
    w = root spawn storage_get(storage_type="local");
    print("All local storage:", w.reports[0]);

    # --- Session Storage ---
    print("\n--- Session Storage ---");

    root spawn storage_set(key="cart_id", value="xyz789", storage_type="session");
    w = root spawn storage_get(key="cart_id", storage_type="session");
    print("cart_id:", w.reports[0]["value"]);

    # --- Save state to file ---
    print("\n--- Save/Load State ---");
    tmp_dir = mkdtemp();

    # Save current state (cookies + storage)
    state_path = tmp_dir + "/my_session.json";
    w = root spawn state_save(path=state_path);
    print("State saved:", w.reports[0]["success"]);

    # Clear everything
    root spawn cookies_clear();
    root spawn storage_clear(storage_type="local");
    root spawn storage_clear(storage_type="session");
    print("Cleared all cookies and storage.");

    # Verify cleared
    w = root spawn cookies_get();
    print("Cookies after clear:", len(w.reports[0]["cookies"]));

    # Restore state from file
    w = root spawn state_load(path=state_path);
    print("State loaded:", w.reports[0]["loaded"]);

    # Verify restored
    w = root spawn cookies_get();
    print("Cookies after restore:", len(w.reports[0]["cookies"]));

    # --- State management utilities ---
    print("\n--- State Utilities ---");

    # Save another state
    state_path2 = tmp_dir + "/backup.json";
    root spawn state_save(path=state_path2);

    # List all states in directory
    w = root spawn state_list(directory=tmp_dir);
    print("Saved states:", w.reports[0]["files"]);

    # Show state contents
    w = root spawn state_show(path=state_path);
    print("State data keys:", list(w.reports[0]["data"].keys()) if w.reports[0]["data"] else "empty");

    # Rename a state
    renamed_path = tmp_dir + "/renamed_session.json";
    w = root spawn state_rename(old_path=state_path, new_path=renamed_path);
    print("Renamed:", w.reports[0]["success"]);

    # Delete a state
    w = root spawn state_delete(path=state_path2);
    print("Deleted backup:", w.reports[0]["success"]);

    # Clean old states (delete files older than N days)
    w = root spawn state_clean(directory=tmp_dir, max_age_days=0);
    print("Cleaned:", w.reports[0]["success"]);

    root spawn close_browser();
    print("\nDone.");
}
