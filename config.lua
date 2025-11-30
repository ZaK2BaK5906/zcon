Config = {}

-- Job name
Config.JobName = 'taxi'

-- Society name
Config.SocietyName = 'society_taxi'

-- Grades with permissions
Config.Grades = {
    employee = 0,  -- chauffeur
    manager = 1,   -- gérant
    boss = 2       -- boss
}

-- Minimum grade for boss menu
Config.BossGrade = 2

-- Boss Menu zone
Config.BossMenuZone = {
    coords = vector3(895.0, -179.0, 74.0),  -- Downtown Cab Co
    size = vector3(2.0, 2.0, 2.0),
    rotation = 0.0,
    debug = false,
    icon = 'fa-solid fa-briefcase',
    label = 'Menu Patron'
}

-- NPC Mission locations (~20 missions)
Config.NPCMissions = {
    {name = "Centre-ville vers Aéroport", pickup = vector4(213.0, -809.0, 31.0, 340.0), dropoff = vector4(-1037.0, -2738.0, 20.0, 240.0), price = 950},
    {name = "Hôpital vers Vinewood", pickup = vector4(338.0, -1395.0, 32.0, 50.0), dropoff = vector4(106.0, 196.0, 105.0, 340.0), price = 850},
    {name = "Sandy Shores vers Ville", pickup = vector4(1961.0, 3740.0, 32.0, 300.0), dropoff = vector4(-48.0, -1097.0, 26.0, 70.0), price = 1000},
    {name = "Paleto Bay vers Centre", pickup = vector4(-280.0, 6230.0, 31.0, 45.0), dropoff = vector4(228.0, -786.0, 30.0, 160.0), price = 1000},
    {name = "Commissariat vers Hôpital", pickup = vector4(441.0, -982.0, 30.0, 90.0), dropoff = vector4(295.0, -1447.0, 29.0, 320.0), price = 750},
    {name = "Plage vers Centre", pickup = vector4(-1223.0, -1481.0, 4.0, 125.0), dropoff = vector4(147.0, -1035.0, 29.0, 340.0), price = 800},
    {name = "Vinewood Hills vers Aéroport", pickup = vector4(758.0, 618.0, 128.0, 180.0), dropoff = vector4(-1278.0, -3392.0, 13.0, 330.0), price = 980},
    {name = "Gare vers Hôtel", pickup = vector4(-545.0, -1290.0, 26.0, 240.0), dropoff = vector4(316.0, -229.0, 54.0, 70.0), price = 720},
    {name = "Centre vers Sandy Shores", pickup = vector4(-251.0, -978.0, 31.0, 70.0), dropoff = vector4(1905.0, 3732.0, 32.0, 210.0), price = 990},
    {name = "Aéroport vers Ville", pickup = vector4(-1042.0, -2746.0, 21.0, 330.0), dropoff = vector4(-815.0, -97.0, 37.0, 205.0), price = 920},
    {name = "Port vers Centre", pickup = vector4(1208.0, -3115.0, 5.0, 90.0), dropoff = vector4(215.0, -810.0, 30.0, 250.0), price = 870},
    {name = "Vinewood vers Plage", pickup = vector4(-1430.0, 462.0, 109.0, 280.0), dropoff = vector4(-1212.0, -1494.0, 4.0, 125.0), price = 780},
    {name = "Route 68 vers Paleto", pickup = vector4(1705.0, 3608.0, 35.0, 210.0), dropoff = vector4(-105.0, 6528.0, 29.0, 45.0), price = 950},
    {name = "Hôpital vers Commissariat", pickup = vector4(358.0, -593.0, 28.0, 250.0), dropoff = vector4(425.0, -981.0, 30.0, 90.0), price = 700},
    {name = "Casino vers Aéroport", pickup = vector4(924.0, 47.0, 81.0, 145.0), dropoff = vector4(-1269.0, -3387.0, 13.0, 330.0), price = 960},
    {name = "Mirror Park vers Centre", pickup = vector4(1207.0, -620.0, 65.0, 210.0), dropoff = vector4(174.0, -1006.0, 29.0, 340.0), price = 730},
    {name = "Little Seoul vers Vinewood", pickup = vector4(-526.0, -213.0, 37.0, 210.0), dropoff = vector4(372.0, 326.0, 103.0, 165.0), price = 810},
    {name = "Grapeseed vers Sandy", pickup = vector4(2451.0, 4968.0, 46.0, 45.0), dropoff = vector4(1960.0, 3748.0, 32.0, 300.0), price = 760},
    {name = "Banque vers Hôpital", pickup = vector4(150.0, -1040.0, 29.0, 340.0), dropoff = vector4(304.0, -1433.0, 29.0, 320.0), price = 720},
    {name = "Docks vers Centre", pickup = vector4(-1649.0, -3142.0, 13.0, 240.0), dropoff = vector4(-58.0, -1099.0, 26.0, 70.0), price = 1000}
}

-- Blip settings
Config.Blip = {
    enabled = true,
    coords = vector3(895.0, -179.0, 74.0),
    sprite = 198,
    color = 5,
    scale = 0.8,
    label = 'Taxi Downtown'
}
