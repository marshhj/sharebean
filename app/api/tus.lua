local tus = require('tus')

tus.onRequest({
    path = TEMP_PATH,
    url = '/api/tus/', --'http://' .. GetHost() .. ':' .. GetPort() ..'/api/tus/',
    maxsize = MAX_PAYLOAD_SIZE - 1450,
    needmeta = {'filename', 'filetype', 'folder'},
    onfinish = function(meta)
        local dst = DATA_PATH .. meta.meta.folder.. '/'.. meta.meta.filename
        unix.rename( meta.fpath, dst )
    end
})