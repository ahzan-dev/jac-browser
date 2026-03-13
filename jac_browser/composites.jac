"""Composite walkers: multi-step browser automation patterns.

These walkers compose primitive bridge operations into higher-level
workflows like login, pagination, form filling, crawling, and more.
They are unique to jac-browser and have no equivalent in agent-browser.
"""

import re;
import time;
import from datetime {datetime}
import from base64 {b64encode}
import from jac_browser.browser_bridge {PlaywrightBridge}
import from jac_browser.nodes {BrowserSession, PageNode, SnapshotNode, ElementRef}
import from jac_browser.helpers {
    get_or_create_session,
    get_active_page_node,
    get_page_object,
    store_page_object,
    get_latest_snapshot,
    remove_old_snapshots,
    get_ready_page,
    get_ref_map_for_page
}


# ===========================================================================
# login - Navigate to login page, fill credentials, submit, optionally save state
# ===========================================================================

walker :pub login {
    has url: str = "";
    has username_selector: str = "#username";
    has password_selector: str = "#password";
    has username: str = "";
    has password: str = "";
    has submit_selector: str = "button[type='submit']";
    has save_state_path: str = "";

    can go with Root entry {
        bridge = PlaywrightBridge();
        session = get_or_create_session(here);

        if not bridge.is_launched() {
            bridge.launch(headless=session.headless);
            session.is_launched = True;
            if not get_active_page_node(session) {
                pw_page = bridge.new_page();
                page_node = PageNode();
                session ++> page_node;
                store_page_object(page_node, pw_page);
            }
        }

        page_node = get_active_page_node(session);
        if not page_node {
            report {"success": False, "error": "No active page"};
            disengage;
        }
        pw_page = get_page_object(page_node);
        if not pw_page {
            report {"success": False, "error": "Page object not found"};
            disengage;
        }

        try {
            # Navigate to login page
            bridge.goto(pw_page, self.url, wait_until="load");
            bridge.wait_for_load_state(pw_page, "load");

            # Fill credentials
            ref_map = get_ref_map_for_page(page_node);
            user_loc = bridge.get_locator(pw_page, self.username_selector, ref_map);
            bridge.fill_element(user_loc, self.username);

            pass_loc = bridge.get_locator(pw_page, self.password_selector, ref_map);
            bridge.fill_element(pass_loc, self.password);

            # Submit
            submit_loc = bridge.get_locator(pw_page, self.submit_selector, ref_map);
            bridge.click_element(submit_loc);
            bridge.wait_for_load_state(pw_page, "load");

            # Update page node
            page_node.url = bridge.get_url(pw_page);
            page_node.title = bridge.get_title(pw_page);

            result = {
                "success": True,
                "url": page_node.url,
                "title": page_node.title,
                "state_saved": False
            };

            # Optionally save state for future runs
            if self.save_state_path {
                bridge.state_save(self.save_state_path);
                result["state_saved"] = True;
                result["state_path"] = self.save_state_path;
            }

            report result;
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# fill_form - Fill multiple fields, check boxes, select dropdowns, submit
# ===========================================================================

walker :pub fill_form {
    has fields: dict = {};
    has checks: list = [];
    has selects: dict = {};
    has submit_selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);

            filled = 0;
            checked = 0;
            selected = 0;

            # Fill text fields
            for key in self.fields {
                locator = bridge.get_locator(pw_page, key, ref_map);
                bridge.fill_element(locator, self.fields[key]);
                filled += 1;
            }

            # Check checkboxes
            for selector in self.checks {
                locator = bridge.get_locator(pw_page, selector, ref_map);
                bridge.check_element(locator);
                checked += 1;
            }

            # Select dropdowns
            for key in self.selects {
                locator = bridge.get_locator(pw_page, key, ref_map);
                bridge.select_option(locator, self.selects[key]);
                selected += 1;
            }

            submitted = False;
            if self.submit_selector {
                submit_loc = bridge.get_locator(pw_page, self.submit_selector, ref_map);
                bridge.click_element(submit_loc);
                bridge.wait_for_load_state(pw_page, "load");
                page_node.url = bridge.get_url(pw_page);
                page_node.title = bridge.get_title(pw_page);
                submitted = True;
            }

            report {
                "success": True,
                "fields_filled": filled,
                "checks_checked": checked,
                "selects_selected": selected,
                "submitted": submitted,
                "url": bridge.get_url(pw_page)
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# scrape - Navigate, wait, extract data, optionally screenshot
# ===========================================================================

walker :pub scrape {
    has url: str = "";
    has extract_script: str = "";
    has wait_selector: str = "";
    has include_screenshot: bool = False;

    can go with Root entry {
        bridge = PlaywrightBridge();
        session = get_or_create_session(here);

        if not bridge.is_launched() {
            bridge.launch(headless=session.headless);
            session.is_launched = True;
            if not get_active_page_node(session) {
                pw_page = bridge.new_page();
                page_node = PageNode();
                session ++> page_node;
                store_page_object(page_node, pw_page);
            }
        }

        page_node = get_active_page_node(session);
        if not page_node {
            report {"success": False, "error": "No active page"};
            disengage;
        }
        pw_page = get_page_object(page_node);
        if not pw_page {
            report {"success": False, "error": "Page object not found"};
            disengage;
        }

        try {
            bridge.goto(pw_page, self.url, wait_until="load");
            bridge.wait_for_load_state(pw_page, "load");

            # Wait for specific element if requested
            if self.wait_selector {
                ref_map = get_ref_map_for_page(page_node);
                wait_loc = bridge.get_locator(pw_page, self.wait_selector, ref_map);
                bridge.wait_for(wait_loc, state="visible");
            }

            page_node.url = bridge.get_url(pw_page);
            page_node.title = bridge.get_title(pw_page);

            result = {
                "success": True,
                "url": page_node.url,
                "title": page_node.title
            };

            # Extract data via JS or fall back to page text
            if self.extract_script {
                result["data"] = bridge.evaluate(pw_page, self.extract_script);
            } else {
                result["text"] = bridge.get_content(pw_page);
            }

            # Optional screenshot
            if self.include_screenshot {
                raw = bridge.take_screenshot(pw_page);
                result["screenshot_base64"] = b64encode(raw).decode("ascii");
            }

            report result;
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# paginate - Extract data across multiple pages by clicking next
# ===========================================================================

walker :pub paginate {
    has url: str = "";
    has extract_script: str = "";
    has next_selector: str = "";
    has max_pages: int = 10;
    has wait_state: str = "load";

    can go with Root entry {
        bridge = PlaywrightBridge();
        session = get_or_create_session(here);

        if not bridge.is_launched() {
            bridge.launch(headless=session.headless);
            session.is_launched = True;
            if not get_active_page_node(session) {
                pw_page = bridge.new_page();
                page_node = PageNode();
                session ++> page_node;
                store_page_object(page_node, pw_page);
            }
        }

        page_node = get_active_page_node(session);
        if not page_node {
            report {"success": False, "error": "No active page"};
            disengage;
        }
        pw_page = get_page_object(page_node);
        if not pw_page {
            report {"success": False, "error": "Page object not found"};
            disengage;
        }

        try {
            bridge.goto(pw_page, self.url, wait_until=self.wait_state);

            all_data: list = [];
            page_num = 0;

            while page_num < self.max_pages {
                bridge.wait_for_load_state(pw_page, self.wait_state);

                # Extract data from current page
                data = bridge.evaluate(pw_page, self.extract_script);
                current_url = bridge.get_url(pw_page);
                all_data.append({
                    "page": page_num + 1,
                    "url": current_url,
                    "data": data
                });
                page_num += 1;

                if page_num >= self.max_pages {
                    break;
                }

                # Try to click next page button
                has_next = False;
                try {
                    ref_map = get_ref_map_for_page(page_node);
                    next_loc = bridge.get_locator(pw_page, self.next_selector, ref_map);
                    visible = bridge.is_visible(next_loc);
                    if visible {
                        bridge.click_element(next_loc);
                        has_next = True;
                    }
                } except Exception {
                    has_next = False;
                }

                if not has_next {
                    break;
                }
            }

            page_node.url = bridge.get_url(pw_page);
            page_node.title = bridge.get_title(pw_page);

            report {
                "success": True,
                "pages_scraped": page_num,
                "data": all_data
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# smart_click - Find element by text/role from snapshot, click it
# ===========================================================================

walker :pub smart_click {
    has text: str = "";
    has role: str = "";
    has index: int = 0;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);

            # Take snapshot to find elements by text/role
            snap_result = bridge.take_snapshot(pw_page);
            refs = snap_result["refs"];

            # Search for matching elements
            matches: list = [];
            search_text = self.text.lower();

            for ref_id in refs {
                entry = refs[ref_id];
                name = str(entry.get("name", "")).lower();
                entry_role = str(entry.get("role", ""));

                if search_text in name {
                    if self.role {
                        if entry_role == self.role {
                            matches.append(ref_id);
                        }
                    } else {
                        matches.append(ref_id);
                    }
                }
            }

            if not matches {
                filter_desc = "text='" + self.text + "'";
                if self.role {
                    filter_desc = filter_desc + " role='" + self.role + "'";
                }
                report {
                    "success": False,
                    "error": "No elements found matching " + filter_desc
                };
                disengage;
            }

            if self.index >= len(matches) {
                report {
                    "success": False,
                    "error": "Index " + str(self.index) + " out of range, found " + str(len(matches)) + " matches"
                };
                disengage;
            }

            target_ref = matches[self.index];
            locator = bridge.get_locator(pw_page, target_ref, refs);
            bridge.click_element(locator);

            page_node.url = bridge.get_url(pw_page);
            page_node.title = bridge.get_title(pw_page);

            target_info = refs[target_ref];
            report {
                "success": True,
                "clicked_ref": target_ref,
                "clicked_role": target_info.get("role", ""),
                "clicked_name": target_info.get("name", ""),
                "total_matches": len(matches),
                "url": page_node.url
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# crawl - Follow links matching a pattern, extract data from each page
# ===========================================================================

walker :pub crawl {
    has url: str = "";
    has link_pattern: str = "";
    has extract_script: str = "";
    has max_pages: int = 10;
    has max_depth: int = 2;

    can go with Root entry {
        bridge = PlaywrightBridge();
        session = get_or_create_session(here);

        if not bridge.is_launched() {
            bridge.launch(headless=session.headless);
            session.is_launched = True;
            if not get_active_page_node(session) {
                pw_page = bridge.new_page();
                page_node = PageNode();
                session ++> page_node;
                store_page_object(page_node, pw_page);
            }
        }

        page_node = get_active_page_node(session);
        if not page_node {
            report {"success": False, "error": "No active page"};
            disengage;
        }
        pw_page = get_page_object(page_node);
        if not pw_page {
            report {"success": False, "error": "Page object not found"};
            disengage;
        }

        try {
            visited: list = [];
            results: list = [];
            queue: list = [{"url": self.url, "depth": 0}];

            while queue and len(results) < self.max_pages {
                current = queue.pop(0);
                current_url = current["url"];
                current_depth = current["depth"];

                if current_url in visited {
                    continue;
                }
                if current_depth > self.max_depth {
                    continue;
                }

                visited.append(current_url);

                # Navigate to page
                bridge.goto(pw_page, current_url, wait_until="load");
                bridge.wait_for_load_state(pw_page, "load");

                # Extract data
                data = bridge.evaluate(pw_page, self.extract_script);
                results.append({
                    "url": current_url,
                    "depth": current_depth,
                    "data": data
                });

                # Discover links if not at max depth
                if current_depth < self.max_depth {
                    links_js = "Array.from(document.querySelectorAll('a[href]')).map(a => a.href)";
                    links = bridge.evaluate(pw_page, links_js);
                    if links {
                        for link in links {
                            link_str = str(link);
                            if link_str not in visited {
                                try {
                                    if re.search(self.link_pattern, link_str) {
                                        queue.append({
                                            "url": link_str,
                                            "depth": current_depth + 1
                                        });
                                    }
                                } except Exception {
                                    pass;
                                }
                            }
                        }
                    }
                }
            }

            page_node.url = bridge.get_url(pw_page);
            page_node.title = bridge.get_title(pw_page);

            report {
                "success": True,
                "pages_crawled": len(results),
                "urls_visited": visited,
                "data": results
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# retry - Execute JS expression with retries until truthy
# ===========================================================================

walker :pub retry {
    has script: str = "";
    has retries: int = 3;
    has delay_ms: int = 1000;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);

            last_result = None;
            succeeded = False;

            for attempt in range(self.retries) {
                result = bridge.evaluate(pw_page, self.script);
                last_result = result;

                if result {
                    report {
                        "success": True,
                        "result": result,
                        "attempts": attempt + 1
                    };
                    succeeded = True;
                    break;
                }

                if attempt < self.retries - 1 {
                    time.sleep(self.delay_ms / 1000.0);
                }
            }

            if not succeeded {
                report {
                    "success": False,
                    "error": "Expression did not return truthy after " + str(self.retries) + " retries",
                    "last_result": last_result,
                    "attempts": self.retries
                };
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# observe - Combined snapshot + screenshot + metadata in one call
# ===========================================================================

walker :pub observe {
    has include_screenshot: bool = True;
    has include_html: bool = False;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);

            result = {
                "success": True,
                "url": bridge.get_url(pw_page),
                "title": bridge.get_title(pw_page)
            };

            # Take snapshot and persist to graph
            snap_result = bridge.take_snapshot(pw_page);
            remove_old_snapshots(page_node);

            snap_node = SnapshotNode(
                tree=snap_result["tree"],
                ref_map=snap_result["refs"],
                taken_at=datetime.now().isoformat(),
                origin_url=bridge.get_url(pw_page)
            );
            page_node ++> snap_node;

            # Build simple refs and persist element refs to graph
            simple_refs = {};
            for ref_id in snap_result["refs"] {
                data = snap_result["refs"][ref_id];
                simple_refs[ref_id] = {
                    "role": data.get("role", ""),
                    "name": data.get("name", "")
                };
                eref = ElementRef(
                    ref_id=ref_id,
                    role=data.get("role", ""),
                    name=data.get("name", ""),
                    selector=data.get("selector", ""),
                    nth=data.get("nth", -1)
                );
                snap_node ++> eref;
            }

            result["snapshot"] = snap_result["tree"];
            result["refs"] = simple_refs;
            result["element_count"] = len(simple_refs);

            # Optional screenshot
            if self.include_screenshot {
                raw = bridge.take_screenshot(pw_page);
                result["screenshot_base64"] = b64encode(raw).decode("ascii");
            }

            # Optional HTML
            if self.include_html {
                result["html"] = bridge.get_content(pw_page);
            }

            report result;
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}
