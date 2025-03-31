-- ESX initialization
local ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        -- Try different methods to get ESX
        if GetResourceState('es_extended') ~= 'missing' then
            if exports['es_extended'] ~= nil and exports['es_extended'].getSharedObject ~= nil then
                ESX = exports['es_extended']:getSharedObject()
            else
                TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            end
        else
            print('ERROR: es_extended not found. Make sure es_extended is installed and started correctly.')
        end
        
        if ESX == nil then
            Citizen.Wait(500)
        end
    end
    print('Private Weapons Market: ESX Loaded Successfully')
end)

-- Handle weapon purchase
RegisterServerEvent('privateWeapons:purchaseWeapon')
AddEventHandler('privateWeapons:purchaseWeapon', function(weaponName, price)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        print('[PRIVATE WEAPONS] ERROR: Player not found when trying to purchase weapon')
        TriggerClientEvent('privateWeapons:purchaseFailed', source, "Error processing purchase. Try again later.")
        return
    end
    
    -- Try different methods to check money (compatibility with different ESX versions)
    local playerMoney = 0
    local canRemoveMoney = false
    
    -- Try each method of getting player's money
    if xPlayer.getMoney then
        playerMoney = xPlayer.getMoney()
        canRemoveMoney = xPlayer.removeMoney ~= nil
    elseif xPlayer.getAccount and xPlayer.getAccount('money') then
        playerMoney = xPlayer.getAccount('money').money
        canRemoveMoney = xPlayer.removeAccountMoney ~= nil
    end
    
    -- Check if player has enough money
    if playerMoney >= price then
        -- Remove money from player (try different methods)
        local success = false
        
        if canRemoveMoney and xPlayer.removeMoney then
            xPlayer.removeMoney(price)
            success = true
        elseif xPlayer.removeAccountMoney then
            xPlayer.removeAccountMoney('money', price)
            success = true
        end
        
        if success then
            -- Tell client purchase was successful
            TriggerClientEvent('privateWeapons:purchaseSuccess', source)
            
            -- Store weapon in temp storage for delivery
            TriggerClientEvent('privateWeapons:giveWeapon', source, weaponName)
            
            -- Log purchase
            local playerName = xPlayer.getName and xPlayer.getName() or ("Player " .. source)
            print(string.format("[PRIVATE WEAPONS] %s purchased %s for $%s", playerName, weaponName, price))
        else
            TriggerClientEvent('privateWeapons:purchaseFailed', source, "Error processing payment. Try again later.")
        end
    else
        -- Tell client purchase failed
        TriggerClientEvent('privateWeapons:purchaseFailed', source, "You don't have enough money")
    end
end)

-- Resource started message
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^2[PRIVATE WEAPONS] ^7Resource started successfully!')
    end
end)

-- Resource stop message
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^1[PRIVATE WEAPONS] ^7Resource stopped!')
    end
end)
