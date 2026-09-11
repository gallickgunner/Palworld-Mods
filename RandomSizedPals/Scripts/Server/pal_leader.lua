---@class PalLeader
local PalLeader = {}

local LeaderStateManager = require("Network.leader_state_manager")
local Server = require("Server.server")

local CDO = require("Utils.cdo")
local UPaths = require("Constants.upaths")
local PalUtils = require("Utils.pal_utils")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")

local UEHelpers = require("UEHelpers")

-- Aliases used often
local Log = CoreUtils.Log
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local FUNC_PATHS = UPaths.FUNC_PATHS
local UOBJ_PATHS = UPaths.UOBJ_PATHS

local CAPTURED_LEADERS_DIR = CoreUtils.GetModDir() .. "Data/Captured-Leaders/"
local LEADER_CONFIRM_PAYLOAD_HEADER = FName("RSP|LEADER_CONFIRMATION")
local ADD_LEADER_PAYLOAD_HEADER = FName("RSP|ADD_LEADER")

local captured_leaders_file_log_name = "../Data/Captured-Leaders/"
local world_save_dirname = ""

local game_instance = nil
local captured_leaders = {}
local wild_leader_found_cbs = {}
local NO_OVERRIDE = FName("")
local player_controllers = {
	--[[
	PlayerUid = {
		controller = PlayerController
		full_name = FullName
		address = Controller Address
	}
	--]]
}

local function LoadCapturedGroupLeadersFromFile()
	local fp = CAPTURED_LEADERS_DIR .. world_save_dirname
	local file = io.open(fp, "r")
	captured_leaders = {}

	if not file then
		Log("Captured group leader data file not found. Creating a new file.")
		local dat_file = io.open(fp, "w")

		if dat_file then
			dat_file:close()
			Log("Successfully generated the captured group leader dat file. " .. captured_leaders_file_log_name .. world_save_dirname .. ".dat")
		else
			Log("Failed to generate the captured group leader dat file. " .. captured_leaders_file_log_name .. world_save_dirname .. ".dat")
		end
		return true
	end

	for unique_id in file:lines() do
		if unique_id ~= "" then
			captured_leaders[unique_id] = true
		end
	end

	file:close()
	Log("Successfuly read the captured group leader dat file.")
	return true
end

local function SaveCapturedGroupLeader(id)
	local fp = CAPTURED_LEADERS_DIR .. world_save_dirname
	if captured_leaders[id] then
		return true
	end

	local file = io.open(fp, "a")

	if not file then
		Log("Failed to open captured group leader data file.")
		return false
	end

	local wrote = file:write(id, "\n")
	file:close()

	if not wrote then
		Log("Failed to save captured group leader in file: %s", id)
		return false
	end

	captured_leaders[id] = true
	return true
end

local function CachePlayerController(controller)
	if not IsValid(controller) then
		return false
	end

	-- We only need to cache all client controllers for networking.
	if controller:IsLocalPlayerController() then
		return false
	end
	local address = controller:GetAddress()
	local full_name = controller:GetFullName()
	local uid = CDO.kismet_guid_lib:Conv_GuidToString(controller:GetPlayerUId()):ToString()
	local cached = player_controllers[uid]

	if cached
		and IsValid(cached.controller)
		and cached.address == address
		and cached.full_name == full_name then
		return false
	end

	if cached then
		DebugLog("Replacing PlayerController | UID: %s | oldAddr=%s | newAddr=%s", uid, tostring(cached.address), tostring(address))
	else
		DebugLog("Caching PlayerController | UID: %s | address=%s", uid, tostring(address))
	end

	player_controllers[uid] = {
		controller = controller,
		address = address,
		full_name = full_name
	}

	return true
end

local function OnServerAcknowledgePossesssion(controller)
	-- If game_instance was stale fetch new
	if not IsValid(game_instance) then
		game_instance = UEHelpers.GetGameInstance()

		-- If we got a new valid game instance get the world save directory name and load its captured leader data
		if not IsValid(game_instance) then
			Log("GameInstance invalid")
			return
		end
	end

	local loaded_save_dirname = game_instance:GetSelectedWorldSaveDirectoryName():ToString()

	-- If the current loaded save dir name don't match, means the player loaded a different world so load that world's captured leaders data
	local world_changed = loaded_save_dirname ~= world_save_dirname
	if world_changed then
		world_save_dirname = loaded_save_dirname

		LeaderStateManager.ResetState()
		LoadCapturedGroupLeadersFromFile()
	end
	CachePlayerController(controller)
end

local function BroadcastLeaderPalId(indiv_id)
	for uid, entry in pairs(player_controllers) do
		local player_controller = entry.controller

		if IsValid(player_controller) then
			DebugLog("Broadcasting leader ID: " .. PalUtils.GetPalInstanceIdFromIndivId(indiv_id))
			player_controller:SendLog_ToClient(0, 0, ADD_LEADER_PAYLOAD_HEADER, { IndividualId = indiv_id })
		else
			player_controller[uid] = nil
		end
	end
end

local function OnWildLeaderFound(pal_actor)
	local indiv_id = CDO.pal_utility:GetIndividualIDByActor(pal_actor)
	if not CDO.pal_utility:IsValidInstanceID(indiv_id) then
		DebugLog("Failed to get a valid FPalInstanceID from wild leader pal")
		return
	end

	LeaderStateManager.AddLeader(indiv_id)
	BroadcastLeaderPalId(indiv_id)
	for _, callback in ipairs(wild_leader_found_cbs) do
		-- Apply the correct size to leaders on server
		callback(pal_actor)
	end
end

function PalLeader.RegisterOnWildLeaderFoundCb(callback)
	table.insert(wild_leader_found_cbs, callback)
end

function PalLeader.OnPalInitHookFired(pal_actor)
	local instance_id = PalUtils.GetPalInstanceIdFromActor(pal_actor)

	if instance_id and captured_leaders[instance_id] then
		local indiv_id = CDO.pal_utility:GetIndividualIDByActor(pal_actor)
		LeaderStateManager.AddLeader(indiv_id)

		-- On Singleplayer and MP enabled worlds without clients, the controller cache is empty so this doesn't do anything
		BroadcastLeaderPalId(indiv_id)
	end
end

function PalLeader.Init()
	Server.RegisterSAPCallback(OnServerAcknowledgePossesssion)

	-- In this hook we determine which pal within a group is a leader
	NotifyOnNewObject(UOBJ_PATHS.BP_AIACTION_WILD_LIFE,
		function()
			RegisterHook(
				FUNC_PATHS.BP_WILD_LIFE_ACTION_START,
				function(Context, ControlledPawn)
					local pal_actor = ControlledPawn:get()
					if not IsValid(pal_actor) then
						return
					end

					local char_param = pal_actor:GetCharacterParameterComponent()
					local pal_controller = pal_actor:GetController()

					if not IsValid(pal_controller) or not IsValid(char_param) then
						return
					end

					if not pal_controller:GetIsSquadBehaviour() or not pal_controller:IsLeader() then
						return
					end

					OnWildLeaderFound(pal_actor)
				end
			)
			return true
		end
	)

	-- If a wild gorup leader pal is captured save it's id as the leader info is lost afer capturing
	RegisterHook(
		FUNC_PATHS.PAL_CAPTURE_SUCCESS,
		function(Context, AttackerPlayer, Monster)
			local pal_actor = Monster:get()

			if IsValid(pal_actor) then
				local instance_id = PalUtils.GetPalInstanceIdFromActor(pal_actor)

				if instance_id and LeaderStateManager.IsLeader(instance_id) then
					SaveCapturedGroupLeader(instance_id)
					DebugLog("Pal Utility Capture success: %s | Scale: %f | ID: %s", pal_actor:GetFullName(), pal_actor.mesh.RelativeScale3D.X, instance_id)
				end
			end
		end
	)

	-- Client asks whether a specific pal id belongs to a leader by calling controller:RequestDebugGuildInfo_ToServer which runs on the server
	-- So we intercept the server's function and check if the id belongs to a pal. If so, we send confirmation via SendLog_ToClient
	RegisterHook(
		FUNC_PATHS.REQUEST_DEBUG_GUILD_INFO_TO_SERVER,
		function(Context, GuildId)
			local controller = Context:get()
			if not IsValid(controller) then
				DebugLog("CONTROLLER NOT VALID")
				return
			end
			local instance_guid = GuildId:get()
			local instance_id = CDO.kismet_guid_lib:Conv_GuidToString(instance_guid):ToString()

			DebugLog("Leader query received | ID=%s", instance_id)

			local indiv_id = LeaderStateManager.GetLeader(instance_id)
			if indiv_id then
				DebugLog("Pal is a leader")
				controller:SendLog_ToClient(0, 0, LEADER_CONFIRM_PAYLOAD_HEADER, { IndividualId = indiv_id })
			end
		end
	)

	RegisterHook(
		FUNC_PATHS.CALCULATE_DAMAGE,
		function()
		end,
		function(Context, ReturnValue, DamageInfo, Defender)
			local damage_info = DamageInfo:get()
			local defender = Defender:get()

			DebugLog(" IN CALC DAMAGE ")
			if not damage_info or not IsValid(defender) then
				return
			end

			local attacker = damage_info.Attacker
			local damage = tonumber(ReturnValue:get())

			if not damage or damage <= 0 then
				return
			end

			local is_player_attacker = CDO.pal_utility:IsPlayerControlActor(attacker)
			local is_wild_leader_def = PalUtils.IsWildLeader(defender)

			-- Player -> wild leader
			if is_player_attacker and is_wild_leader_def then
				local new_damage = math.max(1, math.floor(damage * 0.01 + 0.5))

				ReturnValue:set(new_damage)

				DebugLog(
					"Leader damage reduced: %i -> %i",
					damage,
					new_damage
				)

				return
			end

			-- Wild leader -> player
			if PalUtils.IsWildLeader(attacker) and CDO.pal_utility:IsPlayerControlActor(defender) then
				local new_damage = math.max(1, math.floor(damage * 1.5 + 0.5))

				ReturnValue:set(new_damage)

				DebugLog(
					"Leader damage increased: %i -> %i",
					damage,
					new_damage
				)
			end
		end
	)
end

return PalLeader
