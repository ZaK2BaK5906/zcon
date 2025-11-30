ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local currentMission = nil
local npcPed = nil
local missionBlip = nil
local missionVehicleBlip = nil

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

-- Check if player has taxi job
function HasJob()
    return PlayerData.job and PlayerData.job.name == Config.JobName
end

-- Check if player is boss
function IsBoss()
    return PlayerData.job and PlayerData.job.name == Config.JobName and PlayerData.job.grade >= Config.BossGrade
end

-- F6 Key mapping for job menu
RegisterCommand('+taxijobmenu', function()
    if HasJob() then
        OpenJobMenu()
    end
end, false)

RegisterKeyMapping('+taxijobmenu', 'Ouvrir le menu Taxi (F6)', 'keyboard', 'F6')

-- Open main job menu
function OpenJobMenu()
    if not HasJob() then
        lib.notify({
            title = 'Erreur',
            description = 'Vous n\'êtes pas chauffeur de taxi',
            type = 'error'
        })
        return
    end

    local options = {}

    -- NPC Missions
    if not currentMission then
        table.insert(options, {
            title = '🚕 Démarrer une Mission',
            description = 'Prendre un client NPC',
            icon = 'taxi',
            onSelect = function()
                OpenMissionMenu()
            end
        })
    else
        table.insert(options, {
            title = '❌ Annuler la Mission',
            description = 'Annuler la mission en cours',
            icon = 'xmark',
            onSelect = function()
                CancelMission()
            end
        })
    end

    -- Billing
    table.insert(options, {
        title = '💵 Facturer un Client',
        description = 'Envoyer une facture à un joueur',
        icon = 'receipt',
        onSelect = function()
            OpenBillingMenu()
        end
    })

    lib.registerContext({
        id = 'taxi_job_menu',
        title = '🚕 Menu Taxi',
        options = options
    })

    lib.showContext('taxi_job_menu')
end

-- Open mission selection menu
function OpenMissionMenu()
    local options = {}

    for i, mission in ipairs(Config.NPCMissions) do
        table.insert(options, {
            title = mission.name,
            description = string.format('Prix: $%s', ESX.Math.GroupDigits(mission.price)),
            icon = 'location-dot',
            onSelect = function()
                StartMission(mission)
            end
        })
    end

    lib.registerContext({
        id = 'taxi_missions',
        title = '🚕 Choisir une Mission',
        menu = 'taxi_job_menu',
        options = options
    })

    lib.showContext('taxi_missions')
end

-- Start NPC mission
function StartMission(mission)
    if currentMission then
        lib.notify({
            title = 'Erreur',
            description = 'Vous avez déjà une mission en cours',
            type = 'error'
        })
        return
    end

    currentMission = {
        name = mission.name,
        pickup = mission.pickup,
        dropoff = mission.dropoff,
        price = mission.price,
        stage = 'goto_pickup'
    }

    -- Create blip for pickup
    missionBlip = AddBlipForCoord(mission.pickup.x, mission.pickup.y, mission.pickup.z)
    SetBlipSprite(missionBlip, 280)
    SetBlipColour(missionBlip, 5)
    SetBlipRoute(missionBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Client à récupérer')
    EndTextCommandSetBlipName(missionBlip)

    lib.notify({
        title = 'Mission',
        description = 'Rendez-vous au point de prise en charge',
        type = 'info'
    })

    -- Monitor pickup
    MonitorMission()
end

-- Monitor mission progress
function MonitorMission()
    CreateThread(function()
        while currentMission do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            if currentMission.stage == 'goto_pickup' then
                local pickupCoords = vector3(currentMission.pickup.x, currentMission.pickup.y, currentMission.pickup.z)
                local distance = #(playerCoords - pickupCoords)

                if distance < 30.0 and vehicle ~= 0 then
                    -- Spawn NPC at pickup
                    if not npcPed or not DoesEntityExist(npcPed) then
                        SpawnNPC(currentMission.pickup)
                    end

                    if distance < 10.0 then
                        -- NPC enters vehicle
                        if npcPed and DoesEntityExist(npcPed) then
                            TaskEnterVehicle(npcPed, vehicle, -1, 1, 1.0, 1, 0)
                            Wait(3000)

                            if IsPedInVehicle(npcPed, vehicle, false) then
                                currentMission.stage = 'goto_dropoff'
                                RemoveBlip(missionBlip)

                                -- Create blip for dropoff
                                missionBlip = AddBlipForCoord(currentMission.dropoff.x, currentMission.dropoff.y, currentMission.dropoff.z)
                                SetBlipSprite(missionBlip, 1)
                                SetBlipColour(missionBlip, 2)
                                SetBlipRoute(missionBlip, true)
                                BeginTextCommandSetBlipName('STRING')
                                AddTextComponentString('Destination')
                                EndTextCommandSetBlipName(missionBlip)

                                lib.notify({
                                    title = 'Mission',
                                    description = 'Client à bord! Direction la destination',
                                    type = 'success'
                                })
                            end
                        end
                    end
                end
            elseif currentMission.stage == 'goto_dropoff' then
                local dropoffCoords = vector3(currentMission.dropoff.x, currentMission.dropoff.y, currentMission.dropoff.z)
                local distance = #(playerCoords - dropoffCoords)

                if distance < 20.0 then
                    if npcPed and DoesEntityExist(npcPed) and IsPedInVehicle(npcPed, vehicle, false) then
                        TaskLeaveVehicle(npcPed, vehicle, 0)
                        Wait(2000)
                        DeleteEntity(npcPed)
                        npcPed = nil

                        -- Complete mission
                        TriggerServerEvent('ztaxi:completeMission', currentMission.price)
                        RemoveBlip(missionBlip)

                        currentMission = nil
                    end
                end
            end

            Wait(500)
        end
    end)
end

-- Spawn NPC
function SpawnNPC(coords)
    local modelHash = GetHashKey('a_m_m_business_01')
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    npcPed = CreatePed(4, modelHash, coords.x, coords.y, coords.z, coords.w, false, true)
    SetEntityAsMissionEntity(npcPed, true, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    FreezeEntityPosition(npcPed, false)

    SetModelAsNoLongerNeeded(modelHash)
end

-- Cancel mission
function CancelMission()
    if currentMission then
        if npcPed and DoesEntityExist(npcPed) then
            DeleteEntity(npcPed)
        end
        if missionBlip then
            RemoveBlip(missionBlip)
        end
        currentMission = nil
        npcPed = nil
        missionBlip = nil

        lib.notify({
            title = 'Mission',
            description = 'Mission annulée',
            type = 'error'
        })
    end
end

-- Open billing menu
function OpenBillingMenu()
    local input = lib.inputDialog('Facturer un client', {
        {
            type = 'number',
            label = 'ID du joueur',
            description = 'ID du client à facturer',
            required = true,
            min = 1
        },
        {
            type = 'number',
            label = 'Montant',
            description = 'Montant de la facture',
            required = true,
            min = 1
        }
    })

    if input then
        local targetId = tonumber(input[1])
        local amount = tonumber(input[2])

        if targetId and amount and targetId > 0 and amount > 0 then
            TriggerServerEvent('ztaxi:sendBill', targetId, amount)
        end
    end
end

-- Receive bill from taxi driver
RegisterNetEvent('ztaxi:receiveBill', function(taxiDriverSource, driverName, amount)
    lib.registerContext({
        id = 'taxi_bill_received',
        title = '💵 Facture Taxi',
        options = {
            {
                title = string.format('Facture de %s', driverName),
                description = string.format('Montant: $%s', ESX.Math.GroupDigits(amount)),
                icon = 'info',
                disabled = true
            },
            {
                title = '✅ Accepter',
                description = 'Payer la facture',
                icon = 'check',
                onSelect = function()
                    TriggerServerEvent('ztaxi:processBillPayment', taxiDriverSource, amount, true)
                end
            },
            {
                title = '❌ Refuser',
                description = 'Refuser la facture',
                icon = 'xmark',
                onSelect = function()
                    TriggerServerEvent('ztaxi:processBillPayment', taxiDriverSource, amount, false)
                end
            }
        }
    })

    lib.showContext('taxi_bill_received')
end)

-- Boss Menu
function OpenBossMenu()
    if not IsBoss() then
        lib.notify({
            title = 'Erreur',
            description = 'Vous n\'êtes pas patron',
            type = 'error'
        })
        return
    end

    ESX.TriggerServerCallback('ztaxi:getSocietyMoney', function(money)
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
            },
            {
                title = '👔 Recruter un employé',
                description = 'Recruter un joueur dans la société',
                icon = 'user-plus',
                onSelect = function()
                    RecruitEmployee()
                end
            }
        }

        lib.registerContext({
            id = 'taxi_boss',
            title = '💰 Menu Patron Taxi',
            options = options
        })

        lib.showContext('taxi_boss')
    end)
end

-- Withdraw money
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
            TriggerServerEvent('ztaxi:withdrawMoney', amount)
        end
    end

    OpenBossMenu()
end

-- Deposit money
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
            TriggerServerEvent('ztaxi:depositMoney', amount)
        end
    end

    OpenBossMenu()
end

-- Recruit employee
function RecruitEmployee()
    local input = lib.inputDialog('Recruter un employé', {
        {
            type = 'number',
            label = 'ID du joueur',
            description = 'Entrez l\'ID du joueur à recruter',
            required = true,
            min = 1
        },
        {
            type = 'select',
            label = 'Grade',
            description = 'Choisir le grade de l\'employé',
            required = true,
            options = {
                {value = 0, label = 'Chauffeur'},
                {value = 1, label = 'Gérant'},
                {value = 2, label = 'Boss'}
            },
            default = 0
        }
    })

    if input then
        local targetId = tonumber(input[1])
        local grade = tonumber(input[2])

        if targetId and grade then
            TriggerServerEvent('ztaxi:recruitEmployee', targetId, grade)
        end
    end

    OpenBossMenu()
end

-- Setup boss menu zone
CreateThread(function()
    exports.ox_target:addBoxZone({
        coords = Config.BossMenuZone.coords,
        size = Config.BossMenuZone.size,
        rotation = Config.BossMenuZone.rotation,
        debug = Config.BossMenuZone.debug,
        options = {
            {
                name = 'taxi_boss_menu',
                icon = Config.BossMenuZone.icon,
                label = Config.BossMenuZone.label,
                groups = {[Config.JobName] = Config.BossGrade},
                onSelect = function()
                    OpenBossMenu()
                end
            }
        }
    })

    -- Create map blip
    if Config.Blip.enabled then
        local blip = AddBlipForCoord(Config.Blip.coords.x, Config.Blip.coords.y, Config.Blip.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.Blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CancelMission()
end)
