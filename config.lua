Config = {}

-- Job name
Config.JobName = 'concess'

-- Society name
Config.SocietyName = 'society_concess'

-- Grades with permissions
Config.Grades = {
    employee = 0,  -- employé
    manager = 1,   -- gérant
    boss = 2       -- boss
}

-- Minimum grade for boss menu
Config.BossGrade = 2

-- Minimum grade for ordering
Config.MinGradeToOrder = 0

-- Zones (Sandy Shores Cardealer)
Config.Zones = {
    -- Bureau/Tablette - Menu de gestion
    Office = {
        coords = vector3(1922.7627, 3725.1802, 32.5662),
        size = vector3(2.0, 2.0, 2.0),
        rotation = 0.0,
        debug = false,
        icon = 'fa-solid fa-tablet',
        label = 'Ouvrir le menu de gestion'
    },

    -- Garage employé - Sortir véhicule de service
    Garage = {
        coords = vector3(1894.9537, 3714.4873, 32.5113),
        size = vector3(3.0, 3.0, 2.0),
        rotation = 0.0,
        debug = false,
        icon = 'fa-solid fa-warehouse',
        label = 'Garage de service',
        spawnPoint = vector4(1891.5820, 3711.9229, 32.5113, 210.0)
    },

    -- Zone de déchargement
    Unload = {
        coords = vector3(1900.2015, 3716.9209, 32.3932),
        size = vector3(5.0, 5.0, 2.0),
        rotation = 0.0,
        debug = false,
        icon = 'fa-solid fa-dolly',
        label = 'Zone de déchargement'
    },

    -- Menu Boss (séparé)
    BossMenu = {
        coords = vector3(1925.0, 3727.0, 32.5662),
        size = vector3(2.0, 2.0, 2.0),
        rotation = 0.0,
        debug = false,
        icon = 'fa-solid fa-briefcase',
        label = 'Menu Patron'
    }
}

-- Showroom spots (employees can place vehicles here)
Config.ShowroomSpots = {
    vector4(1917.3323, 3736.0859, 32.5662, 206.2456),
    vector4(1916.5022, 3712.5427, 32.5662, 26.2196),
    vector4(1921.7382, 3715.1169, 32.5661, 34.5537),
    vector4(1909.5616, 3734.7903, 32.5735, 112.2522),
    vector4(1906.8090, 3723.0435, 32.5697, 25.0360),
    vector4(1910.3209, 3727.8323, 32.5735, 63.2570)
}

-- Citizen catalog zones (where citizens can browse vehicles)
Config.CitizenCatalogZones = {
    {
        coords = vector3(1912.0, 3730.0, 32.5662),
        size = vector3(2.0, 2.0, 2.0),
        rotation = 0.0,
        icon = 'fa-solid fa-book',
        label = 'Consulter le catalogue'
    },
    {
        coords = vector3(1914.0, 3720.0, 32.5662),
        size = vector3(2.0, 2.0, 2.0),
        rotation = 0.0,
        icon = 'fa-solid fa-book',
        label = 'Consulter le catalogue'
    },
    {
        coords = vector3(1920.0, 3732.0, 32.5662),
        size = vector3(2.0, 2.0, 2.0),
        rotation = 0.0,
        icon = 'fa-solid fa-book',
        label = 'Consulter le catalogue'
    }
}

-- Delivery locations (random points for vehicle pickup)
Config.DeliveryLocations = {
    vector4(100.2705, 6376.7852, 31.2258, 117.5896),
    vector4(2536.1978, 2614.6311, 37.9448, 130.8772),
}

-- Service vehicle
Config.ServiceVehicle = {
    model = 'flatbed',
    livery = 0
}

-- Vehicle catalog (vehicles available for ordering)
Config.Vehicles = {
    -- Compacts
    {
        category = 'Compacts',
        vehicles = {
            {model = 'blista', name = 'Blista', price = 12000},
            {model = 'brioso', name = 'Brioso R/A', price = 15000},
            {model = 'dilettante', name = 'Dilettante', price = 13000},
            {model = 'issi2', name = 'Issi', price = 10000},
            {model = 'panto', name = 'Panto', price = 9500},
            {model = 'prairie', name = 'Prairie', price = 14000},
            {model = 'rhapsody', name = 'Rhapsody', price = 11000}
        }
    },

    -- Sedans
    {
        category = 'Sedans',
        vehicles = {
            {model = 'asea', name = 'Asea', price = 16000},
            {model = 'asterope', name = 'Asterope', price = 18000},
            {model = 'cognoscenti', name = 'Cognoscenti', price = 45000},
            {model = 'emperor', name = 'Emperor', price = 14000},
            {model = 'fugitive', name = 'Fugitive', price = 32000},
            {model = 'glendale', name = 'Glendale', price = 15000},
            {model = 'ingot', name = 'Ingot', price = 17000},
            {model = 'intruder', name = 'Intruder', price = 19000},
            {model = 'premier', name = 'Premier', price = 16500},
            {model = 'primo', name = 'Primo', price = 15500},
            {model = 'regina', name = 'Regina', price = 12000},
            {model = 'schafter2', name = 'Schafter', price = 35000},
            {model = 'stanier', name = 'Stanier', price = 13000},
            {model = 'stratum', name = 'Stratum', price = 16000},
            {model = 'stretch', name = 'Stretch', price = 55000},
            {model = 'superd', name = 'Super Diamond', price = 65000},
            {model = 'surge', name = 'Surge', price = 21000},
            {model = 'tailgater', name = 'Tailgater', price = 28000},
            {model = 'warrener', name = 'Warrener', price = 17000},
            {model = 'washington', name = 'Washington', price = 19000}
        }
    },

    -- SUVs
    {
        category = 'SUVs',
        vehicles = {
            {model = 'baller', name = 'Baller', price = 45000},
            {model = 'cavalcade', name = 'Cavalcade', price = 42000},
            {model = 'contender', name = 'Contender', price = 48000},
            {model = 'dubsta', name = 'Dubsta', price = 50000},
            {model = 'fq2', name = 'FQ 2', price = 38000},
            {model = 'granger', name = 'Granger', price = 44000},
            {model = 'gresley', name = 'Gresley', price = 40000},
            {model = 'habanero', name = 'Habanero', price = 43000},
            {model = 'huntley', name = 'Huntley S', price = 55000},
            {model = 'landstalker', name = 'Landstalker', price = 41000},
            {model = 'mesa', name = 'Mesa', price = 35000},
            {model = 'patriot', name = 'Patriot', price = 52000},
            {model = 'radi', name = 'Radius', price = 39000},
            {model = 'rocoto', name = 'Rocoto', price = 46000},
            {model = 'seminole', name = 'Seminole', price = 37000},
            {model = 'serrano', name = 'Serrano', price = 43000},
            {model = 'xls', name = 'XLS', price = 47000}
        }
    },

    -- Coupés
    {
        category = 'Coupés',
        vehicles = {
            {model = 'cogcabrio', name = 'Cognoscenti Cabrio', price = 58000},
            {model = 'exemplar', name = 'Exemplar', price = 52000},
            {model = 'f620', name = 'F620', price = 48000},
            {model = 'felon', name = 'Felon', price = 55000},
            {model = 'jackal', name = 'Jackal', price = 46000},
            {model = 'oracle', name = 'Oracle', price = 43000},
            {model = 'sentinel', name = 'Sentinel', price = 50000},
            {model = 'windsor', name = 'Windsor', price = 95000},
            {model = 'zion', name = 'Zion', price = 45000}
        }
    },

    -- Sports
    {
        category = 'Sports',
        vehicles = {
            {model = 'alpha', name = 'Alpha', price = 85000},
            {model = 'banshee', name = 'Banshee', price = 95000},
            {model = 'bestiagts', name = 'Bestia GTS', price = 105000},
            {model = 'blista2', name = 'Blista Compact', price = 35000},
            {model = 'buffalo', name = 'Buffalo', price = 48000},
            {model = 'buffalo2', name = 'Buffalo S', price = 65000},
            {model = 'carbonizzare', name = 'Carbonizzare', price = 115000},
            {model = 'comet2', name = 'Comet', price = 88000},
            {model = 'coquette', name = 'Coquette', price = 98000},
            {model = 'elegy2', name = 'Elegy RH8', price = 72000},
            {model = 'feltzer2', name = 'Feltzer', price = 82000},
            {model = 'furoregt', name = 'Furore GT', price = 92000},
            {model = 'fusilade', name = 'Fusilade', price = 68000},
            {model = 'jester', name = 'Jester', price = 78000},
            {model = 'kuruma', name = 'Kuruma', price = 75000},
            {model = 'massacro', name = 'Massacro', price = 105000},
            {model = 'ninef', name = 'Nine F', price = 125000},
            {model = 'penumbra', name = 'Penumbra', price = 52000},
            {model = 'rapidgt', name = 'Rapid GT', price = 86000},
            {model = 'schafter3', name = 'Schafter V12', price = 115000},
            {model = 'sultan', name = 'Sultan', price = 58000},
            {model = 'surano', name = 'Surano', price = 94000},
            {model = 'tropos', name = 'Tropos Rallye', price = 102000},
            {model = 'verlierer2', name = 'Verlierer', price = 118000}
        }
    },

    -- Super
    {
        category = 'Super',
        vehicles = {
            {model = 'adder', name = 'Adder', price = 1200000},
            {model = 'bullet', name = 'Bullet', price = 285000},
            {model = 'cheetah', name = 'Cheetah', price = 375000},
            {model = 'entityxf', name = 'Entity XF', price = 695000},
            {model = 'infernus', name = 'Infernus', price = 380000},
            {model = 'osiris', name = 'Osiris', price = 1950000},
            {model = 'reaper', name = 'Reaper', price = 1595000},
            {model = 't20', name = 'T20', price = 2200000},
            {model = 'turismor', name = 'Turismo R', price = 485000},
            {model = 'tyrus', name = 'Tyrus', price = 1550000},
            {model = 'vacca', name = 'Vacca', price = 425000},
            {model = 'voltic', name = 'Voltic', price = 195000},
            {model = 'zentorno', name = 'Zentorno', price = 1450000}
        }
    }
}

-- Animation settings
Config.LoadAnimation = {
    dict = 'anim@heists@box_carry@',
    anim = 'idle',
    duration = 5000  -- 5 seconds
}

-- Vehicle attachment offsets for flatbed
Config.VehicleAttachment = {
    offset = vector3(0.0, -2.0, 1.2),
    rotation = vector3(0.0, 0.0, 0.0)
}

-- Sell price multiplier (sell for 120% of buy price)
Config.SellPriceMultiplier = 1.2

-- Notification settings
Config.UseOxLib = true  -- Set to false to use ESX notifications

-- Map blip settings
Config.Blip = {
    enabled = true,
    coords = vector3(1922.7627, 3725.1802, 32.5662),  -- Same as office location
    sprite = 326,  -- Car dealership icon
    color = 3,     -- Blue
    scale = 0.8,
    label = 'Concess Auto'
}
