fx_version 'cerulean'
game 'gta5'

client_scripts {
    'cl_main.lua',
    'cl_seatbelt.lua'
}

server_script 'server.lua'

shared_script {
    'config.lua',
    '@ox_lib/init.lua'
}

ui_page 'nui/ui.html'

files {
    'nui/ui.html',
    'nui/styles.css',
    'nui/script.js',
    'nui/img/*.png'
}

lua54 'yes'

escrow_ignore {
    'config.lua'
}