local mbean = {
    version = '0.0.1'
}

-- simple class
-- https://blog.codingnow.com/cloud/LuaOO
local _class={}
function Class(super)
	local class_type={}
	class_type.ctor=false
	class_type.super=super
	class_type.new=function(...)
			local obj={}
			do
				local create
				create = function(c,...)
					if c.super then
						create(c.super,...)
					end
					if c.ctor then
						c.ctor(obj,...)
					end
				end
				create(class_type,...)
			end
			setmetatable(obj,{ __index=_class[class_type] })
			return obj
		end
	local vtbl={}
	_class[class_type]=vtbl
	setmetatable(class_type,{__newindex=
		function(t,k,v)
			vtbl[k]=v
		end
	})
	if super then
		setmetatable(vtbl,{__index=
			function(t,k)
				local ret=_class[super][k]
				vtbl[k]=ret
				return ret
			end
		})
	end
	return class_type
end
mbean.class = Class

-- base
mbean.try = function( func, catch)
    local status, result = pcall(func)
    if status then
        return result
    else
        if catch then
            catch(result)
        else
            Log(kLogInfo, tostring(result))
        end
    end
end


-- string
function string:split(sep, pattern)
	if sep == "" then return { self } end
	local rs = {}
	local previdx = 1
	while true do
		local startidx, endidx = self:find(sep, previdx, not pattern)
		if not startidx then
			table.insert(rs, self:sub(previdx))
			break
		end
		table.insert(rs, self:sub(previdx, startidx - 1))
		previdx = endidx + 1
	end
	return rs
end

function string:tohex()
    return (self:gsub('.', function (c)
        return string.format('%02x', string.byte(c))
    end))
end



-- table


-- redbean
BLog = function( ... )
    local args = {...}
    local str = ''
    for _,v in ipairs(args) do
        str = str .. tostring(v) .. ' '
    end
    Log(kLogInfo, str)
end

BWrite = function(... )
    local args = {...}
    local str = ''
    for _,v in ipairs(args) do
        str = str.. tostring(v)..''
    end
    Write(str)
end

local _Write = Write
Write = function( obj )
    local t = type(obj)
    if t == "table" then
        _Write( EncodeJson( obj ) )
    else
        _Write( tostring(obj) )
    end
end

ParseJsonBody = function()
    return function( name )
        local bdy = GetHeader('Content-Type') == 'application/json' and DecodeJson(GetBody()) or {}
        local bodyparam = (type(bdy) == 'table') and bdy or {}
        return GetParam(name) or bodyparam[name]
    end
end

path.list = function( dir )
    if( not path.isdir(dir) ) then return {} end
    local ret = {}
    local dirObj = assert(unix.opendir(dir))
    for name in dirObj do
        if name ~= '.' and name ~= '..' then
            ret[#ret+1] = EscapeHtml(name)
        end
    end
    dirObj:close()
    return ret
end


return mbean