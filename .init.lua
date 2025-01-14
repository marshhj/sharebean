require('config')
require('mbean')

HidePath('/usr/share/zoneinfo/')
HidePath('/usr/share/ssl/')

function OnHttpRequest()
    return RoutePath('app/web/index.lua')
end

function OnServerReload()
    Log(kLogInfo, 'reload')
end

local function initConfig()
    local confPath = arg[1] or 'config.lua'
    if path.exists( confPath ) then loadfile(confPath)() end
    if not CODE_CACHE then
        local _require = require
        package.loaded['mbean'] = nil
        require = function( p )
            package.loaded[p] = nil
            return _require(p)
        end
    end
    ProgramMaxPayloadSize( MAX_PAYLOAD_SIZE )
    ProgramPort( HTTP_PORT )
    if LOG_PATH ~= '' then
        ProgramLogPath( LOG_PATH )
    end
end

local function initDataPath()
    unix.makedirs(DATA_PATH)
    unix.makedirs(TEMP_PATH)
    unix.makedirs(TEMP_PATH .. 'meta')
    ProgramDirectory(DATA_PATH)
end

local function start()
    initConfig()
    initDataPath()
end

start()