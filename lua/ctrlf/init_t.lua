-- Features
--
-- bias search direction (default x bias atm)
--
-- maybe find_string should return next char, for easier acces when generating hints.
--
-- move to match_pos - 1 (ctrl-t maybe?) good when using with d,y etc
--
-- make a hint for the last char of the word so you can jump to start or end of target
--
-- standardize when using with offset or not
--      maybe a class for Coord, with row, col/start, end, local or window offset
--
-- set config table from vimrc
--
-- hint and jump to all open windows


local window = require("ctrlf.window")
local hints = require("ctrlf.hints")
local buffer = require("ctrlf.buffer")


--- @enum
local DIR = { forward = 1, none = 0, backwards = -1 }

local function get_input(prompt)
    prompt = prompt or "> "
    local inp = vim.fn.input(prompt)
    return inp
end

---@param loc Span
---@param opts Options
---@return integer
local function distance_from_cursor(loc, opts)
    local cursor = window.get_cursor_pos()
    local dir = 1
    local x_b = 10
    local y_b = 1
    local same_line_b = 100
    local offset = window.get_line_offset()
    if cursor.row < loc.line + offset or cursor.col < loc.start then
        dir = -1
    end

    local distance = (x_b * math.abs(cursor.row - (loc.line + offset)) + y_b * math.abs(cursor.col - loc.start)) * dir

    return distance
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

---@param buf_handle integer
---@param needle string
---@param opts Options
---@return Match[]
local function find_string(buf_handle, needle, opts)
    --return list of (row,col) of first character where needle is founqd

    local buf = buffer.get_buf(buf_handle)

    local matches = {} --[[@as Match[] ]]
    local do_smartcase = false

    if opts.enable_smartcase and not string.match(needle, "%u") then
        do_smartcase = true
    end
    if opts.enable_wildcard then
        local replace = vim.api.nvim_replace_termcodes(opts.wildcard_key, true, false, true)
        needle = string.gsub(needle, replace, opts.wildcard_magic_string)
    end

    for i, line in ipairs(buf) do
        if do_smartcase then
            line = string.lower(line)
        end

        ---@type integer | nil
        local start = 0
        ---@type integer | nil
        local stop = 0
        -- test string () {} [] \ /

        while stop ~= nil do
            --should i return stop +1 to, like f does
            start, stop = string.find(line, needle, stop + 1, false)

            -- BUG: fasntar här om man har två wildcards i början av en söksträng
            -- funkar med ett men inte två. see issue:3
            if start and stop then
                local loc = { line = i, start = start - 1, stop = stop } --[[@as Span]]
                local distance = distance_from_cursor(loc, opts)
                local match = { line = loc.line, start = loc.start, stop = loc.stop, distance = distance }
                table.insert(matches, match)
                table.sort(matches, function(a, b) return math.abs(a.distance) < math.abs(b.distance) end)
            end
        end
    end
    return matches
end

---determens if the target is befor or after the cursors current position
----1 = before
---0 = same pos
---1 = after
---@param cur_pos Pos
---@param target Pos
---@return Dir
local function before_or_after(cur_pos, target)
    local dir = 0
    if cur_pos.row == target.row + window.get_line_offset() then
        -- print(vim.inspect(cur_pos))
        -- print(vim.inspect(target))
        if cur_pos.col > target.col then
            dir = -1
        elseif cur_pos.col < target.col then
            dir = 1
        else
            dir = 0
        end
    elseif cur_pos.row > target.row + window.get_line_offset() then
        dir = -1
    elseif cur_pos.row < target.row + window.get_line_offset() then
        dir = 1
    end

    return dir
end

---jumps to a target and returns the direction of the jump
---@param target Pos
---@param opts Options
---@return Dir dir the direction
local function jump(target, opts)
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
    -- do the actual jump here!
    vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { target.row + window.get_line_offset(), target.col })
    return dir
end


---@param matches Span[]
---@param direction Dir
---@param x_bias integer
---@param y_bias integer
---@return Match[] | nil
local function closest_match(matches, direction, x_bias, y_bias)
    --returns a sorted list (closest first) of locations or the matches
    --prioritize same line?
    -- direction -1 for backwards, 0 for both ways and 1 for forward
    -- abs(x1 -x2) + abs(y1 - y2)

    if not matches then
        return
    end
    local dir = direction or 0
    local x_b = x_bias or 10
    local y_b = y_bias or 1
    local same_line_b = 100
    local pos = window.get_cursor_pos()
    local min = 99999999
    local best = {}

    -- print("matches: " .. #matches)

    local distances = {}

    for _, v in pairs(matches) do
        local candidate = x_b * math.abs(pos.row - (v.line + window.get_line_offset()))
            + y_b * math.abs(pos.col - v.start)
        local item = { line = v.line, start = v.start, stop = v.stop, score = candidate } --[[@as Match]]
        table.insert(distances, item)
        -- if candidate < min then
        --     min = candidate
        --     best = { row = v.line, col = v.start, distance_score = candidate }
        -- end
    end

    table.sort(distances, function(a, b) return a.distance_score < b.distance_score end)
    return distances
end


---escapes a character to match litteral in a regex (inserts % before)
---@param str string
---@return string
local function escape_string(str)
    assert(#str == 1)
    local needs_escaping = { '(', ')', '[', ']', '-' }

    for _, value in ipairs(needs_escaping) do
        if value == str then
            return "%" .. value
        end
    end
    return str
end

local function save_current_state(needle, direction, match_list, active)
    vim.w.ctrlf_needle = needle
    vim.w.ctrlf_dir = direction
    vim.w.ctrlf_matches = match_list
    vim.w.ctrlf_offset = window.get_line_offset()
    vim.w.ctrlf_active = active or false
end

---Goto the next match
---@param reverse boolean | nil  #reverse order, defaults to false
---@param opts Options
local function ctrlf_next(reverse, opts)
    reverse = reverse or false  -- reverse the direction true, false
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
        for _, v in ipairs(matches) do
            local target = { row = v.line, col = v.start }
            if before_or_after(cur_pos, target) > 0 then
                jump(target, opts)
                break
            end
        end
    elseif dir == DIR.backwards then
        for i = #matches, 1, -1 do
            local target = { row = matches[i].line, col = matches[i].start }
            if before_or_after(cur_pos, target) < 0 then
                jump(target, opts)
                break
            end
        end
    end
end

--- makes a search
---@param opts Options
local function ctrlf(opts)
    if not opts.enabled then
        return
    end
    --local pos = window.get_cursor_pos()
    local buf_handle = buffer.get_buf_nr()
    --local buffer = get_buf(buf_handle, pos.row, pos.row +1)

    local needle = ""
    local special_key = false
    local cancel = false
    local matches = {}
    local ns_id = hints.create_namespace("cfns")
    ---@type table | nil
    local target = {}
    local hints_loc = {}
    local hints_key_pressed = false

    hints.create_searchbox(0, ns_id, "", opts)
    vim.api.nvim_command("redraw")

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

            if opts.enable_hints then
                for _, v in pairs(hints_loc) do
                    if key == v.char then
                        -- selecting the target from the hint chars here!
                        target = { row = v.row - window.get_line_offset() + 1, col = v.col }
                        hints_key_pressed = true
                        break
                    end
                end
            end
            if hints_key_pressed then
                break
            end
        elseif key:byte() == 128 then
            special_key = true
        end

        if not special_key and key and not hints_key_pressed then
            needle = needle .. escape_string(key)
            -- print(needle)
        elseif special_key then
            if string.sub(key, 2) == "kb" then
                needle = string.sub(needle, 0, #needle - 1)
                if needle == "" then
                    hints.create_searchbox(0, ns_id, needle, opts)
                    vim.api.nvim_command("redraw")
                end
                -- print(needle)
            else
                vim.api.nvim_feedkeys(key, "", true) -- ???
                break
            end
        end

        if needle ~= "" and needle ~= vim.api.nvim_replace_termcodes(opts.wildcard_key, true, false, true) then
            hints.clear_hints(ns_id)
            matches = find_string(buf_handle, needle, opts)
            -- target = closest_match(matches, 0, 10, 1) or {}
            -- if the the closest target is selected then we dont have a target, so set the target to the first
            -- in the sorted list of matches
            if #matches > 0 then
                target = { row = matches[1].line, col = matches[1].start }
            end
            hints_loc = hints.create_hints(0, ns_id, matches, opts)
            hints.create_searchbox(0, ns_id, needle, opts)
            vim.api.nvim_command("redraw")
        end
    end --end of while 1

    --clear namespace color hints
    hints.clear_hints(ns_id)

    if #matches > 0 and not cancel then
        assert(target ~= {}, "target is empty")
        local dir = jump(target or {}, opts)
        save_current_state(needle, dir, matches, true)
    else
        -- print("no matches")
        --vim.api.nvim_input("<cr>")
    end
end

local M = {}
---@param opts Options
M.ctrlf = function(opts)
    ctrlf(opts)
end

---@param reverse boolean
---@param opts Options
M.ctrlf_next = function(reverse, opts)
    ctrlf_next(reverse, opts)
end

return M
