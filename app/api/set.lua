local app = require('app')
local getParams = ParseJsonBody()

local folder = app.checkFolder( getParams('folder') )
if folder == '' then return end

local token = getParams('token')
local pwd = getParams('pwd') or ''
local hide = getParams('hide') or ''

local auth,authData = app.getFolderAuth(folder, token)
if not auth then return app.err('auth error') end

if pwd == '' then pwd = authData.pwd end

local token = GetCryptoHash('MD5', folder .. pwd .. GetTime(), folder)
token = string.tohex( token )

app.setAuthData(folder, {
    pwd = pwd,
    hide = hide,
    token = token
})
return app.ok({token = token})