-- ~/.config/nvim/snippets/quarto.lua
-- LuaSnip snippets for Quarto (.qmd) and R Markdown (.Rmd) files
-- Trigger with Ctrl-Space, select with Enter
-- Jump between placeholders with Tab / Shift-Tab
--
-- Note: this same file is loaded for both quarto and rmd filetypes.
-- The installer symlinks or copies it for both.

local ls  = require("luasnip")
local s   = ls.snippet
local t   = ls.text_node
local i   = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {

  -- Basic R code chunk
  s("rch", fmt([[
```{{r {label}}}
{body}
```]], {
    label = i(1, "chunk-label"),
    body  = i(2, ""),
  })),

  -- R code chunk with common quarto options
  s("rcho", fmt([[
```{{r {label}}}
#| eval: {eval}
#| echo: {echo}
#| warning: {warning}
{body}
```]], {
    label   = i(1, "chunk-label"),
    eval    = i(2, "true"),
    echo    = i(3, "true"),
    warning = i(4, "false"),
    body    = i(5, ""),
  })),

  -- R code chunk with figure options
  s("rchf", fmt([[
```{{r {label}}}
#| fig-cap: "{caption}"
#| fig-width: {width}
#| fig-height: {height}
{body}
```]], {
    label   = i(1, "fig-label"),
    caption = i(2, "Figure caption"),
    width   = i(3, "8"),
    height  = i(4, "6"),
    body    = i(5, ""),
  })),

  -- Python code chunk
  s("pch", fmt([[
```{{python {label}}}
{body}
```]], {
    label = i(1, "chunk-label"),
    body  = i(2, ""),
  })),

  -- Bash code chunk
  s("bch", fmt([[
```{{bash}}
{body}
```]], {
    body = i(1, ""),
  })),

  -- Quarto callout block (note/warning/tip/important)
  s("call", fmt([[
::: {{.callout-{type}}}
## {title}
{body}
:::]], {
    type  = i(1, "note"),
    title = i(2, "Title"),
    body  = i(3, ""),
  })),

  -- Quarto tabset
  s("tabs", fmt([[
::: {{.panel-tabset}}
## {tab1}
{body1}

## {tab2}
{body2}
:::]], {
    tab1  = i(1, "Tab 1"),
    body1 = i(2, ""),
    tab2  = i(3, "Tab 2"),
    body2 = i(4, ""),
  })),

}
