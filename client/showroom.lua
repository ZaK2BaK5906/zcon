local showroomVehicles = {} -- [spotIndex] = {vehicle = entity, model = string, name = string}

-- Get all vehicles from catalog
local function GetAllVehicles()
    local allVehicles = {}
    for _, category in ipairs(Config.Vehicles) do
        for _, vehicle in ipairs(category.vehicles) do
            table.insert(allVehicles, {
                model = vehicle.model,
                name = vehicle.name,
                price = vehicle.price,
                category = category.category
            })
        end
    end
    return allVehicles
end

-- Open showroom management menu
function OpenShowroomMenu()
    if not HasJob() then
        lib.notify({
            title = 'Erreur',
            description = 'Vous n\'êtes pas employé de la concession',
            type = 'error'
        })
        return
    end

    local options = {}

    -- Add option to place vehicles
    for i, spot in ipairs(Config.ShowroomSpots) do
        local spotOccupied = showroomVehicles[i] ~= nil

        table.insert(options, {
            title = string.format('Emplacement %d', i),
            description = spotOccupied and
                string.format('🚗 %s (Cliquer pour retirer)', showroomVehicles[i].name) or
                '📍 Emplacement libre (Cliquer pour placer)',
            icon = spotOccupied and 'car' or 'plus',
            onSelect = function()
                if spotOccupied then
                    RemoveShowroomVehicle(i)
                else
                    PlaceShowroomVehicle(i)
                end
            end
        })
    end

    lib.registerContext({
        id = 'showroom_management',
        title = '🏢 Gestion Showroom',
        menu = 'concess_main',
        options = options
    })

    lib.showContext('showroom_management')
end

-- Place vehicle in showroom
function PlaceShowroomVehicle(spotIndex)
    local allVehicles = GetAllVehicles()
    local vehicleOptions = {}

    -- Group by category
    local categories = {}
    for _, vehicle in ipairs(allVehicles) do
        if not categories[vehicle.category] then
            categories[vehicle.category] = {}
        end
        table.insert(categories[vehicle.category], vehicle)
    end

    -- Create menu options by category
    for category, vehicles in pairs(categories) do
        table.insert(vehicleOptions, {
            title = category,
            description = string.format('%d véhicules', #vehicles),
            icon = 'folder',
            onSelect = function()
                ShowVehiclesByCategory(category, vehicles, spotIndex)
            end
        })
    end

    lib.registerContext({
        id = 'showroom_select_category',
        title = string.format('📍 Emplacement %d - Choisir catégorie', spotIndex),
        menu = 'showroom_management',
        options = vehicleOptions
    })

    lib.showContext('showroom_select_category')
end

-- Show vehicles by category
function ShowVehiclesByCategory(category, vehicles, spotIndex)
    local options = {}

    for _, vehicle in ipairs(vehicles) do
        table.insert(options, {
            title = vehicle.name,
            description = string.format('$%s', ESX.Math.GroupDigits(vehicle.price)),
            icon = 'car',
            onSelect = function()
                SpawnShowroomVehicle(spotIndex, vehicle)
            end
        })
    end

    lib.registerContext({
        id = 'showroom_select_vehicle',
        title = string.format('%s - %s', category, 'Choisir véhicule'),
        menu = 'showroom_select_category',
        options = options
    })

    lib.showContext('showroom_select_vehicle')
end

-- Spawn vehicle in showroom
function SpawnShowroomVehicle(spotIndex, vehicleData)
    local spot = Config.ShowroomSpots[spotIndex]

    ESX.Game.SpawnVehicle(vehicleData.model, vector3(spot.x, spot.y, spot.z), spot.w, function(vehicle)
        if DoesEntityExist(vehicle) then
            -- Configure vehicle for showroom
            SetVehicleDoorsLocked(vehicle, 2) -- Lock vehicle
            SetEntityInvincible(vehicle, true)
            FreezeEntityPosition(vehicle, true)
            SetVehicleEngineOn(vehicle, false, true, true)
            SetVehicleUndriveable(vehicle, true)

            -- Store in showroom data
            showroomVehicles[spotIndex] = {
                vehicle = vehicle,
                model = vehicleData.model,
                name = vehicleData.name,
                price = vehicleData.price
            }

            lib.notify({
                title = 'Showroom',
                description = string.format('%s placé à l\'emplacement %d', vehicleData.name, spotIndex),
                type = 'success'
            })

            OpenShowroomMenu()
        else
            lib.notify({
                title = 'Erreur',
                description = 'Impossible de spawner le véhicule',
                type = 'error'
            })
        end
    end)
end

-- Remove vehicle from showroom
function RemoveShowroomVehicle(spotIndex)
    if showroomVehicles[spotIndex] then
        local vehicle = showroomVehicles[spotIndex].vehicle
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end

        showroomVehicles[spotIndex] = nil

        lib.notify({
            title = 'Showroom',
            description = string.format('Véhicule retiré de l\'emplacement %d', spotIndex),
            type = 'success'
        })

        OpenShowroomMenu()
    end
end

-- Setup showroom vehicle interaction
CreateThread(function()
    Wait(1000)

    for spotIndex, spot in ipairs(Config.ShowroomSpots) do
        -- Create interaction zone around each spot
        exports.ox_target:addSphereZone({
            coords = vector3(spot.x, spot.y, spot.z),
            radius = 2.5,
            options = {
                {
                    name = 'showroom_vehicle_' .. spotIndex,
                    icon = 'fa-solid fa-car',
                    label = 'Voir le véhicule',
                    canInteract = function()
                        return showroomVehicles[spotIndex] ~= nil
                    end,
                    onSelect = function()
                        ShowShowroomVehicleInfo(spotIndex)
                    end
                }
            }
        })
    end
end)

-- Show showroom vehicle info (for citizens)
function ShowShowroomVehicleInfo(spotIndex)
    local vehicleData = showroomVehicles[spotIndex]
    if not vehicleData then return end

    local options = {
        {
            title = '📋 Informations',
            description = string.format('Modèle: %s\nPrix: $%s',
                vehicleData.name,
                ESX.Math.GroupDigits(vehicleData.price)),
            icon = 'info',
            disabled = true
        }
    }

    -- If player has job, allow to interact
    if HasJob() then
        table.insert(options, {
            title = '🗑️ Retirer du showroom',
            description = 'Retirer ce véhicule de l\'exposition',
            icon = 'trash',
            onSelect = function()
                RemoveShowroomVehicle(spotIndex)
            end
        })
    end

    lib.registerContext({
        id = 'showroom_vehicle_info',
        title = string.format('🚗 %s', vehicleData.name),
        options = options
    })

    lib.showContext('showroom_vehicle_info')
end

-- Cleanup showroom on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, data in pairs(showroomVehicles) do
        if DoesEntityExist(data.vehicle) then
            DeleteEntity(data.vehicle)
        end
    end
end)
