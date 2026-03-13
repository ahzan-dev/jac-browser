# Getting Started with jac-browser

## What is jac-browser?

jac-browser is a pure-Jac library that gives your Jac applications full browser control through 145 walkers wrapping Playwright. Every browser action -- navigate, click, fill, screenshot, scrape -- is a walker that reports results as JSON.

## Prerequisites

- Python 3.11 or higher
- jaclang 0.6.1 or higher

## Installation

```bash
pip install jac-browser
playwright install chromium
```

If you're using a Jac virtual environment:

```bash
source ~/.jacvenv/bin/activate
pip install jac-browser
playwright install chromium
```

## Your First Program

Create a file called `hello.jac`:

```jac
import from jac_browser.walkers {launch, navigate, snapshot, close_browser}

with entry {
    # Launch a headless browser
    root spawn launch(headless=True);

    # Go to a website
    root spawn navigate(url="https://example.com");

    # Take a snapshot to "see" the page
    w = root spawn snapshot();
    print(w.reports[0]["snapshot"]);

    # Clean up
    root spawn close_browser();
}
```

Run it:

```bash
jac run hello.jac
```

You'll see the accessibility tree of example.com printed to your terminal -- that's how jac-browser "sees" web pages.

## Understanding the Output

The `snapshot` walker returns an ARIA accessibility tree with element refs:

```
- heading "Example Domain" [level=1]
- paragraph:
  - text: "This domain is for use in illustrative examples..."
- paragraph:
  - link [e1] "More information...":
    - /url: https://www.iana.org/domains/example
```

The `[e1]` is a **ref** -- a short ID you can use to interact with that element:

```jac
root spawn click(selector="e1");  # Clicks "More information..." link
```

## The Core Pattern

Every jac-browser program follows the same cycle:

```
launch -> navigate -> snapshot -> interact -> re-snapshot -> close
```

1. **Launch** the browser (headless or visible)
2. **Navigate** to a URL
3. **Snapshot** to see the page structure and get element refs
4. **Interact** using refs or CSS selectors (click, fill, etc.)
5. **Re-snapshot** to see what changed
6. **Close** the browser when done

## Walker Results

Every walker reports a dict. Access results like this:

```jac
w = root spawn some_walker(params...);
result = w.reports[0];
```

Common result keys:

| Key | Description |
|-----|-------------|
| `success` | `True` if the action succeeded |
| `error` | Error message if `success` is `False` |
| `snapshot` | ARIA accessibility tree text |
| `refs` | Dict mapping ref IDs to element info |
| `base64` | Base64-encoded screenshot data |
| `url` | Current page URL |
| `title` | Current page title |
| `text` | Extracted text content |
| `html` | Extracted HTML content |
| `result` | JavaScript evaluation result |
| `cookies` | List of cookie objects |

## Next Steps

- [Tutorials](tutorials.md) -- Step-by-step guides for common tasks
- [Jac Syntax Guide](jac-syntax-guide.md) -- Jac language tips for browser automation
- [API Reference](api-reference.md) -- Using jac-browser as a REST API
- [Troubleshooting](troubleshooting.md) -- Common errors and fixes
- [Examples](../examples/README.md) -- 30 working example programs
