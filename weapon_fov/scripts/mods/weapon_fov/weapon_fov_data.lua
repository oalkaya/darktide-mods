local mod = get_mod("weapon_fov")


return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets =
		{
			{
				setting_id = "toggle_fov",
				type = "keybind",
				default_value = {},
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "toggle_custom_fov",
			},
			{
				setting_id = "fov_mode",
				type = "dropdown",
				default_value  = "no_custom_fov",
				options =
				{
					{text = "loc_regular_fov", value = "regular_fov"},
					{text = "loc_custom_fov", value = "custom_fov"},
					{text = "loc_no_custom_fov", value = "no_custom_fov"},
					{text = "loc_custom_non_ads_fov", value = "custom_non_ads_fov"},
				}
			},
			-- NEW: debug toggle (UI checkbox)
			{
				setting_id = "debug_fov_logging",
				type = "checkbox",
				default_value = false,
			},
			{
				setting_id = "ranged_group",
				type = "group",
				sub_widgets =
				{
					{
						setting_id = "weapon_zoom_fov",
						type = "numeric",
						default_value = 45,
						range = {15,120},
						decimals_number = 0
					},
					{
						setting_id = "weapon_fov",
						type = "numeric",
						default_value = 40,
						range = {15,120},
						decimals_number = 0
					},
					{
						setting_id = "weapon_fov_ads",
						type = "numeric",
						default_value = 40,
						range = {15,120},
						decimals_number = 0
					},
				}
			},
			{
				setting_id = "melee_group",
				type = "group",
				sub_widgets =
				{
					{
						setting_id = "melee_weapon_fov",
						type = "numeric",
						default_value = 65,
						range = {15,120},
						decimals_number = 0
					},
				}
			},
		},
	},
}
