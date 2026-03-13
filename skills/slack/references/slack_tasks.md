# Common Slack Tasks

## Check All Unread Messages

1. Take snapshot to see sidebar
2. Look for "Activity" tab ref (often `e14`)
3. Click Activity tab to see all unreads
4. Or find "More unreads" button in sidebar
5. Screenshot the results

## Navigate to a Channel

1. Snapshot sidebar to find channel refs
2. Click channel ref
3. Re-snapshot after navigation
4. If channel not visible, scroll sidebar: `scroll(direction="down", amount=300, selector=".p-sidebar")`

## Search for Messages

1. Click search button (often `e5`)
2. Fill search input with query
3. Use filters: `in:channel`, `from:@user`, `before:date`, `after:date`, `has:file`
4. Example: `"deploy failed" in:engineering after:2026-03-01`

## Extract Channel List

Use JavaScript to extract channel names:
```jac
js = "Array.from(document.querySelectorAll('[data-qa=\"channel_sidebar_name_button\"]')).map(el => el.textContent)";
w = root spawn evaluate(script=js);
channels = w.reports[0]["result"];
```

## Monitor Channel Activity

1. Navigate to target channel
2. Take snapshot to read recent messages
3. Scroll down for older messages
4. Check threads by clicking thread indicators

## Find Pinned Messages

1. Navigate to channel
2. Look for "Pins" tab in channel header
3. Click Pins tab
4. Snapshot to read pinned content

## Count Unreads

Parse the accessibility tree snapshot for treeitem elements in the unreads section:
```jac
w = root spawn snapshot();
snap = w.reports[0]["snapshot"];
# Count lines containing channel names with unread indicators
```

## Slack Sidebar Structure

Typical elements in the accessibility tree:
- **Tabs**: Home, DMs, Activity, More
- **Sections**: Starred, Channels, Direct Messages, Apps
- **Channel items**: treeitems at level 2 under sections
- **More unreads**: Button that expands collapsed unread channels

## Search Filter Reference

| Filter | Example | Description |
|--------|---------|-------------|
| `in:` | `in:engineering` | Search in specific channel |
| `from:` | `from:@alice` | Messages from user |
| `before:` | `before:2026-03-13` | Before date |
| `after:` | `after:2026-03-01` | After date |
| `has:file` | `has:file` | Messages with files |
| `has:emoji` | `has:emoji` | Messages with reactions |
| `has:link` | `has:link` | Messages with links |
| `has:pin` | `has:pin` | Pinned messages |
