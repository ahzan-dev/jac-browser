"""Example 13: Working with Iframes - Execute code inside frames.

Demonstrates interacting with iframe content using the frame and
mainframe walkers.

Usage:
    jac run examples/13_iframe_frames.jac
"""

import from jac_browser.walkers {
    launch, navigate, close_browser,
    set_content,
    frame, mainframe,
    evaluate, get_title
}


with entry {
    root spawn launch(headless=True);

    # Create a page with iframes
    page_html = "<h1>Main Page</h1><p id='main-content'>This is the main page content.</p><iframe id='frame1' name='frame1' srcdoc='<html><body><h2 id=frame-heading>Frame 1 Content</h2><p id=frame-text>Hello from iframe 1</p><input id=frame-input value=frame-value /></body></html>'></iframe><iframe id='frame2' name='frame2' srcdoc='<html><body><h2>Frame 2 Content</h2><p id=frame2-text>Hello from iframe 2</p></body></html>'></iframe>";
    root spawn set_content(html=page_html);

    # --- Read main page content ---
    print("--- Main Page ---");
    w = root spawn evaluate(script="document.getElementById('main-content').textContent");
    print("Main content:", w.reports[0]["result"]);

    # --- Execute JavaScript inside frame 1 ---
    print("\n--- Frame 1 ---");

    w = root spawn frame(selector="#frame1", script="document.getElementById('frame-heading').textContent");
    print("Frame 1 heading:", w.reports[0]["result"]);

    w = root spawn frame(selector="#frame1", script="document.getElementById('frame-text').textContent");
    print("Frame 1 text:", w.reports[0]["result"]);

    # Read input value inside frame
    w = root spawn frame(selector="#frame1", script="document.getElementById('frame-input').value");
    print("Frame 1 input value:", w.reports[0]["result"]);

    # Modify content inside frame
    w = root spawn frame(selector="#frame1", script="document.getElementById('frame-text').textContent = 'Modified!'; 'done'");
    print("Modified frame 1:", w.reports[0]["result"]);

    # Verify modification
    w = root spawn frame(selector="#frame1", script="document.getElementById('frame-text').textContent");
    print("Frame 1 after modification:", w.reports[0]["result"]);

    # --- Execute JavaScript inside frame 2 ---
    print("\n--- Frame 2 ---");

    w = root spawn frame(selector="#frame2", script="document.getElementById('frame2-text').textContent");
    print("Frame 2 text:", w.reports[0]["result"]);

    # --- Switch back to main frame ---
    print("\n--- Mainframe ---");
    w = root spawn mainframe();
    print("Switched to mainframe:", w.reports[0]["success"]);
    print("Main frame URL:", w.reports[0]["url"]);

    # Verify we're on the main frame
    w = root spawn evaluate(script="document.querySelector('h1').textContent");
    print("Main page h1:", w.reports[0]["result"]);

    root spawn close_browser();
    print("\nDone.");
}
