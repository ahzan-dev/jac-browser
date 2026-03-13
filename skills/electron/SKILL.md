# Electron Skill for jac-browser

Automate Electron desktop apps (VS Code, Slack, Discord, etc.) using jac-browser.

## Limitation

The current jac_browser walkers use Playwright's `launch()` which starts a new browser. To connect to an existing Electron app via CDP, you would need a `connect` walker (not yet implemented).

**Workaround**: Launch the Electron app with `--remote-debugging-port` and use the CLI agent-browser tool for CDP connection, or extend jac_browser with a connect walker.

## Concept

Electron apps are built on Chromium and support Chrome DevTools Protocol (CDP). By launching them with remote debugging enabled, you can automate them like a web page.

### Launch Electron Apps with CDP

**Linux**:
```bash
slack --remote-debugging-port=9222
code --remote-debugging-port=9223
discord --remote-debugging-port=9224
```

**macOS**:
```bash
open -a "Slack" --args --remote-debugging-port=9222
open -a "Visual Studio Code" --args --remote-debugging-port=9223
```

### Future: Connect Walker

When implemented, the workflow would be:

```jac
import from jac_browser.walkers {
    connect, snapshot, click, screenshot, close_browser
}

with entry {
    # Connect to running Electron app
    root spawn connect(cdp_port=9222);

    # Standard workflow from here
    w = root spawn snapshot();
    print(w.reports[0]["snapshot"]);

    root spawn click(ref="e5");
    root spawn screenshot();

    root spawn close_browser();
}
```

## Supported Apps

- **Communication**: Slack, Discord, Teams, Signal, Telegram Desktop
- **Development**: VS Code, GitHub Desktop, Postman, Insomnia
- **Design**: Figma, Notion, Obsidian
- **Media**: Spotify, Tidal
- **Productivity**: Todoist, Linear, 1Password

## Current Alternative

Use jac_browser for web versions of these apps:

```jac
import from jac_browser.walkers {
    launch, navigate, snapshot, click, close_browser
}

with entry {
    root spawn launch(headless=False);
    root spawn navigate(url="https://app.slack.com");

    w = root spawn snapshot();
    print(w.reports[0]["snapshot"]);

    root spawn click(ref="e5");
    root spawn close_browser();
}
```
