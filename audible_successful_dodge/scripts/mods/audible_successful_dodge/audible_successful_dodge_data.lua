local mod = get_mod("audible_successful_dodge")

return {
	name = "Audible Successful Dodge",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "use_custom_sounds1", type = "checkbox", default_value = false
			},{
				setting_id = "use_custom_sounds2", type = "checkbox", default_value = false
			},
			{
				setting_id = "successful_dodge_sound", type = "dropdown", default_value = "wwise/events/player/play_ability_zealot_bolstering_prayer", options = {
					{text = "human_punch_heavy", value = "wwise/events/weapon/play_melee_hits_human_punch_heavy"},
					{text = "human_punch_light", value = "wwise/events/weapon/play_melee_hits_human_punch_light"},
					{text = "pick_up_forge_material_small", value = "wwise/events/player/play_pick_up_forge_material_small"}, 
					{text = "pick_up_forge_material_large", value = "wwise/events/player/play_pick_up_forge_material_large"},
					{text = "pick_up_forge_material_platinum_small", value = "wwise/events/player/play_pick_up_forge_material_platinum_small"},
					{text = "pick_up_forge_material_platinum_large", value = "wwise/events/player/play_pick_up_forge_material_platinum_large"},
					{text = "pick_up_grenade", value = "wwise/events/player/play_pick_up_grenade"},
					{text = "pick_up_syringe", value = "wwise/events/player/play_pick_up_syringe"},
					{text = "pick_up_tome", value = "wwise/events/player/play_pick_up_tome"},
					{text = "play_pick_up_ammo_01", value = "wwise/events/player/play_pick_up_ammo_01"},
					{text = "pick_up_ammo_pack", value = "wwise/events/player/play_pick_up_ammopack"},
					{text = "pick_up_box", value = "wwise/events/player/play_pick_up_box"},
					{text = "indicator_weakspot", value = "wwise/events/weapon/play_indicator_weakspot"},
					{text = "indicator_weakspot_melee_sharp", value = "wwise/events/weapon/play_hit_indicator_weakspot_melee_sharp"}, 
					{text = "indicator_crit", value = "wwise/events/weapon/play_indicator_crit"},
					{text = "psyker_lightning_bolt_impact_death", value = "wwise/events/weapon/play_psyker_lightning_bolt_impact_death"},
					{text = "bullet_hit_unarmored_death", value = "wwise/events/weapon/play_bullet_hits_gen_unarmored_death"},
					{text = "bullet_hits_explosive_gen", value = "wwise/events/weapon/play_bullet_hits_explosive_gen"}, 
					{text = "hits_blunt_shield", value = "wwise/events/weapon/melee_hits_blunt_shield"},
					{text = "bullet_hits_laser_unarmored", value = "wwise/events/weapon/play_bullet_hits_laser_unarmored"},  
					{text = "chaos_spawn_ground_impact_large_default", value = "wwise/events/minions/play_chaos_spawn_ground_impact_large_default"},
					{text = "plague_ogryn_stomp_metal", value = "wwise/events/minions/play_enemy_character_foley_plague_ogryn_stomp_metal"},
					{text = "battery_pick_up", value = "wwise/events/world/play_int_battery_pick_up"},
					{text = "auspex_bio_minigame_selection_right", value = "wwise/events/player/play_device_auspex_bio_minigame_selection_right"},
					{text = "auspex_bio_minigame_selection_wrong", value = "wwise/events/player/play_device_auspex_bio_minigame_selection_wrong"},
					{text = "zealot_bolstering_prayer", value = "wwise/events/player/play_ability_zealot_bolstering_prayer"},
					{text = "psyker_equip_single_shard", value = "wwise/events/player/play_psyker_gunslinger_equip_shard_single"},
					{text = "psyker_restored_final_shard", value = "wwise/events/player/play_psyker_restored_shard"},
				},
			},
			{
				setting_id = "successful_special_dodge_sound", type = "dropdown", default_value = "wwise/events/player/play_ability_zealot_bolstering_prayer", options = {
					{text = "human_punch_heavy", value = "wwise/events/weapon/play_melee_hits_human_punch_heavy"},
					{text = "human_punch_light", value = "wwise/events/weapon/play_melee_hits_human_punch_light"},
					{text = "pick_up_forge_material_small", value = "wwise/events/player/play_pick_up_forge_material_small"}, 
					{text = "pick_up_forge_material_large", value = "wwise/events/player/play_pick_up_forge_material_large"},
					{text = "pick_up_forge_material_platinum_small", value = "wwise/events/player/play_pick_up_forge_material_platinum_small"},
					{text = "pick_up_forge_material_platinum_large", value = "wwise/events/player/play_pick_up_forge_material_platinum_large"},
					{text = "pick_up_grenade", value = "wwise/events/player/play_pick_up_grenade"},
					{text = "pick_up_syringe", value = "wwise/events/player/play_pick_up_syringe"},
					{text = "pick_up_tome", value = "wwise/events/player/play_pick_up_tome"},
					{text = "play_pick_up_ammo_01", value = "wwise/events/player/play_pick_up_ammo_01"},
					{text = "pick_up_ammo_pack", value = "wwise/events/player/play_pick_up_ammopack"},
					{text = "pick_up_box", value = "wwise/events/player/play_pick_up_box"},
					{text = "indicator_weakspot", value = "wwise/events/weapon/play_indicator_weakspot"},
					{text = "indicator_weakspot_melee_sharp", value = "wwise/events/weapon/play_hit_indicator_weakspot_melee_sharp"}, 
					{text = "indicator_crit", value = "wwise/events/weapon/play_indicator_crit"},
					{text = "psyker_lightning_bolt_impact_death", value = "wwise/events/weapon/play_psyker_lightning_bolt_impact_death"},
					{text = "bullet_hit_unarmored_death", value = "wwise/events/weapon/play_bullet_hits_gen_unarmored_death"},
					{text = "bullet_hits_explosive_gen", value = "wwise/events/weapon/play_bullet_hits_explosive_gen"}, 
					{text = "hits_blunt_shield", value = "wwise/events/weapon/melee_hits_blunt_shield"},
					{text = "bullet_hits_laser_unarmored", value = "wwise/events/weapon/play_bullet_hits_laser_unarmored"},  
					{text = "chaos_spawn_ground_impact_large_default", value = "wwise/events/minions/play_chaos_spawn_ground_impact_large_default"},
					{text = "plague_ogryn_stomp_metal", value = "wwise/events/minions/play_enemy_character_foley_plague_ogryn_stomp_metal"},
					{text = "battery_pick_up", value = "wwise/events/world/play_int_battery_pick_up"},
					{text = "auspex_bio_minigame_selection_right", value = "wwise/events/player/play_device_auspex_bio_minigame_selection_right"},
					{text = "auspex_bio_minigame_selection_wrong", value = "wwise/events/player/play_device_auspex_bio_minigame_selection_wrong"},
					{text = "zealot_bolstering_prayer", value = "wwise/events/player/play_ability_zealot_bolstering_prayer"},
					{text = "psyker_equip_single_shard", value = "wwise/events/player/play_psyker_gunslinger_equip_shard_single"},
					{text = "psyker_restored_final_shard", value = "wwise/events/player/play_psyker_restored_shard"},
				},
			}
		}
	}
}