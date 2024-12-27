local garages = {}
local core = require 'client.core'
local menu = require 'client.menu'
local utils = require 'client.utils'
local admin = require 'client.admin'
local zones = {}
local blips = {}
previewcar = nil

-- Functions

local function isAllowed(data)
    if data.type == 'public' or data.type == 'depot' then return true
    elseif data.type == 'job' then
        local job = core.GetJob()
        if not data.restriction then return false end
        if type(data.restriction) == 'table' then
            for i = 1, #data.restriction do
                if job.name == data.restriction[i] then return true end
            end
        else
            if job.name == data.restriction then return true end
        end
    elseif data.type == 'gang' then
        local gang = core.GetGang()
        if not data.restriction then return false end
        if type(data.restriction) == 'table' then
            for i = 1, #data.restriction do
                if gang.name == data.restriction[i] then return true end
            end
        else
            if gang.name == data.restriction then return true end
        end
    elseif data.type == 'house' then
        return true
    end
    return false
end

local function onEnter(data)
    local job = core.GetJob()
    if job.name == 'police' and job.onduty and not data.info.spawner then
        lib.addRadialItem({
            {
                id = 'raid_garage_menu',
                label = 'Raid Garage',
                icon = 'warehouse',
                onSelect = function()
                    menu.RaidGarage(data)
                end,
            }
        })
        lib.showTextUI((data.info.type == 'depot' and 'Impound') or 'Parking')
    end   
    if not isAllowed(data.info) then return end
    lib.addRadialItem({
        {
            id = 'open_garage_menu',
            label = 'Garage',
            icon = 'warehouse',
            onSelect = function()
                menu.OpenMenu(data)
            end,
        }
    })
    lib.showTextUI((data.info.type == 'depot' and 'Impound') or 'Parking')
end

local function onExit()
    lib.removeRadialItem('open_garage_menu')
    lib.removeRadialItem('raid_garage_menu')
    lib.hideTextUI()
end

local Houses = {}
local HouseZones = {}

local function SetHouse(id, haskey, add)
    if haskey and add then
        houseInfo = Houses[id]
        if not houseInfo then return end
        HouseZones[id] = lib.zones.box({
            coords = vec3(houseInfo.takeVehicle.x, houseInfo.takeVehicle.y, houseInfo.takeVehicle.z),
            size = vec3(5, 5, 8),
            debug = Config.Debug,
            info = {
                name = id,
                label = houseInfo.label,
                type = 'house',
                parkinglocations = {vec4(houseInfo.takeVehicle.x, houseInfo.takeVehicle.y, houseInfo.takeVehicle.z, houseInfo.takeVehicle.w)},
                vehicleCategories = Config.HouseVehicleCategories or {'car', 'motorcycle', 'other'}
            },
            rotation = houseInfo.takeVehicle.w,
            onEnter = onEnter,
            onExit = onExit,
        })
    else
        HouseZones[id]:remove()
        HouseZones[id] = nil
    end
end

exports('SetHouse', SetHouse)

local function AddHouse(id, houseInfo)
    Houses[id] = houseInfo
end

exports('AddHouse', AddHouse)

local function GetGarage(id)
    for i=1, #garages do
        if id == garages[i].name then return garages[i] end                             
    end
    return false
end

exports('GetGarage', GetGarage)

local function RemoveHouse(id)
    Houses[id] = nil
end

exports('RemoveHouse', RemoveHouse)

local function CanParkHere(data, vehicle)
    local class = GetVehicleClass(vehicle)
    for i, v in pairs(data.vehicleCategories) do
        for j, k in pairs(Config.VehicleCategories[v]) do
            if class == k then
                return true
            end
        end
    end
    return false
end

function ParkVehicle(data)
    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 10, false)
    vehicle = cache.vehicle or vehicle
    if not vehicle then return lib.notify({description = 'No Vehicle Found', type = 'error'}) end
    if not CanParkHere(data.info, vehicle) then return lib.notify({description = 'This vehicle type cannot be parked here!', type = 'error'}) end
    local success = lib.callback.await('onebit_garages:server:ParkVehicle', false, VehToNet(vehicle), cache.vehicle ~= false, data, exports['cdn-fuel']:GetFuel(vehicle), core.GetVehicleProperties(vehicle))
    if success then lib.notify({description = 'Successful!', type = 'success'}) end
end

function TakeCarOut(vehicle, garage)
    if garage.info.type == 'depot' then
        local success = lib.callback.await('onebit_garages:server:DepotRemoveMoney', false, vehicle)
        if not success then lib.showContext('PreviewVehicle') return lib.notify({description = 'Not Enough Money', type = 'error'}) end
    end
    if not garage.info.spawner then
        lib.callback.await('onebit_garages:server:TakeVehicleOut', false, vehicle)
    end
    local model = joaat(vehicle.model)
    local coords = GetEntityCoords(previewcar)
    local heading = GetEntityHeading(previewcar)
    DeleteVehicle(previewcar)
    previewcar = nil
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
    CreateThread(function()
        local time = GetGameTimer()
        local timeout = 500
        while not IsEntityTouchingEntity(cache.ped, veh) and GetGameTimer() - time <= timeout do Wait(10) end
        while IsEntityTouchingEntity(cache.ped, veh) do
            SetEntityNoCollisionEntity(cache.ped, veh, true)
            Wait(0)
        end
    end)
    if vehicle.mods then core.SetVehicleProperties(veh, vehicle.mods) end
    exports['cdn-fuel']:SetFuel(veh, vehicle.fuel)
    SetVehicleEngineHealth(veh, vehicle.engine)
    SetVehicleBodyHealth(veh, vehicle.body)
    if not garage.info.spawner then SetVehicleNumberPlateText(veh, vehicle.fakeplate or vehicle.plate) end
    local vehstate = Entity(veh).state
    vehstate:set('vehicleLock', {
        lock = 0,
    }, true)
    vehstate:set('suspension', vehicle.otherdmg?.suspension or 50, true)
    vehstate:set('brakes', vehicle.otherdmg?.brakes or 50, true)
    vehstate:set('transmission', vehicle.otherdmg?.transmission or 50, true)
    vehstate:set('vehinfo', vehicle, true)
    Wait(1000)
    if garage.info.spawner then TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(veh))
    else TriggerServerEvent('onebit_garages:server:UpdatOutsideVehicles', VehToNet(veh), vehicle.plate) end
end

exports('adminmenu', function()
    return admin.OpenAdminMenu(lib.callback.await('onebit_garages:server:GetGarages', false))
end)

CreateThread(function()
    while GetResourceState('ox_lib') ~= 'started' do
        Wait(100)
    end
    garages = lib.callback.await('onebit_garages:server:GetGarages', false)
    for i = 1, #garages do
        zones[i] = lib.zones.poly({
            points = garages[i].zonepoints,
            thickness = garages[i].thickness or 15,
            info = garages[i],
            onEnter = onEnter,
            onExit = onExit,
            debug = Config.Debug,
            debugColour = 'blue'
        })
        if garages[i].blipcoords then
            blips[i] = utils.addBlip({
                coords = garages[i].blipcoords,
                id = 357,
                scale = 0.6,
                color = 3,
                name = garages[i].label
            })
        end
    end
end)

utils.RegisterNetEvent('onebit_garage:client:syncGarages', function(add, count, garage)
    if not add then
        zones[count]:remove()
        RemoveBlip(blips[count])
    end
    zones[(add and #zones + 1) or count] = lib.zones.poly({
        points = garage.zonepoints,
        thickness = garage.thickness or 15,
        info = garage,
        onEnter = onEnter,
        onExit = onExit,
        debug = Config.Debug,
        debugColour = 'blue'
    })
    if garage.blipcoords then
        utils.addBlip({
            coords = garage.blipcoords,
            id = 357,
            scale = 0.6,
            color = 3,
            name = garage.label
        })
    end
end)

utils.RegisterNetEvent('onebit_garage:client:removeGarage', function(count)
    zones[count]:remove()
    RemoveBlip(blips[count])
end)


CreateThread(function()
    local options = {
        {
            name = 'toggle_hose',
            command = 'hose',
            icon = 'fa-solid fa-road',
            label = 'Attach/Detach Hose',
            group = 'ambulance',
        },
        {
            name = 'setup_supply',
            command = 'supplyline setup',
            icon = 'fa-solid fa-road',
            label = 'Setup Supply Line',
            group = 'ambulance'
        },
        {
            name = 'remove_supply',
            command = 'supplyline remove',
            icon = 'fa-solid fa-road',
            label = 'Remove Supply Line',
            group = 'ambulance'
        },
    }
    exports.ox_target:addModel('lsfdtruck', options)
end)