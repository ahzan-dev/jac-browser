"""jac-browser: Headless browser automation for Jac."""

__version__ = "0.1.0"


def _ensure_jaclang():
    try:
        import jaclang  # noqa: F401
    except ImportError:
        raise ImportError(
            "jaclang is required but not installed. "
            "Install it with: pip install jaclang"
        )


_ensure_jaclang()
