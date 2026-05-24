--function damage_received(damage, message, attacker, is_fatal, projectile)
--function death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)


function death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)
	local message = damage_message
	local is_fatal = true
	local attacker = entity_thats_responsible
	local projectile = 0

	if not is_fatal then return end --If damage is fatal, no need to mess with the death message.
	local msg = message:sub(1,1) == '$' and GameTextGetTranslatedOrNot(message) or message --if the message is a translation key, translate it
	if #msg > 0 then return end --If message is not empty, assume all is good and return early. 

	local entity_id = GetUpdatedEntityID()
	local stats = EntityGetFirstComponent(entity_id, "GameStatsComponent")
	print("GameStatsComponent id: " .. tostring(stats))
	print("GameStatsComponent name: " .. tostring(ComponentGetTypeName(stats or 0)))
	if not stats then return end
	if #ComponentGetTypeName(stats) == 0 then return end

	local function get_translation_or_nil(str)
		if str == nil then return end
		if str:sub(1,1) ~= '$' then str = '$' .. str end
		local tl = GameTextGetTranslatedOrNot(str)
		if #tl > 0 then return tl end
	end

	local function match_action(str) return get_translation_or_nil("$action_" .. (str or "")) end
	local function match_animal(str) return get_translation_or_nil("$animal_" .. (str or "")) end

	local function get_file_name(target) return EntityGetFilename(target):match("[^/]*$"):sub(1,-5) end

	local function get_projectile_filename_from_varcomp(target)
		for _,varcomp in ipairs(EntityGetComponent(target, "VariableStorageComponent") or {}) do
			if ComponentGetValue2(varcomp, "name") == "projectile_file" then
				return ComponentGetValue2(varcomp, "value_string"):match("[^/]*$"):sub(1,-5)
			end
		end
	end

	local funcs = {
		function(target) --check $action_filename
			return match_action(get_file_name(target))
		end,
		function(target) --check $action_projectile_varcomp
			return match_action(get_projectile_filename_from_varcomp(target))
		end,
		function(target) --check $name
			return get_translation_or_nil(EntityGetName(target))
		end,
		function(target) --check $animal_filename
			return match_animal(get_file_name(target))
		end,
		function(target) --check $filename
			return get_translation_or_nil(get_file_name(target))
		end,
	}

	local attacker_name
	if attacker ~= 0 then
		if projectile == 0 then
			for _,proj_comp in ipairs(EntityGetComponent(attacker, "ProjectileComponent") or {}) do
				local who_shot = ComponentGetValue2(proj_comp, "mWhoShot")
				if EntityGetIsAlive(who_shot) then
					projectile = attacker
					attacker = who_shot
					break
				end
			end
		end
		for _,func in ipairs(funcs) do
			attacker_name = func(attacker)
			if attacker_name ~= nil then break end
		end
	end

	local projectile_name
	if projectile ~= 0 then
		for _,func in ipairs(funcs) do
			projectile_name = func(projectile)
			if projectile_name ~= nil then break end
		end
	end

	local death_msg
	if projectile_name and attacker_name then
		if attacker_name:sub(-1) == 's' then
			death_msg = GameTextGet("$menugameover_causeofdeath_killer_cause_name_ends_in_s", attacker_name, projectile_name)
		else
			death_msg = GameTextGet("$menugameover_causeofdeath_killer_cause", attacker_name, projectile_name)
		end
	else
		death_msg = attacker_name or projectile_name
	end

	if not death_msg then return end

	ComponentSetValue2(stats, "extra_death_msg", death_msg .. ComponentGetValue2(stats, "extra_death_msg"))
	local c = EntityCreateNew("remove_extra_death_msg")
	EntityAddChild(entity_id, c)
	EntityAddComponent2(c, "LuaComponent", {
		script_source_file = "mods/fixnoita/files/fix_death_message/remove_message.lua"
	})
	EntityAddComponent2(c, "VariableStorageComponent", {
		name = "fixnoita_remove_string",
		value_string = death_msg
	})
end

function polymorphing_to(target_polymorph_path)
	GameAddFlagRun("fixnoita_player_has_polymorphed")
end