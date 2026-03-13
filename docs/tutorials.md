# Tutorials

Step-by-step guides for common browser automation tasks with jac-browser.

---

## Tutorial 1: Scraping Data from a Website

Extract structured data from a multi-page website.

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, evaluate, click,
    wait_for_load_state
}

with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://quotes.toscrape.com");
    root spawn wait_for_load_state(state="load");

    # Extract quotes using JavaScript
    js = "Array.from(document.querySelectorAll('.quote')).map(q => ({text: q.querySelector('.text').innerText, author: q.querySelector('.author').innerText}))";
    w = root spawn evaluate(script=js);
    quotes = w.reports[0]["result"];

    print("Found", len(quotes), "quotes:");
    for q in quotes {
        print("  ", q["author"], "-", q["text"][:60], "...");
    }

    # Navigate to page 2
    root spawn click(selector="li.next a");
    root spawn wait_for_load_state(state="load");

    # Extract page 2 quotes
    w = root spawn evaluate(script=js);
    page2 = w.reports[0]["result"];
    print("\nPage 2:", len(page2), "quotes");

    root spawn close_browser();
}
```

**Key concepts:**
- Use `evaluate` with JavaScript to extract structured data
- Store long JS strings in variables first (Jac limitation)
- Use `wait_for_load_state` after navigation to ensure the page is ready
- Use specific CSS selectors for `click` to avoid strict mode errors

---

## Tutorial 2: Filling and Submitting Forms

Automate login forms, search boxes, and multi-field forms.

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, fill, click, get_url,
    wait_for_load_state
}

with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://quotes.toscrape.com/login");

    # Step 1: Snapshot to discover form elements
    w = root spawn snapshot();
    print("Form structure:");
    print(w.reports[0]["snapshot"]);

    # Step 2: Fill form fields using CSS selectors
    root spawn fill(selector="#username", value="testuser");
    root spawn fill(selector="#password", value="testpassword");

    # Step 3: Submit the form
    root spawn click(selector="input[type='submit']");
    root spawn wait_for_load_state(state="load");

    # Step 4: Verify the result
    w = root spawn get_url();
    print("After login:", w.reports[0]["url"]);

    w = root spawn snapshot();
    print(w.reports[0]["snapshot"][:300]);

    root spawn close_browser();
}
```

**Key concepts:**
- Always `snapshot` first to understand the form structure
- `fill` clears the field before typing (use `type_text` for append behavior)
- Use `wait_for_load_state` after form submission to wait for the response
- Verify results by checking URL or page content

---

## Tutorial 3: Taking Screenshots and PDFs

Capture visual evidence of pages.

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    screenshot, pdf, viewport,
    wait_for_load_state
}

with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://quotes.toscrape.com");
    root spawn wait_for_load_state(state="networkidle");

    # Viewport screenshot (what you see in the browser)
    w = root spawn screenshot();
    print("Viewport screenshot:", len(w.reports[0]["base64"]), "base64 chars");

    # Full page screenshot (entire scrollable page)
    w = root spawn screenshot(full_page=True);
    print("Full page screenshot:", len(w.reports[0]["base64"]), "base64 chars");

    # Save screenshot to file
    w = root spawn screenshot(path="/tmp/page.png");
    print("Saved to:", w.reports[0]["path"]);

    # Generate PDF
    w = root spawn pdf(path="/tmp/page.pdf");
    print("PDF saved to:", w.reports[0]["path"]);

    # Mobile screenshot
    root spawn viewport(width=375, height=667);
    w = root spawn screenshot(path="/tmp/mobile.png");
    print("Mobile screenshot saved");

    root spawn close_browser();
}
```

---

## Tutorial 4: Managing Browser State (Login Once, Reuse)

Save cookies and localStorage after login so subsequent runs skip the login flow.

```jac
import from os.path {exists}
import from os {remove}

import from jac_browser.walkers {
    launch, navigate, close_browser,
    fill, click, get_url,
    state_save, state_load,
    wait_for_load_state, cookies_get
}

with entry {
    state_file = "/tmp/my_auth_state.json";
    root spawn launch(headless=True);

    if exists(state_file) {
        # Fast path: load saved state, skip login
        print("Loading saved state...");
        root spawn state_load(path=state_file);
        root spawn navigate(url="https://quotes.toscrape.com");
        print("Restored session - login skipped!");
    } else {
        # Slow path: perform login, then save state
        print("No saved state. Logging in...");
        root spawn navigate(url="https://quotes.toscrape.com/login");
        root spawn fill(selector="#username", value="testuser");
        root spawn fill(selector="#password", value="testpassword");
        root spawn click(selector="input[type='submit']");
        root spawn wait_for_load_state(state="load");

        # Save state for next run
        root spawn state_save(path=state_file);
        print("State saved to", state_file);
    }

    # Do authenticated work
    w = root spawn get_url();
    print("Current URL:", w.reports[0]["url"]);

    w = root spawn cookies_get();
    print("Cookies:", len(w.reports[0]["cookies"]));

    root spawn close_browser();

    # Cleanup for demo (remove this in real use)
    if exists(state_file) {
        remove(state_file);
    }
}
```

**Key concepts:**
- `state_save` captures cookies, localStorage, and sessionStorage
- `state_load` restores them in a new browser session
- Check with `os.path.exists` whether a state file exists before loading
- This pattern is essential for automating sites that require authentication

---

## Tutorial 5: Multi-Tab Workflows

Work with multiple tabs simultaneously.

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    tab_new, tab_list, tab_switch, tab_close,
    get_title, get_url
}

with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://quotes.toscrape.com");

    w = root spawn get_title();
    print("Tab 1:", w.reports[0]["title"]);

    # Open a second tab
    root spawn tab_new(url="https://quotes.toscrape.com/login");
    w = root spawn get_title();
    print("Tab 2:", w.reports[0]["title"]);

    # List all tabs
    w = root spawn tab_list();
    tabs = w.reports[0]["tabs"];
    print("\nAll tabs:");
    for t in tabs {
        active = " (active)" if t["is_active"] else "";
        print("  ", t["page_id"][:8], "-", t["url"], active);
    }

    # Switch back to first tab
    root spawn tab_switch(page_id=tabs[0]["page_id"]);
    w = root spawn get_title();
    print("\nSwitched back to:", w.reports[0]["title"]);

    # Close the second tab
    root spawn tab_close(page_id=tabs[1]["page_id"]);
    print("Closed tab 2");

    root spawn close_browser();
}
```

---

## Tutorial 6: Headed Mode (Visible Browser)

Launch a visible browser window for debugging or demos.

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot, fill, click,
    evaluate, wait_for_load_state
}

with entry {
    # Launch with visible browser window
    root spawn launch(headless=False);

    root spawn navigate(url="https://quotes.toscrape.com");
    root spawn wait_for_load_state(state="load");

    # Pause so you can see the browser
    root spawn evaluate(script="new Promise(r => setTimeout(r, 2000))");

    # Navigate to login
    root spawn navigate(url="https://quotes.toscrape.com/login");
    root spawn wait_for_load_state(state="load");

    # Fill form (you can watch it happen)
    root spawn fill(selector="#username", value="testuser");
    root spawn evaluate(script="new Promise(r => setTimeout(r, 500))");
    root spawn fill(selector="#password", value="testpassword");
    root spawn evaluate(script="new Promise(r => setTimeout(r, 500))");

    # Submit
    root spawn click(selector="input[type='submit']");
    root spawn wait_for_load_state(state="load");

    # Pause to see the result
    root spawn evaluate(script="new Promise(r => setTimeout(r, 2000))");

    w = root spawn screenshot();
    print("Screenshot taken:", len(w.reports[0]["base64"]), "chars");

    root spawn close_browser();
}
```

**Key concepts:**
- `headless=False` opens a visible Chrome/Chromium window
- Use `evaluate(script="new Promise(r => setTimeout(r, ms))")` for pauses (there's no `wait_for_timeout` walker)
- Useful for debugging and demonstrations

---

## Tutorial 7: AI Agent Loop (Snapshot-Ref Cycle)

The primary pattern for building AI agents that browse the web autonomously.

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, click, fill
}

with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://quotes.toscrape.com");

    # Step 1: Snapshot to "see" the page
    w = root spawn snapshot();
    snap = w.reports[0]["snapshot"];
    refs = w.reports[0]["refs"];

    print("Page structure:");
    print(snap[:300]);
    print("\nInteractive elements:");
    for (ref_id, info) in refs.items() {
        print("  ", ref_id, ":", info["role"], "-", info["name"]);
    }

    # Step 2: Find and click a target element
    target = "";
    for (ref_id, info) in refs.items() {
        if info["role"] == "link" and "Login" in info["name"] {
            target = ref_id;
        }
    }

    if target {
        print("\nClicking:", target);
        root spawn click(selector=target);

        # Step 3: Re-snapshot to see the new page
        w = root spawn snapshot();
        new_refs = w.reports[0]["refs"];

        # Step 4: Find form fields and fill them
        for (ref_id, info) in new_refs.items() {
            if info["role"] == "textbox" {
                if "user" in info["name"].lower() {
                    root spawn fill(selector=ref_id, value="agent_user");
                    print("Filled", ref_id, "with username");
                }
                if "pass" in info["name"].lower() {
                    root spawn fill(selector=ref_id, value="agent_pass");
                    print("Filled", ref_id, "with password");
                }
            }
        }
    }

    root spawn close_browser();
}
```

**Key concepts:**
- The **snapshot-ref cycle** is how AI agents perceive and interact with web pages
- Refs like `e1`, `e2` map to actual page elements -- pass them to `click`, `fill`, etc.
- Always re-snapshot after actions that change the page (clicks, navigation, form submissions)
- Refs are invalidated by page changes -- never reuse refs from a previous snapshot

---

## Tutorial 8: Network Interception

Block resources, mock API responses, and log network activity.

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    route, unroute, requests_get,
    wait_for_load_state
}

with entry {
    root spawn launch(headless=True);

    # Block images and fonts for faster loading
    root spawn route(url_pattern="**/*.png", handler_type="abort");
    root spawn route(url_pattern="**/*.jpg", handler_type="abort");
    root spawn route(url_pattern="**/*.woff2", handler_type="abort");

    root spawn navigate(url="https://quotes.toscrape.com");
    root spawn wait_for_load_state(state="load");

    # Check captured requests
    w = root spawn requests_get();
    requests = w.reports[0]["requests"];
    print("Captured", len(requests), "requests:");
    for r in requests[:5] {
        print("  ", r["method"], r["url"][:60]);
    }

    # Remove a route
    root spawn unroute(url_pattern="**/*.png");

    root spawn close_browser();
}
```

---

## Tutorial 9: Device Emulation

Test your app on mobile devices and different configurations.

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    device, device_list, viewport,
    useragent, screenshot,
    wait_for_load_state
}

with entry {
    root spawn launch(headless=True);

    # List available device presets
    w = root spawn device_list();
    devices = w.reports[0]["devices"];
    print("Available devices:", len(devices));
    for d in devices[:5] {
        print("  -", d);
    }

    # Emulate iPhone 12
    root spawn device(name="iPhone 12");
    root spawn navigate(url="https://quotes.toscrape.com");
    root spawn wait_for_load_state(state="load");

    w = root spawn screenshot(path="/tmp/iphone12.png");
    print("\niPhone 12 screenshot saved");

    # Switch to desktop
    root spawn viewport(width=1920, height=1080);
    root spawn useragent(ua="Mozilla/5.0 (X11; Linux x86_64) Chrome/120.0.0.0");

    w = root spawn screenshot(path="/tmp/desktop.png");
    print("Desktop screenshot saved");

    root spawn close_browser();
}
```

---

## Tutorial 10: Visual Regression Testing

Compare page snapshots and screenshots to detect changes.

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot, evaluate,
    diff_snapshot, diff_screenshot,
    wait_for_load_state
}

with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://quotes.toscrape.com");
    root spawn wait_for_load_state(state="load");

    # Take baseline
    w = root spawn snapshot();
    baseline_snap = w.reports[0]["snapshot"];
    root spawn screenshot(path="/tmp/baseline.png");
    print("Baseline captured");

    # Mutate the page (simulate a change)
    js = "document.querySelector('h1').textContent = 'CHANGED TITLE'";
    root spawn evaluate(script=js);

    # Take new snapshot
    w = root spawn snapshot();
    changed_snap = w.reports[0]["snapshot"];
    root spawn screenshot(path="/tmp/changed.png");
    print("Changed version captured");

    # Compare snapshots (text diff)
    w = root spawn diff_snapshot(snap1=baseline_snap, snap2=changed_snap);
    diff = w.reports[0];
    print("\nSnapshot diff:");
    print("  Changed:", diff["changed"]);
    print("  Diff:", diff.get("diff", "")[:200]);

    # Compare screenshots (pixel diff)
    w = root spawn diff_screenshot(path1="/tmp/baseline.png", path2="/tmp/changed.png");
    diff_img = w.reports[0];
    print("\nScreenshot diff:");
    print("  Match:", diff_img.get("match", ""));

    root spawn close_browser();
}
```

---

## Next Steps

- See all [30 examples](../examples/) for complete working programs
- Check the [Walker Reference](../README.md#walker-reference) for all 145 walkers
- Read the [Jac Syntax Guide](jac-syntax-guide.md) for language-specific tips
- See the [API Reference](api-reference.md) for REST API usage
