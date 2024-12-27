local db = require 'server.db'
local core = require 'server.core'
local garages = {}
local OutsideVehicles = {}

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        db.PDGarage()
    end
end)

-- IMPORT STUFF FROM IMPORT.LUA TO THE SQL

-- local import = require 'server.import'
-- CreateThread(function()
--     local UPDATE_TABLE = 'INSERT INTO `garagelocations` (`name`, `label`, `type`, `blipcoords`, `zonepoints`, `parkinglocations`, `vehicleCategories`) VALUES (?, ?, ?, ?, ?, ?, ?)'
--     local queries = {}
--     for i, v in pairs(import) do
--         local points = {}
--         for j, k in pairs(v.Zone.Shape) do
--             points[#points + 1] = vec3(k.x, k.y, v.Zone.minZ)
--         end
--         local values = { i, v.label, v.type, (v.showBlip and json.encode(v.blipcoords)) or nil, json.encode(points), json.encode(v.ParkingSpots), json.encode(v.vehicleCategories)}
--         queries[#queries + 1] = {
--             query = UPDATE_TABLE,
--             values = values
--         }
--     end
--     db.updateTransaction(queries)
--     print(json.encode(db.GetAllLocations(), {indent = true}))
-- end)

local function isAllowed(source, data)
    if data.type == 'public' or data.type == 'depot' then return true
    elseif data.type == 'job' then
        local job = core.GetJob(source)
        if not data.restriction then return false end
        if type(data.restriction) == 'table' then
            for i = 1, #data.restriction do
                if job.name == data.restriction[i] then return true end
            end
        else
            if job.name == data.restriction then return true end
        end
    elseif data.type == 'gang' then
        local gang = core.GetGang(source)
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

local function RemoveVehicleFromList(netid)
    if not DoesEntityExist(NetworkGetEntityFromNetworkId(netid)) then
        OutsideVehicles[netid] = nil
    end
end

exports('RemoveVehicleFromList', RemoveVehicleFromList)
-- Callbacks
lib.callback.register('onebit_garages:server:GetGarages', function()
    return garages
end)

lib.callback.register('onebit_garages:server:GetPublicVehicles', function(source, garage, cid)
    if not isAllowed(source, garage) then return end
    local results = db.GetPlayerVehiclesinPublicGarage(garage.name, cid)
    local vehicles = {}
    if not results then return end
    for i = 1, #results do
        local v = results[i]
        vehicles[#vehicles + 1] = {
            cid = v.citizenid,
            model = v.vehicle,
            fuel = v.fuel,
            state = v.state,
            engine = v.engine,
            body = v.body,
            plate = v.plate,
            fakeplate = v.fakeplate,
            garage = v.garage,
            otherdmg = json.decode(v.otherdmg),
            mods = json.decode(v.mods)
        }
    end
    return vehicles
end)

lib.callback.register('onebit_garages:server:GetHouseVehicles', function(source, garage, cid)
    local results = db.GetPlayerVehiclesinSharedGarage(garage.name)
    local vehicles = {}
    if not results then return end
    for i = 1, #results do
        local v = results[i]
        vehicles[#vehicles + 1] = {
            cid = v.citizenid,
            model = v.vehicle,
            fuel = v.fuel,
            state = v.state,
            engine = v.engine,
            body = v.body,
            plate = v.plate,
            fakeplate = v.fakeplate,
            garage = v.garage,
            otherdmg = json.decode(v.otherdmg),
            mods = json.decode(v.mods),
            vinscratched = v.vinscratched == 1 or nil
        }
    end
    return vehicles
end)

lib.callback.register('onebit_garages:server:GetJobVehicles', function(source, garage, cid)
    if not isAllowed(source, garage) then return end
    local results = db.GetPlayerVehiclesinSharedGarage(garage.name)
    local vehicles = {}
    if not results then return end
    for i = 1, #results do
        local v = results[i]
        vehicles[#vehicles + 1] = {
            cid = v.citizenid,
            model = v.vehicle,
            fuel = v.fuel,
            state = v.state,
            engine = v.engine,
            body = v.body,
            plate = v.plate,
            fakeplate = v.fakeplate,
            garage = v.garage,
            otherdmg = json.decode(v.otherdmg),
            mods = json.decode(v.mods),
            vinscratched = v.vinscratched == 1 or nil
        }
    end
    return vehicles
end)

lib.callback.register('onebit_garages:server:GetGangVehicles', function(source, garage, cid)
    if not isAllowed(source, garage) then return end
    local results = db.GetPlayerVehiclesinSharedGarage(garage.name)
    local vehicles = {}
    if not results then return end
    for i = 1, #results do
        local v = results[i]
        vehicles[#vehicles + 1] = {
            cid = v.citizenid,
            model = v.vehicle,
            fuel = v.fuel,
            state = v.state,
            engine = v.engine,
            body = v.body,
            plate = v.plate,
            fakeplate = v.fakeplate,
            garage = v.garage,
            otherdmg = json.decode(v.otherdmg),
            mods = json.decode(v.mods),
            vinscratched = v.vinscratched == 1 or nil
        }
    end
    return vehicles
end)

lib.callback.register('onebit_garages:server:ParkVehicle', function(source, netId, playerinside, data, fuel, mods)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not data.info.spawner then
        local vehstate = Entity(vehicle).state
        local plate = vehstate.vehinfo?.plate or GetVehicleNumberPlateText(vehicle)
        local owner = vehstate.vehinfo?.cid or db.GetVehicleOwner(plate)
        local raid = vehstate.vehinfo?.raid
        if not (owner == core.GetCID(source) or (raid and core.GetJob(source).name == 'police')) and (data.info.type == 'public' or data.info.type == 'depot') then lib.notify(source, {description = 'You cannot park this here!', type = 'error'}) return false end
        if not (owner == core.GetCID(source) or not (raid and core.GetJob(source).name == 'police')) and (data.info.type == 'job' or data.info.type == 'gang' or data.info.type == 'house') and vehstate.vehinfo?.garage ~= data.info.name then lib.notify(source, {description = 'You cannot park this here!', type = 'error'}) return false end
        db.ParkVehicle(plate, data.info.name, GetVehicleEngineHealth(vehicle), GetVehicleBodyHealth(vehicle), {suspension = vehstate.suspension or 80, brakes = vehstate.brakes or 80, transmission = vehstate.transmission or 80}, fuel, mods)
        OutsideVehicles[plate] = nil
    end
    if playerinside then
        for i = -1, 5, 1 do
            local ped = GetPedInVehicleSeat(vehicle, i)
            if ped then
                TaskLeaveVehicle(ped, vehicle, 0)
            end
        end
        Wait(1500)
    end
    DeleteEntity(vehicle)

    return true
end)

lib.callback.register('onebit_garages:server:GetDepotVehicles', function(source, garage, cid)
    local results = db.GetPlayerVehiclesinDepotGarage()
    local vehicles = {}
    if not results then return end
    local depotgarages = {}
    local job = core.GetJob(source)
    for k, v in pairs(garages) do
        if v.job == job then
            depotgarages[v.name] = true
        end
    end
    for i = 1, #results do
        local v = results[i]
        if OutsideVehicles[v.plate] then goto continue end
        if depotgarages[v.garage] or cid == v.citizenid then
            local points
            if v.state == 2 then points = db.GetMDTPoints(v.plate)?.points end
            vehicles[#vehicles + 1] = {
                cid = v.citizenid,
                model = v.vehicle,
                fuel = v.fuel,
                state = v.state,
                engine = v.engine,
                body = v.body,
                plate = v.plate,
                fakeplate = v.fakeplate,
                garage = v.garage,
                vinscratched = v.vinscratched == 1 or nil,
                otherdmg = json.decode(v.otherdmg),
                hold = (v.hold ~= 0 and os.date('%m-%d-%Y', v.hold)) or nil,
                mods = json.decode(v.mods),
                disable = (v.state == 2 and v.hold ~= 0 and os.time() - v.hold <= 0) or nil,
                price = (v.state == 2 and ((points and points ~= 0 and (points * Config.ImpoundPrices.Increments) + Config.ImpoundPrices.BasePrice) or Config.ImpoundPrices.BasePrice)) or nil
            }
        end
        ::continue::
    end
    return vehicles
end)

lib.callback.register('onebit_garages:server:RaidGarage', function(source, garage)
    if core.GetJob(source).name ~= 'police' then return end
    local results = db.GetPlayerVehiclesForRaid(garage, garage.cid)
    local vehicles = {}
    if not results then return end
    if garage.type == 'depot' then
        for i = 1, #results do
            local v = results[i]
            if OutsideVehicles[v.plate] then goto continue end
            vehicles[#vehicles + 1] = {
                cid = v.citizenid,
                model = v.vehicle,
                fuel = v.fuel,
                state = v.state,
                engine = v.engine,
                body = v.body,
                plate = v.plate,
                fakeplate = v.fakeplate,
                garage = v.garage,
                vinscratched = v.vinscratched == 1 or nil,
                otherdmg = json.decode(v.otherdmg),
                mods = json.decode(v.mods),
                raid = true,
            }
            ::continue::
        end
    else
        for i = 1, #results do
            local v = results[i]
            vehicles[#vehicles + 1] = {
                cid = v.citizenid,
                model = v.vehicle,
                fuel = v.fuel,
                state = v.state,
                engine = v.engine,
                body = v.body,
                plate = v.plate,
                fakeplate = v.fakeplate,
                garage = v.garage,
                otherdmg = json.decode(v.otherdmg),
                mods = json.decode(v.mods),
                vinscratched = v.vinscratched == 1 or nil,
                raid = true,
            }
        end
    end
    return vehicles
end)

lib.callback.register('onebit_garages:server:TakeVehicleOut', function(source, vehicle)
    exports['Renewed-Vehiclekeys']:addKey(source, vehicle.fakeplate or vehicle.plate)
    return db.TakeVehicleOut(vehicle.plate)
end)

lib.callback.register('onebit_garages:server:DepotRemoveMoney', function(source, vehicle)
    return exports.ox_inventory:RemoveItem(source, 'money', vehicle.price or Config.DepotPrice)
end)

lib.callback.register('onebit_garages:server:updateGarage', function(source, garage)
    if not exports["snipe-menu"]:isAdmin(source) then return end
    db.UpdateGarage(garage)
    local count
    for i = 1, #garages do
        if garage.name == garages[i].name then
            count = i
            break
        end
    end
    if not count then return false end
    garages[count] = {
        name = garage.name,
        label = garage.label,
        zonepoints = garage.zonepoints,
        thickness = garage.thickness,
        type = garage.type,
        restriction = garage.restriction,
        blipcoords = garage.blipcoords,
        parkinglocations = garage.parkinglocations,
        vehicleCategories = garage.vehicleCategories
    }
    TriggerClientEvent('onebit_garage:client:syncGarages', -1, false, count, garage)
end)

lib.callback.register('onebit_garages:server:addGarage', function(source, garage)
    if not exports["snipe-menu"]:isAdmin(source) then return end
    db.CreateGarage(garage)
    garages[#garages + 1] = {
        name = garage.name,
        label = garage.label,
        zonepoints = garage.zonepoints,
        thickness = garage.thickness,
        type = garage.type,
        restriction = garage.restriction,
        blipcoords = garage.blipcoords,
        parkinglocations = garage.parkinglocations,
        vehicleCategories = garage.vehicleCategories
    }
    TriggerClientEvent('onebit_garage:client:syncGarages', -1, true, count, garage)
end)

lib.callback.register('onebit_garages:server:deleteGarage', function(source, garage)
    if not exports["snipe-menu"]:isAdmin(source) then return end
    local count
    for i = 1, #garages do
        if garage.name == garages[i].name then
            count = i
            break
        end
    end
    if not count then return false end
    db.DeleteGarage(garage.name)
    db.MoveCarsFromDeletedGarage(garage.name)
    table.remove(garages, count)
    TriggerClientEvent('onebit_garage:client:removeGarage', -1, count)
end)

-- Events

RegisterNetEvent('onebit_garages:server:UpdatOutsideVehicles', function(vehnet, plate)
    OutsideVehicles[plate] = vehnet
end)

RegisterNetEvent('onebit_garages:server:ImpoundVehicle', function(netid, inputdate)
    local src = source
    local timestamp
    if inputdate ~= 0 then
        timestamp = math.floor(inputdate / 1000)
        local diff = (timestamp - os.time())
        if diff <= 0 then return lib.notify(src, {description = 'You cannot set that date', type = 'error'}) end
    end
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    local plate = GetVehicleNumberPlateText(vehicle)
    local vehinfo = Entity(vehicle).state.vehinfo
    if not vehinfo then return lib.notify(src, {description = 'This is not an owned vehicle', type = 'error'}) end
    if vehinfo.vinscratched then
        db.DeleteVehicle(vehinfo?.plate)
    end
    local affectedRows = db.ImpoundVehicle(2, timestamp or 0, 'impoundlot', nil, vehinfo.plate)
    if not affectedRows then print('sql didnt save for impounding vehicle with plate: '..plate) return end
    DeleteEntity(vehicle)
    OutsideVehicles[vehinfo.plate] = nil
    lib.notify(src, {description = 'Impounded', type = 'success'})
end)

-- Cron

-- lib.cron.new('* * * * *', function()
--     for i, v in pairs(OutsideVehicles) do
--         local vehicle = NetworkGetEntityFromNetworkId(v)
--         if not DoesEntityExist(vehicle) then
--             OutsideVehicles[i] = nil
--         end
--     end
-- end)

SetInterval(function()
    for i, v in pairs(OutsideVehicles) do
        local vehicle = NetworkGetEntityFromNetworkId(v)
        if not DoesEntityExist(vehicle) then
            OutsideVehicles[i] = nil
        end
    end
end, 30 * 60000)

-- Starting Thread
CreateThread(function()
    local result = db.GetAllLocations()
    for i, v in pairs(result) do
        local blipcoords = json.decode(v.blipcoords)
        local zonepoints = json.decode(v.zonepoints)
        local parkinglocations = json.decode(v.parkinglocations)
        local newzonepoints = {}
        local newparkinglocations = {}
        for l = 1, #zonepoints do
            newzonepoints[#newzonepoints + 1] = vec3(zonepoints[l].x, zonepoints[l].y, zonepoints[l].z)
        end
        if parkinglocations then
            for l = 1, #parkinglocations do
                newparkinglocations[#newparkinglocations + 1] = vec4(parkinglocations[l].x, parkinglocations[l].y, parkinglocations[l].z, parkinglocations[l].w)
            end
        end
        local restriction = json.decode(v.restriction)
        if type(restriction) == 'nil' then restriction = v.restriction end
        garages[#garages + 1] = {
            name = v.name,
            label = v.label,
            zonepoints = newzonepoints,
            thickness = v.thickness,
            type = v.type,
            restriction = restriction,
            blipcoords = blipcoords and vec3(blipcoords.x, blipcoords.y, blipcoords.z) or nil,
            parkinglocations = newparkinglocations,
            vehicleCategories = json.decode(v.vehicleCategories),
            spawner = v.spawner and json.decode(v.spawner)
        }
    end
    -- print(json.encode(garages, {indent = true}))
end)