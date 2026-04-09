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

# Initialize module system if available (HPC clusters)
# Source bash-specific module init directly, bypassing shell detection
# which can fail in non-interactive subshells
set +e
if [ -f /usr/share/Modules/init/bash ]; then
  source /usr/share/Modules/init/bash 2>/dev/null
elif [ -f /usr/share/modules/init/bash ]; then
  source /usr/share/modules/init/bash 2>/dev/null
elif [ -f /etc/profile.d/modules.sh ]; then
  source /etc/profile.d/modules.sh 2>/dev/null
fi
set -e

# On HPC clusters, load required modules if module command is available
# and the tools are not already in PATH
if command -v module &>/dev/null; then
  command -v nvim &>/dev/null || module load neovim 2>/dev/null || true
  command -v tmux &>/dev/null || module load tmux   2>/dev/null || true
  command -v R    &>/dev/null || module load R       2>/dev/null || true
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
backup_if_exists "$HOME/.bash_profile"
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

# ---------- hlterm bash fix --------------------------------------------------
echo "--- Installing hlterm bash override (~/.config/nvim/after/ftplugin/) ---"
mkdir -p "$HOME/.config/nvim/after/ftplugin"
cp "$(dirname "$0")/sh_hlterm.lua" "$HOME/.config/nvim/after/ftplugin/sh_hlterm.lua"
echo "  Done."
echo ""

echo "--- Updating ~/.Rprofile ---"
if ! grep -q "colorout" "$HOME/.Rprofile" 2>/dev/null; then
cat >> "$HOME/.Rprofile" << 'REOF'

# Load colorout for colored R output in nvim terminal (if installed)
# https://github.com/jalvesaq/colorout
if (interactive() && Sys.getenv("NVIMR_ID") != "") {
  tryCatch(
    library(colorout, quietly = TRUE),
    error = function(e) invisible(NULL)
  )
}
REOF
echo "  Appended colorout loader to ~/.Rprofile"
else
  echo "  ~/.Rprofile already updated, skipping."
fi
echo ""

# ---------- bashrc -----------------------------------------------------------
echo "--- Updating ~/.bashrc ---"
backup_if_exists "$HOME/.bashrc"
if ! grep -q "nvim_r_tmux_env" "$HOME/.bashrc" 2>/dev/null; then
cat >> "$HOME/.bashrc" << 'BASHEOF'

# --- nvim_r_tmux_env ---
# Load HPC modules if module command is available
if command -v module &>/dev/null; then
  module load neovim tmux R 2>/dev/null || true
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

# Create ~/.bash_profile if missing — ensures ~/.bashrc is sourced on login
# New HPC accounts often have neither file, causing module command not found
if [ ! -f "$HOME/.bash_profile" ]; then
  echo "--- Creating ~/.bash_profile ---"
  cat > "$HOME/.bash_profile" << 'PROFEOF'
# Source ~/.bashrc for login shells (created by nvim-R-Tmux installer)
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
PROFEOF
  echo "  Done."
  echo ""
fi

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
