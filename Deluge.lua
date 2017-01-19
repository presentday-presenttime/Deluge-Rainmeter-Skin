function Initialize()
    torrentListLength = tonumber(SKIN:GetVariable('TorrentsToShow', 5));

    -- global constants
    updateSpeedName         = "MeterSpeedVal"
    updateTorrentCountName  = "MeterTotalCountVal"
    updateUploadCountName   = "MeterTotalUpCountVal"
    updateDownloadCountName = "MeterTotalDownCountVal"
    toggleStatusButtonName  = "MeterToggleStatus"

    speedFormat = "%04.1f %s"
    countFormat = "%02d"

    torrentInfoPattern  = "Name:.-"
    numberSearchPattern = "%d*.%d* %aiB/s"
    -- the second value is the length of the prefix
    uploadSearchPattern   = {("Up Speed: "   .. numberSearchPattern), 10}
    downloadSearchPattern = {("Down Speed: " .. numberSearchPattern), 12}

    unitSize = {"KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"}

    torrentTable = {};
end

function Update()
    measureRunDeluge = SKIN:GetMeasure("MeasureRunDeluge")
    inputString      = measureRunDeluge:GetStringValue()

    -- getTorrentInfo()
end

-- GeneralInfo Functions
function getGeneralInfo()
    if inputString ~= "" then
        updateSpeed()
        updateTorrentCount()
        upCount   = updateUploadCount()
        downCount = updateDownloadCount()
        playPauseAllButtonText()
    end
end

function playPauseAllButtonText()
    Update()
    local outText = "Resume All"

    if (string.find(inputString, "State: D") or string.find(inputString, "State: U")) then
        outText = "Pause All"
    end

    SKIN:Bang('!SetOption', toggleStatusButtonName, 'Text', outText)
end

function playPauseAll()
    if (upCount + downCount == 0) then
        SKIN:Bang("!CommandMeasure MeasureResumeAll Run")
    else
        SKIN:Bang("!CommandMeasure MeasurePauseAll Run")
    end
end

function updateSpeed()
    local down = getDownSpeed()
    local up   = getUpSpeed()

    SKIN:Bang('!SetOption', updateSpeedName, 'Text', up .. " / " .. down)
end

function updateTorrentCount()
    local pattern    = "Name: "
    local matchTable = getMatchTable(pattern)
    local count      = 0

    for _, _ in pairs(matchTable) do
        count = count + 1
    end

    SKIN:Bang('!SetOption', updateTorrentCountName, 'Text', count)
end

function updateUploadCount()
    local count = countHelper(uploadSearchPattern[1], uploadSearchPattern[2])

    SKIN:Bang('!SetOption', updateUploadCountName, 'Text', count)
    return count;
end

function updateDownloadCount()
    local count = countHelper(downloadSearchPattern[1], downloadSearchPattern[2])

    SKIN:Bang('!SetOption', updateDownloadCountName, 'Text', count)
    return count
end

function getDownSpeed()
    return getSpeedHelper(downloadSearchPattern[1], downloadSearchPattern[2])
end

function getUpSpeed()
    return getSpeedHelper(uploadSearchPattern[1], uploadSearchPattern[2])
end

-- counts non-zero values found in `pattern`
function countHelper(pattern, trimSize)
    local matchTable = getMatchTable(pattern)
    local tTable     = trimTable(matchTable, trimSize, -1)
    local count      = 0

    for _, tVal in pairs(tTable) do
        if byteStringToFloat(tVal) ~= 0.0 then
            count = count + 1
        end
    end

    return string.format(countFormat, count)
end

-- gets the sum speed assuming trimmed string is of form `#.# [unit]`
function getSpeedHelper(pattern, trimSize)
    local matchTable = getMatchTable(pattern)
    local tTable     = trimTable(matchTable, trimSize, -1)
    local byteTable  = {}
    local byteSum    = 0

    for _, trimString in pairs(tTable) do
        byteSum = byteSum + byteStringToFloat(trimString)
    end

    byteString = byteValToString(byteSum)
    return byteString
end

-- converts strings of form `#.# [unit]` to the total bytes
function byteStringToFloat(byteString)
    local num         = 0
    local exp         = 0
    local unit        = ""
    local numPattern  = "%d*%.%d*"
    local unitPattern = "%aiB/s"

    -- parse string to: num [unit]
    sIdx, eIdx = string.find(byteString, numPattern)
    numString  = string.sub(byteString, sIdx, eIdx)
    num        = tonumber(numString)
    if not num or num == 0 then return 0 end

    sIdx, eIdx = string.find(byteString, unitPattern)
    unit       = string.sub(byteString, sIdx, eIdx)

    for exponent,string in pairs(unitSize) do
        if unit == string then
            exp = exponent
            break
        end
    end

    -- apply exponent
    byteVal = num*(1024^exp)

    -- round to 1 decimal
    byteVal = (math.floor(byteVal*10 + 0.5))/10
    return byteVal
end

-- converts bytes to readable abbreviation using [unit]
function byteValToString(byteVal)
    local index = 1
    local val   = byteVal

    while val > 1024 do
        val   = val/1024
        index = index + 1
    end

    return string.format(speedFormat, val, unitSize[index])
end

-- apply string.sub to every value in a table
function trimTable(inTable, startVal, endVal)
    local outTable = {}

    for _, value in pairs(inTable) do
        table.insert(outTable, string.sub(value, startVal, endVal))
    end

    return outTable
end

-- return a table of all instances of `pattern`
function getMatchTable(pattern)
    local inString   = inputString
    local outTable   = {}
    local tableIndex = 1

    repeat
        -- find matches
        matchStart, matchEnd = string.find(inString, pattern)
        if not matchEnd then break end

        -- add match to Table
        matchString = string.sub(inString, matchStart, matchEnd)
        table.insert(outTable, matchString)

        -- trim inString
        inString = string.sub(inString, matchEnd)
    until not matchEnd

    return outTable
end

-- TorrentList Functions
function getTorrentListInfo()
    if inputString ~= "" then
        if torrentTable.getn ~= torrentListLength then
            getTorrentTable()
        end
        for _, torrent in pairs(torrentTable) do
            -- update all torrents
            torrent.info = getTorrentInfo(torrent.index);
            SKIN:Bang('!SetOption', "Torrent"..torrent.index.."Name", 'Text', torrent.info.name)
            SKIN:Bang('!SetOption', "Torrent"..torrent.index.."String", 'Text', torrent.info.body)
        end
    end
end



-- creates a table of torrent objects, with references to the rainmeter Meters & relevant info.
function getTorrentTable()
    local i = 1
    torrentTable = {};
    while i <= torrentListLength do
        local torrent = {
            index  = i,
            meters = {
                name         = SKIN:GetMeter("Torrent"..i.."Name"),
                string       = SKIN:GetMeter("Torrent"..i.."String"),
                statusButton = SKIN:GetMeter("Torrent"..i.."ToggleStatus"),
                removeButton = SKIN:GetMeter("Torrent"..i.."Remove"),
            }
        }
        table.insert(torrentTable, torrent)
        i = i + 1;
    end
end

function getTorrentInfo(index)
    inputTorrentList = Split(inputString, "Name: ");
    local info = {}
    local torrentInfo = Split(inputTorrentList[index+1], "\n")[1]

    info.name = torrentInfo
    info.body = Split(inputTorrentList[index+1], torrentInfo)[2]

    print(info.body)
    return info
    -- local count = 0

    -- print(index)

    -- for key,val in pairs(inputTorrentList) do
    --     count = count + 1
    --     if(count == index) then
    --         print("key: "..key)
    --         print("val: "..val)
    --     end
    -- end

    -- print("count: " .. count)
    -- print(string.find(inputTorrentList[2], "ID: "))
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