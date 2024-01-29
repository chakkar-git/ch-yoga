local QBCore = exports['qb-core']:GetCoreObject()
local Objects = {}

function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

local function CreateUseableItemForYogaMat(matName, matModel, itemToAdd)
    QBCore.Functions.CreateUseableItem(matName, function(source, item)
        local player = QBCore.Functions.GetPlayer(source)
        local objectId = math.random(10000, 99999)
        TriggerClientEvent('yoga:placeMat', source, matName, objectId)
        player.Functions.RemoveItem(item.name, 1)
        if itemToAdd then
            player.Functions.AddItem(itemToAdd, 1, objectId)
        end
    end)
end

for matName, matModel in pairs(Config.Objects) do
    CreateUseableItemForYogaMat(matName, matModel.model, matName)
end

RegisterCommand("yoga", function(source, args, rawCommand)
    local ped = source

    function LoadAnimDict(dict)
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
    end
    TaskPlayAnim(ped, "amb@world_human_yoga@male@base", "base_a", 8.0, 8.0, -1, 1, 0, false, false, false)

    Wait(35000)

    ClearPedTasks(ped)
end, false)

RegisterNetEvent('yoga:checkYogaMat')
AddEventHandler('yoga:checkYogaMat', function(player, matName, objectId)
    local player = QBCore.Functions.GetPlayer(player)
    
    if player then
        local success = player.Functions.RemoveItem(matName, 1)

        if success then
        else
        end
    end

    TriggerClientEvent('yoga:pickup', player, matName, objectId)
end)

for matName, matModel in pairs(Config.Objects) do
    CreateUseableItemForYogaMat(matName, matModel.model)
end

RegisterNetEvent('yoga:startYoga')
AddEventHandler('yoga:startYoga', function()
    local src = source
    local amount = Config.StressRemoval  

    TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_YOGA', 0, true)
    Wait(35000)

    if Config.Framework == 'qb' then
        TriggerServerEvent('hud:server:RelieveStress', amount)
    end
    
    Wait(5000)
    ClearPedTasks(PlayerPedId())
end)

RegisterNetEvent('yoga:pickup')
AddEventHandler('yoga:pickup', function()

    local player = PlayerId()
    local propModel = nil

    for networkId, data in pairs(ObjectList) do
        local prop = data.prop
        local matName = data.matName

        if prop ~= 0 and DoesEntityExist(prop) then
            DeleteEntity(prop)
            if matName then
                TriggerServerEvent('yoga:addItemToInventory', matName)
            else
                print("ERROR: No matName associated with prop.")
            end

            break 
        end
    end
end)

RegisterNetEvent('yoga:addItemToInventory')
AddEventHandler('yoga:addItemToInventory', function(matName)
    local player = QBCore.Functions.GetPlayer(source)

    if player then
        player.Functions.AddItem(matName, 1)
    else
    end
end)
