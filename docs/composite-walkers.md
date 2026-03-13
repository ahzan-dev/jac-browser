# Composite Walkers

Composite walkers are multi-step automation patterns unique to jac-browser. They combine multiple primitive browser operations into single, higher-level walkers. These have no equivalent in agent-browser.

## Why Composites?

Primitive walkers do one thing: `click`, `fill`, `navigate`, `snapshot`. Real automation tasks require sequences of these operations. Composite walkers encapsulate common sequences so you write less code and get more done.

| Instead of | Use |
|------------|-----|
| navigate + fill + fill + click + wait | `login` |
| navigate + wait + evaluate + screenshot | `scrape` |
| loop: evaluate + click next + repeat | `paginate` |
| snapshot + search refs + click | `smart_click` |
| loop: navigate + evaluate + find links | `crawl` |
| snapshot + screenshot + metadata | `observe` |
| loop: evaluate + sleep + retry | `retry` |
| fill + fill + check + select + click | `fill_form` |

## Import

```jac
import from jac_browser.composites {
    login, fill_form, scrape, paginate,
    smart_click, crawl, retry, observe
}
```

---

## login

Navigate to a login page, fill username and password, click submit, and optionally save browser state for future runs.

```jac
w = root spawn login(
    url="https://example.com/login",
    username_selector="#username",
    password_selector="#password",
    username="myuser",
    password="mypass",
    submit_selector="button[type='submit']",
    save_state_path="/tmp/auth.json"    # optional
);
r = w.reports[0];
# r = {success, url, title, state_saved, state_path}
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | str | `""` | Login page URL |
| `username_selector` | str | `"#username"` | CSS selector for username field |
| `password_selector` | str | `"#password"` | CSS selector for password field |
| `username` | str | `""` | Username to fill |
| `password` | str | `""` | Password to fill |
| `submit_selector` | str | `"button[type='submit']"` | CSS selector for submit button |
| `save_state_path` | str | `""` | If set, saves cookies+storage to this path |

---

## fill_form

Fill multiple form fields, check checkboxes, select dropdowns, and optionally submit -- all in one call. Requires the browser to already be on the form page.

```jac
w = root spawn fill_form(
    fields={"#name": "John", "#email": "john@example.com", "#phone": "555-1234"},
    checks=["#agree-terms", "#newsletter"],
    selects={"#country": "US", "#plan": "pro"},
    submit_selector="#submit-btn"
);
r = w.reports[0];
# r = {success, fields_filled, checks_checked, selects_selected, submitted, url}
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `fields` | dict | `{}` | Map of selector -> value for text fields |
| `checks` | list | `[]` | List of selectors for checkboxes to check |
| `selects` | dict | `{}` | Map of selector -> value for dropdowns |
| `submit_selector` | str | `""` | If set, clicks this to submit the form |

---

## scrape

Navigate to a URL, wait for it to load, extract structured data via JavaScript, and optionally take a screenshot.

```jac
js = "Array.from(document.querySelectorAll('.product')).map(p => ({name: p.querySelector('h2').textContent, price: p.querySelector('.price').textContent}))";
w = root spawn scrape(
    url="https://example.com/products",
    extract_script=js,
    wait_selector=".product",
    include_screenshot=True
);
r = w.reports[0];
# r = {success, url, title, data, screenshot_base64}
products = r["data"];  # list of {name, price} dicts
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | str | `""` | URL to scrape |
| `extract_script` | str | `""` | JavaScript that returns data (if empty, returns full page HTML) |
| `wait_selector` | str | `""` | Wait for this element before extracting |
| `include_screenshot` | bool | `False` | Include base64 screenshot in result |

---

## paginate

Extract data from multiple pages by repeatedly clicking a "next" button. Stops when the next button is not found or `max_pages` is reached.

```jac
w = root spawn paginate(
    url="https://example.com/list",
    extract_script="Array.from(document.querySelectorAll('.item')).map(e => e.textContent)",
    next_selector=".next-page a",
    max_pages=5
);
r = w.reports[0];
# r = {success, pages_scraped, data}
# data = [{page: 1, url: "...", data: [...]}, {page: 2, ...}, ...]
for page in r["data"] {
    print("Page", page["page"], ":", len(page["data"]), "items");
}
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | str | `""` | Starting URL |
| `extract_script` | str | `""` | JavaScript to extract data from each page |
| `next_selector` | str | `""` | CSS selector for the "next page" button/link |
| `max_pages` | int | `10` | Maximum number of pages to scrape |
| `wait_state` | str | `"load"` | Wait state between page loads |

---

## smart_click

Find an element by its visible text (and optionally ARIA role) using snapshot analysis, then click it. No CSS selectors needed -- just describe what you want to click.

```jac
# Click the "Login" link
w = root spawn smart_click(text="Login");

# Click the second "About" link
w = root spawn smart_click(text="About", index=1);

# Click a button specifically (not a link with the same text)
w = root spawn smart_click(text="Submit", role="button");

r = w.reports[0];
# r = {success, clicked_ref, clicked_role, clicked_name, total_matches, url}
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text` | str | `""` | Text to search for (case-insensitive substring match) |
| `role` | str | `""` | ARIA role filter (e.g., "link", "button", "textbox") |
| `index` | int | `0` | Which match to click (0 = first) |

---

## crawl

Starting from a URL, discover links matching a regex pattern, follow them up to `max_depth`, and extract data from each page.

```jac
w = root spawn crawl(
    url="https://example.com",
    link_pattern="/products/",     # regex pattern for links to follow
    extract_script="document.title",
    max_pages=10,
    max_depth=2
);
r = w.reports[0];
# r = {success, pages_crawled, urls_visited, data}
# data = [{url: "...", depth: 0, data: "..."}, ...]
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | str | `""` | Starting URL |
| `link_pattern` | str | `""` | Regex pattern to filter which links to follow |
| `extract_script` | str | `""` | JavaScript to extract data from each page |
| `max_pages` | int | `10` | Maximum total pages to visit |
| `max_depth` | int | `2` | Maximum link depth from starting URL |

---

## retry

Evaluate a JavaScript expression repeatedly until it returns a truthy value, with configurable retries and delay between attempts.

```jac
# Wait for a dynamic element to appear
w = root spawn retry(
    script="document.querySelector('.loaded-content') !== null",
    retries=5,
    delay_ms=1000
);
r = w.reports[0];
# r = {success, result, attempts} or {success: false, error, last_result, attempts}
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `script` | str | `""` | JavaScript expression to evaluate |
| `retries` | int | `3` | Maximum number of attempts |
| `delay_ms` | int | `1000` | Milliseconds to wait between retries |

---

## observe

Get everything an AI agent needs to understand a page in one call: URL, title, ARIA snapshot with element refs, and optionally a screenshot and HTML.

```jac
w = root spawn observe(include_screenshot=True, include_html=False);
r = w.reports[0];
# r = {success, url, title, snapshot, refs, element_count, screenshot_base64}

print(r["snapshot"]);     # ARIA accessibility tree
print(r["element_count"]); # number of interactive elements

# refs are persisted to the graph, so subsequent clicks work:
root spawn click(selector="e3");
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `include_screenshot` | bool | `True` | Include base64 screenshot |
| `include_html` | bool | `False` | Include full page HTML |

The `observe` walker also persists the snapshot to the session graph, so element refs (e1, e2, ...) are available for subsequent `click`, `fill`, etc. calls.
