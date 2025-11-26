local M = {}

function M.test()
    return "test"
end

---@return {row: integer, col : integer}
function M.get_cursor_pos()
    local p = vim.api.nvim_win_get_cursor(0)
    local pos = { row = p[1], col = p[2] }
    return pos
end

---clamps the row index to the window
---@param row integer
---@return integer
function M.clamp_row(row)
    local range = M.get_visible_lines_range(0)
    if row <= range.top then
        return range.top
    elseif row >= range.bottom then
        return range.bottom
    end
end

---@param window integer | nil
---@return {top: integer, bottom: integer, width: integer, height: integer}
function M.get_visible_lines_range(window)
    window = window or vim.api.nvim_get_current_win()
    local win_info = vim.fn.getwininfo(window)[1]
    local win = { top = win_info.topline, bottom = win_info.botline, width = win_info.width, height = win_info.height }
    return win
end

---@return integer
function M.get_line_offset()
    local window = vim.api.nvim_get_current_win()
    local win_info = vim.fn.getwininfo(window)[1]
    return win_info.topline - 1
end

---@return integer
function M.get_last_line()
    local window = vim.api.nvim_get_current_win()
    local win_info = vim.fn.getwininfo(window)[1]
    return win_info.botline - 1
end

return M
