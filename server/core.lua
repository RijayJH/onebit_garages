local core = {}
local QBCore = exports['qb-core']:GetCoreObject()


function core.GetCID(src)
    local player = QBCore.Functions.GetPlayer(src)
    return player?.PlayerData.citizenid
end

function core.GetJob(src)
    local player = QBCore.Functions.GetPlayer(src)
    return player?.PlayerData.job
end

function core.GetGang(getSourceByIdentifier)
    return exports['av_gangs']:getGang(source)
end

return core