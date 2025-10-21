
local RSGCore = exports['rsg-core']:GetCoreObject()
local miningActive = false
local smeltingActive = false
local prospectingActive = false
local lanternActive = false
local fuelTimer = 0
local lightProp = nil
local playerSkills = {}

AddEventHandler('playerSpawned', function()
    if Config.UseSkills then
        RSGCore.Functions.TriggerCallback('cb-skills:loadSkills', function(skills)
            playerSkills = skills
            for skill, data in pairs(skills) do
                Config.Notify(skill .. ' Level: ' .. data.level .. ' | XP: ' .. data.xp)
            end
        end)
    end
    SetupTargets()
end)

if Config.UseSkills then
    RegisterNetEvent('cb-skills:setSkill')
    AddEventHandler('cb-skills:setSkill', function(skill, data)
        playerSkills[skill] = data
        Config.Notify(skill .. ' Level: ' .. data.level .. ' | XP: ' .. data.xp)
    end)
end

function SetupTargets()
    for _, spot in ipairs(Config.MiningSpots) do
        exports.ox_target:addBoxZone({
            coords = spot.coords,
            size = spot.size,
            rotation = spot.rotation,
            debug = false,
            options = {
                {
                    name = 'mine_' .. spot.type,
                    label = 'Mine',
                    onSelect = function()
                        StartMining(spot)
                    end
                }
            }
        })
    end
    
    for _, spot in ipairs(Config.SmeltingSpots) do
        exports.ox_target:addBoxZone({
            coords = spot.coords,
            size = spot.size,
            rotation = spot.rotation,
            debug = false,
            options = {
                {
                    name = 'smelt',
                    label = 'Smelt',
                    onSelect = function()
                        StartSmelting(spot)
                    end
                }
            }
        })
    end
    
    for _, spot in ipairs(Config.ProspectingSpots) do
        exports.ox_target:addBoxZone({
            coords = spot.coords,
            size = spot.size,
            rotation = spot.rotation,
            debug = false,
            options = {
                {
                    name = 'prospect',
                    label = 'Prospect',
                    onSelect = function()
                        StartProspecting(spot)
                    end
                }
            }
        })
    end
end



function RandomEvent(playerPed)
    local totalChance = 0
    for _, event in ipairs(Config.RandomEventsList) do
        totalChance = totalChance + event.chance
    end
    local rand = math.random() * totalChance
    local currentChance = 0
    for _, event in ipairs(Config.RandomEventsList) do
        currentChance = currentChance + event.chance
        if rand <= currentChance then
            event.action(playerPed)
            break
        end
    end
end



function HasItem(item, amount)
    amount = amount or 1
    local hasItem = nil
    RSGCore.Functions.TriggerCallback('mining:hasItem', function(result)
        hasItem = result
    end, item, amount)
    while hasItem == nil do
        Citizen.Wait(0)
    end
    return hasItem
end

