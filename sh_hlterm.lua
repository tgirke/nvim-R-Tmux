-- Override hlterm's sh ftplugin to use bash --login instead of sh
-- so ~/.bashrc is sourced and the user's normal prompt appears.
--
-- Full options table copied from hlterm/ftplugin/sh_hlterm.lua
-- with only "app" changed from "sh" to "bash --login".
-- All other fields kept identical to avoid missing field errors.
--
-- This file lives in ~/.config/nvim/after/ftplugin/sh_hlterm.lua
-- and is loaded after hlterm's own ftplugin/sh_hlterm.lua.

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
