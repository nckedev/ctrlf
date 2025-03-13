-- local opts = require "ctrlf.defaults"
--
local window = require "ctrlf.window"
local buffer = require "ctrlf.buffer"
local M = {}
--XX
--vim.api.nvim_buf_set_text(buffer, start_row, start_row, end_row, end_col, replace)
--vim.api.nvim_buf_add_highlight(buffer,nsid,hlgrp,line,colstart,colend)
--namespace

---@param matches Span[]
---@param opts Options
---@return string[] # viable hint characters
local function generate_unique_hints(matches, opts)
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
	---@type table<string, boolean>
	local banned_chars = {}
	local s = ""
	---@type string[]
	local valid_chars = {}
	for _, v in pairs(matches) do
		s = string.sub(buf[v.line], v.stop + 1, v.stop + 1)
		banned_chars[s] = true
		-- table.insert(banned_chars, s)
	end
	for i = 1, hintchars:len(), 1 do
		local s = string.sub(hintchars, i, i)
		if not banned_chars[s] then
			table.insert(valid_chars, s)
		end
	end
	assert(#valid_chars > 0, "no valid chars left")
	return valid_chars
end


--- create namespace, returns id
M.create_namespace = function(name)
	return vim.api.nvim_create_namespace(name)
end
---comment
---@param bufnr integer
---@param ns_id integer
---@param matches_loc {line : integer, start: integer, stop: integer} | nil
---@param closest {row: integer, col : integer}
---@param opts Options
---@return HintChar
function M.create_hints(bufnr, ns_id, matches_loc, closest, opts)
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
	hint_chars = generate_unique_hints(matches_loc or {}, opts)
	--print(#hint_chars , #matches_loc)

	if opts.enable_gray_background then
		for line = win.top, win.bottom, 1 do
			vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Comment", line, 0, -1)
		end
	end

	--TODO: create custom hl groups, and make them overridable from config
	--vim.api.nvim_set_hl(ns_id, name, val)

	for i, v in ipairs(matches_loc or {}) do
		-- if cursor_pos.row == v.line - 1 and cursor_pos.col == v.start then
		-- 	end
		if closest.row == v.line and closest.col == v.start then
			vim.api.nvim_buf_add_highlight(bufnr, ns_id, "CtrlfMatchClosest", v.line - 1 + offset, v.start, v.stop)
		else
			vim.api.nvim_buf_add_highlight(bufnr, ns_id, "CtrlfMatch", v.line - 1 + offset, v.start, v.stop)
			-- TODO: if there is no enough hint char just create for the closest matches
			if #hint_chars >= #matches_loc and opts.enable_hints then
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, v.line - 1 + offset, v.start,
					{ virt_text = { { hint_chars[i], "CtrlfHintChar" } }, virt_text_pos = 'overlay' })
				table.insert(hint_char_with_loc, { char = hint_chars[i], row = v.line - 1 + offset, col = v.start })
			end
		end
	end
	-- print (vim.inspect(hint_char_with_loc))
	return hint_char_with_loc
end

---comment
---@param ns_id integer
---@param opts Options
function M.create_hl_grups(ns_id, opts)
	-- prio
	-- 1 config
	-- 2 color theme
	-- 3 defaults
end

local function create_from_config_or_colorscheme(name, o)

end
---creates a search box
---@param bufnr integer
---@param ns_id integer
---@param search_string string
---@param opts Options
function M.create_searchbox(bufnr, ns_id, search_string, opts)
	local hl_search_box = "CtrlfSearchbox"
	local row_offset = 0
	local col_offset = 0

	if opts.searchbox == "none" then
		return
	elseif opts.searchbox == "cursor_after" then
		row_offset = 0
		col_offset = 1
	elseif opts.searchbox == "cursor_above" then
		row_offset = -1
	elseif opts.searchbox == "cursor_under" then
		row_offset = 1
	end

	local function format_box(str)
		local diff = (opts.searchbox_size or 0) - #str
		if diff > 0 then
			return search_string .. string.rep(" ", diff)
		end
		return str
	end

	local cursor_pos = window.get_cursor_pos()
	local offset = window.get_line_offset()

	assert(window.get_visible_lines_range().top <= cursor_pos.row + row_offset - 1,
		"cursor index " .. cursor_pos.row + row_offset .. " too small")
	assert(window.get_visible_lines_range().bottom >= cursor_pos.row + row_offset - 1, "cursor index too big")

	-- vim.api.nvim_buf_set_extmark(bufnr, ns_id, cursor_pos.row + row_offset - 1, cursor_pos.col + col_offset,
	-- 	{ virt_text = { { search_string .. " ", "CtrlfHintChar" } }, virt_text_pos = 'overlay', strict = false })

	-- TODO: textboxen hamnar inte på rätt plats för rader med mer än 0 tecken
	vim.api.nvim_buf_set_extmark(bufnr, ns_id, cursor_pos.row + row_offset - 1, 0, -- cursor_pos.col + col_offset,
		{ virt_text = { { format_box(search_string), hl_search_box } }, virt_text_win_col = cursor_pos.col + col_offset, strict = true })
end

function M.clear_hints(ns_id)
	vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
	--vim.api.nvim_buf_clear_highlight()
end

return M
