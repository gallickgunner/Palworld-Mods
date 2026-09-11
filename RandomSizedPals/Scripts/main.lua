local ModConfigManager = require("Managers.mod_config_manager")
local LocalizationManager = require("Managers.localization_manager")
local ConfigReloader = require("Core.config_reloader")
local RandomizeSize = require("Core.pal_resizer")
local Ride = require("Core.ride")
local PalSizeDisplay = require("Core.pal_size_display")

local Server = require("Server.server")
local PalLeader = require("Server.pal_leader")

local CDO = require("Utils.cdo")
local PalUtils = require("Utils.pal_utils")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")


-- Aliases used often
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid

local function Main()
	ModConfigManager.Init()
	LocalizationManager.Init()
	Server.Init()
	PalLeader.Init()
	PalSizeDisplay.Init()

	RandomizeSize.Init()
	Ride.Init()

	local mod_config = ModConfigManager.GetConfig()
	if mod_config.enable_hot_reload then
		ConfigReloader.Init()
	end

	CoreUtils.Log("Loaded.")
end

Main()

RegisterHook(
	"/Script/Pal.PalCharacter:SetActiveActor",
	function()
	end,
	function(Context, Active)
		local pal_actor = Context:get()

		if not IsValid(pal_actor) then
			return
		end

		local is_active = Active:get()

		DebugLog(
			"PAL ACTIVE CHANGE | %s | ID= %s | active=%s | property=%s | initialized=%s",
			pal_actor:GetFullName(),
			PalUtils.GetPalInstanceIdFromActor(pal_actor),
			tostring(is_active),
			tostring(pal_actor.bIsPalActiveActor),
			tostring(pal_actor:IsInitialized())
		)
	end
)
