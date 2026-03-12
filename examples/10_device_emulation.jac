"""Example 10: Device Emulation - Simulate mobile devices, geolocation, timezone.

Demonstrates emulating specific devices (iPhone, Pixel), setting geolocation,
timezone, locale, user agent, and media preferences.

Usage:
    jac run examples/10_device_emulation.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    viewport, screenshot,
    device, device_list,
    geolocation, permissions,
    timezone, locale, useragent,
    emulate_media,
    evaluate
}


with entry {
    root spawn launch(headless=True);

    # --- List available device presets ---
    w = root spawn device_list();
    devices = w.reports[0]["devices"];
    print("Available device presets:", len(devices));
    print("First 10 devices:");
    for d in devices[:10] {
        print("  " + str(d));
    }

    # --- Emulate iPhone 12 ---
    print("\n--- iPhone 12 Emulation ---");
    w = root spawn device(device_name="iPhone 12");
    print("Device set:", w.reports[0]["success"]);
    print("Viewport:", w.reports[0].get("viewport", "N/A"));

    root spawn navigate(url="https://example.com");
    w = root spawn screenshot();
    print("Mobile screenshot taken:", w.reports[0]["success"]);

    # --- Set custom viewport ---
    print("\n--- Custom Viewport ---");
    root spawn viewport(width=1920, height=1080);
    w = root spawn evaluate(script="JSON.stringify({w: window.innerWidth, h: window.innerHeight})");
    print("Viewport size:", w.reports[0]["result"]);

    # --- Geolocation ---
    print("\n--- Geolocation ---");

    # Grant geolocation permission first
    root spawn permissions(grant=["geolocation"]);

    # Set location to San Francisco
    root spawn geolocation(latitude=37.7749, longitude=-122.4194, accuracy=100.0);
    print("Geolocation set to San Francisco");

    # Verify with JavaScript
    js = "new Promise(function(resolve) { navigator.geolocation.getCurrentPosition(function(pos) { resolve({lat: pos.coords.latitude, lng: pos.coords.longitude}); }, function(err) { resolve({error: err.message}); }); })";
    w = root spawn evaluate(script=js);
    print("Browser location:", w.reports[0]["result"]);

    # --- Timezone ---
    print("\n--- Timezone ---");
    root spawn timezone(timezone_id="Asia/Tokyo");
    print("Timezone set to Asia/Tokyo");

    w = root spawn evaluate(script="Intl.DateTimeFormat().resolvedOptions().timeZone");
    print("Browser timezone:", w.reports[0]["result"]);

    # --- Locale ---
    print("\n--- Locale ---");
    root spawn locale(locale_str="ja-JP");
    print("Locale set to ja-JP");

    # --- User Agent ---
    print("\n--- User Agent ---");
    w = root spawn useragent();
    print("Current user agent:", str(w.reports[0].get("user_agent", ""))[:80] + "...");

    root spawn useragent(user_agent="JacBrowser/1.0 (Automated)");
    w = root spawn evaluate(script="navigator.userAgent");
    print("Custom user agent:", w.reports[0]["result"]);

    # --- Media Emulation ---
    print("\n--- Media Emulation ---");

    # Dark mode
    root spawn emulate_media(color_scheme="dark");
    w = root spawn evaluate(script="window.matchMedia('(prefers-color-scheme: dark)').matches");
    print("Dark mode active:", w.reports[0]["result"]);

    # Light mode
    root spawn emulate_media(color_scheme="light");
    w = root spawn evaluate(script="window.matchMedia('(prefers-color-scheme: light)').matches");
    print("Light mode active:", w.reports[0]["result"]);

    # Print media
    root spawn emulate_media(media="print");
    print("Print media emulated");

    # Reduced motion
    root spawn emulate_media(reduced_motion="reduce");
    w = root spawn evaluate(script="window.matchMedia('(prefers-reduced-motion: reduce)').matches");
    print("Reduced motion:", w.reports[0]["result"]);

    # Clear permissions
    root spawn permissions(do_clear=True);

    root spawn close_browser();
    print("\nDone.");
}
