---`fixnoita` is a very simple, and self-conceited name. But I believe I have fixed a list of inarguable flaws with the game, such as Spells to Power crashing if
--- cast with a lone Sparkbolt, or Kills to Mana perk's description outright lying to you. I have tried to limit the scope of what I fix to what I believe everyone
--- can agree would be better if fixed. I have an extended bugfixes mod focused on a wider range of things planned (or perhaps out by the time you read this), and
--- in that I can put the fixes I personally like, and have toggles for them there, but this mod is intended to be a baseline for the intended Noita experience that
--- I bevieve everyone should play. This is a list of bugs I think everyone can agree on positively benefitting the game. If for some reason you disagree on any of
--- these, let me know and I will take that into account.
---
---I would also like to make it clear this mod is not any sort of resentment towards the folks at Nolla. They did a wonderful job with this game, even if their code
--- was somewhat (very) questionable at times. I appreciate Noita for what it is rather than resent for what it could've been. This doesn't mean I do not wish for
--- more, wanting more of a good thing is simply human, that's what this mod is. I will always hope Nolla comes back for an Epilogue 3, for bugfixes, more API stuff
--- more content, but hoping this happens is the limit, and they are not responsible for the game they do not work on. Please do not resent Nolla Games.
---They, too, are only human.
---
---And if anyone at Nolla is reading this:
--- :O, hi! Big fan! I do not mind any of these fixes being implemented into vanilla if y'all are comfortable with that!
--- This mod has to do a couple awkward things cuz we're working from outside the vanilla code, so we need to inject our logic and changes into the base game, but I
--- have annotated and explained the bugs and ways I fix them to the best of my abilities below, I hope I can be of assistance!



---With that established, I have done my best to annotate the mod to help people reading the code understand the bugs better, and understand how I fix them.
---Whether you are here for something specific, or just browsing, I do wish you an enjoyable and educational experience.


--NXML is a very helpful Noita library maintained and largely written by https://github.com/NathanSnail used to parse Noita's custom XML format.
local nxml = dofile_once("mods/fixnoita/nxml/nxml.lua") ---@type nxml

--De-patterning function for dealing with string.gsub() and other pattern-utilising Lua functions.
local function escape(str) return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1") end

--Convenient function to simplify modifying files, gsub \r\n to \n to edit multiple lines at a time.
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



---LIST OF FIXES:
--[[ JETPACK HEIGHT FIX ]]
--[[ S2P CRASH FIX ]]
--[[ SUNGEM ALTAR FIX ]]
--[[ TRANSLATION FIXES ]]
--[[ ITEM STUN VISUALS FIX ]]
--[[ EMPTY DEATH MESSAGES ]]
--[[ MULTIPLE CRYSTAL KEYS FIX ]]
--[[ MISSING PERK FIX ]]
--[[ WRONG ENDING SPOT FIX ]]
--[[ SPINNY WANDS FIX ]]




--[[ JETPACK HEIGHT FIX ]]
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

-- Originally used NXML for this, but that's overkill. Unnecessary here.
for _,target in ipairs(jetpack_targets) do
	modifile(target, [[y_pos_offset_min=""]], [[y_pos_offset_min=".5"]])
end
--0.5 looks nicer than 0 imo, we don't know what value Nolla would have written here so it is somewhat up to interpretation.



--[[ S2P CRASH FIX ]]
-- Fixes invalid values resulting in RAB malforming explosion radius. These malformed explosions can in semi-rare cases be large enough to instantly crash your game.

-- Yeah no this is the easiest fix in the world. This bug was undocumented pre-epi2 due to the plethora of other issues with the spell lmao.
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

--Note that for death messages, this specifically targets "invalid" or "incorrect" translations, ones with an invalid translation key, or point to the wrong one.
--Not to be confused with the bug that provides no translation key at all (both show up in-game as an empty death message, so they are easy to confuse).
--The fix for no death message being generated at all can be found below at [[ EMPTY DEATH MESSAGES ]] (it also tries to catch invalid death messages I miss here).

local translation_overrides = {
	--KILLS TO MANA DESCRIPTION: "perkdesc_mana_from_kills"
	-- The perk's description is an outright lie, likely outdated.
	-- Perk actually gives you 150f of MANA_REGENERATION when an enemy that has been within 240px of you dies.
	{ -- en
		target = [["Every time an enemy near you dies, you release mana-recharging liquid."]],
		new = [["You gain a short-lived boost to your mana regeneration when an enemy dies."]]
	},
	{ -- fr-fr
		target = [["Chaque fois qu'un ennemi à proximité meurt, vous libérez un liquide rechargeant le mana."]],
		new = [["Gagne une régéneration de mana accrue pour une courte durée lorsqu'un ennemi meurt."]]
	},--Thank you Spode.
} -- Would be funny if these fan translations got into the game, just sayin' 👀

-- Add new translations, read common.csv for more individual info.
local translations = ModTextFileGetContent("data/translations/common.csv")
translations = translations .. "\n" .. ModTextFileGetContent("mods/fixnoita/files/missing_translations.csv") .. "\n"
translations = translations:gsub("\r", ""):gsub("\n\n+", "\n")
for _,value in ipairs(translation_overrides) do
	translations = translations:gsub(escape(value.target), value.new)
end
ModTextFileSetContent("data/translations/common.csv", translations)

-- Fix the death messages caused by ghosts that follow Tapion Vasalli, "cursed rock" -> "holy"
modifile("data/entities/animals/boss_spirit/wisp.xml", [["$damage_rock_curse"]], [["$damage_holy"]])
-- Fix the death messages caused by the Damage Field modifier, "cursed rock" -> "damage field"
modifile("data/entities/misc/area_damage.xml", [["$damage_rock_curse"]], [["$fixnoita_damage_projectile_area"]])
-- Fix the Propane Tank spell using a hardcoded name instead of its translation, "Propane tank" -> $action_propane_tank
modifile("data/entities/misc/custom_cards/propane_tank.xml", [["Propane tank"]], [["$action_propane_tank"]])

-- Fix "bzzt!" death message from sawblades not being translatable, "bzzt!" -> "$fixnoita_damage_sawblade"
local sawblade_targets = {
	"data/entities/projectiles/deck/disc_bullet_big.xml",
	"data/entities/projectiles/deck/disc_bullet_bigger.xml",
	"data/entities/misc/orbit_discs_disc.xml",
}
for _,file in ipairs(sawblade_targets) do
	modifile(file, [["bzzt!"]], [["$fixnoita_damage_sawblade"]])
end




--[[ ITEM STUN VISUALS FIX ]]
-- The visuals caused by freeze-stun and electricity-stun effects can become permanent on a held item if you switch to a different item before the effect is up.

--[[ EMPTY DEATH MESSAGES ]]
-- Sometimes the game does not provide a death message string, script_death here.

-- These two are just merged for efficiency so I don't need to add more than one LuaComponent to the player, will probably split if I eventually need to later.
for xml in nxml.edit_file("data/entities/player.xml") do
	xml:add_child(nxml.new_element("LuaComponent", {
		execute_every_n_frame = "6000", --fix stun visuals every 100 seconds.
		script_source_file = "mods/fixnoita/files/fix_permanent_stun_visual_items.lua", --Fix stun visuals script.
		script_death = "mods/fixnoita/files/fix_death_message/add_message.lua", --fix empty death message script.
		script_polymorphing_to = "mods/fixnoita/files/fix_death_message/add_message.lua", --Detect when the player polymorphs to apply the fix to their new form.
	}))
end

-- Script that activates when the player has been polymorphed to ensure the entity they polymorph into also has the death message fix applied.
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
			print("fixnoita: COULD NOT FIND POLYMORPHED PLAYER, SHIT SUCKS :/")
			check_count = check_count - 1
			if check_count <= 0 then GameRemoveFlagRun("fixnoita_player_has_polymorphed") end --Give up. :(
			return
		end

		-- Do this here to avoid the function running multiple times after player has been identified.
		GameRemoveFlagRun("fixnoita_player_has_polymorphed")

		for _,luacomp in ipairs(EntityGetComponent(player, "LuaComponent") or {}) do
			if ComponentGetValue2(luacomp, "script_death") == "mods/fixnoita/files/fix_death_message/add_message.lua" then return end
		end --Check if the polymorphed player already has the script. If yes, then early return to halt the function.

		-- If the script is not detected on the player, apply the fix.
		EntityAddComponent2(player, "LuaComponent", {
			script_death = "mods/fixnoita/files/fix_death_message/add_message.lua",
			script_polymorphing_to = "mods/fixnoita/files/fix_death_message/add_message.lua",
		})
	end
end




--[[ MULTIPLE CRYSTAL KEYS FIX ]]
-- The Crystal Key tracks whether it has listened to a specific music machine via RunFlags, but the light/dark chests use the key's VariableStorageComponent to track completion.
-- This causes issues if you have the key listen to a machine and then loes that key, as a new key will think it's already listened to that machine, and not take in the song.

-- Add new <VariableStorageComponent/> to the key.
for xml in nxml.edit_file("data/entities/animals/boss_alchemist/key.xml") do
	xml:add_child(nxml.new_element("VariableStorageComponent", {
		_tags = "enabled_in_world",
		name = "fixnoita_key_tracker",
		value_int = "0",
	}))
end

-- Prepend with our new function.
ModTextFileSetContent("data/entities/animals/boss_alchemist/key_music.lua",
	ModTextFileGetContent("mods/fixnoita/files/key_script_prepend.lua") .. ModTextFileGetContent("data/entities/animals/boss_alchemist/key_music.lua")
)

-- Replace flag check with our function.
modifile("data/entities/animals/boss_alchemist/key_music.lua",
	[[GameHasFlagRun( mm_flag ) and ( GameHasFlagRun( mm_flag .. "_done" ) == false )]],
	[[update_music_machine_status(entity_id, mm_id)]]
)




--[[ MISSING PERK FIX ]]
---In Holy Mountain, when entering a portal that's not one of the two directly above the Perk Altar, or if in the starting area above where you enter
--- the Holy Mountain and restarting/crashing, the third perk will be missing from the Perk Altar, on account of it being loaded into a chunk that was
--- not yet generated, causing it to not be saved.

-- Fix this by creating a singular entity created in the chunk the perks are spawned from to guarantee it's serialised, and then add the perks to it as children.
-- The perks will now be serialised as child entities under the group entity, group entity checks every 2f to see if both chunks are loaded.
-- If both chunks are loaded, the perk_group entity de-childs the perks and then deletes itself.

--Create our perk group entity.
modifile("data/scripts/perks/perk.lua", [[for i=1,count do]],
	[[local perk_group = EntityLoad("mods/fixnoita/files/missing_perk/perk_group.xml", x, y)
	for i=1,count do]]
)

--Attach our perks to it.
modifile("data/scripts/perks/perk.lua", [[perk_spawn( x + (i-0.5)*item_width, y, perk_id, dont_remove_others )]],
		[[local perk = perk_spawn( x + (i-0.5)*item_width, y, perk_id, dont_remove_others )
		if perk then EntityAddChild(perk_group, perk) end]]
)




--[[ WRONG ENDING SPOT FIX ]]
---This bug I initially didn't understand, but with Letaali's guidance and rereading the code, I finally get it, if there is more than one mountain altar
--- loaded at a time, it will not check if the player is close to each of them, it will check if the player is close to the youngest one. This oversight
--- means that if an altar in Main World is loaded whilst the player is at a different mountain altar in a Parallel World, the game will only check the
--- youngest one and deduce that the player is not near the mountain altar, failing to trigger the mountain alter ending.
---This bug is a bit frustrating as it is so easily avoidable by either using `EntityGetClosestWithTag` instead of `EntityGetWithTag`, or by iterating over
--- the ending spots captured and identifying the closest one.
---Ideally this should be using EntityGetInRadiusWithTag(), but this would mess with some of the existing code, so simply using EntityGetClosestWithTag is
--- the simplest way to resolve this. Thank you to Letaali for illuminating this one for me, and allowing me to use his fix from the QoL mod.

--Solution is to do a manual check for the closest one and override the prior returns.
modifile("data/entities/animals/boss_centipede/ending/sampo_start_ending_sequence.lua",
[[local endpoint_mountain = EntityGetWithTag( "ending_sampo_spot_mountain" )]],
[[local endpoint_mountain = EntityGetWithTag( "ending_sampo_spot_mountain" )
local fixnoita_underground = EntityGetClosestWithTag( x, y, "ending_sampo_spot_underground" )
local fixnoita_endpoint_mountain = EntityGetClosestWithTag( x, y, "ending_sampo_spot_mountain" )

if fixnoita_underground ~= 0 then endpoint_underground[1] = fixnoita_underground end
if fixnoita_endpoint_mountain ~= 0 then endpoint_mountain[1] = fixnoita_endpoint_mountain end
]])




--[[ SPINNY WANDS FIX ]]
---After an enemy picks up a wand, the wand loses its spinning property, and does not regain it when held by a player.

--Bug appears to be solely due to this collection of wands that are either prefabs, or templates from which prefabs are derived.
-- First floor basically has a lot of prefab wands, a design approach Nolla swiftly abandoned. Fixing these should fix any other cases. Probably.
local non_spinny_wands = {
	"data/entities/items/wands/level_01/base_wand_level_1.xml",
	"data/entities/items/wands/level_01/wand_001.xml",
	"data/entities/items/wands/level_01/wand_002.xml",
	"data/entities/items/wands/level_01/wand_003.xml",
	"data/entities/items/wands/level_01/wand_004.xml",
	"data/entities/items/wands/level_01/wand_005.xml",
	"data/entities/items/wands/level_01/wand_006.xml",
	"data/entities/items/wands/level_01/wand_007.xml",
	"data/entities/items/wands/level_01/wand_008.xml",
	"data/entities/items/wands/level_01/wand_009.xml",
}

for _,wand in ipairs(non_spinny_wands) do
	modifile(wand, [[play_spinning_animation="0"]], [[play_spinning_animation="1"]])
end




--[[ UNSAVED PROGRESS FIX ]]
---When crashing in a run, the game will sometimes successfully remember which progress was discovered this run- but forget to have it permanently discovered.
---This results in locked portraits having a glowy border indicating they were discovered, but not actually saving them to the progress menu.

--Since the game is correctly remembering what has been discovered this run, and theoretically if someone discovered something "this run", then they must have "discovered it"
-- to begin with, we can just iterate over everything and force-discover everything that has been discovered this run.
function OnWorldInitialized()
	RegisterPerk = function(id, ...)
		print(id)
		if GameHasFlagRun("new_perk_picked_" .. id) then
			AddFlagPersistent("perk_picked_" .. id)
		end
	end
	dofile("data/scripts/perks/perk_reflect.lua")
end

--This approach might theoretically be undesirable for a mod that intentionally has things discovered "this run" while not permanently marking them as discovered.
-- If such a case were to occur, I may end up taking out this fix and relegating it to my Extended Fixes mod, we shall see.




---Aaaand that's all!
--- Funny that the comments took up more space than the bug fixes half the time, huh?
--- This is because most of these fixes are quite simple! (and also I like to yap.)
--- Hope you got what you were looking for!
---
---FINAL NOTES:
--- If there's a bug with my mod or incompatibility with any other mods, let me know!
--- If there are any crucial bugs that I missed that were not patched, let me know!
--- If you have any questions about any specific bugs, let me know!
--- If there was anything I explained wrong or that you can provide more info on, let me know!
---
---I am @UserK on discord, you can ping me on the Noita Discord: https://discord.gg/Noita
--- or contact me directly (though I may think you're a bot- sorry, I get a lot of bots.)