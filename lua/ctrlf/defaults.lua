local M = {}

M.hint_chars = "jfkdhglsrtyui"
M.quit_keys = { "<esc>" }
M.enable_hints = true
M.enable_smartcase = true
M.enable_wildcard = true
M.jump_keys = { "<cr>", "<tab>" }
M.jump_next_keys = { "<tab>" }
M.wildcard_key = "<space>"
M.search_direction = "both" --forward, backwards, both
M.enable_gray_background = true
M.wildcard_magic_string = ".?"
M.enable_jumplist = true


return M
