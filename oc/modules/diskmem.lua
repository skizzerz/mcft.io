local fs = require('filesystem')
local computer = require('computer')

local self = {}

function self:onTick()
  local used = fs.fstab['/'].fs.spaceUsed()
  Shared.modules.charts:track('disk_used_bytes', used)
  Shared.modules.charts:track('disk_used_pct', used * 100 / fs.fstab['/'].fs.spaceTotal())
  local total = computer.totalMemory()
  local free = computer.freeMemory()
  Shared.modules.charts:track('mem_used_bytes', total - free)
  Shared.modules.charts:track('mem_used_pct', 100 - free / total * 100)

  if 100 * free / total < 10 then
    Shared.data.pending_reboot = true
    Shared.modules.sysmsg.sendConsole("Reboot pending.")
  end
end

return self
