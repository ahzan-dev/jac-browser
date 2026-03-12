"""Example 03: Web Scraping - Extract data from web pages.

Demonstrates extracting text, HTML, attributes, and structured data
from web pages using various content inspection walkers.

Usage:
    jac run examples/03_web_scraping.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot,
    get_text, inner_text, inner_html, get_html_content,
    get_attribute, get_title, get_url,
    element_count,
    evaluate,
    bounding_box,
    is_visible
}


with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://quotes.toscrape.com/");

    # Get page title
    w = root spawn get_title();
    print("Page title:", w.reports[0]["title"]);

    # Use snapshot to see page structure with element refs
    w = root spawn snapshot();
    print("--- Snapshot (first 500 chars) ---");
    snap = str(w.reports[0]["snapshot"]);
    if len(snap) > 500 {
        print(snap[:500] + "...");
    } else {
        print(snap);
    }

    # Count how many quotes are on the page
    w = root spawn element_count(selector=".quote");
    print("\nNumber of quotes:", w.reports[0]["count"]);

    # Get text content of the first quote
    w = root spawn get_text(selector=".quote:first-child .text");
    print("First quote:", w.reports[0]["text"]);

    # Get the author of the first quote
    w = root spawn inner_text(selector=".quote:first-child .author");
    print("Author:", w.reports[0]["text"]);

    # Get inner HTML (includes markup)
    w = root spawn inner_html(selector=".quote:first-child");
    print("\nFirst quote HTML (first 200 chars):");
    html = str(w.reports[0]["html"]);
    if len(html) > 200 {
        print(html[:200] + "...");
    } else {
        print(html);
    }

    # Get an attribute value
    w = root spawn get_attribute(selector=".quote:first-child small.author", attribute="class");
    print("\nAuthor class:", w.reports[0]["value"]);

    # Check visibility of an element
    w = root spawn is_visible(selector=".quote:first-child");
    print("Quote visible:", w.reports[0]["visible"]);

    # Get bounding box (position and size)
    w = root spawn bounding_box(selector=".quote:first-child");
    print("Quote bounding box:", w.reports[0]["box"]);

    # Use JavaScript to extract structured data
    js = "Array.from(document.querySelectorAll('.quote')).map(function(q) { return {text: q.querySelector('.text').innerText, author: q.querySelector('.author').innerText, tags: Array.from(q.querySelectorAll('.tag')).map(function(t) { return t.innerText; })}; })";
    w = root spawn evaluate(script=js);
    print("\n--- All quotes (structured) ---");
    for q in w.reports[0]["result"] {
        print(q["author"] + ": " + q["text"][:60] + "...");
        print("  Tags:", q["tags"]);
    }

    # Get full page HTML
    w = root spawn get_html_content();
    print("\nFull page HTML length:", len(str(w.reports[0]["html"])), "chars");

    root spawn close_browser();
    print("\nScraping complete.");
}
