ESX = exports['es_extended']:getSharedObject()

-- Get player job grade
local function GetPlayerGrade(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end

    if xPlayer.job.name == Config.JobName then
        return xPlayer.job.grade
    end
    return nil
end

-- Check if player has job
local function HasJob(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.job.name == Config.JobName
end

-- Send notification
local function Notify(source, message, type)
    TriggerClientEvent('ox_lib:notify', source, {
        title = type == 'error' and 'Erreur' or type == 'success' and 'Succès' or 'Info',
        description = message,
        type = type or 'info'
    })
end

-- Get society account
local function GetSocietyAccount(cb)
    MySQL.query('SELECT * FROM addon_account_data WHERE account_name = ?', {Config.SocietyName}, function(result)
        if result and #result > 0 then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end

-- Add money to society
local function AddSocietyMoney(amount, cb)
    MySQL.update('UPDATE addon_account_data SET money = money + ? WHERE account_name = ?', {amount, Config.SocietyName}, function(affectedRows)
        if cb then cb(affectedRows > 0) end
    end)
end

-- Remove money from society
local function RemoveSocietyMoney(amount, cb)
    MySQL.update('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', {amount, Config.SocietyName}, function(affectedRows)
        if cb then cb(affectedRows > 0) end
    end)
end

-- Update society money for all employees
local function UpdateSocietyMoneyForAll()
    GetSocietyAccount(function(account)
        if account then
            local employees = ESX.GetExtendedPlayers('job', Config.JobName)
            for _, employee in pairs(employees) do
                TriggerClientEvent('zcon:updateSocietyMoney', employee.source, account.money)
            end
        end
    end)
end

-- Get stock
ESX.RegisterServerCallback('zcon:getStock', function(source, cb)
    if not HasJob(source) then
        cb({})
        return
    end

    MySQL.query('SELECT * FROM concess_stock ORDER BY vehicle_name', {}, function(result)
        cb(result or {})
    end)
end)

-- Get vehicle catalog
ESX.RegisterServerCallback('zcon:getCatalog', function(source, cb)
    if not HasJob(source) then
        cb({})
        return
    end

    cb(Config.Vehicles)
end)

-- Get orders
ESX.RegisterServerCallback('zcon:getOrders', function(source, cb)
    if not HasJob(source) then
        cb({})
        return
    end

    MySQL.query('SELECT * FROM concess_orders WHERE status != "completed" AND status != "cancelled" ORDER BY ordered_at DESC', {}, function(result)
        cb(result or {})
    end)
end)

-- Place order
RegisterNetEvent('zcon:placeOrder', function(vehicleModel, vehicleName, quantity, totalPrice)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end
    if xPlayer.job.name ~= Config.JobName then
        Notify(source, 'Vous n\'avez pas accès à cette action', 'error')
        return
    end

    if xPlayer.job.grade < Config.MinGradeToOrder then
        Notify(source, 'Votre grade ne vous permet pas de passer des commandes', 'error')
        return
    end

    -- Check society money
    GetSocietyAccount(function(account)
        if not account then
            Notify(source, 'Erreur: Compte société introuvable', 'error')
            return
        end

        if account.money < totalPrice then
            Notify(source, 'Fonds insuffisants dans la société ($' .. ESX.Math.GroupDigits(account.money) .. ' disponible)', 'error')
            return
        end

        -- Create order
        MySQL.insert('INSERT INTO concess_orders (vehicle_model, vehicle_name, quantity, total_price, status, ordered_by) VALUES (?, ?, ?, ?, ?, ?)',
            {vehicleModel, vehicleName, quantity, totalPrice, 'pending', xPlayer.identifier},
            function(orderId)
                if orderId then
                    Notify(source, string.format('Commande enregistrée: %dx %s - Aller chercher la livraison', quantity, vehicleName), 'success')

                    -- Refresh orders for all employees
                    local employees = ESX.GetExtendedPlayers('job', Config.JobName)
                    for _, employee in pairs(employees) do
                        TriggerClientEvent('zcon:refreshOrders', employee.source)
                    end
                else
                    Notify(source, 'Erreur lors de la création de la commande', 'error')
                end
            end
        )
    end)
end)

-- Start delivery
RegisterNetEvent('zcon:startDelivery', function(orderId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end
    if xPlayer.job.name ~= Config.JobName then
        Notify(source, 'Vous n\'avez pas accès à cette action', 'error')
        return
    end

    -- Check if order exists and is pending
    MySQL.query('SELECT * FROM concess_orders WHERE id = ? AND status = "pending"', {orderId}, function(result)
        if result and #result > 0 then
            local order = result[1]

            -- Update order status
            MySQL.update('UPDATE concess_orders SET status = "in_progress" WHERE id = ?', {orderId}, function(affectedRows)
                if affectedRows > 0 then
                    -- Send delivery location to client
                    local deliveryLocation = Config.DeliveryLocations[math.random(#Config.DeliveryLocations)]
                    TriggerClientEvent('zcon:startDeliveryMission', source, order, deliveryLocation)
                    Notify(source, 'Mission de livraison démarrée - Suivez le GPS', 'info')

                    -- Refresh orders for all employees
                    local employees = ESX.GetExtendedPlayers('job', Config.JobName)
                    for _, employee in pairs(employees) do
                        TriggerClientEvent('zcon:refreshOrders', employee.source)
                    end
                end
            end)
        else
            Notify(source, 'Commande introuvable ou déjà en cours', 'error')
        end
    end)
end)

-- Complete delivery (unload vehicles)
RegisterNetEvent('zcon:completeDelivery', function(orderId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end
    if xPlayer.job.name ~= Config.JobName then
        Notify(source, 'Vous n\'avez pas accès à cette action', 'error')
        return
    end

    -- Get order details
    MySQL.query('SELECT * FROM concess_orders WHERE id = ? AND status = "in_progress"', {orderId}, function(result)
        if result and #result > 0 then
            local order = result[1]

            -- Deduct money from society
            GetSocietyAccount(function(account)
                if not account then
                    Notify(source, 'Erreur: Compte société introuvable', 'error')
                    return
                end

                if account.money < order.total_price then
                    Notify(source, 'Fonds insuffisants dans la société', 'error')
                    return
                end

                RemoveSocietyMoney(order.total_price)

                -- Add to stock or update existing
                MySQL.query('SELECT * FROM concess_stock WHERE vehicle_model = ?', {order.vehicle_model}, function(stockResult)
                    if stockResult and #stockResult > 0 then
                        -- Update existing stock
                        local newQuantity = stockResult[1].quantity + order.quantity
                        MySQL.update('UPDATE concess_stock SET quantity = ? WHERE vehicle_model = ?',
                            {newQuantity, order.vehicle_model}
                        )
                    else
                        -- Create new stock entry
                        local buyPrice = order.total_price / order.quantity
                        local sellPrice = math.floor(buyPrice * Config.SellPriceMultiplier)

                        MySQL.insert('INSERT INTO concess_stock (vehicle_model, vehicle_name, quantity, buy_price, sell_price) VALUES (?, ?, ?, ?, ?)',
                            {order.vehicle_model, order.vehicle_name, order.quantity, buyPrice, sellPrice}
                        )
                    end

                    -- Mark order as completed
                    MySQL.update('UPDATE concess_orders SET status = "completed", completed_at = NOW() WHERE id = ?', {orderId})

                    Notify(source, string.format('Livraison terminée! +%d %s ajouté(s) au stock', order.quantity, order.vehicle_name), 'success')

                    -- Refresh for all employees
                    local employees = ESX.GetExtendedPlayers('job', Config.JobName)
                    for _, employee in pairs(employees) do
                        TriggerClientEvent('zcon:refreshOrders', employee.source)
                        TriggerClientEvent('zcon:refreshStock', employee.source)
                    end
                end)
            end)
        else
            Notify(source, 'Commande introuvable', 'error')
        end
    end)
end)

-- Cancel delivery
RegisterNetEvent('zcon:cancelDelivery', function(orderId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end
    if xPlayer.job.name ~= Config.JobName then return end

    MySQL.update('UPDATE concess_orders SET status = "pending" WHERE id = ? AND status = "in_progress"', {orderId}, function(affectedRows)
        if affectedRows > 0 then
            -- Refresh orders for all employees
            local employees = ESX.GetExtendedPlayers('job', Config.JobName)
            for _, employee in pairs(employees) do
                TriggerClientEvent('zcon:refreshOrders', employee.source)
            end
        end
    end)
end)

-- Boss actions
ESX.RegisterServerCallback('zcon:getSocietyMoney', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer or xPlayer.job.name ~= Config.JobName or xPlayer.job.grade < Config.BossGrade then
        cb(0)
        return
    end

    GetSocietyAccount(function(account)
        if account then
            cb(account.money)
        else
            cb(0)
        end
    end)
end)

RegisterNetEvent('zcon:withdrawMoney', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer or xPlayer.job.name ~= Config.JobName or xPlayer.job.grade < Config.BossGrade then
        Notify(source, 'Vous n\'avez pas accès à cette action', 'error')
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        Notify(source, 'Montant invalide', 'error')
        return
    end

    GetSocietyAccount(function(account)
        if not account then
            Notify(source, 'Erreur: Compte société introuvable', 'error')
            return
        end

        if account.money < amount then
            Notify(source, 'Fonds insuffisants (Disponible: $' .. ESX.Math.GroupDigits(account.money) .. ')', 'error')
            return
        end

        RemoveSocietyMoney(amount, function(success)
            if success then
                xPlayer.addMoney(amount)
                Notify(source, string.format('Vous avez retiré $%s', ESX.Math.GroupDigits(amount)), 'success')
                UpdateSocietyMoneyForAll()
            else
                Notify(source, 'Erreur lors du retrait', 'error')
            end
        end)
    end)
end)

RegisterNetEvent('zcon:depositMoney', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer or xPlayer.job.name ~= Config.JobName or xPlayer.job.grade < Config.BossGrade then
        Notify(source, 'Vous n\'avez pas accès à cette action', 'error')
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        Notify(source, 'Montant invalide', 'error')
        return
    end

    if xPlayer.getMoney() < amount then
        Notify(source, 'Vous n\'avez pas assez d\'argent (Disponible: $' .. ESX.Math.GroupDigits(xPlayer.getMoney()) .. ')', 'error')
        return
    end

    GetSocietyAccount(function(account)
        if not account then
            Notify(source, 'Erreur: Compte société introuvable', 'error')
            return
        end

        xPlayer.removeMoney(amount)
        AddSocietyMoney(amount, function(success)
            if success then
                Notify(source, string.format('Vous avez déposé $%s', ESX.Math.GroupDigits(amount)), 'success')
                UpdateSocietyMoneyForAll()
            else
                Notify(source, 'Erreur lors du dépôt', 'error')
            end
        end)
    end)
end)

-- Get service vehicle
RegisterNetEvent('zcon:getServiceVehicle', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer or xPlayer.job.name ~= Config.JobName then
        Notify(source, 'Vous n\'avez pas accès à cette action', 'error')
        return
    end

    TriggerClientEvent('zcon:spawnServiceVehicle', source)
end)

print('^2[ZCon]^7 Concess job loaded successfully')
