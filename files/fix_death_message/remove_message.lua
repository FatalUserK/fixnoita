local entity_id = GetUpdatedEntityID()

local parent = EntityGetParent(entity_id)
local stats = EntityGetFirstComponent(parent, "GameStatsComponent")
if not stats then print("no stats :(") EntityKill(entity_id) return end

local function escape(str) return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1") end

for _,varcomp in ipairs(EntityGetComponent(entity_id, "VariableStorageComponent") or {}) do
    if ComponentGetValue2(varcomp, "name") == "fixnoita_remove_string" then
        ComponentSetValue2(stats, "extra_death_msg", ComponentGetValue2(stats, "extra_death_msg"):gsub(escape(ComponentGetValue2(varcomp, "value_string")), "", 1))
        print("removed death message")
        break
    end
end

EntityKill(entity_id)