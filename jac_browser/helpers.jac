"""Shared helper functions for walker implementations."""

import from jac_browser.browser_bridge {PlaywrightBridge}
import from jac_browser.nodes {BrowserSession, PageNode, SnapshotNode, ElementRef}


def get_or_create_session(root_node: object) -> BrowserSession {
    sessions = [root_node -->(?:BrowserSession)];
    if sessions {
        return sessions[0];
    }
    session = BrowserSession();
    root_node ++> session;
    return session;
}

def get_active_page_node(session: BrowserSession) -> PageNode {
    pages = [session -->(?:PageNode)];
    for p in pages {
        if p.is_active {
            return p;
        }
    }
    return None;
}

def get_page_object(page_node: PageNode) -> object {
    bridge = PlaywrightBridge();
    return bridge.get_page(page_node.page_id);
}

def store_page_object(page_node: PageNode, pw_page: object) -> None {
    bridge = PlaywrightBridge();
    bridge.store_page(page_node.page_id, pw_page);
}

def get_latest_snapshot(page_node: PageNode) -> SnapshotNode {
    snaps = [page_node -->(?:SnapshotNode)];
    if snaps {
        return snaps[-1];
    }
    return None;
}

def remove_old_snapshots(page_node: PageNode) -> None {
    for snap in [page_node -->(?:SnapshotNode)] {
        for eref in [snap -->(?:ElementRef)] {
            snap del --> eref;
            del eref;
        }
        page_node del --> snap;
        del snap;
    }
}

"""Return [bridge, session, page_node, pw_page] or raise RuntimeError."""
def get_ready_page(root_node: object) -> list {
    bridge = PlaywrightBridge();
    session = get_or_create_session(root_node);
    page_node = get_active_page_node(session);
    if not page_node {
        raise RuntimeError("No active page");
    }
    pw_page = get_page_object(page_node);
    if not pw_page {
        raise RuntimeError("Page object not found");
    }
    return [bridge, session, page_node, pw_page];
}

"""Return ref_map from latest snapshot or empty dict."""
def get_ref_map_for_page(page_node: PageNode) -> dict {
    snap = get_latest_snapshot(page_node);
    if snap {
        return snap.ref_map;
    }
    return {};
}
