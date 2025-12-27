local mod = get_mod("weapon_fov")

local AlternateFire = require("scripts/utilities/alternate_fire")
local Recoil = require("scripts/utilities/recoil")
local Sway = require("scripts/utilities/sway")
local DEFAULT_SWAY_LERP_SPEED = 10
local _update_move, _update_aim_offset, _update_lunge_hit_mass = nil

function _update_move(dt, t, first_person_unit, unit_data_extension, alternate_fire_component, lerp_values)
	local first_person_component = unit_data_extension:read_component("first_person")
	local locomotion_component = unit_data_extension:read_component("locomotion")
	local rotation = first_person_component.rotation
	local velocity_current = Vector3.flat(locomotion_component.velocity_current)
	local velocity_normalized = Vector3.normalize(velocity_current)
	local rotation_right = Quaternion.right(rotation)
	local rotation_right_normalized = Vector3.normalize(rotation_right)
	local move_x_raw = Vector3.dot(velocity_normalized, rotation_right_normalized)
	local move_x = move_x_raw
	local rotation_forward = Vector3.flat(Quaternion.forward(rotation))
	local rotation_forward_normalized = Vector3.normalize(rotation_forward)
	local move_z = Vector3.dot(velocity_normalized, rotation_forward_normalized)

	if alternate_fire_component.is_active then
		move_x = math.clamp(math.lerp(lerp_values.move_x or 0, move_x, math.easeOutCubic(0.5 * dt)), -1, 1)
		move_z = math.clamp(math.lerp(lerp_values.move_z or 0, move_z, math.easeOutCubic(0.2 * dt)), -1, 1)
	else
		move_x = math.clamp(math.lerp(lerp_values.move_x or 0, move_x, math.easeOutCubic(0.2 * dt)), -1, 1)
		move_z = math.clamp(math.lerp(lerp_values.move_z or 0, move_z, math.easeOutCubic(0.5 * dt)), -1, 1)
	end

	move_x_raw = math.clamp(math.lerp(lerp_values.move_x_raw or 0, move_x_raw, math.easeOutCubic(1.7 * dt)), -1, 1)
	lerp_values.move_x_raw = move_x_raw
	lerp_values.move_z = move_z
	lerp_values.move_x = move_x

	local move_x_variable = Unit.animation_find_variable(first_person_unit, "move_x")
	if move_x_variable then
		Unit.animation_set_variable(first_person_unit, move_x_variable, move_x)
	end

	local move_x_raw_variable = Unit.animation_find_variable(first_person_unit, "move_x_raw")
	if move_x_raw_variable then
		Unit.animation_set_variable(first_person_unit, move_x_raw_variable, move_x_raw)
	end

	local move_z_variable = Unit.animation_find_variable(first_person_unit, "move_z")
	if move_z_variable then
		Unit.animation_set_variable(first_person_unit, move_z_variable, move_z)
	end

	local move_speed = Vector3.length(velocity_current)
	local move_speed_variable = Unit.animation_find_variable(first_person_unit, "move_speed")
	if move_speed_variable then
		Unit.animation_set_variable(first_person_unit, move_speed_variable, math.min(move_speed, 19.99999))
	end
end

local deg_65_in_rad = math.degrees_to_radians(65)

-- Debug log once per second (only if checkbox enabled)
local function debug_log_fov_throttled(weapon_extension, ads_scale, base_tweak_fov, current_fov, fov_mod, fov_mod_2, raw_x, raw_y)
	if not mod:get("debug_fov_logging") then
		return
	end

	local now = nil
	if Managers.time then
		now = Managers.time:time("main")
	end
	now = now or os.clock()

	mod._last_fov_debug_chat_t = mod._last_fov_debug_chat_t or 0
	if (now - mod._last_fov_debug_chat_t) < 1.0 then
		return
	end
	mod._last_fov_debug_chat_t = now

	local wt = weapon_extension and weapon_extension:weapon_template()
	local wname = (wt and wt.name) or "unknown_weapon"

	local ax = math.abs(raw_x)
	local ay = math.abs(raw_y)
	local over_x = math.max(0, ax - 1.0)
	local over_y = math.max(0, ay - 1.0)
	local over = math.max(over_x, over_y)
	local clamp_hit = (over > 0)

	local clamp_txt = ""
	if clamp_hit then
		clamp_txt = string.format("  **CLAMP HIT** over=%.3f", over)
	end

	mod:echo(string.format(
		"[weapon_fov] weapon=%s  s=%.3f  base=%.1fdeg  current=%.1fdeg  fov_mod=%.3f  fov_mod_2=%.3f  raw=(%.3f, %.3f)%s",
		wname,
		ads_scale or 1.0,
		math.radians_to_degrees(base_tweak_fov or 0),
		math.radians_to_degrees(current_fov or 0),
		fov_mod or 0,
		fov_mod_2 or 0,
		raw_x or 0,
		raw_y or 0,
		clamp_txt
	))
end

-- Compute ADS recoil scale from your "weapon model fov ads" slider relative to the weapon template's ORIGINAL model ADS FOV.
local function ads_recoil_scale_from_template_and_slider(weapon_extension)
	local data = mod:persistent_table("data")
	local current_ads_deg = (data and data.weapon_fov_ads) or mod:get("weapon_fov_ads")
	if not current_ads_deg then
		return 1
	end

	local weapon_template = weapon_extension and weapon_extension:weapon_template()
	local base_ads_deg = nil

	if weapon_template and weapon_template.alternate_fire_settings and weapon_template.alternate_fire_settings.camera then
		local cam = weapon_template.alternate_fire_settings.camera
		base_ads_deg = cam.orig_custom_vertical_fov or cam.custom_vertical_fov
	end

	if not base_ads_deg then
		return 1
	end

	if base_ads_deg <= 0.001 or current_ads_deg <= 0.001 then
		return 1
	end

	local base_ads = math.degrees_to_radians(base_ads_deg)
	local current_ads = math.degrees_to_radians(current_ads_deg)

	local s = math.tan(current_ads * 0.5) / math.tan(base_ads * 0.5)
	s = math.clamp(s, 0.25, 4.0)

	return s
end

function _update_aim_offset(dt, t, first_person_unit, unit_data_extension, weapon_extension, alternate_fire_component, lerp_values)
	local first_person_component = unit_data_extension:read_component("first_person")
	local rotation = first_person_component.rotation
	local pitch = Quaternion.pitch(rotation)
	local aim_height_variable = Unit.animation_find_variable(first_person_unit, "aim_height")

	if aim_height_variable then
		local current_value = Unit.animation_get_variable(first_person_unit, aim_height_variable)
		local wanted_value = math.clamp(pitch, -1, 1)
		local new_value = math.lerp(current_value, wanted_value, 20 * dt)
		new_value = math.clamp(new_value, -1, 1)
		Unit.animation_set_variable(first_person_unit, aim_height_variable, new_value)
	end

	local sway_component = unit_data_extension:read_component("sway")
	local movement_state_component = unit_data_extension:read_component("movement_state")
	local locomotion_component = unit_data_extension:read_component("locomotion")
	local inair_state_component = unit_data_extension:read_component("inair_state")
	local sway_template = weapon_extension:sway_template()
	local sway_settings = Sway.movement_state_settings(sway_template, movement_state_component, locomotion_component, inair_state_component)
	local visual_sway_settings = sway_settings and sway_settings.visual_sway_settings
	local sway_lerp_speed = visual_sway_settings and visual_sway_settings.lerp_speed or DEFAULT_SWAY_LERP_SPEED
	local sway_lerp_scalar = math.min(sway_lerp_speed * dt * 2, 1)

	local sway_offset_x = sway_component.offset_x
	local sway_offset_y = sway_component.offset_y

	sway_offset_x = math.lerp(lerp_values.sway_offset_x or 0, sway_offset_x, sway_lerp_scalar)
	sway_offset_y = math.lerp(lerp_values.sway_offset_y or 0, sway_offset_y, sway_lerp_scalar)
	lerp_values.sway_offset_x = sway_offset_x
	lerp_values.sway_offset_y = sway_offset_y

	local aim_offset_x = sway_offset_x * (sway_settings and sway_settings.visual_yaw_impact_mod or 1)
	local aim_offset_y = sway_offset_y * (sway_settings and sway_settings.visual_pitch_impact_mod or 1)

	local recoil_template = weapon_extension:recoil_template()
	local recoil_component = unit_data_extension:read_component("recoil")
	local movement_state_settings = Recoil.recoil_movement_state_settings(recoil_template, movement_state_component, locomotion_component, inair_state_component)
	local visual_recoil_settings = movement_state_settings and movement_state_settings.visual_recoil_settings

	-- We'll also compute ads_scale for logging (only meaningful in ADS)
	local ads_scale_for_log = 1.0

	if visual_recoil_settings then
		local recoil_intensity = visual_recoil_settings.intensity
		local lerp_scalar = visual_recoil_settings.lerp_scalar
		local yaw_intensity = visual_recoil_settings.yaw_intensity or recoil_intensity * 0.5

		local recoil_pitch_offset, recoil_yaw_offset = Recoil.weapon_offset(
			recoil_template,
			recoil_component,
			movement_state_component,
			locomotion_component,
			inair_state_component
		)

		local recoil_pitch_lerped = math.lerp(lerp_values.recoil_pitch_offset or 0, recoil_pitch_offset * recoil_intensity, lerp_scalar)
		local recoil_yaw_lerped   = math.lerp(lerp_values.recoil_yaw_offset   or 0, recoil_yaw_offset   * yaw_intensity,   lerp_scalar)
		lerp_values.recoil_pitch_offset = recoil_pitch_lerped
		lerp_values.recoil_yaw_offset   = recoil_yaw_lerped

		if alternate_fire_component.is_active then
			ads_scale_for_log = ads_recoil_scale_from_template_and_slider(weapon_extension)
			recoil_pitch_lerped = recoil_pitch_lerped * ads_scale_for_log
			recoil_yaw_lerped   = recoil_yaw_lerped   * ads_scale_for_log
		end

		aim_offset_y = aim_offset_y + recoil_pitch_lerped
		aim_offset_x = aim_offset_x + recoil_yaw_lerped
	end

	local fov_mod = 1
	local fov_mod_2 = 1
	local local_player = Managers.player:local_player(1)

	local base_tweak_fov = deg_65_in_rad
	local current_fov = nil

	if local_player then
		if alternate_fire_component.is_active then
			local weapon_template = weapon_extension:weapon_template()
			local vertical_fov = AlternateFire.camera_variables(weapon_template)

			if vertical_fov then
				base_tweak_fov = vertical_fov

				if weapon_template
					and weapon_template.alternate_fire_settings
					and weapon_template.alternate_fire_settings.camera
					and weapon_template.alternate_fire_settings.camera.orig_vertical_fov
				then
					fov_mod_2 = weapon_template.alternate_fire_settings.camera.orig_vertical_fov
							  / weapon_template.alternate_fire_settings.camera.vertical_fov
				end
			end
		end

		current_fov = Managers.state.camera:fov(local_player.viewport_name)
		fov_mod = math.tan(base_tweak_fov * 0.5) / math.tan(current_fov * 0.5) * fov_mod_2
	end

	local raw_x = aim_offset_x * fov_mod
	local raw_y = aim_offset_y * fov_mod

	-- Debug log once per second when enabled
	debug_log_fov_throttled(weapon_extension, ads_scale_for_log, base_tweak_fov, current_fov, fov_mod, fov_mod_2, raw_x, raw_y)

	aim_offset_x = math.clamp(raw_x, -1, 1)
	aim_offset_y = math.clamp(raw_y, -1, 1)

	local aim_offset_x_variable = Unit.animation_find_variable(first_person_unit, "aim_offset_x")
	if aim_offset_x_variable then
		Unit.animation_set_variable(first_person_unit, aim_offset_x_variable, aim_offset_x)
	end

	local aim_offset_y_variable = Unit.animation_find_variable(first_person_unit, "aim_offset_y")
	if aim_offset_y_variable then
		Unit.animation_set_variable(first_person_unit, aim_offset_y_variable, aim_offset_y)
	end

	_update_lunge_hit_mass(first_person_unit, unit_data_extension)
end

function _update_lunge_hit_mass(first_person_unit, unit_data_extension)
	local hit_mass_variable = Unit.animation_find_variable(first_person_unit, "hit_mass")

	if hit_mass_variable then
		local character_state_hit_mass_component = unit_data_extension:write_component("character_state_hit_mass")
		local hit_mass = character_state_hit_mass_component.used_hit_mass_percentage
		Unit.animation_set_variable(first_person_unit, hit_mass_variable, hit_mass)
	end
end

local FirstPersonAnimationVariables = require("scripts/utilities/first_person_animation_variables")

mod:hook(FirstPersonAnimationVariables, "update", function(func, dt, t, first_person_unit, unit_data_extension, weapon_extension, lerp_values)
	local alternate_fire_component = unit_data_extension:read_component("alternate_fire")

	_update_move(dt, t, first_person_unit, unit_data_extension, alternate_fire_component, lerp_values)
	_update_aim_offset(dt, t, first_person_unit, unit_data_extension, weapon_extension, alternate_fire_component, lerp_values)
	_update_lunge_hit_mass(first_person_unit, unit_data_extension)
end)
