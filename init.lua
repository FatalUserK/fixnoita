local nxml = dofile_once("mods/fixnoita/nxml/nxml.lua") ---@type nxml

local function escape(str) return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1") end

local function modifile(file, target, sub)
	ModTextFileSetContent(file, ModTextFileGetContent(file):gsub("\r\n", "\n"):gsub(escape(target), sub))
end

--- [Random Access Bullshit] (RAB), a thing Noita likes to do where when an invalid value is encountered, it uses a random value from memory.
--- Name decided by a friend of mine whom i paraphrased the issue to, lmk if you have a better/more accurate name.

--- Explanation from Nathansnail on Noitacord: https://discord.com/channels/453998283174576133/1445918844265697435
--[[The issue is CAnyContainer, they do a CAnyContainerCast which in the case that the type is wrong (it always is for xml because its a string) will just
use std::stringstreams operator >> on a T & (technically a const T & which they illegally cast the const away from but whatever), operator >> will do
nothing if the stream doesn't contain a valid string representation of the value of that type, so it doesn't set the return value.
Primitive types in c++ by default aren't initialised, so it just returns whatever happened to be on the stack where the return value was supposed to be.]]



--<ParticleEmitterComponent:y_pos_offset_min/> is "" for these entities, this results in RAB causing the particle trail's length to be malformed
local jetpack_targets = {
	"data/entities/base_jetpack_nosound.xml",
	"data/entities/animals/assassin.xml",
	"data/entities/animals/flamer.xml",
	"data/entities/animals/icer.xml",
	"data/entities/animals/necrobot_super.xml",
	"data/entities/animals/necrobot.xml",
	"data/entities/animals/spearbot.xml",
	"data/entities/misc/effect_farts.xml",
	"data/entities/misc/effect_rainbow_farts.xml",
	"data/entities/misc/player_drone_clone.xml",
	"data/scripts/streaming_integration/entities/effect_player_gas.xml",
}

for _,target in ipairs(jetpack_targets) do
	for xml in nxml.edit_file(target) do
		local pecomp = xml:first_of("ParticleEmitterComponent")
		if pecomp and pecomp.attr.y_pos_offset_min == "" then pecomp.attr.y_pos_offset_min = ".5" end --.5 looks nicer than 0 imo
	end
end


--fixes invalid values resulting in RAB explosion radius
local s2p = ModTextFileGetContent("data/scripts/projectiles/spells_to_power.lua")
if not s2p:find("ComponentObjectSetValue2") then
	ModTextFileSetContent("data/scripts/projectiles/spells_to_power.lua",
		"local ComponentObjectSetValue = ComponentObjectSetValue2\n\n" .. s2p
	)
end


--changes mountain altar to do a check for the sungem materials in case the entity attached was destroyed
for xml in nxml.edit_file("data/entities/animals/boss_centipede/ending/ending_sampo_spot_mountain.xml") do
	xml:add_children({
		nxml.parse_file("mods/fixnoita/files/sungems/sun_check.xml"),
		nxml.parse_file("mods/fixnoita/files/sungems/darksun_check.xml"),
	})
end

modifile("data/scripts/magic/altar_tablet_magic.lua", [[GlobalsGetValue("MISC_SUN_EFFECT") ~= "1"]], [[false]])
modifile("data/scripts/magic/altar_tablet_magic.lua", [[GlobalsGetValue("MISC_DARKSUN_EFFECT") ~= "1"]], [[false]])


--translations: fixes kills to mana perk description being a flat-out lie, and adds translations for empty death messages
local compatible_languages = {
	"",
}
if compatible_languages[GameTextGetTranslatedOrNot("")] or true then
	ModTextFileSetContent("data/translations/common.csv",
		(ModTextFileGetContent("data/translations/common.csv") .. "\n" .. ModTextFileGetContent("mods/fixnoita/")):gsub("\r",""):gsub("\n\n","\n")
	)
end

--perkdesc_mana_from_kills,"You gain a short-lived boost to your mana regeneration when an enemy dies.",,,,,,,,,,,,,
--animal_arrowtrap_left,Arrow trap,,,,,,,,,,,,,
--animal_arrowtrap_right,Arrow trap,,,,,,,,,,,,,
--animal_firetrap_left,Fire trap,,,,,,,,,,,,,
--animal_firetrap_right,Fire trap,,,,,,,,,,,,,
--animal_crystal_red,crystal,кристалл,cristal,cristal,Kristall,cristal,cristallo,kryształ,晶体,クリスタル,수정,,,,,,,,,,,,,
--animal_crystal_pink,crystal,кристалл,cristal,cristal,Kristall,cristal,cristallo,kryształ,晶体,クリスタル,수정,,,,,,,,,,,,,
--animal_crystal_green,crystal,кристалл,cristal,cristal,Kristall,cristal,cristallo,kryształ,晶体,クリスタル,수정,,,,,,,,,,,,,
--animal_physics_die,Chaos die,Кубик случая,Dado do caos,Dado caótico,Chaoswürfel,Dé chaotique,Dado del caos,Kość chaosu,混沌骰子,カオスのサイコロ,혼돈 주사위,,,,,,,,,,,,,