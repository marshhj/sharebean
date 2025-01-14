local app = require('app')
local getParams = ParseJsonBody()

local folder = app.checkFolder( getParams('folder') )
local token = getParams('token')
local name = getParams('name') or ''
if folder == '' then return end

if name == '' or name:match("([<>:\"/\\|?*])") ~= nil then
    return app.err('name is not allowed')
end

local auth = app.getFolderAuth(folder, token)

if not auth then
    return app.err('auth error')
end

local fpath = DATA_PATH .. folder .. '/'.. name
if not unix.unlink( fpath ) then
    return app.err('file not exists')
end

return app.ok()