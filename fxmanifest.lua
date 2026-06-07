fx_version 'cerulean'
game 'gta5'

author 'Virtue'
description 'Vitrue Dumpster Diving Script - Optimized dumpster searching with Qbox and ox_lib'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target'
}
