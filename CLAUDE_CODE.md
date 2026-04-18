# Claude Code — Setup and Workflow Guide
> For researchers and students using tmux + Neovim on Linux/macOS and HPC clusters

---

## What is Claude Code?

Claude Code is Anthropic's AI coding assistant that runs in your terminal. Unlike
browser-based AI tools, it has direct read/write access to your project files — it
can open files, edit them, run shell commands, check git status, and iterate on
errors without you relaying anything back and forth.

The interaction is plain English conversation, not code syntax. You describe what
you want, Claude acts on it, you review the result.

**Claude Code vs claude.ai (browser):**

| Task | Better in |
|------|-----------|
| Edit files, fix errors, refactor code | Claude Code (terminal) |
| Run analysis pipelines end to end | Claude Code (terminal) |
| Conceptual discussions, curriculum design | claude.ai (browser) |
| Interactive visualizations and widgets | claude.ai (browser) |

---

## Requirements

- A paid Anthropic account — Claude Pro ($20/month) or API access via
  `console.anthropic.com` (pay per token, no monthly fee). The free
  Claude.ai plan does not include Claude Code.
- git installed and configured
- tmux and Neovim (for the workflow described here)

---

## Installation

```bash
# Native installer — no dependencies, auto-updates in background
curl -fsSL https://claude.ai/install.sh | bash

# Verify
claude --version

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

After install, run `claude` in any directory and follow the browser prompt
to authenticate. Credentials are stored securely — you only do this once.

---

## Project Setup

Every Claude Code project lives in a git repo. The `CLAUDE.md` file at the
repo root is Claude's project memory — it reads this at the start of every
session so you don't have to re-explain your setup each time.

```bash
# Create a new project
mkdir ~/projects/my-project && cd ~/projects/my-project
git init
git add .
git commit -m "initial"

# Start Claude Code
claude

# Inside Claude Code — generate a CLAUDE.md for this project
/init
```

`/init` reads your repo structure and drafts a `CLAUDE.md`. Edit it to add
project-specific conventions, known issues, and dataset quirks.

### Two levels of CLAUDE.md

| File | Scope | Use for |
|------|-------|---------|
| `~/.claude/CLAUDE.md` | Global — every session | Editor setup, coding style, personal preferences |
| `project/CLAUDE.md` | Project-specific | Known bugs, dataset quirks, file structure |

### CLAUDE.md template

```markdown
## Project
Brief description of what this project is.

## Environment
- Editor: Neovim (tmux pane setup)
- Cluster: SLURM scheduler, module system
- Rendering: Quarto (if applicable)

## File Structure
- analysis.qmd        — main document (calls functions from R/)
- R/functions.R       — helper functions
- CLAUDE.md           — this file

## Coding Conventions
- Functions go in R/ scripts; qmd files stay slim with narrative text
- Use tidyverse style where applicable
- Comment functions with roxygen2-style headers

## File Editing Restrictions
- Do NOT modify README*.md files unless explicitly asked
- Do NOT modify CLAUDE.md unless explicitly asked
- Only edit files directly relevant to the current task
- Always state which files you intend to modify before doing so
- When in doubt about scope, ask rather than assuming
```

The file editing restrictions section is important — without it Claude may
"helpfully" update documentation files it finds in the repo when you only
asked it to change a script.

---

## tmux + Neovim Workflow

Run Claude Code in one tmux pane and Neovim in another. They work on the
same files simultaneously — no copying or syncing needed.

```
┌─────────────────────┬─────────────────────┐
│                     │                     │
│   Claude Code       │   Neovim + R/bash   │
│   (claude)          │                     │
│                     │                     │
└─────────────────────┴─────────────────────┘
```

```bash
tmux new -s work          # new session (or: tmux a to reattach)
Ctrl-b |                  # vertical split
Ctrl-b -                  # horizontal split
Ctrl-b arrow              # navigate between panes
```

---

## End-to-End Workflow

The complete loop for a Claude Code session with diff review.

### 1. Set a baseline commit before starting

```bash
git add -A
git commit -m "before: describe what you're about to do"
```

This is the most important habit. It makes `HEAD~1` meaningful and ensures
you can always roll back cleanly if Claude does something unexpected.

### 2. Start Claude Code and give your instruction

```bash
cd ~/projects/my-project
claude
```

Give instructions in plain English:
```
"Read analysis.qmd. Extract the R code chunks into well-documented
functions in R/functions.R. Replace inline chunks in the qmd with
calls to those functions. Commit after each function you complete."
```

The "commit after each function" instruction keeps diffs small — each
review then covers exactly one logical change.

You can also ask interpretive questions mid-session, not just give
execution commands:
- *"This AUC value is 1.0 — does that look right or is something wrong?"*
- *"Which features are most important here — does that make biological sense?"*
- *"Which approach would you recommend for a teaching example and why?"*

### 3. Review changes with fugitive + Neovim diff mode

After Claude commits a change, switch to the Neovim pane:

```bash
# Overview of all files changed
git diff --stat HEAD~1
```

Then open the file and review:
```
:Gvdiffsplit HEAD~1     side-by-side diff vs previous commit
]c                      jump to next change
[c                      jump to previous change
do                      revert this hunk (restores old version)
:diffoff                exit diff mode
:w                      save (keeps all hunks you didn't revert)
```

**Accepting vs reverting:**
- Hunk you want to **keep** → do nothing, move on with `]c`
- Hunk you want to **revert** → `do` restores the old version
- Anything not touched with `do` is accepted when you `:w`

**When Claude changed multiple files:**

Claude lists every modified file in the terminal as it works. After the
session, use `git diff --stat HEAD~1` for a summary, then review each file:

```bash
nvim file1.R file2.qmd    # open multiple files
:Gvdiffsplit HEAD~1        # review first file
:diffoff | :w
:n                         # switch to next file
:Gvdiffsplit HEAD~1        # review
:diffoff | :w
```

### 4. Commit what you're happy with

```bash
git add -A
git commit -m "add: descriptive message of what changed"
```

To undo everything Claude did and return to baseline:
```bash
git reset --hard HEAD~1    # destructive — use with caution
```

### Full session rhythm

```
BASH PANE                   CLAUDE PANE                  NEOVIM PANE
──────────────────────────────────────────────────────────────────────
cd ~/projects/my-project
git add -A
git commit "before: ..."
                            cd ~/projects/my-project
                            claude
                            "do X, commit when done"
                            [works, commits]
                                                          git diff --stat HEAD~1
                                                          :Gvdiffsplit HEAD~1
                                                          ]c ]c ]c   (happy)
                                                          :diffoff | :w
git add -A
git commit "add: X"
                            "now do Y, commit when done"
                            [works, commits]
                                                          :Gvdiffsplit HEAD~1
                                                          ]c → do   (revert one)
                                                          :diffoff | :w
git add -A
git commit "add: Y"
```

---

## Git Workflow: File States

```
Working tree               Index (staging)          Repository (commits)
(files on disk)            (git add puts here)      (git commit saves here)

functions.R  →  git add  →  staged copy  →  git commit  →  HEAD, HEAD~1...
     ↑
Claude Code edits here directly
```

### Key commands

```bash
git diff                      # working tree vs last commit
git diff --stat HEAD~1        # summary of files changed in last commit
git add -A                    # stage all changes
git commit -m "message"       # commit staged changes
git checkout -- file.R        # discard all changes to one file
git reset HEAD~1              # uncommit but keep files (safe)
git reset --hard HEAD~1       # uncommit and discard changes (destructive)
```

### Fugitive commands (inside Neovim)

```
:Git status                   interactive status (- to stage/unstage)
:Git commit                   commit buffer (ZZ to save and close)
:Gvdiffsplit HEAD~1           side-by-side diff vs previous commit
```

---

## Session Commands

| Action | Command |
|--------|---------|
| Start session | `claude` (from project directory) |
| Generate CLAUDE.md | `/init` |
| Plan before acting | `/plan` |
| Clear context | `/clear` |
| Exit | `/exit` or `Ctrl+d` |
| Resume last session | `claude --continue` |
| Pick from past sessions | `claude --resume` |
| Run single task non-interactively | `claude -p "your prompt"` |

**Plan mode** (`/plan`) is useful when starting a large task — Claude
describes what it intends to do and waits for your approval before
touching any files.

**Context hygiene:** use `/clear` when starting a new task within a
session. Context fills faster than expected — don't carry unrelated
history from one task into the next.

**CLAUDE.md is read at session start only.** If you edit it mid-session,
either ask Claude to re-read it explicitly or start a fresh session.

---

## Sending Code Context from Neovim to Claude

When working in a specific file or function and you want Claude's input
without switching away from your code:

**Send a visual selection directly to the Claude terminal:**
```
V                          enter visual line mode
j j j                      select lines
:ClaudeCodeSend            send to Claude pane
```

**Reference file and line range from the Claude pane:**
```
"Look at functions.R lines 42-63 and add error handling to the
 cross-validation loop"
```

Claude Code always has full file access — you don't need to paste code
into the Claude pane. Referencing by line number is enough.

---

## RStudio Users

Claude Code works alongside RStudio without any plugin. Open a terminal
tab within your RStudio session and run `claude` there. Claude edits
files on disk; RStudio reloads and runs them. No extra setup needed.

For tighter integration, the `ClaudeR` R package connects RStudio
directly to Claude Code via MCP, allowing Claude to execute R code in
your active session and see results including plots in real time.

---

## HPC Cluster Setup (UCR)

### Installation

Same one-line install on any login node — no sysadmin involvement needed:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

All login and compute nodes have outbound internet access, so no
firewall configuration is required.

### Redirect ~/.claude/ to bigdata (recommended)

Home directory quotas are limited. Redirect Claude's cache to bigdata:

```bash
# Personal lab space
mv ~/.claude /bigdata/grpLABNAME/USERNAME/.claude
ln -s /bigdata/grpLABNAME/USERNAME/.claude ~/.claude

# Course space (each student gets their own subdirectory)
mkdir -p /bigdata/COURSENAME/students/USERNAME/.claude
ln -s /bigdata/COURSENAME/students/USERNAME/.claude ~/.claude
```

Do this before the first `claude` run. Claude Code follows the symlink
transparently.

**Security:** `~/.claude/` contains auth tokens. Set permissions to 700:
```bash
chmod 700 ~/.claude
```

### HPC Cluster additions for project CLAUDE.md

```markdown
## HPC Cluster
- Scheduler: SLURM
- Submit heavy jobs via sbatch — do not run on login nodes
- Module system: run `module load R` before R sessions
- Bigdata path: /bigdata/grpLABNAME/
```

### For sysadmins

Claude Code installs entirely within user home directories (`~/.local/bin/`).
No root access, shared credentials, or system-wide configuration is needed.

The only infrastructure requirement is outbound HTTPS to `api.anthropic.com`
from login and compute nodes — already available on UCR HPC cluster.

Each user authenticates with their own Anthropic account. There are no
shared API keys or license files to manage.

---

## What Stays Better in claude.ai (Browser)

Use the browser interface for tasks where conversation and rendered output
matter more than file editing:

- Conceptual discussions and algorithm comparisons
- Curriculum and document planning
- Interactive visualizations and widgets
- Slide outlines and long-form writing

Claude Code wins for everything that involves editing files, running code,
fixing errors, and iterating on analysis pipelines.
