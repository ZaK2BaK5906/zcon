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

-- Setup pickup zone with E key detection
function SetupPickupZone()
    if not activeDelivery or activeDelivery.stage ~= 'goto_pickup' then return end

    local location = activeDelivery.location

    print('[ZCon] Setting up pickup zone at', location.x, location.y, location.z)

    -- Create thread for E key detection
    CreateThread(function()
        while activeDelivery and activeDelivery.stage == 'goto_pickup' do
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            -- Check if player is in flatbed and in zone
            if vehicle ~= 0 then
                local model = GetEntityModel(vehicle)
                if model == GetHashKey(Config.ServiceVehicle.model) then
                    local vehicleCoords = GetEntityCoords(vehicle)
                    local distance = #(vehicleCoords - vector3(location.x, location.y, location.z))

                    if distance < 10.0 then
                        -- Show help text
                        lib.showTextUI(string.format('[E] Charger les véhicules (%dx %s)',
                            activeDelivery.order.quantity,
                            activeDelivery.order.vehicle_name),
                            {position = 'right-center'})

                        -- Check for E key press
                        if IsControlJustReleased(0, 38) then -- E key
                            lib.hideTextUI()
                            print('[ZCon] Loading vehicles...')
                            LoadVehicles()
                            return
                        end
                    else
                        lib.hideTextUI()
                    end
                else
                    lib.hideTextUI()
                end
            else
                lib.hideTextUI()
            end

            Wait(0)
        end

        lib.hideTextUI()
    end)

    print('[ZCon] Pickup zone created successfully')
end

-- Load vehicles onto flatbed with cinematic animations
function LoadVehicles()
    if not activeDelivery or activeDelivery.stage ~= 'goto_pickup' then return end

    local ped = PlayerPedId()
    local flatbed = GetVehiclePedIsIn(ped, false)

    if flatbed == 0 then
        Notify('Vous devez être dans le flatbed')
        return
    end

    local order = activeDelivery.order
    local vehicleModel = order.vehicle_model
    local quantity = order.quantity

    -- Save flatbed position
    local flatbedCoords = GetEntityCoords(flatbed)
    local flatbedHeading = GetEntityHeading(flatbed)

    -- Step 1: Exit vehicle with animation
    lib.notify({
        title = 'Chargement',
        description = 'Préparation du chargement...',
        type = 'info'
    })

    TaskLeaveVehicle(ped, flatbed, 0)
    Wait(2000)

    -- Step 2: Walk to side of flatbed
    local sideOffset = GetOffsetFromEntityInWorldCoords(flatbed, 3.0, 0.0, 0.0)
    TaskGoToCoordAnyMeans(ped, sideOffset.x, sideOffset.y, sideOffset.z, 1.0, 0, 0, 786603, 0xbf800000)
    Wait(3000)

    -- Step 3: Loading animation
    local animDict = 'anim@heists@box_carry@'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    -- Cinematic camera
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local camCoords = GetOffsetFromEntityInWorldCoords(flatbed, 8.0, -8.0, 3.0)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtEntity(cam, flatbed, 0.0, 0.0, 0.0, true)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, false)

    -- Request vehicle model
    local modelHash = GetHashKey(vehicleModel)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(100)
    end

    -- Loading animation loop
    lib.notify({
        title = 'Chargement',
        description = string.format('Chargement de %dx %s en cours...', quantity, order.vehicle_name),
        type = 'info',
        duration = 8000
    })

    for i = 1, math.min(quantity, 3) do
        -- Play loading animation
        TaskPlayAnim(ped, animDict, 'idle', 8.0, -8.0, 2000, 1, 0, false, false, false)
        Wait(2500)
    end

    -- Step 4: Spawn and attach vehicles
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

        Wait(100)
    end

    SetModelAsNoLongerNeeded(modelHash)

    -- Step 5: Return to flatbed
    ClearPedTasks(ped)
    Wait(500)

    TaskEnterVehicle(ped, flatbed, 5000, -1, 1.0, 1, 0)
    Wait(3000)

    -- Restore normal camera
    RenderScriptCams(false, true, 1000, true, false)
    DestroyCam(cam, false)

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

    lib.notify({
        title = 'Chargement terminé',
        description = string.format('%dx %s chargé(s)! Retournez à la concession', quantity, order.vehicle_name),
        type = 'success'
    })

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
end

-- Unload vehicles with cinematic animations
function UnloadVehicles()
    if not activeDelivery or activeDelivery.stage ~= 'goto_unload' then
        Notify('Aucune livraison en cours')
        return
    end

    local ped = PlayerPedId()
    local flatbed = GetVehiclePedIsIn(ped, false)

    if flatbed == 0 then
        Notify('Vous devez être dans le flatbed')
        return
    end

    -- Step 1: Exit vehicle
    lib.notify({
        title = 'Déchargement',
        description = 'Préparation du déchargement...',
        type = 'info'
    })

    TaskLeaveVehicle(ped, flatbed, 0)
    Wait(2000)

    -- Step 2: Walk to side
    local sideOffset = GetOffsetFromEntityInWorldCoords(flatbed, 3.0, 0.0, 0.0)
    TaskGoToCoordAnyMeans(ped, sideOffset.x, sideOffset.y, sideOffset.z, 1.0, 0, 0, 786603, 0xbf800000)
    Wait(2000)

    -- Step 3: Unloading animation
    local animDict = 'anim@heists@box_carry@'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    lib.notify({
        title = 'Déchargement',
        description = 'Déchargement des véhicules en cours...',
        type = 'info',
        duration = 5000
    })

    TaskPlayAnim(ped, animDict, 'idle', 8.0, -8.0, 3000, 1, 0, false, false, false)
    Wait(3500)

    -- Delete loaded vehicles
    for _, vehicle in ipairs(loadedVehicles) do
        if DoesEntityExist(vehicle) then
            DetachEntity(vehicle, true, true)
            DeleteEntity(vehicle)
        end
    end
    loadedVehicles = {}

    ClearPedTasks(ped)
    Wait(500)

    -- Step 4: Return to flatbed
    TaskEnterVehicle(ped, flatbed, 5000, -1, 1.0, 1, 0)
    Wait(3000)

    -- Complete delivery on server
    TriggerServerEvent('zcon:completeDelivery', activeDelivery.order.id)

    -- Clean up
    RemoveDeliveryBlip()
    activeDelivery = nil
    isAtPickupPoint = false
    isAtUnloadPoint = false

    lib.notify({
        title = 'Livraison terminée',
        description = 'Livraison terminée avec succès!',
        type = 'success'
    })
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
