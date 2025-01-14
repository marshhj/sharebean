local app = require('app')
local router = require('router').new()

--local approot = 'app/share/'

local function rouApi( path  )
    return RoutePath( 'app/api/'.. path)
end

local function serveAsset( path )
    return ServeAsset( 'app/web/' .. path )
end

-- tus
router:any('/api/tus', function(params)
    return rouApi('tus.lua')
end)

router:any('/api/tus/*', function(params)
    return rouApi('tus.lua')
end)

-- api
router:any('/api/*path', function(params)
    return rouApi( params.path .. '.lua' ) or Write(EncodeJson({
        code = 404,
        msg = 'not found'
    }))
end)

-- download
router:get('/f/*fpath', function(params)
    local dpath =  DATA_PATH .. params.fpath
    local mainfd = GetClientFd()
    if path.isfile( dpath ) then
        local st = unix.stat(dpath)
        if st == nil then return ServeError(404) end
        local size = st:size()
        unix.write(mainfd, 'HTTP/1.0 200 OK\r\n' ..
                   'Date: '.. FormatHttpDateTime(GetDate()) ..'\r\n' ..
                   'Content-Disposition: attachment; filename='.. EscapePath(path.basename(dpath)) .. '\r\n' ..
                   'Connection: close\r\n' ..
                   'Content-Length: ' .. size..'\r\n'..
                   'Server: redbean unix\r\n' ..
                   '\r\n')
        local fd = unix.open(dpath, unix.O_RDONLY)
        if fd ~= nil then
            while true do
                local buf = unix.read(fd)
                if buf == '' or buf == nil then
                    unix.close(fd)
                    break
                else
                    unix.write(mainfd, buf)
                end
            end
        end
        unix.close(mainfd)
    else
        ServeError(404)
    end
end)

-- preview
router:get('/v/:folder/*fname', function(params)
    local folder = params.folder or ''
    local fname = params.fname or ''
    local p = folder .. '/'.. fname

    if not path.exists(DATA_PATH .. p ) then return ServeError(404) end

    local token = GetParam('token') or ''
    local auth,authData = app.getFolderAuth(folder, token)

    local hideFilter = app.convertHideFilter( authData.hide )
    local ishide = app.checkHide(hideFilter, fname)

    if ishide and not auth then return ServeError(404) end
    return ServeAsset( p )
end)

-- homepage
router:get('/', function(params)
    return serveAsset( 'index.html')
end)

-- -- static
router:get('/*path', function(params)
    return serveAsset( params.path ) or
        serveAsset( 'index.html')
end)

router:execute( GetMethod(), GetPath())