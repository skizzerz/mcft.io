-- vim: set ts=2 sw=2 tw=40 et:

---@type fun(base:table, field:string): table
local function defaultobj(base, field)
  ---@type table | nil
  local x = base[field]
  if not x then
    x = {}
    base[field] = x
  end
  return x
end

local self = {
  data = defaultobj(Shared.data, 'memon'),
  itemcache = {},
  projections = {},
}
local cmps = require("component")
local sides = require("sides")

-- { itemname_to_stock, qty [, to_craft = ...] [, craft_max = ...] }
self.items_to_stock = {
  { 'Potassium Disulfate Dust', 64, target = 128, cpu = 'AutoCPU3' },
  { "Potassium Dichromate Dust", 64, target = 128, cpu = 'AutoCPU3' },
  { 'Wireless Transmitter', 2 },
  { 'Wireless Receiver', 2 },
  { 'AND Gate', 2 },
  { 'Lapotron Crystal', 4, target = 10 },
  { 'ME Dual Interface', 4 },
  { 'ME Interface', 2 },
--  { 'Ender Fluid Conduit', 32, target = 40 },
  { 'Item Conduit', 32, target = 40 },
  { 'LV Machine Hull', 16, target = 20 },
  { 'MV Machine Hull', 16, target = 20 },
  { 'HV Machine Hull', 16, target = 20 },
  { 'EV Machine Hull', 4, target = 8 },
  { 'IV Machine Hull', 4 },
  { 'LuV Machine Hull', 4},
  { 'Electric Piston (LV)', 4 },
  { 'Electric Motor (LV)', 16, target = 20 },
  { 'Electric Motor (MV)', 16, target = 20 },
  { 'Electric Motor (HV)', 16, target = 20 },
  { 'Electric Motor (EV)', 4, target = 8 },
  { 'Electric Motor (IV)', 4 },
  { 'Electric Pump (LV)', 16 },
  { 'Electric Pump (MV)', 16 },
  { 'Electric Pump (HV)', 16 },
  { 'Electric Pump (EV)', 4 },
  { 'Electric Pump (IV)', 4 },
  { 'Iron Tank', 16, target = 20 },
  { 'Blank Pattern', 8, target = 12 },
  { 'Nanoprocessor', 32, target = 20 },
  { 'Quantumprocessor', 64, target = 20 },
  { 'SMD Capacitor', 512, target = 600 },
  { 'SMD Resistor', 512, target = 600 },
  { 'QBit Processing Unit', 128 },
  { 'Formation Core', 2 },
  { 'Annihilation Core', 2 },
  { 'Logic Processor', 16, target = 32 },
  { 'Calculation Processor', 8, target = 16 },
  { 'Engineering Processor', 4, target = 8 },
  { 'ME Glass Cable - Fluix', 16, target = 32 },
  { 'Certus Quartz Screw', 32, target = 64 },
  { 'Nether Quartz Rod', 16, target = 32 },
  { 'Certus Quartz Rod', 16, target = 32 },
  { 'Copper Foil', 128, target = 150 },
  { 'Energetic Alloy Foil', 64, target = 100 },
  { 'Electrum Foil', 128, target = 150 },
  { 'Titanium Plate', 64, target = 96 },
  { 'Stainless Steel Plate', 64, target = 128 },
  { 'Cupronickel Ingot', 64, target = 128 },
  { 'Steel Plate', 128, target = 150 },
  { 'Red Alloy Ingot', 128, target = 150 },
  { 'Electrum Ingot', 128, target = 150 },
  { 'Iron Ingot', 2000, target = 2300, craft_max = 640, cpu = 'AutoCPU3' },
  { 'Copper Ingot', 2000, target = 2300, craft_max = 640, cpu = 'AutoCPU3' },
  { 'Silver Ingot', 2000, target = 2300, craft_max = 640, cpu = 'AutoCPU3' },
  { 'Gold Ingot', 1000, target = 1100, craft_max = 640, cpu = 'AutoCPU3' },
 
  {'Steel Ingot', 1024, 2048, craft_max=512, cpu = 'AutoCPU4' },
  {'HSS-E Ingot', 1024, 2048, craft_max=512, cpu = 'AutoCPU4' },
  {'Ruridit Ingot', 1024, 2048, craft_max=64, cpu = 'AutoCPU4' },
  {'Annealed Copper Ingot', 1024, 2048, cpu = 'AutoCPU4' },
  {'Titanium Ingot', 1024, 2048, craft_max=512, cpu = 'AutoCPU4' },
  {'Iridium Ingot', 1024, 2048, craft_max=512, cpu = 'AutoCPU4' },
  {'Energetic Alloy Ingot', 1024, 2048, cpu = 'AutoCPU4' },
  
  { 'Chest', 8 },
  { 'Water Cell', 32 },
  { 'drop of Radon', 3800000,craft_max=5000, cpu= 'AutoCPU3' },
  { 'drop of Chlorine', 1000000, target = 2560000, craft_max = 128000, cpu = 'AutoCPU3' },
  { 'drop of Hydrochloric Acid', 200000, target = 256000, cpu = 'AutoCPU3' },
  { 'drop of Hydrofluoric Acid', 128000, target = 150000, cpu = 'AutoCPU3' },
  { 'drop of Ammonia', 1000000, target = 1250000, cpu = 'AutoCPU3' },
  { 'drop of Ammonium Chloride', 32000, target = 48000, cpu = 'AutoCPU3' },
  { 'drop of Sulfuric Acid', 48000, target = 64000, cpu = 'AutoCPU3' },
  { 'drop of Nitric Acid', 48000, target = 64000, cpu = 'AutoCPU3' },
  { 'drop of Molten Polytetrafluoroethylene', 36000, target = 40000 },
  { 'drop of Molten Polybenzimidazole', 36000, target = 40000 },
  { 'drop of Molten Rubber', 36000, target = 40000 },
  { 'drop of Platinum Concentrate', 100000, target = 200000},
  { 'drop of Nitrobenzene', 128000, craft_max = 16000, cpu = 'AutoCPU2'},
  { 'drop of High Octane Gasoline', 128000, craft_max = 16000, cpu = 'AutoCPU2'},
  { 'Aqua Regia Cell', 64, target = 80 },
  { 'Polydimethylsiloxane Pulp', 32 },
  { 'Quad Fuel Rod (Uranium)', 7, target = 14 },

  { 'drop of Antimony Pentachloride', 2000, to_craft = 'drop of Antimony Pentachloride Solution' },
  { 'Rhodium Filter Cake Dust', 128, target = 150, craft_max = 32, to_craft = 'Rhodium Nitrate Dust' },
  { 'Platinum Dust', 5000, target = 6000, craft_max = 32 },
  { 'Rhodium Dust', 5000, target = 6000, craft_max = 32 },
  {'Osmium Dust', 1024, 2048, craft_max=16 },
}

-- {
--   name_to_monitor,
--   take_action_above_qty,
--   action_to_take,
--   qty_for_action,
--   [ consume = N, ]
-- }
self.items_to_proc = {
  { 'Calcium Chloride Dust', 2500, 'Elec Calc Chloride', 1, consume = 510 },
  { 'drop of Rhodium Sulfate', 33000, 'Crude Rhodium Metal Dust', 33 },
  { 'drop of Rhodium Sulfate Solution', 33000, 'Crude Rhodium Metal Dust', 33 },
  { 'drop of Palladium Enriched Ammonia', 18000, 'Tiny Pile of Reprecipitated Palladium Dust', 36 },
  { 'drop of Acidic Iridium Solution', 32000, 'Iridium Dust', 32, if_nhcl = true },
  { 'drop of Platinum Concentrate', 72000, 'Platinum Dust', 8, if_nhcl = true },
  { 'drop of Platinum Concentrate', 18000, 'Platinum Dust', 2, if_nhcl = true },
  { 'Scheelite Dust', 64, 'Tungstic Acid Dust', 49, if_hcl = true },
  { 'Ruthenium Tetroxide Dust', 16, 'Ruthenium Dust', 16, if_hcl = true },
  { 'Sodium Ruthenate Dust', 18, 'drop of Ruthenium Tetroxide Solution', 27000 },
  { 'Iridium Dioxide Dust', 32, 'Iridium Dust', 32, if_nhcl = true, if_hcl = true },
  { 'Iridium Chloride Dust', 32, 'Iridium Dust', 32, if_nhcl = true },
  { 'Rhodium Salt Dust', 30, 'Rhodium Nitrate Dust', 6 },
}

-- Each rule is a sequence of steps, executed until false or error
-- A step can be:
--   {'>', name, level }, pass if name higher than level
--   {'<', name, level }, pass if name lower than level
--   {'do', name, qty, cpu }, pass if successfully queue craft of name at qty
--   {'do-stock', check_name, target, craft_name, multiplier, max, cpu },
--     pass if successfully queue craft of craft_name at MIN(multiplier * (target-CUR), max)
--   {'mark', name, qty }, modify cached count of name by qty

local if_hcl = { '>', 'drop of Hydrochloric Acid', 63000 }
local if_nhcl = { '>', 'drop of Ammonium Chloride', 31000 }

self.rules = {
  {
    { '<', 'drop of Hydrogen Gas', 2000000 },
    { '>', 'drop of 1,2-Dimethylbenzen', 128000 },
    { 'do', 'Elec 1,2-Dimethylbenzen', 1, 'AutoCPU3' },
    { 'mark', 'drop of 1,2-Dimethylbenzen', -8000 },
    { 'mark', 'drop of Hydrogen Gas', 80000 },
  },
  {
    { '<', 'Aluminium Ingot', 2000 },
    { '<', 'Raw Aluminium', 128 },
    { 'do-stock', 'Aluminium Ingot', 2128, 'Raw Aluminium', 1, 128, 'AutoCPU2' },
  },
}

self.invalidRules = {}

for _, r in ipairs(self.items_to_stock) do
  local name, qty, target = r[1], r[2], (r.target or r[2])
  local craft_max, to_craft = (r.craft_max or target), (r.to_craft or name)
  local cpu = r.cpu or 'AutoCPU'
  table.insert(self.rules, {
    { '<', name, qty },
    { 'do-stock', name, target, to_craft, 1, craft_max, cpu },
  })
end

for _, r in ipairs(self.items_to_proc) do
  local check_name, qty, craft_name, craft_qty = r[1], r[2], r[3], r[4]
  local consume = r.consume or qty
  local rule = {
    { '>', check_name, qty },
    { 'do', craft_name, craft_qty, 'AutoCPU2' },
    { 'mark', check_name, -consume },
  }
  if r.if_hcl then table.insert(rule, 1, if_hcl) end
  if r.if_nhcl then table.insert(rule, 1, if_nhcl) end
  table.insert(self.rules, rule)
end

local function validateStep(s)

end

for _, r in ipairs(self.rules) do
  for _, s in ipairs(r) do
    validateStep(s)
  end
end

self.items_to_track = {
  'Iron Ingot',
  'Steel Ingot',
  'Titanium Ingot',
  'Tungstensteel Ingot',
  'Tungsten Ingot',
  'Copper Ingot',
  'Platinum Ingot',
  'Platinum Dust',
  'Lapis Dust',
  'Thorium Dust',
  'Uranium 238 Dust',
  'Uranium 235 Dust',
  'Stainless Steel Ingot',
  'Tin Ingot',
  'Gold Ingot',
  'Redstone',
  'Empty Cell',
  'Sodium Dust',
  'Salt',
  'Sulfur Dust',
  'drop of Hydrogen Gas',
  'drop of Nitrogen Gas',
  'drop of Oxygen Gas',
  'drop of Fluorine',
  'drop of Chlorine',
  'drop of Mercury',
}

function self:preTick()
  self.me = cmps.proxy(cmps.get("c4b5232a"))
  self.lookups = 0
end

function self:getCachedItem(label, atLeastTick)
  if not atLeastTick then atLeastTick = Shared.tick - self.lookups - 5 end
  local item = self.itemcache[label]
  if not item or item.tick < atLeastTick then
    self.lookups = self.lookups + 1
    local match = self.me.getItemsInNetwork({ label = label })[1]
    item = {
      label = label,
      name = match and match.name,
      damage = match and match.damage,
      size = match and match.size or 0,
      tick = Shared.tick
    }
    self.itemcache[label] = item
  end
  return item
end

function self:getCachedItemCount(label, atLeastTick)
  return self:getCachedItem(label, atLeastTick).size
end

function self:getCachedItemProjection(label, atLeastTick)
  local item = self:getCachedItem(label, atLeastTick)
  return math.max(item.size + (self.projections[label] or 0), 0)
end

function self:modifyCachedItemCount(label, delta)
  local item = self:getCachedItem(label, 0)
  item.size = math.max(0, item.size + delta)
end

function self:modifyCachedItemProjection(label, delta)
  self.projections[label] = delta + (self.projections[label] or 0)
end

function self:onTick()
  local items = {}
  self.data.items = items
  local crafting = defaultobj(self.data, 'crafting')
  local all_cpus = self.me.getCpus()
  local function slice_items(items)
    local ret = { __serialize_as_array = true }
    for i, w in ipairs(items) do
      if w and w.size > 0 then
        ret[i] = {
          label = w.label,
          size = w.size,
          name = w.name,
          damage = w.damage,
        }
      end
    end
    return ret
  end

  self.projections = {}
  local idle = {}
  for k, v in ipairs(all_cpus) do
    if v.name and not v.busy then idle[v.name] = true end
    local finalOutputs = { v.cpu.finalOutput() }
    for _, o in ipairs(finalOutputs) do
      if o.label then self:modifyCachedItemProjection(o.label, o.size) end
    end
    crafting[k] = {
      name = v.name,
      finalOutput = slice_items(finalOutputs)[1],
      isBusy = v.busy,
      activeItems = slice_items(v.cpu.activeItems()),
      pendingItems = slice_items(v.cpu.pendingItems()),
      storedItems = slice_items(v.cpu.storedItems()),
    }
    if crafting[k].activeItems[1] then
      if crafting[k].activeItems[1].label == 'Elec Calc Chloride' then
        cmps.proxy(cmps.get('07c47fbe')).transferItem(sides.down, sides.down, 1, 1, 9)
      elseif crafting[k].activeItems[1].label == 'Elec 1,2-Dimethylbenzen' then
        cmps.proxy(cmps.get('07c47fbe')).transferItem(sides.down, sides.down, 1, 2, 9)
      elseif crafting[k].activeItems[1].label == 'Elec Biotite' then
        cmps.proxy(cmps.get('07c47fbe')).transferItem(sides.down, sides.down, 1, 3, 9)
      end
    end
  end

  local curCPU = 'AutoCPU'
  local function try_request2(craft_num, craft_name, msg)
    if not msg then
      msg = "Crafting " .. tostring(craft_num) .. 'x ' .. craft_name
    end
    if not idle[curCPU] then
      Shared.modules.sysmsg.sendInfo("(Would " .. curCPU .. ") " .. msg)
      return false
    else
      local craft = self.me.getCraftables({ label = craft_name })[1]
      if craft then
        local a = craft.request(craft_num, true, curCPU)
        if a.isCanceled() then
          Shared.modules.sysmsg.sendInfo("(Failed " .. curCPU .. ") " .. msg)
          return false
        else
          Shared.modules.sysmsg.sendConsole(msg)
          idle[curCPU] = nil
          return true
        end
      end
    end
  end

  local function try_request_simple(craft_num, craft_name, msg)
    if try_request2(craft_num, craft_name, msg) then
      self:modifyCachedItemCount(craft_name, craft_num)
    end
  end

  self.proc_idx = (self.proc_idx or 1) % #self.rules
  for i, _ in ipairs(self.rules) do
    local rule = self.rules[((self.proc_idx + i) % #self.rules) + 1]
    for _, step in ipairs(rule) do
      if step[1] == '>' then
        if self:getCachedItemCount(step[2]) <= step[3] then goto end_rule end
      elseif step[1] == '<' then
        if self:getCachedItemProjection(step[2]) >= step[3] then goto end_rule end
      elseif step[1] == 'do' then
        curCPU = step[4]
        if not try_request_simple(step[3], step[2]) then goto end_rule end
      elseif step[1] == 'do-stock' then
        local check_name, target, craft_name, multiplier, max = step[2], step[3], step[4], step[5], step[6]
        local missing = target - self:getCachedItemCount(check_name)
        local qty = math.ceil(math.min(missing * multiplier, max))
        if qty <= 0 then goto end_rule end
        curCPU = step[7]
        if not try_request_simple(qty, craft_name) then goto end_rule end
      elseif step[1] == 'mark' then
        if step[3] < 0 then
          self:modifyCachedItemCount(step[2], step[3])
        else
          self:modifyCachedItemProjection(step[2], step[3])
        end
      end
    end
    ::end_rule::
  end

  for _, v in ipairs(self.items_to_track) do
    items[v] = self:getCachedItemCount(v)
  end
  for i, v in ipairs(self.me.getEssentiaInNetwork()) do
    items[v.label] = v.amount
  end

  -- for i, n in pairs(items) do
  --   Shared.modules.charts:track('me_' .. i, n)
  -- end
end

return self