fx_version 'cerulean'
game 'gta5'

author 'ZaK2BaK5906'
description 'ESX Concess Job - Vehicle Dealership with Delivery System'
version '2.1.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/delivery.lua',
    'client/showroom.lua'
}

lua54 'yes'

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
    'oxmysql'
}
