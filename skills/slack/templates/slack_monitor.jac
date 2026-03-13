"""Slack Monitor: Check Slack workspace for unreads, channels, and activity.

Opens Slack web app, navigates through channels, and extracts information.
Requires a saved auth state from a previous headed-mode login.

Usage:
    # First time: login in headed mode and save state
    # Then: jac run skills/slack/templates/slack_monitor.jac

Note: This template uses example.com as a demo since Slack requires
      real authentication. Replace with actual Slack workspace URL
      and auth state for real use.
"""

import from os.path {exists}
import json;

import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot, click, fill,
    get_text, get_title, get_url,
    evaluate, state_load,
    wait_for_load_state
}


glob SLACK_URL = "https://app.slack.com";
glob AUTH_STATE = "/tmp/slack-auth.json";


with entry {
    print("=== Slack Monitor ===\n");

    # --- Demo mode: since Slack requires real auth, demonstrate the pattern ---
    # In real usage, you would:
    # 1. Run once with headless=False to login manually
    # 2. Save state: root spawn state_save(path=AUTH_STATE);
    # 3. Then run this script which loads the saved state

    print("--- Demo Mode ---");
    print("This template demonstrates the Slack monitoring pattern.");
    print("For real Slack use:");
    print("  1. Launch with headless=False");
    print("  2. Login to Slack manually");
    print("  3. Save state with state_save()");
    print("  4. Update AUTH_STATE path and re-run\n");

    root spawn launch(headless=True);

    # Demo: Use quotes.toscrape.com to show the pattern
    demo_url = "https://quotes.toscrape.com";
    root spawn navigate(url=demo_url);
    root spawn wait_for_load_state(state="load");

    # --- Step 1: Orient ---
    print("--- Step 1: Orient ---");
    w = root spawn get_url();
    home_url = w.reports[0]["url"];
    w = root spawn get_title();
    home_title = w.reports[0]["title"];
    w = root spawn snapshot();
    home_snap = w.reports[0]["snapshot"];
    home_refs = w.reports[0]["refs"];
    w = root spawn screenshot();
    home_img = w.reports[0]["base64"];
    print("[Home] " + home_title + " (" + str(len(home_refs)) + " elements)");
    print("Snapshot preview:");
    print(home_snap[:300]);

    # --- Step 2: Discover navigation ---
    print("\n--- Step 2: Discover Navigation ---");
    links: list = [];
    for (ref_id, ref_info) in home_refs.items() {
        if ref_info["role"] == "link" {
            links.append({"ref": ref_id, "name": ref_info["name"]});
        }
    }
    print("Found", len(links), "navigable links:");
    for link in links[:10] {
        print("  @" + link["ref"] + " -> " + link["name"]);
    }

    # --- Step 3: Navigate to a section ---
    print("\n--- Step 3: Navigate to Section ---");
    root spawn click(selector="a[href='/login']");
    root spawn wait_for_load_state(state="load");
    w = root spawn get_url();
    login_url = w.reports[0]["url"];
    w = root spawn get_title();
    login_title = w.reports[0]["title"];
    w = root spawn snapshot();
    login_refs = w.reports[0]["refs"];
    w = root spawn screenshot();
    print("[Login Page] " + login_title + " (" + str(len(login_refs)) + " elements)");

    # --- Step 4: Extract data ---
    print("\n--- Step 4: Extract Data ---");
    js_quotes = "Array.from(document.querySelectorAll('.quote .text')).map(el => el.textContent.slice(0, 60))";
    root spawn navigate(url=demo_url);
    root spawn wait_for_load_state(state="load");
    w = root spawn evaluate(script=js_quotes);
    quotes = w.reports[0]["result"];
    if quotes {
        print("Extracted", len(quotes), "items:");
        for q in quotes {
            print("  -", q, "...");
        }
    }

    # --- Step 5: Generate summary ---
    print("\n--- Summary ---");
    print("Pages explored: 2");
    print("Elements found:", len(home_refs));
    print("Links discovered:", len(links));
    print("Data items extracted:", len(quotes) if quotes else 0);

    root spawn close_browser();
    print("\nSlack monitor demo complete.");
    print("Replace demo_url with Slack URL and add auth for real use.");
}
