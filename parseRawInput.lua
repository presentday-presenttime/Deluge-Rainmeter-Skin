local delim = "\r\n"
local inString = io.lines()

function parseRawInput(inString)
	local torrentTable = Split(inString, delim)
	for k,v in pairs(torrentTable) do
		print(v)
	end
end




-- Compatibility: Lua-5.0
function Split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end
parseRawInput(inString)
print(inString)