local Ride = require("Core.ride")
local RandomizeSize = require("Core.randomize_size")
local ConfigReloader = require("Core.config_reloader")
local ModConfigManager = require("Managers.mod_config_manager")
local CoreUtils = require("Utils.core_utils")

local function Main()
	local mod_config = ModConfigManager.GetConfig()

	RandomizeSize.Init()

	if mod_config.disable_tiny_ride_pals or mod_config.disable_saddle_requirement then
		Ride.Init()
	end

	if mod_config.enable_hot_reload then
		ConfigReloader.Init()
	end

	CoreUtils.Log("Loaded.")
end

Main()
