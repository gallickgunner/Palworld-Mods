local ModConfigManager = require("Managers.mod_config_manager")
local LocalizationManager = require("Managers.localization_manager")
local ConfigReloader = require("Core.config_reloader")
local PalSizeDisplay = require("Core.pal_size_display")
local PalVisuals = require("Core.pal_visuals")
local Ride = require("Core.ride")
local GroupBehavior = require("Server.group_behavior")
local PalLifeCycle = require("SharedHooks.pal_lifecycle")
local Uninstall = require("Core.uninstall")
local TrustGrowth = require("Core.trust_growth")
local ProcessDamage = require("Server.process_damage")

local Server = require("Server.server")
local PalTraits = require("Server.pal_traits")

local PalUtils = require("Utils.pal_utils")
local CoreUtils = require("Utils.core_utils")


local function Main()
	local mod_config = ModConfigManager.GetConfig()

	if mod_config.uninstall_mode then
		Uninstall.Init()
		CoreUtils.Log("Mod is running in uninstall mode. Wait a few seconds then save game and exit to remove any custom skills from captured pals.")
		return
	end

	-- Systems
	if mod_config.enable_hot_reload then
		ConfigReloader.Init()
	end

	LocalizationManager.Init()
	PalLifeCycle.Init()
	Server.Init()
	PalUtils.Init()


	-- Modules
	TrustGrowth.Init()
	PalTraits.Init()
	PalVisuals.Init()
	Ride.Init()
	ProcessDamage.Init()

	if mod_config.display_size_widget then
		PalSizeDisplay.Init()
	end

	if mod_config.pals_spawn_disordered then
		GroupBehavior.Init()
	end


	CoreUtils.Log("Loaded.")
end

Main()
