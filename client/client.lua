local QBCore = exports['qb-core']:GetCoreObject()
local ObjectList = {}

QBCore.UseableItems = QBCore.UseableItems or {}

function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

Citizen.CreateThread(function()
    while QBCore == nil do
        TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
        Citizen.Wait(200)
    end

local placeMatAnimDict = "anim@mp_snowball"
local placeMatAnimName = "pickup_snowball"

local function PlayPlaceMatAnimation()
    LoadAnimDict(placeMatAnimDict)
    TaskPlayAnim(PlayerPedId(), placeMatAnimDict, placeMatAnimName, 8.0, 8.0, -1, 0, 0, false, false, false)
end

-- Mat Placement

RegisterNetEvent('yoga:placeMat')
AddEventHandler('yoga:placeMat', function(matName)

    PlayPlaceMatAnimation()

    Citizen.Wait(2000)

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed)
    local spawnCoords = coords + forwardVector * 1.0

    local propModel = Config.Objects[matName].model or `prop_yoga_mat_01`

    RequestModel(propModel)
    while not HasModelLoaded(propModel) do
        Wait(1)
    end

    local prop = CreateObject(propModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, false, true)
    local heading = GetEntityHeading(prop)
    PlaceObjectOnGroundProperly(prop)
    SetEntityAsMissionEntity(prop, true, true)
    SetEntityHeading(prop, heading + 90)

    table.insert(ObjectList, { prop = prop, matName = matName })

    exports['qb-target']:AddTargetEntity(prop, {
        options = {
            {
                icon = "fa-sharp fa-solid fa-heart",
                label = "Yoga",
                event = "yoga:startYoga",
                canInteract = function(entity)
                    return true
                end,
            },
            {
                icon = "fa-solid fa-arrow-up-from-bracket",
                label = "Pick Up",
                event = "yoga:pickup",
                canInteract = function(entity)
                    return true
                end,
            },
        },
        distance = 1.8,
    })
end)

-- Yoga

local isYogaAnimationPlaying = false 

function IsPlayingYogaAnimation()
    return IsPedUsingScenario(PlayerPedId(), "WORLD_HUMAN_YOGA")
end

RegisterNetEvent('yoga:startYoga')
AddEventHandler('yoga:startYoga', function()
    local ped = PlayerPedId()
    if not ped or ped == -1 then
        print("ERROR: PlayerPedId is not valid.")
        return
    end

    local amount = Config.StressRemoval

    isYogaAnimationPlaying = true

    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_YOGA", 0, true)

    local animationTimer = GetGameTimer()

    while isYogaAnimationPlaying do
        Citizen.Wait(100)

        if GetGameTimer() - animationTimer > 35000 then
            break
        elseif not IsPlayingYogaAnimation() then
            TriggerEvent('yoga:cancelYoga')
            return
        end
    end

    if isYogaAnimationPlaying then
        TriggerServerEvent('hud:server:RelieveStress', amount)
    end

    isYogaAnimationPlaying = false
    ClearPedTasks(ped)
end)

RegisterNetEvent('yoga:checkYogaAnimation')
AddEventHandler('yoga:checkYogaAnimation', function()
    if not IsPlayingYogaAnimation() then
        TriggerEvent('yoga:cancelYoga')
    end
end)

RegisterNetEvent('yoga:cancelYoga')
AddEventHandler('yoga:cancelYoga', function()
    local ped = PlayerPedId()
    if isYogaAnimationPlaying then
        isYogaAnimationPlaying = false
        ClearPedTasks(ped)
    end
end)

    local pickupAnimDict = "anim@mp_snowball"
    local pickupAnimName = "pickup_snowball"

    local function PlayPickupAnimation()
        LoadAnimDict(pickupAnimDict)
        TaskPlayAnim(PlayerPedId(), pickupAnimDict, pickupAnimName, 8.0, 8.0, -1, 0, 0, false, false, false)
    end
    
-- Pickup Mat

    RegisterNetEvent('yoga:pickup')
    AddEventHandler('yoga:pickup', function()

        local playerPed = PlayerPedId()
        local closestProp = nil
        local closestDistance = math.huge
        for _, data in ipairs(ObjectList) do
            local prop = data.prop
            if DoesEntityExist(prop) then
                local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(prop))
                if distance < closestDistance then
                    closestProp = data  
                    closestDistance = distance
                end
            end
        end
    
        if closestProp then
            PlayPickupAnimation()
            Citizen.Wait(1500)
            DeleteEntity(closestProp.prop)
            local matName = closestProp.matName
            if matName then
                TriggerServerEvent('yoga:addItemToInventory', matName)
            else
                print("ERROR: No matName associated with prop.")
            end
            for i, data in ipairs(ObjectList) do
                if data == closestProp then
                    table.remove(ObjectList, i)
                    break
                end
            end
        else
        end
    end)
end)
