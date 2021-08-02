local opts = require "ctrlf.defaults"
local window = require "ctrlf.window"
local M = {}
--XX
--vim.api.nvim_buf_set_text(buffer, start_row, start_row, end_row, end_col, replace)
--vim.api.nvim_buf_add_highlight(buffer,nsid,hlgrp,line,colstart,colend)
--namespace

function M.generate_unique_hints(matches)
	-- create unique table of char or char-pairs depending on how many matches
	-- they have to be unique from each other (pairs can have same chars ("aa" and "ab" is considered unique))
	-- they also have to be unique from from the next char or chars right after the maching string
	-- so if i have a string "hello world" and search for "hel" the hint char cant be an "l" or if
	-- two chars is needed they cant start with "l"
	-- hints have to be updateded after every search char entered to guarantee that the hint char is different
	-- from the next char in the buffer.
	local hintchars = opts.hint_chars

end

--- create namespace, returns id
function M.create_namespace(name)
	return vim.api.nvim_create_namespace(name)
end

function M.create_hints(bufnr, ns_id, matches_loc, closest)
	--vim.api.nvim_buf_set_extmark(0, hl_ns, hint.line, hint.col - 1, { virt_text = { { hint.hint, "HopNextKey" } }; virt_text_pos = 'overlay' })
	--nvim_buf_set_extmark({buffer}, {ns_id}, {line}, {col}, {opts})
	--RedrawDebugRecompose
	--nvim_buf_add_highlight({buffer}, {ns_id}, {hl_group}, {line}, {col_start}, {col_end})

	local cursor_pos = window.get_cursor_pos()
	local offset = window.get_line_offset()
	for _, v in pairs(matches_loc) do
		if cursor_pos.row == v.line - 1 and cursor_pos.col == v.start then 
		end

		if closest.row == v.line and closest.col == v.start then
			vim.api.nvim_buf_add_highlight(bufnr, ns_id, "DiffAdd", v.line -1 + offset, v.start, v.stop)
		else
			vim.api.nvim_buf_add_highlight(bufnr, ns_id, "DiffText", v.line -1 + offset, v.start, v.stop)
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, v.line - 1 + offset , v.start, { virt_text = { {"X", "DiffAdd" }}; virt_text_pos = 'overlay' })
		end
	end
end

function M.clear_hints(ns_id)
	vim.api.nvim_buf_clear_namespace(0, ns_id,0,-1)
	--vim.api.nvim_buf_clear_highlight()
end
return M

