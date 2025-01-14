local app = require('app')
local getParams = ParseJsonBody()

local folder = app.checkFolder( getParams('folder') )
if folder == '' then return end

local token = getParams('token')

local auth,authData = app.getFolderAuth(folder, token)

if not auth then return app.err('auth error!') end


return app.ok({hide=authData.hide})
