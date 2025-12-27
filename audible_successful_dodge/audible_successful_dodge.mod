return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`audible_successful_dodge` encountered an error loading the Darktide Mod Framework.")

		new_mod("audible_successful_dodge", {
			mod_script       = "audible_successful_dodge/scripts/mods/audible_successful_dodge/audible_successful_dodge",
			mod_data         = "audible_successful_dodge/scripts/mods/audible_successful_dodge/audible_successful_dodge_data",
			mod_localization = "audible_successful_dodge/scripts/mods/audible_successful_dodge/audible_successful_dodge_localization",
		})
	end,
	packages = {},
}
