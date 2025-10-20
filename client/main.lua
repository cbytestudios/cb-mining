local RSGCore = exports['rsg-core']:GetCoreObject()
local miningActive = false
local smeltingActive = false
local prospectingActive = false
local lanternActive = false
local fuelTimer = 0
local lightProp = nil
local playerSkills = {}

AddEventHandler('playerSpawned', function()
    RSGCore.Functions.TriggerCallback('cb-skills:loadSkills', function(skills)
        playerSkills = skills
        for skill, data in pairs(skills) do
            Config.Notify(skill .. ' Level: ' .. data.level .. ' | XP: ' .. data.xp)
        end
    end)
end)

RegisterNetEvent('cb-skills:setSkill')
AddEventHandler('cb-skills:setSkill', function(skill, data)
    playerSkills[skill] = data
    Config.Notify(skill .. ' Level: ' .. data.level .. ' | XP: ' .. data.xp)
end)

CreateThread(function()
    while true do
        Wait(1000)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for _, spot in ipairs(Config.MiningSpots) do
            local dist = #(playerCoords - spot.coords)
            if dist < spot.radius and not miningActive then
                DisplayPrompt(spot, 'mining')
            end
        end
        
        for _, spot in ipairs(Config.SmeltingSpots) do
            local dist = #(playerCoords - spot.coords)
            if dist < spot.radius and not smeltingActive then
                DisplayPrompt(spot, 'smelting')
            end
        end
        
        for _, spot in ipairs(Config.ProspectingSpots) do
            local dist = #(playerCoords - spot.coords)
            if dist < spot.radius and not prospectingActive then
                DisplayPrompt(spot, 'prospecting')
            end
        end
    end
end)

function DisplayPrompt(spot, actionType)
    local promptText = '[E] Start ' .. actionType:gsub("^%l", string.upper)
    RSGCore.Functions.DrawText3D(spot.coords, promptText)
    if IsControlJustPressed(0, 0xCEFD9220) then
        if actionType == 'mining' then
            StartMining(spot)
        elseif actionType == 'smelting' then
            StartSmelting(spot)
        elseif actionType == 'prospecting' then
            StartProspecting(spot)
        end
    end
end

function StartMining(spot)
    local playerPed = PlayerPedId()
    if not HasItem(spot.requiredItem) then
        Config.Notify('You need a ' .. spot.requiredItem)
        return
    end
    
    miningActive = true
    local animDict, animClip
    
    if spot.type == 'rock_pickaxe' then
        animDict = 'mech_pickaxe@wall@speed_normal'
        animClip = 'base'
        TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, -1, 1, 0, false, false, false)
    elseif spot.type == 'rock_dynamite' then
        animDict = 'mech_dynamite@throw'
        animClip = 'idle'
        TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, 3000, 0, 0, false, false, false)
        Wait(2000)
        local dynProp = CreateObject(GetHashKey('p_dynamite01x'), spot.coords + vector3(0,0,-1), true, true, true)
        Wait(1000)
        AddExplosion(spot.coords, 2, 1.0, true, false, 1.0)
        DeleteEntity(dynProp)
        if math.random() < spot.explosionRisk then
            SetEntityHealth(playerPed, GetEntityHealth(playerPed) - 50)
            Config.Notify('Dynamite misfired!')
        end
    elseif spot.type == 'gold_pan' then
        animDict = 'script_mp@naturalist@pan_loop'
        animClip = 'pan_loop'
        TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, -1, 1, 0, false, false, false)
    end
    
    local skillData = playerSkills[spot.skill] or {level = 1}
    local level = skillData.level
    local bonus = Config.Skills[spot.skill].levelBonuses[level] or Config.Skills[spot.skill].levelBonuses[1]
    local progressTime = Config.ProgressTime - bonus.timeReducer
    
    RSGCore.Functions.Progressbar('mining', 'Mining...', progressTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        StopAnimTask(playerPed, animDict, animClip, 1.0)
        TriggerServerEvent('mining:reward', spot, level)
        if Config.RandomEvents and math.random() < Config.RandomEventChance then
            RandomEvent()
        end
        miningActive = false
    end, function()
        StopAnimTask(playerPed, animDict, animClip, 1.0)
        miningActive = false
    end)
end

function StartSmelting(spot)
    if not HasItem(spot.requiredFuel, spot.fuelAmount) then
        Config.Notify('You need ' .. spot.fuelAmount .. ' ' .. spot.requiredFuel)
        return
    end
    
    local selectedRecipe = nil
    for _, recipe in ipairs(spot.recipes) do
        if HasItem(recipe.input.item, recipe.input.amount) then
            selectedRecipe = recipe
            break
        end
    end
    
    if not selectedRecipe then
        Config.Notify('No materials to smelt')
        return
    end
    
    smeltingActive = true
    local playerPed = PlayerPedId()
    local animDict = 'amb_work@world_human_anvil@work@male_a@base'
    local animClip = 'base'
    TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    local skillData = playerSkills[spot.skill] or {level = 1}
    local level = skillData.level
    local bonus = Config.Skills[spot.skill].levelBonuses[level] or Config.Skills[spot.skill].levelBonuses[1]
    local progressTime = selectedRecipe.time - bonus.timeReducer
    
    RSGCore.Functions.Progressbar('smelting', 'Smelting...', progressTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        StopAnimTask(playerPed, animDict, animClip, 1.0)
        TriggerServerEvent('mining:smelt', spot, selectedRecipe, level)
        smeltingActive = false
    end, function()
        StopAnimTask(playerPed, animDict, animClip, 1.0)
        smeltingActive = false
    end)
end

function StartProspecting(spot)
    local playerPed = PlayerPedId()
    if not HasItem(spot.requiredItem) then
        Config.Notify('You need a ' .. spot.requiredItem)
        return
    end
    
    prospectingActive = true
    local animDict = 'amb_work@world_human_survey@male_a@base'
    local animClip = 'base'
    TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    local skillData = playerSkills[spot.skill] or {level = 1}
    local level = skillData.level
    local bonus = Config.Skills[spot.skill].levelBonuses[level] or Config.Skills[spot.skill].levelBonuses[1]
    local progressTime = Config.ProgressTime - bonus.timeReducer
    
    RSGCore.Functions.Progressbar('prospecting', 'Prospecting...', progressTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        StopAnimTask(playerPed, animDict, animClip, 1.0)
        TriggerServerEvent('mining:prospectReward', spot, level)
        prospectingActive = false
    end, function()
        StopAnimTask(playerPed, animDict, animClip, 1.0)
        prospectingActive = false
    end)
end

function RandomEvent()
    local event = math.random(1,3)
    if event == 1 then
        Config.Notify('You found a rare gem!')
        TriggerServerEvent('mining:giveItem', 'rare_gem', 1)
    elseif event == 2 then
        Config.Notify('Cave-in! You take damage.')
        SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) - 30)
    elseif event == 3 then
        Config.Notify('Animal attack!')
        local animalHash = GetHashKey('a_c_coyote_01')
        local animal = CreatePed(animalHash, GetEntityCoords(PlayerPedId()) + vector3(5,0,0), 0.0, true, true)
        TaskCombatPed(animal, PlayerPedId(), 0, 16)
    end
end

RegisterNetEvent('mining:toggleLantern')
AddEventHandler('mining:toggleLantern', function()
    if lanternActive then
        lanternActive = false
        if lightProp then DeleteEntity(lightProp) end
    else
        if not HasItem(Config.FuelItem) then
            Config.Notify('No fuel for lantern')
            return
        end
        lanternActive = true
        TriggerServerEvent('mining:consumeFuel')
        fuelTimer = GetGameTimer() + Config.FuelDuration * 1000
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if lanternActive then
            local playerPed = PlayerPedId()
            local boneIndex = GetPedBoneIndex(playerPed, 21030)
            local boneCoords = GetWorldPositionOfEntityBone(playerPed, boneIndex)
            local lightPos = boneCoords + Config.LightOffset
            DrawLightWithRange(lightPos.x, lightPos.y, lightPos.z, Config.LightColor.r, Config.LightColor.g, Config.LightColor.b, Config.LightRange, Config.LightIntensity)
            
            if GetGameTimer() > fuelTimer then
                if HasItem(Config.FuelItem) then
                    TriggerServerEvent('mining:consumeFuel')
                    fuelTimer = GetGameTimer() + Config.FuelDuration * 1000
                else
                    Config.Notify('Lantern out of fuel!')
                    lanternActive = false
                    if lightProp then DeleteEntity(lightProp) end
                end
            end
        end
    end
end)

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

RSGCore.Functions.DrawText3D = function(coords, text)
    -- Implement or use lib
end