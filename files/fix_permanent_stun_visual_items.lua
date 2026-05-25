local root = GetUpdatedEntityID()


local function recursive_fix(entity_id)
	for _,sprite in ipairs(EntityGetComponentIncludingDisabled(entity_id, "SpriteComponent") or {}) do
		if not ComponentGetIsEnabled(sprite) then EntityRefreshSprite(entity_id, sprite) end
	end -- ^We do not refresh the sprite if it is currently held by the player because it makes the sprite disappear for a frame- we want to be subtle.
	for _,child in ipairs(EntityGetAllChildren(entity_id) or {}) do
		recursive_fix(child)
	end
end

recursive_fix(root)