"""Example 11: Dialog Handling - Handle alert, confirm, and prompt dialogs.

Demonstrates setting up dialog handlers to automatically accept or dismiss
browser dialogs (alert, confirm, prompt).

Usage:
    jac run examples/11_dialog_handling.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    dialog, confirm, deny,
    evaluate, set_content
}


with entry {
    root spawn launch(headless=True);

    # --- Auto-accept alerts using dialog() ---
    print("--- Alert handling (dialog walker) ---");

    root spawn set_content(html="<h1>Dialog Test</h1>");

    # Set up dialog handler to accept all dialogs
    root spawn dialog(response="accept");
    print("Dialog handler set to: accept");

    # Trigger an alert - gets auto-accepted
    root spawn evaluate(script="alert('Hello from jac-browser!')");
    print("Alert triggered and auto-accepted");

    # Trigger another alert
    root spawn evaluate(script="alert('Second alert')");
    print("Second alert auto-accepted");

    # --- Prompt dialog with custom text ---
    print("\n--- Prompt dialog (dialog walker) ---");

    # Change handler to accept with prompt text
    root spawn dialog(response="accept", prompt_text="My custom answer");
    root spawn evaluate(script="window.promptResult = prompt('What is your name?')");
    w = root spawn evaluate(script="window.promptResult");
    print("Prompt result:", w.reports[0]["result"]);

    # Dismiss prompt (returns null)
    root spawn dialog(response="dismiss");
    root spawn evaluate(script="window.promptResult2 = prompt('Enter something:')");
    w = root spawn evaluate(script="window.promptResult2");
    print("Dismissed prompt result:", w.reports[0]["result"]);

    # --- Confirm/Deny walkers ---
    # Navigate to a fresh page to reset dialog listeners
    print("\n--- Confirm dialog (confirm walker) ---");
    root spawn navigate(url="about:blank");
    root spawn set_content(html="<h1>Confirm Test</h1>");

    # Use confirm() to pre-accept the next confirm dialog
    root spawn confirm();
    root spawn evaluate(script="window.confirmResult = confirm('Are you sure?')");
    w = root spawn evaluate(script="window.confirmResult");
    print("Confirm result (accepted):", w.reports[0]["result"]);

    # Navigate again to reset listeners before deny
    print("\n--- Confirm dialog (deny walker) ---");
    root spawn navigate(url="about:blank");
    root spawn set_content(html="<h1>Deny Test</h1>");

    # Use deny() to pre-deny the next confirm dialog
    root spawn deny();
    root spawn evaluate(script="window.denyResult = confirm('Delete everything?')");
    w = root spawn evaluate(script="window.denyResult");
    print("Confirm result (denied):", w.reports[0]["result"]);

    root spawn close_browser();
    print("\nDone.");
}
