"""Example 06: Keyboard and Mouse Control - Low-level input simulation.

Demonstrates precise keyboard typing, key combinations, mouse movement,
clicking at coordinates, dragging, scrolling, and touch events.

Usage:
    jac run examples/06_keyboard_mouse.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    fill, focus, clear_input,
    keyboard, key_down, key_up, press,
    mouse_move, mouse_down, mouse_up, mouse_click, mouse_dblclick,
    wheel,
    scroll, scroll_into_view,
    swipe, tap,
    input_keyboard, input_mouse,
    insert_text,
    input_value, evaluate
}


with entry {
    root spawn launch(headless=True);

    # Use a simple input page
    root spawn navigate(url="https://httpbin.org/forms/post");

    # --- Keyboard operations ---
    print("--- Keyboard ---");

    # Focus an input and type with the keyboard walker
    root spawn focus(selector="input[name='custname']");
    root spawn keyboard(subaction="type", text="Hello World", delay=10);

    w = root spawn input_value(selector="input[name='custname']");
    print("Typed:", w.reports[0]["value"]);

    # Select all text with Ctrl+A, then delete
    root spawn keyboard(subaction="press", keys="Control+a");
    root spawn keyboard(subaction="press", keys="Delete");

    w = root spawn input_value(selector="input[name='custname']");
    print("After Ctrl+A + Delete:", repr(w.reports[0]["value"]));

    # Type new text
    root spawn keyboard(subaction="type", text="Jac Browser");

    # Press individual keys
    root spawn key_down(key="Shift");
    root spawn keyboard(subaction="press", keys="Home");  # Shift+Home selects all
    root spawn key_up(key="Shift");

    # Insert text at cursor (replaces selection)
    root spawn insert_text(text="Replaced Text");
    w = root spawn input_value(selector="input[name='custname']");
    print("After insert_text:", w.reports[0]["value"]);

    # Use input_keyboard for quick key injection
    root spawn focus(selector="input[name='custtel']");
    root spawn input_keyboard(text="555-0123");
    w = root spawn input_value(selector="input[name='custtel']");
    print("input_keyboard result:", w.reports[0]["value"]);

    # --- Mouse operations ---
    print("\n--- Mouse ---");

    # Move mouse to specific coordinates
    w = root spawn mouse_move(x=100.0, y=200.0);
    print("Mouse moved:", w.reports[0]["success"]);

    # Click at coordinates
    w = root spawn mouse_click(x=300.0, y=200.0, button="left", click_count=1);
    print("Mouse click:", w.reports[0]["success"]);

    # Double-click at coordinates
    w = root spawn mouse_dblclick(x=300.0, y=200.0);
    print("Mouse dblclick:", w.reports[0]["success"]);

    # Mouse down and up (for custom drag operations)
    root spawn mouse_move(x=100.0, y=100.0);
    root spawn mouse_down(button="left");
    root spawn mouse_move(x=200.0, y=200.0);
    root spawn mouse_up(button="left");
    print("Mouse drag via down/move/up: done");

    # Use input_mouse for coordinate-based actions
    w = root spawn input_mouse(x=150.0, y=150.0, action="click");
    print("input_mouse click:", w.reports[0]["success"]);

    # --- Scrolling ---
    print("\n--- Scrolling ---");

    # Scroll page down
    w = root spawn scroll(direction="down", amount=300);
    print("Scroll down:", w.reports[0]["success"]);

    # Scroll page up
    w = root spawn scroll(direction="up", amount=150);
    print("Scroll up:", w.reports[0]["success"]);

    # Scroll using mouse wheel
    w = root spawn wheel(delta_x=0.0, delta_y=200.0);
    print("Mouse wheel:", w.reports[0]["success"]);

    # Scroll a specific element into view
    w = root spawn scroll_into_view(selector="textarea[name='comments']");
    print("Scroll into view:", w.reports[0]["success"]);

    # Swipe gesture (mobile-style)
    w = root spawn swipe(direction="up", start_x=200.0, start_y=400.0, distance=200.0);
    print("Swipe up:", w.reports[0]["success"]);

    root spawn close_browser();
    print("\nDone.");
}
