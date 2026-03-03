# Semgrep Patterns

Fix guidance for common Semgrep SAST findings. Use these BAD/GOOD patterns to fix security issues correctly the first time.

## Hardcoded Secrets

Credentials, API keys, or tokens embedded directly in source code. Move them to environment variables or a secrets manager.

BAD:
```python
API_KEY = "sk-abc123secretkey"
db_password = "hunter2"
```

GOOD:
```python
API_KEY = os.environ["API_KEY"]
db_password = os.environ["DB_PASSWORD"]
```

## SQL Injection

Unparameterized user input in SQL queries. Always use parameterized queries or prepared statements.

BAD:
```python
cursor.execute(f"SELECT * FROM users WHERE name = '{user_input}'")
```

GOOD:
```python
cursor.execute("SELECT * FROM users WHERE name = %s", (user_input,))
```

BAD:
```ruby
User.where("name = '#{params[:name]}'")
```

GOOD:
```ruby
User.where(name: params[:name])
```

## Command Injection

User input passed to shell commands. Use parameterized APIs or escape/validate input.

BAD:
```python
os.system(f"ping {user_input}")
subprocess.call(f"convert {filename}", shell=True)
```

GOOD:
```python
subprocess.run(["ping", user_input], check=True)
subprocess.run(["convert", filename], check=True)
```

BAD:
```ruby
system("ping #{params[:host]}")
`ls #{user_input}`
```

GOOD:
```ruby
system("ping", params[:host])
```

## Insecure Deserialization

Deserializing untrusted data can execute arbitrary code. Use safe loaders or allowlists.

BAD (Python):
```
data = pickle.loads(user_data)      # unsafe deserializer
obj = yaml.load(user_input)         # unsafe yaml loader
```

GOOD:
```python
data = json.loads(user_data)
obj = yaml.safe_load(user_input)
```

BAD (Ruby):
```
Marshal.load(user_data)             # unsafe deserializer
YAML.load(user_input)               # unsafe yaml loader
```

GOOD:
```ruby
JSON.parse(user_data)
YAML.safe_load(user_input)
```

## SSRF (Server-Side Request Forgery)

User-controlled URLs in server-side requests can access internal services. Validate and restrict target URLs.

BAD:
```python
response = requests.get(user_url)
```

GOOD:
```python
parsed = urllib.parse.urlparse(user_url)
if parsed.hostname not in ALLOWED_HOSTS:
    raise ValueError("Disallowed host")
response = requests.get(user_url)
```

## Path Traversal

User input in file paths can access arbitrary files. Validate paths stay within the expected directory.

BAD:
```python
with open(f"/uploads/{filename}") as f:
    return f.read()
```

GOOD:
```python
safe_path = os.path.realpath(os.path.join("/uploads", filename))
if not safe_path.startswith("/uploads/"):
    raise ValueError("Path traversal detected")
with open(safe_path) as f:
    return f.read()
```

BAD:
```javascript
const data = fs.readFileSync(path.join(uploadDir, userFile));
```

GOOD:
```javascript
const safePath = path.resolve(uploadDir, userFile);
if (!safePath.startsWith(path.resolve(uploadDir))) {
  throw new Error("Path traversal detected");
}
const data = fs.readFileSync(safePath);
```

## Open Redirect

User-controlled redirect targets can send users to malicious sites. Validate redirect URLs against an allowlist.

BAD:
```python
return redirect(request.args.get("next"))
```

GOOD:
```python
next_url = request.args.get("next", "/")
if not is_safe_url(next_url):
    next_url = "/"
return redirect(next_url)
```

## Weak Cryptography

Using broken or weak cryptographic algorithms. Use modern, vetted alternatives.

BAD:
```python
hashlib.md5(password.encode()).hexdigest()
hashlib.sha1(data).hexdigest()
```

GOOD:
```python
import bcrypt
bcrypt.hashpw(password.encode(), bcrypt.gensalt())
hashlib.sha256(data).hexdigest()
```
