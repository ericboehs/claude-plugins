# Ruby Linter Patterns

Fix guidance for common Ruby linter issues (Reek + RuboCop). Use these BAD/GOOD patterns to fix lint errors correctly the first time.

## Reek Smells

### FeatureEnvy

When a method accesses multiple attributes of another object, it has "Feature Envy" — it wants to be on that object instead. Extract the accessed attributes into local variables or move the logic.

BAD:
```ruby
def format_address
  "#{user.street}, #{user.city}, #{user.state} #{user.zip}"
end
```

GOOD:
```ruby
def format_address
  street, city, state, zip = user.values_at(:street, :city, :state, :zip)
  "#{street}, #{city}, #{state} #{zip}"
end
```

Alternative: Use destructuring or move the method onto the data object.

### TooManyStatements

Keep methods under 10 statements (project threshold). Extract logical groups into private helper methods.

BAD:
```ruby
def process
  validate_input
  data = fetch_data
  transformed = transform(data)
  filtered = filter(transformed)
  sorted = sort(filtered)
  formatted = format(sorted)
  cache_result(formatted)
  log_completion
  notify_subscribers
  formatted
end
```

GOOD:
```ruby
def process
  validate_input
  result = fetch_and_transform
  finalize(result)
end

private

def fetch_and_transform
  data = fetch_data
  transform(data).then { filter(_1) }.then { sort(_1) }
end

def finalize(result)
  formatted = format(result)
  cache_result(formatted)
  log_completion
  notify_subscribers
  formatted
end
```

### DuplicateMethodCall

When the same method is called multiple times with the same receiver, extract it into a local variable.

BAD:
```ruby
if config.enabled?
  process(config.timeout, config.retries)
  log("Config: #{config.timeout}s, #{config.retries} retries")
end
```

GOOD:
```ruby
if config.enabled?
  timeout = config.timeout
  retries = config.retries
  process(timeout, retries)
  log("Config: #{timeout}s, #{retries} retries")
end
```

### ControlParameter

Don't use method parameters as boolean flags to control flow. Use separate methods, predicates, or hash dispatch.

BAD:
```ruby
def render(format)
  if format == :json
    render_json
  elsif format == :xml
    render_xml
  else
    render_html
  end
end
```

GOOD:
```ruby
RENDERERS = {
  json: ->(data) { render_json(data) },
  xml: ->(data) { render_xml(data) },
  html: ->(data) { render_html(data) }
}.freeze

def render(format)
  RENDERERS.fetch(format, RENDERERS[:html]).call(data)
end
```

### DataClump

When the same group of parameters travels together across methods, bundle them into a Struct or Data.define.

BAD:
```ruby
def connect(host, port, timeout)
  socket = open(host, port)
  configure(host, port, timeout)
end
```

GOOD:
```ruby
ConnectionConfig = Data.define(:host, :port, :timeout)

def connect(config)
  socket = open(config.host, config.port)
  configure(config)
end
```

### UncommunicativeVariableName

Use descriptive variable names. Avoid single-letter names except for well-known conventions (i, j for indices, e for exceptions, _ for unused).

BAD: `d = fetch_data` / `r = process(d)` / `x = transform(r)`
GOOD: `data = fetch_data` / `result = process(data)` / `output = transform(result)`

### InstanceVariableAssumption

Don't assume instance variables are set. Initialize them in the constructor or use lazy initialization.

BAD:
```ruby
def process
  @cache ||= {}
  @cache[key] = value
end
```

GOOD:
```ruby
def initialize
  @cache = {}
end

def process
  @cache[key] = value
end
```

### NilCheck

Avoid explicit nil checks. Use safe navigation (`&.`), `fetch`, or null objects instead.

BAD:
```ruby
def full_name
  if user.nil?
    "Unknown"
  else
    "#{user.first_name} #{user.last_name}"
  end
end
```

GOOD:
```ruby
def full_name
  return "Unknown" unless user

  "#{user.first_name} #{user.last_name}"
end
```

## RuboCop Cops

### Metrics/MethodLength

Keep methods short. Default max is 10 lines. Extract helper methods for logical groups of statements. Count lines proactively when writing a method.

### Layout/MultilineMethodCallBraceLayout

When a method call spans multiple lines, the closing brace must be on its own line.

BAD:
```ruby
result = method_call(
  arg1,
  arg2)
```

GOOD:
```ruby
result = method_call(
  arg1,
  arg2
)
```

### Style/GuardClause

Use guard clauses for early returns instead of wrapping the body in a conditional.

BAD:
```ruby
def process
  if valid?
    # many lines of code
  end
end
```

GOOD:
```ruby
def process
  return unless valid?

  # many lines of code
end
```

### Naming/MethodParameterName

Method parameter names should be at least 3 characters. Use descriptive names.

BAD: `def process(x, y)` / `def connect(to)`
GOOD: `def process(input, output)` / `def connect(target)`

### Metrics/AbcSize

ABC size measures Assignments, Branches, and Conditions. Reduce by:
- Extracting conditionals into predicate methods
- Extracting assignments into helper methods
- Reducing branching with guard clauses or early returns

### Metrics/CyclomaticComplexity

Reduce branching in methods. Each `if`, `unless`, `when`, `&&`, `||` adds complexity. Extract branches into separate methods or use polymorphism/hash dispatch.

### Style/StringLiterals

Use the project's configured string literal style consistently (single or double quotes).

### Layout/LineLength

Keep lines under the configured max (usually 120 or 80 chars). Break long lines at logical points.

BAD:
```ruby
result = SomeService.new(param1: value1, param2: value2, param3: value3, param4: value4).call
```

GOOD:
```ruby
result = SomeService.new(
  param1: value1,
  param2: value2,
  param3: value3,
  param4: value4
).call
```
