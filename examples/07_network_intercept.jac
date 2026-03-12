"""Example 07: Network Interception - Block, mock, and log network requests.

Demonstrates intercepting network requests to block resources, mock API
responses, and log all network traffic.

Usage:
    jac run examples/07_network_intercept.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    route, unroute,
    requests_get,
    wait_for_load_state,
    evaluate
}


with entry {
    root spawn launch(headless=True);

    # --- Block images to speed up page loads ---
    print("--- Blocking images ---");
    root spawn route(url="**/*.png", abort=True);
    root spawn route(url="**/*.jpg", abort=True);
    root spawn route(url="**/*.gif", abort=True);
    root spawn route(url="**/*.svg", abort=True);

    root spawn navigate(url="https://quotes.toscrape.com/");
    root spawn wait_for_load_state(state="load");

    # Check captured requests
    w = root spawn requests_get();
    print("Total requests logged:", len(w.reports[0]["requests"]));
    for req in w.reports[0]["requests"][:5] {
        print("  " + str(req["method"]) + " " + str(req["url"])[:80]);
    }

    # Remove image blocks
    root spawn unroute(url="**/*.png");
    root spawn unroute(url="**/*.jpg");
    root spawn unroute(url="**/*.gif");
    root spawn unroute(url="**/*.svg");
    print("Image blocks removed.");

    # --- Mock an API response ---
    print("\n--- Mocking API response ---");
    root spawn route(
        url="**/api/data",
        response_status=200,
        response_body='{"items": [{"id": 1, "name": "Mocked Item"}], "total": 1}',
        response_content_type="application/json"
    );

    # Navigate to a page that would call the API (simulated with JS)
    js = "fetch('/api/data').then(function(r) { return r.json(); }).then(function(d) { return JSON.stringify(d); }).catch(function(e) { return 'error: ' + e.message; })";
    w = root spawn evaluate(script=js);
    print("Mocked API response:", w.reports[0]["result"]);

    # --- Filter requests by URL pattern ---
    print("\n--- Filtered requests ---");
    w = root spawn requests_get(filter="toscrape");
    print("Requests matching 'toscrape':", len(w.reports[0]["requests"]));

    # Clear request log
    w = root spawn requests_get(do_clear=True);
    print("Request log cleared:", w.reports[0]["success"]);

    root spawn close_browser();
    print("\nDone.");
}
