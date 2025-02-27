local ESX = exports["es_extended"]:getSharedObject()
local PlayerStress = {} -- Store stress in a table instead of metadata
local ResetStress = false

RegisterNetEvent('hud:server:GainStress', function(amount)
    if Config.DisableStress then return end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local jobName = xPlayer.job.name
    local jobType = xPlayer.job.grade_name -- Adjust this based on your job hierarchy

    if Config.WhitelistedJobs[jobType] or Config.WhitelistedJobs[jobName] then return end

    if not PlayerStress[src] then
        PlayerStress[src] = 0
    end

    local newStress = ResetStress and 0 or (PlayerStress[src] + amount)
    if newStress > 100 then newStress = 100 end

    PlayerStress[src] = newStress

    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
    TriggerClientEvent('ox_lib:notify', src, { description = 'Gained Stress', type = 'error', duration = 1500 })
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    if Config.DisableStress then return end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not PlayerStress[src] then
        PlayerStress[src] = 0
    end

    local newStress = ResetStress and 0 or (PlayerStress[src] - amount)
    if newStress < 0 then newStress = 0 end

    PlayerStress[src] = newStress

    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
    TriggerClientEvent('ox_lib:notify', src, { description = 'Feeling Much Better', type = 'success' })
end)

RegisterCommand('bank', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local bankAmount = xPlayer.getAccount('bank').money
    TriggerClientEvent('hud:client:ShowAccounts', source, 'bank', bankAmount)
end, false)