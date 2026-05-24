---Despite my confidence in the name of this mod, I do only what I can, and fix only what I believe is right.
---Nolla may have known of some of these, some of these can be interpreted as intentional design, you may think it arrogant to consider my mod "Fixing" Noita.
---Unfortunately, I cannot lie, and my perspective is that this mod fixes things I view as problems in the base game.
---I fix what I think it broken according to my own standards according to a mix of what I think improves the experience of the game and what I believe Nolla indended.
---I can only do my best.

---With that established, I have done my best to annotate the mod to help people reading the code understand the bugs better, and understand how I fix them.
---Whether you are here for something specific, or just browsing, I do wish you an enjoyable and educational experience.


-- NXML is a very helpful Noita library maintained and largely written by https://github.com/NathanSnail used to parse Noita's custom XML format.
local nxml = dofile_once("mods/fixnoita/nxml/nxml.lua") ---@type nxml

-- de-patterning function for dealing with string.gsub() and other pattern-utilising Lua functions.
local function escape(str) return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1") end

-- Convenient function to simplify modifying files, gsub \r\n to \n to edit multiple lines at a time.
local function modifile(file, target, sub)
	ModTextFileSetContent(file, ModTextFileGetContent(file):gsub("\r\n", "\n"):gsub(escape(target), sub))
end



--- [Random Access Bullshit] (RAB Glitch), a thing Noita likes to do where when an invalid value is encountered, it uses a random value from memory.
--- Name decided by me until a better name is suggested. Proposed alternatives thus far:
--- 	Illegal Anycontainer Unboxing
--- 	Illegal CAnyContainerCast Unboxing
--- 	Uninitialized Stack Address
--- 	Hämis Glitch
--- 	Unitialized Memory Address
--- Unfortunately, none of these roll off the tonge as easily as RAB Glitch, nor are they as funny.
--- I will edit this if a new standardized name becomes more popular, or if I like a specific name better.
---
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
--There are a few issues with translations, the main offenders being missing translations for death-messages and Kills To Mana's description being outdated.

--Note that for death messages, this specifically targets "incorrect translations", ie ones that either don't have a string, or point to the wrong one.
--Not to be confused with the bug that provides no translation key at all (both show up in-game as an empty deaht message, so they are easy to confuse).
--The fix for no death message being generated at all can be found below at [[ EMPTY DEATH MESSAGES ]]

local translation_overrides = {
	--KILLS TO MANA DESCRIPTION: "perkdesc_mana_from_kills"
	--The perk's description is an outright lie, likely outdated.
	--Perk actually gives you 150f of MANA_REGENERATION when an enemy that has been within 240p of you dies.
	{ -- en
		target = [["Every time an enemy near you dies, you release mana-recharging liquid."]],
		new = [["You gain a short-lived boost to your mana regeneration when an enemy dies."]]
	},
	{ -- fr-fr
		target = [["Chaque fois qu'un ennemi à proximité meurt, vous libérez un liquide rechargeant le mana."]],
		new = [[Gagne une régéneration de mana accrue pour une courte durée lorsqu'un ennemi meurt.]]
	} --Thank you Spode
}

local translations = ModTextFileGetContent("data/translations/common.csv")
translations = translations .. "\n" .. ModTextFileGetContent("mods/fixnoita/files/missing_translations.csv") .. "\n"
translations = translations:gsub("\r", ""):gsub("\n\n+", "\n")
for _,value in ipairs(translation_overrides) do
	translations = translations:gsub(escape(value.target), value.new)
end
ModTextFileSetContent("data/translations/common.csv", translations)

--Fix the death messages caused by ghosts that follow Tapion Vasalli, "cursed rock" -> "holy"
modifile("data/entities/animals/boss_spirit/wisp.xml", [["$damage_rock_curse"]], [["$damage_holy"]])
--Fix the death messages caused by the Damage Field modifier, "cursed rock" -> "damage field"
modifile("data/entities/misc/area_damage.xml", [["$damage_rock_curse"]], [["$damage_projectile_area"]])




--[[ VOMIT INHERITANCE FIX ]]
--Vomit material was intended to inherit properties from Green Slime, this fails however because it is designated as a <CellData/> rather than <CellDataChild/>.

for xml in nxml.edit_file("data/materials.xml") do
	for elem in xml:each_of("CellData") do
		if elem.attr._parent then print(elem.attr.name) elem.name = "CellDataChild" 
		end
	end
end

for xml in nxml.edit_file("data/materials.xml") do
	for elem in xml:each_of("CellData") do
		--if elem.attr.name == "vomit" then elem.name = "CellDataChild" end
	end
end




--[[ ITEM STUN VISUALS FIX ]]
--The visuals caused by freeze-stun and electricity-stun effects can become permanent on a held item if you switch to a different item before the effect is up.

--[[ EMPTY DEATH MESSAGES ]]
--Sometimes the game does not provide a death message string, script_damage_received here.

--These two are just merged for efficiency so I don't need to add more than one LuaComponent to the player, will probably split if I eventually need to later.
for xml in nxml.edit_file("data/entities/player.xml") do
	xml:add_child(nxml.new_element("LuaComponent", {
		execute_every_n_frame = "6000", --fix stun visuals every 100 seconds.
		script_source_file = "mods/fixnoita/files/fix_permanent_stun_visual_items.lua", --Fix stun visuals script.
		script_damage_received = "mods/fixnoita/files/fix_death_message/add_message.lua", --fix empty death message script.
		script_polymorphing_to = "mods/fixnoita/files/fix_death_message/add_message.lua", --Detect when the player polymorphs to apply the fix to their new form.
	}))
end

--Script that activates when the player has been polymorphed to ensure the entity they polymorph into also has the death message fix applied.
local check_count = 10 --Number of frames in a row the mod will attempt to relocate the player
function OnWorldPreUpdate()
	if GameHasFlagRun("fixnoita_player_has_polymorphed") then
		local max_eid = EntitiesGetMaxID()
		local player
		for i = 0, max_eid - 1 do --Iterating over all entities to find the one with the `polymorphed_player` tag.
			---@type entity_id
			---@diagnostic disable-next-line: assign-type-mismatch
			local id = max_eid - i --Work backwards, cuz polymorphed player is very likely to be close to the end of the list.
			if EntityGetIsAlive(id) and (EntityHasTag(id, "polymorphed_player") or EntityHasTag(id, "player_unit")) then --"player_unit" for if the player is NOT polymorphed.
				player = id --We found our girl!
				break
			end
		end
		if not player then
			print("COULD NOT FIND POLYMORPHED PLAYER, SHIT SUCKS :/")
			check_count = check_count - 1
			if check_count <= 0 then GameRemoveFlagRun("fixnoita_player_has_polymorphed") end -- Give up. :(
			return
		end

		--Do this here to avoid the function running multiple times after player has been identified.
		GameRemoveFlagRun("fixnoita_player_has_polymorphed")

		for _,luacomp in ipairs(EntityGetComponent(player, "LuaComponent") or {}) do
			if ComponentGetValue2(luacomp, "script_damage_received") == "mods/fixnoita/files/fix_death_message/add_message.lua" then return end
		end --Check if the polymorphed player already has the script. If yes, then early return to halt the function.

		--If the script is not detected on the player, apply the fix.
		EntityAddComponent2(player, "LuaComponent", {
			script_damage_received = "mods/fixnoita/files/fix_death_message/add_message.lua",
			script_polymorphing_to = "mods/fixnoita/files/fix_death_message/add_message.lua",
		})
	end
end