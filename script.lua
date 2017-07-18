function Initialize()
    torrentListLength = tonumber(SKIN:GetVariable('TorrentsToShow', 5));

    -- check if these are hidden before updating
    MeterTotalSpeed         = "MeterTotalSpeed"
    MeterTotalTorrentCount  = "MeterTotalTorrentCount"
    MeterTotalUploadCount   = "MeterTotalUploadCount"
    MeterTotalDownloadCount = "MeterTotalDownloadCount"
    MeterPlayPauseButton    = "MeterPlayPauseButton"


    -- 00.0 KiB/s
    -- 00
    speedFormat = "%04.1f %s"
    countFormat = "%02d"
    unitSize    = { "KiB", "MiB", "GiB",
                    "TiB", "PiB", "EiB",
                    "ZiB", "YiB"}

    -- list of all keywords to look for in the torrent output string
    keyWordTable = {
                    "Name: ",
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
                    "::Peers"
                    }

    inFile       = SKIN:MakePathAbsolute('in2.txt') -- used for debugging, will not be used in production
    outFile      = SKIN:MakePathAbsolute('out.txt') -- currently not used
    torrentTable = {};
end

function Update()
    print("stript.Update()")
    InputMeasure = SKIN:GetMeasure("MeasureDelugeInput")
    inputString  = InputMeasure:GetStringValue()
    print(inputString)
    if string.len(inputString) < 40 then
        print("Unusually short output: ")
        print(inputString)
        return
    end
    writeFile("scriptOut.txt", inputString)

    parseInput(inputString)
    -- -- get total upload/download
    -- local totalUpload   = 0
    -- local totalDownload = 0
    -- for _,torrent in pairs(torrentTable) do
    --     totalUpload   = torrent["Up Speed"]   + totalUpload
    --     totalDownload = torrent["Down Speed"] + totalDownload
    -- end
end


function speedStringToFloat(speedString)
    print("speedStringToFloat")
    if not speedString or speedString == nil then return 0 end
    local speedFloat = 0
    local tempString = string.match(speedString, "%d*%.%d*")
    local baseNumber = tonumber(tempString)
    local exponentString = string.match(speedString, "%aiB/s")
    for key,val in pairs(unitSize) do
        if exponentString == val then
            baseNumber = baseNumber * math.pow(1024, key)
            break
        end
    end
    return baseNumber
end
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

-- reads the input string and saves data into torrentTable
function parseInput(inputString)
    print("~~~~~~~~~~~~~~~~~~~~Parse~~~~~~~~~~~~~~~~~~~~")
    local lineTable = {}
    -- local lineTableLen = 0 --= readFile(inFile)
    for line in string.gmatch(inputString, "[^\r\n]+") do
        lineTable[#lineTable + 1] = line
        -- print(line)
    end

    -- create a table of torrent objects,
    -- each containing all the information provided from the input
    torrentTable  = {}
    local torrent = {}

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
                        -- print("torrent[" .. word .."]: " .. torrent[trim(word)])
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
                        -- print("fileTable["..#fileTable.."]" .. fileTable[#fileTable])
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
                        -- print("peerTable["..#peerTable.."]" .. peerTable[#peerTable])

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
                            -- print("torrent[" .. trim(word) .."]: " .. trim(tempString))
                            break
                        end

                    end
                    if not haveFoundWord then
                        torrent[trim(word)] = trim(tempString)
                        -- print("torrent[" .. trim(word) .."]: " .. trim(tempString))
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
    for i,torrent in pairs(torrentTable) do
        formatTorrent(torrent)
        print(i)
    end
    -- formatTorrent(torrent)
    -- tprint(torrentTable)
end

-- convert all numbers to their base form
function formatTorrent(torrent)
    speedStringToFloat(torrent["Up Speed"])
    speedStringToFloat(torrent["Down Speed"])
end