"""Graph nodes representing browser automation state."""

import from uuid {uuid4}
import from datetime {datetime}


node BrowserSession {
    has id: str = "",
        headless: bool = True,
        is_launched: bool = False,
        created_at: str = "",
        url: str = "";

    def postinit {
        self.id = str(uuid4());
        self.created_at = datetime.now().isoformat();
    }
}

node PageNode {
    has page_id: str = "",
        url: str = "",
        title: str = "",
        is_active: bool = True;

    def postinit {
        self.page_id = str(uuid4());
    }
}

node SnapshotNode {
    has tree: str = "",
        ref_map: dict = {},
        taken_at: str = "",
        origin_url: str = "";
}

node ElementRef {
    has ref_id: str = "",
        role: str = "",
        name: str = "",
        selector: str = "",
        nth: int = -1;
}
