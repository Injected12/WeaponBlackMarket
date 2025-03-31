local ESX = exports["es_extended"]:getSharedObject()

-- Handle weapon purchase
RegisterServerEvent('privateWeapons:purchaseWeapon')
AddEventHandler('privateWeapons:purchaseWeapon', function(weaponName, price)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player has enough money
    if xPlayer.getMoney() >= price then
        -- Remove money from player
        xPlayer.removeMoney(price)
        
        -- Tell client purchase was successful
        TriggerClientEvent('privateWeapons:purchaseSuccess', source)
        
        -- Store weapon in temp storage for delivery
        TriggerClientEvent('privateWeapons:giveWeapon', source, weaponName)
        
        -- Log purchase (optional)
        print(string.format("[PRIVATE WEAPONS] Player %s purchased %s for $%s", xPlayer.getName(), weaponName, price))
    else
        -- Tell client purchase failed
        TriggerClientEvent('privateWeapons:purchaseFailed', source, "You don't have enough money")
    end
end)
