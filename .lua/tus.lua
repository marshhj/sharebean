local function randomID( len )
    math.randomseed(os.time())
    local len = len or 16
    local str = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local ret = ''
    for i = 1, len do
        local idx = math.random(1, #str)
        ret = ret..str:sub(idx, idx)
    end
    return ret
end


local BaseHandler = Class()

function BaseHandler:ctor( options )
    self.version = '1.0.0'
    self.options = options
    self.path = options.path or 'tus/'
    self.url = options.url or ''
    self.maxsize = options.maxsize or 1024
end

function BaseHandler:send()
    Write('Hello tus!')
end

function BaseHandler:generateUrl()
    return 'BaseHandler:generateUrl'
end

function BaseHandler:getHeaderInteger( key, dft )
    return tonumber( GetHeader(key) ) or dft
end

function BaseHandler:getMetaPath()
    return self.path .. 'meta/' .. self:getID() .. '.json'
end

function BaseHandler:getMeta()
    local dat = Slurp( self:getMetaPath() )
    if dat == nil then return nil end
    return DecodeJson(dat)
end

function BaseHandler:setMeta(meta)
    local dat = EncodeJson(meta)
    return Barf(self:getMetaPath(), dat )
end

function BaseHandler:deleteMeta()
    return unix.unlink(self:getMetaPath())
end

function BaseHandler:getID()
    if self.id then return self.id end
    local p = GetPath()
    local fpath = p:split('/')
    local id = fpath[#fpath]
    return id
end

function BaseHandler:getFilePath()
    return self.path .. self:getID()
end

function BaseHandler:decodeMeta( meta)
    local ret = {}
    local marr = meta:split(',')
    for _,v in pairs(marr) do
        local varr = v:split(' ')
        if #varr == 2 then
            ret[varr[1]] = DecodeBase64( varr[2] )
        end
    end
    return ret
end



local GetHandler = Class(BaseHandler)
function GetHandler:send()
    Write('Hello tus get!')
end


local HeadHandler = Class(BaseHandler)
function HeadHandler:send()
    local meta = self:getMeta()
    if meta == nil then return ServeError(404) end

    local st = unix.stat( self:getFilePath() )
    local offset = 0
    if st ~= nil then
        offset = st:size()
    end

    SetStatus(200)
    SetHeader('Tus-Resumable', self.version)
    SetHeader('Upload-Offset', offset)
    SetHeader('Upload-Length', meta.uploadLength)
    SetHeader('Tus-Max-Size', self.maxsize)
end


local PostHandler = Class(BaseHandler)
function PostHandler:send()
    local uploadLength = tonumber( GetHeader('Upload-Length') ) or 0
    if uploadLength == 0 then
        return ServeError(400)
    end

    local meta = self:decodeMeta(GetHeader('Upload-Metadata') or '')
    for _,v in pairs(self.options.needmeta) do
        if meta[v] == nil then 
            return ServeError(400) 
        end
    end

    local id,url = self.options.idfunc(meta)
    self.id = id
    local meta = {
        id = id,
        url = url,
        uploadLength = uploadLength,
        meta = meta
    }
    self:setMeta(meta)

    SetStatus(201)
    SetHeader('Tus-Resumable', self.version)
    SetHeader('Location', url)
    SetHeader('Tus-Max-Size', self.maxsize)
end


local PatchHandler = Class(BaseHandler)

function PatchHandler:send()
    local bodyLength = #GetBody()

    local fpath = self:getFilePath()

    local uploadOffset = tonumber( GetHeader('Upload-Offset') ) or 0

    if GetHeader('Content-Type') ~= 'application/offset+octet-stream' then
        return ServeError(415)
    end

    local st = unix.stat(fpath)
    if st == nil and uploadOffset ~= 0 then
        return ServeError(409)
    end

    if uploadOffset == 0 and st ~= nil then
        return ServeError(409)
    end

    assert( Barf(fpath, GetBody(), 0777,unix.O_CREAT | unix.O_APPEND, 1) )

    --check finished
    local meta = self:getMeta()
    if meta == nil then
        return ServeError(409)
    end

    if meta.uploadLength == uploadOffset + bodyLength then
        meta.fpath = fpath
        self.options.onfinish(meta)
        self:deleteMeta()
    end

    SetStatus(204)
    SetHeader('Upload-Offset', uploadOffset + bodyLength)
    SetHeader('Tus-Max-Size', self.maxsize)
    SetHeader('Tus-Resumable', self.version)
end




local DeleteHandler = Class(BaseHandler)

function DeleteHandler:send()
    unix.unlink( self:getFilePath() )
    SetStatus(204)
    SetHeader('Tus-Resumable', self.version)
end


local OptionsHandler = Class(BaseHandler)
function OptionsHandler:send()
    SetStatus(204)
    SetHeader('Tus-Resumable', self.version)
    SetHeader('Tus-Max-Size', self.maxsize)
    SetHeader('Tus-Version', self.version)
end




local HandlerMap = {
    GET = GetHandler,
    HEAD = HeadHandler,
    POST = PostHandler,
    DELETE = DeleteHandler,
    PATCH = PatchHandler,
    OPTIONS = OptionsHandler
}

local function onRequest(conf)
    conf = conf or {}

    local method = GetMethod()
    local Handler = HandlerMap[method]

    if not Handler then
        return ServeError(405)
    end

    local url = conf.url or ''
    local handler = Handler.new( {
        path = conf.path or 'tus/',
        url = url,
        maxsize = conf.maxsize or 60000,
        idfunc = conf.idfunc or function(meta)
            local id = randomID() .. '_' .. meta.filename
            local url = EscapePath( url .. id )
            return id,url
        end,
        needmeta = conf.needmeta or {'filename', 'filetype'},
        onfinish = conf.onfinish or function() end
    })
    if handler.send then
        return handler:send()
    end
end

return {
    onRequest = onRequest,
}
