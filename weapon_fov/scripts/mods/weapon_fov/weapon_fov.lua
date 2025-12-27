local mod = get_mod("weapon_fov")

local CameraManager = require("scripts/managers/camera/camera_manager")

mod.custom_fov_enabled = mod:get("use_custom_fov") or false
mod.current_fov_mode = mod:get("fov_mode")

-- =========================================================
-- Global runtime application (single source of truth)
-- =========================================================

local function apply_globals_to_runtime()
	local data = mod:persistent_table("data")

	local ranged_zoom = mod:get("weapon_zoom_fov") or 45
	local ranged_fov  = mod:get("weapon_fov") or 40
	local ranged_ads  = mod:get("weapon_fov_ads") or 40
	local melee_fov   = mod:get("melee_weapon_fov") or 65

	-- Always store ranged zoom + ranged ADS FOV (used when aiming with ranged)
	data.weapon_zoom_fov = ranged_zoom
	data.weapon_fov_ads  = ranged_ads

	-- weapon_fov depends on whether we're currently considered melee or not
	-- (this is what your CameraManager.post_update uses when not aiming)
	if melee_weapon then
		data.weapon_fov = melee_fov
	else
		data.weapon_fov = ranged_fov
	end
end

-- =========================================================
-- Update fov mode
-- =========================================================

local function update_custom_fov_mode()
  local mode = mod:get("fov_mode")
  mod.current_fov_mode = mode

  if mode == "custom_fov" or mode == "custom_non_ads_fov" or mode == "regular_fov" then
    mod:set_custom_fov_enabled(true)
  else
    mod:set_custom_fov_enabled(false)
  end
end

mod.update_custom_fov_mode = update_custom_fov_mode


-- =========================================================
-- Mode toggle
-- =========================================================


mod.toggle_custom_fov = function()
	if mod.current_fov_mode == "regular_fov" then
		mod:set("fov_mode", "custom_fov")
		mod.current_fov_mode = "custom_fov"
		mod:set_custom_fov_enabled(true)
	elseif mod.current_fov_mode == "custom_fov" then
		mod:set("fov_mode", "custom_non_ads_fov")
		mod.current_fov_mode = "custom_non_ads_fov"
		mod:set_custom_fov_enabled(false)
	elseif mod.current_fov_mode == "no_custom_fov" then
		mod:set("fov_mode", "custom_non_ads_fov")
		mod.current_fov_mode = "custom_non_ads_fov"
		mod:set_custom_fov_enabled(false)
	elseif mod.current_fov_mode == "custom_non_ads_fov" then
		mod:set("fov_mode", "regular_fov")
		mod.current_fov_mode = "regular_fov"
		mod:set_custom_fov_enabled(true)
	else
		mod:set("fov_mode", "regular_fov")
		mod.current_fov_mode = "regular_fov"
		mod:set_custom_fov_enabled(true)
	end
end

mod.set_custom_fov_enabled = function(self, enabled)
	mod:set("use_custom_fov", enabled)
	mod.custom_fov_enabled = enabled
	mod:refresh_custom_fov()
end

mod.refresh_custom_fov = function()
	-- Guard: player (or player_unit) may not exist in character select / hub transitions
	local player = Managers.player and Managers.player:local_player_safe(1)
	if not player or not player.player_unit then
		return
	end

	local player_unit = player.player_unit

	local visual_loadout_extension = ScriptUnit.extension(player_unit, "visual_loadout_system")

	if (not visual_loadout_extension) or (not visual_loadout_extension._equipment) then
		return
	end

	for name, slot in pairs(visual_loadout_extension._equipment) do
		if slot.unit_1p and Unit.alive(slot.unit_1p) and Unit.is_valid(slot.unit_1p) then
			Unit.set_shader_pass_flag_for_meshes_in_unit_and_childs(slot.unit_1p, "custom_fov", mod:get("use_custom_fov"))
		end
	end
end


mod:hook(Unit, "set_shader_pass_flag_for_meshes_in_unit_and_childs", function(func, unit, name, value, ...)
	if name == "custom_fov" then
		func(unit, "custom_fov", mod:get("use_custom_fov") or false, ...)
	else
		func(unit, name, value, ...)
	end
end)

local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")

local is_aiming = false
melee_weapon = false  -- IMPORTANT: keep this global in file scope for apply_globals_to_runtime()

mod.update_weapon_template = function(self, weapon_template)
	if weapon_template and weapon_template.alternate_fire_settings and weapon_template.alternate_fire_settings.camera then

		if not weapon_template.alternate_fire_settings.camera.orig_vertical_fov then
			weapon_template.alternate_fire_settings.camera.orig_vertical_fov = weapon_template.alternate_fire_settings.camera.vertical_fov
			weapon_template.alternate_fire_settings.camera.orig_custom_vertical_fov = weapon_template.alternate_fire_settings.camera.custom_vertical_fov
		end

		apply_globals_to_runtime()
		weapon_template.alternate_fire_settings.camera.vertical_fov = mod:persistent_table("data").weapon_zoom_fov
		weapon_template.alternate_fire_settings.camera.custom_vertical_fov = mod:persistent_table("data").weapon_fov_ads
	end
end

mod:hook(WeaponTemplate, "current_weapon_template", function(func, weapon_action_component)
	local template = func(weapon_action_component)
	mod:update_weapon_template(template)
	return template
end)

mod:hook_safe(CLASS.ActionAim, "start", function(self, action_settings, t, ...)
	is_aiming = true
	if mod.current_fov_mode == "custom_non_ads_fov" then
		mod:set_custom_fov_enabled(true)
	end
end)

local ScriptViewport = require("scripts/foundation/utilities/script_viewport")
local ScriptWorld = require("scripts/foundation/utilities/script_world")

mod.unaim = function(...)
	is_aiming = false
	if mod.current_fov_mode == "custom_non_ads_fov" then
		mod:set_custom_fov_enabled(false)
	end
end

mod:hook_safe(CLASS.ActionThrowGrenade, "start", mod.unaim)
mod:hook_safe(CLASS.ActionReloadState, "start", mod.unaim)
mod:hook_safe(CLASS.ActionReloadShotgun, "start", mod.unaim)
mod:hook_safe(CLASS.ActionReloadShotgunSpecial, "start", mod.unaim)
mod:hook_safe(CLASS.ActionUnaim, "start", mod.unaim)

mod:hook_safe(CLASS.CameraManager, "post_update", function(self, dt, t, viewport_name)
	local world = Managers.world:world("level_world")
	local viewport = ScriptWorld.viewport(world, viewport_name)

	if viewport then
		local camera = ScriptViewport.camera(viewport)
		if camera and mod.current_fov_mode ~= "regular_fov" then
			apply_globals_to_runtime()

			local data = mod:persistent_table("data")
			if data.weapon_fov_ads ~= nil and is_aiming then
				Camera.set_custom_vertical_fov(camera, math.rad(data.weapon_fov_ads))
			elseif (not is_aiming) and data.weapon_fov ~= nil then
				Camera.set_custom_vertical_fov(camera, math.rad(data.weapon_fov))
			end
		end
	end
end)

-- =========================================================
-- Slot / wield handling: just set melee_weapon flag and apply globals
-- =========================================================

mod.update_primary_slot = function(self, visual_loadout)
	local template = visual_loadout:weapon_template_from_slot("slot_primary")
	if not template then
		return
	end
	melee_weapon = true
	apply_globals_to_runtime()
	mod:update_custom_fov_mode()
end

mod.update_secondary_slot = function(self, visual_loadout)
	local template = visual_loadout:weapon_template_from_slot("slot_secondary")
	if not template then
		return
	end
	melee_weapon = false
	apply_globals_to_runtime()
	mod:update_custom_fov_mode()
end

mod:hook_safe(CLASS.PlayerUnitVisualLoadoutExtension, "_equip_item_to_slot", function (self, item, slot_name, t, optional_existing_unit_3p, from_server_correction_occurred)
	if slot_name == "slot_secondary" then
		mod:update_secondary_slot(self)
	elseif slot_name == "slot_primary" then
		mod:update_primary_slot(self)
	end
end)

mod:hook_safe(CLASS.UIProfileSpawner, "_spawn_character_profile", function(self, profile, profile_loader, position, rotation, scale, state_machine, animation_event, face_state_machine_key, face_animation_event, force_highest_mip, disable_hair_state_machine, optional_unit_3p, optional_ignore_state_machine)
	local id = profile.character_id

	if id then
		if (not string.match(id, "_bot_")) and (not string.match(id, "_")) then
			local player = Managers.player:local_player_safe(1)

			if player and id == player:character_id() then
				local loadout = profile.loadout
				if loadout then
					-- Primary => melee, Secondary => ranged
					if loadout["slot_primary"] then
						melee_weapon = true
						apply_globals_to_runtime()
					end
					if loadout["slot_secondary"] then
						melee_weapon = false
						apply_globals_to_runtime()
					end
				end
			end
		end
	end
end)

local AlternateFire = require("scripts/utilities/alternate_fire")
local FixedFrame = require("scripts/utilities/fixed_frame")

mod:hook(AlternateFire, "camera_variables", function(func, weapon_template)
	local vertical_fov, custom_vertical_fov, near_range = func(weapon_template)

	if not vertical_fov then
		return vertical_fov, custom_vertical_fov, near_range
	end

	apply_globals_to_runtime()
	local data = mod:persistent_table("data")

	local zoom_fov = math.degrees_to_radians(data.weapon_zoom_fov)
	local custom_fov = math.degrees_to_radians(data.weapon_fov_ads)

	return zoom_fov, custom_fov, near_range
end)

mod:hook_safe(CLASS.PlayerUnitVisualLoadoutExtension, "wield_slot", function (self, slot_name)
	if slot_name == "slot_secondary" then
		melee_weapon = false
		apply_globals_to_runtime()
		mod:update_custom_fov_mode()
	elseif slot_name == "slot_primary" then
		melee_weapon = true
		apply_globals_to_runtime()
		mod:update_custom_fov_mode()
	else
		-- For any other slot: keep ranged behavior and apply globals.
		is_aiming = false
		melee_weapon = false
		apply_globals_to_runtime()
		mod:set_custom_fov_enabled(true)
	end
end)

mod.on_all_mods_loaded = function()
	-- Make sure runtime is in sync immediately
	mod.current_fov_mode = mod:get("fov_mode")
	apply_globals_to_runtime()
	mod:update_custom_fov_mode()
end

-- Global-only: sliders apply live, no per-weapon saving.
mod.on_setting_changed = function(setting_name)
	if setting_name == "weapon_zoom_fov"
		or setting_name == "weapon_fov"
		or setting_name == "weapon_fov_ads"
		or setting_name == "melee_weapon_fov"
	then
		apply_globals_to_runtime()
	elseif setting_name == "fov_mode" then
		mod:update_custom_fov_mode()
	end
end

mod:io_dofile("weapon_fov/scripts/mods/weapon_fov/fp_anim_variables")
