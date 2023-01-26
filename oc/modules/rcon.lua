local self = {}
local fs = require('filesystem')

function self:onTick()
    if fs.exists('/home/rcon') and not fs.exists('/home/rcon.out') then
        local f = fs.open('/home/rcon.out', 'wb')
        local status, v = xpcall(function()
            return assert(loadfile('/home/rcon'))()
        end, function(v)
            f:write(tostring(v) .. '\n' .. debug.traceback() .. '\n')
        end)
        if status then f:write(tostring(v)) end
        f:close()
    end
end

return self
