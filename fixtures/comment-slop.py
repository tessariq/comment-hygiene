"""A small module used to exercise AST-safe comment handling."""

# Explains an obvious assignment.
DEFAULT_DOCUMENTATION_URL = "https://example.test/docs/#fragment"


def build_url(path: str) -> str:
    """Return a URL for a relative documentation path."""
    # The following URL is data, not a comment.
    return f"{DEFAULT_DOCUMENTATION_URL}/{path}"


# TODO: Replace the compatibility fallback after v2 adoption.
def normalize(value: str | None) -> str:
    # Return an empty string for null values.
    return value or ""
