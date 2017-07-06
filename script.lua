-- Name: <>
-- ID: <>
-- State: <> Up Speed: <> ETA: <>
-- Seeds: <> Peers: <> Availability: <>
-- Size: <> Ratio: <>
-- Seed time: <> Active: <>
-- Tracker status: <>
--   ::Files<
--   >::Peers<
--  >
--

-- all torrents start with Name: and end with a blank line


function Initialize()
    local inFile  = SKIN:MakePathAbsolute('in.txt')
    local outFile = SKIN:MakePathAbsolute('out.txt')

    local keyWordTable = {"Name: ",
    "ID: ",
    "State: ",
    "Up Speed: ",
    "Seeds: ",
    "Availability: ",
    "Size: ",
    "Ratio: ",
    "Seed time: ",
    "Active: ",
    "Tracker status: ",
    "::Files",
    "::Peers"}

    -- create a table of torrent objects,
    -- each containing all the information provided from the input
    local torrentTable = {}
    local curTorrent = nil


    local lineTable   = readFile(inFile)
    local fileStr     = ""
    local prevWord    = {s = nil, e = nil}
    local currentWord = {s = nil, e = nil}

    for index,line in pairs(lineTable) do -- look through each line
        for _, word in pairs(keyWordTable) do -- check each line for keywords
            local iStart, iEnd = string.find(line, word)
            if  iStart ~= nil then -- if found word, handle it
                prevWord = currentWord

                if  word == "Name: " or         --whole line
                    word == "ID: "   or
                    word == "Tracker status: " then
                        --torrent[word] = string.sub(line, iEnd)
                        print(string.sub(line, iEnd))
                elseif  word == "::Files" then  --series of whole lines
                    --read lines until "::Peers"
                    local tIdx = index+1
                    local tStr = lineTable[tIdx]
                    local fileString = ""
                    while   string.find(tStr,"::Peers") ~= nil and
                            string.find(tStr,"\n")      ~= nil do
                        fileString = fileString .. tStr
                    end
                    print(fileString)
                elseif  word == "::Peers" then
                    --read lines until Blank line
                    --read lines until "::Peers"
                    local tIdx = index+1
                    local tStr = lineTable[tIdx]
                    local fileString = ""
                    while string.find(tStr,"\n") ~= nil do
                        fileString = fileString .. tStr
                    end
                    print(fileString)
                else                            --part of a single line
                    -- local tIdx = index+1
                    -- local tStr = lineTable[tIdx]
                    -- for _, word in pairs(keyWordTable) do
                    --     while string.find(tStr, word) ~= nil do
                    --         string.sub(tStr, tIdx, string.len(tStr) - 1)
                    --     end
                    --     string.sub(tStr, tIdx, string.len(tStr) - string.len(word))
                    -- end
                    -- print(tStr)
                end
                print('key found: ' .. word .. ' :: ' .. line)
                fileStr = fileStr  .. 'key found: ' .. word .. ' :: ' .. line .. '\n'
            end
        end
    end
    -- print(str)
    -- local splitStr = Split(str, "\r\n")
    -- local i = 0
    -- for k, v in pairs(splitStr) do
    --     print(k .. ":~:".. v)
    --     i = i + 1
    -- end
    print(writeFile(outFile, fileStr))
end


-- starting from idx,
-- create a string until nextWord is found
-- match string with word
-- move idx to end of nextWord
    --TODO: do we want to cut the string or use an iterator?
function getKeyWordString(str, idx, word)
    local keyWordString = ""
    local nextWord = nil
    local tempWord = nil
    --
    for _, word in pairs(keyWordTable) do -- find all the words in the string
        tempWord = string.find(line, word, idx)
        if tempWord ~= nil then
            if tempWord[1] < nextWord[1] then -- if a word is found with a lower index, use that word
                nextWord = tempWord
            end
        end

        keyWordString = string.sub(str, idx, nextWord[1])
        currentTorrent.word = keyWordString
        idx = nextWord[2]
        return true
    end
end

function readFile(filePath)
    local file = io.open(filePath)
    if not file then
        print ('cant read file')
        return
    end

    local temp = file:read()
    local rStr = {}
    while temp ~= nil do
        table.insert(rStr, temp)
        temp = file:read()
    end


    -- local text = file:read()
    file:close()

    return rStr
end

function writeFile(filePath, text)
    local file = io.open(filePath, 'w')

    if not file then
        print('cant write file')
        return
    end

    file:write(text)
    file:close()

    return true
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
