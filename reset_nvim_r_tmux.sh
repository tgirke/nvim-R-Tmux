#!/usr/bin/env bash
# =============================================================================
# reset_nvim_r_tmux.sh
# Removes all files installed by install_nvim_r_tmux.sh for clean retesting.
#
# Authors / maintainers:
#   Thomas Girke (tgirke@ucr.edu)
#   https://github.com/tgirke/Nvim-R_Tmux
#
# Usage:
#   bash reset_nvim_r_tmux.sh
#
# WARNING: This permanently deletes the listed files and directories.
# It is intended for use in test accounts only.
# =============================================================================
set -euo pipefail

echo "============================================================"
echo "  Nvim-R-Tmux Reset"
echo "============================================================"
echo ""
echo "  WARNING: This will permanently delete your Neovim config,"
echo "  plugins, cache, tmux config, and related settings."
echo ""
read -r -p "  Are you sure? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "  Aborted."
  exit 0
fi
echo ""

# ---------- neovim -----------------------------------------------------------
echo "--- Removing Neovim config and data ---"
rm -rf "$HOME/.config/nvim"
rm -rf "$HOME/.local/share/nvim"
rm -rf "$HOME/.local/state/nvim"
rm -rf "$HOME/.cache/nvim"
rm -rf "$HOME/.cache/R.nvim"
echo "  Done."
echo ""

# ---------- tmux -------------------------------------------------------------
echo "--- Removing tmux config ---"
rm -f "$HOME/.tmux.conf"
echo "  Done."
echo ""

# ---------- clip script ------------------------------------------------------
echo "--- Removing clip script ---"
rm -f "$HOME/.local/bin/clip"
echo "  Done."
echo ""

# ---------- bashrc block -----------------------------------------------------
echo "--- Removing nvim_r_tmux_env block from ~/.bashrc ---"
if grep -q "nvim_r_tmux_env" "$HOME/.bashrc" 2>/dev/null; then
  # Remove from the marker line to the end of the block (5 lines)
  sed -i '/# --- nvim_r_tmux_env ---/,/^export VISUAL=nvim$/d' "$HOME/.bashrc"
  echo "  Done."
else
  echo "  Block not found, skipping."
fi
echo ""

# ---------- Rprofile block ---------------------------------------------------
echo "--- Removing nvim_r_tmux_env block from ~/.Rprofile ---"
if grep -q "nvim_r_tmux_env" "$HOME/.Rprofile" 2>/dev/null; then
  sed -i '/# --- nvim_r_tmux_env ---/,/^}$/d' "$HOME/.Rprofile"
  echo "  Done."
else
  echo "  Block not found, skipping."
fi
echo ""

# ---------- bash_profile block -----------------------------------------------
echo "--- Removing installer block from ~/.bash_profile ---"
if grep -q "nvim-R-Tmux installer" "$HOME/.bash_profile" 2>/dev/null; then
  sed -i '/# Source ~\/.bashrc for login shells (added by nvim-R-Tmux installer)/,/^fi$/d' \
    "$HOME/.bash_profile"
  echo "  Done."
else
  echo "  Block not found, skipping."
fi
echo ""

# ---------- done -------------------------------------------------------------
echo "============================================================"
echo "  Reset complete."
echo "============================================================"
echo ""
echo "  You can now re-run the installer:"
echo "    module load neovim/0.11.4 tmux R && bash install_nvim_r_tmux.sh"
echo ""
