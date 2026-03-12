"""Example 20: AI Agent Loop - The snapshot-ref cycle for AI-driven browsing.

This is the primary pattern for AI agents using jac-browser. The agent:
1. Takes a snapshot to "see" the page (ARIA accessibility tree)
2. Reads the ref_map to understand interactive elements
3. Decides which element to interact with
4. Takes another snapshot to see the result
5. Repeats until the task is complete

Usage:
    jac run examples/20_ai_agent_loop.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, click, fill, get_text,
    screenshot
}


"""Simulate an AI agent navigating and interacting with a search site."""
with entry {
    root spawn launch(headless=True);
    root spawn navigate(url="https://quotes.toscrape.com/");

    # === Step 1: See the page ===
    print("=== Step 1: Take snapshot ===");
    w = root spawn snapshot();
    snap = w.reports[0];

    # The snapshot tree is what an AI "sees"
    print("Page structure (first 300 chars):");
    print(str(snap["snapshot"])[:300] + "...");

    # The refs map maps ref IDs to element info
    print("\nInteractive elements (refs):");
    ref_map = snap["refs"];
    for ref_id in ref_map {
        el = ref_map[ref_id];
        print("  " + str(ref_id) + ": " + str(el["role"]) + " \"" + str(el["name"]) + "\"");
    }

    # === Step 2: AI decides to click a link ===
    # Find a link to click (the AI would use LLM reasoning here)
    target_ref = "";
    for ref_id in ref_map {
        el = ref_map[ref_id];
        if el["role"] == "link" and "Login" in str(el["name"]) {
            target_ref = str(ref_id);
        }
    }

    if target_ref {
        print("\n=== Step 2: Click ref '" + target_ref + "' (Login link) ===");
        root spawn click(selector=target_ref);
    } else {
        # Fallback: click first link
        for ref_id in ref_map {
            el = ref_map[ref_id];
            if el["role"] == "link" {
                target_ref = str(ref_id);
                break;
            }
        }
        if target_ref {
            print("\n=== Step 2: Click ref '" + target_ref + "' ===");
            root spawn click(selector=target_ref);
        }
    }

    # === Step 3: See updated page ===
    print("\n=== Step 3: Re-snapshot after action ===");
    w = root spawn snapshot();
    snap2 = w.reports[0];
    print("New page structure (first 300 chars):");
    print(str(snap2["snapshot"])[:300] + "...");

    # Check for form fields on the new page
    ref_map2 = snap2["refs"];
    textboxes = [];
    for ref_id in ref_map2 {
        el = ref_map2[ref_id];
        if el["role"] == "textbox" {
            textboxes.append({"ref": ref_id, "name": el["name"]});
        }
    }

    if textboxes {
        print("\nFound text inputs:");
        for tb in textboxes {
            print("  " + str(tb["ref"]) + ": " + str(tb["name"]));
        }

        # === Step 4: Fill form fields using refs ===
        print("\n=== Step 4: Fill form fields ===");
        for tb in textboxes {
            if "username" in str(tb["name"]).lower() or "user" in str(tb["name"]).lower() {
                root spawn fill(selector=str(tb["ref"]), value="testuser");
                print("Filled " + str(tb["ref"]) + " with username");
            }
            if "password" in str(tb["name"]).lower() or "pass" in str(tb["name"]).lower() {
                root spawn fill(selector=str(tb["ref"]), value="testpass");
                print("Filled " + str(tb["ref"]) + " with password");
            }
        }

        # === Step 5: Re-snapshot to verify ===
        print("\n=== Step 5: Verify filled form ===");
        w = root spawn snapshot();
        print(str(w.reports[0]["snapshot"])[:400] + "...");
    }

    # Take a screenshot for visual verification
    w = root spawn screenshot();
    print("\nScreenshot taken:", w.reports[0]["success"]);

    root spawn close_browser();
    print("\nAgent loop complete.");
}
