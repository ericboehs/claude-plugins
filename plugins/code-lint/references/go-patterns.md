# Go Linter Patterns

Fix guidance for common Go linter issues (golangci-lint). Use these BAD/GOOD patterns to fix lint errors correctly the first time.

## errcheck

### Unchecked Error Returns

Always handle returned errors. Silently ignoring them hides bugs.

BAD:
```go
os.Remove(tmpFile)
json.Unmarshal(data, &result)
```

GOOD:
```go
if err := os.Remove(tmpFile); err != nil {
    return fmt.Errorf("removing temp file: %w", err)
}
if err := json.Unmarshal(data, &result); err != nil {
    return fmt.Errorf("parsing response: %w", err)
}
```

If the error is genuinely safe to ignore, be explicit: `_ = os.Remove(tmpFile)`

## govet

### Printf Format Mismatch

BAD:
```go
fmt.Printf("user %s has %d points", user.Name, "lots")  // string passed for %d
log.Printf("got error: %s", err)                         // use %v for errors
```

GOOD:
```go
fmt.Printf("user %s has %d points", user.Name, user.Points)
log.Printf("got error: %v", err)
```

### Struct Tag Syntax

BAD:
```go
type User struct {
    Name string `json: "name"`   // space after colon is invalid
    Age  int    `json:"age" db:"age" ` // trailing space
}
```

GOOD:
```go
type User struct {
    Name string `json:"name"`
    Age  int    `json:"age" db:"age"`
}
```

## staticcheck

### Unreachable Code (SA4xxx)

BAD:
```go
func process() error {
    return nil
    log.Println("done") // unreachable
}
```

GOOD:
```go
func process() error {
    log.Println("done")
    return nil
}
```

### Useless Assignment (SA4006)

BAD:
```go
func validate(s string) bool {
    err := checkFormat(s)
    err = checkLength(s)  // first assignment never read
    return err == nil
}
```

GOOD:
```go
func validate(s string) bool {
    if err := checkFormat(s); err != nil {
        return false
    }
    return checkLength(s) == nil
}
```

## ineffassign

### Ineffective Assignment

BAD:
```go
func getConfig() Config {
    cfg := Config{}
    cfg, err := loadFromFile()  // := shadows cfg; original assignment is useless
    if err != nil {
        return Config{}
    }
    return cfg
}
```

GOOD:
```go
func getConfig() Config {
    cfg, err := loadFromFile()
    if err != nil {
        return Config{}
    }
    return cfg
}
```

## unused

### Unused Variables / Functions / Types

BAD:
```go
func handler(w http.ResponseWriter, r *http.Request) {
    userID := r.Header.Get("X-User-ID")  // declared but never used
    respond(w, "ok")
}
```

GOOD:
```go
func handler(w http.ResponseWriter, r *http.Request) {
    userID := r.Header.Get("X-User-ID")
    log.Printf("request from user %s", userID)
    respond(w, "ok")
}
```

Unexported functions/types with no callers should be removed or exported if needed externally.

## gosimple

### Unnecessary Nil Check Before Range

BAD:
```go
if items != nil {
    for _, item := range items {
        process(item)
    }
}
```

GOOD:
```go
for _, item := range items {
    process(item)
}
```

### Select With Single Channel

BAD:
```go
select {
case v := <-ch:
    handle(v)
}
```

GOOD:
```go
v := <-ch
handle(v)
```

## gocritic

### rangeValCopy — Large Struct Copy in Range

BAD:
```go
type Record struct { Data [1024]byte }

for _, r := range records {  // copies 1KB per iteration
    process(r)
}
```

GOOD:
```go
for i := range records {
    process(&records[i])
}
```

### appendAssign — Result of Append Not Used

BAD:
```go
func extend(items []string) {
    items = append(items, "extra")  // mutation lost; caller sees unchanged slice
}
```

GOOD:
```go
func extend(items []string) []string {
    return append(items, "extra")
}
```

## gofmt / goimports

### Formatting

Run `gofmt -w .` or `goimports -w .` — do not fix manually. Common triggers:

- Mixed tabs/spaces
- Misaligned struct fields
- Wrong brace placement

### Import Grouping (goimports)

BAD:
```go
import (
    "fmt"
    "github.com/example/myapp/internal/config"
    "os"
    "net/http"
)
```

GOOD:
```go
import (
    "fmt"
    "net/http"
    "os"

    "github.com/example/myapp/internal/config"
)
```

Standard library imports first, then third-party/internal, separated by a blank line. `goimports` enforces this automatically.
