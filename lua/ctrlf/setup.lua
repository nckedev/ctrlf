local config = {
	hint_chars = "jfkdhglsrtyui",
	quit_keys = { "<esc>" },
	enable = true,
	enable_hints = true,
	enable_smartcase = true,
	enable_wildcard = true,
	jump_keys_closest = { "<cr>", "<tab>" },
	jump_next_keys = { "<tab>" },
	wildcard_key = "<space>",
	search_direction = "both", --forward, backwards, both
	enable_gray_background = true,
	wildcard_magic_string = ".?", --lua magic regex + * ? -
	enable_jumplist = true,
}

local M = {}

--- @param args table
M.setup = function(args)
	print("setup")
	M.config = vim.tbl_deep_extend("force", config, args or {})
end

return M
