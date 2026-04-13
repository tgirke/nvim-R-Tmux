#!/usr/bin/env bash
# =============================================================================
# install_nvim_r_tmux.sh
# Automated installer for the Nvim-R-Tmux environment
#
# Installs and configures:
#   - Neovim config (init.lua) with lazy.nvim, R.nvim, hlterm,
#     nvim-treesitter, neo-tree, indent-blankline, kanagawa
#   - Tmux config (.tmux.conf)
#   - OSC 52 clip script for clipboard over SSH
#   - Patched bol.R to cap bo_code.R workers at 1 on HPC nodes
#   - Shell convenience aliases in .bashrc
#
# Assumptions:
#   - Neovim >= 0.10 is available (via module load or in PATH)
#   - Tmux >= 3.4 is available
#   - R is available
#   - git is available
#
# Authors / maintainers:
#   Thomas Girke (tgirke@ucr.edu)
#   https://github.com/tgirke/Nvim-R_Tmux
#
# Usage:
#   bash install_nvim_r_tmux.sh
#
# To undo: the script prints rollback commands at the end.
# =============================================================================
set -euo pipefail
# On HPC clusters, initialize the module system if needed and load tools.
# We source the bash-specific init directly to avoid shell detection issues
# in non-interactive subshells. The 2>/dev/null suppresses known bugs in
# some module system versions (e.g. uasked variable error).
set +e
if [ -f /usr/share/Modules/init/bash ] && ! command -v module &>/dev/null; then
  source /usr/share/Modules/init/bash 2>/dev/null
fi
set -e
# Load required modules if available and not already in PATH
if command -v module &>/dev/null; then
  command -v nvim &>/dev/null || module load neovim/0.11.4 2>/dev/null || module load neovim 2>/dev/null || true
  command -v tmux &>/dev/null || module load tmux 2>/dev/null || true
  command -v R    &>/dev/null || module load R    2>/dev/null || true
fi
BACKUP_SUFFIX=".bak_$(date +%Y%m%d_%H%M%S)"
echo "============================================================"
echo "  Nvim-R-Tmux Installer"
echo "============================================================"
echo ""
# ---------- helpers ----------------------------------------------------------
backup_if_exists() {
    if [ -e "$1" ]; then
        cp -r "$1" "${1}${BACKUP_SUFFIX}"
        echo "  Backed up: $1  →  ${1}${BACKUP_SUFFIX}"
    fi
}
require_cmd() {
    if ! command -v "$1" &>/dev/null; then
        echo "ERROR: '$1' not found."
        echo "       On HPC: load modules first, then run the script in the same shell:"
        echo "         module load neovim tmux R && bash install_nvim_r_tmux.sh"
        echo "       Or use a login shell:"
        echo "         bash -l install_nvim_r_tmux.sh"
        exit 1
    fi
}
# ---------- pre-flight -------------------------------------------------------
echo "--- Checking prerequisites ---"
require_cmd nvim
require_cmd tmux
require_cmd git
echo "  neovim : $(nvim --version | head -1)"
echo "  tmux   : $(tmux -V)"
echo "  git    : $(git --version)"
echo ""
# ---------- backup existing configs ------------------------------------------
echo "--- Backing up existing configs ---"
backup_if_exists "$HOME/.config/nvim"
backup_if_exists "$HOME/.tmux.conf"
backup_if_exists "$HOME/.Rprofile"
backup_if_exists "$HOME/.bashrc"
echo ""
# ---------- clip script (OSC 52 clipboard) -----------------------------------
echo "--- Installing clip script (~/.local/bin/clip) ---"
mkdir -p "$HOME/.local/bin"
cp "$(dirname "$0")/clip" "$HOME/.local/bin/clip"
chmod +x "$HOME/.local/bin/clip"
echo "  Done."
echo ""
# ---------- tmux config ------------------------------------------------------
echo "--- Installing tmux config (~/.tmux.conf) ---"
cp "$(dirname "$0")/.tmux.conf" "$HOME/.tmux.conf"
echo "  Done."
echo ""
# ---------- nvim config ------------------------------------------------------
echo "--- Installing Neovim config (~/.config/nvim/init.lua) ---"
mkdir -p "$HOME/.config/nvim"
cp "$(dirname "$0")/init.lua" "$HOME/.config/nvim/init.lua"
echo "  Done."
echo ""
# ---------- patched bol.R ----------------------------------------------------
# nvimcom's bol.R hardcodes parallel::detectCores() - 2 as the worker count
# for its completion database builder, ignoring all R options and environment
# variables. On SLURM nodes with --cpus-per-task > 2 this causes 20+ bo_code.R
# processes per session. The patched bol.R in this repo caps num_cores at 1L.
#
# This file is installed to ~/.config/nvim/bol.R so that the build hook in
# init.lua can copy it into the lazy.nvim plugin directory after each
# :Lazy sync / :Lazy update, ensuring the patch survives plugin updates.
echo "--- Installing patched bol.R (~/.config/nvim/bol.R) ---"
cp "$(dirname "$0")/bol.R" "$HOME/.config/nvim/bol.R"
echo "  Done."
echo ""
# ---------- hlterm bash fix --------------------------------------------------
echo "--- Installing hlterm bash override (~/.config/nvim/after/ftplugin/) ---"
mkdir -p "$HOME/.config/nvim/after/ftplugin"
cp "$(dirname "$0")/sh_hlterm.lua" "$HOME/.config/nvim/after/ftplugin/sh_hlterm.lua"
echo "  Done."
echo ""
# ---------- Rprofile ---------------------------------------------------------
# Guards against re-running: checks for nvim_r_tmux_env marker.
echo "--- Updating ~/.Rprofile ---"
if ! grep -q "nvim_r_tmux_env" "$HOME/.Rprofile" 2>/dev/null; then
cat >> "$HOME/.Rprofile" << 'REOF'
# --- nvim_r_tmux_env ---
# Disable nvimcom package description indexing.
# Prevents additional bo_code.R processes from being spawned to read
# DESCRIPTION files for all installed packages on startup.
options(nvimcom.pkg.desc = FALSE)

# Load colorout for colored R output in nvim terminal (if installed)
# https://github.com/jalvesaq/colorout
if (interactive() && Sys.getenv("NVIMR_ID") != "") {
  tryCatch(
    library(colorout, quietly = TRUE),
    error = function(e) invisible(NULL)
  )
}
REOF
echo "  Appended nvimcom and colorout settings to ~/.Rprofile"
else
  echo "  ~/.Rprofile already updated, skipping."
fi
echo ""
# ---------- bashrc -----------------------------------------------------------
echo "--- Updating ~/.bashrc ---"
if ! grep -q "nvim_r_tmux_env" "$HOME/.bashrc" 2>/dev/null; then
cat >> "$HOME/.bashrc" << 'BASHEOF'
# --- nvim_r_tmux_env ---
# Load HPC modules if module command is available
if command -v module &>/dev/null; then
  module load neovim/0.11.4 tmux R 2>/dev/null || true
fi
export PATH="$HOME/.local/bin:$PATH"
alias vim=nvim
export EDITOR=nvim
export VISUAL=nvim
BASHEOF
echo "  Appended to ~/.bashrc"
else
  echo "  ~/.bashrc already updated, skipping."
fi
echo ""
# ---------- bash_profile -----------------------------------------------------
# Ensure ~/.bash_profile sources ~/.bashrc for login shells.
# On HPCC, many accounts already have a ~/.bash_profile that does NOT source
# ~/.bashrc, which means the module load and PATH changes above are silently
# skipped at login — causing the system's old Neovim to be used instead of
# the one loaded by the module system.
# We check for an existing source line and append one if missing, regardless
# of whether the file already exists.
echo "--- Checking ~/.bash_profile sources ~/.bashrc ---"
if ! grep -qE '\.\s+~/\.bashrc|source\s+~/\.bashrc' "$HOME/.bash_profile" 2>/dev/null; then
  backup_if_exists "$HOME/.bash_profile"
  cat >> "$HOME/.bash_profile" << 'PROFEOF'

# Source ~/.bashrc for login shells (added by nvim-R-Tmux installer)
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
PROFEOF
  echo "  Appended bashrc sourcing to ~/.bash_profile"
else
  echo "  ~/.bash_profile already sources ~/.bashrc, skipping."
fi
echo ""
# ---------- visidata ---------------------------------------------------------
# Must run after bashrc update — export PATH first so vd check works
export PATH="$HOME/.local/bin:$PATH"
echo "--- Installing VisiData (~/.local/bin/vd) ---"
if command -v vd &>/dev/null; then
  echo "  VisiData already installed: $(vd --version 2>&1 | head -1)"
elif command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
  PIP=$(command -v pip3 || command -v pip)
  echo "  Using: $PIP"
  if ! $PIP install --user visidata 2>/dev/null; then
    $PIP install --user visidata --break-system-packages
  fi
  # Check common install locations explicitly
  if command -v vd &>/dev/null; then
    echo "  VisiData installed: $(vd --version 2>&1 | head -1)"
  elif [ -f "$HOME/.local/bin/vd" ]; then
    echo "  VisiData installed to ~/.local/bin/vd (active after: source ~/.bashrc)"
  else
    # pip may install to a different location on some systems (e.g. Mac)
    VD_PATH=$(python3 -c "import site; print(site.getuserbase())" 2>/dev/null)
    echo "  VisiData may be installed under: $VD_PATH/bin/vd"
    echo "  Add to PATH: export PATH=\"$VD_PATH/bin:\$PATH\""
  fi
else
  echo "  pip not found — skipping VisiData install."
  echo "  Install manually: pip install --user visidata"
  echo "  Or on Mac: brew install visidata"
fi
echo ""
# ---------- done -------------------------------------------------------------
echo "============================================================"
echo "  Installation complete!"
echo "============================================================"
echo ""
echo "  NEXT STEPS:"
echo ""
echo "  1. Log out and back in (or: source ~/.bashrc)"
echo ""
echo "  2. Start a tmux session:"
echo "       tmux new -s work"
echo ""
echo "  3. Open an R file and install plugins (first launch only):"
echo "       nvim myscript.R"
echo "       # lazy.nvim installs plugins automatically"
echo "       # then: :Lazy sync"
echo "       # the build hook in init.lua deploys the patched bol.R"
echo ""
echo "  4. Start R with:  \\rf"
echo "     Send lines with: Enter"
echo ""
echo "  5. For Python/Bash: open .py or .sh file"
echo "     Start interpreter with: \\s"
echo "     Send lines with: Enter"
echo ""
echo "  6. Optional: install colorout R package for colored output:"
echo "       Rscript -e 'install.packages(\"remotes\")'"
echo "       Rscript -e 'remotes::install_github(\"jalvesaq/colorout\")'"
echo ""
echo "------------------------------------------------------------"
echo "  ROLLBACK (if something goes wrong):"
for f in "$HOME/.config/nvim" "$HOME/.tmux.conf" "$HOME/.Rprofile" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    bak="${f}${BACKUP_SUFFIX}"
    if [ -e "$bak" ]; then
        echo "    rm -rf \"$f\" && mv \"$bak\" \"$f\""
    fi
done
echo "------------------------------------------------------------"
