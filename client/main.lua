local ESX = exports["es_extended"]:getSharedObject()
local marketOpen = false
local isLoggedIn = false
local currentUser = nil
local npcSpawned = false
local weaponDeliveryActive = false
local deliveryNPC = nil
local deliveryBlip = nil

-- Function to show notification
function ShowNotification(message)
    ESX.ShowNotification(message)
end

-- Function to draw 3D text in the world
function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 90)
end

-- Function to open the market UI
function OpenMarketUI()
    marketOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openMarket"
    })
end

-- Function to close the market UI
function CloseMarketUI()
    marketOpen = false
    isLoggedIn = false
    currentUser = nil
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "closeMarket"
    })
end

-- Function to spawn the delivery NPC
function SpawnDeliveryNPC()
    if npcSpawned then return end
    
    -- Request the model
    local model = GetHashKey(Config.NPCModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    -- Create the NPC
    deliveryNPC = CreatePed(4, model, Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z - 1.0, Config.NPCHeading, false, true)
    
    -- Set NPC properties
    SetEntityAsMissionEntity(deliveryNPC, true, true)
    SetBlockingOfNonTemporaryEvents(deliveryNPC, true)
    SetPedDiesWhenInjured(deliveryNPC, false)
    SetPedCanRagdollFromPlayerImpact(deliveryNPC, false)
    SetPedCanRagdoll(deliveryNPC, false)
    SetEntityInvincible(deliveryNPC, true)
    FreezeEntityPosition(deliveryNPC, true)
    
    -- Create blip for the NPC
    deliveryBlip = AddBlipForCoord(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z)
    SetBlipSprite(deliveryBlip, 500)
    SetBlipColour(deliveryBlip, 2)
    SetBlipAsShortRange(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Weapon Delivery")
    EndTextCommandSetBlipName(deliveryBlip)
    
    npcSpawned = true
    weaponDeliveryActive = true
end

-- Function to handle weapon delivery
function DeliverWeapons()
    weaponDeliveryActive = false
    
    -- Play animation
    local playerPed = PlayerPedId()
    TaskTurnPedToFaceEntity(playerPed, deliveryNPC, 2000)
    Wait(2000)
    
    -- Animation for both player and NPC
    RequestAnimDict("mp_common")
    while not HasAnimDictLoaded("mp_common") do
        Wait(1)
    end
    
    TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, -8.0, -1, 0, 0, false, false, false)
    TaskPlayAnim(deliveryNPC, "mp_common", "givetake1_a", 8.0, -8.0, -1, 0, 0, false, false, false)
    Wait(2000)
    
    -- Remove NPC and blip
    if DoesEntityExist(deliveryNPC) then
        DeleteEntity(deliveryNPC)
    end
    
    if deliveryBlip ~= nil then
        RemoveBlip(deliveryBlip)
    end
    
    npcSpawned = false
    deliveryNPC = nil
    deliveryBlip = nil
    
    -- Notification for received weapon
    ShowNotification("You have received your weapon!")
end

-- NUI Callbacks
RegisterNUICallback('login', function(data, cb)
    -- Check login credentials
    local authenticated = false
    for _, user in ipairs(Config.Users) do
        if user.username == data.username and user.password == data.password then
            authenticated = true
            isLoggedIn = true
            currentUser = user
            break
        end
    end
    
    if authenticated then
        -- Send weapons data to UI
        SendNUIMessage({
            type = "loadWeapons",
            weapons = currentUser.weapons
        })
        cb({success = true})
    else
        cb({success = false, message = "Invalid username or password"})
    end
end)

RegisterNUICallback('purchaseWeapon', function(data, cb)
    -- Find weapon in user's available weapons
    local weaponData = nil
    for _, weapon in ipairs(currentUser.weapons) do
        if weapon.name == data.weapon then
            weaponData = weapon
            break
        end
    end
    
    if weaponData then
        -- Trigger server event to handle purchase
        TriggerServerEvent('privateWeapons:purchaseWeapon', weaponData.name, weaponData.price)
        cb({success = true})
    else
        cb({success = false, message = "Weapon not available for purchase"})
    end
end)

RegisterNUICallback('closeUI', function(data, cb)
    CloseMarketUI()
    cb({})
end)

-- Event handlers
RegisterNetEvent('privateWeapons:purchaseSuccess')
AddEventHandler('privateWeapons:purchaseSuccess', function()
    ShowNotification("Your weapon has been purchased and will be delivered nearby.")
    CloseMarketUI()
    SpawnDeliveryNPC()
end)

RegisterNetEvent('privateWeapons:purchaseFailed')
AddEventHandler('privateWeapons:purchaseFailed', function(reason)
    SendNUIMessage({
        type = "purchaseError",
        message = reason
    })
end)

RegisterNetEvent('privateWeapons:giveWeapon')
AddEventHandler('privateWeapons:giveWeapon', function(weaponName)
    GiveWeaponToPed(PlayerPedId(), GetHashKey(weaponName), 100, false, true)
end)

-- Main thread for market location
Citizen.CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - Config.MarketLocation)
        
        if distance < Config.MarketRadius then
            Draw3DText(Config.MarketLocation.x, Config.MarketLocation.y, Config.MarketLocation.z + 1.0, "Press ~g~E~w~ to access weapon market")
            
            if IsControlJustReleased(0, 38) and not marketOpen then -- 38 is E key
                OpenMarketUI()
            end
        end
        
        -- Delivery NPC interaction
        if npcSpawned and weaponDeliveryActive then
            local distanceToNPC = #(playerCoords - Config.NPCLocation)
            
            if distanceToNPC < 2.0 then
                Draw3DText(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z + 1.0, "Press ~g~E~w~ to receive weapons")
                
                if IsControlJustReleased(0, 38) then -- 38 is E key
                    DeliverWeapons()
                end
            end
        end
        
        Citizen.Wait(0)
    end
end)
