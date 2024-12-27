local menu = {}
local core = require 'client.core'
local utils = require 'client.utils'
local Shared = core.SharedVehicleHashes()

local function PreviewVehicle(vehicle, garage)
    DeleteVehicle(previewcar)
    local spawncoords = utils.GetClosestParking(garage.info)
    if not spawncoords then return lib.notify({description = 'Too far away from any parking spot', type = 'error'}) end
    local options = {}
    options[#options + 1] = {
        title = 'Pull This Vehicle Out',
        icon = 'fa-solid fa-right-from-bracket',
        description = (vehicle.state == 0 and 'Price: '..tostring(Config.DepotPrice)) or (vehicle.state == 2 and 'Price: '..tostring(vehicle.price)) or nil,
        onSelect = function()
            TakeCarOut(vehicle, garage)
        end,
        disabled = vehicle.disable
    }
    if not garage.info?.spawner then
        options[#options + 1] = {
            title = 'Health Info',
            description = ('Engine: %s | Body = %s'):format(vehicle.engine/10, vehicle.body/10),
            icon = 'fa-solid fa-heart',
            readOnly = true
        }
        options[#options + 1] = {
            title = 'Fuel Info',
            description = ('Fuel = %s'):format(vehicle.fuel),
            icon = 'fa-solid fa-gas-pump',
            readOnly = true
        }
        if vehicle.hold then
            options[#options + 1] = {
                title = 'Vehicle on Hold by LSPD',
                description = ('Hold will end at: %s'):format(vehicle.hold),
                icon = 'fa-solid fa-lock',
                readOnly = true
            }
        end
    end
    
    local model = joaat(vehicle.model)

    lib.requestModel(model)
    previewcar = CreateVehicle(model, spawncoords.x, spawncoords.y, spawncoords.z, spawncoords.w, false, true)
    FreezeEntityPosition(previewcar, true)
    SetEntityCollision(previewcar, false, false)
    if vehicle.plate then SetVehicleNumberPlateText(previewcar, vehicle.plate) end
    if vehicle.mods then core.SetVehicleProperties(previewcar, vehicle.mods) end

    lib.registerContext({
        id = 'PreviewVehicle',
        title = Shared[model]?.name or vehicle.name,
        options = options,
        menu = 'Public_Garage',
        onBack = function()
            DeleteVehicle(previewcar)
            previewcar = nil
            --SetVehicleAsNoLongerNeeded(model)
        end,
        onExit = function()
            DeleteVehicle(previewcar)
            previewcar = nil
            --SetVehicleAsNoLongerNeeded(model)
        end
    })
    lib.showContext('PreviewVehicle')
end

local function GetSpawnerVehicles(data)
    -- print(json.encode(data.info.spawner, {indent = true}))
    -- print(core.GetJob().grade.level)
    local options = {}
    for i, v in pairs(data.info.spawner[tostring(core.GetJob().grade.level)]) do
        options[#options + 1] = {
            title = ('%s'):format(v),
            description = '',
            icon = utils.GetIcon(i),
            onSelect = function()
                PreviewVehicle({
                    -- cid = core.GetCID(),
                    name = v,
                    model = i,
                    fuel = 100,
                    state = 1,
                    engine = 1000,
                    body = 1000,
                    otherdmg = {suspension = 100, brakes = 100, transmission = 100},
                }, data)
            end
        }
    end
    lib.registerContext({
        id = 'Public_Garage',
        title = data.info.label,
        options = options
    })
    lib.showContext('Public_Garage')
end

function GetGarageVehicles(data)
    if data.info.spawner then return GetSpawnerVehicles(data) end
    local vehicles = lib.callback.await(('onebit_garages:server:Get%sVehicles'):format(utils.ConvertGarageNameToString(data.info.type)), false, data.info, core.GetCID())
    local options = {}
    if not vehicles then return lib.notify({description = 'Garage Error', type = 'error'}) end
    for i = 1, #vehicles do
        local v = vehicles[i]
        options[#options + 1] = {
            title = ('%s'):format(Shared[joaat(v.model)].name),
            description = ('Plate: %s'):format(v.plate),
            icon = utils.GetIcon(v.model),
            onSelect = function()
                PreviewVehicle(v, data)
            end
        }
    end
    lib.registerContext({
        id = 'Public_Garage',
        title = data.info.label,
        options = options
    })
    lib.showContext('Public_Garage')
end

local function OpenGarage(data)
    local job = core.GetJob()
    local options = {}
    if data.info.type ~='depot' then
        options[#options + 1] = {
            title = 'Park Vehicle',
            description = 'Use this to park your vehicle',
            icon = 'fa-solid fa-square-parking',
            onSelect = function()
                ParkVehicle(data)
            end
        }
    end
    options[#options + 1] = {
        title = 'Available Vehicles',
        description = 'View stored vehicles!',
        icon = 'fa-solid fa-warehouse',
        onSelect = function()
            GetGarageVehicles(data)
        end
    }
    lib.registerContext({
        id = 'PublicVehList',
        title = data.info.label,
        options = options
    })
    lib.showContext('PublicVehList')
end

function menu.OpenMenu(data)
    OpenGarage(data)
end

function menu.RaidGarage(data)
    local options = {}
    local job = core.GetJob()
    if job.name == 'police' and job.onduty then
        options[#options+1] = {
            title = 'Raid Garage',
            description = 'Raid a Garage',
            icon = 'fa-solid fa-shield-halved',
            onSelect = function()
                local kekw = lib.inputDialog('Raid Garage', {
                    {type = 'checkbox', label = 'Raid Garage'},
                    {type = 'input', label = 'Citizen ID'}
                })
                if kekw then
                    if kekw[1] == true then
                        cid = tostring(kekw[2]):upper()
                        local datastuff = {
                            garageId = data.info.name,
                            garage = data.info,
                            type = data.info.type,
                            cid = cid
                        }
                        local vehicles = lib.callback.await('onebit_garages:server:RaidGarage', false, datastuff)
                        if vehicles then
                            local options = {}
                            if not vehicles then return lib.notify({description = 'Garage Error', type = 'error'}) end
                            for i = 1, #vehicles do
                                local v = vehicles[i]
                                options[#options + 1] = {
                                    title = ('%s'):format(Shared[joaat(v.model)].name),
                                    description = ('Plate: %s'):format(v.plate),
                                    icon = utils.GetIcon(v.model),
                                    onSelect = function()
                                        PreviewVehicle(v, data)
                                    end
                                }
                            end
                            lib.registerContext({
                                id = 'Public_Garage',
                                title = data.info.label,
                                options = options
                            })
                            lib.showContext('Public_Garage')
                        end
                    end
                end
            end
        }
    end
    lib.registerContext({
        id = 'RaidGarageMenu',
        title = data.info.label,
        options = options
    })
    lib.showContext('RaidGarageMenu')
end

return menu