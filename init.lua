local nxml = dofile_once("mods/fixnoita/nxml/nxml.lua") ---@type nxml

local function escape(str) return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1") end

local function modifile(file, target, sub)
	ModTextFileSetContent(file, ModTextFileGetContent(file):gsub("\r\n", "\n"):gsub(escape(target), sub))
end

--fix jetpack particles
for xml in nxml.edit_file("data/entities/base_jetpack_nosound.xml") do
	local pecomp = xml:first_of("ParticleEmitterComponent")
	if pecomp and pecomp.attr.y_pos_offset_min == "" then pecomp.attr.y_pos_offset_min = "0" end
end

--fix s2p crash
local s2p = ModTextFileGetContent("data/scripts/projectiles/spells_to_power.lua")
if not s2p:find("ComponentObjectSetValue2") then
	ModTextFileSetContent("data/scripts/projectiles/spells_to_power.lua",
		"local ComponentObjectSetValue = ComponentObjectSetValue2\n\n" .. s2p
	)
end

--fix sungems
for xml in nxml.edit_file("data/entities/animals/boss_centipede/ending/ending_sampo_spot_mountain.xml") do
	xml:add_children({
		nxml.parse_file("mods/fixnoita/files/sungems/sun_check.xml"),
		nxml.parse_file("mods/fixnoita/files/sungems/darksun_check.xml"),
	})
end

modifile("data/scripts/magic/altar_tablet_magic.lua", [[GlobalsGetValue("MISC_SUN_EFFECT") ~= "1"]], [[false]])
modifile("data/scripts/magic/altar_tablet_magic.lua", [[GlobalsGetValue("MISC_DARKSUN_EFFECT") ~= "1"]], [[false]])

AddFlagPersistent("progress_sun")
AddFlagPersistent("progress_darksun")