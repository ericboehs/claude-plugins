---
name: setup-agent-desktop
description: Install and configure the agent-desktop CLI for macOS accessibility automation, honoring Eric's aube supply-chain hardening. Use when asked to install agent-desktop, fix "Native binary not found", or "/setup-agent-desktop".
tools: Bash
---

# Setup agent-desktop CLI

Install the `agent-desktop` CLI (lahfir/agent-desktop) and grant permissions. Eric's environment has two supply-chain gates that block the normal install — this skill works through both.

## Step 1: Check if already installed

```bash
which agent-desktop && agent-desktop version && agent-desktop status
```

- If `version` prints JSON and `status` shows `accessibility: granted`, it's set up — suggest `/agent-desktop`.
- If "Native binary not found": the wrapper installed but the build step was skipped — go to Step 3 (approve build).
- If "command not found": install from scratch — Step 2.

## Step 2: Verify a trusted binary, then install via aube

`agent-desktop` (npm) is a thin JS wrapper; its `postinstall` downloads the platform binary from GitHub Releases (SHA-256 only, no Sigstore). We verify it ourselves first, then hand it to the postinstall so no unreviewed network fetch runs.

```bash
VER=$(gh release view --repo lahfir/agent-desktop --json tagName --jq '.tagName' | tr -d v)
mkdir -p /tmp/ad-trusted && cd /tmp/ad-trusted
gh release download "v$VER" --repo lahfir/agent-desktop \
  --pattern "agent-desktop-v$VER-aarch64-apple-darwin.tar.gz" --pattern checksums.txt --clobber
grep aarch64-apple-darwin checksums.txt | grep -v ffi > my.sum
shasum -a 256 -c my.sum                                            # must say OK
gh attestation verify "agent-desktop-v$VER-aarch64-apple-darwin.tar.gz" --repo lahfir/agent-desktop  # Sigstore
tar -xzf "agent-desktop-v$VER-aarch64-apple-darwin.tar.gz" && chmod +x agent-desktop
```

Install globally with aube (Eric's Node package manager). Two gates fire:
- **Low-download guard** (`ERR_AUBE_LOW_DOWNLOAD_PACKAGE`, ~800/wk < 1000) → `--allow-low-downloads`.
- **Build-script skip** → `approve-builds` + `rebuild` below.

```bash
export AGENT_DESKTOP_BINARY_PATH=/tmp/ad-trusted/agent-desktop
aube add -g agent-desktop --allow-low-downloads
```

## Step 3: Approve and run the build script

```bash
export AGENT_DESKTOP_BINARY_PATH=/tmp/ad-trusted/agent-desktop   # set if a new shell
aube approve-builds -g agent-desktop                              # name the pkg to skip the picker
# approve-builds prints the global dir, e.g. ~/.local/share/aube/global-aube/<hash>
aube -C <global-dir> rebuild                                      # runs postinstall; copies our binary, no download
hash -r
```

The postinstall honors `AGENT_DESKTOP_BINARY_PATH` (copy local binary) and `AGENT_DESKTOP_SKIP_DOWNLOAD=1`. The bin links into `~/.local/share/aube/agent-desktop` (on PATH).

## Step 4: Grant permissions

macOS requires Accessibility permission for the terminal that launches agent-desktop; Screen Recording too for screenshots. They usually inherit from the terminal app.

```bash
agent-desktop permissions            # check state
agent-desktop permissions --request  # trigger the OS request path if denied
```

If denied, add the terminal app under **System Settings → Privacy & Security → Accessibility** (and **Screen Recording**), then re-check.

## Step 5: Verify end to end

```bash
agent-desktop launch Finder
agent-desktop snapshot --app Finder -i --compact   # should return refs, not an error
```

If this returns a tree with refs, it's working — suggest `/agent-desktop`. Clean up: `rm -rf /tmp/ad-trusted`.

## Upgrading

The npm/aube package only ships the wrapper, so each upgrade repeats the approve-builds/rebuild dance. Bump with `aube up -g agent-desktop --allow-low-downloads` then redo Steps 2–3 for the new version, or skip the package entirely and drop the verified release binary straight into `~/.local/bin`.
