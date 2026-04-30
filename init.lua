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
--   vim-fugitive (Tim Pope)
--   https://github.com/tpope/vim-fugitive
--
--   claude-code.nvim (Greg Hughes)
--   https://github.com/greggh/claude-code.nvim
--
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
-- Reference: https://neovim.io/doc/user/fold.html
-- Note: v:lua.vim.treesitter.foldexpr() is the correct Lua API form
-- (replaces the deprecated nvim_treesitter#foldexpr() Vimscript call)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
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
  --
  -- HPC bo_code.R worker fix:
  --   nvimcom's bol.R hardcodes parallel::detectCores() - 2 as the worker
  --   count for its completion database builder, ignoring all R options and
  --   environment variables. On SLURM nodes with --cpus-per-task > 2 this
  --   causes 20+ bo_code.R processes per session.
  --
  --   The build hook below:
  --     1. Copies the patched bol.R from ~/.config/nvim/bol.R (installed
  --        by the installer) into the plugin directory. The patch replaces
  --        parallel::detectCores() - 2 with 1L, capping workers at 1, and
  --        filters installed.packages() to currently loaded libs only.
  --     2. Runs git update-index --assume-unchanged on bol.R so that
  --        lazy.nvim's git status check never sees it as a local
  --        modification blocking future :Lazy sync / :Lazy update calls.
  --   This runs automatically on every :Lazy sync / :Lazy update.
  -- ---------------------------------------------------------
  {
    "R-nvim/R.nvim",
    lazy         = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    build = function()
      local plugin_dir = vim.fn.stdpath("data") .. "/lazy/R.nvim"
      local bol_dst    = plugin_dir .. "/nvimcom/R/bol.R"
      local bol_src    = vim.fn.expand("~/.config/nvim/bol.R")

      -- Deploy the patched bol.R
      if vim.fn.filereadable(bol_src) == 1 then
        vim.fn.system("cp " .. bol_src .. " " .. bol_dst)
        if vim.v.shell_error ~= 0 then
          vim.notify(
            "R.nvim: WARNING — failed to deploy patched bol.R",
            vim.log.levels.WARN
          )
          return
        end
      else
        vim.notify(
          "R.nvim: WARNING — ~/.config/nvim/bol.R not found, skipping patch",
          vim.log.levels.WARN
        )
        return
      end

      -- Mark bol.R as assume-unchanged so lazy.nvim git status never
      -- sees our patched version as a local modification blocking updates.
      vim.fn.system(
        "git -C " .. plugin_dir ..
        " update-index --assume-unchanged nvimcom/R/bol.R"
      )
      if vim.v.shell_error == 0 then
        vim.notify(
          "R.nvim: deployed patched bol.R (bo_code.R workers capped at 1)",
          vim.log.levels.INFO
        )
      else
        vim.notify(
          "R.nvim: WARNING — failed to mark bol.R as assume-unchanged",
          vim.log.levels.WARN
        )
      end
    end,
    config = function()
      require("r").setup({
        R_args           = { "--quiet", "--no-save" },
        min_editor_width = 72,
        rconsole_width   = 78,
        auto_quit        = true,

        -- Limit completion database to base R packages only.
        -- This prevents R.nvim from spawning multiple bo_code.R background
        -- processes to index all installed packages at startup. Users still
        -- get completions for any package after loading it with library().
        start_libs = "base,stats,graphics,grDevices,utils,datasets,methods",

        -- Data frame viewer (\rv) — uses VisiData if installed
        view_df = {
          n_lines  = 0,
          csv_sep  = "\t",
          how      = "tabnew",
          open_app = vim.fn.executable("vd") == 1 and "terminal:vd" or "",
          open_fun = "",
          save_fun = "",
        },

        objbr_auto_start    = false,
        hook = {
          on_filetype = function()
            -- Enter sends line (normal) or selection (visual) to R
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
  --
  -- Repository: https://github.com/jalvesaq/hlterm
  -- ---------------------------------------------------------
  {
    "jalvesaq/hlterm",
    lazy = false,
    config = function()
      vim.g.hlterm_map_send_line      = "<Enter>"
      vim.g.hlterm_map_send_selection = "<Enter>"
    end,
  },

  -- ---------------------------------------------------------
  -- neo-tree.nvim
  -- File browser. Toggle: zz
  --
  -- Repository: https://github.com/nvim-neo-tree/neo-tree.nvim
  -- ---------------------------------------------------------
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
        filtered_items = {
          visible         = false,
          hide_dotfiles   = true,
          hide_gitignored = true,
        },
      },
    },
  },

  -- ---------------------------------------------------------
  -- LuaSnip
  -- Snippet engine. Expands code skeletons for R, Quarto, Rmd.
  -- Snippets are defined in ~/.config/nvim/snippets/
  --
  -- Usage:
  --   Ctrl-Space     trigger completion (snippets appear alongside completions)
  --   Enter          confirm/expand selected snippet
  --   Tab            jump to next placeholder inside expanded snippet
  --   Shift-Tab      jump to previous placeholder
  --
  -- Available snippet triggers:
  --   R files:       for, fun, if, ife, whl, aply, laply, tc, pipe
  --   Quarto/Rmd:    rch, rcho, rchf, pch, bch, call, tabs
  --
  -- Repository: https://github.com/L3MON4D3/LuaSnip
  -- ---------------------------------------------------------
  {
    "L3MON4D3/LuaSnip",
    lazy = false,
    config = function()
      local ls = require("luasnip")

      -- Load snippets from ~/.config/nvim/snippets/
      -- Files are named after filetypes: r.lua, quarto.lua, rmd.lua
      require("luasnip.loaders.from_lua").load({
        paths = { vim.fn.expand("~/.config/nvim/snippets/") }
      })

      -- Tab: jump to next placeholder when inside a snippet
      vim.keymap.set({ "i", "s" }, "<Tab>", function()
        if ls.jumpable(1) then
          ls.jump(1)
        else
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Tab>", true, false, true),
            "n", false
          )
        end
      end, { desc = "LuaSnip: jump to next placeholder" })

      -- Shift-Tab: jump to previous placeholder
      vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
        if ls.jumpable(-1) then ls.jump(-1) end
      end, { desc = "LuaSnip: jump to previous placeholder" })
    end,
  },

  -- ---------------------------------------------------------
  -- nvim-cmp + cmp-nvim-lsp + cmp_luasnip
  -- Auto-completion: LSP completions, buffer words, snippets.
  -- Ctrl-Space: manual trigger
  -- Tab / Shift-Tab: navigate completion list or jump placeholders
  -- Enter: confirm selection or expand snippet
  -- Ctrl-e: dismiss popup
  --
  -- Repository: https://github.com/hrsh7th/nvim-cmp
  -- ---------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    lazy = false,
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp",      lazy = false },
      { "hrsh7th/cmp-buffer",        lazy = false },
      { "saadparwaiz1/cmp_luasnip",  lazy = false },
    },
    config = function()
      local cmp     = require("cmp")
      local cmp_lsp = require("cmp_nvim_lsp")
      local luasnip = require("luasnip")

      -- Tell R.nvim's built-in LSP about nvim-cmp's extra capabilities
      local capabilities = cmp_lsp.default_capabilities()
      vim.lsp.config("*", { capabilities = capabilities })

      cmp.setup({
        snippet = {
          -- Required: tell nvim-cmp which engine to use for expansion
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = false }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.jumpable(1) then
              luasnip.jump(1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"]   = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<C-e>"]     = cmp.mapping.abort(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },  -- R.nvim LSP completions
          { name = "luasnip"  },  -- snippet completions
          { name = "buffer"   },  -- words from current buffer
        }),
      })
    end,
  },

  -- ---------------------------------------------------------
  -- indent-blankline.nvim
  -- Vertical indentation guide lines.
  -- Toggle: Space-i
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
  -- Renders markdown inside Neovim. Toggle: Space-rm
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
  -- Color scheme.
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

-- ---------------------------------------------------------
  -- vim-fugitive
  -- Git integration. Review Claude Code changes with vimdiff.
  --
  -- Key commands:
  --   :Git status           interactive status window (- to stage/unstage)
  --   :Git commit           commit message buffer (ZZ to save and close)
  --   :Gvdiffsplit HEAD~1   side-by-side diff vs previous commit
  --   ]c / [c               jump to next / previous change in diff view
  --   do                    diff obtain — revert hunk to old version
  --   dp                    diff put — push hunk to other side
  --   :diffoff              exit diff mode
  --
  -- Repository: https://github.com/tpope/vim-fugitive
  -- ---------------------------------------------------------
  {
    "tpope/vim-fugitive",
    lazy = false,
  },

  -- ---------------------------------------------------------
  -- claude-code.nvim
  -- Claude Code AI assistant terminal inside Neovim.
  -- Requires Claude Code CLI and a Claude Pro account.
  --
  -- Usage:
  --   :ClaudeCode           open Claude Code terminal split
  --   Ctrl-\ Ctrl-n         exit terminal insert mode
  --
  -- Typical workflow:
  --   1. cd into git repo, make a baseline commit
  --   2. :ClaudeCode → give instruction in plain English
  --   3. Claude edits files directly
  --   4. :Gvdiffsplit HEAD~1 to review changes with fugitive
  --   5. git add -A && :Git commit to accept
  --
  -- Repository: https://github.com/greggh/claude-code.nvim
  -- ---------------------------------------------------------
  {
    "greggh/claude-code.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("claude-code").setup()
    end,
  },

}, {
  install = { colorscheme = { "habamax" } },
  checker = { enabled = false },
  rocks   = { enabled = false },
})


-- ===========================================================
-- SECTION 5: Key mappings
-- ===========================================================

-- Jump between splits with Ctrl-hjkl
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left split"  })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to lower split" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper split" })

-- Exit terminal insert mode with Esc
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Toggle mouse on/off (Space-m)
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
vim.keymap.set("n", "<leader>z", "zM", { desc = "Close all folds" })
vim.keymap.set("n", "<leader>Z", "zR", { desc = "Open all folds" })

-- Toggle auto-completion on/off (Space-c)
vim.keymap.set("n", "<leader>c", function()
  local cmp = require("cmp")
  if cmp.get_config().completion.autocomplete then
    cmp.setup({ completion = { autocomplete = false } })
    print("Completion OFF  (Ctrl-Space still works)")
  else
    cmp.setup({ completion = { autocomplete = {
      require("cmp.types").cmp.TriggerEvent.TextChanged
    }}})
    print("Completion ON")
  end
end, { desc = "Toggle auto-completion" })

-- Auto-set tabstop=20 for R data frame viewer
vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
  pattern = { "*.csv", "*.tsv" },
  callback = function()
    vim.opt_local.tabstop = 20
    vim.opt_local.wrap    = false
  end,
  desc = "Align columns in R data frame viewer",
})

-- Kill orphaned bo_code.R processes on nvim exit.
vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    vim.fn.system("pkill -u " .. vim.fn.expand("$USER") .. " -f bo_code.R")
  end,
  desc = "Kill orphaned bo_code.R processes on nvim exit",
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
--   \cc                    send current chunk (Rmd/Quarto)
--   \ch                    send all chunks above cursor
--   \rh                    R help for word under cursor
--   \ro                    toggle object browser
--   \rv                    view data frame in VisiData
--   Ctrl-Space             trigger completion (insert mode)
--   Tab / Shift-Tab        navigate completion list or jump snippet placeholders
--   Enter                  confirm completion or expand snippet
--   Ctrl-e                 dismiss completion popup
--   Space-c                toggle auto-completion on/off
--   Alt + -                insert <-
--   Alt + ,                insert |>
--   :RMapsDesc             full R.nvim keybinding list
--   :RConfigShow           current R.nvim config
--
-- Snippets (type trigger then Ctrl-Space, select, Enter):
--   R:      for, fun, if, ife, whl, aply, laply, tc, pipe
--   Quarto: rch, rcho, rchf, pch, bch, call, tabs
--   After expanding: Tab / Shift-Tab to jump between placeholders
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
--
-- Folding:
--   Space-z                close all folds
--   Space-Z                open all folds
--   za                     toggle fold under cursor
--   zc / zo                close / open fold under cursor
--
-- Clipboard:
--   yy                     yank line to system clipboard
--   p                      paste from system clipboard
--
-- Plugins:
--   :Lazy                  plugin manager UI
--   :Lazy update           update all plugins
--   :Lazy sync             install + update + clean
--   :checkhealth r         R.nvim health check
--   :checkhealth provider  clipboard/provider check
--   :checkhealth lazy      lazy.nvim health check
-- ===========================================================
