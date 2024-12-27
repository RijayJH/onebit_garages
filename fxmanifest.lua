fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
game 'gta5'

description 'Garages script'
author 'RijayJH'
version '0.0.1'


client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
    '@oxmysql/lib/MySQL.lua',
}

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}

lua54 'yes'