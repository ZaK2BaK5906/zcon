ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local currentStock = {}
local currentOrders = {}
local isUIOpen = false

-- Get player data
CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Wait(100)
    end
    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
    if isUIOpen then
        CloseUI()
    end
end)

-- Check if player has concess job
local function HasJob()
    return PlayerData.job and PlayerData.job.name == Config.JobName
end

-- Get player grade
local function GetGrade()
    if HasJob() then
        return PlayerData.job.grade
    end
    return -1
end

-- Check if player is boss
local function IsBoss()
    return GetGrade() >= Config.BossGrade
end

-- Notify function
RegisterNetEvent('zcon:notify', function(message, type)
    ESX.ShowNotification(message)
end)

-- Update society money in NUI
RegisterNetEvent('zcon:updateSocietyMoney', function(money)
    if isUIOpen then
        SendNUIMessage({
            type = 'updateSocietyMoney',
            money = money
        })
    end
end)

-- Refresh stock
RegisterNetEvent('zcon:refreshStock', function()
    if isUIOpen then
        ESX.TriggerServerCallback('zcon:getStock', function(stock)
            currentStock = stock
        end)
    end
end)

-- Refresh orders
RegisterNetEvent('zcon:refreshOrders', function()
    if isUIOpen then
        ESX.TriggerServerCallback('zcon:getOrders', function(orders)
            currentOrders = orders
        end)
    end
end)

-- Open UI
function OpenUI()
    if not HasJob() then
        ESX.ShowNotification('Vous n\'êtes pas employé de la concession')
        return
    end

    -- Get all data
    ESX.TriggerServerCallback('zcon:getStock', function(stock)
        ESX.TriggerServerCallback('zcon:getCatalog', function(catalog)
            ESX.TriggerServerCallback('zcon:getOrders', function(orders)
                ESX.TriggerServerCallback('zcon:getSocietyMoney', function(societyMoney)
                    currentStock = stock
                    currentOrders = orders

                    SetNuiFocus(true, true)
                    isUIOpen = true

                    SendNUIMessage({
                        type = 'openUI',
                        stock = stock,
                        catalog = catalog,
                        orders = orders,
                        societyMoney = societyMoney,
                        isBoss = IsBoss()
                    })
                end)
            end)
        end)
    end)
end

-- Close UI
function CloseUI()
    SetNuiFocus(false, false)
    isUIOpen = false
    SendNUIMessage({
        type = 'closeUI'
    })
end

-- Force close UI (safety measure)
CreateThread(function()
    while true do
        Wait(1000)
        if not HasJob() and isUIOpen then
            CloseUI()
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('placeOrder', function(data, cb)
    TriggerServerEvent('zcon:placeOrder', data.model, data.name, data.quantity, data.totalPrice)
    cb('ok')
end)

RegisterNUICallback('startDelivery', function(data, cb)
    TriggerServerEvent('zcon:startDelivery', data.orderId)
    cb('ok')
end)

RegisterNUICallback('withdrawMoney', function(data, cb)
    TriggerServerEvent('zcon:withdrawMoney', data.amount)
    cb('ok')
end)

RegisterNUICallback('depositMoney', function(data, cb)
    TriggerServerEvent('zcon:depositMoney', data.amount)
    cb('ok')
end)

-- Spawn service vehicle
RegisterNetEvent('zcon:spawnServiceVehicle', function()
    local spawnPoint = Config.Zones.Garage.spawnPoint

    ESX.Game.SpawnVehicle(Config.ServiceVehicle.model, vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z), spawnPoint.w, function(vehicle)
        if DoesEntityExist(vehicle) then
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

            if Config.ServiceVehicle.livery then
                SetVehicleLivery(vehicle, Config.ServiceVehicle.livery)
            end

            ESX.ShowNotification('Véhicule de service sorti')
        else
            ESX.ShowNotification('Erreur lors du spawn du véhicule')
        end
    end)
end)

-- Setup ox_target zones
CreateThread(function()
    -- Wait for ox_target to be loaded
    while not exports.ox_target do
        Wait(100)
    end

    -- Office/Tablet zone
    exports.ox_target:addBoxZone({
        coords = Config.Zones.Office.coords,
        size = Config.Zones.Office.size,
        rotation = Config.Zones.Office.rotation,
        debug = Config.Zones.Office.debug,
        options = {
            {
                name = 'concess_office',
                icon = Config.Zones.Office.icon,
                label = Config.Zones.Office.label,
                groups = Config.JobName,
                onSelect = function()
                    OpenUI()
                end
            }
        }
    })

    -- Garage zone
    exports.ox_target:addBoxZone({
        coords = Config.Zones.Garage.coords,
        size = Config.Zones.Garage.size,
        rotation = Config.Zones.Garage.rotation,
        debug = Config.Zones.Garage.debug,
        options = {
            {
                name = 'concess_garage',
                icon = Config.Zones.Garage.icon,
                label = Config.Zones.Garage.label,
                groups = Config.JobName,
                onSelect = function()
                    TriggerServerEvent('zcon:getServiceVehicle')
                end
            }
        }
    })

    -- Unload zone
    exports.ox_target:addBoxZone({
        coords = Config.Zones.Unload.coords,
        size = Config.Zones.Unload.size,
        rotation = Config.Zones.Unload.rotation,
        debug = Config.Zones.Unload.debug,
        options = {
            {
                name = 'concess_unload',
                icon = Config.Zones.Unload.icon,
                label = Config.Zones.Unload.label,
                groups = Config.JobName,
                canInteract = function()
                    return exports.zcon:HasActiveDelivery()
                end,
                onSelect = function()
                    exports.zcon:UnloadVehicles()
                end
            }
        }
    })
end)

-- Draw markers for debug
if Config.Zones.Office.debug or Config.Zones.Garage.debug or Config.Zones.Unload.debug then
    CreateThread(function()
        while true do
            Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())

            if Config.Zones.Office.debug then
                local distance = #(playerCoords - Config.Zones.Office.coords)
                if distance < 50.0 then
                    DrawMarker(1, Config.Zones.Office.coords.x, Config.Zones.Office.coords.y, Config.Zones.Office.coords.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.Zones.Office.size.x, Config.Zones.Office.size.y, Config.Zones.Office.size.z,
                        0, 255, 0, 100, false, true, 2, false, nil, nil, false)
                end
            end

            if Config.Zones.Garage.debug then
                local distance = #(playerCoords - Config.Zones.Garage.coords)
                if distance < 50.0 then
                    DrawMarker(1, Config.Zones.Garage.coords.x, Config.Zones.Garage.coords.y, Config.Zones.Garage.coords.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.Zones.Garage.size.x, Config.Zones.Garage.size.y, Config.Zones.Garage.size.z,
                        255, 255, 0, 100, false, true, 2, false, nil, nil, false)
                end
            end

            if Config.Zones.Unload.debug then
                local distance = #(playerCoords - Config.Zones.Unload.coords)
                if distance < 50.0 then
                    DrawMarker(1, Config.Zones.Unload.coords.x, Config.Zones.Unload.coords.y, Config.Zones.Unload.coords.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.Zones.Unload.size.x, Config.Zones.Unload.size.y, Config.Zones.Unload.size.z,
                        0, 0, 255, 100, false, true, 2, false, nil, nil, false)
                end
            end
        end
    end)
end
