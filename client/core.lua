local core = {}
local QBCore = exports['qb-core']:GetCoreObject()
function core.GetJob()
    return QBCore.Functions.GetPlayerData().job
end

function core.GetAllJobs()
    return QBCore.Shared.Jobs
end

function core.GetGang()
    return exports.av_gangs:getGang()
end

function core.GetAllGangs()
    return QBCore.Shared.Gangs
end

function core.GetCID()
    return QBCore.Functions.GetPlayerData().citizenid
end

function core.SharedVehicleHashes()
    return QBCore.Shared.VehicleHashes
end

function core.SetVehicleProperties(vehicle, properties)
    return QBCore.Functions.SetVehicleProperties(vehicle, properties)
end

function core.GetVehicleProperties(veh)
    return QBCore.Functions.GetVehicleProperties(veh)
end
return core