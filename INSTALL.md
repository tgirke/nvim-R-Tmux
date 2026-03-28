# Nvim-R-Tmux Installation Guide

Step-by-step guide to setting up a terminal-based R, Python, and Bash
development environment using Neovim + R.nvim + hlterm + Tmux.

Each step is independent and verifiable before moving to the next.

**Platforms covered:** HPC clusters (Linux), personal Linux, macOS,
Windows (MobaXterm/WSL), ChromeOS (Crostini/Debian)

---

## Source documentation and author credits

This guide is derived from the following upstream sources.
When things break after an update, consult these first:

| Component | Author(s) | Repository / Docs |
|---|---|---|
| Neovim | Neovim contributors | https://github.com/neovim/neovim |
| Neovim install guide | Neovim contributors | https://github.com/neovim/neovim/blob/master/INSTALL.md |
| Neovim releases (current glibc) | Neovim contributors | https://github.com/neovim/neovim/releases |
| Neovim releases (older glibc) | Neovim contributors | https://github.com/neovim/neovim-releases/releases |
| lazy.nvim | Folke Viegas | https://github.com/folke/lazy.nvim |
| R.nvim | Jakson Alves de Aquino & contributors | https://github.com/R-nvim/R.nvim |
| R.nvim documentation | Jakson Alves de Aquino & contributors | https://github.com/R-nvim/R.nvim/blob/main/doc/R.nvim.txt |
| R.nvim wiki | R-nvim contributors | https://github.com/R-nvim/R.nvim/wiki |
| hlterm (replaces vimcmdline) | Jakson Alves de Aquino | https://github.com/jalvesaq/hlterm |
| nvim-treesitter | nvim-treesitter contributors | https://github.com/nvim-treesitter/nvim-treesitter |
| neo-tree.nvim | Michael Sloan & contributors | https://github.com/nvim-neo-tree/neo-tree.nvim |
| indent-blankline.nvim | Lukas Reineke | https://github.com/lukas-reineke/indent-blankline.nvim |
| kanagawa.nvim | rebelot | https://github.com/rebelot/kanagawa.nvim |
| colorout (R package) | Jakson Alves de Aquino | https://github.com/jalvesaq/colorout |
| Tmux | Nicholas Marriott & contributors | https://github.com/tmux/tmux |
| Tmux manual | Tmux contributors | https://man.openbsd.org/tmux |

**Prior art this guide builds on:**

- Original Nvim-R-Tmux tutorial by Thomas Girke:
  https://github.com/tgirke/Nvim-R_Tmux
- GEN242 course Linux/HPC tutorial (UCR):
  https://girke.bioinformatics.ucr.edu/GEN242/tutorials/linux/linux/
- UCR HPCC terminal IDE manual:
  https://hpcc.ucr.edu/manuals/hpc_cluster/terminalide/

---

## Overview

| Component | Purpose | Required |
|---|---|---|
| Neovim >= 0.10 | The editor | Yes |
| R | R interpreter | Yes for R work |
| lazy.nvim | Plugin manager (auto-installs) | Yes |
| R.nvim | R integration in Neovim | Yes for R work |
| nvim-treesitter | Syntax parsing (required by R.nvim) | Yes |
| hlterm | Python/Bash REPL integration | Yes for Python/Bash |
| Tmux >= 3.4 | Persistent terminal sessions | Recommended on HPC |
| neo-tree | File browser | Optional |
| indent-blankline | Indentation guides | Optional |
| kanagawa.nvim | Color scheme | Optional |

---

## Clipboard behavior by platform

Clipboard integration works differently per platform. This is handled
automatically in the provided `init.lua`:

| Platform | Clipboard method | Mouse default |
|---|---|---|
| HPC via MobaXterm (Windows) | xclip via X11 (auto) | ON |
| macOS iTerm2 → HPC SSH | OSC 52 (built into Neovim 0.10+) | ON |
| Linux desktop | xclip / unnamedplus | ON |
| ChromeOS Crostini | Terminal Ctrl-Shift-C/V | OFF |

On ChromeOS, mouse is disabled by default in `init.lua` because
the Crostini X11 clipboard bridge is unreliable. Use `Space-m` to
toggle mouse on if needed, and use `Ctrl-Shift-C/V` for copy/paste.

For clipboard over SSH on macOS and Linux (without X11):
install the provided `clip` script which uses OSC 52 — see Step 6.

---

## Step 1: Install Neovim (>= 0.10 required)

**Upstream:** https://github.com/neovim/neovim/blob/master/INSTALL.md

```bash
nvim --version   # check existing version, need >= 0.10
```

### HPC Cluster
```bash
module avail neovim
module load neovim      # verify it's >= 0.10
echo 'module load neovim' >> ~/.bashrc
```
If only an old version is available, use the Linux tarball method below
(no sudo needed — installs to your home directory).

### Linux / ChromeOS (Crostini) / WSL

**Important:** Use `neovim-releases` (not `neovim`) — it is compiled
against older glibc and works on Debian Bullseye, ChromeOS Crostini,
and any system that is not cutting-edge Ubuntu. The main `neovim`
releases require glibc 2.32+ and will fail on older systems.

- **neovim-releases** (recommended): https://github.com/neovim/neovim-releases/releases/latest
- **neovim** (newer glibc only): https://github.com/neovim/neovim/releases/latest

```bash
curl -LO https://github.com/neovim/neovim-releases/releases/latest/download/nvim-linux-x86_64.tar.gz
tar -C ~/.local -xzf nvim-linux-x86_64.tar.gz
echo 'export PATH="$HOME/.local/nvim-linux-x86_64/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
nvim --version   # verify >= 0.10
```

If you see `GLIBC_2.32 not found`, you used the wrong URL —
make sure it says `neovim-releases` not `neovim`.

### macOS
```bash
brew install neovim      # https://formulae.brew.sh/formula/neovim
nvim --version
```

### Windows (MobaXterm)
MobaXterm includes a built-in X server and SSH client. Neovim runs
on the remote HPC server, not on Windows. Follow the HPC Cluster
instructions above after connecting via MobaXterm.

For local use on Windows, install WSL (Ubuntu) from the Microsoft
Store and follow the Linux instructions inside WSL:
https://learn.microsoft.com/en-us/windows/wsl/install

---

## Step 2: Install Tmux (>= 3.4 required for full clipboard support)

**Upstream:** https://github.com/tmux/tmux

Tmux provides persistent sessions that survive SSH disconnects —
essential for HPC work. Version 3.4 is required for OSC 52
clipboard passthrough (`allow-passthrough` option).

```bash
tmux -V   # check existing version
```

### HPC Cluster
```bash
module avail tmux
module load tmux
echo 'module load tmux' >> ~/.bashrc
```
If the module version is below 3.4, install from source (see below).

### Linux / ChromeOS / WSL
The apt package is often too old. Build from source:
```bash
sudo apt install libevent-dev libncurses-dev build-essential bison
curl -LO https://github.com/tmux/tmux/releases/download/3.4/tmux-3.4.tar.gz
tar xzf tmux-3.4.tar.gz
cd tmux-3.4
./configure --prefix=$HOME/.local
make && make install
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
tmux -V   # verify 3.4
```

### macOS
```bash
brew install tmux
tmux -V
```

---

## Step 3: Install R

**Upstream:** https://cran.r-project.org

### HPC Cluster
```bash
module avail R
module load R
echo 'module load R' >> ~/.bashrc
```

### Linux / ChromeOS / WSL
```bash
sudo apt install r-base
# For a more recent version: https://cran.r-project.org/bin/linux/
```

### macOS
```bash
brew install r
# or .pkg installer: https://cran.r-project.org/bin/macosx/
```

---

## Step 4: Set up Neovim config

```bash
mkdir -p ~/.config/nvim
cp init.lua ~/.config/nvim/init.lua
```

The `init.lua` template bootstraps lazy.nvim automatically on first
launch and installs all plugins. No separate plugin manager install
step is needed.

---

## Step 5: Set up Tmux config

```bash
cp .tmux.conf ~/.tmux.conf
```

Start the default session:
```bash
tmux
```

This creates a session named "work" with five named windows:
`main`, `editor`, `shell`, `monitor`, `extra`. Switch between
them with `Ctrl-a 1` through `Ctrl-a 5` or `Ctrl-a n`/`Ctrl-a p`.

To reattach after disconnecting:
```bash
tmux a
```

To kill the session entirely from inside tmux:
```
Ctrl-a : kill-session
```

---

## Step 6: Install clip script (clipboard over SSH, optional)

The `clip` script enables clipboard copy over SSH via OSC 52,
without requiring X11 forwarding. This is the recommended clipboard
solution for macOS and Linux users connecting to HPC over SSH.

**Not needed for MobaXterm users** — MobaXterm's X11 server handles
clipboard automatically.

**Not needed on ChromeOS Crostini** — use Ctrl-Shift-C/V instead.

```bash
mkdir -p ~/.local/bin
cp clip ~/.local/bin/clip
chmod +x ~/.local/bin/clip
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Test it (outside tmux first, then inside):
```bash
echo "hello from clip" | clip
# then Ctrl-V in your local terminal or browser
```

---

## Step 7: First launch — let plugins install

This step requires internet access. On HPC, run on the **login node**.

```bash
nvim
```

Lazy.nvim will install all plugins on first launch. Wait for it to
finish, then run:
```
:Lazy sync
:qa
```

Reopen and verify:
```bash
nvim
```
```
:checkhealth r
:checkhealth provider
:checkhealth lazy
```

Expected results:
- `checkhealth r`: Neovim version OK, treesitter OK, gcc OK
- `checkhealth provider`: xclip found (Linux) or clipboard OK
- `checkhealth lazy`: lazy.nvim OK, luarocks warnings are safe to ignore

---

## Step 8: Verify R.nvim works

```bash
nvim test.R
```

```
:RMapsDesc          # should show R.nvim keybindings list
\rf                 # start R session
```

Type a line and press Enter in normal mode to send it to R.

---

## Step 9: Verify hlterm works (Python and Bash)

```bash
nvim test.py
```

Press `\s` to start Python. Press Enter to send the current line.

```bash
nvim test.sh
```

Press `\s` to start Bash. Press Enter to send the current line.

---

## Step 10: Optional — install colorout R package

colorout colorizes R's **console output** (numbers, warnings, errors)
in the R terminal pane inside Neovim. This is separate from
nvim-treesitter which colorizes the R **script file** in the editor.

**Author:** Jakson Alves de Aquino
**Repository:** https://github.com/jalvesaq/colorout

```r
install.packages("remotes")
remotes::install_github("jalvesaq/colorout")
```

---

## Updating plugins

```
:Lazy update          # update all plugins
:Lazy update R.nvim   # update one plugin
```

---

## Troubleshooting

### `:RMapsDesc` says "not an editor command"
R.nvim did not load. Check:
```
:Lazy       # is R.nvim listed with a filled circle ●?
:checkhealth r
```
Most common cause: nvim-treesitter not loaded before R.nvim.
Use the provided `init.lua` unmodified for first install.

### `\rf` types the letter `f` instead of starting R
localleader not set correctly. Verify:
```
:echo maplocalleader
```
Should return `\`. If empty, the leader setup isn't being read —
check for a Lua syntax error earlier in `init.lua`.

### `\s` does not start Python or Bash interpreter
hlterm is not loaded or the file type isn't recognized. Check:
```
:set filetype?        # should return 'python' or 'sh'
:Lazy                 # is hlterm listed?
```

### `Parser could not be created for language "r"`
treesitter R parser missing or loaded too late. Run:
```
:TSInstall r
:TSInstall rnoweb
```
Restart Neovim.

### nvim-treesitter `configs` module not found
Wrong branch was pulled. Fix:
```bash
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter
```
Then `:Lazy install`. The `init.lua` pins `branch = "master"` to
prevent this. See: https://github.com/nvim-treesitter/nvim-treesitter/issues/6552

### Plugins didn't install on first launch
Network issue. Run `:Lazy install`. On HPC, use the login node.

### Colors look wrong
Terminal needs 256-color support:
```bash
echo $TERM   # should be xterm-256color or similar
```
Add to `~/.bashrc`: `export TERM=xterm-256color`

### `allow-passthrough` invalid option in tmux
Your tmux is below 3.3. Install tmux 3.4 from source (see Step 2).

---

## Platform-specific notes

### HPC clusters
- Run first plugin install on the login node (internet access)
- Load neovim, tmux, and R modules before launching nvim
- Use tmux for sessions that survive disconnects
- Add `module load` commands to `~/.bashrc`
- UCR HPCC: https://hpcc.ucr.edu/manuals/hpc_cluster/terminalide/

### macOS
- `xcode-select --install` first
- Homebrew (https://brew.sh) for all dependencies
- iTerm2 (https://iterm2.com) recommended — supports OSC 52 clipboard

### Windows (MobaXterm)
- MobaXterm has a built-in X server — clipboard works automatically
  via X11, no `clip` script needed
- MobaXterm docs: https://mobaxterm.mobatek.net/documentation.html
- Enable clipboard: MobaXterm Settings → X11 → Clipboard → enabled
- Disable "copy on select" if auto-copy is annoying

### Linux desktop
- Install `xclip`: `sudo apt install xclip`
- `clipboard=unnamedplus` in `init.lua` handles the rest

### ChromeOS (Crostini)
- Use `neovim-releases` tarball (apt and main neovim releases are too old)
- Mouse is disabled by default in `init.lua` (Crostini clipboard bridge
  is unreliable; terminal text selection works instead)
- Use `Ctrl-Shift-C` / `Ctrl-Shift-V` for copy/paste in terminal
- Use `Space-m` to toggle mouse on temporarily if needed
- Install tmux 3.4 from source (system tmux is an old rc version)
