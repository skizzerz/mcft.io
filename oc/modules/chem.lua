-- vim: set ts=2 sw=2 tw=40 et:
local self = { data = Shared.data.chem }
local cmps = require("component")
local sides = require("sides")

if not self.data then
  self.data = {}
  Shared.data.chem = self.data
end

function Chem_onTick()
  local chemdata = self.data
  local tp = cmps.proxy(cmps.get("73a772fe"))
  local tp2 = cmps.proxy(cmps.get("ce6580c2"))
  local redstone = cmps.proxy(cmps.get("6fe1c3"))
  local tank_no = { ["Oxygen Gas"] = 0, ["Nitrogen Gas"] = 1, ["Chlorine Gas"] = 3, ["Hydrogen Gas"] = 2, ["Water"] = 4 }
  local side_main = sides.north
  local side_me = sides.west
  local side_main2 = sides.south
  local side2_export = sides.west

  if not chemdata.lcr_load then chemdata.lcr_load = 0 end

  local function getUniqueName(label, damage)
    return label .. " D" .. tostring(damage)
  end

  local function getUniqueNameItem(item)
    if item.label then
      if item.label == "Plastic Circuit Board" then
        return getUniqueName(item.label, item.damage)
      else
        return item.label
      end
    else
      return item.name .. " D" .. tostring(item.damage)
    end
  end

  local function isempty(side)
    local inv = tp.getAllStacks(side)
    local n = inv.count()
    for i = 1, n do
      local item = inv[i]
      if item then return false end
    end
    return true
  end

  local inv = {}
  local have_more = {}
  local all_items = tp.getAllStacks(side_main)
  local n = all_items.count()
  local all_me_items = tp.getAllStacks(side_me)
  local m = all_me_items.count()
  local empty_slots = 0
  for i = 1, n do
    local item = all_items[i]
    if item then
      local n = getUniqueNameItem(item)
      local x = item.size
      if inv[n] then
        x = x + inv[n]
      end
      inv[n] = x
    else
      empty_slots = empty_slots + 1
    end
  end
  for i = 1, m do
    local item = all_me_items[i]
    if item then
      local n = getUniqueNameItem(item)
      local x = item.size
      if inv[n] then
        x = x + inv[n]
      end
      inv[n] = x
      if item.size == item.maxSize then
        have_more[n] = 1
      end
    end
  end
  for k, v in ipairs(tp.getFluidInTank(side_me)) do
    local l = v.label
    if l == "Chlorine" then l = "Chlorine Gas" end
    if l then
      inv[l] = v.amount
      if v.amount == v.capacity then
        have_more[l] = 1
      end
    end
  end

  local function transfer(label, qty, side)
    if label:match(" Gas$") then
      if side >= 100 then
        print("FATAL ERROR: COULD NOT TRANSFER FLUID INTO NON-LCR")
        return
      end
      for i = 0, 10 do
        local a, b = tp.transferFluid(side_me, side, qty, tank_no[label])
        qty = qty - b
        if qty == 0 then return end
      end
      print("FATAL ERROR: COULD NOT TRANSFER FLUID")
      return
    end
    for i = n, 1, -1 do
      local item = all_items[i]
      if item then
        if getUniqueNameItem(item) == label then
          local myqty = math.min(item.size, qty)
          if side >= 100 then
            tp2.transferItem(side_main2, side - 100, myqty, i)
          else
            tp.transferItem(side_main, side, myqty, i)
          end
          qty = qty - myqty
          if qty == 0 then
            return
          end
        end
      end
    end
    for i = 1, m do
      local item = all_me_items[i]
      if item then
        if getUniqueNameItem(item) == label then
          local myqty = math.min(item.size, qty)
          if side >= 100 then
            print("FATAL ERROR: COULD NOT TRANSFER ME INTO NON-LCR")
            return
          else
            tp.transferItem(side_me, side, myqty, i)
          end
          qty = qty - myqty
          if qty == 0 then
            return
          end
        end
      end
    end
  end

  local function print_processing(msg)
    if chemdata.executing == nil then
      Shared.modules.sysmsg.sendConsole("processing unknown / manual (" .. msg .. ")")
      return
    else
      Shared.modules.sysmsg.sendConsole("active (" .. msg .. "): " ..
        tostring(chemdata.executing.qty) .. "x " .. tostring(chemdata.executing.name))
      return
    end
  end

  local LCR_occupied = true
  local empty_up = isempty(sides.up)
  local empty_east = isempty(sides.east)
  local empty_south = isempty(sides.south)
  local rs_east = redstone.getInput(sides.east) > 0
  if not empty_up then
    print_processing("up not empty")
  elseif not empty_east then
    print_processing("east not empty")
  elseif not empty_south then
    print_processing("south not empty")
  elseif rs_east then
    print_processing("redstone on")
  else
    LCR_occupied = false
    redstone.setOutput(side_me, 0)
    chemdata.executing = nil
  end

  if LCR_occupied then
    chemdata.lcr_load = chemdata.lcr_load + Shared.data.time.span_ms / 2
  end

  if empty_slots == 0 then
    Shared.modules.sysmsg.sendConsole("no space.")
    return
  end
  if not inv["Empty Cell"] then
    Shared.modules.sysmsg.sendConsole("no Empty Cells.")
    return
  end

  local function count(label) if not inv[label] then return 0 else return inv[label] end end

  local function executeRecipe(recipe, mult)
    if not mult then mult = 1 end
    for i, r in ipairs(recipe) do
      transfer(r[1], r[2] * mult, r[3])
    end
    redstone.setOutput(side_me, 1)
  end

  local PCB2 = "Plastic Circuit Board D32106"
  local PCB1 = "Plastic Circuit Board D32007"

  -- Output, quantity, [input, quantity, side]...
  ---@alias Ingredient {[1]: string, [2]: integer | nil, [3]: integer | nil}
  ---@alias Recipe {[1]: string, [2]: integer, [3]: Ingredient[]}
  ---@type Recipe[]
  local Recipes = {
    -- { "Proc Reprecipitated Platinum Dust", 4, {
    --   { "Reprecipitated Platinum Dust", 4 }, { "Calcium Dust", 1 }
    -- } },
    -- { "Proc Magnesiumchloride Dust", 6, {
    --   { "Magnesiumchloride Dust", 6 }, { "Sodium Dust", 4 }
    -- } },
    -- { "Proc Reprecipitated Palladium Dust", 4, {
    --   { "Reprecipitated Palladium Dust", 4 }, { "Formic Acid Cell", 4 }
    -- } },
    -- { "Proc Palladium Metallic Powder Dust", 1, {
    --   { "Palladium Metallic Powder Dust", 1 }, { "Palladium Enriched Ammonia Cell", 1, sides.up }
    -- } },
    -- { "Proc Purified Chalcopyrite Ore", 20, {
    --   { "Purified Chalcopyrite Ore", 20 }, { "Aqua Regia Cell", 3 }
    -- } },
    -- {"Proc Purified Sphalerite Ore", 1, {
    --   {"Purified Sphalerite Ore", 1}, {"Purified Galena Ore", 3}, {"Sulfuric Acid Cell", 4} }},
    -- {"Proc Indium Concentrate Cell", 8, {
    --   {"Indium Concentrate Cell", 8, sides.up}, {"Aluminium Dust", 4} }},
    --    {"Bio Diesel Cell", ">=", 50, {
    --      {"Bio Diesel Cell", 50, sides.east}, {"Tetranitromethane Cell", 2, sides.up} }},
    -- produces potassium, which gums up the output
    -- {"Proc Rhodium Sulfate Cell", 11, {
    --   {"Rhodium Sulfate Cell", 11, sides.up}, {"Water Cell", 10} }},
    -- { "Proc Rhodium Sulfate Solution Cell", 1, {
    --   { "Rhodium Sulfate Solution Cell", 1 }, { "Zinc Dust", 1 }
    -- } },
    -- { "Proc Rhodium Salt Solution Cell", 1, {
    --   { "Rhodium Salt Solution Cell", 1 }, { "Sodium Nitrate Dust", 5 }
    -- } },
    -- { "Proc Zinc Sulfate Dust", 6, {
    --   { "Zinc Sulfate Dust", 6 }, { "Hydrogen Cell", 2 }
    -- } },
    -- { "Proc Rutile Dust", 1, {
    --   { "Chlorine Cell", 4 }, { "Carbon Dust", 2 }, { "Rutile Dust", 1 }
    -- } },
    -- { "Proc Reprecipitated Rhodium Dust", 1, {
    --   { "Reprecipitated Rhodium Dust", 1 }, { "Hydrochloric Acid Cell", 1 }
    -- } },
    -- { "Proc Sodium Ruthenate Dust", 6, {
    --   { "Sodium Ruthenate Dust", 6 }, { "Chlorine Cell", 3 }
    -- } },
    -- { "Proc Platinum Metallic Powder Dust", 1, {
    --   { "Platinum Metallic Powder Dust", 1 }, { "Aqua Regia Cell", 1 }
    -- } },
    -- { "Proc Platinum Concentrate Cell", 10, {
    --   { "Platinum Concentrate Cell", 10 }, { "Ammonium Chloride Cell", 2 }
    -- } },
    -- { "Proc Acidic Iridium Solution Cell", 1, {
    --   { "Acidic Iridium Solution Cell", 1 }, { "Ammonium Chloride Cell", 3 }
    -- } },
    -- { "Proc Iridium Chloride Dust", 1, {
    --   { "Iridium Chloride Dust", 1 }, { "Calcium Dust", 3 }
    -- } },
    -- { "Proc Scheelite Dust", 6, {
    --   { "Scheelite Dust", 6 }, { "Hydrochloric Acid Cell", 2 }
    -- } },
    -- { "Proc Iridium Dioxide Dust", 1, {
    --   { "Iridium Dioxide Dust", 1 }, { "Hydrochloric Acid Cell", 1 }
    -- } },
    -- { "Proc Sodium Tungstate Cell", 1, {
    --   { "Sodium Tungstate Cell", 1 }, { "Calcium Chloride Dust", 3 }
    -- } },
    -- { "Proc Sulfuric Naphtha Cell", 12, {
    --   { "Sulfuric Naphtha Cell", 12, sides.up }, { "Hydrogen Cell", 2 }
    -- } },
    -- { "Proc Sulfuric Heavy Fuel Cell", 8, {
    --   { "Sulfuric Heavy Fuel Cell", 8, sides.up }, { "Hydrogen Cell", 2 }
    -- } },
    -- { "Proc Sulfuric Light Fuel Cell", 12, {
    --   { "Sulfuric Light Fuel Cell", 12, sides.up }, { "Hydrogen Cell", 2 }
    -- } },
    -- { "Proc Enriched-Naquadah Oxide Mixture Dust", 4, {
    --   { "Enriched-Naquadah Oxide Mixture Dust", 4 }, { "Sulfuric Acid Cell", 18 }, { "P-507 Cell", 1, sides.up }
    -- } },

    --    {"Sodium Sulfate Dust", ">=", 14, {
    --      {"Sodium Sulfate Dust", 14, sides.south}, {"Hydrogen Cell", 4, sides.up} }},
    { "Formic Acid Cell", 2, {
      { "Sulfuric Acid Cell", 1 }, { "Sodium Formate Cell", 2, sides.up }
    } },
    { "Sodium Formate Cell", 1, {
      { "Carbon Monoxide Cell", 1, sides.east }, { "Sodium Hydroxide Dust", 3 }
    } },
    { "Molten Epoxid Cell", 6, {
      { "Bisphenol A Cell", 1, sides.up }, { "Epichlorohydrin Cell", 2, sides.east }, { "Sodium Hydroxide Dust", 6 }
    } },
    { "Bisphenol A Cell", 1, {
      { "Phenol Cell", 2 }, { "Hydrochloric Acid Cell", 1 }, { "Acetone Cell", 1, sides.south }
    } },
    -- { "Aqua Regia Cell", 2, {
    --   { "Diluted Sulfuric Acid Cell", 1, sides.north + 100 }, { "Nitric Acid Cell", 1, sides.north + 100 }
    -- } },
    { "P-507 Cell", 1, {
      { "Ethanol Cell", 2, sides.up }, { "Phosphoric Acid Cell", 1 }, { "2-Ethyl-1-Hexanol Cell", 2, sides.south },
      { "Sodium Dust", 2 }
    } },
    { "Epichlorohydrin Cell", 1, {
      { "Glycerol Cell", 1, sides.up }, { "Hydrochloric Acid Cell", 1 }
    } },
    { "Glycerol Cell", 1, {
      { "Fish Oil Cell", 6, sides.up }, { "Methanol Cell", 1, sides.east }, { "Tiny Pile of Sodium Hydroxide Dust", 1 }
    } },
    { "2-Ethyl-1-Hexanol Cell", 1, {
      { "Hydrogen Cell", 8 }, { "Seed Oil Cell", 3, sides.up }
    } },
    { "Phosphoric Acid Cell", 1, {
      { "Water Cell", 6 }, { "Phosphorous Pentoxide Dust", 14 }
    } },
    { "Phosphorous Pentoxide Dust", 14, {
      { "Oxygen Cell", 10 }, { "Phosphorous Dust", 4 }
    } },
    { "More Advanced Circuit Board", 1, {
      { "Iron III Chloride Cell", 1 }, { "Fiber-Reinforced Circuit Board", 1 }, { "Energetic Alloy Foil", 12 }
    } },
    { "Fiber-Reinforced Circuit Board", 2, {
      { "Sulfuric Acid Cell", 1 }, { "Fiber-Reinforced Epoxy Resin Sheet", 2 }, { "Aluminium Foil", 24 }
    } },
    { "Tetranitromethane Cell", 2, {
      { "Ethenone Cell", 1, sides.up }, { "Nitric Acid Cell", 8 }
    } },
    { "Ethenone Cell", 2, {
      { "Sulfuric Acid Cell", 1 }, { "Acetic Acid Cell", 1 }
    } },
    { "Molten Polybenzimidazole Cell", 6, {
      { "Diphenyl Isophtalate Cell", 1 }, { "3,3-Diaminobenzidine Cell", 1 }
    } },
    { "Diphenyl Isophtalate Cell", 1, {
      { "Phenol Cell", 2 }, { "Sulfuric Acid Cell", 1 }, { "Phthalic Acid Cell", 1, sides.south }
    } },
    { "Phthalic Acid Cell", 1, {
      { "Oxygen Cell", 6 }, { "1,2-Dimethylbenzen Cell", 1 }, { "Tiny Pile of Potassium Dichromate Dust", 1 }
    } },
    { "1,2-Dimethylbenzen Cell", 1, {
      { "Benzene Cell", 1 }, { "Methane Cell", 2, sides.up }
    } },
    { "3,3-Diaminobenzidine Cell", 1, {
      { "3,3-Dichlorobenzidine Cell", 1 }, { "Ammonia Cell", 2 }, { "Zinc Dust" }
    } },
    { "3,3-Dichlorobenzidine Cell", 1, {
      { "2-Nitrochlorobenzene Cell", 2 }, { "Tiny Pile of Copper Dust", 1 }
    } },
    { "2-Nitrochlorobenzene Cell", 1, {
      { "Nitration Mixture Cell", 2 }, { "Chlorobenzene Cell", 1 }
    } },
    { "Sodium Nitrate Dust", 5, {
      { "Nitric Acid Cell", 1 }, { "Sodium Dust", 1 }
    } },
    { "Potassium Dichromate Dust", 11, {
      { "Potassium Nitrate Dust", 10 }, { "Chromium Trioxide Dust", 8 }
    } },
    { "Potassium Nitrate Dust", 5, {
      { "Nitric Acid Cell", 1 }, { "Potassium Dust", 1 }
    } },
    { "Polydimethylsiloxane Pulp", 3, {
      { "Water Cell", 1 }, { "Dimethyldichlorosilane Cell", 1 }
    } },
    { "Chromium Trioxide Dust", 4, {
      { "Oxygen Cell", 1 }, { "Chromium Dioxide Dust", 3 }
    } },
    { "Chromium Dioxide Dust", 3, {
      { "Oxygen Cell", 2 }, { "Chrome Dust", 1 }
    } },
    { "Dimethyldichlorosilane Cell", 1, {
      { "Chloromethane Cell", 2 }, { "Raw Silicon Dust", 1 }
    } },
    { "Chlorobenzene Cell", 1, {
      { "Benzene Cell", 1 }, { "Chlorine Cell", 2 }
    } },
    { "Chloromethane Cell", 1, {
      { "Methane Cell", 1 }, { "Chlorine Cell", 2 }
    } },
    { "Tetrafluoroethylene Cell", 1, {
      { "Hydrofluoric Acid Cell", 4 }, { "Chloroform Cell", 2 }
    } },
    { "Methane Cell", 1, {
      { "Hydrogen Cell", 4 }, { "Carbon Dust", 1 }
    } },
    { "Hydrofluoric Acid Cell", 1, {
      { "Hydrogen Cell", 1 }, { "Fluorine Cell", 1 }
    } },
    { PCB2, 4, {
      { "Iron III Chloride Cell", 1 }, { PCB1, 4 }, { "Copper Foil", 24 }
    } },
    { PCB1, 4, {
      { "Sulfuric Acid Cell", 1 }, { "Polyvinyl Chloride Sheet", 2 }, { "Copper Foil", 8 }
    } },
    { "Advanced Circuit Board", 2, {
      { "Iron III Chloride Cell", 1 }, { "Epoxy Circuit Board", 2 }, { "Electrum Foil", 16 }
    } },
    { "Epoxy Circuit Board", 2, {
      { "Sulfuric Acid Cell", 1 }, { "Epoxid Sheet", 2 }, { "Gold Foil", 16 }
    } },
    { "Iron III Chloride Cell", 1, {
      { "Hydrochloric Acid Cell", 3 }, { "Iron Dust", 1 }
    } },
    { "Ammonium Chloride Cell", 1, {
      { "Ammonia Cell", 1 }, { "Hydrochloric Acid Cell", 1 }
    } },
    { "Nitric Acid Cell", 2, {
      { "Nitrogen Dioxide Cell", 3 }, { "Water Cell", 1 }
    } },
    { "Nitrogen Dioxide Cell", 1, {
      { "Nitric Oxide Cell", 1 }, { "Oxygen Cell", 1 }
    } },
    { "Nitric Oxide Cell", 4, {
      { "Ammonia Cell", 4 }, { "Oxygen Cell", 10 }
    } },
    { "Ammonia Cell", 1, {
      { "Hydrogen Cell", 3 }, { "Nitrogen Cell", 1 }
    } },
    { "Hydrochloric Acid Cell", 1, {
      { "Hydrogen Cell", 1 }, { "Chlorine Cell", 1 }
    } },
    { "Potassium Disulfate Dust", 11, {
      { "Oxygen Cell", 7 }, { "Sulfur Dust", 2 }, { "Potassium Dust", 2 }
    } },
    { "Sulfuric Acid Cell", 1, {
      { "Sulfur Trioxide Cell", 1 }, { "Water Cell", 1 }
    } },
    { "Sulfur Trioxide Cell", 1, {
      { "Sulfur Dioxide Cell", 1 }, { "Oxygen Cell", 1 }
    } },
    { "Sulfur Dioxide Cell", 1, {
      { "Hydrogen Sulfide Cell", 1 }, { "Oxygen Cell", 3 }
    } },
    { "Hydrogen Sulfide Cell", 1, {
      { "Sulfur Dust", 1 }, { "Hydrogen Cell", 2 }
    } },
    { "Sodium Hydroxide Dust", 1, {
      { "Sodium Dust", 1 }, { "Water Cell", 1 }
    } },
  }

  -- Check recipes and assign missing sides
  local side_assign = {}
  for _, r in ipairs({
    "Oxygen",
    "Hydrogen",
    "Hydrochloric Acid",
    "Water",
    "Aqua Regia",
    "Iron III Chloride",
    "Sulfuric Acid",
    "Formic Acid",
    "Nitric Acid",
    "Benzene",
    "Methane",
    "Hydrofluoric Acid",
    "Ammonium Chloride",
    "Diphenyl Isophtalate",
    "3,3-Dichlorobenzidine",
    "Nitration Mixture",
    "Phosphoric Acid",
  }) do side_assign[r .. " Cell"] = sides.east end
  for _, r in ipairs({
    "Dimethyldichlorosilane",
    "Chlorobenzene",
    "Chloromethane",
    "Chloroform",
    "Platinum Concentrate",
    "Rhodium Sulfate Solution",
    "Rhodium Salt Solution",
    "Chlorine",
    "Nitrogen",
    "Sulfur Dioxide",
    "Sulfur Trioxide",
    "Hydrogen Sulfide",
    "Nitric Oxide",
    "Nitrogen Dioxide",
    "Sodium Tungstate",
    "Ammonia",
    "Fluorine",
    "Acidic Iridium Solution",
    "3,3-Diaminobenzidine",
    "Phenol",
    "1,2-Dimethylbenzen",
    "2-Nitrochlorobenzene",
    "Acetic Acid",
  }) do side_assign[r .. " Cell"] = sides.up end
  local to_gas = {
    ["Oxygen Cell"] = "Oxygen Gas",
    ["Hydrogen Cell"] = "Hydrogen Gas",
    ["Chlorine Cell"] = "Chlorine Gas",
    ["Nitrogen Cell"] = "Nitrogen Gas"
  }
  for k, v in pairs(to_gas) do
    side_assign[v] = side_assign[k]
  end
  for i, r in ipairs(Recipes) do
    local used_sides = {}
    for j, s in ipairs(r[3]) do
      if not s[2] then s[2] = 1 end
      if to_gas[s[1]] then
        s[1] = to_gas[s[1]]
        s[2] = s[2] * 1000
      end
      if s[1]:match(" Cell") or s[1]:match(" Gas") then
        if not s[3] then
          s[3] = side_assign[s[1]]
        end
        if s[3] and s[3] < 100 then
          if used_sides[s[3]] then
            error("WARNING: RECIPE SIDE CONFLICT IN " .. r[1])
          end
          used_sides[s[3]] = 1
        end
      else
        if not s[3] then s[3] = sides.south end
      end
      if not s[3] then
        error("Unknown side for " .. s[1])
      end
    end
  end

  (function()
    -- basket is virtually initialized to
    -- "negative" inventory
    local basket = {}
    local function addToBasket(n, q)
      if q == 0 then return end
      if basket[n] ~= nil then
        q = q + basket[n]
      else
        q = q - count(n)
      end
      basket[n] = q
    end

    local targetAEItems = {
      { "Tetranitromethane Cell", 8 },
      { "Molten Polybenzimidazole Cell", 32 },
    }
    targetAEItems = (function()
      local ret = {}
      for _, v in ipairs(targetAEItems) do
        ret[v[1]] = v[2]
      end
      return ret
    end)()
    local itemsToAE = {}
    local function addToBasketOrAE(n, q)
      local count = Shared.modules.memon:getCachedItemCount(n)
      itemsToAE[n] = q - count
      addToBasket(n, math.max(0, q - count))
    end

    for k, v in pairs(targetAEItems) do
      addToBasketOrAE(k, v)
    end


    local me_bus = cmps.proxy(cmps.get("7dec127e"))
    local dispense_slot = 1
    local function dispense(item)
      Shared.modules.sysmsg.sendConsole("Dispensing " .. item.label)
      Shared.modules.itemdata:setDBByNameDamage(item.name, item.damage)
      me_bus.setExportConfiguration(sides.south, 1, Shared.modules.itemdata.address, 1)
      me_bus.exportIntoSlot(sides.south, dispense_slot)
      Shared.modules.memon:modifyCachedItemCount(item.label, -math.min(64, item.size))
      dispense_slot = dispense_slot + 1
    end

    for i, v in ipairs(Recipes) do
      if v[1]:match("^Proc ") then
        addToBasket(v[1], math.floor(count(v[1]:sub(6, -1)) / v[2]) * v[2])
      end
    end

    for n, v in pairs(basket) do
      if v > 0 then
        Shared.modules.sysmsg.sendConsole("Want " .. tostring(v) .. "x " .. n:sub(1, 27))
      end
    end

    ---@type {[1]: integer, [2]: unknown}[]
    local plan = {}
    for _, v in ipairs(Recipes) do
      local q = basket[v[1]]
      if q then
        -- take active LCR recipe into consideration
        if chemdata.executing and chemdata.executing.name == v[1] then
          q = q - chemdata.executing.qty
          basket[v[1]] = q
        end
        if q > 0 then
          local me_item = Shared.modules.memon:getCachedItem(v[1])
          local available = me_item.size - (targetAEItems[v[1]] or 0)
          if available > 0 then
            q = q - math.min(q, available)
            basket[v[1]] = q
            dispense(me_item)
          end
        end
        if q > 0 then
          local batches = math.ceil(1.0 * q / v[2])
          for j, w in ipairs(v[3]) do
            if w[1]:match(" Cell$") then
              -- Limit to 64 cells
              batches = math.min(math.floor(64.0 / w[2]), batches)
            end
          end
          addToBasket(v[1], -batches * v[2])
          for _, w in ipairs(v[3]) do
            addToBasket(w[1], w[2] * batches)
          end
          plan[#plan + 1] = { batches, v }
        end
      end
    end
    for i = #plan, 1, -1 do
      local v = plan[i]
      local maxbatch = v[1]
      for j, w in ipairs(v[2][3]) do
        -- Limit based on ingredient availability
        local ibatches = math.floor(count(w[1]) * 1.0 / w[2])
        maxbatch = math.min(ibatches, maxbatch)
        if w[1]:match(" Cell$") then
          -- Limit to 64 cells
          ibatches = math.floor(64.0 / w[2])
          maxbatch = math.min(ibatches, maxbatch)
        end
      end
      Shared.modules.sysmsg.sendInfo(tostring(maxbatch) .. 'x' .. tostring(v[2][2]) .. "x " .. v[2][1]:sub(1, 33))
      if maxbatch > 0 and not LCR_occupied then
        executeRecipe(v[2][3], maxbatch)
        chemdata.executing = { qty = maxbatch * v[2][2], name = v[2][1] };
        Shared.modules.sysmsg.sendConsole("Execute " ..
          tostring(chemdata.executing.qty) .. "x " .. tostring(chemdata.executing.name))
        LCR_occupied = true
      end
    end
    for i, v in pairs(basket) do
      if v > 0 and not have_more[i] then
        Shared.modules.sysmsg.sendConsole("Missing " .. tostring(v) .. 'x ' .. i)
        local item = Shared.modules.memon:getCachedItem(i)
        if item.size > 0 then
          dispense(item)
        end
      end
    end
    local all_items = tp.getAllStacks(side_main)
    local n = all_items.count()
    for i = 1, n do
      local item = all_items[i]
      if item then
        local n = getUniqueNameItem(item)
        if not basket[n] then
          tp2.transferItem(side_main2, side2_export, item.size, i)
          Shared.modules.memon:modifyCachedItemCount(n, item.size)
        elseif itemsToAE[n] and itemsToAE[n] > 0 then
          local to_export = math.min(itemsToAE[n], item.size)
          itemsToAE[n] = itemsToAE[n] - to_export
          tp2.transferItem(side_main2, side2_export, to_export, i)
          Shared.modules.memon:modifyCachedItemCount(n, to_export)
        end
      end
    end
    if LCR_occupied then
      chemdata.lcr_load = chemdata.lcr_load + Shared.data.time.span_ms / 2
    end
    Shared.modules.charts:track("chem_lcr_load", self.data.lcr_load)
  end)()
end

return self
