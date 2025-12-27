--audible successful dodge
--created by demba

local mod = get_mod("audible_successful_dodge")
local once = false
local enabled = false
function mod.on_enabled()
   enabled = true
end
function mod.on_disabled()
   enabled = false
end
local Audio = get_mod("Audio")
mod.on_all_mods_loaded = function()
    Audio = get_mod("Audio")  
end

-- Use Custom Sound Toggle
local useCustomSounds = mod:get("use_custom_sounds")

local playSound = function(soundfile)
    local world = Managers.world:world("level_world")
    local wwise_world = Managers.world:wwise_world(world)
    WwiseWorld.trigger_resource_event(wwise_world, soundfile)
end
-- Use custom sound or selected in-game sound
local CharacterSheet = require("scripts/utilities/character_sheet")
mod:hook_safe("WwiseWorld","trigger_resource_event",function(s, file_path, ...)
    if file_path == "wwise/events/player/play_player_dodge_melee_success_specials" then
        if enabled then
            if not mod:get("use_custom_sounds1") then playSound(mod:get("successful_special_dodge_sound"))
            else Audio.play_file("special.opus", { audio_type = "sfx" }) end
        end
    elseif file_path == "wwise/events/player/play_player_dodge_melee_success" then
        if enabled then 
            if not mod:get("use_custom_sounds2") then playSound(mod:get("successful_dodge_sound"))
            else Audio.play_file("dodge.opus", { audio_type = "sfx" }) end
        end
    end 
end)