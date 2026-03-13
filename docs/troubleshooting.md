# Troubleshooting

Common errors and how to fix them.

---

## "Page object not found"

**Cause:** Stale session data persisted in `.jac/data/*.db*` files. Jac stores session IDs in SQLite between runs, but the actual Playwright browser process is gone.

**Fix:**

```bash
rm -rf .jac/data/*.db*
jac run your_script.jac
```

**Prevention:** This happens on every new run after a previous run ended. Clear the database files before each run, or add cleanup at the end of your scripts.

---

## "Strict mode violation" / "resolved to N elements"

**Cause:** A CSS selector matches multiple elements. Playwright's strict mode requires selectors that match exactly one element.

**Fix:** Use a more specific selector:

```jac
# WRONG -- matches all links on the page
root spawn click(selector="a");

# RIGHT -- match a specific element
root spawn click(selector="a[href='/login']");
root spawn click(selector=".quote:first-child a");
root spawn click(selector="#submit-btn");

# BEST -- use snapshot refs
w = root spawn snapshot();
root spawn click(selector="e3");  # Clicks the third interactive element
```

---

## "Expected 'with' after 'can' ability name"

**Cause:** Using `can` instead of `def` for standalone function declarations.

**Fix:** Use `def` for regular functions:

```jac
# WRONG
can my_function(x: int) -> int {
    return x + 1;
}

# RIGHT
def my_function(x: int) -> int {
    return x + 1;
}
```

Note: `def` functions cannot use `root spawn` -- walker spawning only works in `with entry` blocks.

---

## "Module 'X' not found" for walkers

**Cause:** Using incorrect walker names.

**Fix:** Use the exact names from `jac_browser.walkers`:

| Wrong | Correct |
|-------|---------|
| `cookie_get` | `cookies_get` |
| `cookie_set` | `cookies_set` |
| `count_elements` | `element_count` |
| `wait_for_selector` | `wait_for` |
| `check` | `check_element` |
| `errors` | `errors_get` |
| `set_viewport` | `viewport` |
| `get_html` | `get_html_content` |
| `wait_for_timeout` | (use `evaluate` instead) |

---

## Import errors

**Cause:** Using Python import syntax instead of Jac syntax.

**Fix:**

```jac
# WRONG
import os
from os.path import exists
import:py os

# RIGHT
import from os.path {exists}
import from os {makedirs, remove}
import json;
```

---

## SIGSEGV (exit code 139) with dialogs

**Cause:** Dialog handler stacking -- multiple dialog handlers registered on the same page conflict with each other.

**Fix:** Avoid switching between `dialog()` and `confirm()`/`deny()` on the same page. If you need to handle different dialog types, navigate to `about:blank` between sections to reset handlers:

```jac
# Handle alerts with dialog()
root spawn dialog(action="accept");
root spawn evaluate(script="alert('hello')");

# Navigate away to reset handlers
root spawn navigate(url="about:blank");

# Now safe to use confirm()
root spawn navigate(url="https://example.com");
root spawn confirm();
root spawn evaluate(script="confirm('ok?')");
```

---

## "No multi-line string" parse errors

**Cause:** Jac doesn't support multi-line strings inside function call arguments.

**Fix:** Store long strings in a variable first:

```jac
# WRONG
root spawn evaluate(script="
    var items = document.querySelectorAll('.item');
    return items.length;
");

# RIGHT
js = "document.querySelectorAll('.item').length";
root spawn evaluate(script=js);
```

---

## Screenshots return empty base64

**Cause:** The page hasn't finished loading when the screenshot is taken.

**Fix:** Wait for the page to load:

```jac
root spawn navigate(url="https://example.com");
root spawn wait_for_load_state(state="load");        # Basic load
root spawn wait_for_load_state(state="networkidle");  # Wait for all network requests

w = root spawn screenshot();
print(len(w.reports[0]["base64"]));  # Should be > 0
```

---

## "Browser not launched" errors

**Cause:** Calling walkers before `launch()` or after `close_browser()`.

**Fix:** Always launch first and close last:

```jac
with entry {
    root spawn launch(headless=True);   # FIRST
    # ... all your browser work ...
    root spawn close_browser();          # LAST
}
```

---

## Playwright not installed

**Error:** `Playwright browser not found` or similar.

**Fix:**

```bash
playwright install chromium
```

If that fails:

```bash
pip install playwright
playwright install chromium
```

On Linux, you may also need system dependencies:

```bash
playwright install-deps chromium
```

---

## Slow test execution

**Tips for faster runs:**

1. Use `headless=True` (default) -- visible browsers are slower
2. Block unnecessary resources:
   ```jac
   root spawn route(url_pattern="**/*.png", handler_type="abort");
   root spawn route(url_pattern="**/*.jpg", handler_type="abort");
   root spawn route(url_pattern="**/*.woff2", handler_type="abort");
   ```
3. Use `wait_for_load_state(state="load")` instead of `"networkidle"` when possible
4. Avoid unnecessary `screenshot()` calls -- they're expensive

---

## Running behind a proxy

Set the `HTTP_PROXY` and `HTTPS_PROXY` environment variables before running:

```bash
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
jac run your_script.jac
```

---

## Getting help

- Check the [examples/](../examples/) directory for 30 working programs
- See the [Jac Syntax Guide](jac-syntax-guide.md) for language-specific tips
- File issues at the project repository
