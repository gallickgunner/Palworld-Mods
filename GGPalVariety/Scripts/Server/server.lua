---@class Server
local Server = {}
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local UPaths = require("Constants.upaths")
local UEHelpers = require("UEHelpers")

-- Aliases used often
local Log = CoreUtils.Log
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local FUNC_PATHS = UPaths.FUNC_PATHS

local game_instance = nil
local world_save_dirname = ""
local sap_cbs = {}
local new_world_loaded_cbs = {}
local notify_world_loaded_cbs = {}


local function IsNewWorld()
	-- If game_instance was stale fetch new
	if not IsValid(game_instance) then
		game_instance = UEHelpers.GetGameInstance()

		if not IsValid(game_instance) then
			Log("GameInstance invalid")
			return false
		end
	end

	local loaded_save_dirname = game_instance:GetSelectedWorldSaveDirectoryName():ToString()

	-- If the current loaded save dir name don't match with our cached name, means the player loaded a different world
	if loaded_save_dirname ~= world_save_dirname then
		world_save_dirname = loaded_save_dirname
		return true
	end
	return false
end

function Server.RegisterSAPCallback(cb, unregister_after_call)
	unregister_after_call = unregister_after_call or false
	table.insert(sap_cbs, { callback = cb, unregister_after_call = unregister_after_call })
end

function Server.RegisterOnNotifyWorldLoadedToServer(cb, unregister_after_call)
	unregister_after_call = unregister_after_call or false
	table.insert(notify_world_loaded_cbs, { callback = cb, unregister_after_call = unregister_after_call })
end

function Server.RegisterOnNewWorldLoadedCallback(cb, unregister_after_call)
	unregister_after_call = unregister_after_call or false
	table.insert(new_world_loaded_cbs, { callback = cb, unregister_after_call = unregister_after_call })
end

function Server.Init()
	RegisterHook(FUNC_PATHS.SERVER_ACK_POSSESS,
		function()
		end,
		function(Context)
			local controller = Context:get()
			if not IsValid(controller) then
				return
			end

			for i = #sap_cbs, 1, -1 do
				local entry = sap_cbs[i]

				entry.callback(controller)
				if entry.unregister_after_call then
					table.remove(sap_cbs, i)
				end
			end

			if IsNewWorld() then
				for i = #new_world_loaded_cbs, 1, -1 do
					local entry = new_world_loaded_cbs[i]

					entry.callback(controller)
					if entry.unregister_after_call then
						table.remove(new_world_loaded_cbs, i)
					end
				end
			end

			DebugLog("SAP triggered for PlayerController: %s", controller:GetFullName())
		end
	)

	RegisterHook(
		FUNC_PATHS.NOTIFY_ON_WORLD_LOAD_TO_SERVER,
		function()
		end,
		function(Context)
			local player_state = Context:get()

			if not IsValid(player_state) then
				DebugLog("Player State was not valid in: %s", FUNC_PATHS.NOTIFY_ON_WORLD_LOAD_TO_SERVER)
				return
			end

			for i = #notify_world_loaded_cbs, 1, -1 do
				local entry = notify_world_loaded_cbs[i]

				entry.callback(player_state)
				if entry.unregister_after_call then
					table.remove(notify_world_loaded_cbs, i)
				end
			end

			DebugLog("OnWorldLoad triggered for PlayerController: %s", player_state:GetPlayerController():GetFullName())
		end
	)
end

return Server
