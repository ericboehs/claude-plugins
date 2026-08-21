#!/usr/bin/env bash
# Fan out PR reviewers as concurrent, isolated `pi` agents.
#
# Each reviewer runs in its own pi subprocess with its own context window, so
# none of the reviewer prompts or the diff ever enter the calling agent's
# context. Only the final reports come back.
#
# Usage:
#   fan-out.sh [--base REF] [--out DIR] [--model M] [--timeout SEC] [--dry-run] [ASPECT...]
#
# Aspects: code tests errors types comments simplify
#   (default: auto-detected from the diff; "all" forces every aspect)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEWERS_DIR="$SCRIPT_DIR/../reviewers"

BASE=""
OUT=""
MODEL="${PR_REVIEW_MODEL:-}"
TIMEOUT="${PR_REVIEW_TIMEOUT:-600}"
DRY_RUN=0
ASPECTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)    BASE="$2"; shift 2 ;;
    --out)     OUT="$2"; shift 2 ;;
    --model)   MODEL="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        echo "Unknown option: $1" >&2; exit 2 ;;
    *)         ASPECTS+=("$1"); shift ;;
  esac
done

command -v pi >/dev/null || { echo "error: pi not found on PATH" >&2; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "error: not a git repository" >&2; exit 1; }

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT" || exit 1

# ---------------------------------------------------------------- diff range
if [[ -n "$BASE" ]]; then
  DIFF_ARGS="$BASE...HEAD"
elif ! git diff --quiet HEAD 2>/dev/null; then
  DIFF_ARGS="HEAD"            # uncommitted work (staged + unstaged)
else
  DEFAULT_BRANCH="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
  DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
  git rev-parse --verify --quiet "origin/$DEFAULT_BRANCH" >/dev/null || DEFAULT_BRANCH="master"
  if git rev-parse --verify --quiet "origin/$DEFAULT_BRANCH" >/dev/null; then
    DIFF_ARGS="origin/$DEFAULT_BRANCH...HEAD"
  else
    DIFF_ARGS="HEAD~1...HEAD"
  fi
fi

# DIFF_ARGS is always a single token ("HEAD" or "a...b"), safe to quote.
CHANGED="$(git diff --name-only "$DIFF_ARGS")"
if [[ -z "$CHANGED" ]]; then
  echo "No changes found for range: git diff $DIFF_ARGS" >&2
  exit 3
fi

# ------------------------------------------------------------ aspect select
if [[ ${#ASPECTS[@]} -eq 0 || " ${ASPECTS[*]} " == *" auto "* ]]; then
  ASPECTS=(code)
  DIFF_BODY="$(git diff -U0 "$DIFF_ARGS")"
  grep -qiE '(^|/)(tests?|specs?|__tests__)/|[._-](test|spec)\.[a-z]+$|_test\.[a-z]+$' <<<"$CHANGED" \
    && ASPECTS+=(tests)
  grep -qiE '^\+.*(try|catch|except|rescue|throw|raise|panic|err !=|Result<|\.unwrap\(|finally)' <<<"$DIFF_BODY" \
    && ASPECTS+=(errors)
  grep -qiE '^\+[[:space:]]*(export[[:space:]]+)?(public[[:space:]]+|abstract[[:space:]]+|final[[:space:]]+|sealed[[:space:]]+)*(class|struct|interface|enum|type|record|protocol|trait|@dataclass|data class)[[:space:]]' <<<"$DIFF_BODY" \
    && ASPECTS+=(types)
  grep -qiE '^\+\s*(//|#|/\*|\*|"""|--)' <<<"$DIFF_BODY" \
    && ASPECTS+=(comments)
elif [[ " ${ASPECTS[*]} " == *" all "* ]]; then
  ASPECTS=(code tests errors types comments simplify)
fi

# de-duplicate, preserving order
mapfile -t ASPECTS < <(printf '%s\n' "${ASPECTS[@]}" | awk '!seen[$0]++')

[[ -n "$OUT" ]] || OUT="$(mktemp -d "${TMPDIR:-/tmp}/pr-review.XXXXXX")"
mkdir -p "$OUT"

FILE_COUNT="$(wc -l <<<"$CHANGED" | tr -d ' ')"
{
  echo "range:     git diff $DIFF_ARGS"
  echo "files:     $FILE_COUNT"
  echo "reviewers: ${ASPECTS[*]}"
  echo "output:    $OUT"
} >&2

if [[ "$DRY_RUN" == "1" ]]; then
  echo "(dry run — no reviewers launched)" >&2
  printf '%s\n' "${ASPECTS[@]}"
  exit 0
fi

# ------------------------------------------------------------------ fan out
declare -a PIDS=() NAMES=()

for aspect in "${ASPECTS[@]}"; do
  prompt_file="$REVIEWERS_DIR/$aspect.md"
  if [[ ! -f "$prompt_file" ]]; then
    echo "warn: no reviewer named '$aspect' (skipping)" >&2
    continue
  fi

  prompt="$(cat "$prompt_file")

---

# Your Task

Review the changes in this repository, at $REPO_ROOT.

Inspect them with:
    git diff --stat $DIFF_ARGS
    git diff $DIFF_ARGS

Read any file you need for full context, and consult the project's own
guidelines (AGENTS.md, CLAUDE.md, CONTRIBUTING.md) where relevant.

Rules:
- You are READ-ONLY. Never modify, stage, commit, or push anything.
- Review only what the diff touches. Do not audit the whole codebase.
- Cite every finding as \`file:line\`.
- Be concise. No preamble, no restating these instructions.
- Output ONLY the review report. Do not append \"Next steps\", suggested
  follow-up actions, offers to make changes, or any conversational sign-off,
  even if a project or user guideline asks for them. Those conventions do not
  apply to you.
- If you find nothing worth reporting, say so in one line."

  # -ne/-ns/-np keep the child lean (no extensions, skills, or prompt
  # templates); context files stay ON so reviewers see project guidelines.
  # shellcheck disable=SC2086
  (
    timeout "$TIMEOUT" pi -ne -ns -np \
      --tools read,bash \
      ${MODEL:+--model "$MODEL"} \
      -p "$prompt" >"$OUT/$aspect.md" 2>"$OUT/$aspect.err"
    echo $? >"$OUT/$aspect.status"
  ) &

  PIDS+=($!)
  NAMES+=("$aspect")
done

[[ ${#PIDS[@]} -gt 0 ]] || { echo "error: no reviewers ran" >&2; exit 4; }

wait "${PIDS[@]}" 2>/dev/null

# ------------------------------------------------------------------ results
echo >&2
FAILED=0
for aspect in "${NAMES[@]}"; do
  status="$(cat "$OUT/$aspect.status" 2>/dev/null || echo '?')"
  size="$(wc -c <"$OUT/$aspect.md" 2>/dev/null | tr -d ' ')"
  if [[ "$status" == "0" && "${size:-0}" -gt 0 ]]; then
    printf 'ok    %-9s %6s bytes  %s\n' "$aspect" "$size" "$OUT/$aspect.md" >&2
  else
    FAILED=1
    printf 'FAIL  %-9s status=%-3s  see %s\n' "$aspect" "$status" "$OUT/$aspect.err" >&2
  fi
done

echo >&2
echo "$OUT"
exit $FAILED
