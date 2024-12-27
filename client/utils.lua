local utils = {}

function utils.addBlip(settings)
    local blip = AddBlipForCoord(settings.coords.x, settings.coords.y, settings.coords.z)
    SetBlipSprite(blip, settings.id)
    SetBlipCategory(blip, 7)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, settings.scale)
    SetBlipColour(blip, settings.color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(settings.name)
    EndTextCommandSetBlipName(blip)
    return blip
end

function utils.GetClosestParking(garage)
    local mycoords = GetEntityCoords(cache.ped)
    local closestdistance = 100
    local spot
    for i = 1, #garage.parkinglocations do
        local v = vec3(garage.parkinglocations[i].x, garage.parkinglocations[i].y, garage.parkinglocations[i].z)
        local distance = #(v - mycoords)
        if distance < closestdistance then
            spot = i
            closestdistance = distance
        end
    end
    return garage.parkinglocations[spot]
end

local icons = {
    [0] = 'fa-solid fa-car-side',
    [1] = 'fa-solid fa-car-side',
    [2] = 'fa-solid fa-car-side',
    [3] = 'fa-solid fa-car-side',
    [4] = 'fa-solid fa-car-side',
    [5] = 'fa-solid fa-car-side',
    [6] = 'fa-solid fa-car-side',
    [7] = 'fa-solid fa-car-side',
    [8] = 'fa-solid fa-motorcycle',
    [9] = 'fa-solid fa-truck-monster',
    [10] = 'fa-solid fa-truck-moving',
    [11] = 'fa-solid fa-truck-pickup',
    [12] = 'fa-solid fa-van-shuttle',
    [13] = 'fa-solid fa-bicycle',
    [14] = 'fa-solid fa-sailboat',
    [15] = 'fa-solid fa-helicopter',
    [16] = 'fa-solid fa-plane',
    [17] = 'fa-solid fa-bus',
    [18] = 'fa-solid fa-taxi',
    [19] = 'fa-solid fa-car-side',
    [20] = 'fa-solid fa-bus',
    [21] = 'fa-solid fa-train',
    [22] = 'fa-solid fa-truck-monster'
}

function utils.GetIcon(model)
    local hash = joaat(model)
    local class = GetVehicleClassFromName(hash)
    return icons[class]
end

function utils.ConvertGarageNameToString(type)
    if type == 'public' then return 'Public'
    elseif type == 'job' then return 'Job'
    elseif type == 'gang' then return 'Gang'
    elseif type == 'depot' then return 'Depot'
    elseif type == 'house' then return 'House' end
end

function utils.RegisterNetEvent(event, fn)
    RegisterNetEvent(event, function(...)
        if source ~= '' then fn(...) end
    end)
end

return utils