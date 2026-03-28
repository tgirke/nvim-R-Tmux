-- ===========================================================
-- ~/.config/nvim/init.lua
-- Neovim config for R, Python and Bash development
-- on HPC clusters and personal systems
--
-- Authors / maintainers:
--   Thomas Girke (tgirke@ucr.edu)
--   https://github.com/tgirke/Nvim-R_Tmux
--
-- Derived from and based on:
--   R.nvim (Jakson Alves de Aquino & contributors)
--   https://github.com/R-nvim/R.nvim
--   https://github.com/R-nvim/R.nvim/blob/main/doc/R.nvim.txt
--
--   hlterm (Jakson Alves de Aquino) — replaces vimcmdline
--   https://github.com/jalvesaq/hlterm
--   Supports: Python, Bash, Shell, Julia, and many others
--   Same author as R.nvim; \s starts interpreter, Enter sends code
--
--   lazy.nvim plugin manager (Folke Viegas)
--   https://github.com/folke/lazy.nvim
--
--   nvim-treesitter (nvim-treesitter contributors)
--   https://github.com/nvim-treesitter/nvim-treesitter
--
--   neo-tree.nvim (Michael Sloan & contributors)
--   https://github.com/nvim-neo-tree/neo-tree.nvim
--
--   indent-blankline.nvim (Lukas Reineke)
--   https://github.com/lukas-reineke/indent-blankline.nvim
--
--   kanagawa.nvim color scheme (rebelot)
--   https://github.com/rebelot/kanagawa.nvim
--
-- Last tested: Neovim 0.11, R.nvim 0.99, hlterm, nvim-treesitter master
--
-- Maintainability notes:
--   - Each plugin block is self-contained and can be commented out
--   - Branch pins prevent upstream breakage (see nvim-treesitter note)
--   - To add a plugin: copy any block and change the GitHub repo name
--   - To remove a plugin: comment out its block, then :Lazy clean
--   - To update all plugins: :Lazy update
--   - To check for problems: :checkhealth
-- ===========================================================


-- ===========================================================
-- SECTION 1: Bootstrap lazy.nvim
--
-- Clones itself automatically on first launch if not present.
-- Source: https://github.com/folke/lazy.nvim#-installation
-- Nothing here needs to be changed.
-- ===========================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)


-- ===========================================================
-- SECTION 2: Basic editor options
-- Reference: https://neovim.io/doc/user/options.html
-- ===========================================================

vim.opt.number         = true   -- show line numbers
vim.opt.relativenumber = false
vim.opt.expandtab      = true   -- spaces not tabs
vim.opt.shiftwidth     = 4
vim.opt.tabstop        = 4
vim.opt.smartindent    = true
vim.opt.wrap           = false
vim.opt.undofile       = true   -- persistent undo across sessions
vim.opt.ignorecase     = true   -- case-insensitive search...
vim.opt.smartcase      = true   -- ...unless uppercase used
vim.opt.splitright     = true   -- vsplit opens right
vim.opt.splitbelow     = true   -- split opens below
vim.opt.scrolloff      = 5      -- keep 5 context lines
vim.opt.termguicolors  = true   -- 24-bit color

-- Cursor shape and color
-- Insert mode: bright yellow vertical bar, easy to spot on dark backgrounds.
-- Change the bg color to taste — options: #00e5ff (cyan), #ff9500 (orange)
-- Reference: https://neovim.io/doc/user/options.html#'guicursor'
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25-iCursor,r-cr:hor20,o:hor50"
vim.api.nvim_set_hl(0, "iCursor", { fg = "#000000", bg = "#ffff00" })

-- Split window borders
-- Unicode box-drawing characters give a clean continuous line
-- Color is a muted blue-grey that works well with kanagawa-wave
-- Adjust the hex value to taste: lighter = more visible, darker = more subtle
vim.opt.fillchars = { vert = "│", horiz = "─" }
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#5c6a7a", bold = false })

-- Folding
-- Uses treesitter to fold along code structure (function bodies,
-- chunk argument blocks in Rmd/Quarto, etc.)
-- foldlevel=99 means all folds start open — close manually as needed
-- Reference: https://github.com/nvim-treesitter/nvim-treesitter#folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr   = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel  = 99

-- ----------------------------------------------------------
-- Mouse and clipboard
--
-- Mouse is enabled on all systems by default.
-- Use Space-m to toggle mouse off when you need to select
-- and copy text with the terminal (e.g. on ChromeOS use
-- Space-m to turn off, then Ctrl-Shift-C to copy).
--
-- clipboard=unnamedplus syncs yy/p with the system clipboard.
-- On MobaXterm (Windows): works via X11 automatically.
-- On macOS/Linux over SSH: use the clip script (OSC 52).
-- On ChromeOS: use Ctrl-Shift-C/V in terminal.
--
-- To toggle mouse: Space-m (defined in Section 5)
-- Reference: https://neovim.io/doc/user/provider.html#clipboard
-- ----------------------------------------------------------

vim.opt.mouse     = "a"            -- mouse on (toggle with Space-m)
vim.opt.clipboard = "unnamedplus"  -- sync yy/p with system clipboard


-- ===========================================================
-- SECTION 3: Leader keys
--
-- maplocalleader (\) — R.nvim and hlterm R-specific commands:
--   \rf   start R session
--   \s    start Python/Bash interpreter (hlterm)
--   \rh   R help
--   \ro   object browser
--
-- mapleader (Space) — general editor keymaps (Section 5)
--
-- IMPORTANT: set before require("lazy").setup()
-- IMPORTANT: keep mapleader != maplocalleader to avoid
--   timeout conflicts with R.nvim keybindings
-- ===========================================================

vim.g.mapleader      = " "   -- Space
vim.g.maplocalleader = "\\"  -- Backslash


-- ===========================================================
-- SECTION 4: Plugins
--
-- Load order matters:
--   nvim-treesitter must load BEFORE R.nvim
--
-- Plugin manager UI:  :Lazy
-- Update all:         :Lazy update
-- Sync:               :Lazy sync
-- Health check:       :checkhealth
-- ===========================================================

require("lazy").setup({

  -- ---------------------------------------------------------
  -- nvim-treesitter
  -- Syntax parsing for R, Python, Bash and other languages.
  -- Required by R.nvim — must load at startup (lazy = false)
  -- and must be listed before R.nvim.
  --
  -- Repository: https://github.com/nvim-treesitter/nvim-treesitter
  --
  -- IMPORTANT: pinned to branch = "master"
  -- The "main" branch is a complete rewrite that removes the
  -- nvim-treesitter.configs module used by R.nvim.
  -- Do not remove this pin without testing first.
  -- ---------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",           -- pinned: "main" breaks R.nvim
    build  = ":TSUpdate",
    lazy   = false,              -- must load at startup
    main   = "nvim-treesitter.configs",
    opts   = {
      ensure_installed = {
        "r",                -- R
        "rnoweb",           -- Rnoweb/Sweave
        "markdown",         -- R Markdown / Quarto
        "markdown_inline",
        "yaml",             -- YAML front matter
        "bash",             -- Bash/Shell scripts
        "python",           -- Python
        "lua",              -- Neovim config
      },
      highlight = { enable = true },
      indent    = { enable = true },
    },
  },

  -- ---------------------------------------------------------
  -- R.nvim
  -- R integration: send code, completions, object browser,
  -- R Markdown/Quarto support, help lookups.
  --
  -- Repository:    https://github.com/R-nvim/R.nvim
  -- Documentation: https://github.com/R-nvim/R.nvim/blob/main/doc/R.nvim.txt
  -- Wiki:          https://github.com/R-nvim/R.nvim/wiki
  --
  -- Key bindings:
  --   \rf     start R session
  --   Enter   send line / selection to R  (set in hook below)
  --   \rh     R help for word under cursor
  --   \ro     toggle object browser
  --   Alt+-   insert <-
  --   Alt-,   insert |>
  --   :RMapsDesc    full keybinding list
  --   :RConfigShow  current config values
  -- ---------------------------------------------------------
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

        -- HPC performance: skip automatic completion database build on startup.
        -- On HPC systems with large R libraries on network filesystems (GPFS/NFS)
        -- the database build locks up Neovim completely and cannot be interrupted
        -- without killing the process from another terminal.
        -- R.nvim starts with basic completion only (fast and safe).
        -- Do NOT run \rb (RBuildTags) on the HPC login node — it will freeze nvim.
        -- If full completion is needed, run it inside an srun compute node session.
        objbr_auto_start = false,    -- don't open object browser automatically
        hook = {
          on_filetype = function()
            -- Enter sends line (normal) or selection (visual) to R
            -- Using Enter rather than Space avoids leader key conflict
            vim.api.nvim_buf_set_keymap(0, "n", "<Enter>",
              "<Plug>RDSendLine", {})
            vim.api.nvim_buf_set_keymap(0, "v", "<Enter>",
              "<Plug>RSendSelection", {})
          end,
        },
      })
    end,
  },

  -- ---------------------------------------------------------
  -- hlterm
  -- Send code to Python, Bash/Shell interpreters and more.
  -- The modern replacement for vimcmdline, by the same author
  -- (Jakson Alves de Aquino) as R.nvim.
  --
  -- Repository: https://github.com/jalvesaq/hlterm
  --
  -- Supported languages include: Python, Bash, Shell, Julia,
  -- JavaScript, Kotlin, Lua, Matlab, Ruby, Scala, and more.
  --
  -- Usage (in a .py or .sh file):
  --   \s      start the interpreter in a split pane
  --   Enter   send current line to interpreter  (set below)
  --   Enter   send selection to interpreter     (set below)
  --
  -- Note: uses the same Enter keybinding as R.nvim but they
  -- are buffer-local so they don't conflict — R files use
  -- R.nvim's Enter, Python/Bash files use hlterm's Enter.
  -- ---------------------------------------------------------
  {
    "jalvesaq/hlterm",
    lazy = false,
    config = function()
      -- Remap send-line from default \l to Enter
      -- to match R.nvim's keybinding for consistency
      vim.g.hlterm_map_send_line      = "<Enter>"
      vim.g.hlterm_map_send_selection = "<Enter>"
    end,
  },

  -- ---------------------------------------------------------
  -- neo-tree.nvim
  -- File browser. Replacement for unmaintained NERDTree.
  -- Toggle: zz
  --
  -- Repository:    https://github.com/nvim-neo-tree/neo-tree.nvim
  -- Documentation: https://github.com/nvim-neo-tree/neo-tree.nvim/blob/v3.x/doc/neo-tree.txt
  -- ---------------------------------------------------------
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch       = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",       -- https://github.com/nvim-lua/plenary.nvim
      "nvim-tree/nvim-web-devicons", -- optional icons (needs Nerd Font)
      "MunifTanjim/nui.nvim",        -- https://github.com/MunifTanjim/nui.nvim
    },
    keys = {
      { "zz", "<cmd>Neotree toggle<cr>", desc = "Toggle file browser" },
    },
    opts = {
      -- ASCII icons work in any terminal without Nerd Fonts installed.
      -- Students connecting via SSH/MobaXterm won't see broken boxes.
      -- To use Nerd Font icons instead, remove this default_component_configs
      -- block and install a Nerd Font: https://www.nerdfonts.com
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
        filtered_items = {
          visible       = false,
          hide_dotfiles = true,
          hide_gitignored = true,
        },
      },
    },
  },

  -- ---------------------------------------------------------
  -- indent-blankline.nvim
  -- Vertical indentation guide lines.
  -- Toggle: Space-i  (or :IBLToggle)
  --
  -- Repository: https://github.com/lukas-reineke/indent-blankline.nvim
  -- ---------------------------------------------------------
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
    keys = {
      { "<leader>i", "<cmd>IBLToggle<cr>", desc = "Toggle indent guides" },
    },
  },

  -- ---------------------------------------------------------
  -- render-markdown.nvim
  -- Renders markdown inside Neovim — no browser needed.
  -- Works over SSH on HPC and in any terminal.
  -- Toggle rendered view with Space-rm.
  --
  -- Repository: https://github.com/MeanderingProgrammer/render-markdown.nvim
  -- ---------------------------------------------------------
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

  -- ---------------------------------------------------------
  -- kanagawa.nvim
  -- Color scheme. Works in 256-color SSH sessions and
  -- true-color local terminals.
  -- Variants: "kanagawa-wave" | "kanagawa-dragon" | "kanagawa-lotus"
  --
  -- Repository: https://github.com/rebelot/kanagawa.nvim
  -- ---------------------------------------------------------
  {
    "rebelot/kanagawa.nvim",
    lazy     = false,
    priority = 1000,
    config = function()
      vim.cmd("colorscheme kanagawa-wave")
    end,
  },

}, {
  -- lazy.nvim settings
  -- Reference: https://github.com/folke/lazy.nvim#%EF%B8%8F-configuration
  install = { colorscheme = { "habamax" } },
  checker = { enabled = false },    -- no auto-update (recommended on HPC)
  rocks   = { enabled = false },    -- disable luarocks (not needed, avoids warnings)
})


-- ===========================================================
-- SECTION 5: Key mappings
-- General keymaps not specific to any plugin.
-- Plugin keymaps are co-located with their plugin blocks above.
-- Reference: https://neovim.io/doc/user/map.html
-- ===========================================================

-- Jump between splits with Ctrl-hjkl
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left split"  })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to lower split" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper split" })

-- Exit terminal insert mode with Esc
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Toggle mouse on/off (Space-m)
-- Use to switch between Neovim mouse support and terminal text selection.
-- On ChromeOS mouse starts off; on other systems it starts on.
vim.keymap.set("n", "<leader>m", function()
  if vim.opt.mouse:get() == "" or next(vim.opt.mouse:get()) == nil then
    vim.opt.mouse = "a"
    print("Mouse ON  — use Space-m to toggle, Shift+drag to select text")
  else
    vim.opt.mouse = ""
    print("Mouse OFF — terminal text selection active")
  end
end, { desc = "Toggle mouse" })

-- Fold toggles (Space-z / Space-Z)
-- Useful for collapsing Quarto/Rmd chunk argument blocks (#| lines)
-- and R function bodies to get a high-level overview of a script.
-- Uses treesitter foldexpr set in Section 2 above.
--   Space-z   close all folds
--   Space-Z   open all folds
--   za        toggle fold under cursor
vim.keymap.set("n", "<leader>z", "zM", { desc = "Close all folds" })
vim.keymap.set("n", "<leader>Z", "zR", { desc = "Open all folds" })

-- Auto-set tabstop=20 when viewing R data frames with \rv
-- Aligns column titles with column content in the viewer buffer.
-- Also disables line wrapping so wide tables stay readable.
-- To adjust column width change tabstop value (e.g. :set tabstop=15)
vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
  pattern = { "*.csv", "*.tsv" },
  callback = function()
    vim.opt_local.tabstop = 20
    vim.opt_local.wrap    = false
  end,
  desc = "Align columns in R data frame viewer",
})


-- ===========================================================
-- QUICK REFERENCE
--
-- Starting a session:
--   tmux new -s work       start tmux session (survives disconnects)
--   tmux a                 reattach to existing session
--   nvim script.R          open R script
--   nvim script.py         open Python script
--   nvim script.sh         open Bash script
--
-- R files (.R / .Rmd / .qmd):
--   \rf                    start R session
--   Enter (normal)         send current line to R
--   Enter (visual)         send selection to R
--   \aa                    send entire file
--   \ff                    send current function
--   \ce                    send current chunk (Rmd/Quarto)
--   \ch                    send all chunks above cursor
--   \rh                    R help for word under cursor
--   \ro                    toggle object browser
--   \rv                    view data frame (columns auto-aligned, tabstop=20)
--                          adjust width with: :set tabstop=15 (or any value)
--   Alt + -                insert <-
--   Alt + ,                insert |>
--   :RMapsDesc             full R.nvim keybinding list
--   :RConfigShow           current R.nvim config
--
-- Python files (.py) and Bash files (.sh):
--   \s                     start interpreter (Python or Bash)
--   Enter (normal)         send current line
--   Enter (visual)         send selection
--
-- File browser (neo-tree):
--   zz                     toggle open/close
--   a / d / r              create / delete / rename
--   H                      toggle hidden files
--   ?                      help inside neo-tree
--   q                      close
--
-- Markdown preview (in .md files):
--   Space-rm               toggle rendered markdown view on/off
--
-- Indent guides:
--   Space-i                toggle vertical indent guide lines on/off
--                          (useful before copying to avoid pasting guide chars)
--
-- Splits:
--   :vsplit                vertical split
--   :split                 horizontal split
--   Ctrl-w w               cycle between splits
--   Ctrl-hjkl              jump to split
--   gz                     maximize current split
--   Ctrl-w =               equalize splits
--   :terminal              open terminal
--   Esc                    exit terminal insert mode
--
-- Mouse:
--   Space-m                toggle mouse on/off
--   (ChromeOS: starts OFF — use terminal text selection)
--   (Others:   starts ON  — Shift+drag for terminal selection)
--
-- Folding (chunk args, function bodies):
--   Space-z                close all folds
--   Space-Z                open all folds
--   za                     toggle fold under cursor
--   zc / zo                close / open fold under cursor
--
-- Clipboard:
--   yy                     yank line to system clipboard
--   p                      paste from system clipboard
--   (ChromeOS: use Ctrl-Shift-C/V in terminal instead)
--
-- Plugins:
--   :Lazy                  plugin manager UI
--   :Lazy update           update all plugins
--   :Lazy sync             install + update + clean
--   :checkhealth r         R.nvim health check
--   :checkhealth provider  clipboard/provider check
--   :checkhealth lazy      lazy.nvim health check
-- ===========================================================
