"""Example 15: Visual Diff - Compare screenshots, snapshots, and URLs.

Demonstrates comparing page states using diff_screenshot, diff_snapshot,
and diff_url to detect visual or structural changes.

Usage:
    jac run examples/15_visual_diff.jac
"""

import from tempfile {mkdtemp}
import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot,
    diff_screenshot, diff_snapshot, diff_url,
    evaluate, set_content
}


with entry {
    root spawn launch(headless=True);

    # --- Diff Snapshots (ARIA tree comparison) ---
    print("--- Snapshot Diff ---");

    root spawn navigate(url="https://example.com");

    # Take first snapshot
    w = root spawn snapshot();
    snap1 = str(w.reports[0]["snapshot"]);
    print("Snapshot 1 taken (", len(snap1), "chars)");

    # Take second snapshot (same page, should match)
    w = root spawn snapshot();
    snap2 = str(w.reports[0]["snapshot"]);
    print("Snapshot 2 taken (", len(snap2), "chars)");

    # Compare - should be identical
    w = root spawn diff_snapshot(snapshot1=snap1, snapshot2=snap2);
    print("Snapshots match:", w.reports[0]["match"]);

    # Now modify the page and compare again
    root spawn evaluate(script="document.querySelector('h1').textContent = 'Modified Title'");
    w = root spawn snapshot();
    snap3 = str(w.reports[0]["snapshot"]);

    w = root spawn diff_snapshot(snapshot1=snap1, snapshot2=snap3);
    print("After modification - match:", w.reports[0]["match"]);
    if w.reports[0].get("diff") {
        print("Diff:", str(w.reports[0]["diff"])[:200]);
    }

    # --- Diff URLs ---
    print("\n--- URL Diff ---");

    # Compare current URL against expected
    w = root spawn diff_url(expected_url="https://example.com/");
    print("URL matches https://example.com/:", w.reports[0]["match"]);

    w = root spawn diff_url(expected_url="https://other.com");
    print("URL matches https://other.com:", w.reports[0]["match"]);

    # --- Diff Screenshots (pixel comparison) ---
    print("\n--- Screenshot Diff ---");

    tmp_dir = mkdtemp();

    # Take first screenshot
    root spawn set_content(html="<h1 style='color: blue'>Hello World</h1>");
    w = root spawn screenshot();
    print("Screenshot 1:", w.reports[0]["success"]);

    # Modify page and take second screenshot
    root spawn set_content(html="<h1 style='color: red'>Hello World</h1>");
    w = root spawn screenshot();
    print("Screenshot 2:", w.reports[0]["success"]);

    # Compare screenshots (this compares the base64 data or file paths)
    w = root spawn diff_screenshot(selector1="h1", selector2="h1");
    print("Screenshots match:", w.reports[0].get("match", "N/A"));

    root spawn close_browser();
    print("\nDone.");
}
