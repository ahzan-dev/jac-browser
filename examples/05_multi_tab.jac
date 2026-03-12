"""Example 05: Multi-Tab Workflow - Open, switch, and manage browser tabs.

Demonstrates opening multiple tabs, switching between them, listing all tabs,
and closing specific tabs.

Usage:
    jac run examples/05_multi_tab.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    tab_new, tab_list, tab_switch, tab_close,
    get_url, get_title, snapshot,
    window_new, bring_to_front
}


with entry {
    root spawn launch(headless=True);

    # Navigate first tab
    root spawn navigate(url="https://example.com");
    w = root spawn get_title();
    print("Tab 1:", w.reports[0]["title"]);

    # Open a second tab and navigate it
    w = root spawn tab_new(url="https://httpbin.org/get");
    tab2_id = w.reports[0]["page_id"];
    print("Opened tab 2, page_id:", tab2_id);

    w = root spawn get_title();
    print("Tab 2:", w.reports[0]["title"]);

    # Open a third tab
    w = root spawn tab_new(url="https://quotes.toscrape.com/");
    tab3_id = w.reports[0]["page_id"];
    print("Opened tab 3, page_id:", tab3_id);

    # List all open tabs
    w = root spawn tab_list();
    print("\n--- All tabs ---");
    for tab in w.reports[0]["tabs"] {
        active = " (active)" if tab["is_active"] else "";
        print("  " + str(tab["page_id"])[:8] + "... " + str(tab["url"]) + active);
    }

    # Switch back to the first tab
    first_tab_id = w.reports[0]["tabs"][0]["page_id"];
    root spawn tab_switch(page_id=str(first_tab_id));
    w = root spawn get_url();
    print("\nSwitched to tab 1:", w.reports[0]["url"]);

    # Take a snapshot of the active tab
    w = root spawn snapshot();
    print("Tab 1 snapshot taken:", w.reports[0]["success"]);

    # Switch to tab 3
    root spawn tab_switch(page_id=str(tab3_id));
    w = root spawn get_title();
    print("Switched to tab 3:", w.reports[0]["title"]);

    # Close tab 2 (the middle one)
    root spawn tab_close(page_id=str(tab2_id));
    print("Closed tab 2");

    # Verify remaining tabs
    w = root spawn tab_list();
    print("\n--- Remaining tabs ---");
    for tab in w.reports[0]["tabs"] {
        print("  " + str(tab["url"]));
    }

    # Bring current tab to front (useful in headed mode)
    root spawn bring_to_front();

    # Open a new window (creates a new browser window, not just tab)
    w = root spawn window_new(url="https://example.com");
    print("\nNew window opened:", w.reports[0]["success"]);
    # Close the new window tab
    root spawn tab_close(page_id=str(w.reports[0]["page_id"]));

    root spawn close_browser();
    print("\nDone.");
}
