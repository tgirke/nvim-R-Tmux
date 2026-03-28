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
cat > "$HOME/.local/bin/clip" << 'CLIPEOF'
#!/bin/bash
# OSC 52 clipboard writer — copies text to local system clipboard over SSH
# Works with: macOS iTerm2, Windows Terminal, most Linux terminals
# Does NOT work with MobaXterm (uses X11 clipboard automatically instead)
# Usage: echo "text" | clip
buf=$(cat "$@")
encoded=$(printf '%s' "$buf" | base64 | tr -d '\n')
printf '\033]52;c;%s\a' "$encoded"
CLIPEOF
chmod +x "$HOME/.local/bin/clip"
echo "  Done."
echo ""

# ---------- tmux config ------------------------------------------------------
echo "--- Installing tmux config (~/.tmux.conf) ---"
cat > "$HOME/.tmux.conf" << 'TMUXEOF'
# Prefix: Ctrl-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# General
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 10000
set -s escape-time 0
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
set -g set-titles on
set -g set-titles-string "#T"

# OSC 52 clipboard passthrough (requires tmux >= 3.3 full release)
# Allows Neovim/clip to write to local clipboard over SSH without X11
set -g allow-passthrough on
set -s set-clipboard on

# Mouse
set -g mouse on

# Splits (| and - instead of % and ")
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Pane navigation
bind Left  select-pane -L
bind Right select-pane -R
bind Up    select-pane -U
bind Down  select-pane -D

# Pane resize (Alt+arrow, no prefix)
bind -n M-Left  resize-pane -L 5
bind -n M-Right resize-pane -R 5
bind -n M-Up    resize-pane -U 5
bind -n M-Down  resize-pane -D 5

# Zoom
bind z resize-pane -Z

# New window in current directory
bind c new-window -c "#{pane_current_path}"

# Toggle mouse
bind m set -g mouse \; display-message "Mouse: #{?mouse,ON,OFF}"

# Reload config
bind r source-file ~/.tmux.conf \; display-message "Config reloaded"

# Status bar
set -g status-position bottom
set -g status-bg colour234
set -g status-fg colour137
set -g status-left  '#[fg=colour233,bg=colour241,bold] #S '
set -g status-right '#[fg=colour233,bg=colour241,bold] %d %b %H:%M '
set -g status-right-length 50
set -g status-left-length 20
setw -g window-status-current-style fg=colour81,bg=colour238,bold
setw -g window-status-current-format ' #I:#W#F '
setw -g window-status-style fg=colour138,bg=colour235
setw -g window-status-format ' #I:#W#F '

# Default session with named windows
# Start with: tmux  (creates session)
# Reattach with: tmux a
# Kill session: Ctrl-a : kill-session
new-session -s work -n main
neww -n editor
neww -n shell
neww -n monitor
neww -n extra
select-window -t 1
TMUXEOF
echo "  Done."
echo ""

# ---------- nvim config ------------------------------------------------------
echo "--- Installing Neovim config (~/.config/nvim/init.lua) ---"
mkdir -p "$HOME/.config/nvim"

cat > "$HOME/.config/nvim/init.lua" << 'LUAEOF'
-- Neovim config for R/Python/Bash on HPC and personal systems
-- Authors: Thomas Girke — https://github.com/tgirke/Nvim-R_Tmux
-- Plugins: R.nvim, hlterm, nvim-treesitter, neo-tree, lazy.nvim
-- See INSTALL.md for full documentation and attribution

-- Bootstrap lazy.nvim (https://github.com/folke/lazy.nvim)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Editor options
vim.opt.number         = true
vim.opt.relativenumber = false
vim.opt.expandtab      = true
vim.opt.shiftwidth     = 4
vim.opt.tabstop        = 4
vim.opt.smartindent    = true
vim.opt.wrap           = false
vim.opt.undofile       = true
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.splitright     = true
vim.opt.splitbelow     = true
vim.opt.scrolloff      = 5
vim.opt.termguicolors  = true

-- Split window borders
vim.opt.fillchars = { vert = "│", horiz = "─" }
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#5c6a7a", bold = false })

-- Folding via treesitter (foldlevel=99 means all folds start open)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr   = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel  = 99

-- Mouse and clipboard (on by default, toggle with Space-m)
vim.opt.mouse     = "a"
vim.opt.clipboard = "unnamedplus"

-- Leader keys
-- maplocalleader (\): R.nvim (\rf, \rh etc) and hlterm (\s)
-- mapleader (Space): general keymaps
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- Plugins
require("lazy").setup({

  -- nvim-treesitter: syntax parsing, required by R.nvim
  -- PINNED to master branch — "main" branch breaks R.nvim
  -- https://github.com/nvim-treesitter/nvim-treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build  = ":TSUpdate",
    lazy   = false,
    main   = "nvim-treesitter.configs",
    opts   = {
      ensure_installed = {
        "r", "rnoweb", "markdown", "markdown_inline",
        "yaml", "bash", "python", "lua",
      },
      highlight = { enable = true },
      indent    = { enable = true },
    },
  },

  -- R.nvim: R integration
  -- https://github.com/R-nvim/R.nvim
  -- \rf: start R  |  Enter: send line/selection  |  \rh: help
  {
    "R-nvim/R.nvim",
    lazy         = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("r").setup({
        R_args           = { "--quiet", "--no-save" },
        min_editor_width = 72,
        rconsole_width   = 78,
        auto_quit        = true,
        hook = {
          on_filetype = function()
            vim.api.nvim_buf_set_keymap(0, "n", "<Enter>",
              "<Plug>RDSendLine", {})
            vim.api.nvim_buf_set_keymap(0, "v", "<Enter>",
              "<Plug>RSendSelection", {})
          end,
        },
      })
    end,
  },

  -- hlterm: Python/Bash/Shell REPL — replaces vimcmdline
  -- https://github.com/jalvesaq/hlterm
  -- \s: start interpreter  |  Enter: send line/selection
  -- bash --login override is in after/ftplugin/sh_hlterm.lua
  {
    "jalvesaq/hlterm",
    lazy = false,
    config = function()
      vim.g.hlterm_map_send_line      = "<Enter>"
      vim.g.hlterm_map_send_selection = "<Enter>"
    end,
  },

  -- neo-tree: file browser (replaces NERDTree)
  -- https://github.com/nvim-neo-tree/neo-tree.nvim
  -- zz: toggle
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch       = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "zz", "<cmd>Neotree toggle<cr>", desc = "Toggle file browser" },
    },
    opts = {
      default_component_configs = {
        icon = {
          folder_closed = "+",
          folder_open   = "-",
          folder_empty  = "~",
          default       = " ",
        },
        git_status = { symbols = {} },
      },
      filesystem = {
        filtered_items = { visible = false, hide_dotfiles = true, hide_gitignored = true },
      },
    },
  },

  -- indent-blankline: indentation guides
  -- https://github.com/lukas-reineke/indent-blankline.nvim
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },

  -- render-markdown: renders markdown inside nvim terminal
  -- No browser needed — works over SSH on HPC
  -- Toggle with Space-rm in any .md file
  -- https://github.com/MeanderingProgrammer/render-markdown.nvim
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft           = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<leader>rm", "<cmd>RenderMarkdown toggle<cr>",
        ft = "markdown", desc = "Toggle markdown render" },
    },
    opts = {
      heading = { enabled = true },
      code    = { enabled = true },
    },
  },

  -- kanagawa: color scheme
  -- https://github.com/rebelot/kanagawa.nvim
  {
    "rebelot/kanagawa.nvim",
    lazy     = false,
    priority = 1000,
    config   = function() vim.cmd("colorscheme kanagawa-wave") end,
  },

}, {
  install = { colorscheme = { "habamax" } },
  checker = { enabled = false },
  rocks   = { enabled = false },
})

-- Key mappings
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Left split"  })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Right split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Lower split" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Upper split" })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal" })

-- Toggle mouse (Space-m)
vim.keymap.set("n", "<leader>m", function()
  if vim.opt.mouse:get() == "" or next(vim.opt.mouse:get()) == nil then
    vim.opt.mouse = "a"
    print("Mouse ON  — Shift+drag for terminal text selection")
  else
    vim.opt.mouse = ""
    print("Mouse OFF — terminal text selection active")
  end
end, { desc = "Toggle mouse" })

-- Fold toggles: Space-z closes all, Space-Z opens all, za toggles one
vim.keymap.set("n", "<leader>z", "zM", { desc = "Close all folds" })
vim.keymap.set("n", "<leader>Z", "zR", { desc = "Open all folds" })

-- Auto-set tabstop=20 for R data frame viewer (\rv)
-- Aligns column titles with column content
vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
  pattern = { "*.csv", "*.tsv" },
  callback = function()
    vim.opt_local.tabstop = 20
    vim.opt_local.wrap    = false
  end,
  desc = "Align columns in R data frame viewer",
})
LUAEOF
echo "  Done."
echo ""

# ---------- hlterm bash fix --------------------------------------------------
echo "--- Installing hlterm bash override (~/.config/nvim/after/ftplugin/) ---"
mkdir -p "$HOME/.config/nvim/after/ftplugin"
cat > "$HOME/.config/nvim/after/ftplugin/sh_hlterm.lua" << 'HLTERMEOF'
-- Override hlterm's sh ftplugin to use bash --login instead of sh
-- so ~/.bashrc is sourced and the user's normal prompt appears.
-- Full options table copied from hlterm/ftplugin/sh_hlterm.lua
-- with only "app" changed from "sh" to "bash --login".
-- All other fields kept identical to avoid missing field errors.

local function source_lines(lines)
    local config = require("hlterm").get_config()
    local f = config.tmp_dir .. "/lines.sh"
    vim.fn.writefile(lines, f)
    require("hlterm").send_cmd("sh", ". " .. f)
end

require("hlterm").set_ft_opts("sh", {
    nl         = "\n",
    app        = "bash --login",
    quit_cmd   = "exit",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^\\$ .*" },
            { "Input", "^> .*" },
            { "Error", "^sh: .*" },
        },
        keyword = {},
    },
})
HLTERMEOF
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
