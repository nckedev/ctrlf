---@alias Pos {row: integer, col: integer}
---
---@class Options
---@field enabled boolean
---@field hint_chars string
---@field quit_keys string[]
---@field enable_hints boolean
---@field enable_smartcase boolean
---@field enable_wildcard boolean
---@field searchbox "none" | "cursor_above" | "cursor_under" | "cursor_after"
---@field searchbox_match_count boolean
---@field searchbox_size integer
---@field jump_keys_closest string[]
---@field jump_keys_next string[]
---@field wildcard_key string
---@field search_direction "forward" | "backward" | "both"
---@field enable_gray_background boolean
---@field wildcard_magic_string  string
---@field enable_jumplist boolean
---@field colors {hint_char : Color, closest_match : Color, match : Color, gray : Color, searchbox : Color }
---
---@alias HintChar {char: string, row: integer, col: integer}
---@alias Span {line: integer, start: integer, stop: integer }
---@alias Dir -1 | 0 | 1
---@alias Color {fg : string, bg : string}
