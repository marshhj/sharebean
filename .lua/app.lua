local app = {}


function app.init()
end

function app.err( msg, code )
    Write( { code = code or 1, msg = msg or 'error!'} )
end

function app.ok( result ) 
    Write( { code = 0, result = result or {} } )
end

function app.checkFolder( folder )
    local folder = folder or ''
    if string.match(folder, '^[a-z0-9]+$') == nil then
        app.err('folder is not allowed: ' .. folder)
        return ''
    end
    return folder
end

function app.getAuthData( folder )
    local ret = {pwd='', token='', hide=''}
    local authPath = DATA_PATH .. folder .. '/.auth'

    if not path.exists( authPath ) then return ret end
    local d = Slurp( authPath )
    if d == nil then return ret end
    local json = DecodeJson( d )
    if json == nil then return ret end

    ret.pwd = json.pwd or ''
    ret.token = json.token or ''
    ret.hide = json.hide or ''
    return ret
end

function app.convertHideFilter( hide )
    local ret = {}
    local hide = hide or ''
    local arr = string.split(hide, '\n')
    for _,v in ipairs(arr) do
        local pat = string.gsub(v, "%.", "%%.")
        pat = string.gsub(pat, "%*", ".*")
        pat = '^' .. pat .. '$'
        ret[#ret+1] = (v == '*') and v or pat
    end
    return ret
end

function app.checkHide( hide, name )
    name = string.lower( name )
    local ret = false
    if #hide == 0 then return ret end
    if hide[1] == '*' then ret = true end
    for i = (ret and 2 or 1),#hide do
        local v = hide[i]
        if string.match(name, v) then 
            return not ret
        end
    end
    return ret
end

function app.setAuthData( folder, data )
    local ret = app.getAuthData( folder )
    local authPath = DATA_PATH .. folder .. '/.auth'
    for k,v in pairs(data) do
        ret[k] = v
    end
    return Barf(authPath, EncodeJson(ret))
end

function app.getFolderAuth( folder, token)
    --Log(kLogInfo, 'fuck')
    local authData = app.getAuthData( folder )
    local auth = authData.pwd == '' and true or false
    if not auth and token then
        auth = authData.token == token and true or false
    end
    return auth, authData
end

return app