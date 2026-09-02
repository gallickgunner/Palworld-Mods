---@class ConfigReloader
local ConfigReloader = {}

local UPaths = require("Constants.upaths")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local ModConfigManager = require("Managers.mod_config_manager")

local local_player_controller

-- Show notification about hot reload succeeding
local function ShowNotification()
	if not UnrealUtils.IsValid(local_player_controller) then
		return
	end

	local_player_controller:AddKillLog_Client({
		LogType = 2,
		AttackerName = CoreUtils.GetModName(),
		KilledCharacterName = "Config file reloaded"
	})
end


function ConfigReloader.Init()
	RegisterHook(
		UPaths.FUNC_PATHS.CLIENT_RESTART,

		function(Context)
			-- pre
		end,

		function(Context)
			local controller = Context:get()

			if not UnrealUtils.IsValid(controller) or not controller:IsLocalPlayerController() then
				return
			end

			local_player_controller = controller
		end
	)

	local mod_config = ModConfigManager.GetConfig()
	RegisterKeyBind(
		Key[mod_config.hot_reload_key],
		function()
			ModConfigManager.Reload()
			ShowNotification()
		end
	)
end

return ConfigReloader
