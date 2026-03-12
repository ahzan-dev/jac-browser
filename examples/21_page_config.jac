"""Example 21: Page Configuration - Viewport, content, media, offline mode.

Demonstrates configuring the browser page: setting viewport size, injecting
HTML content, emulating media features, and toggling offline mode.

Usage:
    jac run examples/21_page_config.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    viewport, set_content,
    emulate_media, offline,
    evaluate, screenshot,
    wait_for_load_state
}


with entry {
    root spawn launch(headless=True);

    # --- Viewport Sizes ---
    print("--- Viewport ---");

    # Desktop
    root spawn viewport(width=1920, height=1080);
    w = root spawn evaluate(script="window.innerWidth + 'x' + window.innerHeight");
    print("Desktop:", w.reports[0]["result"]);

    # Tablet
    root spawn viewport(width=768, height=1024);
    w = root spawn evaluate(script="window.innerWidth + 'x' + window.innerHeight");
    print("Tablet:", w.reports[0]["result"]);

    # Mobile
    root spawn viewport(width=375, height=812);
    w = root spawn evaluate(script="window.innerWidth + 'x' + window.innerHeight");
    print("Mobile:", w.reports[0]["result"]);

    # --- Set Content (inject HTML directly) ---
    print("\n--- Set Content ---");

    root spawn viewport(width=800, height=600);

    page_html = "<!DOCTYPE html><html><head><title>Injected Page</title></head><body style='font-family: sans-serif; padding: 20px;'><h1 id='title' style='color: #2c3e50;'>Dynamic Content</h1><p>This page was created entirely via set_content.</p><ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul></body></html>";
    root spawn set_content(html=page_html);

    w = root spawn evaluate(script="document.getElementById('title').textContent");
    print("Injected page title:", w.reports[0]["result"]);

    w = root spawn evaluate(script="document.querySelectorAll('li').length");
    print("List items:", w.reports[0]["result"]);

    # --- Media Emulation ---
    print("\n--- Media Emulation ---");

    # Test dark mode
    root spawn emulate_media(color_scheme="dark");
    w = root spawn evaluate(script="window.matchMedia('(prefers-color-scheme: dark)').matches");
    print("Dark mode:", w.reports[0]["result"]);

    # Test light mode
    root spawn emulate_media(color_scheme="light");
    w = root spawn evaluate(script="window.matchMedia('(prefers-color-scheme: light)').matches");
    print("Light mode:", w.reports[0]["result"]);

    # Test print media
    root spawn emulate_media(media="print");
    w = root spawn evaluate(script="window.matchMedia('print').matches");
    print("Print media:", w.reports[0]["result"]);

    # Reset to screen
    root spawn emulate_media(media="screen");

    # Test reduced motion
    root spawn emulate_media(reduced_motion="reduce");
    w = root spawn evaluate(script="window.matchMedia('(prefers-reduced-motion: reduce)').matches");
    print("Reduced motion:", w.reports[0]["result"]);

    # --- Offline Mode ---
    print("\n--- Offline Mode ---");

    root spawn navigate(url="https://example.com");
    root spawn wait_for_load_state(state="load");
    print("Page loaded while online");

    # Go offline
    root spawn offline(is_offline=True);
    print("Offline mode: enabled");

    w = root spawn evaluate(script="navigator.onLine");
    print("navigator.onLine:", w.reports[0]["result"]);

    # Go back online
    root spawn offline(is_offline=False);
    print("Offline mode: disabled");

    w = root spawn evaluate(script="navigator.onLine");
    print("navigator.onLine:", w.reports[0]["result"]);

    root spawn close_browser();
    print("\nDone.");
}
