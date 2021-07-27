--vim.api.nvim_buf_set_text(buffer, start_row, start_row, end_row, end_col, replace)
--vim.api.nvim_buf_add_highlight(buffer,nsid,hlgrp,line,colstart,colend)
--namespace
--disable keymaps? no need with getchar, consumes all input
local function get_cursor_pos()
	local p = vim.api.nvim_win_get_cursor(0)
	local pos = { x = p[1], y = p[2] }
	return pos
end

local function get_buf(nr, start, stop)
	nr = nr or 0
	start = start or 0
	stop = stop or -1
	return vim.api.nvim_buf_get_lines(nr, start, stop, false)
end

local function get_visible_lines_range(window)
	window = window or vim.api.nvim_get_current_win()
	local win_info = vim.fn.getwininfo(window)[1]
	local win = { top = win_info.topline,  bottom = win_info.botline }
	return win
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

local function find(needle, haystack)
	--return list of (row,col) of first character where needle is founqd
end
local function jump(win, target)
	win = win or 0

	-- register current pos berfore jumping
	-- to add it to the jumplist
    vim.cmd("normal! m'")
	vim.api.nvim_win_set_cursor(win, target)
end

local function ctrlf()
	local pos = get_cursor_pos()
	local bufnr = get_buf_nr()
	local buffer = get_buf(bufnr, pos.x, pos.x +1)
	--print(get_input_wo_prompt())
	--local s = get_input("Search > ")
	-- print('\r\n' .. s)
	-- print(pos.x .. " " .. pos.y)
	-- for k,v in pairs(buffer) do
	-- 	print(k .. " " .. v)
	-- end

	local needle = ""
	while 1 do
		local t = get_input_wo_prompt()
		if type(t) == "string" then
			needle = needle .. t
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
				break
			end
		end
	end
	print(needle)
end

return {
	ctrlf = ctrlf
}

