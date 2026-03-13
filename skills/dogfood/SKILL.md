# Dogfood Skill for jac-browser

Systematically explore and test web applications to find bugs, UX issues, and problems. Produces a structured report with screenshots as evidence.

## Overview

The dogfood workflow:
1. **Initialize** - Launch browser, create output directories
2. **Authenticate** - Sign in if needed, save state
3. **Orient** - Take initial screenshot, understand app structure
4. **Explore** - Systematically visit pages, test features
5. **Document** - Screenshot each issue as found
6. **Wrap up** - Generate summary report, close browser

## Quick Start

```bash
jac run skills/dogfood/templates/dogfood.jac
```

Or import the dogfood walker in your own application:

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot, click, fill,
    evaluate, get_title, get_url,
    errors, console_get
}
```

## Workflow Details

### Step 1: Initialize

```jac
import from os {makedirs}

makedirs("/tmp/dogfood/screenshots", exist_ok=True);
root spawn launch(headless=True);
root spawn navigate(url="https://target-app.com");
```

### Step 2: Authenticate (if needed)

```jac
root spawn snapshot();
root spawn fill(selector="#email", value="test@example.com");
root spawn fill(selector="#password", value="password");
root spawn click(selector="button[type='submit']");
root spawn wait_for_load_state(state="networkidle");
root spawn state_save(path="/tmp/dogfood/auth-state.json");
```

### Step 3: Orient

```jac
w = root spawn screenshot();
# Save screenshot to file
w = root spawn snapshot();
snap = w.reports[0]["snapshot"];
print("Page structure:", snap[:500]);
```

### Step 4: Explore

At each page:
```jac
# Take snapshot to understand structure
w = root spawn snapshot();
print(w.reports[0]["snapshot"]);

# Take screenshot for evidence
w = root spawn screenshot();

# Check console for errors
w = root spawn errors();
errs = w.reports[0];

# Check JS console
w = root spawn console_get();
```

### Step 5: Document Issues

For each issue found:
```jac
# Take screenshot showing the problem
w = root spawn screenshot();
base64_img = w.reports[0]["base64"];

# Get current URL for the report
w = root spawn get_url();
issue_url = w.reports[0]["url"];

# Get page title
w = root spawn get_title();
title = w.reports[0]["title"];
```

### Step 6: Wrap Up

```jac
root spawn close_browser();
print("Dogfood testing complete. Report saved.");
```

## Issue Severity Levels

| Severity | Description |
|----------|-------------|
| Critical | Blocks core workflow, causes data loss, crashes app |
| High | Major feature broken/unusable, no workaround |
| Medium | Feature works but with noticeable problems |
| Low | Minor cosmetic/polish issue |

## Issue Categories

- **Visual/UI** - Layout, alignment, clipped text, missing icons
- **Functional** - Broken links, buttons doing nothing, bad validation
- **UX** - Confusing navigation, missing loading indicators
- **Content** - Typos, outdated text, placeholder text left in
- **Performance** - Slow loads (>3s), janky animations
- **Console** - JS exceptions, failed network requests (4xx, 5xx)
- **Accessibility** - Missing alt text, unlabeled inputs, poor keyboard nav

## Exploration Checklist

1. Visual scan - Look for layout/alignment/rendering issues
2. Interactive elements - Click every button, link, control
3. Forms - Fill and submit, test empty/invalid input
4. Navigation - Follow all paths, check back button, deep links
5. States - Check empty states, loading states, error states
6. Console - Check for JS errors, failed requests
7. Responsiveness - Different viewport sizes if relevant

## References

- [issue_taxonomy.md](references/issue_taxonomy.md) - Full issue categorization
- [dogfood.jac](templates/dogfood.jac) - Working dogfood application

## Best Practices

- Verify reproducibility before documenting
- Screenshot each step so reader can follow visually
- Find 5-10 well-documented issues (depth over count)
- Check console errors periodically
- Test like a user, not a robot
