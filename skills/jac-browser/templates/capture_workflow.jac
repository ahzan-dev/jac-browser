"""Template: Capture Workflow - Extract content with screenshots.

Demonstrates capturing page metadata, text content, screenshots,
and structured data from a website.

Usage:
    jac run skills/jac-browser/templates/capture_workflow.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot, pdf,
    get_text, get_title, get_url,
    get_html_content, evaluate,
    wait_for_load_state
}


with entry {
    root spawn launch(headless=True);
    print("=== Capture Workflow Template ===\n");

    # --- Step 1: Navigate ---
    root spawn navigate(url="https://quotes.toscrape.com");
    root spawn wait_for_load_state(state="networkidle");

    # --- Step 2: Capture metadata ---
    print("--- Page Metadata ---");
    w = root spawn get_title();
    print("Title:", w.reports[0]["title"]);

    w = root spawn get_url();
    print("URL:", w.reports[0]["url"]);

    # --- Step 3: Take screenshot ---
    print("\n--- Screenshots ---");
    w = root spawn screenshot();
    print("Viewport screenshot:", len(w.reports[0]["base64"]), "base64 chars");

    w = root spawn screenshot(full_page=True);
    print("Full page screenshot:", len(w.reports[0]["base64"]), "base64 chars");

    # --- Step 4: Get page structure via snapshot ---
    print("\n--- Page Structure (snapshot) ---");
    w = root spawn snapshot();
    snap = w.reports[0]["snapshot"];
    refs = w.reports[0]["refs"];
    print("Snapshot length:", len(snap), "chars");
    print("Interactive elements:", len(refs));
    print("First 500 chars:");
    print(snap[:500]);

    # --- Step 5: Extract text content ---
    print("\n--- Text Extraction ---");
    w = root spawn get_text(selector="h1");
    print("H1:", w.reports[0]["text"]);

    # --- Step 6: Extract structured data via JS ---
    print("\n--- Structured Data ---");
    js = "Array.from(document.querySelectorAll('.quote')).map(q => ({text: q.querySelector('.text').innerText.slice(0, 80), author: q.querySelector('.author').innerText}))";
    w = root spawn evaluate(script=js);
    data = w.reports[0]["result"];

    print("Extracted", len(data), "items:");
    for item in data {
        print("  ", item["author"], "-", item["text"], "...");
    }

    # --- Step 7: Save as PDF ---
    print("\n--- PDF Export ---");
    w = root spawn pdf(path="/tmp/jac_capture.pdf");
    print("PDF saved to:", w.reports[0]["path"]);

    # --- Step 8: Get full HTML ---
    print("\n--- HTML Content ---");
    w = root spawn get_html_content();
    html_len = len(w.reports[0]["html"]);
    print("Full HTML:", html_len, "chars");

    root spawn close_browser();
    print("\nCapture complete.");
}
