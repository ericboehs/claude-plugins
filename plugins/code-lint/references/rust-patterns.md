# Rust Clippy Patterns

Fix guidance for common Rust clippy warnings. Use these BAD/GOOD patterns to fix lint errors correctly the first time.

## Clippy Warnings

### needless_return

Rust functions return the last expression implicitly. Drop the `return` keyword on the final expression.

BAD:
```rust
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}
```

GOOD:
```rust
fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

### redundant_clone

Don't clone a value that is already owned or not used after the clone.

BAD:
```rust
let name = String::from("Alice");
let greeting = format!("Hello, {}!", name.clone());
```

GOOD:
```rust
let name = String::from("Alice");
let greeting = format!("Hello, {}!", name);
```

### unnecessary_unwrap

Calling `.unwrap()` after already checking `.is_some()` or `.is_ok()` is redundant and can be replaced with an `if let` or direct use inside the branch.

BAD:
```rust
if opt.is_some() {
    println!("{}", opt.unwrap());
}
```

GOOD:
```rust
if let Some(val) = opt {
    println!("{}", val);
}
```

### map_unwrap_or

`.map(f).unwrap_or(default)` can be collapsed into `.map_or(default, f)`.

BAD:
```rust
let len = opt.map(|s: &str| s.len()).unwrap_or(0);
```

GOOD:
```rust
let len = opt.map_or(0, |s: &str| s.len());
```

### single_match

A `match` with only one non-wildcard arm should be an `if let`.

BAD:
```rust
match status {
    Status::Active => println!("active"),
    _ => {}
}
```

GOOD:
```rust
if let Status::Active = status {
    println!("active");
}
```

### manual_map

Manually matching on `Option` or `Result` just to transform the inner value is better expressed with `.map()`.

BAD:
```rust
let upper = match name {
    Some(s) => Some(s.to_uppercase()),
    None => None,
};
```

GOOD:
```rust
let upper = name.map(|s| s.to_uppercase());
```

### unused_variables / dead_code

Prefix intentionally unused variables with `_`. Remove truly dead code rather than silencing it.

BAD:
```rust
let result = compute();  // never used, triggers warning
fn helper() { }          // never called, triggers dead_code
```

GOOD:
```rust
let _result = compute(); // underscore prefix signals intentional discard
// remove dead functions entirely, or add #[cfg(test)] if test-only
```

### clippy::needless_borrow

Don't take a reference to a value that is immediately auto-deref'd or already a reference.

BAD:
```rust
fn print_name(name: &str) { println!("{}", name); }

let s = String::from("Alice");
print_name(&s.as_str());
```

GOOD:
```rust
print_name(s.as_str()); // as_str() already returns &str
// or simply:
print_name(&s);         // coerces String → &str automatically
```

### clippy::iter_next_slice

`.iter().next()` on a slice retrieves the first element; use `.first()` instead.

BAD:
```rust
let first = items.iter().next();
```

GOOD:
```rust
let first = items.first();
```
