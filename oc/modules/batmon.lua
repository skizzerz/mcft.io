-- vim: set ts=2 sw=2 tw=40 et:
local self = {}

local cmps = require("component")

self.lsc = cmps.proxy(cmps.get("3577af6f"))

function self:onTick()
  Shared.data.batmon = {
    sensor = self.lsc.getSensorInformation(),
    current = self.lsc.getEUStored(),
    max = self.lsc.getEUCapacity(),
  }
  Shared.modules.charts:track("batmon_raw", Shared.data.batmon.current)
  Shared.modules.charts:track("batmon_pct", Shared.data.batmon.current * 100 / Shared.data.batmon.max)
end

return self
