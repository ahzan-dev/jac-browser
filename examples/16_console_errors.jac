"""Example 16: Console and Error Monitoring - Capture browser logs and errors.

Demonstrates capturing console.log messages, JavaScript errors, and
page errors from the browser.

Usage:
    jac run examples/16_console_errors.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    set_content,
    console_get, errors_get,
    evaluate, click
}


with entry {
    root spawn launch(headless=True);

    # Create a page with various console and error scenarios
    page_html = "<h1>Console and Error Test</h1><button id='btn-log' onclick=\"console.log('User clicked the button')\">Log Message</button><button id='btn-warn' onclick=\"console.warn('This is a warning')\">Warn</button><button id='btn-error' onclick=\"console.error('Something went wrong')\">Error</button><button id='btn-throw' onclick=\"throw new Error('Uncaught exception!')\">Throw</button><button id='btn-multi' onclick=\"console.log('Step 1: started'); console.log('Step 2: processing'); console.log('Step 3: done');\">Multi Log</button>";
    root spawn set_content(html=page_html);

    # --- Capture console messages ---
    print("--- Console Messages ---");

    # Trigger some console output
    root spawn click(selector="#btn-log");
    root spawn click(selector="#btn-warn");
    root spawn click(selector="#btn-error");
    root spawn click(selector="#btn-multi");

    # Also log from JavaScript directly
    root spawn evaluate(script="console.log('Log from evaluate')");
    root spawn evaluate(script="console.info('Info message')");

    # Get all captured console messages
    w = root spawn console_get();
    print("Total console messages:", len(w.reports[0]["messages"]));
    for m in w.reports[0]["messages"] {
        print("  [" + str(m.get("type", "log")) + "] " + str(m["text"]));
    }

    # Get and clear console
    w = root spawn console_get(do_clear=True);
    print("\nCleared console:", w.reports[0].get("cleared", False));

    # Verify cleared
    w = root spawn console_get();
    print("Messages after clear:", len(w.reports[0]["messages"]));

    # --- Capture page errors ---
    print("\n--- Page Errors ---");

    # Trigger a JavaScript error
    root spawn click(selector="#btn-throw");

    # Also trigger an error via evaluate
    root spawn evaluate(script="try { undefinedFunction(); } catch(e) { throw e; }");

    w = root spawn errors_get();
    print("Page errors:", len(w.reports[0]["errors"]));
    for e in w.reports[0]["errors"] {
        print("  " + str(e)[:100]);
    }

    # Clear errors
    w = root spawn errors_get(do_clear=True);
    print("\nErrors cleared.");

    w = root spawn errors_get();
    print("Errors after clear:", len(w.reports[0]["errors"]));

    root spawn close_browser();
    print("\nDone.");
}
