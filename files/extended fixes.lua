--These are bugfixes that will instead be moved to my extended bugfixes mod and will not be a part of my core critical fixes.
--these will not remain in this mod, ill remove this file when i make my extended fixes projectile- just cant be bothered rn
---@diagnostic disable


--[[ VOMIT INHERITANCE FIX ]]
-- Vomit material was intended to inherit properties from Green Slime, this fails however because it is designated as a <CellData/> rather than <CellDataChild/>.

for xml in nxml.edit_file("data/materials.xml") do
	for elem in xml:each_of("CellData") do
		if elem.attr._parent then elem.name = "CellDataChild" end
	end
end




--[[ FIX DROPPER BOLT CHARGES ]]
-- Dropper Bolt spell starts with 25/35 charges. This is because of some nonsense where it's custom card entity is shared with Firebolt and Odd Firebolt.

-- I actually don't fully understand this bug that much since it seems reliant on a bizarre system I don't fully understand and don't think I need to.
-- Removing the overrides from the first <Base/> component appears to fix this, I don't know why they're there or if they do anything helpful?
-- It seems to work, if something breaks go pester me and I'll go fix it.
for xml in nxml.edit_file("data/entities/misc/custom_cards/grenade.xml") do
	local base = xml:first_of("Base")
	if base then
		base:clear_children()
	end
end




--[[ FIX MIST PROJECTILES ]]
-- The Mist spells do not have the `projectile` tag because `tags` is defined on the entity twice. This causes them to not be properly identified by things like StX or shields.

local mists = {
	"data/entities/projectiles/deck/mist_alcohol.xml",
	"data/entities/projectiles/deck/mist_blood.xml",
	"data/entities/projectiles/deck/mist_radioactive.xml",
	"data/entities/projectiles/deck/mist_slime.xml",
}

for _,mist in ipairs(mists) do
	modifile(mist, [[tags=""]], [[]]) --Remove redundant tags definition.
end --shelved, may instead have all spell related fixes in their own mod