"""Example 28: Real World Scraper - Multi-page data extraction workflow.

Demonstrates a realistic scraping workflow: navigate across multiple pages,
extract structured data, follow links, and aggregate results.

Usage:
    jac run examples/28_real_world_scraper.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    get_text, click, element_count, evaluate,
    wait_for, get_title, get_url
}


with entry {
    root spawn launch(headless=True);

    # --- Page 1: Scrape quotes listing ---
    print("=== Page 1: Quotes listing ===");
    root spawn navigate(url="https://quotes.toscrape.com");

    # Count total quotes on page
    w = root spawn element_count(selector=".quote");
    total = w.reports[0]["count"];
    print("Quotes on page 1:", total);

    # Extract all quotes with author and tags using JS
    js = "Array.from(document.querySelectorAll('.quote')).map(q => ({text: q.querySelector('.text').innerText, author: q.querySelector('.author').innerText, tags: Array.from(q.querySelectorAll('.tag')).map(t => t.innerText)}))";
    w = root spawn evaluate(script=js);
    quotes_p1 = w.reports[0]["result"];

    print("\nPage 1 quotes:");
    for q in quotes_p1 {
        author = q["author"];
        text = q["text"][:60];
        tags = q["tags"];
        print("  ", author, "-", text, "...");
        print("    Tags:", tags);
    }

    # --- Page 2: Navigate to next page ---
    print("\n=== Page 2: Next page ===");
    root spawn click(selector="li.next a");
    root spawn wait_for(selector="li.next a");

    w = root spawn get_url();
    print("URL:", w.reports[0]["url"]);

    w = root spawn element_count(selector=".quote");
    print("Quotes on page 2:", w.reports[0]["count"]);

    # Extract page 2 quotes
    w = root spawn evaluate(script=js);
    quotes_p2 = w.reports[0]["result"];

    print("\nPage 2 quotes:");
    for q in quotes_p2 {
        author = q["author"];
        text = q["text"][:60];
        print("  ", author, "-", text, "...");
    }

    # --- Follow an author link ---
    print("\n=== Author detail page ===");
    root spawn click(selector=".quote:first-child a[href*='/author/']");
    root spawn wait_for(selector=".author-title");

    w = root spawn get_text(selector=".author-title");
    print("Author:", w.reports[0]["text"]);

    w = root spawn get_text(selector=".author-born-date");
    print("Born:", w.reports[0]["text"]);

    w = root spawn get_text(selector=".author-born-location");
    print("Location:", w.reports[0]["text"]);

    w = root spawn get_text(selector=".author-description");
    desc = w.reports[0]["text"][:200];
    print("Bio:", desc, "...");

    # --- Aggregate results ---
    all_quotes = quotes_p1 + quotes_p2;
    print("\n=== Summary ===");
    print("Total quotes scraped:", len(all_quotes));

    # Count unique authors
    authors: list = [];
    for q in all_quotes {
        if q["author"] not in authors {
            authors.append(q["author"]);
        }
    }
    print("Unique authors:", len(authors));
    print("Authors:", authors);

    # Count all tags
    all_tags: list = [];
    for q in all_quotes {
        for t in q["tags"] {
            if t not in all_tags {
                all_tags.append(t);
            }
        }
    }
    print("Unique tags:", len(all_tags));

    root spawn close_browser();
    print("\nDone.");
}
