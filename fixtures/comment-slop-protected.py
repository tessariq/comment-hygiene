# Ordinary protected comment.
PROTECTED_DOCUMENTATION_URL = "https://example.test/protected/#fragment"

# ruff: noqa: F401
# ~keep
# This protected comment remains.
protected_value = 1
trailing_protected_value = 3  # ~keep

# Protected TODO candidate.
protected_todo_value = 2
