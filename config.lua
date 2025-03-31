Config = {}

-- Market location
Config.MarketLocation = vector3(-1296.74, -1117.68, 6.2) -- Location where player can access the market
Config.MarketRadius = 2.0 -- Distance to trigger market notification

-- NPC delivery settings
Config.NPCModel = "s_m_m_ammucountry" -- Model for the weapon delivery NPC
Config.NPCLocation = vector3(-1291.02, -1114.23, 6.5) -- Location where NPC will spawn after purchase
Config.NPCHeading = 269.5 -- NPC heading direction

-- Login credentials (should be moved to a database in production)
Config.Users = {
    {
        username = "dealer1",
        password = "password1",
        weapons = {
            {name = "WEAPON_PISTOL", label = "Pistol", price = 1000},
            {name = "WEAPON_SMG", label = "SMG", price = 3000},
            {name = "WEAPON_ASSAULTRIFLE", label = "Assault Rifle", price = 5000}
        }
    },
    {
        username = "dealer2",
        password = "password2",
        weapons = {
            {name = "WEAPON_HEAVYPISTOL", label = "Heavy Pistol", price = 2000},
            {name = "WEAPON_CARBINERIFLE", label = "Carbine Rifle", price = 6000},
            {name = "WEAPON_SNIPERRIFLE", label = "Sniper Rifle", price = 10000}
        }
    }
}

-- UI Settings
Config.Theme = {
    mainColor = "#014690",
    opacity = 0.85
}

-- Notification settings
Config.NotifyDuration = 5000 -- Duration of notifications in ms
