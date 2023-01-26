-- vim: set ts=2 sw=2 tw=40 et:
-- After editing this file, press 'r' in the console to reload

-- <locations>
local wash = "washer"
local macerator = "macerator"
local centrifuge = "centrifuge"
local sifting = "sifting"
local thermal = "thermal"
local mercury = "mercury"
-- </locations>

local toMWMC = {
  "Pyrite Ore",
  "Shadow Metal Ore",
  "Magnesite Ore",
  "Cassiterite Sand",
  "Ardite Ore",
  "Tricalcium Phosphate Ore",
  "Roasted Iron Ore",
  "Copper Ore",
  "Lazurite Ore",
  "Calcite Ore",
  "Salt Ore",
  "Rock Salt Ore",
  "Cassiterite Ore",
  "Tin Ore",
  "Iron Ore",
  "Brown Limonite Ore",
  "Yellow Limonite Ore",
  "Vanadium Magnetite Ore",
  "Stibnite Ore",
  "Mica Ore",
  "Aluminium Ore",
  "Barite Ore",
  "Ilmenite Ore",
  "Alunite Ore",
  "Gold Ore",
  "Redstone Ore",
  "Glauconite Sand",
  "Granitic Mineral Sand",
  "Garnet Sand",
  "Pyrope Ore",
  "Kyanite Ore",
  "Kaolinite",
  "Realgar Ore",
  "Glauconite Ore",
  "Neodymium Ore",
  "Bastnasite Ore",
  "Coal Ore",
  "Pyrite Ore",
  "Desh Ore",
  "Tungstate Ore",
  "Scheelite Ore",
  "Chromite Ore",
  "Mica Ore",
  "Magnetite Ore",
  "Fluor-Buergerite Ore",
  "Olenite Ore",
  "Chromo-Alumino-Povondraite Ore",
  "Vanadio-Oxy-Dravite Ore",
  "Hedenbergite Ore",
  "Wittichenite Ore",
  "Ferberite Ore",
  "Arsenopyrite Ore",
  "Loellingite Ore",
  "Red Fuchsite Ore",
  "Naquadah Ore",
  "Samarium Ore",
  "Rubracium Ore",
  "Florencite Ore",
}

local toMW = {
  "Galena Ore",
  "Tetrahedrite Ore",
  "Lepidolite Ore",
  "Chalcopyrite Ore",
  "Uranium 238 Ore",
  "Bornite Ore",
  "Djurleite Ore",
}

local toMWS = {
  "Ilmenite Ore",
  "Lapis Ore",
  "Jasper Ore",
  "Olivine Ore",
  "Certus Quartz Ore",
  "Nether Quartz Ore",
}

local toMMC = {
  "Cinnabar Ore",
  "Fullers Earth",
  "Ruby Ore",
  "Cryolite Ore",
}

local toMMC_M = {
  "Sulfur Ore",
  "Silver Ore",
  "Titanium Ore",
  "Lead Ore",
  "Graphite Ore",
  "Soapstone Ore",
  "Thorium Ore",
  "Saltpeter Ore",
  "Malachite Ore",
  "Fayalite Ore",
  "Bismuthinite Ore",
  "Bismutite Ore",
  "Roquesite Ore",
  "Green Fuchsite Ore",
  "Red Zircon Ore",
  "Mytryl Ore",
}

local toMWTM = {
  "Bauxite Ore",
  "Apatite Ore",
  "Pyrochlore Ore",
  "Electrotine Ore",
  "Pollucite Ore",
  "Tantalite Ore",
  "Monazite",
  "Orange Descloizite Ore",
  "Red Descloizite Ore",
  "Pyrochlore Ore",
  "Pyrolusite Ore",
}
-- Mercury Bath
local toMBMC = {
  "Nickel Ore",
}
local toMacerate = {
  "Aer Infused Stone Ore",
  "Ignis Infused Stone Ore",
  "Aqua Infused Stone Ore",
  "Ordo Infused Stone Ore",
  "Terra Infused Stone Ore",
  "Perditio Infused Stone Ore",
}
local toWash = {
  "Crushed Aer Crystals",
  "Crushed Ignis Crystals",
  "Crushed Aqua Crystals",
  "Crushed Ordo Crystals",
  "Crushed Terra Crystals",
  "Crushed Perditio Crystals",
}
local toMercury = {
}
local toSift = {
  "Purified Aer Crystals",
  "Purified Ignis Crystals",
  "Purified Aqua Crystals",
  "Purified Ordo Crystals",
  "Purified Terra Crystals",
  "Purified Perditio Crystals",
  "Platinum Salt Dust",
  "Palladium Salt Dust",
}
-- Note: function toOreName(label: string): string
-- this function transforms ores into a "unique" name, different than their dust

local function toOreName(label)
  if label:match(" Ore$") then return label end
  return label .. " Ore"
end

local function toCrushedName(label)
  if label:match(" Ore$") then return "Crushed "..label end
  return "Ground "..label
end
local function toPurifiedName(label)
  return "Purified "..label
end

local mapping = {}
for k,v in ipairs(toMWTM) do
  mapping[toOreName(v)] = macerator
  mapping[toCrushedName(v)] = wash
  mapping[toPurifiedName(v)] = thermal
end
for k,v in ipairs(toMWMC) do
  mapping[toOreName(v)] = macerator
  mapping[toCrushedName(v)] = wash
  mapping[toPurifiedName(v)] = macerator
end
for k,v in ipairs(toMMC) do
  mapping[toOreName(v)] = macerator
  mapping[toCrushedName(v)] = macerator
end
for k,v in ipairs(toMMC_M) do
  mapping[toOreName(v)] = macerator
  mapping[toCrushedName(v)] = macerator
  mapping[toPurifiedName(v)] = macerator
end
for k,v in ipairs(toMBMC) do
  mapping[toOreName(v)] = macerator
  mapping[toCrushedName(v)] = mercury
  mapping[toPurifiedName(v)] = macerator
end
for k,v in ipairs(toMW) do
  mapping[toOreName(v)] = macerator
  mapping[toCrushedName(v)] = wash
end
for k,v in ipairs(toMWS) do
  mapping[toOreName(v)] = macerator
  mapping[toCrushedName(v)] = wash
  mapping[toPurifiedName(v)] = sifting
end
for k,v in ipairs(toMacerate) do
  mapping[v] = macerator
end
for k,v in ipairs(toWash) do
  mapping[v] = wash
end
for k,v in ipairs(toSift) do
  mapping[v] = sifting
end
for k,v in ipairs(toMercury) do
  mapping[v] = mercury
end

return mapping