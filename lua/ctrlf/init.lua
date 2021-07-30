-- Features
-- highlighting
--  -closest: green
--  -rest:    blue
--  -no match: gray
--
-- bias search direction (default x bias atm)
--
-- smartcase (if search input contains UPPER chars then casesensitive otherwise not
--
-- ignore wierd chars like _.{([ etc for faster typing 
-- 		space as wildcard maybe?
--
-- fix tab confirm (tab to move to next match, s-tab for prev in buffer)
--
-- move to match_pos - 1 (ctrl-t maybe?) good when using with d,y etc
--
--vim.api.nvim_buf_set_text(buffer, start_row, start_row, end_row, end_col, replace)
--vim.api.nvim_buf_add_highlight(buffer,nsid,hlgrp,line,colstart,colend)
--namespace

local window = require "window"
local opts = require "defaults"
local keys = { confirm = "confirm", backspace = "backspace", cancel = "cancel" }

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
	-- tab = 9
	-- 33 to 126 = valid chars
	-- if escape cancel seach
	-- if space or enter jump to closest match (manhattan distance?)
	-- if hits pressed then jump
	-- TODO bricks when press esc wo any other input?	
	local ok, key = pcall(vim.fn.getchar)
	if not ok then
		--clear hl
		print ("some sort of error in get_input_wo_prompt")
		return keys.cancel
	end
	print("...." .. key)
	if type(key) == "number" then
		if (key == 27) then
			print("escape 27")
			return keys.cancel
		elseif (key == 13 or key == 32 or key == 9) then
			return keys.confirm
		else
			return vim.fn.nr2char(key)
		end
	elseif key:byte() >= 128 then
		if key == vim.api.nvim_replace_termcodes("<backspace>",true, false, true) then
			print("backspace")
			return keys.backspace
			-- local special_key = string.sub(key,2)
			-- if special_key == "kb" then
			-- 	print ("backpace")
			-- 	return keys.backspace
			--s = string.sub(s,1, #s -1)
		else 
			return keys.cancel
		end
	else
		return 0
	end
	--return "("..s:gsub('[%c]','') .. ")"
	--return s:gsub('[%c]','')
end

local function find(buf_handle, needle)
	--return list of (row,col) of first character where needle is founqd
	-- test string : key hello world mumbojumbo k ke key "hello world"
	local win = window.get_visible_lines_range()
	local buffer = get_buf(buf_handle, win.top, win.bottom)
	local matches = {}
	if opts.enable_wildcard then
		local replace = vim.api.nvim_replace_termcodes(opts.wildcard_key,true,false,true)
		needle = string.gsub(needle, replace, ".")
	end

	for i,line in ipairs(buffer) do
		local len = #line
		local start = 0
		local stop = 0
		while stop ~= nil do
			start, stop = string.find(line, needle, stop, false)
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

	-- print("matches: " .. #matches)

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
	local special_key = false
	local cancel = false
	while 1 do
		--elseif key is in hints
		special_key = false
		local ok, key = pcall(vim.fn.getchar)
		if not ok then
			print("error")
		end

		if type(key) == "number" then
			if key == 9 or key == 13 then 
				break
			else if key == 27 then
				cancel = true
				break
			end
			--elseif key is in hints
		end
		key = vim.fn.nr2char(key)
		elseif key:byte() == 128 then
			print(#key)
			special_key = true
		end

		if not special_key and key then
			needle = needle .. key
		elseif special_key then
			if string.sub(key,2) == "kb" then
				needle = string.sub(needle, 1, #needle - 1)
				print(needle)
			else
				--vim.api.nvim_feedkeys(key, '', true)
				key = nil
				break
			end
		end
	end


	local matches = ""
	if #needle > 0 then
		print(needle)
		matches = find(buf_handle, needle)
	end
	-- local matches = ""
	if #matches > 0 and not cancel then
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
