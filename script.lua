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

    local keyWordTable = {  "Name: ",
                            "ID: ",
                            "State: ",
                            "Up Speed: ",
                            "Seeds: ",
                            "Peers: ",
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


    local lineTable, lineTableLen   = readFile(inFile)
    print("lineTableLen: " .. lineTableLen)
    local fileStr     = ""
    -- local prevWord    = {s = nil, e = nil}
    -- local currentWord = {s = nil, e = nil}
    local torrent = {}

    -- TODO: fix variable names, too confusing as is

    for lineIndex,line in pairs(lineTable) do -- look through each line
        for wordIndex, word in pairs(keyWordTable) do -- check each line for keywords
            local wordStartIndex, wordEndIndex = string.find(line, word)
            if  wordStartIndex ~= nil then -- if found word, handle it
                -- prevWord = currentWord

                if  word == "Name: " or         --whole line
                    word == "ID: "   or
                    word == "Tracker status: " then
                        torrent[word] = string.sub(line, wordEndIndex)
                        print("torrent[" .. word .."]: " .. torrent[word])
                elseif  word == "::Files" then  --series of whole lines
                    --read lines until "::Peers"
                    local fileTable  = {}
                    local count      = 1
                    local tIdx       = lineIndex+count
                    if    tIdx       > lineTableLen then return end
                    local tStr       = lineTable[tIdx]

                    while   string.find(tStr,"::Peers") == nil and
                            tStr ~= "" and
                            tStr ~= nil do

                        fileTable[count] = tStr
                        print("fileTable["..count.."]" .. fileTable[count])

                        count = count + 1
                        tIdx = tIdx + 1
                        tStr = lineTable[tIdx]
                    end
                    torrent["files"] = fileTable
                elseif  word == "::Peers" then
                    print(line)
                    --read lines until Blank line
                    --read lines until "::Peers"
                    local peerTable  = {}
                    local count      = 1
                    local tIdx       = lineIndex+count
                    if    tIdx       > lineTableLen then return end
                    local tStr       = lineTable[tIdx]

                    while   tStr ~= "" and
                            tStr ~= nil do

                        peerTable[count] = tStr
                        print("peerTable["..count.."]" .. peerTable[count])

                        count = count + 1
                        tIdx = tIdx + 1
                        tStr = lineTable[tIdx]
                    end
                    torrent["peers"] = peerTable
                else                            --part of a single line
                    local tIdx = lineIndex+1
                    if    tIdx > lineTableLen then return end
                    local tStr = lineTable[tIdx]
                    local nextWordInLine = nil
                    tStr = string.sub(tStr, string.len(word), string.len(tStr))
                    for _, word2 in pairs(keyWordTable) do
                        local x2, y2 = string.find(tStr, word2)

                        if x2 ~= nil then
                            print("112x2 " .. x2)
                            print(word2)
                            nextWordInLine = word2
                            tStr = string.sub(tStr, 0, x2 - 1)
                            print("120torrent[" .. nextWordInLine .."]: " .. tStr)
                            break
                        end

                    end
                    -- print(tStr)

                end
            end
        end
    end
    for key, val in pairs(torrent) do
        print("key" .. key)
        print("val" .. val)
    end
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
    local count = 0
    while temp ~= nil do
        table.insert(rStr, temp)
        temp = file:read()
        count = count + 1
    end


    -- local text = file:read()
    file:close()

    return rStr, count
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
