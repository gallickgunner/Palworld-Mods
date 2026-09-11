---@class Server
local Server = {}
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local UPaths = require("Constants.upaths")

-- Aliases used often
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local FUNC_PATHS = UPaths.FUNC_PATHS

local sap_cbs = {}
local world_loaded_cbs = {}


function Server.RegisterSAPCallback(callback)
	table.insert(sap_cbs, callback)
end

function Server.RegisterOnClientWorldLoadedCallback(callback)
	table.insert(world_loaded_cbs, callback)
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

			for _, callback in ipairs(sap_cbs) do
				callback(controller)
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

			for _, callback in ipairs(world_loaded_cbs) do
				callback(player_state)
			end
		end
	)
end

return Server
