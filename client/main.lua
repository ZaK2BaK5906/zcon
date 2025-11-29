ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local currentStock = {}
local currentOrders = {}

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

-- Notify function
local function Notify(message, type)
    if Config.UseOxLib then
        lib.notify({
            description = message,
            type = type or 'info'
        })
    else
        ESX.ShowNotification(message)
    end
end

-- Refresh stock
RegisterNetEvent('zcon:refreshStock', function()
    ESX.TriggerServerCallback('zcon:getStock', function(stock)
        currentStock = stock
    end)
end)

-- Refresh orders
RegisterNetEvent('zcon:refreshOrders', function()
    ESX.TriggerServerCallback('zcon:getOrders', function(orders)
        currentOrders = orders
    end)
end)

-- Main Menu
function OpenMainMenu()
    if not HasJob() then
        Notify('Vous n\'êtes pas employé de la concession', 'error')
        return
    end

    local grade = GetGrade()
    local options = {
        {
            title = '📊 Gestion Stock',
            description = 'Voir le stock actuel des véhicules',
            icon = 'warehouse',
            onSelect = function()
                OpenStockMenu()
            end
        },
        {
            title = '🛒 Passer Commande',
            description = 'Commander de nouveaux véhicules',
            icon = 'cart-shopping',
            onSelect = function()
                OpenOrderMenu()
            end
        },
        {
            title = '📦 Commandes en cours',
            description = 'Voir les commandes actives',
            icon = 'boxes-stacked',
            onSelect = function()
                OpenActiveOrders()
            end
        }
    }

    -- Boss menu (only for boss grade)
    if grade >= Config.BossGrade then
        table.insert(options, {
            title = '💰 Menu Patron',
            description = 'Gestion de la société',
            icon = 'briefcase',
            onSelect = function()
                OpenBossMenu()
            end
        })
    end

    lib.registerContext({
        id = 'concess_main_menu',
        title = '🏢 Concessionnaire',
        options = options
    })

    lib.showContext('concess_main_menu')
end

-- Stock Menu
function OpenStockMenu()
    ESX.TriggerServerCallback('zcon:getStock', function(stock)
        if not stock or #stock == 0 then
            Notify('Aucun véhicule en stock', 'info')
            return
        end

        local options = {}
        for _, vehicle in ipairs(stock) do
            table.insert(options, {
                title = vehicle.vehicle_name,
                description = string.format('Quantité: %d | Prix achat: $%s | Prix vente: $%s',
                    vehicle.quantity,
                    ESX.Math.GroupDigits(vehicle.buy_price),
                    ESX.Math.GroupDigits(vehicle.sell_price)
                ),
                icon = 'car',
                disabled = true
            })
        end

        lib.registerContext({
            id = 'concess_stock_menu',
            title = '📊 Stock de véhicules',
            menu = 'concess_main_menu',
            options = options
        })

        lib.showContext('concess_stock_menu')
    end)
end

-- Order Menu (Catalog)
function OpenOrderMenu()
    ESX.TriggerServerCallback('zcon:getCatalog', function(catalog)
        if not catalog or #catalog == 0 then
            Notify('Catalogue indisponible', 'error')
            return
        end

        local options = {}
        for _, category in ipairs(catalog) do
            table.insert(options, {
                title = category.category,
                description = string.format('%d véhicules disponibles', #category.vehicles),
                icon = 'folder',
                onSelect = function()
                    OpenCategoryMenu(category)
                end
            })
        end

        lib.registerContext({
            id = 'concess_order_menu',
            title = '🛒 Catalogue de véhicules',
            menu = 'concess_main_menu',
            options = options
        })

        lib.showContext('concess_order_menu')
    end)
end

-- Category Menu
function OpenCategoryMenu(category)
    local options = {}
    for _, vehicle in ipairs(category.vehicles) do
        table.insert(options, {
            title = vehicle.name,
            description = string.format('Prix: $%s', ESX.Math.GroupDigits(vehicle.price)),
            icon = 'car',
            onSelect = function()
                OpenQuantityMenu(vehicle)
            end
        })
    end

    lib.registerContext({
        id = 'concess_category_menu',
        title = '📁 ' .. category.category,
        menu = 'concess_order_menu',
        options = options
    })

    lib.showContext('concess_category_menu')
end

-- Quantity Menu
function OpenQuantityMenu(vehicle)
    local input = lib.inputDialog('Commander ' .. vehicle.name, {
        {
            type = 'number',
            label = 'Quantité',
            description = 'Nombre de véhicules à commander (1-10)',
            required = true,
            min = 1,
            max = 10,
            default = 1
        }
    })

    if not input then return end

    local quantity = tonumber(input[1])
    if not quantity or quantity < 1 or quantity > 10 then
        Notify('Quantité invalide', 'error')
        return
    end

    local totalPrice = vehicle.price * quantity

    -- Confirmation
    local alert = lib.alertDialog({
        header = 'Confirmer la commande',
        content = string.format('Véhicule: %s\nQuantité: %d\nPrix total: $%s\n\nConfirmer la commande?',
            vehicle.name,
            quantity,
            ESX.Math.GroupDigits(totalPrice)
        ),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        TriggerServerEvent('zcon:placeOrder', vehicle.model, vehicle.name, quantity, totalPrice)
    end
end

-- Active Orders Menu
function OpenActiveOrders()
    ESX.TriggerServerCallback('zcon:getOrders', function(orders)
        if not orders or #orders == 0 then
            Notify('Aucune commande en cours', 'info')
            return
        end

        local options = {}
        for _, order in ipairs(orders) do
            local statusText = order.status == 'pending' and '⏳ En attente' or '🚚 En livraison'
            local canStart = order.status == 'pending'

            table.insert(options, {
                title = string.format('%dx %s', order.quantity, order.vehicle_name),
                description = string.format('%s | Prix: $%s', statusText, ESX.Math.GroupDigits(order.total_price)),
                icon = 'truck',
                disabled = not canStart,
                onSelect = function()
                    TriggerServerEvent('zcon:startDelivery', order.id)
                end
            })
        end

        lib.registerContext({
            id = 'concess_active_orders',
            title = '📦 Commandes actives',
            menu = 'concess_main_menu',
            options = options
        })

        lib.showContext('concess_active_orders')
    end)
end

-- Boss Menu
function OpenBossMenu()
    ESX.TriggerServerCallback('zcon:getSocietyMoney', function(money)
        local options = {
            {
                title = '💵 Solde de la société',
                description = string.format('$%s', ESX.Math.GroupDigits(money)),
                icon = 'money-bill',
                disabled = true
            },
            {
                title = '📤 Retirer argent',
                description = 'Retirer de l\'argent de la société',
                icon = 'hand-holding-dollar',
                onSelect = function()
                    local input = lib.inputDialog('Retirer argent', {
                        {
                            type = 'number',
                            label = 'Montant',
                            description = string.format('Disponible: $%s', ESX.Math.GroupDigits(money)),
                            required = true,
                            min = 1
                        }
                    })

                    if input then
                        local amount = tonumber(input[1])
                        if amount and amount > 0 then
                            TriggerServerEvent('zcon:withdrawMoney', amount)
                        end
                    end
                end
            },
            {
                title = '📥 Déposer argent',
                description = 'Déposer de l\'argent dans la société',
                icon = 'piggy-bank',
                onSelect = function()
                    local input = lib.inputDialog('Déposer argent', {
                        {
                            type = 'number',
                            label = 'Montant',
                            required = true,
                            min = 1
                        }
                    })

                    if input then
                        local amount = tonumber(input[1])
                        if amount and amount > 0 then
                            TriggerServerEvent('zcon:depositMoney', amount)
                        end
                    end
                end
            }
        }

        lib.registerContext({
            id = 'concess_boss_menu',
            title = '💰 Menu Patron',
            menu = 'concess_main_menu',
            options = options
        })

        lib.showContext('concess_boss_menu')
    end)
end

-- Spawn service vehicle
RegisterNetEvent('zcon:spawnServiceVehicle', function()
    local spawnPoint = Config.Zones.Garage.spawnPoint

    ESX.Game.SpawnVehicle(Config.ServiceVehicle.model, vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z), spawnPoint.w, function(vehicle)
        if DoesEntityExist(vehicle) then
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

            if Config.ServiceVehicle.livery then
                SetVehicleLivery(vehicle, Config.ServiceVehicle.livery)
            end

            Notify('Véhicule de service sorti', 'success')
        else
            Notify('Erreur lors du spawn du véhicule', 'error')
        end
    end)
end)

-- Setup ox_target zones
CreateThread(function()
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
                    OpenMainMenu()
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
