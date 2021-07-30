local M = {}

local opts = require "defaults"
function M.generate_unique_hints(matches)
	-- create unique table of char or char-pairs depending on how many matches
	-- they have to be unique from each other (pairs can have same chars ("aa" and "ab" is considered unique))
	-- they also have to be unique from from the next char or chars right after the maching string
	-- so if i have a string "hello world" and search for "hel" the hint char cant be an "l" or if 
	-- two chars is needed they cant start with "l"
	-- hints have to be updateded after every search char entered to guarantee that the hint char is different
	-- from the next char in the buffer.
	
	
end


return M
