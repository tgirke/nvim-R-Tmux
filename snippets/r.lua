-- ~/.config/nvim/snippets/r.lua
-- LuaSnip snippets for R scripts (.R files)
-- Trigger with Ctrl-Space, select with Enter
-- Jump between placeholders with Tab / Shift-Tab

local ls  = require("luasnip")
local s   = ls.snippet
local t   = ls.text_node
local i   = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {

  -- for loop
  -- Expands: for (var in iterable) { body }
  s("for", fmt([[
for ({var} in {iter}) {{
    {body}
}}]], {
    var  = i(1, "i"),
    iter = i(2, "seq_along(x)"),
    body = i(3, ""),
  })),

  -- function definition
  -- Expands: name <- function(args) { body }
  s("fun", fmt([[
{name} <- function({args}) {{
    {body}
}}]], {
    name = i(1, "my_fun"),
    args = i(2, "x"),
    body = i(3, ""),
  })),

  -- if/else
  -- Expands: if (cond) { } else { }
  s("if", fmt([[
if ({cond}) {{
    {if_body}
}} else {{
    {else_body}
}}]], {
    cond      = i(1, "condition"),
    if_body   = i(2, ""),
    else_body = i(3, ""),
  })),

  -- if / else if / else
  s("ife", fmt([[
if ({cond1}) {{
    {body1}
}} else if ({cond2}) {{
    {body2}
}} else {{
    {body3}
}}]], {
    cond1 = i(1, "condition1"),
    body1 = i(2, ""),
    cond2 = i(3, "condition2"),
    body2 = i(4, ""),
    body3 = i(5, ""),
  })),

  -- while loop
  s("whl", fmt([[
while ({cond}) {{
    {body}
}}]], {
    cond = i(1, "condition"),
    body = i(2, ""),
  })),

  -- sapply
  s("aply", fmt([[
{result} <- sapply({vec}, function({var}) {{
    {body}
}})]], {
    result = i(1, "result"),
    vec    = i(2, "x"),
    var    = i(3, "x"),
    body   = i(4, ""),
  })),

  -- lapply
  s("laply", fmt([[
{result} <- lapply({vec}, function({var}) {{
    {body}
}})]], {
    result = i(1, "result"),
    vec    = i(2, "x"),
    var    = i(3, "x"),
    body   = i(4, ""),
  })),

  -- tryCatch
  s("tc", fmt([[
tryCatch({{
    {try_body}
}}, error = function(e) {{
    {err_body}
}})]], {
    try_body = i(1, ""),
    err_body = i(2, 'message("Error: ", e$message)'),
  })),

  -- pipe chain (base R |>)
  s("pipe", fmt([[
{obj} |>
    {fn1}() |>
    {fn2}()]], {
    obj = i(1, "x"),
    fn1 = i(2, "filter"),
    fn2 = i(3, "summarise"),
  })),

}
