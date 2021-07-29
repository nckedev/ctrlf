-- Features
-- highlighting
--  -closest: green
--  -rest:    blue
--  -no match: gray
-- bias search direction (default x bias atm)
-- smartcase (if search input contains UPPER chars then casesensitive otherwise not
-- ignore wierd chars like _.{([ etc for faster typing (maybe replace with space)
-- fix tab confirm (tab repeat search)
--
--
--vim.api.nvim_buf_set_text(buffer, start_row, start_row, end_row, end_col, replace)
--vim.api.nvim_buf_add_highlight(buffer,nsid,hlgrp,line,colstart,colend)
--namespace
--disable keymaps? no need with getchar, consumes all input

local window = require "window"

local function get_buf(nr, start, stop)
	nr = nr or 0
	start = start or 0
	stop = stop or -1

	--0 based indexing, stop - 1 aswell?
	return vim.api.nvim_buf_get_lines(nr, start - 1, stop, false)
end


local function get_buf_nr()
	local bufnr = vim.api.nvim_get_current_buf()
	return bufnr
end

local function get_input(prompt)
	prompt = prompt or "> "
	local inp = vim.fn.input(prompt)
	return inp
end

local function get_input_wo_prompt()
	-- esc = 27
	-- space = 32
	-- enter = 13
	-- backspace = ?
	-- if escape cancel seach
	-- if space or enter jump to closest match (manhattan distance?)
	-- if hits pressed then jump
	local s = ""
	local cancel = -1
	local backspace = -2
	local ok, key = pcall(vim.fn.getchar)
	if not ok then
		--clear hl
		return cancel
	end
	if type(key) == "number" then
		if (key == 27) then
			return cancel
		elseif (key == 13 or key == 32) then
			return 1
		end
		key = vim.fn.nr2char(key)
		return key
	elseif key:byte() == 128 then
		local special_key = string.sub(key,2)
		if special_key == "kb" then
			print ("backpace")
			return backspace
			--s = string.sub(s,1, #s -1)
		else
			return -1
		end
	end
	return 0
	--return "("..s:gsub('[%c]','') .. ")"
	--return s:gsub('[%c]','')
end


local function hint(buffer)
	local hint_keys = "fjghdkslaörutyvnbmcireowpqåc,x.z-"
end

local function clear_hints()
end

local function find(buf_handle, needle)
	--return list of (row,col) of first character where needle is founqd
	-- test string : key hello world mumbojumbo k ke key "hello world"
	local win = window.get_visible_lines_range()
	local buffer = get_buf(buf_handle, win.top, win.bottom)
	local matches = {}
	for i,line in ipairs(buffer) do
		local len = #line
		local start = 0
		local stop = 0
		while stop ~= nil do
			start, stop = string.find(line, needle, stop, true)
			if start and stop then
				table.insert(matches, {line=i, start=start - 1, stop=stop })
			end
		end

	end
	--print(vim.inspect(matches))
	return matches
end

local function jump(target)
	local window = vim.api.nvim_get_current_win()
	local win_info = vim.fn.getwininfo(window)[1]
	-- register current pos berfore jumping
	-- to add it to the jumplist
    vim.cmd("normal! m'")

	vim.api.nvim_win_set_cursor(window, {target.row + win_info.topline - 1, target.col})
	-- print(vim.inspect(target))
end


local function closest_match(matches, direction, x_bias, y_bias)
	--returnd (row, col) of the closest (manhattan distance)  match
	--prioritize same line?
	-- direction -1 for backwards, 0 for both ways and 1 for forward
	-- abs(x1 -x2) + abs(y1 - y2)

	-- TODO implement direction
	if not matches then
		return 
	end
	local dir = direction or 0
	local x_b = x_bias or 10
	local y_b = y_bias or 1
	local pos = window.get_cursor_pos()
	local min = 99999999
	local best = 0

	print("matches: " .. #matches)

	for _,v in pairs(matches) do
		local candidate = x_b * math.abs(pos.row - (v.line + window.get_line_offset())) + y_b * math.abs(pos.col - v.start)
		if candidate < min then
			min = candidate
			best = { row = v.line, col = v.start }
		end
end
	return best
end


local function ctrlf()
	local pos = window.get_cursor_pos()
	local buf_handle = get_buf_nr()
	local buffer = get_buf(buf_handle, pos.row, pos.row +1)

	local needle = ""
	for i=1, 1000 do
		local t = get_input_wo_prompt()
		if type(t) == "string" then
			needle = needle .. t
			-- print(needle)
		elseif type(t) == "number" then
			if t == -2 then
				--backspace
				needle = string.sub(needle,1, #needle -1)
			elseif t == -1 then
				--cancel search
				needle = ""
				break
			elseif t == 1 then
				--confirm
				-- vim.api.nvim_input("<cr>")
				break
			else
				break
			end
		end
	end
	--print(vim.inspect(find(buf_handle, needle)))
	local matches = find(buf_handle, needle)
	if #matches > 0 then
		local a = closest_match(matches)
		jump(a)
	else
		print("no matches")
	--vim.api.nvim_input("<cr>")
	end
end

return {
	ctrlf = ctrlf
}
--asd
