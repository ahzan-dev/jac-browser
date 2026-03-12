"""Example 09: Semantic Locators - Find elements by role, text, label, etc.

Demonstrates Playwright's semantic locator API: get_by_text, get_by_role,
get_by_label, get_by_placeholder, get_by_alt_text, get_by_title, and
get_by_test_id. These are more resilient than CSS selectors.

Usage:
    jac run examples/09_semantic_locators.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot,
    get_by_text, get_by_role, get_by_label,
    get_by_placeholder, get_by_alt_text, get_by_title, get_by_test_id
}


with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://httpbin.org/forms/post");

    # Take snapshot to see the page
    w = root spawn snapshot();
    print("--- Page ---");
    snap = str(w.reports[0]["snapshot"]);
    print(snap[:600] + "..." if len(snap) > 600 else snap);

    # --- get_by_role: Find elements by ARIA role ---
    print("\n--- get_by_role ---");

    # Count all buttons
    w = root spawn get_by_role(role="button", action="count");
    print("Buttons on page:", w.reports[0]["count"]);

    # Count all textboxes
    w = root spawn get_by_role(role="textbox", action="count");
    print("Textboxes on page:", w.reports[0]["count"]);

    # --- get_by_text: Find elements by visible text ---
    print("\n--- get_by_text ---");

    w = root spawn get_by_text(text="Customer name", action="count");
    print("Elements with 'Customer name':", w.reports[0]["count"]);

    # Use exact match
    w = root spawn get_by_text(text="Delivery instructions", exact=True, action="count");
    print("Exact 'Delivery instructions':", w.reports[0]["count"]);

    # Get text of element found by text
    w = root spawn get_by_text(text="Customer name", action="text");
    print("Text content:", w.reports[0].get("text", "N/A"));

    # --- get_by_label: Find inputs by their label ---
    print("\n--- get_by_label ---");

    # Fill an input found by its label
    w = root spawn get_by_label(text="Customer name", action="fill:Jane Doe");
    print("Fill by label:", w.reports[0]["success"]);

    w = root spawn get_by_label(text="Telephone", action="fill:555-1234");
    print("Fill telephone:", w.reports[0]["success"]);

    # --- get_by_placeholder: Find by placeholder text ---
    print("\n--- get_by_placeholder ---");

    w = root spawn get_by_placeholder(text="Comments", action="count");
    print("Elements with 'Comments' placeholder:", w.reports[0].get("count", 0));

    # --- get_by_title: Find by title attribute ---
    print("\n--- get_by_title ---");

    w = root spawn get_by_title(text="submit", action="count");
    print("Elements with 'submit' title:", w.reports[0].get("count", 0));

    # --- Actions available for all semantic locators ---
    print("\n--- Available actions ---");
    print("  click    - Click the element");
    print("  count    - Count matching elements");
    print("  text     - Get text content");
    print("  fill:VAL - Fill input with value");
    print("  check    - Check a checkbox");
    print("  uncheck  - Uncheck a checkbox");

    root spawn close_browser();
    print("\nDone.");
}
