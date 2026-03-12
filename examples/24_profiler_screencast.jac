"""Example 24: Profiler and Screencast - Performance profiling and screen recording.

Demonstrates starting/stopping the browser profiler for performance analysis
and screencast for capturing browser frames.

Usage:
    jac run examples/24_profiler_screencast.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    profiler_start, profiler_stop,
    screencast_start, screencast_stop,
    response_body,
    evaluate
}


with entry {
    root spawn launch(headless=True);

    # --- Profiler ---
    print("--- Profiler ---");
    print("The profiler captures performance metrics during browser operations.");

    w = root spawn profiler_start();
    print("Profiler started:", w.reports[0]["success"]);

    # Perform some operations to profile
    root spawn navigate(url="https://example.com");
    root spawn evaluate(script="var sum = 0; for (var i = 0; i < 100000; i++) { sum += Math.sqrt(i); } sum;");
    root spawn navigate(url="https://httpbin.org/get");

    w = root spawn profiler_stop();
    print("Profiler stopped:", w.reports[0]["success"]);
    if w.reports[0].get("profile") {
        print("Profile data available");
    }

    # --- Screencast ---
    print("\n--- Screencast ---");
    print("Screencast captures browser frames (useful for recording sessions).");

    w = root spawn screencast_start();
    print("Screencast started:", w.reports[0]["success"]);

    # Navigate around to generate frames
    root spawn navigate(url="https://example.com");
    root spawn evaluate(script="document.title");

    w = root spawn screencast_stop();
    print("Screencast stopped:", w.reports[0]["success"]);

    # --- Response Body ---
    print("\n--- Response Body ---");
    print("Capture response body for specific network requests.");

    root spawn navigate(url="https://httpbin.org/json");
    w = root spawn response_body(url_filter="httpbin");
    print("Response body result:", w.reports[0]["success"]);
    if w.reports[0].get("body") {
        body_str = str(w.reports[0]["body"]);
        if len(body_str) > 200 {
            print("Body preview:", body_str[:200]);
        } else {
            print("Body preview:", body_str);
        }
    }

    root spawn close_browser();
    print("\nDone.");
}
