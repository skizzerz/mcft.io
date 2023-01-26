local os = require('os')
local self = { data = Shared.data.time }

if not self.data then
    self.data = {}
    Shared.data.time = self.data
end

function self.now_ms()
    return math.floor(os.time() / 72 * 1000)
end

function self:preTick()
    self.data.last_ms = self.data.cur_ms or self.now_ms()
    self.data.cur_ms = self.now_ms()
    self.data.span_ms = self.data.cur_ms - self.data.last_ms
end

return self
