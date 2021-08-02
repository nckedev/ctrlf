-- Features
-- highlighting
--  -closest: green
--  -rest:    blue
--  -no match: gray
--
-- bias search direction (default x bias atm)
-- crash when starting serach with a wildcard.
--
-- DONE smartcase (if search input contains UPPER chars then casesensitive otherwise not
--
-- DONE space as wildcard maybe?
--
-- DONE fix tab confirm (tab to move to next match, s-tab for prev in buffer)
--
-- move to match_pos - 1 (ctrl-t maybe?) good when using with d,y etc
--
local window = require "ctrlf.window"
local opts = require "ctrlf.defaults"
local hints = require "ctrlf.hints"
local buffer = require "ctrlf.buffer"

local KEYS = { confirm = "confirm", backspace = "backspace", cancel = "cancel" }
local DIR = { forward = 1, none = 0, backwards = -1 }


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
end

local function find_string(buf_handle, needle)
	--return list of (row,col) of first character where needle is founqd
	-- test string : key hello world mumbojumbo k ke key "hello world"
	local win = window.get_visible_lines_range()
	local buffer = buffer.get_buf(buf_handle, win.top, win.bottom)
	local matches = {}
	local do_smartcase = false

	if opts.enable_smartcase and not string.match(needle, "%u") then --XXXX
		
		do_smartcase = true
	end
	if opts.enable_wildcard then
		local replace = vim.api.nvim_replace_termcodes(opts.wildcard_key, true, false, true)
		needle = string.gsub(needle, replace, opts.wildcard_magic_string)
	end

	for i,line in ipairs(buffer) do
		if do_smartcase then
			line = string.lower(line)
		end
		local start = 0
		local stop = 0

		while stop ~= nil do
			--should i return stop +1 to, like f does
			start, stop = string.find(line, needle, stop + 1, false)
			if start and stop then
				table.insert(matches, {line = i, start = start - 1, stop = stop })
			end
		end

	end
	--print(vim.inspect(matches))
	return matches
end
--neeeee
local function before_or_after(cur_pos,target)
	local dir = 0

	if cur_pos.row == target.row + window.get_line_offset() then
		-- print(vim.inspect(cur_pos))
		-- print(vim.inspect(target))
		if cur_pos.col > target.col then
			dir =  -1
		elseif cur_pos.col < target.col then
			dir =  1
		else
			dir =  0
		end
	elseif cur_pos.row > target.row + window.get_line_offset() then
		dir =  -1
	elseif cur_pos.row < target.row + window.get_line_offset() then
		dir =  1
	end
	return dir
end


local function jump(target)
	--- expects target pos relative to window { row= , col= }
	-- register current pos berfore jumping
	-- to add it to the jumplist
	if opts.enable_jumplist then
		vim.cmd("normal! m'")
	end
	-- check direction
	local dir = 0
	local cur_pos = window.get_cursor_pos()

	dir = before_or_after(cur_pos, target)
	vim.api.nvim_win_set_cursor(window, { target.row + window.get_line_offset(), target.col } )
	-- print(vim.inspect(target))
	return dir
end


local function closest_match(matches, direction, x_bias, y_bias)
	--returnd (row, col) of the closest (manhattan distance)  match
	--prioritize same line?
	-- direction -1 for backwards, 0 for both ways and 1 for forward
	-- abs(x1 -x2) + abs(y1 - y2)

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

local function save_current_state(needle, direction, match_list, active)
	vim.w.ctrlf_needle = needle
	vim.w.ctrlf_dir = direction
	vim.w.ctrlf_matches = match_list
	vim.w.ctrlf_offset = window.get_line_offset()
	vim.w.ctrlf_active = active or false
end

local function ctrlf_next(reverse)
	local reverse = reverse or false  -- reverse the direction true, false
	local dir = vim.w.ctrlf_dir -- the direction the search was first jumped
	local matches = vim.w.ctrlf_matches
	local cur_pos = window.get_cursor_pos()

	if vim.w.ctrlf_offset ~= window.get_line_offset() then
		-- we should do a new search to include every line on screen
		print("offset has changed")
	end

	if not dir or not matches then
		print("no search to repeat")
		return
	end
	if reverse then
		dir = dir * -1
	end

	if dir == DIR.forward then
		for i, v in ipairs(matches) do
			local target = { row = v.line, col = v.start }
			if before_or_after(cur_pos, target ) > 0 then
				jump( target )
				break
			end
		end
	elseif dir == DIR.backwards then
		for i = #matches, 1, -1 do
			local target = { row = matches[i].line, col = matches[i].start }
			if before_or_after(cur_pos, target) < 0 then
				jump(target)
				break
			end
		end
	end
end

local function ctrlf()
	--local pos = window.get_cursor_pos()
	local buf_handle = buffer.get_buf_nr()
	--local buffer = get_buf(buf_handle, pos.row, pos.row +1)

	local needle = ""
	local special_key = false
	local cancel = false
	local matches = " "
	local ns_id = hints.create_namespace("cfns")
	local closest = {}

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
			elseif key == 27 then
				cancel = true
				break
			end
			--elseif key is in hints
			key = vim.fn.nr2char(key)
		elseif key:byte() == 128 then
			special_key = true
		end

		if not special_key and key then
			needle = needle .. key
		elseif special_key then
			if string.sub(key,2) == "kb" then
				needle = string.sub(needle, 1, #needle - 1)
			else
				vim.api.nvim_feedkeys(key, '', true) -- ???
				break
			end
		end
		--if needle ~= "" and needle ~= opts.wildcard_key then
		if needle ~= "" and needle ~= vim.api.nvim_replace_termcodes(opts.wildcard_key, true, false, true) then
			matches = find_string(buf_handle, needle)
			--create namespace
			--create hints 
			hints.clear_hints(ns_id)
			closest = closest_match(matches)
			hints.create_hints(0, ns_id, matches, closest)
			vim.api.nvim_command("redraw")
			
			--apply colors
		end
	end
	--clear namespace color hints
	hints.clear_hints(ns_id)

	if #matches > 0 and not cancel then
		closest = closest_match(matches)
		local dir = jump(closest)
		save_current_state(needle, dir, matches, true)
	else
		print("no matches")
		--vim.api.nvim_input("<cr>")
	end
end
return {
	ctrlf = ctrlf,
	ctrlf_next = ctrlf_next
}
--asd
