"""Dogfood: Systematically explore and test a web app to find issues.

Explores a target website, checks for visual bugs, functional problems,
console errors_get, and generates a structured report with screenshots.

Usage:
    jac run skills/dogfood/templates/dogfood.jac

Customize TARGET_URL below before running.
"""

import from os {makedirs}
import from os.path {exists}
import json;

import from jac_browser.walkers {
    launch, navigate, close_browser,
    snapshot, screenshot, click,
    get_text, get_title, get_url,
    evaluate, errors_get, console_get,
    viewport, wait_for_load_state
}


glob TARGET_URL: str = "https://quotes.toscrape.com";
glob OUTPUT_DIR: str = "/tmp/dogfood";
glob issues: list = [];
glob issue_counter: int = 0;


with entry {
    # --- Step 1: Initialize ---
    print("=== Dogfood Testing ===");
    print("Target:", TARGET_URL);

    if not exists(OUTPUT_DIR) {
        makedirs(OUTPUT_DIR, exist_ok=True);
    }

    root spawn launch(headless=True);

    # --- Step 2: Navigate to target ---
    root spawn navigate(url=TARGET_URL);
    root spawn wait_for_load_state(state="load");

    # --- Step 3: Orient - understand app structure ---
    print("\n--- Exploring: Home ---");
    w = root spawn get_url();
    home_url = w.reports[0]["url"];
    print("URL:", home_url);

    w = root spawn get_title();
    print("Title:", w.reports[0]["title"]);

    w = root spawn snapshot();
    home_snap = w.reports[0]["snapshot"];
    home_refs = w.reports[0]["refs"];
    print("Elements:", len(home_refs));

    w = root spawn screenshot();
    print("Screenshot:", len(w.reports[0]["base64"]), "chars");

    # Check console errors_get on home page
    w = root spawn errors_get();
    home_errors = w.reports[0];
    if home_errors.get("errors") and len(home_errors["errors"]) > 0 {
        for e in home_errors["errors"] {
            issue_counter += 1;
            issue_id = "ISSUE-" + str(issue_counter).zfill(3);
            issues.append({"id": issue_id, "severity": "medium", "category": "console", "title": "JS error on Home", "description": str(e)[:200], "url": home_url});
            print("  [" + issue_id + "] MEDIUM - JS error on Home");
        }
    }

    # --- Step 4: Discover navigation links ---
    print("\n--- Checking navigation links ---");
    nav_links: list = [];
    for (ref_id, ref_info) in home_refs.items() {
        if ref_info["role"] == "link" {
            nav_links.append({"ref": ref_id, "name": ref_info["name"]});
        }
    }
    print("Found", len(nav_links), "links");
    for link in nav_links[:5] {
        print("  ", link["ref"], "->", link["name"]);
    }

    # --- Step 5: Visit Login page ---
    root spawn navigate(url=TARGET_URL + "/login");
    root spawn wait_for_load_state(state="load");
    print("\n--- Exploring: Login ---");

    w = root spawn get_url();
    login_url = w.reports[0]["url"];
    print("URL:", login_url);

    w = root spawn snapshot();
    login_refs = w.reports[0]["refs"];
    print("Elements:", len(login_refs));

    w = root spawn screenshot();
    print("Screenshot:", len(w.reports[0]["base64"]), "chars");

    # Check if login form has inputs
    has_form = False;
    for (ref_id, ref_info) in login_refs.items() {
        if ref_info["role"] == "textbox" {
            has_form = True;
        }
    }
    if not has_form {
        issue_counter += 1;
        issue_id = "ISSUE-" + str(issue_counter).zfill(3);
        issues.append({"id": issue_id, "severity": "high", "category": "functional", "title": "Login form missing inputs", "description": "No textbox elements on login page.", "url": login_url});
        print("  [" + issue_id + "] HIGH - Login form missing inputs");
    }

    # Check console errors_get
    w = root spawn errors_get();
    login_errs = w.reports[0];
    if login_errs.get("errors") and len(login_errs["errors"]) > 0 {
        for e in login_errs["errors"] {
            issue_counter += 1;
            issue_id = "ISSUE-" + str(issue_counter).zfill(3);
            issues.append({"id": issue_id, "severity": "medium", "category": "console", "title": "JS error on Login", "description": str(e)[:200], "url": login_url});
            print("  [" + issue_id + "] MEDIUM - JS error on Login");
        }
    }

    # --- Step 6: Visit Page 2 ---
    root spawn navigate(url=TARGET_URL + "/page/2/");
    root spawn wait_for_load_state(state="load");
    print("\n--- Exploring: Page 2 ---");

    w = root spawn get_url();
    p2_url = w.reports[0]["url"];
    print("URL:", p2_url);

    w = root spawn snapshot();
    print("Elements:", len(w.reports[0]["refs"]));

    w = root spawn screenshot();
    print("Screenshot:", len(w.reports[0]["base64"]), "chars");

    # Check pagination
    w = root spawn evaluate(script="document.querySelectorAll('.pager a').length");
    pager_count = w.reports[0]["result"];
    if pager_count == 0 {
        issue_counter += 1;
        issue_id = "ISSUE-" + str(issue_counter).zfill(3);
        issues.append({"id": issue_id, "severity": "medium", "category": "ux", "title": "Missing pagination", "description": "No pagination controls on list page.", "url": p2_url});
        print("  [" + issue_id + "] MEDIUM - Missing pagination");
    }

    # --- Step 7: Visit Author page ---
    root spawn navigate(url=TARGET_URL + "/author/Albert-Einstein");
    root spawn wait_for_load_state(state="load");
    print("\n--- Exploring: Author Page ---");

    w = root spawn get_url();
    author_url = w.reports[0]["url"];
    print("URL:", author_url);

    w = root spawn snapshot();
    print("Elements:", len(w.reports[0]["refs"]));

    w = root spawn screenshot();
    print("Screenshot:", len(w.reports[0]["base64"]), "chars");

    # Check author page has required content
    w = root spawn evaluate(script="!!document.querySelector('.author-title')");
    has_title = w.reports[0]["result"];
    w = root spawn evaluate(script="!!document.querySelector('.author-description')");
    has_desc = w.reports[0]["result"];
    if not has_title or not has_desc {
        issue_counter += 1;
        issue_id = "ISSUE-" + str(issue_counter).zfill(3);
        issues.append({"id": issue_id, "severity": "medium", "category": "content", "title": "Author page missing sections", "description": "Author page needs title and description.", "url": author_url});
        print("  [" + issue_id + "] MEDIUM - Author page missing sections");
    }

    # --- Step 8: Check 404 error handling ---
    root spawn navigate(url=TARGET_URL + "/nonexistent-page-404");
    root spawn wait_for_load_state(state="load");
    print("\n--- Exploring: 404 Page ---");

    w = root spawn get_url();
    err_url = w.reports[0]["url"];
    print("URL:", err_url);

    w = root spawn snapshot();
    print("Elements:", len(w.reports[0]["refs"]));

    # --- Step 9: Responsive check ---
    print("\n--- Responsive check (mobile 375px) ---");
    root spawn navigate(url=TARGET_URL);
    root spawn viewport(width=375, height=667);
    root spawn wait_for_load_state(state="load");

    w = root spawn snapshot();
    print("Mobile elements:", len(w.reports[0]["refs"]));

    w = root spawn screenshot();
    print("Mobile screenshot:", len(w.reports[0]["base64"]), "chars");

    # Check overflow
    js_overflow = "document.querySelector('.container') ? document.querySelector('.container').scrollWidth > 375 : false";
    w = root spawn evaluate(script=js_overflow);
    if w.reports[0]["result"] {
        issue_counter += 1;
        issue_id = "ISSUE-" + str(issue_counter).zfill(3);
        issues.append({"id": issue_id, "severity": "medium", "category": "visual", "title": "Content overflow on mobile", "description": "Container exceeds 375px viewport.", "url": TARGET_URL});
        print("  [" + issue_id + "] MEDIUM - Content overflow on mobile");
    }

    # Reset viewport
    root spawn viewport(width=1280, height=720);

    # --- Step 10: Generate report ---
    report_path = OUTPUT_DIR + "/report.json";

    critical = 0;
    high = 0;
    medium = 0;
    low = 0;
    for issue in issues {
        sev = issue["severity"];
        if sev == "critical" { critical += 1; }
        if sev == "high" { high += 1; }
        if sev == "medium" { medium += 1; }
        if sev == "low" { low += 1; }
    }

    # Build report as JSON string
    report_str = json.dumps({"target": TARGET_URL, "total": len(issues), "critical": critical, "high": high, "medium": medium, "low": low, "issues": issues}, indent=2);

    f = open(report_path, "w");
    f.write(report_str);
    f.close();

    print("\n=== Dogfood Report ===");
    print("Target:", TARGET_URL);
    print("Total issues:", len(issues));
    print("  Critical:", critical);
    print("  High:", high);
    print("  Medium:", medium);
    print("  Low:", low);
    print("Report saved to:", report_path);

    # --- Cleanup ---
    root spawn close_browser();
    print("\nDogfood testing complete.");
}
