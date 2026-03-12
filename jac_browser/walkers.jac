"""Walker declarations and implementations for browser automation commands."""

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
# launch
# ===========================================================================

walker :pub launch {
    has headless: bool = True;

    can start with Root entry {
        bridge = PlaywrightBridge();
        try {
            bridge.launch(headless=self.headless);
            session = get_or_create_session(here);
            session.is_launched = True;
            session.headless = self.headless;

            pw_page = bridge.new_page();
            page_node = PageNode();
            session ++> page_node;
            store_page_object(page_node, pw_page);

            report {
                "success": True,
                "session_id": session.id,
                "page_id": page_node.page_id
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# navigate
# ===========================================================================

walker :pub navigate {
    has url: str = "";
    has wait_until: str = "load";

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
            bridge.goto(pw_page, self.url, wait_until=self.wait_until);
            page_node.url = bridge.get_url(pw_page);
            page_node.title = bridge.get_title(pw_page);
            session.url = page_node.url;
            report {
                "success": True,
                "url": page_node.url,
                "title": page_node.title
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# snapshot
# ===========================================================================

walker :pub snapshot {
    has selector: str = "page";

    can take with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
        } except Exception as e {
            report {"success": False, "error": str(e)};
            disengage;
        }

        try {
            result = bridge.take_snapshot(pw_page, self.selector);
            remove_old_snapshots(page_node);

            snap = SnapshotNode(
                tree=result["tree"],
                ref_map=result["refs"],
                taken_at=datetime.now().isoformat(),
                origin_url=bridge.get_url(pw_page)
            );
            page_node ++> snap;

            for ref_id in result["refs"] {
                data = result["refs"][ref_id];
                eref = ElementRef(
                    ref_id=ref_id,
                    role=data.get("role", ""),
                    name=data.get("name", ""),
                    selector=data.get("selector", ""),
                    nth=data.get("nth", -1)
                );
                snap ++> eref;
            }

            simple_refs = {};
            for ref_id in result["refs"] {
                data = result["refs"][ref_id];
                simple_refs[ref_id] = {
                    "role": data.get("role", ""),
                    "name": data.get("name", "")
                };
            }

            report {
                "success": True,
                "snapshot": result["tree"],
                "refs": simple_refs,
                "origin": bridge.get_url(pw_page)
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# click
# ===========================================================================

walker :pub click {
    has selector: str = "";

    can do_click with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.click_element(locator);
            page_node.url = bridge.get_url(pw_page);
            page_node.title = bridge.get_title(pw_page);
            report {
                "success": True,
                "clicked": self.selector,
                "url": page_node.url
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# fill
# ===========================================================================

walker :pub fill {
    has selector: str = "";
    has value: str = "";

    can do_fill with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.fill_element(locator, self.value);
            report {
                "success": True,
                "filled": self.selector,
                "value": self.value
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# type_text
# ===========================================================================

walker :pub type_text {
    has selector: str = "";
    has text: str = "";
    has delay: int = 50;
    has clear: bool = False;

    can do_type with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            if self.clear {
                bridge.clear_element(locator);
            }
            bridge.type_element(locator, self.text, delay=self.delay);
            report {
                "success": True,
                "typed": self.text,
                "selector": self.selector
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# screenshot
# ===========================================================================

walker :pub screenshot {
    has full_page: bool = False;
    has selector: str = "";

    can capture with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            raw = bridge.take_screenshot(
                pw_page,
                full_page=self.full_page,
                selector=self.selector
            );
            b64 = b64encode(raw).decode("ascii");
            report {
                "success": True,
                "base64": b64,
                "format": "png"
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# scroll
# ===========================================================================

walker :pub scroll {
    has direction: str = "down";
    has amount: int = 300;
    has selector: str = "";

    can do_scroll with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
        } except Exception as e {
            report {"success": False, "error": str(e)};
            disengage;
        }

        delta_x = 0;
        delta_y = 0;
        if self.direction == "down" {
            delta_y = self.amount;
        } elif self.direction == "up" {
            delta_y = -(self.amount);
        } elif self.direction == "right" {
            delta_x = self.amount;
        } elif self.direction == "left" {
            delta_x = -(self.amount);
        }

        try {
            if self.selector {
                ref_map = get_ref_map_for_page(page_node);
                locator = bridge.get_locator(pw_page, self.selector, ref_map);
                bridge.scroll_element(locator, delta_x, delta_y);
            } else {
                bridge.mouse_wheel(pw_page, delta_x, delta_y);
            }
            report {
                "success": True,
                "scrolled": self.direction,
                "amount": self.amount
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# get_text
# ===========================================================================

walker :pub get_text {
    has selector: str = "";

    can do_get with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            text = bridge.get_text_content(locator);
            report {
                "success": True,
                "text": text,
                "selector": self.selector
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# close_browser
# ===========================================================================

walker :pub close_browser {
    can shutdown with Root entry {
        bridge = PlaywrightBridge();
        session = get_or_create_session(here);

        try {
            bridge.close_browser();
            session.is_launched = False;

            for page_node in [session -->(?:PageNode)] {
                remove_old_snapshots(page_node);
                session del --> page_node;
                del page_node;
            }

            report {"success": True, "closed": True};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 2A: Navigation
# ===========================================================================

walker :pub back {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.go_back(pw_page);
            page_node.url = bridge.get_url(pw_page);
            page_node.title = bridge.get_title(pw_page);
            report {
                "success": True,
                "url": page_node.url,
                "title": page_node.title
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub forward {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.go_forward(pw_page);
            page_node.url = bridge.get_url(pw_page);
            page_node.title = bridge.get_title(pw_page);
            report {
                "success": True,
                "url": page_node.url,
                "title": page_node.title
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub reload {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.reload_page(pw_page);
            page_node.url = bridge.get_url(pw_page);
            page_node.title = bridge.get_title(pw_page);
            report {
                "success": True,
                "url": page_node.url,
                "title": page_node.title
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 2A: Page info
# ===========================================================================

walker :pub get_url {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            url = bridge.get_url(pw_page);
            report {"success": True, "url": url};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub get_title {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            title = bridge.get_title(pw_page);
            report {"success": True, "title": title};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 2A: Interaction
# ===========================================================================

walker :pub hover {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.hover_element(locator);
            report {"success": True, "hovered": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub dblclick {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.dblclick_element(locator);
            report {"success": True, "dblclicked": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub press {
    has selector: str = "";
    has key: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.press_key(locator, self.key);
            report {
                "success": True,
                "pressed": self.key,
                "selector": self.selector
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub check_element {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.check_element(locator);
            report {"success": True, "checked": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub uncheck_element {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.uncheck_element(locator);
            report {"success": True, "unchecked": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub select_option {
    has selector: str = "";
    has value: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.select_option(locator, self.value);
            report {
                "success": True,
                "selected": self.value,
                "selector": self.selector
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub clear_input {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.clear_element(locator);
            report {"success": True, "cleared": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 2A: Element queries
# ===========================================================================

walker :pub get_attribute {
    has selector: str = "";
    has attribute: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            value = bridge.get_attribute(locator, self.attribute);
            report {
                "success": True,
                "value": value,
                "attribute": self.attribute,
                "selector": self.selector
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub is_visible {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            visible = bridge.is_visible(locator);
            report {
                "success": True,
                "visible": visible,
                "selector": self.selector
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub is_enabled {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            enabled = bridge.is_enabled(locator);
            report {
                "success": True,
                "enabled": enabled,
                "selector": self.selector
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub is_checked {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            checked = bridge.is_checked(locator);
            report {
                "success": True,
                "checked": checked,
                "selector": self.selector
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 2B: JavaScript execution
# ===========================================================================

walker :pub evaluate {
    has script: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            result = bridge.evaluate(pw_page, self.script);
            report {"success": True, "result": result};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 2B: Wait commands
# ===========================================================================

walker :pub wait_for {
    has selector: str = "";
    has state: str = "visible";
    has timeout: int = 30000;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.wait_for(locator, state=self.state, timeout=self.timeout);
            report {
                "success": True,
                "selector": self.selector,
                "state": self.state
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub wait_for_url {
    has url: str = "";
    has timeout: int = 30000;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.wait_for_url(pw_page, self.url, timeout=self.timeout);
            report {"success": True, "url": self.url};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 2B: Cookies
# ===========================================================================

walker :pub cookies_get {
    has url: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            cookies = bridge.cookies_get(url=self.url);
            report {"success": True, "cookies": cookies};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub cookies_set {
    has cookies: list = [];

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.cookies_set(self.cookies);
            report {"success": True, "set": len(self.cookies)};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub cookies_clear {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.cookies_clear();
            report {"success": True, "cleared": True};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 2B: Element count
# ===========================================================================

walker :pub element_count {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            count = bridge.element_count(locator);
            report {
                "success": True,
                "count": count,
                "selector": self.selector
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 2C: Tab management
# ===========================================================================

walker :pub tab_new {
    has url: str = "";

    can go with Root entry {
        bridge = PlaywrightBridge();
        session = get_or_create_session(here);

        if not bridge.is_launched() {
            report {"success": False, "error": "Browser not launched"};
            disengage;
        }

        try {
            # Deactivate all existing page nodes
            for p in [session -->(?:PageNode)] {
                p.is_active = False;
            }

            pw_page = bridge.new_page();
            page_node = PageNode();
            page_node.is_active = True;
            session ++> page_node;
            store_page_object(page_node, pw_page);

            if self.url {
                bridge.goto(pw_page, self.url);
                page_node.url = bridge.get_url(pw_page);
                page_node.title = bridge.get_title(pw_page);
            }

            report {
                "success": True,
                "page_id": page_node.page_id,
                "url": page_node.url
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub tab_list {
    can go with Root entry {
        bridge = PlaywrightBridge();
        session = get_or_create_session(here);

        tabs: list = [];
        for p in [session -->(?:PageNode)] {
            pw_page = get_page_object(p);
            url = "";
            title = "";
            if pw_page {
                try {
                    url = bridge.get_url(pw_page);
                    title = bridge.get_title(pw_page);
                } except Exception {
                    url = "";
                    title = "";
                }
            }
            tabs.append({
                "page_id": p.page_id,
                "url": url,
                "title": title,
                "is_active": p.is_active
            });
        }

        report {"success": True, "tabs": tabs};
        disengage;
    }
}

walker :pub tab_switch {
    has page_id: str = "";

    can go with Root entry {
        session = get_or_create_session(here);
        found = False;

        for p in [session -->(?:PageNode)] {
            if p.page_id == self.page_id {
                p.is_active = True;
                found = True;
            } else {
                p.is_active = False;
            }
        }

        if found {
            report {"success": True, "active_page_id": self.page_id};
        } else {
            report {"success": False, "error": "Page not found: " + self.page_id};
        }
        disengage;
    }
}

walker :pub tab_close {
    has page_id: str = "";

    can go with Root entry {
        bridge = PlaywrightBridge();
        session = get_or_create_session(here);
        pages = [session -->(?:PageNode)];

        # Find target page
        target = None;
        target_id = self.page_id;

        if not target_id {
            # Close active page
            for p in pages {
                if p.is_active {
                    target = p;
                    target_id = p.page_id;
                    break;
                }
            }
        } else {
            for p in pages {
                if p.page_id == target_id {
                    target = p;
                    break;
                }
            }
        }

        if not target {
            report {"success": False, "error": "Page not found"};
            disengage;
        }

        try {
            # Close the Playwright page
            pw_page = get_page_object(target);
            if pw_page {
                bridge.close_page(pw_page);
            }
            bridge.remove_page(target_id);

            # Remove snapshots and page node from graph
            remove_old_snapshots(target);
            session del --> target;
            del target;

            # Activate another tab if the closed one was active
            remaining = [session -->(?:PageNode)];
            if remaining {
                has_active = False;
                for p in remaining {
                    if p.is_active {
                        has_active = True;
                        break;
                    }
                }
                if not has_active {
                    remaining[0].is_active = True;
                }
            }

            report {"success": True, "closed_page_id": target_id};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3A: Dialog handling
# ===========================================================================

walker :pub dialog {
    has response: str = "accept";
    has prompt_text: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.set_dialog_handler(pw_page, self.response, self.prompt_text);
            report {
                "success": True,
                "handler": "set",
                "response": self.response
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3A: File upload
# ===========================================================================

walker :pub upload {
    has selector: str = "";
    has files: list = [];

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.set_input_files(locator, self.files);
            report {"success": True, "uploaded": self.files};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3A: File download
# ===========================================================================

walker :pub download {
    has selector: str = "";
    has path: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            result = bridge.download_file(pw_page, locator, self.path);
            report {
                "success": True,
                "path": result["path"],
                "suggested_filename": result["suggested_filename"]
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3A: Focus
# ===========================================================================

walker :pub focus {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.focus_element(locator);
            report {"success": True, "focused": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3A: Drag and drop
# ===========================================================================

walker :pub drag {
    has source: str = "";
    has target: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.drag_and_drop(pw_page, self.source, self.target);
            report {
                "success": True,
                "source": self.source,
                "target": self.target
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3A: Scroll into view
# ===========================================================================

walker :pub scroll_into_view {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.scroll_into_view(locator);
            report {"success": True, "scrolled": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3B: Storage
# ===========================================================================

walker :pub storage_get {
    has key: str = "";
    has storage_type: str = "local";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            result = bridge.storage_get(pw_page, self.key, self.storage_type);
            if self.key {
                report {"success": True, "key": self.key, "value": result};
            } else {
                report {"success": True, "data": result};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub storage_set {
    has key: str = "";
    has value: str = "";
    has storage_type: str = "local";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.storage_set(pw_page, self.key, self.value, self.storage_type);
            report {"success": True, "set": True, "key": self.key};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub storage_clear {
    has storage_type: str = "local";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.storage_clear(pw_page, self.storage_type);
            report {"success": True, "cleared": True, "type": self.storage_type};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3C: Console capture
# ===========================================================================

walker :pub console_get {
    has do_clear: bool = False;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.install_console_listener(pw_page, page_node.page_id);
            if self.do_clear {
                bridge.clear_console_messages();
                report {"success": True, "cleared": True};
            } else {
                messages = bridge.get_console_messages();
                report {"success": True, "messages": messages, "count": len(messages)};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub errors_get {
    has do_clear: bool = False;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.install_error_listener(pw_page, page_node.page_id);
            if self.do_clear {
                bridge.clear_page_errors();
                report {"success": True, "cleared": True};
            } else {
                errors = bridge.get_page_errors();
                report {"success": True, "errors": errors, "count": len(errors)};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3D: Content inspection
# ===========================================================================

walker :pub inner_text {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            text = bridge.inner_text(locator);
            report {"success": True, "text": text, "selector": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub inner_html {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            html = bridge.inner_html(locator);
            report {"success": True, "html": html, "selector": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub input_value {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            value = bridge.input_value(locator);
            report {"success": True, "value": value, "selector": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub bounding_box {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            box = bridge.bounding_box(locator);
            report {"success": True, "box": box, "selector": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub get_html_content {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            html = bridge.get_content(pw_page, self.selector);
            report {"success": True, "html": html};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub dispatch_event {
    has selector: str = "";
    has event: str = "";
    has event_init: dict = {};

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.dispatch_event(locator, self.event, self.event_init);
            report {
                "success": True,
                "dispatched": self.event,
                "selector": self.selector
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3E: Mouse control
# ===========================================================================

walker :pub mouse_move {
    has x: float = 0.0;
    has y: float = 0.0;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.mouse_move(pw_page, self.x, self.y);
            report {"success": True, "x": self.x, "y": self.y};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub mouse_down {
    has button: str = "left";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.mouse_down(pw_page, self.button);
            report {"success": True, "button": self.button, "state": "down"};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub mouse_up {
    has button: str = "left";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.mouse_up(pw_page, self.button);
            report {"success": True, "button": self.button, "state": "up"};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3E: Keyboard control
# ===========================================================================

walker :pub keyboard {
    has subaction: str = "press";
    has text: str = "";
    has keys: str = "";
    has delay: int = 0;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            if self.subaction == "type" {
                bridge.keyboard_type(pw_page, self.text, self.delay);
                report {"success": True, "typed": True, "text": self.text};
            } elif self.subaction == "insertText" {
                bridge.keyboard_insert_text(pw_page, self.text);
                report {"success": True, "inserted": True, "text": self.text};
            } else {
                bridge.keyboard_press(pw_page, self.keys);
                report {"success": True, "pressed": self.keys};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub key_down {
    has key: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.key_down(pw_page, self.key);
            report {"success": True, "key": self.key, "state": "down"};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub key_up {
    has key: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.key_up(pw_page, self.key);
            report {"success": True, "key": self.key, "state": "up"};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3E: Network interception
# ===========================================================================

walker :pub route {
    has url: str = "";
    has response_status: int = 200;
    has response_body: str = "";
    has response_content_type: str = "text/plain";
    has abort: bool = False;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.add_route(
                pw_page, self.url, abort=self.abort,
                status=self.response_status, body=self.response_body,
                content_type=self.response_content_type
            );
            report {"success": True, "routed": self.url};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub unroute {
    has url: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.remove_route(pw_page, self.url);
            if self.url {
                report {"success": True, "unrouted": self.url};
            } else {
                report {"success": True, "unrouted": "all"};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub requests_get {
    has filter: str = "";
    has do_clear: bool = False;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.install_request_listener(pw_page, page_node.page_id);
            if self.do_clear {
                bridge.clear_request_log();
                report {"success": True, "cleared": True};
            } else {
                reqs = bridge.get_request_log(self.filter);
                report {"success": True, "requests": reqs, "count": len(reqs)};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3E: Advanced waits
# ===========================================================================

walker :pub wait_for_load_state {
    has state: str = "load";
    has timeout: int = 30000;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.wait_for_load_state(pw_page, self.state, self.timeout);
            report {"success": True, "state": self.state};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub wait_for_function {
    has expression: str = "";
    has timeout: int = 30000;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.wait_for_function(pw_page, self.expression, self.timeout);
            report {"success": True, "waited": True};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3F: Page configuration
# ===========================================================================

walker :pub viewport {
    has width: int = 1280;
    has height: int = 720;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.set_viewport(pw_page, self.width, self.height);
            report {"success": True, "width": self.width, "height": self.height};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub set_content {
    has html: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.set_content(pw_page, self.html);
            report {"success": True, "set": True};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub emulate_media {
    has media: str = "";
    has color_scheme: str = "";
    has reduced_motion: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.emulate_media(pw_page, self.media, self.color_scheme, self.reduced_motion);
            report {"success": True, "emulated": True};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub offline {
    has is_offline: bool = True;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.set_offline(self.is_offline);
            report {"success": True, "offline": self.is_offline};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 3F: State persistence
# ===========================================================================

walker :pub state_save {
    has path: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.state_save(self.path);
            report {"success": True, "path": self.path};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub state_load {
    has path: str = "";

    can go with Root entry {
        bridge = PlaywrightBridge();
        session = get_or_create_session(here);

        if not bridge.is_launched() {
            report {"success": False, "error": "Browser not launched"};
            disengage;
        }

        try {
            bridge.state_load(self.path);

            # Remove old page nodes from graph
            for page_node in [session -->(?:PageNode)] {
                remove_old_snapshots(page_node);
                session del --> page_node;
                del page_node;
            }

            # Create new page in the loaded context
            pw_page = bridge.new_page();
            page_node = PageNode();
            session ++> page_node;
            store_page_object(page_node, pw_page);

            report {
                "success": True,
                "loaded": True,
                "path": self.path,
                "page_id": page_node.page_id
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Frames
# ===========================================================================

walker :pub frame {
    has selector: str = "";
    has script: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            if self.script {
                result = bridge.frame_evaluate(pw_page, self.selector, self.script);
                report {"success": True, "result": result};
            } else {
                fl = bridge.frame_locator(pw_page, self.selector);
                report {"success": True, "frame": self.selector};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub mainframe {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            url = bridge.main_frame_url(pw_page);
            report {"success": True, "url": url};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Semantic locators
# ===========================================================================

walker :pub get_by_text {
    has text: str = "";
    has exact: bool = False;
    has action: str = "click";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            locator = bridge.get_by_text(pw_page, self.text, self.exact);
            if self.action == "click" {
                bridge.click_element(locator);
            } elif self.action == "count" {
                report {"success": True, "count": bridge.element_count(locator)};
                disengage;
            }
            report {"success": True, "text": self.text, "action": self.action};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub get_by_role {
    has role: str = "";
    has name: str = "";
    has action: str = "click";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            locator = bridge.get_by_role(pw_page, self.role, self.name);
            if self.action == "click" {
                bridge.click_element(locator);
            } elif self.action == "count" {
                report {"success": True, "count": bridge.element_count(locator)};
                disengage;
            }
            report {"success": True, "role": self.role, "action": self.action};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub get_by_label {
    has text: str = "";
    has exact: bool = False;
    has action: str = "click";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            locator = bridge.get_by_label(pw_page, self.text, self.exact);
            if self.action == "click" {
                bridge.click_element(locator);
            } elif self.action == "fill" {
                report {"success": False, "error": "Use fill walker with label selector"};
                disengage;
            } elif self.action == "count" {
                report {"success": True, "count": bridge.element_count(locator)};
                disengage;
            }
            report {"success": True, "label": self.text, "action": self.action};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub get_by_placeholder {
    has text: str = "";
    has exact: bool = False;
    has action: str = "click";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            locator = bridge.get_by_placeholder(pw_page, self.text, self.exact);
            if self.action == "click" {
                bridge.click_element(locator);
            } elif self.action == "count" {
                report {"success": True, "count": bridge.element_count(locator)};
                disengage;
            }
            report {"success": True, "placeholder": self.text, "action": self.action};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub get_by_alt_text {
    has text: str = "";
    has exact: bool = False;
    has action: str = "click";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            locator = bridge.get_by_alt_text(pw_page, self.text, self.exact);
            if self.action == "click" {
                bridge.click_element(locator);
            } elif self.action == "count" {
                report {"success": True, "count": bridge.element_count(locator)};
                disengage;
            }
            report {"success": True, "alt_text": self.text, "action": self.action};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub get_by_title {
    has text: str = "";
    has exact: bool = False;
    has action: str = "click";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            locator = bridge.get_by_title(pw_page, self.text, self.exact);
            if self.action == "click" {
                bridge.click_element(locator);
            } elif self.action == "count" {
                report {"success": True, "count": bridge.element_count(locator)};
                disengage;
            }
            report {"success": True, "title": self.text, "action": self.action};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub get_by_test_id {
    has test_id: str = "";
    has action: str = "click";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            locator = bridge.get_by_test_id(pw_page, self.test_id);
            if self.action == "click" {
                bridge.click_element(locator);
            } elif self.action == "count" {
                report {"success": True, "count": bridge.element_count(locator)};
                disengage;
            }
            report {"success": True, "test_id": self.test_id, "action": self.action};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: PDF export
# ===========================================================================

walker :pub pdf {
    has path: str = "";
    has format: str = "";
    has landscape: bool = False;
    has print_background: bool = False;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            data = bridge.pdf_export(pw_page, self.format, self.landscape, self.print_background);
            if self.path {
                with open(self.path, "wb") as f {
                    f.write(data);
                }
                report {"success": True, "path": self.path, "size": len(data)};
            } else {
                b64 = b64encode(data).decode("ascii");
                report {"success": True, "base64": b64, "size": len(data)};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Emulation
# ===========================================================================

walker :pub geolocation {
    has latitude: float = 0.0;
    has longitude: float = 0.0;
    has accuracy: float = 0.0;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.grant_permissions(["geolocation"]);
            bridge.set_geolocation(self.latitude, self.longitude, self.accuracy);
            report {
                "success": True,
                "latitude": self.latitude,
                "longitude": self.longitude
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub permissions {
    has grant: list = [];
    has do_clear: bool = False;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            if self.do_clear {
                bridge.clear_permissions();
                report {"success": True, "cleared": True};
            } else {
                bridge.grant_permissions(self.grant);
                report {"success": True, "granted": self.grant};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub timezone {
    has timezone_id: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.evaluate(pw_page,
                "Intl.DateTimeFormat().resolvedOptions().timeZone");
            report {
                "success": True,
                "note": "Timezone must be set at context creation. Use evaluate for runtime checks.",
                "timezone": self.timezone_id
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub locale {
    has locale_str: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            current = bridge.evaluate(pw_page, "navigator.language");
            report {
                "success": True,
                "current_locale": current,
                "note": "Locale must be set at context creation."
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub useragent {
    has user_agent: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            current = bridge.evaluate(pw_page, "navigator.userAgent");
            report {
                "success": True,
                "current": current,
                "note": "User agent must be set at context creation."
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub device {
    has device_name: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {
                "success": True,
                "note": "Device emulation must be set at context creation.",
                "device": self.device_name
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub device_list {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            devices = bridge.evaluate(pw_page, "[]");
            report {
                "success": True,
                "note": "Device list available from playwright.devices",
                "devices": []
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Auth & HTTP
# ===========================================================================

walker :pub credentials {
    has username: str = "";
    has password: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.set_http_credentials(self.username, self.password);
            report {"success": True, "username": self.username};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub headers {
    has headers_dict: dict = {};

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.set_extra_http_headers(self.headers_dict);
            report {"success": True, "headers_set": len(self.headers_dict)};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Script injection
# ===========================================================================

walker :pub add_init_script {
    has script: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.add_init_script(pw_page, self.script);
            report {"success": True, "added": True};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub add_script {
    has url: str = "";
    has content: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.add_script_tag(pw_page, self.url, self.content);
            report {"success": True, "added": True};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub add_style {
    has url: str = "";
    has content: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.add_style_tag(pw_page, self.url, self.content);
            report {"success": True, "added": True};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Advanced element operations
# ===========================================================================

walker :pub highlight {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.highlight_element(locator);
            report {"success": True, "highlighted": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub set_checked {
    has selector: str = "";
    has checked: bool = True;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.set_checked(locator, self.checked);
            report {"success": True, "checked": self.checked, "selector": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub select_all {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.select_all(pw_page);
            report {"success": True, "selected": "all"};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub multi_select {
    has selector: str = "";
    has values: list = [];

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.multi_select(locator, self.values);
            report {"success": True, "selected": self.values, "selector": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub nth {
    has selector: str = "";
    has index: int = 0;
    has action: str = "click";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            target = bridge.locator_nth(locator, self.index);
            if self.action == "click" {
                bridge.click_element(target);
            } elif self.action == "text" {
                text = bridge.get_text_content(target);
                report {"success": True, "text": text, "index": self.index};
                disengage;
            }
            report {"success": True, "index": self.index, "action": self.action};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Clipboard
# ===========================================================================

walker :pub clipboard {
    has action: str = "read";
    has text: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            if self.action == "write" {
                bridge.clipboard_write(pw_page, self.text);
                report {"success": True, "action": "write"};
            } else {
                result = bridge.clipboard_read(pw_page);
                report {"success": True, "action": "read", "text": result};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Mouse extras
# ===========================================================================

walker :pub mouse_click {
    has x: float = 0.0;
    has y: float = 0.0;
    has button: str = "left";
    has click_count: int = 1;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.mouse_click(pw_page, self.x, self.y, self.button, self.click_count);
            report {"success": True, "x": self.x, "y": self.y, "button": self.button};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub mouse_dblclick {
    has x: float = 0.0;
    has y: float = 0.0;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.mouse_dblclick(pw_page, self.x, self.y);
            report {"success": True, "x": self.x, "y": self.y};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub wheel {
    has delta_x: float = 0.0;
    has delta_y: float = 0.0;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.mouse_wheel(pw_page, int(self.delta_x), int(self.delta_y));
            report {"success": True, "delta_x": self.delta_x, "delta_y": self.delta_y};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Touch
# ===========================================================================

walker :pub tap {
    has selector: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.tap_element(locator);
            report {"success": True, "tapped": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Browser window
# ===========================================================================

walker :pub bring_to_front {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.bring_to_front(pw_page);
            report {"success": True};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub window_new {
    has url: str = "";

    can go with Root entry {
        bridge = PlaywrightBridge();
        session = get_or_create_session(here);

        if not bridge.is_launched() {
            report {"success": False, "error": "Browser not launched"};
            disengage;
        }

        try {
            for p in [session -->(?:PageNode)] {
                p.is_active = False;
            }

            pw_page = bridge.new_page();
            page_node = PageNode();
            page_node.is_active = True;
            session ++> page_node;
            store_page_object(page_node, pw_page);

            if self.url {
                bridge.goto(pw_page, self.url);
                page_node.url = bridge.get_url(pw_page);
                page_node.title = bridge.get_title(pw_page);
            }

            report {
                "success": True,
                "page_id": page_node.page_id,
                "url": page_node.url
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Tracing
# ===========================================================================

walker :pub trace_start {
    has name: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.tracing_start(self.name);
            report {"success": True, "tracing": "started"};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub trace_stop {
    has path: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.tracing_stop(self.path);
            report {"success": True, "tracing": "stopped", "path": self.path};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub har_start {
    has path: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.har_start(pw_page, self.path);
            report {"success": True, "har": "started", "path": self.path};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub har_stop {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {"success": True, "har": "stopped"};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub video_path {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            path = bridge.video_path(pw_page);
            report {"success": True, "path": path};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Advanced JS
# ===========================================================================

walker :pub eval_handle {
    has script: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            result = bridge.evaluate_handle(pw_page, self.script);
            report {"success": True, "result": result};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub expose {
    has name: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {
                "success": True,
                "note": "expose_function requires a Python callable. Use evaluate for most use cases.",
                "name": self.name
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub pause_page {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {
                "success": True,
                "note": "page.pause() only works in headed mode with PWDEBUG=1"
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Confirmation
# ===========================================================================

walker :pub confirm {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.set_confirm_handler(pw_page, True);
            report {"success": True, "handler": "confirm_accept"};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub deny {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.set_confirm_handler(pw_page, False);
            report {"success": True, "handler": "confirm_deny"};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Visual diff
# ===========================================================================

walker :pub diff_screenshot {
    has selector1: str = "";
    has selector2: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            img1 = bridge.take_screenshot(pw_page, selector=self.selector1);
            img2 = bridge.take_screenshot(pw_page, selector=self.selector2);
            result = bridge.diff_screenshots(img1, img2);
            report {"success": True, "diff": result};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub diff_snapshot {
    has snapshot1: str = "";
    has snapshot2: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            if not self.snapshot1 {
                snap = bridge.take_snapshot(pw_page);
                self.snapshot1 = snap["tree"];
            }
            match_result = self.snapshot1 == self.snapshot2;
            report {
                "success": True,
                "match": match_result,
                "snapshot1_len": len(self.snapshot1),
                "snapshot2_len": len(self.snapshot2)
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub diff_url {
    has expected_url: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            current = bridge.get_url(pw_page);
            match_result = current == self.expected_url;
            report {
                "success": True,
                "match": match_result,
                "current": current,
                "expected": self.expected_url
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: State management extras
# ===========================================================================

walker :pub state_list {
    has directory: str = ".";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            files = bridge.state_list(self.directory);
            report {"success": True, "files": files, "count": len(files)};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub state_show {
    has path: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            data = bridge.state_show(self.path);
            report {"success": True, "data": data};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub state_delete {
    has path: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.state_delete(self.path);
            report {"success": True, "deleted": self.path};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub state_rename {
    has old_path: str = "";
    has new_path: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.state_rename(self.old_path, self.new_path);
            report {"success": True, "renamed": True, "from": self.old_path, "to": self.new_path};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub state_clear {
    has directory: str = ".";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            files = bridge.state_list(self.directory);
            for f in files {
                bridge.state_delete(self.directory + "/" + f);
            }
            report {"success": True, "cleared": len(files)};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Input injection (CDP-based, stubbed)
# ===========================================================================

walker :pub input_keyboard {
    has key: str = "";
    has text: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            if self.text {
                bridge.keyboard_type(pw_page, self.text, 0);
            } elif self.key {
                bridge.keyboard_press(pw_page, self.key);
            }
            report {"success": True, "key": self.key, "text": self.text};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub input_mouse {
    has x: float = 0.0;
    has y: float = 0.0;
    has action: str = "click";
    has button: str = "left";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            if self.action == "click" {
                bridge.mouse_click(pw_page, self.x, self.y, self.button, 1);
            } elif self.action == "move" {
                bridge.mouse_move(pw_page, self.x, self.y);
            } elif self.action == "down" {
                bridge.mouse_down(pw_page, self.button);
            } elif self.action == "up" {
                bridge.mouse_up(pw_page, self.button);
            }
            report {"success": True, "action": self.action, "x": self.x, "y": self.y};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub input_touch {
    has x: float = 0.0;
    has y: float = 0.0;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {
                "success": True,
                "note": "Touch input requires context with has_touch=True",
                "x": self.x,
                "y": self.y
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Network extras
# ===========================================================================

walker :pub response_body {
    has url_filter: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {
                "success": True,
                "note": "Use route walker to intercept responses, or requests_get for request logging."
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub screencast_start {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {
                "success": True,
                "note": "Screencast requires CDP. Use video recording via context options instead."
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub screencast_stop {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {"success": True, "note": "Screencast stopped."};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Profiler (stubbed - requires CDP)
# ===========================================================================

walker :pub profiler_start {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {"success": True, "note": "Profiler requires CDP protocol access."};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub profiler_stop {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {"success": True, "note": "Profiler requires CDP protocol access."};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4: Recording
# ===========================================================================

walker :pub recording_start {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {
                "success": True,
                "note": "Use trace_start for tracing. Video requires context-level record_video_dir."
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub recording_stop {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            report {"success": True, "note": "Use trace_stop to stop tracing."};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub insert_text {
    has text: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.keyboard_insert_text(pw_page, self.text);
            report {"success": True, "inserted": self.text};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub set_value {
    has selector: str = "";
    has value: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            bridge.fill_element(locator, self.value);
            report {"success": True, "value": self.value, "selector": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4 gap: Computed CSS styles
# ===========================================================================

walker :pub styles {
    has selector: str = "";
    has properties: list = [];

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);
            locator = bridge.get_locator(pw_page, self.selector, ref_map);
            result = bridge.get_computed_styles(locator, self.properties);
            report {"success": True, "styles": result, "selector": self.selector};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4 gap: State clean (delete old state files)
# ===========================================================================

walker :pub state_clean {
    has directory: str = ".";
    has max_age_days: int = 30;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            deleted = bridge.state_clean(self.directory, self.max_age_days);
            report {"success": True, "deleted": deleted};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4 gap: Wait for download
# ===========================================================================

walker :pub wait_for_download {
    has selector: str = "";
    has path: str = "";
    has timeout: int = 30000;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            ref_map = get_ref_map_for_page(page_node);

            if self.selector {
                locator = bridge.get_locator(pw_page, self.selector, ref_map);
                def _click_action() -> None {
                    locator.click();
                }
                result = bridge.wait_for_download(pw_page, _click_action, self.path, self.timeout);
            } else {
                result = bridge.wait_for_download(pw_page, None, self.path, self.timeout);
            }
            report {
                "success": True,
                "suggested_filename": result["suggested_filename"],
                "path": result["path"]
            };
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4 gap: Swipe (touch gesture)
# ===========================================================================

walker :pub swipe {
    has direction: str = "up";
    has start_x: float = 200.0;
    has start_y: float = 400.0;
    has distance: float = 300.0;
    has steps: int = 10;

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            end_x = self.start_x;
            end_y = self.start_y;
            if self.direction == "up" {
                end_y = self.start_y - self.distance;
            } elif self.direction == "down" {
                end_y = self.start_y + self.distance;
            } elif self.direction == "left" {
                end_x = self.start_x - self.distance;
            } elif self.direction == "right" {
                end_x = self.start_x + self.distance;
            }
            bridge.swipe(pw_page, self.start_x, self.start_y, end_x, end_y, self.steps);
            report {"success": True, "direction": self.direction, "distance": self.distance};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4 gap: Recording restart
# ===========================================================================

walker :pub recording_restart {
    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            bridge.recording_restart();
            report {"success": True, "recording": "restarted"};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}


# ===========================================================================
# Phase 4 gap: Auth vault
# ===========================================================================

walker :pub auth_save {
    has name: str = "";
    has url: str = "";
    has username: str = "";
    has password: str = "";
    has username_selector: str = "";
    has password_selector: str = "";
    has submit_selector: str = "";

    can go with Root entry {
        try {
            bridge = PlaywrightBridge();
            result = bridge.auth_save(
                self.name, self.url, self.username, self.password,
                self.username_selector, self.password_selector, self.submit_selector
            );
            report {"success": True, "saved": result};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub auth_list {
    can go with Root entry {
        try {
            bridge = PlaywrightBridge();
            profiles = bridge.auth_list();
            report {"success": True, "profiles": profiles, "count": len(profiles)};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub auth_show {
    has name: str = "";

    can go with Root entry {
        try {
            bridge = PlaywrightBridge();
            profile = bridge.auth_show(self.name);
            if "error" in profile {
                report {"success": False, "error": profile["error"]};
            } else {
                report {"success": True, "profile": profile};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub auth_delete {
    has name: str = "";

    can go with Root entry {
        try {
            bridge = PlaywrightBridge();
            bridge.auth_delete(self.name);
            report {"success": True, "deleted": self.name};
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}

walker :pub auth_login {
    has name: str = "";

    can go with Root entry {
        try {
            (bridge, session, page_node, pw_page) = get_ready_page(here);
            result = bridge.auth_login(self.name, pw_page);
            if "error" in result {
                report {"success": False, "error": result["error"]};
            } else {
                page_node.url = result["url"];
                page_node.title = result["title"];
                report {"success": True, "url": result["url"], "title": result["title"]};
            }
        } except Exception as e {
            report {"success": False, "error": str(e)};
        }
        disengage;
    }
}
