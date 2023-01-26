local os = require('os')

local self = { n = 100, i = 1 }

function self:track(key, value)
  local c = self.d[key]
  if not c then
    c = { __serialize_as_array = true, n = self.n }
    self.d[key] = c
  end
  self.d[key][self.i] = value
end

function self:slice()
  local datapoints = {}
  for k, v in pairs(self.d) do
    local val = v[self.i]
    if val then datapoints[k] = val end
  end
  return datapoints
end

function self:preTick()
  self.i = (self.i % self.n) + 1
  local c = Shared.data.charts
  if not c then
    c = { d = {} }
    Shared.data.charts = c
  end
  local d = c.d
  if not d then
    d = {}
    c.d = d
  end
  for k, v in pairs(d) do
    v[self.i] = nil
  end
  self.d = d
end

function self:onTick()
  self:track('tick', os.time() / 72)
end

return self
