local opts = require "ctrlf.defaults"
local window = require "ctrlf.window"
local buffer = require "ctrlf.buffer"
local M = {}
--XX
--vim.api.nvim_buf_set_text(buffer, start_row, start_row, end_row, end_col, replace)
--vim.api.nvim_buf_add_highlight(buffer,nsid,hlgrp,line,colstart,colend)
--namespace

local function generate_unique_hints(matches)
	-- create unique table of char or char-pairs depending on how many matches
	-- they have to be unique from each other (pairs can have same chars ("aa" and "ab" is considered unique))
	-- they also have to be unique from from the next char or chars right after the maching string
	-- so if i have a string "hello world" and search for "hel" the hint char cant be an "l" or if
	-- two chars is needed they cant start with "l"
	-- hints have to be updateded after every search char entered to guarantee that the hint char is different
	-- from the next char in the buffer.
	--
	-- TODO return table with hint linked to the location
	local hintchars = opts.hint_chars
	local buf = buffer.get_buf()
	local banned_chars = {} --k: character, v: bool
	local s = ""
	local valid_chars = {}
	for _, v in pairs(matches) do
		s = string.sub(buf[v.line], v.stop + 1, v.stop + 1)
		banned_chars[s] = true
		-- table.insert(banned_chars, s)
	end
	for  i= 1, hintchars:len(),1 do
		local s = string.sub(hintchars, i ,i )
		if not banned_chars[s] then
			table.insert(valid_chars, s)
		end
	end
	return valid_chars
end

--- create namespace, returns id
M.create_namespace = function(name)
	return vim.api.nvim_create_namespace(name)
end
function M.create_hints(bufnr, ns_id, matches_loc, closest)
	--vim.api.nvim_buf_set_extmark(0, hl_ns, hint.line, hint.col - 1, { virt_text = { { hint.hint, "HopNextKey" } }; virt_text_pos = 'overlay' })
	--nvim_buf_set_extmark({buffer}, {ns_id}, {line}, {col}, {opts})
	--RedrawDebugRecompose
	--nvim_buf_add_highlight({buffer}, {ns_id}, {hl_group}, {line}, {col_start}, {col_end})
	--
	local cursor_pos = window.get_cursor_pos()
	local offset = window.get_line_offset()
	local win = window.get_visible_lines_range()
	local hint_chars = {}
	local hint_char_with_loc = {} --  k: char v: {row, col}
	hint_chars = generate_unique_hints(matches_loc)
	--print(#hint_chars , #matches_loc)

	if opts.enable_gray_background then
		for line = win.top, win.bottom, 1 do
			vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Comment",line, 0 , -1)
		end
	end

	for i, v in ipairs(matches_loc) do
	-- if cursor_pos.row == v.line - 1 and cursor_pos.col == v.start then
	-- 	end
		if closest.row == v.line and closest.col == v.start then
			vim.api.nvim_buf_add_highlight(bufnr, ns_id, "DiffAdd", v.line -1 + offset, v.start, v.stop)
		else
			vim.api.nvim_buf_add_highlight(bufnr, ns_id, "DiffText", v.line -1 + offset, v.start, v.stop)
			if #hint_chars >= #matches_loc then
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, v.line - 1 + offset , v.start, { virt_text = { {hint_chars[i], "DiffAdd" }}; virt_text_pos = 'overlay' })
				table.insert(hint_char_with_loc,  { char=hint_chars[i], row = v.line - 1 + offset, col = v.start})

			end
		end
	end
	-- print (vim.inspect(hint_char_with_loc))
	return hint_char_with_loc
end

function M.clear_hints(ns_id)
	vim.api.nvim_buf_clear_namespace(0, ns_id,0,-1)
	--vim.api.nvim_buf_clear_highlight()
end
return M

