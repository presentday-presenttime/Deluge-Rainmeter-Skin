function Initialize()
    -- global constants
    updateSpeedName         = "MeterResult"
    updateTorrentCountName  = "MeterTotalCountVal"
    updateUploadCountName   = "MeterTotalUpCountVal"
    updateDownloadCountName = "MeterTotalDownCountVal"

    speedFormat = "%04.1f %s"
    countFormat = "%02d"

    numberSearchPattern   = "%d*.%d* %aiB/s"
    -- the second value is the length of the prefix
    uploadSearchPattern   = {("Up Speed: "   .. numberSearchPattern), 10}
    downloadSearchPattern = {("Down Speed: " .. numberSearchPattern), 12}

    unitSize = {"KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"}
end

function Update()
    measureRunDeluge = SKIN:GetMeasure("MeasureRunDeluge")
    inputString      = measureRunDeluge:GetStringValue()

    if inputString ~= "" then
        updateSpeed()
        updateTorrentCount()
        updateUploadCount()
        updateDownloadCount()
    end
end

function updateSpeed()
    local down = getDownSpeed()
    local up   = getUpSpeed()

    SKIN:Bang('!SetOption', updateSpeedName, 'Text', down .. " / " .. up)
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
end

function updateDownloadCount()
    local count = countHelper(downloadSearchPattern[1], downloadSearchPattern[2])

    SKIN:Bang('!SetOption', updateDownloadCountName, 'Text', count)
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