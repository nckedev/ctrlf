local M = {}

function M.test()
	return "test"
end

---@return table
function M.get_cursor_pos()
	local p = vim.api.nvim_win_get_cursor(0)
	local pos = { row = p[1], col = p[2] }
	return pos
end

---@param window integer | nil
---@return table
function M.get_visible_lines_range(window)
	window = window or vim.api.nvim_get_current_win()
	local win_info = vim.fn.getwininfo(window)[1]
	local win = { top = win_info.topline, bottom = win_info.botline }
	return win
end

---@return integer
function M.get_line_offset()
	local window = vim.api.nvim_get_current_win()
	local win_info = vim.fn.getwininfo(window)[1]
	return win_info.topline - 1
end

return M
