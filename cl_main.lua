local ESX = exports['es_extended']:getSharedObject()

local thirst, hunger, cash, bank, oxygen = 100, 0, 100, 100, 100
local showSeatbelt, seatbeltOn, rpm, fuel, enginehealth = false, false, 100, 20, 300
local isLoggedIn = false
local harness = 0
local cashAmount = 0
local bankAmount = 0

CreateThread(function()
    while true do
        Citizen.Wait(50)
        DisplayRadar(IsPedInAnyVehicle(PlayerPedId(), true))
        if IsPedInAnyVehicle(PlayerPedId(), true) then
            SetRadarZoom(1000)
        end
    end
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    hunger, thirst = newHunger, newThirst
end)

RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
    showSeatbelt = not showSeatbelt
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function()
    seatbeltOn = not seatbeltOn
end)

RegisterNetEvent('esx:playerLoaded', function()
    isLoggedIn = true
    SendNUIMessage({ type = 'showhud', show = true })
    TriggerEvent('hud:client:minimap')
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    Citizen.Wait(1000)
    isLoggedIn = false
    SendNUIMessage({ type = 'hidehud', show = false })
end)

RegisterNetEvent('hud:client:ShowAccounts', function(type, amount)
    local description = type == 'cash' and ('Cash: $' .. amount) or ('Bank: $' .. amount)
    lib.notify({ description = description, icon = 'dollar', type = 'success' })
end)

RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, isMinus)
    cashAmount = ESX.GetPlayerData().money['cash']
    bankAmount = ESX.GetPlayerData().money['bank']
    local description = (isMinus and "-" or "+") .. "$" .. amount
    description = description .. (type == 'cash' and (" (Cash: $" .. cashAmount .. ")") or (" (Bank: $" .. bankAmount .. ")"))
    lib.notify({ description = description, icon = 'dollar', type = 'success' })
end)

local function getCardinalDirection(heading)
    local directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
    heading = (heading % 360 + 360) % 360
    local index = math.floor((heading + 22.5) / 45) % 8
    return directions[index + 1]
end

local function hasHarness()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end
    local hasHarness = exports['esx_smallresources']:HasHarness()
    harness = hasHarness and 1 or 0
end

CreateThread(function()
    while true do
        Citizen.Wait(50)
        if isLoggedIn then
            local playerPed = PlayerPedId()
            local health = GetEntityHealth(playerPed) - 100
            local armor = GetPedArmour(playerPed)
            local cash = ESX.GetPlayerData().money["cash"]
            local bank = ESX.GetPlayerData().money["bank"]

            local inVehicle = IsPedInAnyVehicle(playerPed, false)
            local speed = 0

            if not IsEntityInWater(playerPed) then
                oxygen = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
            else
                oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
            end

            if inVehicle then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                speed = GetEntitySpeed(vehicle) * 2.23694
                rpm = GetVehicleCurrentRpm(vehicle) * 1000 / 10
                fuel = exports["LegacyFuel"]:GetFuel(vehicle)
                enginehealth = GetVehicleEngineHealth(vehicle) / 10

                local pos = GetEntityCoords(playerPed)
                local heading = GetEntityHeading(playerPed)
                local cardinalDirection = getCardinalDirection(heading)
                local streetNameHash, crossingHash = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
                local streetName = GetStreetNameFromHashKey(streetNameHash)
                local areaName = GetLabelText(GetNameOfZone(pos.x, pos.y, pos.z))

                SendNUIMessage({
                    type = 'updateLocation',
                    heading = cardinalDirection,
                    street = streetName,
                    area = areaName,
                    x = pos.x,
                    y = pos.y,
                    z = pos.z
                })
            end

            SendNUIMessage({
                type = 'updatehud',
                health = health,
                armor = armor,
                oxygen = oxygen,
                hunger = hunger,
                thirst = thirst,
                cash = cash,
                bank = bank,
                speed = math.floor(speed),
                belt = seatbeltOn,
                rpm = rpm,
                fuel = fuel,
                harness = harness,
                inVehicle = inVehicle,
                engine = enginehealth
            })

            if inVehicle then
                SendNUIMessage({ type = 'showLocationHUD' })
            else
                SendNUIMessage({ type = 'hideLocationHUD' })
            end
        end
    end
end)

RegisterNetEvent('hud:client:UpdateHarness', function(harnessHp)
    harness = harnessHp
end)

RegisterNetEvent("hud:client:LoadMap", function()
    print('loaded?')
    Wait(50)
    local defaultAspectRatio = 1920 / 1080
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end
    RequestStreamedTextureDict("squaremap", false)
    if not HasStreamedTextureDictLoaded("squaremap") then
        Wait(150)
    end
    SetMinimapClipType(1)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
    SetMinimapComponentPosition("minimap", "L", "B", 0.0 + minimapOffset, -0.037, 0.1638, 0.183)
    SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset, 0.01, 0.128, 0.20)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.011 + minimapOffset, 0.059, 0.265, 0.295)
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    SetMinimapClipType(1)
    Wait(50)
    SetRadarBigmapEnabled(false, false)
end)

local function BlackBars()
    local screenW, screenH = GetScreenResolution()
    local barHeight = screenH * 0.1

    DrawRect(0.5, -0.05 + (barHeight / screenH), 1.0, barHeight / screenH, 0, 0, 0, 255)

    DrawRect(0.5, 1.05 - (barHeight / screenH), 1.0, barHeight / screenH, 0, 0, 0, 255)
end

CreateThread(function()
    while true do
        Wait(15000)
        if LocalPlayer.state.isLoggedIn then
            local ped = cache.ped
            if IsPedInAnyVehicle(ped, false) then
                hasHarness()
                local veh = GetEntityModel(GetVehiclePedIsIn(ped, false))
                if seatbeltOn ~= true and IsThisModelACar(veh) then
                    TriggerEvent("InteractSound_CL:PlayOnOne", "beltalarm", 0.6)
                end
            end
         end
    end
end)

CreateThread(function()
    local isPaused = false
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(playerPed, false)

        if IsPauseMenuActive() and not isPaused then
            SendNUIMessage({
                type = 'hidehud',
                show = false
            })

            if inVehicle then
                SendNUIMessage({
                    type = 'hideLocationHUD'
                })
            end
            isPaused = true

        elseif not IsPauseMenuActive() and isPaused then
            SendNUIMessage({
                type = 'showhud',
                show = true
            })

            if inVehicle then
                SendNUIMessage({
                    type = 'showLocationHUD'
                })
            end
            isPaused = false
        end
    end
end)

local cinematic = false

RegisterCommand('cinematic', function ()
    local playerPed = PlayerPedId()
    if not cinematic then
        cinematic = true
        SendNUIMessage({ type = 'hidehud', show = true })
        while cinematic do
            Wait(1)
            DisplayRadar(false)
            BlackBars()

            local inVehicle = IsPedInAnyVehicle(playerPed, false)

            if inVehicle then
                SendNUIMessage({
                    type = 'hideLocationHUD'
                })
            else
                SendNUIMessage({
                    type = 'hideLocationHUD'
                })
            end
        end
    else
        local inVehicle = IsPedInAnyVehicle(playerPed, false)
        if inVehicle then
            SendNUIMessage({
                type = 'showLocationHUD'
            })
        end
        cinematic = false
        SendNUIMessage({ type = 'showhud', show = true })
        DisplayRadar(true)
    end
end)

RegisterNetEvent('hud:client:minimap', function()
    Citizen.Wait(1000)
    SetMapZoomDataLevel(0, 0.96, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(1, 1.6, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(2, 8.6, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(3, 12.3, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(4, 22.3, 0.9, 0.08, 0.0, 0.0)
    TriggerEvent('hud:client:LoadMap')
end)

RegisterCommand('resethud', function ()
    TriggerEvent('hud:client:minimap')
end)