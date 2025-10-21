local RSGCore = exports['rsg-core']:GetCoreObject()

RSGCore.Functions.CreateCallback('mining:hasItem', function(source, cb, item, count)
    local Player = RSGCore.Functions.GetPlayer(source)
    local itemData = Player.Functions.GetItemByName(item)
    if itemData and itemData.amount >= count then
        cb(true)
    else
        cb(false)
    end
end)

RegisterServerEvent('mining:reward')
AddEventHandler('mining:reward', function(spot, level)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local bonus = { yieldMultiplier = 1.0 }
    if Config.Skills and spot.skill and Config.Skills[spot.skill] and Config.Skills[spot.skill].levelBonuses then
        bonus = Config.Skills[spot.skill].levelBonuses[level] or Config.Skills[spot.skill].levelBonuses[1]
    end
    local grantedItems = {}

    for _, reward in ipairs(spot.rewards) do
        local amount = math.random(reward.amountMin, reward.amountMax)
        amount = math.floor(amount * bonus.yieldMultiplier)
        if amount > 0 then
            Player.Functions.AddItem(reward.item, amount)
            table.insert(grantedItems, { item = reward.item, amount = amount })
        end
    end

    if math.random() < spot.chanceRare then
        local rareAmount = math.floor(spot.rareReward.amount * bonus.yieldMultiplier)
        Player.Functions.AddItem(spot.rareReward.item, rareAmount)
        table.insert(grantedItems, { item = spot.rareReward.item, amount = rareAmount })
    end

    if #grantedItems > 0 then
        TriggerClientEvent('mining:notifyReward', src, grantedItems)
    end
    
    if Config.UseSkills and Config.Skills and spot.skill and Config.Skills[spot.skill] then
        exports['cb-skills']:AddSkillXP(src, spot.skill, Config.Skills[spot.skill].xpPerAction)
    end
end)

RegisterServerEvent('mining:smelt')
AddEventHandler('mining:smelt', function(spot, recipe, level)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    Player.Functions.RemoveItem(spot.requiredFuel, spot.fuelAmount)
    Player.Functions.RemoveItem(recipe.input.item, recipe.input.amount)

    local grantedItems = {}
    local bonus = { yieldMultiplier = 1.0 }
    if Config.Skills and spot.skill and Config.Skills[spot.skill] and Config.Skills[spot.skill].levelBonuses then
        bonus = Config.Skills[spot.skill].levelBonuses[level] or Config.Skills[spot.skill].levelBonuses[1]
    end
    local outputAmount = math.floor(recipe.output.amount * bonus.yieldMultiplier)
    Player.Functions.AddItem(recipe.output.item, outputAmount)
    table.insert(grantedItems, { item = recipe.output.item, amount = outputAmount })

    if #grantedItems > 0 then
        TriggerClientEvent('mining:notifyReward', src, grantedItems)
    end
    
    if Config.UseSkills and Config.Skills and spot.skill and Config.Skills[spot.skill] then
        exports['cb-skills']:AddSkillXP(src, spot.skill, Config.Skills[spot.skill].xpPerAction)
    end
end)

RegisterServerEvent('mining:prospectReward')
AddEventHandler('mining:prospectReward', function(spot, level)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local bonus = { yieldMultiplier = 1.0 }
    if Config.Skills and spot.skill and Config.Skills[spot.skill] and Config.Skills[spot.skill].levelBonuses then
        bonus = Config.Skills[spot.skill].levelBonuses[level] or Config.Skills[spot.skill].levelBonuses[1]
    end
    
    local grantedItems = {}
    for _, reward in ipairs(spot.rewards) do
        local amount = math.random(reward.amountMin, reward.amountMax)
        amount = math.floor(amount * bonus.yieldMultiplier)
        if amount > 0 then
            Player.Functions.AddItem(reward.item, amount)
            table.insert(grantedItems, { item = reward.item, amount = amount })
        end
    end

    if math.random() < spot.chanceRare then
        local rareAmount = math.floor(spot.rareReward.amount * bonus.yieldMultiplier)
        Player.Functions.AddItem(spot.rareReward.item, rareAmount)
        table.insert(grantedItems, { item = spot.rareReward.item, amount = rareAmount })
    end

    if #grantedItems > 0 then
        TriggerClientEvent('mining:notifyReward', src, grantedItems)
    end
    
    if Config.UseSkills and Config.Skills and spot.skill and Config.Skills[spot.skill] then
        exports['cb-skills']:AddSkillXP(src, spot.skill, Config.Skills[spot.skill].xpPerAction)
    end
end)

RegisterServerEvent('mining:giveItem')
AddEventHandler('mining:giveItem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.AddItem(item, amount)
end)

RegisterServerEvent('mining:removeItem')
AddEventHandler('mining:removeItem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(item, amount)
end)

RegisterServerEvent('mining:consumeFuel')
AddEventHandler('mining:consumeFuel', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(Config.FuelItem, 1)
end)

RSGCore.Functions.CreateUseableItem(Config.LanternHelmet, function(source, item)
    TriggerClientEvent('mining:toggleLantern', source)
end)