# Slack Skill for jac-browser

Interact with Slack workspaces via browser automation. Check messages, extract data, navigate channels, and automate tasks - no Slack API tokens needed.

## Quick Start

```jac
import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot, click, fill,
    get_text, evaluate
}

with entry {
    root spawn launch(headless=False);  # Headed mode for Slack login
    root spawn navigate(url="https://app.slack.com");

    # Take snapshot to see available elements
    w = root spawn snapshot();
    print(w.reports[0]["snapshot"]);

    # Navigate using refs from snapshot
    root spawn click(ref="e14");  # Activity tab (ref varies)

    root spawn screenshot();
    root spawn close_browser();
}
```

## Core Workflow

1. **Launch/Navigate** to Slack web app
2. **Snapshot** to discover interactive elements (channels, tabs, buttons)
3. **Navigate** by clicking tabs, channels, sections
4. **Extract** data via `get_text`, `snapshot`, `evaluate`
5. **Screenshot** to capture evidence

## Authentication

Slack requires login. Use headed mode for first-time auth, then save state:

```jac
# First time - login manually in headed mode
root spawn launch(headless=False);
root spawn navigate(url="https://app.slack.com");
# ... manual login happens in visible browser ...
# After logged in:
root spawn state_save(path="/tmp/slack-auth.json");
root spawn close_browser();

# Subsequent runs - load saved state
root spawn launch(headless=True);
root spawn state_load(path="/tmp/slack-auth.json");
root spawn navigate(url="https://app.slack.com");
```

## Common Tasks

### Check Unread Messages

```jac
w = root spawn snapshot();
snap = w.reports[0]["snapshot"];
# Look for channels with unread indicators in the snapshot
# Navigate to Activity tab for all unreads
root spawn click(ref="e14");  # Activity tab (ref varies by session)
w = root spawn screenshot();
```

### Navigate to a Channel

```jac
w = root spawn snapshot();
# Find channel ref in snapshot output
root spawn click(ref="e42");  # Channel ref from snapshot
w = root spawn snapshot();    # Re-snapshot after navigation
```

### Search Messages

```jac
root spawn click(ref="e5");  # Search button (ref varies)
root spawn fill(selector="input[type='text']", value="bug report in:engineering");
root spawn click(selector="button[type='submit']");  # Or press Enter
w = root spawn snapshot();
```

### Extract Channel Data

```jac
js = "Array.from(document.querySelectorAll('[data-qa=\"channel_sidebar_name_button\"]')).map(el => el.textContent)";
w = root spawn evaluate(script=js);
channels = w.reports[0]["result"];
for ch in channels {
    print("Channel:", ch);
}
```

### Check Console for Errors

```jac
w = root spawn errors();
print("Page errors:", w.reports[0]);

w = root spawn console_get();
print("Console messages:", w.reports[0]);
```

## Slack Search Filters

Use these in the search box:
- `in:channel-name` - Search in specific channel
- `from:@user` - Messages from specific user
- `before:2026-03-13` - Messages before date
- `after:2026-03-01` - Messages after date
- `has:file` - Messages with files
- `has:emoji` - Messages with reactions

Example: `"deploy failed" in:engineering from:@alice after:2026-03-01`

## Sidebar Structure

Typical Slack sidebar elements:
- Home / DMs / Activity / More tabs
- Section headers (Channels, Direct Messages, Apps)
- Channel items (treeitems in accessibility tree)
- "More unreads" button

## Best Practices

- Use **headed mode** (`headless=False`) for first-time login
- **Save state** after login for reuse in subsequent runs
- Always **snapshot before clicking** to identify correct refs
- **Re-snapshot after navigation** (channel switch, tab click)
- Add small pauses between rapid interactions
- If element not in snapshot, try scrolling the sidebar

## Limitations

- No Slack API access - browser automation only
- Session-specific screenshots and snapshots
- Slack may rate-limit rapid interactions
- Only interact with your own workspace
- Some features require headed mode for proper rendering

## References

- [slack_tasks.md](references/slack_tasks.md) - Common Slack task patterns
- [slack_monitor.jac](templates/slack_monitor.jac) - Slack monitoring application
