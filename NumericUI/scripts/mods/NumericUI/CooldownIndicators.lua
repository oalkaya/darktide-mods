local mod = get_mod("NumericUI")
local UISettings = require("scripts/settings/ui/ui_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local FixedFrame = require("scripts/utilities/fixed_frame")

mod:hook_require(
	"scripts/ui/hud/elements/blocking/hud_element_stamina_definitions",
	function(instance)
        instance.widget_definitions.recover_time = UIWidget.create_definition({
            {
                style_id = "timer",
                pass_type = "rect",
                style = {
                    color = { 255, 255, 100, 100 },
                    vertical_alignment = "top",
                    horizontal_alignment = "center",
                    drop_shadow = true,
                    size = { 100, 8 },
                    offset = {
                        0,
                        5,
                    },
                },
                visibility_function = function(_content, _style)
                    return true
                end,
            },
        }, "gauge")
	end
)

mod:hook_require(
	"scripts/ui/hud/elements/dodge_counter/hud_element_dodge_counter_definitions",
	function(instance)
        instance.widget_definitions.dodge_timer = UIWidget.create_definition({
            {
                style_id = "timer",
                pass_type = "rect",
                style = {
                    color = { 255, 255, 100, 100 },
                    vertical_alignment = "top",
                    horizontal_alignment = "center",
                    drop_shadow = true,
                    size = { 100, 8 },
                    offset = {
                        0,
                        3,
                    },
                },
                visibility_function = function(_content, _style)
                    return true
                end,
            },
        }, "gauge")
	end
)

local timer_size_color = function(stam_progress, cooldown, force_full)
    local timer_size = { 212, mod:get("dodge_timer_height") }
    local timer_color = { 0, 0, 0, 0 }
	-- NB: time_to_refresh will increase towards zero
	local t_max = cooldown or 1
	if (stam_progress >= t_max and not force_full) then
		return
	end
	local natural_time = 1 - math.clamp(stam_progress / t_max, 0, 1)
    if force_full and natural_time == 0 then
        natural_time = 1
    end

	timer_size[1] = 212 * natural_time

	local color_start = Color[mod:get("color_start")](255, true)
	local color_end = Color[mod:get("color_end")](255, true)
	for i = 1, 4 do
		timer_color[i] = math.lerp(color_start[i], color_end[i], 1 - natural_time)
	end
	return timer_size, timer_color
end

mod:hook_safe("HudElementStamina", "update", function(self, dt, t, ui_renderer, render_settings, input_service)
    self._widgets_by_name.recover_time.style.timer.size = ZERO_SIZE
    local parent = self._parent
    local player_extensions = parent:player_extensions()
    if player_extensions then
        local unit_data_extension = player_extensions.unit_data
        local archetype = unit_data_extension:archetype()
        local base_stamina_template = archetype and archetype.stamina

        if unit_data_extension and base_stamina_template then
            local stamina_component = unit_data_extension:read_component("stamina")
            local buff_extension = ScriptUnit.has_extension(unit_data_extension._unit, "buff_system")
            local stat_buffs = buff_extension and buff_extension:stat_buffs()
            local regen_stat = stat_buffs and stat_buffs.stamina_regeneration_delay or 0
            local stamina_regen_delay = base_stamina_template.regeneration_delay + regen_stat
		    local gameplay_t = Managers.time:time("gameplay")
            local stam_progress = gameplay_t - stamina_component.last_drain_time
            local block_component = unit_data_extension:read_component("block")
			local sprint_component = unit_data_extension:read_component("sprint_character_state")
            local is_blocking = block_component and block_component.is_blocking
            local is_sprinting = sprint_component and sprint_component.is_sprinting
            local timer_size, timer_color =
                timer_size_color(stam_progress, stamina_regen_delay, stamina_component.current_fraction < 1 and (is_sprinting))
            self._widgets_by_name.recover_time.style.timer.size = timer_size or ZERO_SIZE
            self._widgets_by_name.recover_time.style.timer.color = timer_color or Color.text_default(0, true)
        end
    end
end)

mod:hook_safe("HudElementDodgeCounter", "update", function(self, dt, t, ui_renderer, render_settings, input_service)
    self._widgets_by_name.dodge_timer.style.timer.size = ZERO_SIZE
    local parent = self._parent
    local player_extensions = parent:player_extensions()
    if player_extensions then
        local unit_data_extension = player_extensions.unit_data
        local archetype = unit_data_extension and unit_data_extension:archetype()
        local base_dodge_template = archetype and archetype.dodge
        local dodge_state_component = unit_data_extension:read_component("dodge_character_state")
        local gameplay_t = FixedFrame.get_latest_fixed_time()

        if base_dodge_template and dodge_state_component then
            local relative_cooldown = dodge_state_component.consecutive_dodges_cooldown - dodge_state_component.dodge_time
            local relative_time = gameplay_t - dodge_state_component.dodge_time
			local movement_state_component = unit_data_extension:read_component("movement_state")
			local is_sliding = movement_state_component and movement_state_component.method == "sliding"
			local is_dodging = movement_state_component and movement_state_component.is_dodging
            local already_dodging = is_sliding or is_dodging
            local timer_size, timer_color =
                timer_size_color(relative_time, relative_cooldown, already_dodging)
            self._widgets_by_name.dodge_timer.style.timer.size = timer_size or ZERO_SIZE
            self._widgets_by_name.dodge_timer.style.timer.color = timer_color or Color.text_default(0, true)
        end
    end
end)