local activeDelivery = nil
local deliveryBlip = nil
local deliveryVehicles = {}
local isAtPickupPoint = false
local isAtUnloadPoint = false
local loadedVehicles = {}

-- Notify function
local function Notify(message, type)
    ESX.ShowNotification(message)
end

-- Simple progress bar
local function ProgressBar(duration, label, onComplete)
    local playerPed = PlayerPedId()

    -- Load animation
    RequestAnimDict(Config.LoadAnimation.dict)
    while not HasAnimDictLoaded(Config.LoadAnimation.dict) do
        Wait(10)
    end

    TaskPlayAnim(playerPed, Config.LoadAnimation.dict, Config.LoadAnimation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Show notification
    Notify(label, 'info')

    -- Wait for duration
    Wait(duration)

    -- Stop animation
    ClearPedTasks(playerPed)

    -- Callback
    if onComplete then
        onComplete()
    end
end

-- Create blip
local function CreateDeliveryBlip(coords, sprite, color, text)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
    SetBlipRoute(blip, true)
    return blip
end

-- Remove blip
local function RemoveDeliveryBlip()
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
end

-- Start delivery mission
RegisterNetEvent('zcon:startDeliveryMission', function(order, deliveryLocation)
    if activeDelivery then
        Notify('Vous avez déjà une livraison en cours')
        return
    end

    activeDelivery = {
        order = order,
        location = deliveryLocation,
        stage = 'goto_pickup'  -- Stages: goto_pickup, load, goto_unload, unload
    }

    -- Create blip for pickup location
    deliveryBlip = CreateDeliveryBlip(
        vector3(deliveryLocation.x, deliveryLocation.y, deliveryLocation.z),
        67, -- Delivery truck icon
        5,  -- Yellow
        'Point de livraison'
    )

    Notify('Rendez-vous au point de livraison marqué sur votre GPS')

    -- Start monitoring distance to pickup point
    CreateThread(function()
        while activeDelivery and activeDelivery.stage == 'goto_pickup' do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(deliveryLocation.x, deliveryLocation.y, deliveryLocation.z))

            if distance < 50.0 and not isAtPickupPoint then
                isAtPickupPoint = true
                SetupPickupZone()
            elseif distance >= 50.0 and isAtPickupPoint then
                isAtPickupPoint = false
            end

            Wait(1000)
        end
    end)
end)

-- Setup pickup zone with ox_target
function SetupPickupZone()
    if not activeDelivery or activeDelivery.stage ~= 'goto_pickup' then return end

    local location = activeDelivery.location

    print('[ZCon] Setting up pickup zone at', location.x, location.y, location.z)

    -- Remove any existing pickup zone first
    exports.ox_target:removeZone('concess_pickup_zone')

    -- Add temporary target zone
    exports.ox_target:addBoxZone({
        coords = vector3(location.x, location.y, location.z),
        size = vector3(10.0, 10.0, 4.0),
        rotation = location.w or 0.0,
        debug = true,  -- Show the zone for debugging
        name = 'concess_pickup_zone',
        options = {
            {
                name = 'concess_pickup',
                icon = 'fa-solid fa-truck-loading',
                label = string.format('Charger les véhicules (%dx %s)', activeDelivery.order.quantity, activeDelivery.order.vehicle_name),
                canInteract = function()
                    local ped = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(ped, false)

                    -- Allow interaction if in flatbed
                    if vehicle ~= 0 then
                        local model = GetEntityModel(vehicle)
                        if model == GetHashKey(Config.ServiceVehicle.model) then
                            return true
                        end
                    end

                    -- Also allow if near a flatbed (within 5 meters)
                    local playerCoords = GetEntityCoords(ped)
                    local nearbyVehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 71)

                    if nearbyVehicle ~= 0 then
                        local model = GetEntityModel(nearbyVehicle)
                        if model == GetHashKey(Config.ServiceVehicle.model) then
                            return true
                        end
                    end

                    return false
                end,
                onSelect = function()
                    print('[ZCon] Loading vehicles...')
                    LoadVehicles()
                end
            }
        }
    })

    print('[ZCon] Pickup zone created successfully')
end

-- Load vehicles onto flatbed
function LoadVehicles()
    if not activeDelivery or activeDelivery.stage ~= 'goto_pickup' then return end

    local ped = PlayerPedId()
    local flatbed = GetVehiclePedIsIn(ped, false)

    if flatbed == 0 then
        Notify('Vous devez être dans le flatbed')
        return
    end

    -- Progress bar
    ProgressBar(Config.LoadAnimation.duration, 'Chargement des véhicules...', function()
        -- Spawn vehicles and attach to flatbed
        local order = activeDelivery.order
        local vehicleModel = order.vehicle_model
        local quantity = order.quantity

        -- Request model
        local modelHash = GetHashKey(vehicleModel)
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(100)
        end

        -- Get flatbed position
        local flatbedCoords = GetEntityCoords(flatbed)
        local flatbedHeading = GetEntityHeading(flatbed)

        -- Calculate positions for multiple vehicles (stack them)
        local offsets = {
            {x = 0.0, y = -2.0, z = 1.2},
            {x = 0.0, y = 0.5, z = 1.2},
            {x = 0.0, y = 3.0, z = 1.2},
            {x = 0.0, y = -2.0, z = 2.8},
            {x = 0.0, y = 0.5, z = 2.8},
            {x = 0.0, y = 3.0, z = 2.8},
            {x = 0.0, y = -2.0, z = 4.4},
            {x = 0.0, y = 0.5, z = 4.4},
            {x = 0.0, y = 3.0, z = 4.4},
            {x = 0.0, y = -2.0, z = 6.0}
        }

        for i = 1, math.min(quantity, 10) do
            local offset = offsets[i] or offsets[1]

            -- Create vehicle
            local vehicle = CreateVehicle(modelHash, flatbedCoords.x, flatbedCoords.y, flatbedCoords.z, flatbedHeading, true, false)

            if DoesEntityExist(vehicle) then
                SetEntityAsMissionEntity(vehicle, true, true)
                SetVehicleDoorsLocked(vehicle, 2)
                SetEntityInvincible(vehicle, true)
                FreezeEntityPosition(vehicle, true)

                -- Attach to flatbed
                AttachEntityToEntity(
                    vehicle,
                    flatbed,
                    0,
                    offset.x, offset.y, offset.z,
                    0.0, 0.0, 0.0,
                    false, false, false, false, 0, true
                )

                table.insert(loadedVehicles, vehicle)
            end
        end

        SetModelAsNoLongerNeeded(modelHash)

        -- Update delivery stage
        activeDelivery.stage = 'goto_unload'
        RemoveDeliveryBlip()

        -- Create blip for unload zone
        local unloadCoords = Config.Zones.Unload.coords
        deliveryBlip = CreateDeliveryBlip(
            unloadCoords,
            50, -- Garage icon
            2,  -- Green
            'Zone de déchargement'
        )

        Notify(string.format('%dx %s chargé(s)! Retournez à la concession', quantity, order.vehicle_name))

        -- Monitor distance to unload point
        CreateThread(function()
            while activeDelivery and activeDelivery.stage == 'goto_unload' do
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - unloadCoords)

                if distance < 10.0 and not isAtUnloadPoint then
                    isAtUnloadPoint = true
                elseif distance >= 10.0 and isAtUnloadPoint then
                    isAtUnloadPoint = false
                end

                Wait(1000)
            end
        end)
    end)
end

-- Unload vehicles
function UnloadVehicles()
    if not activeDelivery or activeDelivery.stage ~= 'goto_unload' then
        Notify('Aucune livraison en cours')
        return
    end

    -- Progress bar
    ProgressBar(Config.LoadAnimation.duration, 'Déchargement des véhicules...', function()
        -- Delete loaded vehicles
        for _, vehicle in ipairs(loadedVehicles) do
            if DoesEntityExist(vehicle) then
                DetachEntity(vehicle, true, true)
                DeleteEntity(vehicle)
            end
        end
        loadedVehicles = {}

        -- Complete delivery on server
        TriggerServerEvent('zcon:completeDelivery', activeDelivery.order.id)

        -- Clean up
        RemoveDeliveryBlip()
        activeDelivery = nil
        isAtPickupPoint = false
        isAtUnloadPoint = false

        Notify('Livraison terminée avec succès!')
    end)
end

-- Cancel delivery on disconnect/job change
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if activeDelivery then
        TriggerServerEvent('zcon:cancelDelivery', activeDelivery.order.id)
        CleanupDelivery()
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    if job.name ~= Config.JobName and activeDelivery then
        TriggerServerEvent('zcon:cancelDelivery', activeDelivery.order.id)
        CleanupDelivery()
    end
end)

-- Cleanup delivery
function CleanupDelivery()
    -- Delete loaded vehicles
    for _, vehicle in ipairs(loadedVehicles) do
        if DoesEntityExist(vehicle) then
            DetachEntity(vehicle, true, true)
            DeleteEntity(vehicle)
        end
    end
    loadedVehicles = {}

    RemoveDeliveryBlip()
    activeDelivery = nil
    isAtPickupPoint = false
    isAtUnloadPoint = false
end

-- Exports for ox_target
exports('HasActiveDelivery', function()
    return activeDelivery ~= nil and activeDelivery.stage == 'goto_unload'
end)

exports('UnloadVehicles', function()
    UnloadVehicles()
end)
