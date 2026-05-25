---@diagnostic disable-next-line: unused-function, unused-local
local function update_music_machine_status(entity_id, mm_id)
	for _,varcomp in ipairs(EntityGetComponent(entity_id, "VariableStorageComponent") or {}) do
		if ComponentGetValue2(varcomp, "name") == "fixnoita_key_tracker" then
			local val = ComponentGetValue2(varcomp, "value_int") or 0
			local mm_bit = 2^mm_id
			if bit.band(val, mm_bit) == 0 then
				ComponentSetValue2(varcomp, "value_int", val + mm_bit)
				return true
			else
				return false
			end
		end
	end
end
