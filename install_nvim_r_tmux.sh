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
        echo "ERROR: '$1' not found. Please load the module first."
        echo "       e.g.: module load neovim tmux R"
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
for f in "$HOME/.config/nvim" "$HOME/.tmux.conf" "$HOME/.Rprofile" "$HOME/.bashrc"; do
    bak="${f}${BACKUP_SUFFIX}"
    if [ -e "$bak" ]; then
        echo "    rm -rf \"$f\" && mv \"$bak\" \"$f\""
    fi
done
echo "------------------------------------------------------------"
