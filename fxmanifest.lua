fx_version 'cerulean'
game 'gta5'

author 'ZaK2BaK5906'
description 'ESX Concess Job - Vehicle Dealership with Delivery System & NUI'
version '2.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/delivery.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js'
}

lua54 'yes'

dependencies {
    'es_extended',
    'ox_target',
    'oxmysql'
}
