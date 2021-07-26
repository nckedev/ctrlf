
local function get_cursor_pos()
	local x = vim.fn.getpos('.')
	--buff, row, col, offset?
	return x
end
local function get_buf(nr, start, stop) 
	local buffer = vim.api.nvim_buf_get_lines(nr,start,stop, false)
	return buffer
end

local function get_visible_lines_range(window)
	--return linenr at the top and bottom 
	local window_height = vim.fn.winheight(0)
	return window_height
end
local function get_buf_nr()
	local bufnr = vim.api.nvim_get_current_buf()
	return bufnr
end

local function ctrlf()
	local pos = get_cursor_pos()
	local bufnr = get_buf_nr()
	local buffer= get_buf(bufnr, pos[2], pos[2]+1)
	print(pos[2])
	for k,v in pairs(buffer) do
		print(k .. " " .. v)
	end

	print(get_visible_lines_range(0))
end

return {
	ctrlf = ctrlf
}

--vim.api.nvim_buf_add_highlight(buffer,nsid,hlgrp,line,colstart,colend)
