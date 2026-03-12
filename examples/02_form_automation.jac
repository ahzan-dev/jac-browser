"""Example 02: Form Automation - Fill inputs, check boxes, select dropdowns.

Demonstrates how to automate HTML forms: text inputs, checkboxes, radio buttons,
dropdowns, and form submission.

Usage:
    jac run examples/02_form_automation.jac
"""

import from jac_browser.walkers {
    launch, navigate, snapshot, close_browser,
    fill, type_text, clear_input,
    click, press,
    check_element, uncheck_element, is_checked,
    select_option,
    input_value, get_text
}


with entry {
    root spawn launch(headless=True);

    # Navigate to a form page (using httpbin as example)
    root spawn navigate(url="https://httpbin.org/forms/post");

    # Take snapshot to see what's on the page
    w = root spawn snapshot();
    print("--- Page structure ---");
    print(w.reports[0]["snapshot"]);

    # Fill text inputs using the "fill" walker (clears first, then types)
    root spawn fill(selector="input[name='custname']", value="Jane Doe");
    root spawn fill(selector="input[name='custtel']", value="555-1234");
    root spawn fill(selector="input[name='custemail']", value="jane@example.com");

    # Fill a textarea
    root spawn fill(selector="textarea[name='comments']", value="Please deliver to the back door.");

    # Select a radio button by clicking it
    root spawn click(selector="input[value='medium']");

    # Check checkboxes
    root spawn check_element(selector="input[name='topping'][value='cheese']");
    root spawn check_element(selector="input[name='topping'][value='mushroom']");

    # Verify a checkbox is checked
    w = root spawn is_checked(selector="input[name='topping'][value='cheese']");
    print("Cheese checked:", w.reports[0]["checked"]);

    # Read back the filled value
    w = root spawn input_value(selector="input[name='custname']");
    print("Name field value:", w.reports[0]["value"]);

    # Type text character-by-character (simulates real typing with delay)
    root spawn clear_input(selector="input[name='custtel']");
    root spawn type_text(selector="input[name='custtel']", text="555-9999", delay=20);

    # Use keyboard press on a focused element
    root spawn press(selector="input[name='custtel']", key="End");

    # Take final snapshot to verify form state
    w = root spawn snapshot();
    print("\n--- Form filled ---");
    print(w.reports[0]["snapshot"]);

    root spawn close_browser();
    print("Done.");
}
