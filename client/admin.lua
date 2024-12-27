local admin = {}
local garages = {}
local newgarage = {}
local editgarage = {}
local previewCar

local core = require 'client.core'
local zones = require 'client.zones'

local function ZoneStuff()
    return zones.startCreator()
end

local function GetParkingSpot(new)
    local spots = {}
    local gettingSpots = false
    local info = new and newgarage.parkinglocations or editgarage.parkinglocations

    lib.showTextUI('[E] Get Spot')

    CreateThread(function()
        while not gettingSpots do
            if IsControlJustPressed(0, 38) then
                local coords = GetEntityCoords(cache.ped)
                local heading = GetEntityHeading(cache.ped)
                if new then
                    newgarage.parkinglocations[#newgarage.parkinglocations + 1] = vec4(coords.x, coords.y, coords.z, heading)
                else
                    editgarage.parkinglocations[#editgarage.parkinglocations + 1] = vec4(coords.x, coords.y, coords.z, heading)
                end
                lib.hideTextUI()
                return ParkingSpotMenu(new)
            end
            Wait(0)
        end
    end)
end

local function ShowParkingSpot(spot, new)
    local showingSpot = false
    local info = new and newgarage.parkinglocations or editgarage.parkinglocations
    local previewcar

    lib.showTextUI('[E] Delete Spot | [G] Cancel')

    local model = joaat('sultan')

    lib.requestModel(model)
    previewcar = CreateVehicle(model, info[spot].x, info[spot].y, info[spot].z, info[spot].w, false, true)
    FreezeEntityPosition(previewcar, true)
    SetEntityCollision(previewcar, false, false)
    SetEntityDrawOutline(previewcar, true)
    SetEntityDrawOutlineColor(255 ,255 ,255 ,1)
    showingSpot = true

    CreateThread(function()
        while showingSpot do
            -- draw marker or vehicle
            if IsControlJustPressed(0, 38) then
                local alert = lib.alertDialog({
                    header = 'Delete Parking Spot',
                    content = 'Are you sure you want to delete this spot?',
                    centered = true,
                    cancel = true,
                })
                if alert == 'confirm' then
                    -- info[spot] = nil
                    -- local oldinfo = info
                    -- for i = 1, #oldinfo do
                    --     if oldinfo[i] ~= nil then
                    --         info[#info + 1] = oldinfo[i]
                    --     end
                    -- end
                    table.remove(info, spot)
                    if new then
                        newgarage.parkinglocations = info
                    else
                        editgarage.parkinglocations = info
                    end
                    showingSpot = false
                    lib.hideTextUI()
                    DeleteVehicle(previewcar)
                    ParkingSpotMenu(new)
                end
            elseif IsControlJustPressed(0, 47) then
                showingSpot = false
                lib.hideTextUI()
                DeleteVehicle(previewcar)
                ParkingSpotMenu(new)
            end
            Wait(0)
        end
                
    end)
end

function ParkingSpotMenu(new)
    local options = {}
    if not newgarage.parkinglocations then newgarage.parkinglocations = {} end
    if not editgarage.parkinglocations then editgarage.parkinglocations = {} end
    local info = new and newgarage.parkinglocations or editgarage.parkinglocations
    options[#options + 1] = {
        title = 'Add New Spot',
        icon = 'fa-solid fa-location-dot',
        onSelect = function()
            GetParkingSpot(new)
        end
    }

    for k,v in pairs(info) do
        options[#options + 1] = {
            title = ('%s. vec4(%.2f, %.2f, %.2f, %.2f)'):format(#options, v.x, v.y, v.z, v.w),
            icon = 'fa-solid fa-location-dot',
            onSelect = function()
                ShowParkingSpot(k, new)
            end,
        }
    end

    lib.registerContext({
        id = 'admin_parkingspotmenu',
        title = 'ParkingSpots',
        options = options,
        menu = new and 'admin_add_garage' or 'admin_edit_garage'
    })

    lib.showContext('admin_parkingspotmenu')
end

local function EditGarage(data)
    local options = {}
    if data then
        editgarage = data.garage
    end

    options[#options + 1] = {
        title = 'Edit Garage Label',
        description = editgarage.label,
        icon = 'fa-solid fa-list',
        onSelect = function()
            local input = lib.inputDialog('Change Garage Label', {
                {type = 'input', label = 'Garage Label', description = 'Needs to be between 4-15 characters (No Special Characters)', required = true, min = 4, max = 15}
            })

            if not input then return end
            if input[1] then
                editgarage.label = input[1]
            end
            return EditGarage()
        end
    }

    options[#options + 1] = {
        title = 'Vehicle Categories',
        description = (editgarage.vehicleCategories and json.encode(editgarage.vehicleCategories)),
        icon = 'fa-solid fa-bars',
        onSelect = function()
            local choice = {}
            for i, v in pairs(Config.VehicleCategories) do
                choice[#choice + 1] = {value = i}
            end
        
            local input = lib.inputDialog('Vehicle Categories', {
                {type = 'multi-select', options = choice, label = 'Choose Categories', required = true, default = editgarage.vehicleCategories}
            })
            if not input then return end
            editgarage.vehicleCategories = input[1]

            return EditGarage()
        end
    }

    local meta
    if editgarage.type and editgarage.restriction then
        meta = {editgarage.type == 'job' and 'Jobs:' or "Gangs:"}
        if type(editgarage.restriction) == 'table' then
            for i = 1, #editgarage.restriction do
                meta[#meta + 1] = {label = editgarage.restriction[i], value = 0}
            end
        else
            meta[#meta + 1] = {label = editgarage.restriction, value = 0}
        end
    end

    options[#options + 1] = {
        title = 'Edit Garage Type',
        description = editgarage.type,
        icon = 'fa-solid fa-car',
        onSelect = function()
            local choice = {}
            local input = lib.inputDialog('Change Garage Type', {
                {type = 'select', label = 'Select Garage Type', options = {
                    {value = 'public', label = 'Public Garage'},
                    {value = 'job', label = 'Job Garage'},
                    {value = 'gang', label = 'Gang Garage'},
                }, default = 'public'},
            })

            if not input then return end
            if input[1] == 'job' then
                for i, v in pairs(core.GetAllJobs()) do
                    choice[#choice + 1] = {value = i, label = v.label}
                end
            
                local input2 = lib.inputDialog('Job Restrictions', {
                    {type = 'multi-select', options = choice, label = 'Choose Jobs', required = true}
                })
                if not input2 then return end
                if #input2[1] == 1 then input2[1] = input2[1][1] end
                editgarage.type = input[1]
                editgarage.restriction = input2[1]
            elseif input[1] == 'gang' then
                for i, v in pairs(core.GetAllGangs()) do
                    choice[#choice + 1] = {value = i, label = v.label}
                end
            
                local input2 = lib.inputDialog('Gang Restrictions', {
                    {type = 'multi-select', options = choice, label = 'Choose Gangs', required = true}
                })
                if not input2 then return end
                if #input2[1] == 1 then input2[1] = input2[1][1] end
                editgarage.type = input[1]
                editgarage.restriction = input2[1]
            else
                editgarage.type = input[1]
                editgarage.restriction = nil
            end
            return EditGarage()
        end, 
        metadata = meta
    }

    options[#options + 1] = {
        title = 'Set Zones',
        description = 'Set Garage Zone Perimeter',
        icon = 'fa-solid fa-table-cells-large',
        onSelect = function()
            local points, thickness = ZoneStuff()
            if points then
                editgarage.zonepoints = points
                editgarage.thickness = thickness
            end
            EditGarage()
        end
    }

    options[#options + 1] = {
        title = 'Blip Location',
        description = (editgarage.blipcoords and ('vec3(%2f, %2f, %2f)'):format(editgarage.blipcoords.x, editgarage.blipcoords.y, editgarage.blipcoords.z)),
        icon = 'fa-solid fa-location-dot',
        onSelect = function()
            CreateThread(function()
                lib.showTextUI('[E] - Set Blip Location', options)
                local finish = false
                while not finish do
                    if IsControlJustPressed(0, 38) then
                        finish = true
                        lib.hideTextUI()
                        editgarage.blipcoords = GetEntityCoords(cache.ped)
                        return EditGarage()
                    end
                    Wait(0)
                end
            end)
        end
    }

    options[#options + 1] = {
        title = 'Set Parking Spots',
        description = 'Set Various Spots For Vehicles To Spawn',
        icon = 'fa-solid fa-table-cells-large',
        onSelect = function()
            ParkingSpotMenu()
        end
    }

    options[#options + 1] = {
        title = 'Save Garage',
        icon = 'fa-solid fa-floppy-disk',
        onSelect = function()
            lib.callback.await('onebit_garages:server:updateGarage', false, editgarage)
        end
    }

    options[#options + 1] = {
        title = 'Remove Garage',
        icon = 'fa-solid fa-trash',
        onSelect = function()
            local alert = lib.alertDialog({
                header = 'Delete Garage',
                content = 'Are you sure you want to delete this garage?',
                centered = true,
                cancel = true,
            })
            if alert == 'confirm' then
                lib.callback.await('onebit_garages:server:deleteGarage', false, editgarage)
            end
        end
    }

    lib.registerContext({
        id = 'admin_edit_garage',
        title = 'Edit Garage',
        options = options
    })

    lib.showContext('admin_edit_garage')
end

local function AddNewGarage(new)
    if new then newgarage = {} end
    options = {}
    
    options[#options + 1] = {
        title = 'Garage Name',
        description = newgarage.name or 'Not Set',
        icon = 'fa-solid fa-chevron-right',
        onSelect = function()
            local input = lib.inputDialog('Add', {
                {type = 'input', label = 'Garage Name', description = 'Needs to be between 4-15 characters (no spaces allowed)', required = true, min = 4, max = 15},
            })
            if not input then return AddNewGarage() end
            if string.match(input[1], ' ') then lib.notify({description = 'Spaces not allowed!', type = 'error'}) return AddNewGarage() end
            local garages = lib.callback.await('onebit_garages:server:GetGarages', false)
            for i = 1, #garages do
                if garages[i].name == input[1] then
                    lib.notify({description = 'Garage Name Already Exists', type = 'error'})
                    return AddNewGarage()
                end
            end
            newgarage.name = input[1]
            return AddNewGarage()
        end
    }
    options[#options + 1] = {
        title = 'Garage Label',
        icon = 'fa-solid fa-chevron-right',
        description = newgarage.label or 'Not Set',
        onSelect = function()
            local input = lib.inputDialog('Add', {
                {type = 'input', label = 'Garage Label', required = true},
            })
            if not input then return AddNewGarage() end
            newgarage.label = input[1]
            return AddNewGarage()
        end
    }
    options[#options + 1] = {
        title = 'Blip Location',
        description = (newgarage.blipcoords and ('vec3(%2f, %2f, %2f)'):format(newgarage.blipcoords.x, newgarage.blipcoords.y, newgarage.blipcoords.z)) or 'Not Set',
        icon = 'fa-solid fa-location-dot',
        onSelect = function()
            CreateThread(function()
                lib.showTextUI('[E] - Set Blip Location', options)
                local finish = false
                while not finish do
                    if IsControlJustPressed(0, 38) then
                        finish = true
                        lib.hideTextUI()
                        newgarage.blipcoords = GetEntityCoords(cache.ped)
                        return AddNewGarage()
                    end
                    Wait(0)
                end
            end)
        end
    }
    options[#options + 1] = {
        title = 'Vehicle Categories',
        description = (newgarage.vehicleCategories and json.encode(newgarage.vehicleCategories)) or 'Not Set',
        icon = 'fa-solid fa-bars',
        onSelect = function()
            local choice = {}
            for i, v in pairs(Config.VehicleCategories) do
                choice[#choice + 1] = {value = i}
            end
        
            local input = lib.inputDialog('Vehicle Categories', {
                {type = 'multi-select', options = choice, label = 'Choose Categories', required = true}
            })
            if not input then return end
            newgarage.vehicleCategories = input[1]

            return AddNewGarage()
        end
    }
    local meta
    if newgarage.type and newgarage.restriction then
        meta = {newgarage.type == 'job' and 'Jobs:' or "Gangs:"}
        if type(newgarage.restriction) == 'table' then
            for i = 1, #newgarage.restriction do
                meta[#meta + 1] = {label = newgarage.restriction[i], value = 0}
            end
        else
            meta[#meta + 1] = {label = newgarage.restriction, value = 0}
        end
    end
    options[#options + 1] = {
        title = 'Garage Type',
        description = newgarage.type or 'Not Set',
        icon = 'fa-solid fa-font-awesome',
        onSelect = function()
            local choice = {}
            local input = lib.inputDialog('Change Garage Type', {
                {type = 'select', label = 'Select Garage Type', options = {
                    {value = 'public', label = 'Public Garage'},
                    {value = 'job', label = 'Job Garage'},
                    {value = 'gang', label = 'Gang Garage'},
                }, default = 'public'},
            })
            if not input then return end
            if input[1] == 'job' then
                for i, v in pairs(core.GetAllJobs()) do
                    choice[#choice + 1] = {value = i, label = v.label}
                end
            
                local input2 = lib.inputDialog('Job Restrictions', {
                    {type = 'multi-select', options = choice, label = 'Choose Jobs', required = true}
                })
                if not input2 then return end
                if #input2[1] == 1 then input2[1] = input2[1][1] end
                newgarage.type = input[1]
                newgarage.restriction = input2[1]
            elseif input[1] == 'gang' then
                for i, v in pairs(core.GetAllGangs()) do
                    choice[#choice + 1] = {value = i, label = v.label}
                end
            
                local input2 = lib.inputDialog('Gang Restrictions', {
                    {type = 'multi-select', options = choice, label = 'Choose Gangs', required = true}
                })
                if not input2 then return end
                if #input2[1] == 1 then input2[1] = input2[1][1] end
                newgarage.type = input[1]
                newgarage.restriction = input2[1]
            else
                newgarage.type = input[1]
                newgarage.restriction = nil
            end
            return AddNewGarage()
        end,
        metadata = meta
    }
    options[#options + 1] = {
        title = 'Set Zones',
        description = (newgarage.zonepoints and 'Set') or 'Not Set',
        icon = 'fa-solid fa-table-cells-large',
        onSelect = function()
            local points, thickness = ZoneStuff()
            if points then
                newgarage.zonepoints = points
                newgarage.thickness = thickness
            end
            AddNewGarage()
        end
    }

    options[#options + 1] = {
        title = 'Set Parking Spots',
        description = 'Set Various Spots For Vehicles To Spawn',
        icon = 'fa-solid fa-table-cells-large',
        onSelect = function()
            ParkingSpotMenu(true)
        end
    }

    options[#options + 1] = {
        title = 'Save Garage',
        icon = 'fa-solid fa-floppy-disk',
        onSelect = function()
            if newgarage.zonepoints and newgarage.thickness and newgarage.type and newgarage.vehicleCategories and newgarage.label and newgarage.name then
                lib.callback.await('onebit_garages:server:addGarage', false, newgarage)
            else
                lib.notify({description = 'Not Enough Info!', type = 'error'})
                AddNewGarage()
            end
        end
    }

    lib.registerContext({
        id = 'admin_add_garage',
        title = 'Add Garage',
        options = options
    })

    lib.showContext('admin_add_garage')
end

local function ShowGarages()
    local options = {}
    for i, v in pairs(garages) do
        options[#options + 1] = {
            title = v.label,
            icon = 'fa-solid fa-square-parking',
            description = 'Select to edit location',
            args = {
                garage = v
            },
            onSelect = EditGarage,
        }
    end

    lib.registerContext({
        id = 'admin_show_garages',
        title = 'Garages',
        options = options
    })

    lib.showContext('admin_show_garages')
end

function admin.OpenAdminMenu(info)
    if not exports["snipe-menu"]:isAdmin() then return end
    garages = info
    lib.registerContext({
        id = 'admin_garage_menu',
        title = 'Garage Admin Menu',
        options = {
            {
                title = 'Show Garages ',
                icon = 'fa-solid fa-list',
                description = 'Show All Garages',
                onSelect = ShowGarages  
            },
            {
                title = 'Add Garage',
                icon = 'fa-solid fa-plus',
                description = 'Add a new garage',
                onSelect = function()
                    AddNewGarage(true)
                end,
            }
        }
    })

    lib.showContext('admin_garage_menu')
end

return admin