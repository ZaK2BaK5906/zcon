ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}

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

-- Check if player is boss
local function IsBoss()
    return GetGrade() >= Config.BossGrade
end

-- Main Menu
function OpenMainMenu()
    if not HasJob() then
        lib.notify({
            title = 'Erreur',
            description = 'Vous n\'êtes pas employé de la concession',
            type = 'error'
        })
        return
    end

    local options = {
        {
            title = '📊 Gestion Stock',
            description = 'Voir le stock des véhicules',
            icon = 'warehouse',
            onSelect = function()
                OpenStockMenu()
            end
        },
        {
            title = '🛒 Passer Commande',
            description = 'Commander nouveaux véhicules',
            icon = 'shopping-cart',
            onSelect = function()
                OpenCatalogMenu()
            end
        },
        {
            title = '📦 Commandes en cours',
            description = 'Gérer les livraisons',
            icon = 'boxes-stacked',
            onSelect = function()
                OpenOrdersMenu()
            end
        }
    }

    -- Boss menu
    if IsBoss() then
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
        id = 'concess_main',
        title = '🏢 Concessionnaire',
        options = options
    })

    lib.showContext('concess_main')
end

-- Stock Menu
function OpenStockMenu()
    ESX.TriggerServerCallback('zcon:getStock', function(stock)
        if not stock or #stock == 0 then
            lib.notify({
                title = 'Stock',
                description = 'Aucun véhicule en stock',
                type = 'info'
            })
            return
        end

        local options = {}
        for _, vehicle in ipairs(stock) do
            table.insert(options, {
                title = vehicle.vehicle_name,
                description = string.format('Stock: %d | Achat: $%s | Vente: $%s',
                    vehicle.quantity,
                    ESX.Math.GroupDigits(vehicle.buy_price),
                    ESX.Math.GroupDigits(vehicle.sell_price)
                ),
                icon = 'car'
            })
        end

        lib.registerContext({
            id = 'concess_stock',
            title = '📊 Stock de véhicules',
            menu = 'concess_main',
            options = options
        })

        lib.showContext('concess_stock')
    end)
end

-- Catalog Menu
function OpenCatalogMenu()
    ESX.TriggerServerCallback('zcon:getCatalog', function(catalog)
        if not catalog or #catalog == 0 then
            lib.notify({
                title = 'Catalogue',
                description = 'Catalogue indisponible',
                type = 'error'
            })
            return
        end

        local options = {}
        for _, category in ipairs(catalog) do
            table.insert(options, {
                title = category.category,
                description = string.format('%d véhicules disponibles', #category.vehicles),
                icon = 'folder',
                arrow = true,
                onSelect = function()
                    OpenCategoryMenu(category)
                end
            })
        end

        lib.registerContext({
            id = 'concess_catalog',
            title = '🛒 Catalogue',
            menu = 'concess_main',
            options = options
        })

        lib.showContext('concess_catalog')
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
                OrderVehicle(vehicle, category)
            end
        })
    end

    lib.registerContext({
        id = 'concess_category',
        title = '📁 ' .. category.category,
        menu = 'concess_catalog',
        options = options
    })

    lib.showContext('concess_category')
end

-- Order Vehicle
function OrderVehicle(vehicle, category)
    local input = lib.inputDialog('Commander ' .. vehicle.name, {
        {
            type = 'number',
            label = 'Quantité',
            description = 'Nombre de véhicules (1-10)',
            required = true,
            min = 1,
            max = 10,
            default = 1
        }
    })

    if not input then
        OpenCategoryMenu(category)
        return
    end

    local quantity = tonumber(input[1])
    if not quantity or quantity < 1 or quantity > 10 then
        lib.notify({
            title = 'Erreur',
            description = 'Quantité invalide',
            type = 'error'
        })
        OpenCategoryMenu(category)
        return
    end

    local totalPrice = vehicle.price * quantity

    local alert = lib.alertDialog({
        header = 'Confirmer la commande',
        content = string.format('Véhicule: %s\nQuantité: %d\nPrix total: $%s',
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

    OpenCategoryMenu(category)
end

-- Orders Menu
function OpenOrdersMenu()
    ESX.TriggerServerCallback('zcon:getOrders', function(orders)
        if not orders or #orders == 0 then
            lib.notify({
                title = 'Commandes',
                description = 'Aucune commande en cours',
                type = 'info'
            })
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
                    if canStart then
                        TriggerServerEvent('zcon:startDelivery', order.id)
                    end
                end
            })
        end

        lib.registerContext({
            id = 'concess_orders',
            title = '📦 Commandes actives',
            menu = 'concess_main',
            options = options
        })

        lib.showContext('concess_orders')
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
                    WithdrawMoney(money)
                end
            },
            {
                title = '📥 Déposer argent',
                description = 'Déposer de l\'argent dans la société',
                icon = 'piggy-bank',
                onSelect = function()
                    DepositMoney()
                end
            }
        }

        lib.registerContext({
            id = 'concess_boss',
            title = '💰 Menu Patron',
            menu = 'concess_main',
            options = options
        })

        lib.showContext('concess_boss')
    end)
end

-- Withdraw Money
function WithdrawMoney(societyMoney)
    local input = lib.inputDialog('Retirer argent', {
        {
            type = 'number',
            label = 'Montant',
            description = string.format('Disponible: $%s', ESX.Math.GroupDigits(societyMoney)),
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

    OpenBossMenu()
end

-- Deposit Money
function DepositMoney()
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

    OpenBossMenu()
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

            lib.notify({
                title = 'Garage',
                description = 'Véhicule de service sorti',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Erreur',
                description = 'Erreur lors du spawn du véhicule',
                type = 'error'
            })
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
