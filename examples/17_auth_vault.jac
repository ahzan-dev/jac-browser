"""Example 17: Auth Vault - Save and manage authentication profiles.

Demonstrates the auth vault system for saving, listing, viewing,
and using authentication credentials across sessions.

Usage:
    jac run examples/17_auth_vault.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    auth_save, auth_list, auth_show, auth_delete, auth_login,
    credentials, headers
}


with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://example.com");

    # --- Save auth profiles ---
    print("--- Saving Auth Profiles ---");

    # Save a basic auth profile
    w = root spawn auth_save(
        name="dev-server",
        url="https://dev.example.com/login",
        username="developer",
        password="dev-pass-123"
    );
    print("Saved 'dev-server':", w.reports[0]["success"]);

    # Save another profile with CSS selectors for login form
    w = root spawn auth_save(
        name="staging",
        url="https://staging.example.com/auth",
        username="tester",
        password="test-pass-456",
        username_selector="#email",
        password_selector="#password",
        submit_selector="button[type='submit']"
    );
    print("Saved 'staging':", w.reports[0]["success"]);

    # Save a third profile
    w = root spawn auth_save(
        name="production",
        url="https://app.example.com/login",
        username="admin@example.com",
        password="prod-secure-789"
    );
    print("Saved 'production':", w.reports[0]["success"]);

    # --- List all profiles ---
    print("\n--- List Profiles ---");

    w = root spawn auth_list();
    print("Total profiles:", w.reports[0]["count"]);
    for p in w.reports[0]["profiles"] {
        print("  " + str(p["name"]) + " -> " + str(p["url"]));
    }

    # --- Show profile details ---
    print("\n--- Show Profile ---");

    w = root spawn auth_show(name="dev-server");
    profile = w.reports[0]["profile"];
    print("Name:", profile["name"]);
    print("URL:", profile["url"]);
    print("Username:", profile["username"]);
    print("Created:", profile.get("created_at", "N/A"));

    # --- HTTP Auth Credentials ---
    print("\n--- HTTP Authentication ---");

    # Set HTTP Basic Auth credentials (for protected pages)
    w = root spawn credentials(username="api-user", password="api-key-abc");
    print("HTTP credentials set:", w.reports[0]["success"]);

    # --- Custom HTTP Headers ---
    print("\n--- Custom Headers ---");

    w = root spawn headers(headers_dict={
        "Authorization": "Bearer my-jwt-token-xyz",
        "X-Custom-Header": "jac-browser",
        "Accept-Language": "en-US"
    });
    print("Custom headers set:", w.reports[0]["success"]);

    # --- Delete a profile ---
    print("\n--- Delete Profile ---");

    w = root spawn auth_delete(name="production");
    print("Deleted 'production':", w.reports[0]["success"]);

    # Verify deletion
    w = root spawn auth_list();
    print("Remaining profiles:", w.reports[0]["count"]);
    for p in w.reports[0]["profiles"] {
        print("  " + str(p["name"]));
    }

    # --- Clean up remaining profiles ---
    root spawn auth_delete(name="dev-server");
    root spawn auth_delete(name="staging");

    w = root spawn auth_list();
    print("\nAfter cleanup:", w.reports[0]["count"], "profiles");

    root spawn close_browser();
    print("\nDone.");
}
