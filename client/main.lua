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
        TriggerServerEvent('cb-skills:loadSkills')
    end
    SetupTargets()
end)

-- Ensure targets are set up when the resource starts (covers cases where playerSpawned may not fire)
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Citizen.SetTimeout(1000, function()
            SetupTargets()
        end)
    end
end)

if Config.UseSkills then
    RegisterNetEvent('cb-skills:setSkills')
    AddEventHandler('cb-skills:setSkills', function(skills)
        playerSkills = skills
        for skill, data in pairs(skills) do
            exports.ox_lib:notify({description = skill .. ' Level: ' .. data.level .. ' | XP: ' .. data.xp, type = 'inform'})
        end
    end)

    RegisterNetEvent('cb-skills:setSkill')
    AddEventHandler('cb-skills:setSkill', function(skill, data)
        playerSkills[skill] = data
        exports.ox_lib:notify({description = skill .. ' Level: ' .. data.level .. ' | XP: ' .. data.xp, type = 'inform'})
    end)
end

RegisterNetEvent('mining:notifyReward')
AddEventHandler('mining:notifyReward', function(items)
    if not items or #items == 0 then return end
    local parts = {}
    for i=1, #items do
        local it = items[i]
        parts[#parts+1] = tostring(it.amount) .. 'x ' .. it.item
    end
    local msg = 'You received: ' .. table.concat(parts, ', ')
    exports.ox_lib:notify({description = msg, type = 'success'})
end)

function SetupTargets()
    for _, spot in ipairs(Config.MiningSpots) do
        -- calculate radius from configured size (size is full width/length), add a small margin
        local radius = 3.0
        if spot.size and type(spot.size) == 'vector3' then
            radius = math.max(spot.size.x, spot.size.y) / 2
        elseif spot.radius then
            radius = spot.radius
        end
        radius = radius + 1.0

        exports.ox_target:addSphereZone({
            coords = spot.coords,
            radius = radius,
            debug = true,
            options = {
                {
                    name = 'mine_' .. spot.type,
                    label = 'Mine',
                    icon = 'fas fa-pickaxe',
                    distance = radius + 1,
                    canInteract = function() return HasItem(spot.requiredItem) end,
                    onSelect = function()
                        if HasItem(spot.requiredItem) then
                            StartMining(spot)
                        else
                            exports.ox_lib:notify({description = 'You need a ' .. spot.requiredItem .. ' to mine here.', type = 'error'})
                        end
                    end
                }
            }
        })
        print(string.format('[cb-mining] Added mining sphere at x=%.2f y=%.2f z=%.2f radius=%.2f', spot.coords.x, spot.coords.y, spot.coords.z, radius))
    end
    
    for _, spot in ipairs(Config.SmeltingSpots) do
        exports.ox_target:addBoxZone({
            coords = spot.coords,
            size = spot.size,
            rotation = spot.rotation,
            debug = true,
            options = {
                {
                    name = 'smelt_' .. spot.coords.x .. spot.coords.y,
                    label = 'Smelt',
                    icon = 'fas fa-fire',
                    distance = math.max(spot.size.x, spot.size.y) + 1,
                    -- use default visibility rules (no menuName/distance override)
                    
                    canInteract = function() return HasItem(spot.requiredFuel, spot.fuelAmount) end,
                    onSelect = function()
                        if HasItem(spot.requiredFuel, spot.fuelAmount) then
                            StartSmelting(spot)
                        else
                            exports.ox_lib:notify({description = 'You need ' .. spot.fuelAmount .. ' ' .. spot.requiredFuel .. ' to smelt.', type = 'error'})
                        end
                    end
                }
            }
        })
        print(string.format('[cb-mining] Added smelting zone at x=%.2f y=%.2f z=%.2f', spot.coords.x, spot.coords.y, spot.coords.z))
    end
    
    for _, spot in ipairs(Config.ProspectingSpots) do
        exports.ox_target:addBoxZone({
            coords = spot.coords,
            size = spot.size,
            rotation = spot.rotation,
            debug = true,
            options = {
                {
                    name = 'prospect_' .. spot.coords.x .. spot.coords.y,
                    label = 'Prospect',
                    icon = 'fas fa-search',
                    distance = math.max(spot.size.x, spot.size.y) + 1,
                    -- use default visibility rules (no menuName/distance override)
                    
                    canInteract = function() return HasItem(spot.requiredItem) end,
                    onSelect = function()
                        if HasItem(spot.requiredItem) then
                            StartProspecting(spot)
                        else
                            exports.ox_lib:notify({description = 'You need a ' .. spot.requiredItem .. ' to prospect here.', type = 'error'})
                        end
                    end
                }
            }
        })
        print(string.format('[cb-mining] Added prospecting zone at x=%.2f y=%.2f z=%.2f', spot.coords.x, spot.coords.y, spot.coords.z))
    end
end

function StartMining(spot)
    if miningActive then return end
    local playerPed = PlayerPedId()
    miningActive = true
    local animDict, animClip
    
    if spot.type == 'rock_pickaxe' then
        -- use a safe scenario for pickaxe mining (ox_lib will start/stop scenarios)
        animDict = nil
        animClip = nil
        -- we'll pass a scenario into lib.progressBar below
    elseif spot.type == 'rock_dynamite' then
        animDict = 'mech_dynamite@throw'
        animClip = 'idle'
        -- throw dynamite visual / explosion happens immediately then progress continues
        -- keep the dynamite prop/explosion behavior but don't pre-play the animation here
        Wait(2000)
        local dynProp = CreateObject(GetHashKey('p_dynamite01x'), spot.coords + vector3(0,0,-1), true, true, true)
        Wait(1000)
        AddExplosion(spot.coords, 2, 1.0, true, false, 1.0)
        DeleteEntity(dynProp)
        if math.random() < spot.explosionRisk then
            SetEntityHealth(playerPed, GetEntityHealth(playerPed) - 50)
            exports.ox_lib:notify({description = 'Dynamite misfired!', type = 'error'})
        end
    elseif spot.type == 'gold_pan' then
        animDict = 'script_mp@naturalist@pan_loop'
        animClip = 'pan_loop'
        -- don't pre-play the anim; let lib.progressBar handle it
    end
    
    local level = 1
    local bonus = { yieldMultiplier = 1.0, timeReducer = 0 }
    if Config.UseSkills then
        local skillData = playerSkills[spot.skill] or exports['cb-skills']:GetSkillData(PlayerId(), spot.skill)
        level = skillData.level
        bonus = Config.Skills[spot.skill].levelBonuses[level] or Config.Skills[spot.skill].levelBonuses[1]
    end
    local progressTime = Config.ProgressTime - bonus.timeReducer
    
    -- build animation payload for lib.progressBar; use configurable animation for pickaxe
    local progressAnim = nil
    if spot.type == 'rock_pickaxe' then
        local pickAnim = Config.Animations and Config.Animations.pickaxe or nil
        if pickAnim then
            -- allow use of scenario or dict/clip from config
            if pickAnim.scenario then
                progressAnim = { scenario = pickAnim.scenario }
            elseif pickAnim.dict and pickAnim.clip then
                progressAnim = { dict = pickAnim.dict, clip = pickAnim.clip }
            end
        else
            progressAnim = { scenario = 'WORLD_HUMAN_CROUCH_INSPECT' }
        end
    elseif animDict and animClip then
        progressAnim = { dict = animDict, clip = animClip }
    end

    local ok, res = pcall(lib.progressBar, {
        duration = progressTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disableControl = true,
        disable = { move = true, mouse = true },
        anim = progressAnim,
        label = 'Mining...'
    })
    if ok and res then
        -- clean up animation: if we used a dict/clip stop that, otherwise clear tasks
        if animDict and animClip then
            StopAnimTask(playerPed, animDict, animClip, 1.0)
        else
            ClearPedTasks(playerPed)
        end
        TriggerServerEvent('mining:reward', spot, level)
        if Config.RandomEvents and math.random() < Config.RandomEventChance then
            RandomEvent(playerPed)
        end
    else
        if not ok then
            print('[cb-mining] progressBar pcall error: ' .. tostring(res))
        end
    end
    miningActive = false
end

function StartSmelting(spot)
    if smeltingActive then return end
    local selectedRecipe = nil
    local recipeOptions = {}
    for _, recipe in ipairs(spot.recipes) do
        if HasItem(recipe.input.item, recipe.input.amount) then
            table.insert(recipeOptions, {
                title = recipe.input.item,
                description = 'Smelt ' .. recipe.input.amount .. ' ' .. recipe.input.item .. ' into ' .. recipe.output.amount .. ' ' .. recipe.output.item,
                onSelect = function()
                    selectedRecipe = recipe
                    SmeltItem(spot, selectedRecipe)
                end
            })
        end
    end
    
    if #recipeOptions == 0 then
        exports.ox_lib:notify({description = 'No materials to smelt', type = 'error'})
        return
    end
    
    exports.ox_lib:showContext({
        id = 'smelting_menu',
        title = 'Choose Material to Smelt',
        options = recipeOptions
    })
end

function SmeltItem(spot, recipe)
    smeltingActive = true
    local playerPed = PlayerPedId()
    local animDict = 'amb_work@world_human_anvil@work@male_a@base'
    local animClip = 'base'
    TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    local level = 1
    local bonus = { yieldMultiplier = 1.0, timeReducer = 0 }
    if Config.UseSkills then
        local skillData = playerSkills[spot.skill] or exports['cb-skills']:GetSkillData(PlayerId(), spot.skill)
        level = skillData.level
        bonus = Config.Skills[spot.skill].levelBonuses[level] or Config.Skills[spot.skill].levelBonuses[1]
    end
    local progressTime = recipe.time - bonus.timeReducer
    
    local ok2, res2 = pcall(lib.progressBar, {
        duration = progressTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disableControl = true,
        disable = { move = true, mouse = true },
        anim = { dict = animDict, clip = animClip },
        label = 'Smelting...'
    })
    if ok2 and res2 then
        StopAnimTask(playerPed, animDict, animClip, 1.0)
        TriggerServerEvent('mining:smelt', spot, recipe, level)
    else
        if not ok2 then print('[cb-mining] smelt progressBar pcall error: ' .. tostring(res2)) end
    end
    smeltingActive = false
end

function StartProspecting(spot)
    if prospectingActive then return end
    local playerPed = PlayerPedId()
    prospectingActive = true
    local animDict = 'amb_work@world_human_survey@male_a@base'
    local animClip = 'base'
    TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    local level = 1
    local bonus = { yieldMultiplier = 1.0, timeReducer = 0 }
    if Config.UseSkills then
        local skillData = playerSkills[spot.skill] or exports['cb-skills']:GetSkillData(PlayerId(), spot.skill)
        level = skillData.level
        bonus = Config.Skills[spot.skill].levelBonuses[level] or Config.Skills[spot.skill].levelBonuses[1]
    end
    local progressTime = Config.ProgressTime - bonus.timeReducer
    
    local ok3, res3 = pcall(lib.progressBar, {
        duration = progressTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disableControl = true,
        disable = { move = true, mouse = true },
        anim = { dict = animDict, clip = animClip },
        label = 'Prospecting...'
    })
    if ok3 and res3 then
        StopAnimTask(playerPed, animDict, animClip, 1.0)
        TriggerServerEvent('mining:prospectReward', spot, level)
    else
        if not ok3 then print('[cb-mining] prospect progressBar pcall error: ' .. tostring(res3)) end
    end
    prospectingActive = false
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

RegisterNetEvent('mining:toggleLantern')
AddEventHandler('mining:toggleLantern', function()
    if lanternActive then
        lanternActive = false
        if lightProp then DeleteEntity(lightProp) end
    else
        if not HasItem(Config.FuelItem) then
            exports.ox_lib:notify({description = 'No fuel for lantern', type = 'error'})
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
                    exports.ox_lib:notify({description = 'Lantern out of fuel!', type = 'error'})
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