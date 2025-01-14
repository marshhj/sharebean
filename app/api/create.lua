local app = require('app')
local getParams = ParseJsonBody()

local folder = app.checkFolder( getParams('folder') )
local spwd = getParams('spwd')
if folder == '' then return end

if spwd ~= SUPER_PWD then
    return app.err('spwd error!')
end

local folderPath = DATA_PATH .. folder

if path.exists( folderPath ) then
    return app.ok()
end

local a = unix.mkdir( folderPath )
if a == nil then
    return app.err('folder create error!')
end

app.ok()