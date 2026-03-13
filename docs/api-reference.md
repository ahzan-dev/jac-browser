# REST API Reference

jac-browser can run as a REST API server using `jac serve`. All 145 walkers become HTTP POST endpoints.

## Starting the Server

```bash
jac serve jac_browser/main.jac
```

The server starts on `http://localhost:8000` by default.

## Endpoint Format

Every walker is available at:

```
POST http://localhost:8000/walker/<walker_name>
Content-Type: application/json
```

Walker parameters become JSON body fields. All responses return JSON.

## Quick Start

```bash
# 1. Launch browser
curl -X POST localhost:8000/walker/launch \
  -H 'Content-Type: application/json' \
  -d '{"headless": true}'

# 2. Navigate
curl -X POST localhost:8000/walker/navigate \
  -H 'Content-Type: application/json' \
  -d '{"url": "https://example.com"}'

# 3. Snapshot
curl -X POST localhost:8000/walker/snapshot \
  -H 'Content-Type: application/json' -d '{}'

# 4. Click (by ref from snapshot)
curl -X POST localhost:8000/walker/click \
  -H 'Content-Type: application/json' \
  -d '{"selector": "e1"}'

# 5. Screenshot
curl -X POST localhost:8000/walker/screenshot \
  -H 'Content-Type: application/json' -d '{}'

# 6. Close
curl -X POST localhost:8000/walker/close_browser \
  -H 'Content-Type: application/json' -d '{}'
```

## Response Format

Every endpoint returns a JSON array with one report object:

```json
[
  {
    "success": true,
    "url": "https://example.com/",
    "title": "Example Domain"
  }
]
```

On error:

```json
[
  {
    "success": false,
    "error": "Page object not found"
  }
]
```

## Endpoint Reference

### Browser Lifecycle

```bash
# Launch browser (headless or visible)
curl -X POST localhost:8000/walker/launch \
  -d '{"headless": true}'

# Close browser
curl -X POST localhost:8000/walker/close_browser -d '{}'
```

### Navigation

```bash
# Navigate to URL
curl -X POST localhost:8000/walker/navigate \
  -d '{"url": "https://example.com"}'

# Go back
curl -X POST localhost:8000/walker/back -d '{}'

# Go forward
curl -X POST localhost:8000/walker/forward -d '{}'

# Reload
curl -X POST localhost:8000/walker/reload -d '{}'

# Get current URL
curl -X POST localhost:8000/walker/get_url -d '{}'

# Get page title
curl -X POST localhost:8000/walker/get_title -d '{}'
```

### Page Observation

```bash
# ARIA accessibility snapshot (primary way to "see" the page)
curl -X POST localhost:8000/walker/snapshot -d '{}'

# Screenshot (returns base64)
curl -X POST localhost:8000/walker/screenshot -d '{}'
curl -X POST localhost:8000/walker/screenshot \
  -d '{"full_page": true}'
curl -X POST localhost:8000/walker/screenshot \
  -d '{"path": "/tmp/screenshot.png"}'

# PDF
curl -X POST localhost:8000/walker/pdf \
  -d '{"path": "/tmp/page.pdf"}'

# Get text content
curl -X POST localhost:8000/walker/get_text \
  -d '{"selector": "h1"}'

# Get HTML
curl -X POST localhost:8000/walker/get_html_content -d '{}'

# Count elements
curl -X POST localhost:8000/walker/element_count \
  -d '{"selector": ".item"}'
```

### Interaction

```bash
# Click (by CSS selector or snapshot ref)
curl -X POST localhost:8000/walker/click \
  -d '{"selector": "e3"}'
curl -X POST localhost:8000/walker/click \
  -d '{"selector": "button.submit"}'

# Fill input
curl -X POST localhost:8000/walker/fill \
  -d '{"selector": "#email", "value": "user@example.com"}'

# Type text (character by character)
curl -X POST localhost:8000/walker/type_text \
  -d '{"selector": "#search", "text": "query", "delay": 50}'

# Select dropdown
curl -X POST localhost:8000/walker/select_option \
  -d '{"selector": "#country", "value": "US"}'

# Check/uncheck checkbox
curl -X POST localhost:8000/walker/check_element \
  -d '{"selector": "#agree"}'
curl -X POST localhost:8000/walker/uncheck_element \
  -d '{"selector": "#agree"}'

# Hover
curl -X POST localhost:8000/walker/hover \
  -d '{"selector": ".menu-item"}'

# Double click
curl -X POST localhost:8000/walker/dblclick \
  -d '{"selector": ".editable"}'
```

### JavaScript Execution

```bash
# Evaluate JavaScript
curl -X POST localhost:8000/walker/evaluate \
  -d '{"script": "document.title"}'

# Complex JS
curl -X POST localhost:8000/walker/evaluate \
  -d '{"script": "Array.from(document.querySelectorAll(\".item\")).map(e => e.textContent)"}'
```

### Waiting

```bash
# Wait for element
curl -X POST localhost:8000/walker/wait_for \
  -d '{"selector": ".loaded", "state": "visible", "timeout": 5000}'

# Wait for URL
curl -X POST localhost:8000/walker/wait_for_url \
  -d '{"url": "**/dashboard", "timeout": 10000}'

# Wait for page load state
curl -X POST localhost:8000/walker/wait_for_load_state \
  -d '{"state": "networkidle"}'

# Wait for JS condition
curl -X POST localhost:8000/walker/wait_for_function \
  -d '{"expression": "window.appReady === true"}'
```

### Cookies & Storage

```bash
# Get cookies
curl -X POST localhost:8000/walker/cookies_get -d '{}'

# Set cookies
curl -X POST localhost:8000/walker/cookies_set \
  -d '{"cookies": [{"name": "token", "value": "abc123", "domain": "example.com", "path": "/"}]}'

# Clear cookies
curl -X POST localhost:8000/walker/cookies_clear -d '{}'

# LocalStorage
curl -X POST localhost:8000/walker/storage_set \
  -d '{"key": "theme", "value": "dark"}'
curl -X POST localhost:8000/walker/storage_get \
  -d '{"key": "theme"}'
curl -X POST localhost:8000/walker/storage_clear -d '{}'
```

### State Management

```bash
# Save browser state (cookies + storage)
curl -X POST localhost:8000/walker/state_save \
  -d '{"name": "logged-in"}'

# Load saved state
curl -X POST localhost:8000/walker/state_load \
  -d '{"name": "logged-in"}'

# List saved states
curl -X POST localhost:8000/walker/state_list -d '{}'

# Delete a state
curl -X POST localhost:8000/walker/state_delete \
  -d '{"name": "logged-in"}'
```

### Tabs

```bash
# New tab
curl -X POST localhost:8000/walker/tab_new \
  -d '{"url": "https://google.com"}'

# List tabs
curl -X POST localhost:8000/walker/tab_list -d '{}'

# Switch tab
curl -X POST localhost:8000/walker/tab_switch \
  -d '{"page_id": "abc-123"}'

# Close tab
curl -X POST localhost:8000/walker/tab_close \
  -d '{"page_id": "abc-123"}'
```

### Network Interception

```bash
# Block requests matching pattern
curl -X POST localhost:8000/walker/route \
  -d '{"url_pattern": "**/*.png", "handler_type": "abort"}'

# Remove route
curl -X POST localhost:8000/walker/unroute \
  -d '{"url_pattern": "**/*.png"}'

# Get captured requests
curl -X POST localhost:8000/walker/requests_get -d '{}'
```

### Device Emulation

```bash
# List devices
curl -X POST localhost:8000/walker/device_list -d '{}'

# Emulate device
curl -X POST localhost:8000/walker/device \
  -d '{"name": "iPhone 12"}'

# Set viewport
curl -X POST localhost:8000/walker/viewport \
  -d '{"width": 1920, "height": 1080}'

# Set user agent
curl -X POST localhost:8000/walker/useragent \
  -d '{"ua": "Mozilla/5.0 Custom Agent"}'
```

### Dialogs

```bash
# Accept/dismiss dialogs
curl -X POST localhost:8000/walker/dialog \
  -d '{"action": "accept"}'
curl -X POST localhost:8000/walker/dialog \
  -d '{"action": "dismiss"}'

# Pre-accept next confirm dialog
curl -X POST localhost:8000/walker/confirm -d '{}'

# Pre-deny next confirm dialog
curl -X POST localhost:8000/walker/deny -d '{}'
```

### Console & Errors

```bash
# Get console messages
curl -X POST localhost:8000/walker/console_get -d '{}'

# Get page errors
curl -X POST localhost:8000/walker/errors_get -d '{}'
```

### Visual Diff

```bash
# Compare two snapshots
curl -X POST localhost:8000/walker/diff_snapshot \
  -d '{"snap1": "...", "snap2": "..."}'

# Compare two screenshots
curl -X POST localhost:8000/walker/diff_screenshot \
  -d '{"path1": "/tmp/before.png", "path2": "/tmp/after.png"}'

# Compare two URLs
curl -X POST localhost:8000/walker/diff_url \
  -d '{"url1": "https://example.com", "url2": "https://example.org"}'
```

## Using with Python

You can call the REST API from any language. Python example:

```python
import requests

BASE = "http://localhost:8000/walker"

# Launch
requests.post(f"{BASE}/launch", json={"headless": True})

# Navigate
requests.post(f"{BASE}/navigate", json={"url": "https://example.com"})

# Snapshot
resp = requests.post(f"{BASE}/snapshot", json={})
data = resp.json()[0]
print(data["snapshot"])

# Close
requests.post(f"{BASE}/close_browser", json={})
```

## Using with JavaScript

```javascript
const BASE = "http://localhost:8000/walker";

async function browse() {
  await fetch(`${BASE}/launch`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ headless: true }),
  });

  await fetch(`${BASE}/navigate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ url: "https://example.com" }),
  });

  const resp = await fetch(`${BASE}/snapshot`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: "{}",
  });
  const [data] = await resp.json();
  console.log(data.snapshot);

  await fetch(`${BASE}/close_browser`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: "{}",
  });
}

browse();
```
