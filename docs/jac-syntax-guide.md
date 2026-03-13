# Jac Syntax Guide for Browser Automation

Jac has some syntax differences from Python that matter when writing browser automation code. This guide covers the patterns you need to know.

## Imports

Jac uses its own import syntax:

```jac
# Import walkers from jac_browser
import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, click, fill
}

# Import Python standard library functions
import from os.path {exists}
import from os {makedirs, remove}

# Import Python modules directly
import json;
```

Do NOT use Python-style imports:

```python
# WRONG - these don't work in Jac
import os
from os.path import exists
import:py os
```

## Entry Point

Every Jac program needs a `with entry` block as its main function:

```jac
with entry {
    print("Hello from Jac!");
    root spawn launch(headless=True);
    # ... your code here ...
    root spawn close_browser();
}
```

## Spawning Walkers

All browser actions are walkers. Spawn them with `root spawn`:

```jac
# Spawn a walker and capture its result
w = root spawn navigate(url="https://example.com");
result = w.reports[0];
print(result["url"]);

# Spawn a walker without capturing the result
root spawn close_browser();
```

## Variables and Types

```jac
# Type annotations are optional but supported
url: str = "https://example.com";
count: int = 0;
items: list = [];
data: dict = {};

# Without annotations
url = "https://example.com";
count = 0;
```

## Control Flow

```jac
# If/else
if count > 0 {
    print("Found items");
} else {
    print("No items");
}

# For loops
for item in items {
    print(item);
}

# For loop with dict items
for (key, value) in my_dict.items() {
    print(key, "=", value);
}

# While loops
while count < 10 {
    count += 1;
}

# Break/continue work as expected
for item in items {
    if item == "stop" {
        break;
    }
}
```

## Strings

```jac
# Single or double quotes
name = "hello";
name = 'hello';

# String concatenation
msg = "Hello " + name;

# String formatting -- use concatenation, not f-strings
print("Count: " + str(count));

# Slicing works
first_100 = long_string[:100];
```

## Global Variables

Use `glob` for module-level variables:

```jac
glob TARGET_URL: str = "https://example.com";
glob OUTPUT_DIR: str = "/tmp/output";
glob issues: list = [];

with entry {
    print(TARGET_URL);  # Access glob directly
    issues.append("item");  # Modify glob directly
}
```

## Functions

Use `def` for standalone functions (NOT `can`):

```jac
def add(a: int, b: int) -> int {
    return a + b;
}

with entry {
    result = add(1, 2);
    print(result);
}
```

**Important:** Standalone `def` functions cannot use `root spawn` -- walker spawning only works inside `with entry` blocks and walker definitions. If your function needs to call walkers, inline the logic into `with entry` instead.

```jac
# WRONG -- can't use root spawn in a def function
def take_screenshot() {
    w = root spawn screenshot();  # This won't work!
    return w.reports[0];
}

# RIGHT -- inline it in with entry
with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://example.com");
    w = root spawn screenshot();
    print("Screenshot:", len(w.reports[0]["base64"]), "chars");
    root spawn close_browser();
}
```

## Common Gotchas

### 1. No multi-line strings in function arguments

```jac
# WRONG
root spawn evaluate(script="
    var x = 1;
    var y = 2;
    return x + y;
");

# RIGHT -- store in a variable first
js = "var x = 1; var y = 2; x + y";
root spawn evaluate(script=js);
```

### 2. Semicolons are required

Every statement in Jac ends with a semicolon:

```jac
x = 1;
print(x);
root spawn navigate(url="https://example.com");
```

### 3. Strict mode selectors

Playwright's strict mode fails when a CSS selector matches multiple elements. Use specific selectors:

```jac
# WRONG -- matches all links
root spawn click(selector="a");

# RIGHT -- match a specific link
root spawn click(selector="a[href='/login']");
root spawn click(selector=".nav a:first-child");

# RIGHT -- use snapshot refs instead
w = root spawn snapshot();
root spawn click(selector="e3");  # Click the third interactive element
```

### 4. Stale database files

If you get "Page object not found" errors, clear stale state:

```bash
rm -rf .jac/data/*.db*
```

This happens because Jac persists session IDs in SQLite databases between runs, but the actual Playwright session is gone.

### 5. Ternary expressions

```jac
# Jac supports Python-style ternary
result = "yes" if condition else "no";
value = len(items) if items else 0;
```

### 6. Try/except

```jac
try {
    root spawn click(selector="#maybe-not-here");
} except Exception as e {
    print("Error:", str(e));
}
```

### 7. No wait_for_timeout walker

There is no `wait_for_timeout` or `sleep` walker. Use JavaScript evaluation instead:

```jac
# Wait for 2 seconds
root spawn evaluate(script="new Promise(r => setTimeout(r, 2000))");

# Wait for 500ms
root spawn evaluate(script="new Promise(r => setTimeout(r, 500))");
```

### 8. Walker naming conventions

Use exact walker names. Common mistakes:

| Wrong | Correct |
|-------|---------|
| `cookie_get` | `cookies_get` |
| `cookie_set` | `cookies_set` |
| `count_elements` | `element_count` |
| `wait_for_selector` | `wait_for` |
| `check` | `check_element` |
| `errors` | `errors_get` |
| `set_viewport` | `viewport` |
| `go_back` | `back` |
| `go_forward` | `forward` |

### 9. Dictionary operations

Standard dict operations work:

```jac
d = {"key": "value"};
print(d["key"]);
d["new_key"] = "new_value";

# Iterate dict
for (k, v) in d.items() {
    print(k, v);
}

# Check key
if "key" in d {
    print("found");
}
```

### 10. List operations

```jac
items: list = [];
items.append("a");
items.append("b");
print(len(items));
print(items[0]);

# Slicing
first_three = items[:3];
```
