# Python Linter Patterns

Fix guidance for common Python linter issues (Ruff + mypy + flake8). Use these BAD/GOOD patterns to fix lint errors correctly the first time.

## Ruff

### F841 — Unused Variable

Remove the assignment or use the value. If the call is needed for its side effects, drop the variable binding.

BAD:
```python
def process():
    result = fetch_data()
    return transform()
```

GOOD:
```python
def process():
    fetch_data()
    return transform()
```

If you need to discard a value intentionally, assign to `_`.

### E501 — Line Too Long

Break long lines at logical points: after opening brackets, before operators, or at argument boundaries.

BAD:
```python
result = some_service.create(param1=value1, param2=value2, param3=value3, param4=value4)
```

GOOD:
```python
result = some_service.create(
    param1=value1,
    param2=value2,
    param3=value3,
    param4=value4,
)
```

For long strings, use implicit concatenation or a variable.

### F401 — Unused Import

Remove it. If the import is needed for re-export, add `# noqa: F401` with a comment explaining why.

BAD:
```python
import os
import json

def greet(name: str) -> str:
    return f"Hello, {name}"
```

GOOD:
```python
def greet(name: str) -> str:
    return f"Hello, {name}"
```

### I001 — Import Order

Imports must be grouped: stdlib, third-party, local — each group separated by a blank line, sorted alphabetically within groups. Run `ruff check --fix` to auto-fix.

BAD:
```python
from myapp import utils
import os
import requests
import sys
```

GOOD:
```python
import os
import sys

import requests

from myapp import utils
```

### UP — Pyupgrade Rules

Use modern Python syntax. Common fixes:

BAD:
```python
from typing import Dict, List, Optional, Tuple

def get_users() -> List[Dict[str, str]]:
    items: Optional[List[str]] = None
    pairs: Tuple[int, ...] = (1, 2, 3)
```

GOOD:
```python
def get_users() -> list[dict[str, str]]:
    items: list[str] | None = None
    pairs: tuple[int, ...] = (1, 2, 3)
```

Use `X | Y` over `Union[X, Y]`, built-in generics (`list[str]`) over `typing.List[str]`, and `super()` over `super(ClassName, self)`.

### SIM — Simplify Rules

Common simplifications:

BAD:
```python
# SIM108: ternary
if condition:
    value = "yes"
else:
    value = "no"

# SIM102: nested if
if a:
    if b:
        do_thing()

# SIM118: key in dict
if key in d.keys():
    pass
```

GOOD:
```python
value = "yes" if condition else "no"

if a and b:
    do_thing()

if key in d:
    pass
```

## mypy

### Missing Return Type Annotations

Annotate all function signatures. Use `-> None` for functions that return nothing.

BAD:
```python
def add(x, y):
    return x + y

def log(msg):
    print(msg)
```

GOOD:
```python
def add(x: int, y: int) -> int:
    return x + y

def log(msg: str) -> None:
    print(msg)
```

### Incompatible Types in Assignment

Don't rebind a variable to a different type. Use a union type or a new variable name.

BAD:
```python
value: int = 0
value = "error"  # error: Incompatible types in assignment
```

GOOD:
```python
value: int | str = 0
value = "error"
```

### Missing Type Stubs

When mypy reports `Cannot find implementation or library stub for module`, install the stubs package or add an inline ignore.

BAD (raises error if `types-requests` not installed):
```python
import requests
```

GOOD:
```bash
pip install types-requests
```

Or suppress per-line when stubs don't exist:
```python
import some_lib  # type: ignore[import-untyped]
```

### Optional vs None Handling

`Optional[X]` (or `X | None`) means the value could be `None`. Guard before use; don't pass it where a non-optional is expected.

BAD:
```python
def greet(name: str | None) -> str:
    return name.upper()  # error: Item "None" of "str | None" has no attribute "upper"
```

GOOD:
```python
def greet(name: str | None) -> str:
    if name is None:
        return "Hello, stranger"
    return name.upper()
```

## flake8

### E302 — Expected 2 Blank Lines

Top-level function and class definitions must be preceded by exactly 2 blank lines.

BAD:
```python
def foo():
    pass
def bar():
    pass
```

GOOD:
```python
def foo():
    pass


def bar():
    pass
```

### W291 — Trailing Whitespace

Remove trailing spaces and tabs. Configure your editor to strip them on save.

BAD (space after `pass`):
```python
def foo():
    pass
```

GOOD:
```python
def foo():
    pass
```

### E711 — Comparison to None

Use `is` / `is not` for `None` comparisons, never `==` or `!=`.

BAD:
```python
if result == None:
    return

if error != None:
    raise error
```

GOOD:
```python
if result is None:
    return

if error is not None:
    raise error
```
