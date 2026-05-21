local nxml = dofile_once("mods/fixnoita/nxml/nxml.lua") ---@type nxml

local function escape(str) return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1") end

local function modifile(file, target, sub)
	ModTextFileSetContent(file, ModTextFileGetContent(file):gsub("\r\n", "\n"):gsub(escape(target), sub))
end

--- [Random Access Bullshit] (RAB Glitch), a thing Noita likes to do where when an invalid value is encountered, it uses a random value from memory.
--- Name decided by me until a better name is suggested. Proposed alternatives thus far:
--- Illegal Anycontainer Unboxing
--- Illegal CAnyContainerCast Unboxing
--- Uninitialized Stack Address
--- Hämis Glitch
--- Unitialized Memory Address

--- Explanation from Nathansnail on Noitacord: https://discord.com/channels/453998283174576133/1445918844265697435
--[[The issue is CAnyContainer, they do a CAnyContainerCast which in the case that the type is wrong (it always is for xml because its a string) will just
use std::stringstreams operator >> on a T & (technically a const T & which they illegally cast the const away from but whatever), operator >> will do
nothing if the stream doesn't contain a valid string representation of the value of that type, so it doesn't set the return value.
Primitive types in c++ by default aren't initialised, so it just returns whatever happened to be on the stack where the return value was supposed to be.]]




--[[ JETPACK LENGTH FIX ]]
--<ParticleEmitterComponent::y_pos_offset_min/> is "" for these entities, this results in RAB causing the particle trail's height to be malformed.

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
		if pecomp and pecomp.attr.y_pos_offset_min == "" then pecomp.attr.y_pos_offset_min = ".5" end
		--0.5 looks nicer than 0 imo, we don't know what value Nolla would have written here so it is somewhat up to interpretation.
	end
end




-- [[ S2P CRASH FIX ]]
-- Fixes invalid values resulting in RAB malforming explosion radius. These malformed explosions can in semi-rare cases be large enough to instantly crash your game.

local s2p = ModTextFileGetContent("data/scripts/projectiles/spells_to_power.lua")
if not s2p:find("ComponentObjectSetValue2") then
	ModTextFileSetContent("data/scripts/projectiles/spells_to_power.lua",
		"local ComponentObjectSetValue = ComponentObjectSetValue2\n\n" .. s2p
	)
end




--[[ SUNGEM ALTAR FIX ]]

-- Implements a custom sungem check that also checks the materials in case the entity attached was destroyed.
for xml in nxml.edit_file("data/entities/animals/boss_centipede/ending/ending_sampo_spot_mountain.xml") do
	xml:add_children({
		nxml.parse_file("mods/fixnoita/files/sungems/sun_check.xml"),
		nxml.parse_file("mods/fixnoita/files/sungems/darksun_check.xml"),
	})
end

-- Disables the vanilla checks since we're reimplementing them, and doing both could potentially cause duplicate outcomes (instant supernova).
modifile("data/scripts/magic/altar_tablet_magic.lua", [[GlobalsGetValue("MISC_SUN_EFFECT") ~= "1"]], [[false]])
modifile("data/scripts/magic/altar_tablet_magic.lua", [[GlobalsGetValue("MISC_DARKSUN_EFFECT") ~= "1"]], [[false]])




--[[ TRANSLATION FIXES ]]
--There are a few issues with translations, the main offenders being missing names for death-messages and Kills To Mana's description being outdated

local translation_overrides = {
	{-- Perk description is an outright lie, likely outdated.
		target = [["Every time an enemy near you dies, you release mana-recharging liquid."]],
		new = [["You gain a short-lived boost to your mana regeneration when an enemy dies."]]
	}, --Perk actually gives you 150f of MANA_REGENERATION when an enemy that has been within 240p of you dies.
}

local translations = ModTextFileGetContent("data/translations/common.csv")
translations = translations .. "\n" .. ModTextFileGetContent("mods/fixnoita/files/missing_translations.csv") .. "\n"
translations = translations:gsub("\r", ""):gsub("\n\n+", "\n")
for _,value in ipairs(translation_overrides) do
	translations = translations:gsub(escape(value.target), value.new)
end
ModTextFileSetContent("data/translations/common.csv", translations)




--[[ VOMIT SLIME FIX ]]
--Vomit material was intended to inherit properties from Green Slime, this fails however because it is designated as a <CellData/> rather than <CellDataChild/>

for xml in nxml.edit_file("data/materials.xml") do
	for elem in xml:each_of("CellData") do
		if elem.attr.name == "vomit" then elem.name = "CellDataChild" end
	end
end