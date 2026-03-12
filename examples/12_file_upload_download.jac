"""Example 12: File Upload and Download - Handle file inputs and downloads.

Demonstrates uploading files to file input elements and downloading files
from the browser.

Usage:
    jac run examples/12_file_upload_download.jac
"""

import from tempfile {mkdtemp}
import from jac_browser.walkers {
    launch, navigate, close_browser,
    upload, download, wait_for_download,
    set_content, evaluate
}


with entry {
    root spawn launch(headless=True);

    # Create a page with a file upload input
    page_html = "<h1>File Upload Test</h1><input type='file' id='file-input' /><input type='file' id='multi-input' multiple /><div id='result'></div><script>document.getElementById('file-input').addEventListener('change', function(e) { var files = Array.from(e.target.files).map(function(f) { return f.name; }); document.getElementById('result').textContent = 'Files: ' + files.join(', '); }); document.getElementById('multi-input').addEventListener('change', function(e) { var files = Array.from(e.target.files).map(function(f) { return f.name; }); document.getElementById('result').textContent = 'Multi: ' + files.join(', '); });</script>";
    root spawn set_content(html=page_html);

    # --- Single file upload ---
    print("--- Single File Upload ---");

    # Create a temporary file to upload
    tmp_dir = mkdtemp();
    test_file = tmp_dir + "/test_document.txt";
    f = open(test_file, "w");
    f.write("Hello from jac-browser!");
    f.close();

    w = root spawn upload(selector="#file-input", files=[test_file]);
    print("Upload result:", w.reports[0]["success"]);

    # Check the result
    w = root spawn evaluate(script="document.getElementById('result').textContent");
    print("Page shows:", w.reports[0]["result"]);

    # --- Multiple file upload ---
    print("\n--- Multiple File Upload ---");

    test_file2 = tmp_dir + "/report.csv";
    f2 = open(test_file2, "w");
    f2.write("name,value\nfoo,42");
    f2.close();

    w = root spawn upload(selector="#multi-input", files=[test_file, test_file2]);
    print("Multi upload:", w.reports[0]["success"]);

    w = root spawn evaluate(script="document.getElementById('result').textContent");
    print("Page shows:", w.reports[0]["result"]);

    # --- Clear file input ---
    print("\n--- Clear File Input ---");
    w = root spawn upload(selector="#file-input", files=[]);
    print("Cleared file input:", w.reports[0]["success"]);

    # --- Download example ---
    print("\n--- Download ---");

    # Create a page with a download link
    dl_html = "<a id='download-link' href='data:text/plain;base64,SGVsbG8gV29ybGQ=' download='hello.txt'>Download File</a>";
    root spawn set_content(html=dl_html);

    # Click to download
    w = root spawn download(selector="#download-link", path=tmp_dir + "/downloaded.txt");
    print("Download result:", w.reports[0]["success"]);
    if w.reports[0].get("path") {
        print("Saved to:", w.reports[0]["path"]);
    }

    root spawn close_browser();
    print("\nDone.");
}
