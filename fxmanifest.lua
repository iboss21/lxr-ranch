--[[
    ██╗     ██╗  ██╗██████╗       ██████╗  █████╗ ███╗   ██╗ ██████╗██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗      ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║  ██║
    ██║      ╚███╔╝ ██████╔╝█████╗██████╔╝███████║██╔██╗ ██║██║     ███████║
    ██║      ██╔██╗ ██╔══██╗╚════╝██╔══██╗██╔══██║██║╚██╗██║██║     ██╔══██║
    ███████╗██╔╝ ██╗██║  ██║      ██║  ██║██║  ██║██║ ╚████║╚██████╗██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝

    🐺 LXR Core - Ranch Simulation & Management System

    A persistent, state-driven agricultural simulation system for RedM that
    transforms ranching into a multi-layered economic, biological, and managerial
    gameplay loop. Features deterministic animal simulation, resource dependency
    chains, ownership structures, market-driven outputs, and time-based decay.

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:      The Land of Wolves 🐺
    Tagline:     Georgian RP 🇬🇪 | მგლების მიწა - რჩეულთა ადგილი!
    Description: ისტორია ცოცხლდება აქ! (History Lives Here!)
    Type:        Serious Hardcore Roleplay
    Access:      Discord & Whitelisted

    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    GitHub:      https://github.com/iBoss21
    Store:       https://theluxempire.tebex.io
    Server:      https://servers.redm.net/servers/detail/8gj7eb

    ═══════════════════════════════════════════════════════════════════════════════

    Version: 1.0.0
    Performance Target: Optimized for minimal server overhead and client FPS impact

    Tags: RedM, Georgian, SeriousRP, Whitelist, Ranch, Livestock, Farming,
          Breeding, Economy, Simulation

    Framework Support:
    - LXR Core (Primary)
    - RSG Core (Compatible)
    - VORP Core (Compatible)
    - RedEM:RP (Compatible)
    - QBR Core (Compatible)
    - QR Core (Compatible)
    - Standalone (Compatible)

    ═══════════════════════════════════════════════════════════════════════════════
    CREDITS
    ═══════════════════════════════════════════════════════════════════════════════

    Script Author: iBoss21 / The Lux Empire for The Land of Wolves
    Original Concept: LXR Ranch (Community Contribution)

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

fx_version 'cerulean'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lxr-ranch'
author      'iBoss21 / The Lux Empire'
description 'Persistent ranch simulation & management system with animal lifecycle, breeding, genetics, economy, and taxation'
version     '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/client.lua',
    'client/npcs.lua',
    'client/modules/*.lua',
    'client/exports.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'server/exports.lua'
}

ui_page 'html/index.html'

files {
    'html/**',
    'locales/*.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

escrow_ignore {
    'config.lua',
    'fxmanifest.lua',
    'README.md',
    'docs/**'
}
