local window = require "ctrlf.window"

local M = {}
function M.get_buf(nr)
	nr = nr or 0
	local win = window.get_visible_lines_range()
	return vim.api.nvim_buf_get_lines(nr, win.top - 1, win.bottom, false)
end


function M.get_buf_nr()
	local bufnr = vim.api.nvim_get_current_buf()
	return bufnr
end

return M
