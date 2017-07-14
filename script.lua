-- Example torrent Format
--
-- Name: <>
-- ID: <>
-- State: <> Up Speed: <> ETA: <>
-- Seeds: <> Peers: <> Availability: <>
-- Size: <> Ratio: <>
-- Seed time: <> Active: <>
-- Tracker status: <>
--   ::Files
-- <
-- ...
-- >
--   ::Peers
-- <
-- ...
-- >


-- https://gist.github.com/hashmal/874792
-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. v)
    end
  end
end

function readFile(filePath)
    local file = io.open(filePath)
    if not file then
        print ('cant read file')
        return
    end

    local temp  = file:read()
    local rStr  = {}
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

-- trims leading/ending delims
function trim(str, delims)
    if type(str) ~= "string" then return end
    local d = ": <>"
    if delims then
        d = delims
    end

    local rStr = str
    rStr = string.gsub(rStr, "^[".. d .. "]*",  "")
    rStr = string.gsub(rStr, "[" .. d .. "]*$", "")
    return rStr
end

function Initialize()
    print("~~~~~~~~~~~~~~~~~~~~INIT~~~~~~~~~~~~~~~~~~~~")
    local inFile  = SKIN:MakePathAbsolute('in.txt')
    local outFile = SKIN:MakePathAbsolute('out.txt')
    local lineTable, lineTableLen = readFile(inFile)

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
    local torrent      = {}

    for lineIndex, line in pairs(lineTable) do -- look through each line
        for wordIndex, word in pairs(keyWordTable) do -- check each line for keywords
            local wordStartIndex, wordEndIndex = string.find(line, word)
            if  wordStartIndex ~= nil then -- if found word, handle it
                if  word == "Name: " and
                    next(torrent) ~= nil then
                    torrentTable[#torrentTable + 1] = torrent
                    print("torrent has ended")
                    torrent = {}
                end

                if  word == "Name: " or         --whole line
                    word == "ID: "   or
                    word == "Tracker status: " then
                        torrent[trim(word)] = trim(string.sub(line, wordEndIndex))
                        print("torrent[" .. word .."]: " .. torrent[trim(word)])
                elseif  word == "::Files" then  --series of whole lines
                    -- TODO?: make files into a table {path, size, progress, priority}
                    local fileTable     = {}
                    local tempLineIndex = lineIndex + 1
                    local tempLine      = lineTable[tempLineIndex]
                    while   tempLine ~= "" and
                            tempLine ~= nil and
                            string.find(tempLine,"::Peers") == nil do

                        -- # is used to get length of table
                        fileTable[#fileTable + 1] = trim(tempLine)
                        print("fileTable["..#fileTable.."]" .. fileTable[#fileTable])
                        tempLineIndex = tempLineIndex + 1
                        tempLine = lineTable[tempLineIndex]
                    end
                    torrent[trim(word)] = fileTable

                elseif  word == "::Peers" then
                    local peerTable     = {}
                    local tempLineIndex = lineIndex + 1
                    local tempLine      = lineTable[tempLineIndex]

                    while   tempLine ~= "" and
                            tempLine ~= nil do

                        peerTable[#peerTable + 1] = trim(tempLine)
                        print("peerTable["..#peerTable.."]" .. peerTable[#peerTable])

                        tempLineIndex = tempLineIndex + 1
                        tempLine = lineTable[tempLineIndex]
                    end
                    torrent[trim(word)] = trim(peerTable)

                else                            --part of a single line
                    local tempString     = line
                    local nextWordInLine = nil
                    local haveFoundWord  = false
                    -- cut the string starting after the found word,
                    -- until the end of the string
                    tempString = string.sub(line, wordEndIndex, string.len(tempString))
                    -- check for other keywords on the line
                    for _, word2 in pairs(keyWordTable) do
                        local x2, y2 = string.find(tempString, word2)

                        if x2 ~= nil then
                            haveFoundWord  = true
                            nextWordInLine = word2
                            -- if we find a word on that line,
                            -- cut our substring to just before the start of that word
                            tempString = string.sub(tempString, 0, x2 - 1)
                            torrent[trim(word)] = trim(tempString)
                            print("torrent[" .. trim(word) .."]: " .. trim(tempString))
                            break
                        end

                    end
                    if not haveFoundWord then
                        torrent[trim(word)] = trim(tempString)
                        print("torrent[" .. trim(word) .."]: " .. trim(tempString))
                    end
                    -- print(tempString)

                end
            end
        end
    end

    -- add final torrent to the table
    if next(torrent) ~= nil then
        torrentTable[#torrentTable + 1] = torrent
        print("torrent has ended")
    end
    print("~~~~~~~~~~~~~~~~~~~~END~~~~~~~~~~~~~~~~~~~~~")
    tprint(torrentTable)
end
