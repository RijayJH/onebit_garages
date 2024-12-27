local db = {}


function db.updateTransaction(queries)
    return MySQL.transaction.await(queries)
end

local GET_ALL_LOCATIONS = 'SELECT * FROM `garagelocations`'
function db.GetAllLocations()
    return MySQL.query.await(GET_ALL_LOCATIONS)
end

local GET_VEHICLE_OWNER = 'SELECT `citizenid` FROM `player_vehicles` WHERE `plate` = ? LIMIT 1'
function db.GetVehicleOwner(plate)
    return MySQL.scalar.await(GET_VEHICLE_OWNER, {plate})
end

local PARK_VEHICLE = 'UPDATE `player_vehicles` SET `garage` = ?, `engine` = ?, `body` = ?, `state` = 1, `otherdmg` = ?, `fuel` = ?, `mods` = ?, `hold` = 0 WHERE `plate` = ?'
function db.ParkVehicle(plate, garage, engine, body, otherdmg, fuel, mods)
    return MySQL.update.await(PARK_VEHICLE, {garage, engine, body, json.encode(otherdmg), fuel, json.encode(mods), plate})
end

local TAKE_VEHICLE_OUT = 'UPDATE `player_vehicles` SET `state` = 0 WHERE `plate` = ?'
function db.TakeVehicleOut(plate)
    return MySQL.update.await(TAKE_VEHICLE_OUT, {plate})
end

local GET_PLAYER_VEHICLEs_IN_PUBLIC_GARAGE = 'SELECT * FROM `player_vehicles` WHERE `garage` = ? AND `citizenid` = ? AND `state` = 1'
function db.GetPlayerVehiclesinPublicGarage(garage, cid)
    return MySQL.query.await(GET_PLAYER_VEHICLEs_IN_PUBLIC_GARAGE, {garage, cid})
end

local GET_PLAYER_VEHICLEs_IN_SHARED_GARAGE = 'SELECT * FROM `player_vehicles` WHERE `garage` = ? AND `state` = 1'
function db.GetPlayerVehiclesinSharedGarage(garage)
    return MySQL.query.await(GET_PLAYER_VEHICLEs_IN_SHARED_GARAGE, {garage})
end

local GET_PLAYER_VEHICLEs_IN_DEPOT_GARAGE = 'SELECT * FROM `player_vehicles` WHERE `state` = 0 OR `state` = 2'
function db.GetPlayerVehiclesinDepotGarage()
    return MySQL.query.await(GET_PLAYER_VEHICLEs_IN_DEPOT_GARAGE, {})
end

local GET_PLAYER_VEHICLEs_FOR_RAID = 'SELECT * FROM `player_vehicles` WHERE `garage` = ? AND `citizenid` = ? AND `vinscratched` = 0 AND `state` = 1'
local GET_PLAYER_VEHICLEs_FOR_RAID_IN_DEPOT = 'SELECT * FROM `player_vehicles` WHERE `state` = 0 AND `citizenid` = ? AND `vinscratched` = 0'
function db.GetPlayerVehiclesForRaid(garage, cid)
    if garage.type == 'depot' then
        return MySQL.query.await(GET_PLAYER_VEHICLEs_FOR_RAID_IN_DEPOT, {cid})
    else 
        return MySQL.query.await(GET_PLAYER_VEHICLEs_FOR_RAID, {garage.garage.name, cid})
    end
end

local GET_MDT_POINTS = 'SELECT `points` FROM `mdt_vehicleinfo` WHERE `plate` = ? LIMIT 1'
function db.GetMDTPoints(plate)
    return MySQL.single.await(GET_MDT_POINTS, {plate})
end

local IMPOUND_VEHICLE = 'UPDATE `player_vehicles` SET `state` = ?, `hold` = ?, `garage` = ?, `fakeplate` = ? WHERE `plate` = ?'
function db.ImpoundVehicle(state, hold, garage, fakeplate, plate)
    return MySQL.update.await(IMPOUND_VEHICLE, {state, hold, garage, fakeplate, plate})
end

local DELETE_VEHICLE = 'DELETE FROM `player_vehicles` WHERE `plate` = ?'
function db.DeleteVehicle(plate)
    return MySQL.query.await(DELETE_VEHICLE, {plate})
end

local CREATE_GARAGE = 'INSERT INTO `garagelocations` (name, label, type, restriction, blipcoords, zonepoints, thickness, parkinglocations, vehicleCategories) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
function db.CreateGarage(data)
    local restriction = (type(data.restriction) == 'table' and json.encode(data.restriction)) or data.restriction
    return MySQL.insert.await(CREATE_GARAGE, {data.name, data.label, data.type, restriction, json.encode(data.blipcoords), json.encode(data.zonepoints), data.thickness, json.encode(data.parkinglocations), json.encode(data.vehicleCategories)})
end

local DELETE_GARAGE = 'DELETE FROM `garagelocations` WHERE `name` = ?'
function db.DeleteGarage(name)
    return MySQL.query.await(DELETE_GARAGE, {name})
end

local UPDATE_GARAGE = 'UPDATE `garagelocations` SET `label` = ?, `type` = ?, `restriction` = ?, `blipcoords` = ?, `zonepoints` = ?, `thickness` = ?, `parkinglocations` = ?, `vehicleCategories` = ? WHERE `name` = ?'
function db.UpdateGarage(garage)
    print(type(garage.restriction), json.encode(garage.restriction))
    local restriction = (type(garage.restriction) == 'table' and json.encode(garage.restriction)) or garage.restriction
    return MySQL.update.await(UPDATE_GARAGE, {garage.label, garage.type, restriction, json.encode(garage.blipcoords), json.encode(garage.zonepoints), garage.thickness, json.encode(garage.parkinglocations), json.encode(garage.vehicleCategories), garage.name})
end

local MOVE_CARS_FROM_DELETED_GARAGE = 'UPDATE `player_vehicles` SET `state` = 0 WHERE `garage` = ?'
function db.MoveCarsFromDeletedGarage(garagename)
    return MySQL.update.await(MOVE_CARS_FROM_DELETED_GARAGE, {garagename})
end

local PD_GARAGE = 'UPDATE `player_vehicles` SET `state` = 1 WHERE `garage` = ?'
function db.PDGarage()
    return MySQL.update.await(PD_GARAGE, {'pdgarage'})
end

return db