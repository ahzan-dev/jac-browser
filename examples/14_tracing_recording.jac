"""Example 14: Tracing and Recording - Playwright traces and HAR files.

Demonstrates Playwright's tracing (screenshots + snapshots + network in a zip),
HAR network recording, and action recording.

Usage:
    jac run examples/14_tracing_recording.jac
"""

import from tempfile {mkdtemp}
import from os.path {exists}
import from jac_browser.walkers {
    launch, navigate, close_browser,
    trace_start, trace_stop,
    har_start, har_stop,
    recording_start, recording_stop, recording_restart,
    video_path,
    click, fill, snapshot
}


with entry {
    root spawn launch(headless=True);

    tmp_dir = mkdtemp();

    # --- Playwright Tracing ---
    print("--- Tracing ---");
    print("Traces capture screenshots, DOM snapshots, and network activity.");

    # Start tracing
    w = root spawn trace_start(name="my-trace");
    print("Trace started:", w.reports[0]["success"]);

    # Perform some actions (these will be recorded in the trace)
    root spawn navigate(url="https://example.com");
    root spawn snapshot();
    root spawn navigate(url="https://httpbin.org/get");

    # Stop tracing and save to file
    trace_path = tmp_dir + "/trace.zip";
    w = root spawn trace_stop(path=trace_path);
    print("Trace stopped:", w.reports[0]["success"]);
    print("Trace saved to:", trace_path);

    if exists(trace_path) {
        print("Trace file exists: yes");
        print("View with: npx playwright show-trace " + trace_path);
    }

    # --- HAR Recording ---
    print("\n--- HAR Recording ---");
    print("HAR files record all network requests/responses.");

    har_path = tmp_dir + "/network.har";
    w = root spawn har_start(path=har_path);
    print("HAR recording started:", w.reports[0]["success"]);

    # Navigate (network requests will be captured)
    root spawn navigate(url="https://example.com");
    root spawn navigate(url="https://httpbin.org/headers");

    w = root spawn har_stop();
    print("HAR recording stopped:", w.reports[0]["success"]);
    print("HAR saved to:", har_path);

    # --- Action Recording ---
    print("\n--- Action Recording ---");
    print("Records a log of browser actions performed.");

    w = root spawn recording_start();
    print("Recording started:", w.reports[0]["success"]);

    # Perform actions
    root spawn navigate(url="https://httpbin.org/forms/post");
    root spawn fill(selector="input[name='custname']", value="Test User");
    root spawn click(selector="input[value='medium']");

    # Stop recording and get the action log
    w = root spawn recording_stop();
    print("Recording stopped:", w.reports[0]["success"]);
    if w.reports[0].get("actions") {
        print("Recorded actions:");
        for a in w.reports[0]["actions"] {
            print("  " + str(a));
        }
    }

    # Restart recording (stops current and starts a new one)
    root spawn recording_start();
    root spawn navigate(url="https://example.com");
    w = root spawn recording_restart();
    print("\nRecording restarted:", w.reports[0]["success"]);

    # --- Video path ---
    print("\n--- Video ---");
    w = root spawn video_path();
    print("Video path:", w.reports[0]);

    root spawn close_browser();
    print("\nAll recordings saved to:", tmp_dir);
}
