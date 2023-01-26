-- vim: set ts=2 sw=2 tw=40 et:
local self = {}
local term = require("term")
local cmps = require("component")
local sides = require("sides")

self.stage1 = cmps.proxy(cmps.get("54e95"))
self.stage2 = cmps.proxy(cmps.get("d0d75"))

self.stage1map = {
  macerator = sides.south;
  centrifuge = sides.west;
  washer = sides.north;
  output = sides.east;
  input = sides.up;
}
self.stage2map = {
  output = sides.north;
  input = sides.west;
  cyan = sides.south;
  thermal = sides.south;
  lgray = sides.up;
  mercury = sides.up;
  gray = sides.east;
  sifting = sides.east;
}

function self:onTick()
  for k, v in pairs(Shared.modules.oreprocdata) do
    if self.stage1map[v] == nil and self.stage2map[v] == nil then
      error("invalid machine map: \"" .. k .. "\"=" .. v)
    end
  end
  Shared.data.oreproc = {}
  local function getDst(item)
    local function toOreName(label)
      if label:match(" Ore$") then return label end
      return label .. " Ore"
    end

    local function transformName(item)
      if item.name == "gregtech:gt.blockores" then
        return toOreName(item.label)
      else
        return item.label
      end
    end

    local label = transformName(item)
    local dst = Shared.modules.oreprocdata[label]
    if dst == nil then
      if item.label:match("Purified Pile of ") or item.label:match("Impure Pile of ") then
        dst = "centrifuge"
      elseif item.label:match("Centrifuged ") then
        dst = "macerator"
      else
        dst = "output"
      end
    end
    return dst
  end

  local stacksAttempt = 0
  local function transfer(tp, map)
    local all_items = tp.getAllStacks(map.input)
    local n = all_items.count()
    local sides_filled = {}
    local count = 0
    for i = 1, n do
      local item = all_items[i]
      if item then
        count = count + item.size
        local dst = getDst(item)
        if map[dst] == nil then
          dst = "output"
        end
        if not sides_filled[map[dst]] then
          if tp.transferItem(map.input, map[dst], item.size, i) == 0 then
            sides_filled[map[dst]] = true
          end
        end
        stacksAttempt = stacksAttempt + 1
      end
    end
    if tp == self.stage1 then
      Shared.modules.charts:track("oreproc_s1_inbox", count)
    end
  end

  transfer(self.stage1, self.stage1map)
  transfer(self.stage2, self.stage2map)
  Shared.modules.charts:track("oreproc_stacks", stacksAttempt)
  Shared.log:send(Shared.log.code.info, "Attempted " .. stacksAttempt .. " stacks\n")
end

return self
