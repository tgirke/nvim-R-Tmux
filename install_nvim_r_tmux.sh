#!/usr/bin/env bash
# =============================================================================
# install_nvim_r_tmux.sh
# Automated installer for the Nvim-R-Tmux environment
#
# Installs and configures:
#   - Neovim config (init.lua) with lazy.nvim, R.nvim, hlterm,
#     nvim-treesitter, neo-tree, indent-blankline, kanagawa, luasnip
#   - Tmux config (.tmux.conf)
#   - OSC 52 clip script for clipboard over SSH
#   - Patched bol.R to cap bo_code.R workers at 1 on HPC nodes
#   - Code snippets for R, Quarto and Rmd (~/.config/nvim/snippets/)
#   - Shell convenience aliases in .bashrc
#   - All plugins installed via headless :Lazy sync (no manual nvim needed)
#   - Treesitter parsers installed synchronously (no error on first open)
#   - nvimcom reinstalled from patched source so compiled bytecode is patched
#   - R.nvim completion cache pruned to base packages only
#
# Assumptions:
#   - Neovim >= 0.10 is available (via module load or in PATH)
#   - Tmux >= 3.4 is available
#   - R is available
#   - git is available
#   - Internet access is available (for plugin downloads)
#
# Authors / maintainers:
#   Thomas Girke (tgirke@ucr.edu)
#   https://github.com/tgirke/Nvim-R_Tmux
#
# Usage:
#   module load neovim/0.11.4 tmux R && bash install_nvim_r_tmux.sh
#
# To undo: the script prints rollback commands at the end.
# =============================================================================
set -euo pipefail
# On HPC clusters, initialize the module system if needed and load tools.
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
# ---------- wl-clipboard (local Wayland desktops only) -----------------------
# Only relevant for a local (non-SSH) Wayland session. Without wl-copy/wl-paste,
# Neovim's clipboard provider silently falls back to xclip over the XWayland
# bridge, which can desync from what the (Wayland-native) terminal actually
# pastes. Not needed on HPC — the OSC 52 clip path above has no dependency on
# any of these tools. Not needed on macOS (pbcopy/pbpaste) or X11-only Linux
# (xclip/xsel talk to the X server directly, no XWayland bridge involved).
if [ -n "${WAYLAND_DISPLAY:-}" ] && [ -z "${SSH_TTY:-}${SSH_CONNECTION:-}" ] \
   && ! command -v wl-copy &>/dev/null; then
  echo "--- Local Wayland session detected without wl-clipboard ---"
  if command -v apt-get &>/dev/null; then
    sudo apt-get install -y wl-clipboard
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y wl-clipboard
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm wl-clipboard
  else
    echo "  No supported package manager found — install wl-clipboard manually,"
    echo "  e.g.: sudo apt install wl-clipboard"
  fi || echo "  wl-clipboard install failed/skipped — clipboard may be flaky on this Wayland session."
  echo ""
fi
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
echo "--- Installing patched bol.R (~/.config/nvim/bol.R) ---"
cp "$(dirname "$0")/bol.R" "$HOME/.config/nvim/bol.R"
echo "  Done."
echo ""
# ---------- code snippets ----------------------------------------------------
# Snippets for R, Quarto and Rmd expand common code skeletons directly in
# the editor. Stored in ~/.config/nvim/snippets/ and loaded by LuaSnip.
# rmd.lua is a copy of quarto.lua — same snippets work for both filetypes.
echo "--- Installing code snippets (~/.config/nvim/snippets/) ---"
mkdir -p "$HOME/.config/nvim/snippets"
cp "$(dirname "$0")/snippets/r.lua"      "$HOME/.config/nvim/snippets/r.lua"
cp "$(dirname "$0")/snippets/quarto.lua" "$HOME/.config/nvim/snippets/quarto.lua"
cp "$(dirname "$0")/snippets/quarto.lua" "$HOME/.config/nvim/snippets/rmd.lua"
echo "  Done."
echo ""
# ---------- hlterm bash fix --------------------------------------------------
echo "--- Installing hlterm bash override (~/.config/nvim/after/ftplugin/) ---"
mkdir -p "$HOME/.config/nvim/after/ftplugin"
cp "$(dirname "$0")/sh_hlterm.lua" "$HOME/.config/nvim/after/ftplugin/sh_hlterm.lua"
echo "  Done."
echo ""
# ---------- Rprofile ---------------------------------------------------------
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
  if command -v vd &>/dev/null; then
    echo "  VisiData installed: $(vd --version 2>&1 | head -1)"
  elif [ -f "$HOME/.local/bin/vd" ]; then
    echo "  VisiData installed to ~/.local/bin/vd (active after: source ~/.bashrc)"
  else
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
# ---------- lazy sync (headless) ---------------------------------------------
# Runs :Lazy sync without opening nvim, installing all plugins and triggering
# the build hook in init.lua which deploys the patched bol.R and marks it
# as assume-unchanged so future :Lazy updates are not blocked.
# Requires internet access. Takes 1-3 minutes on first run.
echo "--- Installing Neovim plugins (headless :Lazy sync) ---"
echo "  This may take 1-3 minutes on first run..."
nvim --headless "+Lazy! sync" +qa 2>&1
echo "  Done."
echo ""
# ---------- treesitter parsers -----------------------------------------------
# Install treesitter parsers synchronously so they are ready before nvim is
# opened for the first time. Without this, opening an R file immediately after
# install triggers a one-time error about a missing R parser.
echo "--- Installing treesitter parsers (synchronous) ---"
nvim --headless \
  "+TSInstallSync! r rnoweb markdown markdown_inline yaml bash python lua" \
  +qa 2>&1
echo "  Done."
echo ""
# ---------- reinstall nvimcom from patched source ----------------------------
# nvimcom is installed as a compiled R package (bytecode in .rdb) in the
# user's ~/R/ library. Patching the source bol.R in the lazy plugin directory
# has no effect on the compiled package — library('nvimcom') always loads
# the bytecode from ~/R/, ignoring the source tree entirely.
# The fix is to reinstall nvimcom from our patched source so the compiled
# bytecode contains the patched nvim.build.cmplls() function.
echo "--- Reinstalling nvimcom from patched source ---"
NVIMCOM_SRC="$HOME/.local/share/nvim/lazy/R.nvim/nvimcom"
NVIMCOM_BOL="$NVIMCOM_SRC/R/bol.R"
if [ -d "$NVIMCOM_SRC" ]; then
  cp "$HOME/.config/nvim/bol.R" "$NVIMCOM_BOL"
  echo "  Patched bol.R deployed to nvimcom source tree."
  Rscript --vanilla -e "
    lib <- Sys.getenv('R_LIBS_USER', unset = path.expand('~/R'))
    lib <- strsplit(lib, .Platform\$path.sep)[[1]][1]
    if (!dir.exists(lib)) dir.create(lib, recursive = TRUE)
    cat('  Installing to:', lib, '\n')
    install.packages(
      '$NVIMCOM_SRC',
      lib          = lib,
      repos        = NULL,
      type         = 'source',
      quiet        = FALSE,
      INSTALL_opts = '--no-multiarch'
    )
  " 2>&1
  RESULT=$(Rscript --vanilla -e "
    library('nvimcom', quietly = TRUE)
    fn <- deparse(body(nvimcom:::nvim.build.cmplls))
    if (any(grepl('loaded_libs', fn))) {
      cat('OK: patched nvim.build.cmplls detected\n')
    } else {
      cat('WARNING: patch not detected in installed nvimcom\n')
    }
  " 2>&1)
  echo "  $RESULT"
else
  echo "  WARNING: nvimcom source not found at $NVIMCOM_SRC"
  echo "           Headless lazy sync may have failed. Run manually:"
  echo "           nvim --headless '+Lazy! sync' +qa"
fi
echo ""
# ---------- R.nvim cache cleanup ---------------------------------------------
# Remove cached completion entries for all non-base R packages.
# The patched nvimcom limits indexing to currently loaded packages only,
# but any cache entries built before this install would still trigger
# rebuild attempts. Pruning ensures a clean starting state.
echo "--- Pruning R.nvim completion cache to base packages ---"
CACHE_DIR="$HOME/.cache/R.nvim"
if [ -d "$CACHE_DIR" ]; then
  removed=0
  for f in "$CACHE_DIR"/objls_* "$CACHE_DIR"/alias_* \
            "$CACHE_DIR"/args_*  "$CACHE_DIR"/srcref_*; do
    [ -e "$f" ] || continue
    fname=$(basename "$f")
    pkg=$(echo "$fname" | sed 's/^[^_]*_//; s/_[^_]*$//')
    case "$pkg" in
      base|stats|graphics|grDevices|utils|datasets|methods) ;;
      *) rm -f "$f"; removed=$((removed + 1)) ;;
    esac
  done
  echo "  Removed $removed non-base cache entries."
else
  echo "  Cache directory not found, skipping."
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
echo "  3. Open an R file:"
echo "       nvim myscript.R"
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
echo "  NOTE: After running :Lazy update to update plugins, reinstall"
echo "  the patched nvimcom by re-running the installer or manually:"
echo "    cp ~/.config/nvim/bol.R \\"
echo "      ~/.local/share/nvim/lazy/R.nvim/nvimcom/R/bol.R"
echo "    Rscript --vanilla -e \"install.packages("
echo "      '~/.local/share/nvim/lazy/R.nvim/nvimcom',"
echo "      lib=Sys.getenv('R_LIBS_USER'), repos=NULL, type='source')\""
echo ""
echo "------------------------------------------------------------"
echo "  ROLLBACK (if something goes wrong):"
for f in "$HOME/.config/nvim" "$HOME/.tmux.conf" "$HOME/.Rprofile" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    bak="${f}${BACKUP_SUFFIX}"
    if [ -e "$bak" ]; then
        echo "    rm -rf \"$f\" && mv \"$bak\" \"$f\""
    fi
done
echo "  To reinstall nvimcom from upstream (unpatched):"
echo "    Rscript -e \"remove.packages('nvimcom')\""
echo "------------------------------------------------------------"
