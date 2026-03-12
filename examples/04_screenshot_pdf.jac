"""Example 04: Screenshots and PDF - Capture visual output.

Demonstrates taking screenshots (full page and element-specific)
and generating PDF documents from web pages.

Usage:
    jac run examples/04_screenshot_pdf.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    screenshot, pdf, viewport
}


with entry {
    root spawn launch(headless=True);

    # Set a specific viewport size
    root spawn viewport(width=1280, height=720);

    root spawn navigate(url="https://example.com");

    # Take a regular viewport screenshot (returns base64)
    w = root spawn screenshot();
    print("Screenshot taken:", w.reports[0]["success"]);
    print("Format:", w.reports[0]["format"]);
    b64 = str(w.reports[0]["base64"]);
    print("Base64 length:", len(b64), "chars");

    # Take a full-page screenshot
    w = root spawn screenshot(full_page=True);
    print("\nFull page screenshot:", w.reports[0]["success"]);

    # Take a screenshot of a specific element
    w = root spawn screenshot(selector="h1");
    print("Element screenshot:", w.reports[0]["success"]);

    # Generate a PDF
    w = root spawn pdf(path="/tmp/example_page.pdf");
    print("\nPDF generated:", w.reports[0]["success"]);
    print("PDF path:", w.reports[0].get("path", "/tmp/example_page.pdf"));

    # PDF with landscape orientation
    w = root spawn pdf(
        path="/tmp/example_landscape.pdf",
        format="A4",
        landscape=True,
        print_background=True
    );
    print("Landscape PDF:", w.reports[0]["success"]);

    # Navigate to a more complex page and screenshot it
    root spawn navigate(url="https://news.ycombinator.com");
    root spawn viewport(width=1440, height=900);

    w = root spawn screenshot(full_page=True);
    print("\nHN full page screenshot:", w.reports[0]["success"]);

    root spawn close_browser();
    print("\nDone. PDFs saved to /tmp/");
}
