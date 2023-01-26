local term = require('term')

local self = {}

function self.sendConsole(msg)
    Shared.log:sendTerm(Shared.log.code.error, msg)
end

function self.sendInfo(msg)
    Shared.log:send(Shared.log.code.info, msg)
end

return self
