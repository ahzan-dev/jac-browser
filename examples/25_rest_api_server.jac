"""Example 25: REST API Server - Use jac-browser as a web service.

This file is meant to be served with `jac serve`. It exposes all 145 walkers
as REST API endpoints that any HTTP client can call.

Usage:
    # Start the server
    jac serve examples/25_rest_api_server.jac

    # Then from another terminal:
    # Launch browser
    curl -X POST localhost:8000/walker/launch \
      -H 'Content-Type: application/json' \
      -d '{"headless": true}'

    # Navigate
    curl -X POST localhost:8000/walker/navigate \
      -H 'Content-Type: application/json' \
      -d '{"url": "https://example.com"}'

    # Take snapshot
    curl -X POST localhost:8000/walker/snapshot \
      -H 'Content-Type: application/json' -d '{}'

    # Click element by ref
    curl -X POST localhost:8000/walker/click \
      -H 'Content-Type: application/json' \
      -d '{"selector": "e1"}'

    # Fill an input
    curl -X POST localhost:8000/walker/fill \
      -H 'Content-Type: application/json' \
      -d '{"selector": "e3", "value": "hello"}'

    # Take screenshot
    curl -X POST localhost:8000/walker/screenshot \
      -H 'Content-Type: application/json' \
      -d '{"full_page": true}'

    # Get page title
    curl -X POST localhost:8000/walker/get_title \
      -H 'Content-Type: application/json' -d '{}'

    # Save state
    curl -X POST localhost:8000/walker/state_save \
      -H 'Content-Type: application/json' \
      -d '{"path": "/tmp/my_state.json"}'

    # Close browser
    curl -X POST localhost:8000/walker/close_browser \
      -H 'Content-Type: application/json' -d '{}'
"""

# Import everything from the main module - this makes all 145 walkers
# available as REST endpoints via jac serve
import from jac_browser.main {}


with entry {
    print("jac-browser REST API server ready.");
    print("All 145 walkers available at POST /walker/<walker_name>");
    print("Start with: curl -X POST localhost:8000/walker/launch -H 'Content-Type: application/json' -d '{\"headless\": true}'");
}
