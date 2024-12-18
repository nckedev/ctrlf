---@type Options
local config = {
    --- characters that are availible as hints
    hint_chars = "jfkdhglsrtyui",

    --- exit from searching
    quit_keys = { "<esc>" },
    --- whether or not the plugin should be enabled
    enabled = true,
    enable_hints = true,

    -- requires that expandtab is enabled
    searchbox = "none",
    searchbox_match_count = true,
    searchbox_size = 5,

    --- ignores case when there is no uppercase letters in the serach term
    enable_smartcase = true,
    enable_wildcard = true,
    jump_keys_closest = { "<cr>", "<tab>" },
    jump_keys_next = { "<tab>" },
    wildcard_key = "<space>",

    --- the direction to serach in
    search_direction = "both",

    --- makes all text gray when searching
    enable_gray_background = false,

    --- a regex string for how the wildcard should behave
    --- defaults to .? (any character once)
    wildcard_magic_string = ".?", --lua magic regex + * ? -

    --- saves the jumps in the jumplist
    enable_jumplist = true,
    colors = { hint_char = "DiffDelete", match = "DiffChange", closest_match = "DiffAdd" }
}

local M = {}

--- @param args Options | nil
M.setup = function(args)
    local opts = vim.tbl_deep_extend("force", config, args or {})
    vim.api.nvim_create_user_command("Ctrlf", function() require("ctrlf.init_t").ctrlf(opts) end, { bang = true })
    vim.api.nvim_create_user_command("CtrlfPrev", function() require("ctrlf.init_t").ctrlf_next(false, opts) end,
        { bang = true })
    vim.api.nvim_create_user_command("CtrlfNext", function() require("ctrlf.init_t").ctrlf_next(true, opts) end,
        { bang = true })
end

return M
