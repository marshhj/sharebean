local app = require('app')
local getParams = ParseJsonBody()

local folder = app.checkFolder( getParams('folder') )
if folder == '' then return end

local pwd = getParams('pwd') or ''

local authData = app.getAuthData( folder )

if authData.pwd ~= '' and authData.pwd ~= pwd then
    return app.err('pwd error!')
end

local token = ''
if authData.pwd ~= '' then
    token = GetCryptoHash('MD5', folder .. pwd .. GetTime(), folder)
    token = token:tohex()
end

app.setAuthData(folder, { token = token })
return app.ok({token = token})