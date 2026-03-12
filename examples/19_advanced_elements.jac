"""Example 19: Advanced Element Operations - Highlight, nth, multi-select, etc.

Demonstrates advanced element manipulation including highlighting, nth element
selection, multi-select dropdowns, computed styles, and more.

Usage:
    jac run examples/19_advanced_elements.jac
"""

import from jac_browser.walkers {
    launch, close_browser,
    set_content, snapshot,
    highlight, nth,
    set_checked, is_checked,
    select_all, multi_select,
    styles,
    set_value, input_value,
    focus, fill,
    dispatch_event,
    evaluate
}


with entry {
    root spawn launch(headless=True);

    # Create a rich page for testing
    page_html = "<style>.item { padding: 8px; margin: 4px; border: 1px solid #ccc; } #main-heading { font-size: 24px; color: navy; font-weight: bold; }</style><h1 id='main-heading'>Advanced Elements Demo</h1><div class='item'>Item One</div><div class='item'>Item Two</div><div class='item'>Item Three</div><div class='item'>Item Four</div><div class='item'>Item Five</div><input type='checkbox' id='cb1' /> <label for='cb1'>Option A</label><br/><input type='checkbox' id='cb2' /> <label for='cb2'>Option B</label><br/><input type='checkbox' id='cb3' /> <label for='cb3'>Option C</label><br/><input type='text' id='text-input' value='select me' /><select id='multi' multiple size='4'><option value='apple'>Apple</option><option value='banana'>Banana</option><option value='cherry'>Cherry</option><option value='date'>Date</option></select><div id='event-output'>No events yet</div>";
    root spawn set_content(html=page_html);

    # --- Highlight an element ---
    print("--- Highlight ---");
    w = root spawn highlight(selector="#main-heading");
    print("Highlighted heading:", w.reports[0]["success"]);

    w = root spawn highlight(selector=".item:first-child");
    print("Highlighted first item:", w.reports[0]["success"]);

    # --- Nth element selection ---
    print("\n--- Nth Element ---");

    # Get text of the 1st item (0-indexed)
    w = root spawn nth(selector=".item", index=0, action="text");
    print("Item 0:", w.reports[0]["text"]);

    # Get text of the 3rd item
    w = root spawn nth(selector=".item", index=2, action="text");
    print("Item 2:", w.reports[0]["text"]);

    # Get text of the last item (index 4)
    w = root spawn nth(selector=".item", index=4, action="text");
    print("Item 4:", w.reports[0]["text"]);

    # Click the 2nd item using nth
    w = root spawn nth(selector=".item", index=1, action="click");
    print("Clicked item 1:", w.reports[0]["success"]);

    # --- Set Checked (programmatic checkbox control) ---
    print("\n--- Set Checked ---");

    root spawn set_checked(selector="#cb1", checked=True);
    root spawn set_checked(selector="#cb3", checked=True);

    w = root spawn is_checked(selector="#cb1");
    print("CB1 checked:", w.reports[0]["checked"]);

    w = root spawn is_checked(selector="#cb2");
    print("CB2 checked:", w.reports[0]["checked"]);

    w = root spawn is_checked(selector="#cb3");
    print("CB3 checked:", w.reports[0]["checked"]);

    # Uncheck one
    root spawn set_checked(selector="#cb1", checked=False);
    w = root spawn is_checked(selector="#cb1");
    print("CB1 after uncheck:", w.reports[0]["checked"]);

    # --- Select All text in input ---
    print("\n--- Select All ---");

    root spawn focus(selector="#text-input");
    w = root spawn select_all();
    print("Selected all text:", w.reports[0]["success"]);

    # --- Multi-Select dropdown ---
    print("\n--- Multi-Select ---");

    w = root spawn multi_select(selector="#multi", values=["apple", "cherry", "date"]);
    print("Multi-selected:", w.reports[0]["success"]);

    # Verify selections via JS
    js = "Array.from(document.getElementById('multi').selectedOptions).map(function(o) { return o.value; })";
    w = root spawn evaluate(script=js);
    print("Selected values:", w.reports[0]["result"]);

    # --- Computed Styles ---
    print("\n--- Computed Styles ---");

    w = root spawn styles(selector="#main-heading", properties=["font-size", "color", "font-weight"]);
    print("Heading styles:");
    for prop in w.reports[0]["styles"] {
        print("  " + str(prop) + ": " + str(w.reports[0]["styles"][prop]));
    }

    # --- Set Value (direct JS value assignment) ---
    print("\n--- Set Value ---");

    w = root spawn set_value(selector="#text-input", value="New value via set_value");
    print("Set value:", w.reports[0]["success"]);

    w = root spawn input_value(selector="#text-input");
    print("Input value:", w.reports[0]["value"]);

    # --- Dispatch Event ---
    print("\n--- Dispatch Event ---");

    # Add an event listener first
    root spawn evaluate(script="document.getElementById('event-output').addEventListener('custom-event', function(e) { this.textContent = 'Custom event received!'; });");

    w = root spawn dispatch_event(selector="#event-output", event="custom-event");
    print("Event dispatched:", w.reports[0]["success"]);

    w = root spawn evaluate(script="document.getElementById('event-output').textContent");
    print("After event:", w.reports[0]["result"]);

    root spawn close_browser();
    print("\nDone.");
}
