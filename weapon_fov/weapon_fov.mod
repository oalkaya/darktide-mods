return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`weapon_fov` encountered an error loading the Darktide Mod Framework.")

		new_mod("weapon_fov", {
			mod_script       = "weapon_fov/scripts/mods/weapon_fov/weapon_fov",
			mod_data         = "weapon_fov/scripts/mods/weapon_fov/weapon_fov_data",
			mod_localization = "weapon_fov/scripts/mods/weapon_fov/weapon_fov_localization",
		})
	end,
	packages = {},
}
