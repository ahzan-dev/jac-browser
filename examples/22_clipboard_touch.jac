"""Example 22: Touch, Drag-and-Drop, Swipe, and Clipboard.

Demonstrates touch tap events, drag-and-drop, swipe gestures,
and clipboard read/write.

Usage:
    jac run examples/22_clipboard_touch.jac
"""

import from jac_browser.walkers {
    launch, close_browser,
    set_content,
    clipboard,
    tap,
    drag, swipe,
    evaluate, permissions
}


with entry {
    root spawn launch(headless=True);

    # --- Touch / Tap ---
    print("--- Touch / Tap ---");

    tap_html = "<button id='tap-btn' style='padding: 20px; font-size: 18px;' onclick=\"this.textContent='Clicked!'\">Tap me</button><div id='tap-result'></div>";
    root spawn set_content(html=tap_html);

    w = root spawn tap(selector="#tap-btn");
    print("Tap result:", w.reports[0]["success"]);

    w = root spawn evaluate(script="document.getElementById('tap-btn').textContent");
    print("Button text after tap:", w.reports[0]["result"]);

    # --- Drag and Drop ---
    print("\n--- Drag and Drop ---");

    drag_html = "<style>.box { width: 100px; height: 100px; margin: 20px; display: inline-block; text-align: center; line-height: 100px; } #draggable { background: #3498db; color: white; cursor: grab; } #dropzone { background: #ecf0f1; border: 2px dashed #bdc3c7; }</style><div id='draggable' draggable='true'>Drag me</div><div id='dropzone'>Drop here</div><div id='drag-result'>No drops yet</div><script>var drop = document.getElementById('dropzone'); drop.addEventListener('dragover', function(e) { e.preventDefault(); }); drop.addEventListener('drop', function(e) { e.preventDefault(); document.getElementById('drag-result').textContent = 'Dropped!'; drop.textContent = 'Got it!'; });</script>";
    root spawn set_content(html=drag_html);

    w = root spawn drag(source="#draggable", target="#dropzone");
    print("Drag result:", w.reports[0]["success"]);

    w = root spawn evaluate(script="document.getElementById('drag-result').textContent");
    print("Drop result:", w.reports[0]["result"]);

    # --- Swipe Gesture ---
    print("\n--- Swipe Gesture ---");

    swipe_html = "<div id='swipe-area' style='width: 300px; height: 300px; background: #e8e8e8; display: flex; align-items: center; justify-content: center; font-size: 18px;'>Swipe area</div><div id='swipe-result'>No swipe</div>";
    root spawn set_content(html=swipe_html);

    w = root spawn swipe(direction="down", start_x=150.0, start_y=100.0, distance=200.0, steps=10);
    print("Swipe down:", w.reports[0]["success"]);

    w = root spawn swipe(direction="right", start_x=50.0, start_y=150.0, distance=200.0);
    print("Swipe right:", w.reports[0]["success"]);

    w = root spawn swipe(direction="up", start_x=150.0, start_y=300.0, distance=200.0);
    print("Swipe up:", w.reports[0]["success"]);

    # --- Clipboard ---
    print("\n--- Clipboard ---");

    root spawn set_content(html="<input id='inp' value='copy this text' />");
    root spawn permissions(grant=["clipboard-read", "clipboard-write"]);

    w = root spawn clipboard(action="write", text="Hello from jac-browser!");
    print("Clipboard write:", w.reports[0]["success"]);

    w = root spawn clipboard(action="read");
    print("Clipboard read:", w.reports[0]);

    root spawn close_browser();
    print("\nDone.");
}
