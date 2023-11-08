fx_version "adamant"

games { 'gta5'}
lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_script '@ox_lib/init.lua'
client_scripts {
	'config.lua',
	'components.lua',
	'client/main.lua',
}

server_scripts {
	'config.lua',
	'server/main.lua'
}
