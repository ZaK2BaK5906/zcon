ESX = exports['es_extended']:getSharedObject()

-- Notify function
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

-- Get society money callback
ESX.RegisterServerCallback('ztaxi:getSocietyMoney', function(source, cb)
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

-- Withdraw money
RegisterNetEvent('ztaxi:withdrawMoney', function(amount)
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
            else
                Notify(source, 'Erreur lors du retrait', 'error')
            end
        end)
    end)
end)

-- Deposit money
RegisterNetEvent('ztaxi:depositMoney', function(amount)
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
            else
                Notify(source, 'Erreur lors du dépôt', 'error')
            end
        end)
    end)
end)

-- Recruit employee
RegisterNetEvent('ztaxi:recruitEmployee', function(targetId, grade)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)

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

    xTarget.setJob(Config.JobName, grade)

    local gradeNames = {
        [0] = 'Chauffeur',
        [1] = 'Gérant',
        [2] = 'Boss'
    }

    Notify(source, string.format('Vous avez recruté %s en tant que %s', xTarget.getName(), gradeNames[grade]), 'success')
    Notify(targetId, string.format('Vous avez été recruté chez Taxi en tant que %s', gradeNames[grade]), 'success')

    print(string.format('[ZTaxi] %s recruited %s as %s (grade %d)', xPlayer.getName(), xTarget.getName(), gradeNames[grade], grade))
end)

-- Complete NPC mission
RegisterNetEvent('ztaxi:completeMission', function(price)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer or xPlayer.job.name ~= Config.JobName then
        Notify(source, 'Vous n\'avez pas accès à cette action', 'error')
        return
    end

    price = tonumber(price)
    if not price or price <= 0 then
        Notify(source, 'Prix invalide', 'error')
        return
    end

    -- Add money to society
    AddSocietyMoney(price, function(success)
        if success then
            Notify(source, string.format('Mission terminée! $%s ajoutés à la société', ESX.Math.GroupDigits(price)), 'success')
            print(string.format('[ZTaxi] %s completed mission for $%s', xPlayer.getName(), price))
        else
            Notify(source, 'Erreur lors de l\'ajout de l\'argent', 'error')
        end
    end)
end)

-- Send bill to citizen
RegisterNetEvent('ztaxi:sendBill', function(targetId, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)

    if not xPlayer or xPlayer.job.name ~= Config.JobName then
        Notify(source, 'Vous n\'avez pas accès à cette action', 'error')
        return
    end

    if not xTarget then
        Notify(source, 'Joueur introuvable', 'error')
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        Notify(source, 'Montant invalide', 'error')
        return
    end

    -- Ask target to accept bill
    TriggerClientEvent('ztaxi:receiveBill', targetId, xPlayer.source, xPlayer.getName(), amount)
    Notify(source, string.format('Facture de $%s envoyée à %s', ESX.Math.GroupDigits(amount), xTarget.getName()), 'info')
end)

-- Process bill payment
RegisterNetEvent('ztaxi:processBillPayment', function(taxiDriverSource, amount, accepted)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTaxi = ESX.GetPlayerFromId(taxiDriverSource)

    if not xPlayer or not xTaxi then
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        return
    end

    if accepted then
        if xPlayer.getAccount('bank').money >= amount then
            xPlayer.removeAccountMoney('bank', amount)
            AddSocietyMoney(amount, function(success)
                if success then
                    Notify(source, string.format('Vous avez payé $%s pour la course', ESX.Math.GroupDigits(amount)), 'success')
                    Notify(taxiDriverSource, string.format('%s a payé la facture de $%s', xPlayer.getName(), ESX.Math.GroupDigits(amount)), 'success')
                    print(string.format('[ZTaxi] %s paid bill of $%s to %s', xPlayer.getName(), amount, xTaxi.getName()))
                else
                    xPlayer.addAccountMoney('bank', amount)
                    Notify(source, 'Erreur lors du paiement', 'error')
                    Notify(taxiDriverSource, 'Erreur lors du paiement de la facture', 'error')
                end
            end)
        else
            Notify(source, 'Vous n\'avez pas assez d\'argent en banque', 'error')
            Notify(taxiDriverSource, string.format('%s n\'a pas assez d\'argent', xPlayer.getName()), 'error')
        end
    else
        Notify(taxiDriverSource, string.format('%s a refusé la facture', xPlayer.getName()), 'error')
    end
end)

print('^2[ZTaxi]^7 Taxi job loaded successfully')
