-- vim: set ts=2 sw=2 tw=40 et:
local cmps = require('component')
local self = {
    address = cmps.get('b950548f'),
    items = {
        { label = 'Sodium Dust', name = 'gregtech:gt.metaitem.01', damage = 2017 },
        { label = 'Sulfur Dust', name = 'gregtech:gt.metaitem.01', damage = 2022 },
        { label = 'Magnesiumchloride Dust', name = 'gregtech:gt.metaitem.01', damage = 2377 },
        { label = 'Reprecipitated Platinum Dust', name = 'bartworks:gt.bwMetaGenerateddust', damage = 51 },
    },
    byLabel = {},
}

for k, v in ipairs(self.items) do
    v.index = k
    self.byLabel[v.label] = v
end

function self:setDBByLabel(label, slot)
    if not slot then slot = 1 end
    local db = cmps.proxy(self.address)
    local item = self.byLabel[label]
    if not item then error('No item with label: ' .. label) end
    db.set(slot, item.name, item.damage)
end

function self:setDBByNameDamage(name, damage, slot)
    if not slot then slot = 1 end
    local db = cmps.proxy(self.address)
    db.set(slot, name, damage)
end

return self
