# jac-browser Skill

Browser automation for Jac applications using the jac_browser package. Wraps Playwright via 145 walkers for navigation, interaction, screenshots, scraping, state management, and more.

## Installation

```bash
pip install jac-browser
```

## Core Workflow

The fundamental pattern: **launch -> navigate -> snapshot -> interact -> re-snapshot -> close**.

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser, snapshot, click
}

with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://example.com");

    # Snapshot returns an accessibility tree with element refs (@e1, @e2, ...)
    w = root spawn snapshot();
    print(w.reports[0]["snapshot"]);

    # Interact using refs from the snapshot
    root spawn click(ref="e1");

    # Always re-snapshot after page changes
    w = root spawn snapshot();
    print(w.reports[0]["snapshot"]);

    root spawn close_browser();
}
```

## Walker Result Pattern

Every walker reports a dict. Access it via:

```jac
w = root spawn some_walker(params...);
result = w.reports[0];  # First report dict
```

Common keys: `success`, `error`, `snapshot`, `refs`, `base64`, `text`, `html`, `url`, `title`, `cookies`, `value`, `result`.

## Common Patterns

### Navigation

```jac
root spawn launch(headless=True);
root spawn navigate(url="https://example.com");
root spawn go_back();
root spawn go_forward();
root spawn reload();
root spawn close_browser();
```

### Snapshot and Element Refs

```jac
w = root spawn snapshot();
snap = w.reports[0]["snapshot"];   # Accessibility tree text
refs = w.reports[0]["refs"];       # Dict of ref_id -> {role, name}
```

Refs like `e1`, `e2` are used in `click(ref="e1")`, `fill(ref="e2", value="text")`, etc.

### Form Filling

```jac
root spawn fill(selector="#email", value="user@example.com");
root spawn fill(selector="#password", value="secret");
root spawn select_option(selector="#country", value="US");
root spawn check_element(selector="#agree");
root spawn click(selector="button[type='submit']");
```

### Screenshots and PDF

```jac
w = root spawn screenshot();                          # Viewport
w = root spawn screenshot(full_page=True);            # Full page
w = root spawn screenshot(selector=".hero");          # Element
w = root spawn pdf(path="/tmp/page.pdf");             # PDF export
```

### Data Extraction

```jac
w = root spawn get_text(selector=".title");
w = root spawn inner_html(selector=".content");
w = root spawn get_attribute(selector="a", attribute="href");
w = root spawn get_url();
w = root spawn get_title();
w = root spawn element_count(selector=".item");
w = root spawn evaluate(script="document.title");
```

### State Management

```jac
# Save browser state (cookies, localStorage)
root spawn state_save(path="/tmp/state.json");

# Load in a new session
root spawn state_load(path="/tmp/state.json");

# Cookies
root spawn cookies_set(cookies=[{"name": "token", "value": "abc", "domain": "example.com", "path": "/"}]);
w = root spawn cookies_get();

# localStorage
root spawn storage_set(key="theme", value="dark");
w = root spawn storage_get(key="theme");
```

### Dialog Handling

```jac
root spawn dialog(response="accept");                            # Accept all dialogs
root spawn dialog(response="accept", prompt_text="My answer");   # Accept prompts with text
root spawn dialog(response="dismiss");                           # Dismiss all dialogs
root spawn confirm();                                            # Pre-accept next confirm
root spawn deny();                                               # Pre-deny next confirm
```

### Headed Mode (Visible Browser)

```jac
root spawn launch(headless=False);  # Opens visible Chrome window
```

### JavaScript Evaluation

```jac
w = root spawn evaluate(script="document.querySelectorAll('.item').length");
count = w.reports[0]["result"];

# Complex JS - store in variable first (Jac doesn't support multi-line strings in args)
js = "Array.from(document.querySelectorAll('.item')).map(e => e.textContent)";
w = root spawn evaluate(script=js);
items = w.reports[0]["result"];
```

### Network Interception

```jac
root spawn route(url="**/*.png", action="block");       # Block images
root spawn route(url="**/api/**", action="continue");   # Allow API calls
root spawn unroute(url="**/*.png");                      # Remove route
```

### Waiting

```jac
root spawn wait_for(selector=".loaded");                           # Wait for element
root spawn wait_for_url(url="**/dashboard");                       # Wait for URL
root spawn wait_for_load_state(state="networkidle");               # Wait for network
root spawn wait_for_function(expression="window.ready === true");  # Wait for JS condition
```

## Important Notes

1. **Clear stale state between runs**: `rm -rf .jac/data/*.db*` before each run to avoid "Page object not found" errors.

2. **No multi-line strings in walker args**: Jac parser doesn't support multi-line strings inside function calls. Store long strings in variables first.

3. **Ref lifecycle**: Refs are invalidated after page navigation or DOM changes. Always re-snapshot after interactions that change the page.

4. **Walker names**: Use exact walker names from `jac_browser.walkers` (e.g., `check_element` not `check`, `cookies_get` not `cookie_get`, `element_count` not `count_elements`).

## References

- [walkers.md](references/walkers.md) - Complete walker reference (all 145 walkers)
- [examples/](../../examples/) - 30 working example applications

## Templates

- [form_automation.jac](templates/form_automation.jac) - Form filling with validation
- [authenticated_session.jac](templates/authenticated_session.jac) - Login, save state, reuse
- [capture_workflow.jac](templates/capture_workflow.jac) - Content extraction with screenshots
