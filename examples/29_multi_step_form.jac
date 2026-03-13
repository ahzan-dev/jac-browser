"""Example 29: Multi-Step Form Wizard - Complex form with validation.

Demonstrates a multi-step form workflow using set_content to create a
realistic form wizard, then filling and validating each step.

Usage:
    jac run examples/29_multi_step_form.jac
"""

import from jac_browser.walkers {
    launch, close_browser,
    set_content, click, fill, select_option,
    check_element, evaluate, get_text, snapshot,
    wait_for, is_visible
}


with entry {
    root spawn launch(headless=True);

    # Create a multi-step form wizard
    html = "<html><head><style>body{font-family:sans-serif;max-width:600px;margin:40px auto;} .step{display:none;} .step.active{display:block;} .btn{padding:8px 16px;margin:4px;cursor:pointer;} .error{color:red;font-size:12px;} input,select,textarea{display:block;margin:8px 0;padding:6px;width:200px;} h2{color:#333;}</style></head><body><div id='wizard'><div class='step active' id='step1'><h2>Step 1: Personal Info</h2><label>Name: <input id='name' type='text'></label><label>Email: <input id='email' type='email'></label><label>Age: <select id='age'><option value=''>Select...</option><option value='18-25'>18-25</option><option value='26-35'>26-35</option><option value='36-50'>36-50</option><option value='50+'>50+</option></select></label><span class='error' id='e1'></span><button class='btn' onclick='goStep(2)'>Next</button></div><div class='step' id='step2'><h2>Step 2: Preferences</h2><label><input type='checkbox' id='newsletter'> Subscribe to newsletter</label><label><input type='checkbox' id='terms'> I agree to terms</label><label>Comments:<textarea id='comments'></textarea></label><span class='error' id='e2'></span><button class='btn' onclick='goStep(1)'>Back</button> <button class='btn' onclick='goStep(3)'>Next</button></div><div class='step' id='step3'><h2>Step 3: Confirmation</h2><div id='summary'></div><button class='btn' onclick='goStep(2)'>Back</button> <button class='btn' id='submit' onclick='submitForm()'>Submit</button></div><div class='step' id='done'><h2>Thank you!</h2><p id='result'></p></div></div><script>function goStep(n){document.querySelectorAll('.step').forEach(s=>s.classList.remove('active'));document.getElementById('step'+n).classList.add('active');if(n===3){var s='<b>Name:</b> '+document.getElementById('name').value+'<br><b>Email:</b> '+document.getElementById('email').value+'<br><b>Age:</b> '+document.getElementById('age').value+'<br><b>Newsletter:</b> '+(document.getElementById('newsletter').checked?'Yes':'No')+'<br><b>Terms:</b> '+(document.getElementById('terms').checked?'Yes':'No')+'<br><b>Comments:</b> '+document.getElementById('comments').value;document.getElementById('summary').innerHTML=s;}} function submitForm(){document.querySelectorAll('.step').forEach(s=>s.classList.remove('active'));document.getElementById('done').classList.add('active');document.getElementById('result').textContent='Form submitted for '+document.getElementById('name').value+'!';}</script></body></html>";
    root spawn set_content(html=html);
    print("=== Multi-Step Form Wizard ===\n");

    # --- Step 1: Personal Info ---
    print("--- Step 1: Personal Info ---");
    w = root spawn snapshot();
    snap = w.reports[0]["snapshot"];
    print("Visible:", snap[:200]);

    root spawn fill(selector="#name", value="John Doe");
    root spawn fill(selector="#email", value="john@example.com");
    root spawn select_option(selector="#age", value="26-35");
    print("Filled: name, email, age");

    # Verify values
    w = root spawn evaluate(script="document.getElementById('name').value");
    print("Name value:", w.reports[0]["result"]);
    w = root spawn evaluate(script="document.getElementById('email').value");
    print("Email value:", w.reports[0]["result"]);

    # Click Next
    root spawn click(selector="#step1 .btn");
    print("Clicked Next -> Step 2\n");

    # --- Step 2: Preferences ---
    print("--- Step 2: Preferences ---");
    root spawn wait_for(selector="#step2.active");

    root spawn check_element(selector="#newsletter");
    root spawn check_element(selector="#terms");
    root spawn fill(selector="#comments", value="Looking forward to it!");
    print("Checked newsletter, terms; filled comments");

    # Verify checkboxes
    w = root spawn evaluate(script="document.getElementById('newsletter').checked");
    print("Newsletter checked:", w.reports[0]["result"]);
    w = root spawn evaluate(script="document.getElementById('terms').checked");
    print("Terms checked:", w.reports[0]["result"]);

    # Click Next
    root spawn click(selector="#step2 .btn:last-child");
    print("Clicked Next -> Step 3\n");

    # --- Step 3: Confirmation ---
    print("--- Step 3: Confirmation ---");
    root spawn wait_for(selector="#step3.active");

    w = root spawn get_text(selector="#summary");
    print("Summary:", w.reports[0]["text"]);

    # Submit
    root spawn click(selector="#submit");
    print("Clicked Submit\n");

    # --- Done ---
    print("--- Result ---");
    root spawn wait_for(selector="#done.active");
    w = root spawn get_text(selector="#result");
    print("Result:", w.reports[0]["text"]);

    root spawn close_browser();
    print("\nDone.");
}
