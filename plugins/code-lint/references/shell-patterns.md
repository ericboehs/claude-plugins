# Shell Linter Patterns

Fix guidance for common ShellCheck issues. Use these BAD/GOOD patterns to fix lint errors correctly the first time.

## SC2086 — Double-Quote to Prevent Word Splitting

Unquoted variables are split on whitespace and glob-expanded by the shell. Always double-quote variable references unless word splitting is explicitly desired.

BAD: `cp $source $dest` / `rm $file`
GOOD: `cp "$source" "$dest"` / `rm "$file"`

## SC2046 — Quote Command Substitution

Command substitution output is word-split and glob-expanded. Quote it the same as any variable.

BAD: `chown $(id -u) file`
GOOD: `chown "$(id -u)" file`

Exception: when you intentionally need word splitting (e.g., passing a word list), add a comment: `# shellcheck disable=SC2046`.

## SC2006 — Use $() Instead of Backticks

Backtick syntax is legacy, does not nest cleanly, and is harder to read. Use `$()` for all command substitution.

BAD:
```bash
result=`grep -c "pattern" file`
```

GOOD:
```bash
result=$(grep -c "pattern" file)
```

## SC2034 — Unused Variable

A variable is assigned but never referenced. Either remove the assignment or use the variable. If it exists for documentation purposes only, prefix with `_` to signal intentional non-use.

BAD: `output=$(compute)` (never referenced again)
GOOD: Remove the assignment, or: `_output=$(compute)` if the side-effect is the goal.

## SC2155 — Declare and Assign Separately

Combining `declare`/`local`/`export` with a command substitution assignment hides the exit status of the command — the declare always succeeds even if the substitution fails.

BAD:
```bash
local result=$(some_command)
```

GOOD:
```bash
local result
result=$(some_command)
```

## SC2164 — Use cd ... || exit

If `cd` fails and the script continues, subsequent commands run in the wrong directory. Always handle failure.

BAD:
```bash
cd /some/path
rm -rf build/
```

GOOD:
```bash
cd /some/path || exit 1
rm -rf build/
```

Alternative: use a subshell so the `cd` scope is contained.

```bash
(cd /some/path && rm -rf build/)
```

## SC2068 — Double-Quote Array Expansion

When expanding an array to pass as arguments, use `"${array[@]}"`. Without quotes, elements with spaces are split.

BAD:
```bash
files=(one "two three" four)
rm ${files[@]}
```

GOOD:
```bash
files=(one "two three" four)
rm "${files[@]}"
```

## SC2129 — Group Redirections

When multiple consecutive commands redirect to the same file, use a `{ ...; }` group with a single redirection instead of repeating it.

BAD:
```bash
echo "Header" >> report.txt
date >> report.txt
echo "Footer" >> report.txt
```

GOOD:
```bash
{
  echo "Header"
  date
  echo "Footer"
} >> report.txt
```
