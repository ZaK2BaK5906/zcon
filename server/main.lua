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

-- Generate random plate
function GenerateRandomPlate()
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate = ''

    for i = 1, 8 do
        local rand = math.random(1, #charset)
        plate = plate .. charset:sub(rand, rand)
    end

    return plate
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

-- Sell vehicle to player
RegisterNetEvent('zcon:sellVehicle', function(targetId, vehicleModel, vehicleName, price, paymentMethod)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)

    -- Validation
    if not xPlayer or xPlayer.job.name ~= Config.JobName then
        Notify(source, 'Vous n\'avez pas accès à cette action', 'error')
        return
    end

    if not xTarget then
        Notify(source, 'Joueur introuvable', 'error')
        return
    end

    price = tonumber(price)
    if not price or price <= 0 then
        Notify(source, 'Prix invalide', 'error')
        return
    end

    if paymentMethod ~= 'bank' and paymentMethod ~= 'cash' then
        Notify(source, 'Méthode de paiement invalide', 'error')
        return
    end

    -- Check stock
    MySQL.query('SELECT * FROM concess_stock WHERE vehicle_model = ?', {vehicleModel}, function(result)
        if not result or #result == 0 or result[1].quantity <= 0 then
            Notify(source, 'Véhicule non disponible en stock', 'error')
            return
        end

        -- Check buyer has enough money
        local buyerMoney = paymentMethod == 'bank' and xTarget.getAccount('bank').money or xTarget.getMoney()

        if buyerMoney < price then
            Notify(source, string.format('Le joueur n\'a pas assez d\'argent (%s: $%s)',
                paymentMethod == 'bank' and 'Banque' or 'Liquide',
                ESX.Math.GroupDigits(buyerMoney)), 'error')
            Notify(targetId, 'Vous n\'avez pas assez d\'argent pour acheter ce véhicule', 'error')
            return
        end

        -- Process payment
        if paymentMethod == 'bank' then
            xTarget.removeAccountMoney('bank', price)
        else
            xTarget.removeMoney(price)
        end

        -- Add money to society
        AddSocietyMoney(price, function(success)
            if not success then
                -- Refund buyer if society payment fails
                if paymentMethod == 'bank' then
                    xTarget.addAccountMoney('bank', price)
                else
                    xTarget.addMoney(price)
                end
                Notify(source, 'Erreur lors de l\'ajout de l\'argent à la société', 'error')
                return
            end

            -- Update stock
            MySQL.update('UPDATE concess_stock SET quantity = quantity - 1 WHERE vehicle_model = ?', {vehicleModel}, function(affectedRows)
                if affectedRows > 0 then
                    -- Generate random plate
                    local plate = GenerateRandomPlate()

                    -- Give vehicle to buyer using qs-advancedgarages
                    local success = pcall(function()
                        exports['qs-advancedgarages']:GiveVehicle(source, {targetId, vehicleModel, plate}, 'vehicle')
                    end)

                    if not success then
                        -- Fallback: spawn vehicle client-side if export fails
                        TriggerClientEvent('zcon:spawnPurchasedVehicle', targetId, vehicleModel, vehicleName, price, plate)
                    end

                    -- Give keys using qs-vehiclekeys
                    pcall(function()
                        exports['qs-vehiclekeys']:GiveKeys(plate, vehicleModel, true)
                    end)

                    -- Notifications
                    Notify(source, string.format('Véhicule vendu à %s pour $%s', xTarget.getName(), ESX.Math.GroupDigits(price)), 'success')
                    Notify(targetId, string.format('Vous avez acheté un %s pour $%s (%s)',
                        vehicleName,
                        ESX.Math.GroupDigits(price),
                        paymentMethod == 'bank' and 'Banque' or 'Liquide'), 'success')

                    -- Update society money for all employees
                    UpdateSocietyMoneyForAll()

                    -- Log
                    print(string.format('[ZCon] %s sold %s to %s for $%s (%s) - Plate: %s',
                        xPlayer.getName(),
                        vehicleName,
                        xTarget.getName(),
                        price,
                        paymentMethod,
                        plate))
                else
                    -- Refund if stock update fails
                    if paymentMethod == 'bank' then
                        xTarget.addAccountMoney('bank', price)
                    else
                        xTarget.addMoney(price)
                    end
                    RemoveSocietyMoney(price)
                    Notify(source, 'Erreur lors de la mise à jour du stock', 'error')
                end
            end)
        end)
    end)
end)

-- Recruit employee
RegisterNetEvent('zcon:recruitEmployee', function(targetId, grade)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)

    -- Validation
    if not xPlayer or xPlayer.job.name ~= Config.JobName or xPlayer.job.grade < Config.BossGrade then
        Notify(source, 'Vous n\'avez pas accès à cette action', 'error')
        return
    end

    if not xTarget then
        Notify(source, 'Joueur introuvable', 'error')
        return
    end

    grade = tonumber(grade)
    if not grade or grade < 0 or grade > 2 then
        Notify(source, 'Grade invalide', 'error')
        return
    end

    -- Set job
    xTarget.setJob(Config.JobName, grade)

    -- Notifications
    local gradeNames = {
        [0] = 'Employé',
        [1] = 'Gérant',
        [2] = 'Boss'
    }

    Notify(source, string.format('Vous avez recruté %s en tant que %s', xTarget.getName(), gradeNames[grade]), 'success')
    Notify(targetId, string.format('Vous avez été recruté à la concession en tant que %s', gradeNames[grade]), 'success')

    -- Log
    print(string.format('[ZCon] %s recruited %s as %s (grade %d)',
        xPlayer.getName(),
        xTarget.getName(),
        gradeNames[grade],
        grade))
end)

print('^2[ZCon]^7 Concess job loaded successfully')
