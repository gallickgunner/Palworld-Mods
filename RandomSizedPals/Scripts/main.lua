local Ride = require("Core.ride")
local RandomizeSize = require("Core.randomize_size")
local ConfigReloader = require("Core.config_reloader")
--local PalGroups = require("Core.pal_groups")
--local SaddleRequirements = require("Core.saddle_requirements")
local ModConfigManager = require("Managers.mod_config_manager")
local CoreUtils = require("Utils.core_utils")

local function Main()
	local mod_config = ModConfigManager.GetConfig()

	RandomizeSize.Init()
	Ride.Init()

	if mod_config.enable_hot_reload then
		ConfigReloader.Init()
	end

	CoreUtils.Log("Loaded.")
end

Main()
