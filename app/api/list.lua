local app = require('app')
local getParams = ParseJsonBody()

local folder = app.checkFolder( getParams('folder') )
local token = getParams('token')
if folder == '' then return end

local folderPath = DATA_PATH .. folder

if not path.exists( folderPath ) then
    return app.err('', 2)
end

local auth,authData = app.getFolderAuth(folder, token)

local hideFilter = app.convertHideFilter( authData.hide )

local names = path.list( folderPath )
local files = {[0]=false}
for _,v in ipairs(names) do
    if v == '.auth' then goto continue end
    local ishide = app.checkHide(hideFilter, v)
    if ishide and not auth then goto continue end
    local st = assert(unix.stat( folderPath.. '/'.. v ))
    files[#files+1] = { name = v, size = st:size(), hide = ishide}
    ::continue::
end

return Write( {
    code = 200,
    files = files,
    auth = auth
} )
