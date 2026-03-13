"""Example 30: Visual Regression Testing - Compare page states with diffing.

Demonstrates taking baseline snapshots, making changes, then diffing
to detect structural regressions. Uses diff_snapshot to compare
accessibility tree states and diff_screenshot to compare visual regions.

Usage:
    jac run examples/30_visual_regression.jac
"""

import from jac_browser.walkers {
    launch, close_browser,
    set_content, snapshot, screenshot, evaluate,
    diff_snapshot, diff_screenshot,
    get_text, click
}


with entry {
    root spawn launch(headless=True);

    # --- Create a test page with two cards ---
    html = "<html><head><style>body{font-family:sans-serif;margin:40px;} .card{border:1px solid #ccc;padding:16px;margin:8px 0;border-radius:8px;} .price{color:green;font-weight:bold;font-size:20px;} .title{font-size:18px;} button{padding:8px 16px;background:#007bff;color:white;border:none;border-radius:4px;cursor:pointer;}</style></head><body><h1>Product Page</h1><div class='card' id='product'><div class='title'>Widget Pro</div><div class='price'>$29.99</div><p>The best widget for professionals.</p><button id='buy'>Add to Cart</button></div><div id='cart' style='display:none;'><h2>Cart</h2><p id='cart-item'></p></div></body></html>";
    root spawn set_content(html=html);
    print("=== Visual Regression Testing ===\n");

    # --- Take baseline snapshot ---
    print("--- Baseline ---");
    w = root spawn snapshot();
    baseline_snap = w.reports[0]["snapshot"];
    print("Baseline snapshot (first 200 chars):");
    print(baseline_snap[:200]);

    # Take baseline screenshot
    w = root spawn screenshot();
    baseline_b64 = w.reports[0]["base64"];
    print("\nBaseline screenshot:", len(baseline_b64), "base64 chars");

    # --- Make changes (simulate a "code change") ---
    print("\n--- Applying changes ---");

    # Change price
    root spawn evaluate(script="document.querySelector('.price').textContent = '$39.99'");
    print("Changed price: $29.99 -> $39.99");

    # Change description
    root spawn evaluate(script="document.querySelector('#product p').textContent = 'The ULTIMATE widget for professionals.'");
    print("Changed description text");

    # Add a badge
    js_badge = "var b = document.createElement('span'); b.textContent = ' NEW'; b.style.cssText = 'background:red;color:white;padding:2px 6px;border-radius:4px;font-size:12px;'; document.querySelector('.title').appendChild(b);";
    root spawn evaluate(script=js_badge);
    print("Added NEW badge");

    # Click buy button to show cart
    root spawn click(selector="#buy");
    root spawn evaluate(script="document.getElementById('cart').style.display='block'; document.getElementById('cart-item').textContent='Widget Pro - $39.99';");
    print("Showed cart section");

    # --- Take new snapshot and diff ---
    print("\n--- Snapshot Diff ---");
    w = root spawn snapshot();
    current_snap = w.reports[0]["snapshot"];

    # Compare baseline vs current snapshot
    w = root spawn diff_snapshot(snapshot1=baseline_snap, snapshot2=current_snap);
    diff_result = w.reports[0];
    print("Diff result keys:", list(diff_result.keys()));
    if diff_result.get("success") {
        diff_text = str(diff_result.get("diff", ""));
        if diff_text {
            lines = diff_text.split("\n");
            change_count = 0;
            for line in lines {
                trimmed = line.strip();
                if trimmed.startswith("+") or trimmed.startswith("-") {
                    print(" ", trimmed[:100]);
                    change_count += 1;
                }
            }
            print("Total changed lines:", change_count);
        }
    } else {
        print("Diff error:", diff_result.get("error", "unknown"));
    }

    # --- Screenshot diff (compare two page regions) ---
    print("\n--- Screenshot Diff (comparing product vs cart) ---");
    w = root spawn diff_screenshot(selector1="#product", selector2="#cart");
    sdiff = w.reports[0];
    print("Screenshot diff:", sdiff);

    # --- Verify specific elements ---
    print("\n--- Verify Changes ---");
    w = root spawn get_text(selector=".price");
    print("Current price:", w.reports[0]["text"]);

    w = root spawn get_text(selector=".title");
    print("Current title:", w.reports[0]["text"]);

    w = root spawn get_text(selector="#cart-item");
    print("Cart item:", w.reports[0]["text"]);

    root spawn close_browser();
    print("\nDone.");
}
