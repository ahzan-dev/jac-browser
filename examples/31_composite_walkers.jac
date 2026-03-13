"""Example 31: Composite Walkers - Multi-step automation in a single call.

Demonstrates jac-browser's composite walkers that combine multiple
primitive operations into higher-level automation patterns.

Usage:
    jac run examples/31_composite_walkers.jac
"""

import json;

import from jac_browser.walkers {
    launch, navigate, close_browser,
    set_content, wait_for_load_state
}

import from jac_browser.composites {
    login, fill_form, scrape, paginate,
    smart_click, crawl, retry, observe
}


with entry {
    root spawn launch(headless=True);

    # =================================================================
    # 1. observe - snapshot + screenshot + metadata in one call
    # =================================================================
    print("=== 1. observe ===");
    root spawn navigate(url="https://quotes.toscrape.com");
    root spawn wait_for_load_state(state="load");

    w = root spawn observe(include_screenshot=True, include_html=False);
    r = w.reports[0];
    print("URL:", r["url"]);
    print("Title:", r["title"]);
    print("Elements:", r["element_count"]);
    print("Snapshot preview:", r["snapshot"][:150], "...");
    has_screenshot = "screenshot_base64" in r;
    print("Screenshot included:", has_screenshot);

    # =================================================================
    # 2. smart_click - find and click by text, not selector
    # =================================================================
    print("\n=== 2. smart_click ===");
    root spawn navigate(url="https://quotes.toscrape.com");
    root spawn wait_for_load_state(state="load");

    w = root spawn smart_click(text="Login");
    r = w.reports[0];
    print("Clicked:", r.get("clicked_name", ""), "(ref:", r.get("clicked_ref", "") + ")");
    print("Now at:", r.get("url", ""));

    # =================================================================
    # 3. login - full login flow in one call
    # =================================================================
    print("\n=== 3. login ===");
    w = root spawn login(
        url="https://quotes.toscrape.com/login",
        username_selector="#username",
        password_selector="#password",
        username="testuser",
        password="testpass",
        submit_selector="input[type='submit']"
    );
    r = w.reports[0];
    print("Login success:", r["success"]);
    print("Landed at:", r.get("url", ""));

    # =================================================================
    # 4. fill_form - fill multiple fields at once
    # =================================================================
    print("\n=== 4. fill_form ===");
    html = "<html><body><form id='f'>";
    html = html + "<input id='name' type='text'>";
    html = html + "<input id='email' type='text'>";
    html = html + "<input id='agree' type='checkbox'>";
    html = html + "<select id='plan'><option value='free'>Free</option><option value='pro'>Pro</option></select>";
    html = html + "<button type='submit'>Submit</button>";
    html = html + "</form></body></html>";
    root spawn set_content(html=html);

    w = root spawn fill_form(
        fields={"#name": "John Doe", "#email": "john@example.com"},
        checks=["#agree"],
        selects={"#plan": "pro"}
    );
    r = w.reports[0];
    print("Fields filled:", r["fields_filled"]);
    print("Checks checked:", r["checks_checked"]);
    print("Selects selected:", r["selects_selected"]);
    print("Submitted:", r["submitted"]);

    # =================================================================
    # 5. scrape - navigate + extract data in one call
    # =================================================================
    print("\n=== 5. scrape ===");
    js = "Array.from(document.querySelectorAll('.quote')).map(q => ({text: q.querySelector('.text').innerText.slice(0, 50), author: q.querySelector('.author').innerText}))";
    w = root spawn scrape(
        url="https://quotes.toscrape.com",
        extract_script=js,
        include_screenshot=False
    );
    r = w.reports[0];
    print("Scraped from:", r["title"]);
    data = r.get("data", []);
    print("Items extracted:", len(data));
    if data {
        print("First:", data[0]["author"], "-", data[0]["text"]);
    }

    # =================================================================
    # 6. paginate - scrape across multiple pages
    # =================================================================
    print("\n=== 6. paginate ===");
    extract_js = "Array.from(document.querySelectorAll('.quote .author')).map(a => a.textContent)";
    w = root spawn paginate(
        url="https://quotes.toscrape.com",
        extract_script=extract_js,
        next_selector="li.next a",
        max_pages=3
    );
    r = w.reports[0];
    print("Pages scraped:", r["pages_scraped"]);
    for page_data in r["data"] {
        authors = page_data["data"];
        count = len(authors) if authors else 0;
        print("  Page", page_data["page"], ":", count, "authors");
    }

    # =================================================================
    # 7. retry - retry JS until truthy
    # =================================================================
    print("\n=== 7. retry ===");
    root spawn navigate(url="https://quotes.toscrape.com");
    root spawn wait_for_load_state(state="load");

    w = root spawn retry(
        script="document.querySelector('.quote') ? true : false",
        retries=3,
        delay_ms=500
    );
    r = w.reports[0];
    print("Retry success:", r["success"]);
    print("Attempts:", r.get("attempts", "?"));

    # =================================================================
    # 8. crawl - follow links and extract data
    # =================================================================
    print("\n=== 8. crawl ===");
    crawl_js = "document.title";
    w = root spawn crawl(
        url="https://quotes.toscrape.com",
        link_pattern="/author/",
        extract_script=crawl_js,
        max_pages=3,
        max_depth=1
    );
    r = w.reports[0];
    print("Pages crawled:", r["pages_crawled"]);
    for entry in r["data"] {
        print("  depth=" + str(entry["depth"]), entry["url"][:50], "->", entry["data"]);
    }

    root spawn close_browser();
    print("\nAll composite walkers verified.");
}
