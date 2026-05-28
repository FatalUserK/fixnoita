local entity_id = GetUpdatedEntityID()

if EntityHasTag(EntityGetRootEntity(entity_id), "player_unit") then
    local item_comp = EntityGetFirstComponent(entity_id, "ItemComponent")
    if item_comp then
        ComponentSetValue2(item_comp, "play_spinning_animation", true)
    end
end