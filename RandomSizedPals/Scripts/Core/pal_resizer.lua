---@class PalResizer
local PalResizer = {}

local ModConfigManager = require("Managers.mod_config_manager")
local PalLeaderServer = require("Server.pal_leader")
local LeaderStateManager = require("Network.leader_state_manager")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local PalUtils = require("Utils.pal_utils")
local UPaths = require("Constants.upaths")
local UEHelpers = require("UEHelpers")
local CDO = require("Utils.cdo")
-- Aliases used often
local Log = CoreUtils.Log
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local FUNC_PATHS = UPaths.FUNC_PATHS
local UObjects = UnrealUtils.UObjects

-- Local vars and funcs
local NETWORK_PAYLOAD_HEADER_PATTERN = "^RSP|"
local UNSIGNED_MAX = 4294967296
local MIN_PAL_SCALE = 0.1
-- This is subtracted from non leader pals when randmoizing so the leader pal is guaranteed to standout
local LEADER_PAL_SCALE_DIFF = 0.4

local mod_config = ModConfigManager.GetConfig()
local client_session =
{
	controller_address = nil,
	world_address = nil
}

local function FnvHash(text)
	local hash = 2166136261
	local fnv_prime = 16777619

	for i = 1, #text do
		hash = hash ~ string.byte(text, i)
		hash = (hash * fnv_prime) & 0xFFFFFFFF
	end

	return hash
end

local function GetCustomScale(unique_id, range, is_boss)
	-- Get normalized hashed id from Fnv1a32 in range 0-1
	local unit = FnvHash(unique_id) / UNSIGNED_MAX
	-- if not a boss, subtract a small value to ensure everybody is smaller than the leader and leader is visually distinguishable
	local max_val = is_boss and range.max or math.max(range.min, range.max - LEADER_PAL_SCALE_DIFF)
	return range.min + unit * (max_val - range.min)
end

local function GetSizeRange(pal_size_key, scp)
	if PalUtils.IsBossExcludingRare(scp) then
		return (mod_config.boss_pal_scales[pal_size_key] or mod_config.boss_pal_scales.M)
	elseif scp:IsRarePal() then
		return (mod_config.rare_pal_scales[pal_size_key] or mod_config.rare_pal_scales.M)
	else
		return (mod_config.normal_pal_scales[pal_size_key] or mod_config.normal_pal_scales.M)
	end
end

local function ApplyNewScale(pal_actor, scale)
	local mesh = pal_actor.Mesh
	local static = pal_actor.StaticCharacterParameterComponent
	local base_scale = mesh.DefaultScale3D

	if not base_scale
		or base_scale.X <= 0
		or base_scale.Y <= 0
		or base_scale.Z <= 0 then
		return
	end

	local old_scale = base_scale.X

	local new_scale = {
		X = math.max(MIN_PAL_SCALE, scale),
		Y = math.max(MIN_PAL_SCALE, scale),
		Z = math.max(MIN_PAL_SCALE, scale)
	}

	local ratio = new_scale.X / base_scale.X
	mesh.DefaultScale3D = new_scale

	if mesh:IsRuntimeScaleDefault() then
		mesh:SetRelativeScale3D(new_scale)
	end

	-- These affect various Pal Actions. Palworld scales these by the ratio when creating Alpha version of Pals.
	-- So far I found these used in various Active Partner skills logic, death, coop actions etc.
	static.MeshCapsuleHalfHeight = static.MeshCapsuleHalfHeight * ratio
	static.MeshCapsuleRadius = static.MeshCapsuleRadius * ratio
	--[[
	if CoreUtils.debug_logging then
		DebugLog(
			"%s | ID= %s | %.4f -> %.4f",
			pal_actor:GetFullName(),
			PalUtils.GetUniquePalIDFromActor(pal_actor),
			old_scale,
			new_scale.X
		)
	end--]]

	local individual_id = CDO.pal_utility:GetIndividualIDByActor(pal_actor)
	local player_uid = CDO.kismet_guid_lib:Conv_GuidToString(individual_id.PlayerUId):ToString()
	local instance_id = CDO.kismet_guid_lib:Conv_GuidToString(individual_id.InstanceId):ToString()
	local unique_id = CDO.pal_utility:Convert_PalInstanceIDToString(individual_id):ToString()

	--DebugLog("Wild Pal Init | Name:%s | InstanceId=%s", pal_actor:GetFullName(), instance_id)
end

local function ApplySize(pal_actor, char_param, is_leader)
	local static = pal_actor.StaticCharacterParameterComponent
	local indiv_param = char_param:GetIndividualParameter()

	if not IsValid(indiv_param) or not IsValid(static) then
		return
	end

	if PalUtils.IsBossExcludingRare(static) and not mod_config.boss_pal_scales.enabled then
		return
	end

	if static:IsRarePal() and not mod_config.rare_pal_scales.enabled then
		return
	end

	local unique_id = PalUtils.GetPalInstanceIdFromActor(pal_actor)

	if not unique_id then
		return
	end

	local size_range = nil
	local new_scale = 1.0
	local pal_size_key = ""

	local size = PalUtils.GetPalSize(pal_actor)

	if not size then
		size = 2
	end

	pal_size_key = PalUtils.PAL_SIZE[PalUtils.GetPalSize(pal_actor)]
	size_range = GetSizeRange(pal_size_key, static)

	if is_leader then
		ApplyNewScale(pal_actor, size_range.max)
		return
	end

	new_scale = GetCustomScale(unique_id, size_range, PalUtils.IsBossExcludingRare(static))
	ApplyNewScale(pal_actor, new_scale)
end

local function ReapplyAllScales()
	local pal_actors = FindAllOf("PalMonsterCharacter")

	if not pal_actors then
		DebugLog("No spawned Pal actors found during hot reload")
		return
	end

	local reapplied_count = 0

	for _, pal_actor in ipairs(pal_actors) do
		if IsValid(pal_actor) then
			local char_param = pal_actor:GetCharacterParameterComponent()

			if IsValid(char_param) then
				local instance_id = PalUtils.GetPalInstanceIdFromActor(pal_actor)
				ApplySize(pal_actor, char_param, LeaderStateManager.IsLeader(instance_id))
				reapplied_count = reapplied_count + 1
			end
		end
	end

	DebugLog("Reapplied scale to %d spawned Pals", reapplied_count)
end

local function OnHotReload(updated_config)
	mod_config = updated_config
	ReapplyAllScales()
end

local function OnWildLeaderFoundOnServer(pal_actor)
	if not IsValid(pal_actor) then
		return
	end

	local char_param = pal_actor:GetCharacterParameterComponent()

	if not IsValid(char_param) then
		return
	end

	ApplySize(pal_actor, char_param, true)
end

local function RegisterRemoteClientHooks()
	-- We reset our runtime leader state on remote clients whenever client disconnect/reconnect. This is so
	-- when a client joins a different world it rebuilds a fresh runtime leader cache
	RegisterHook(
		FUNC_PATHS.CLIENT_RESTART,
		function(Context)
			local controller = Context:get()
			local world = controller:GetWorld()

			-- Only work for remote clients
			if CDO.pal_utility:IsServer(controller) then
				return
			end

			if not IsValid(world) then
				DebugLog("World wasn't valid at Client Restart Hook")
				return
			end

			local is_server = CDO.pal_utility:IsServer(controller)
			DebugLog("Is Server: %s", tostring(is_server))

			local controller_address = controller:GetAddress()
			local world_address = world:GetAddress()

			if client_session.controller_address == controller_address and client_session.world_address == world_address then
				return
			end

			-- Reset if this is a new world or the controller is new
			LeaderStateManager.ResetState()
			client_session.controller_address = controller_address
			client_session.world_address = world_address
			DebugLog("New client session | controller=%s | world=%s", tostring(controller_address), tostring(world_address))
		end
	)

	-- This hook gets fired on remote clients only whenever the server calls player_controller:SendLog_ToClient
	-- We use this to get individual ids of leader pals that the server detects.
	RegisterHook(
		FUNC_PATHS.SEND_LOG_TO_CLIENT,
		function(Context, Priority, TextCategory, TextId, AdditionalData)
			local controller = Context:get()
			local text_id = TextId:get():ToString()
			local additional_data = AdditionalData:get()

			if not text_id:find(NETWORK_PAYLOAD_HEADER_PATTERN) then
				return
			end

			if not CDO.pal_utility:IsValidInstanceID(additional_data.IndividualId) then
				DebugLog("CLIENT RECEIVED AN INVALID INDIVIDUAL ID!")
				return
			end

			-- Reapply the correct size to leader if it's actor is present on clients
			local pal_instance_id = PalUtils.GetPalInstanceIdFromIndivId(additional_data.IndividualId)

			-- Add the temporary leader pal id on clients. We cant store the AdditionalData.IndividualId as that struct may be temporary just
			-- duration of the network message. We will store this instance_id's individual_id if the actor is already loaded or during PAL_INIT
			LeaderStateManager.AddTempLeaderInClient(pal_instance_id)

			DebugLog("RSP CLIENT MESSAGE | text_id=%s | message=%s", text_id, pal_instance_id)
			local character_manager = CDO.pal_utility:GetCharacterManager(controller)

			if not IsValid(character_manager) then
				return
			end

			local handle = character_manager:GetIndividualHandle(additional_data.IndividualId)

			if not IsValid(handle) then
				DebugLog("CLIENT | Handle was not valid for id: " .. pal_instance_id)
				return
			end

			local pal_actor = handle:TryGetIndividualActor()

			if not IsValid(pal_actor) then
				DebugLog("CLIENT | Actor was not valid for id: " .. pal_instance_id)
				return
			end

			local param = pal_actor:GetCharacterParameterComponent()

			if not IsValid(param) then
				DebugLog("CLIENT | Param was not valid for id: " .. pal_instance_id)
				return
			end

			LeaderStateManager.RemoveTempLeaderInClient(pal_instance_id)
			LeaderStateManager.AddLeader(CDO.pal_utility:GetIndividualIDByActor(pal_actor))
			ApplySize(pal_actor, param, true)
		end
	)
end

function PalResizer.Init()
	ModConfigManager.RegisterHotReloadCallback(OnHotReload)
	PalLeaderServer.RegisterOnWildLeaderFoundCb(OnWildLeaderFoundOnServer)
	RegisterRemoteClientHooks()

	-- Apply size variation after pals initialize
	RegisterHook(
		FUNC_PATHS.ON_PAL_INIT,
		function()
		end,
		function(Context, Character)
			local char_param = Context:get()
			local pal_actor = Character:get()

			if not IsValid(char_param) or not IsValid(pal_actor) then
				return
			end

			-- If it's not a "Pal" no need to apply size variation
			if not CDO.pal_utility:IsPalMonster(pal_actor) then
				return
			end

			local is_server = CDO.pal_utility:IsServer(pal_actor)

			-- Do server's work in PalInit. The server mainly checks if the initializing pal is a captured wild leader pal.
			-- If so it adds that id to the leader state manager and broadcasts it to all remote clients.
			-- On remote clients this function won't do anything as the captured leader dataset is empty in their version of Server/pal_leader.lua
			if is_server then
				PalLeaderServer.OnPalInitHookFired(pal_actor)
			end
			DebugLog("Pal Init: " .. PalUtils.GetPalInstanceIdFromActor(pal_actor))

			local controller = CDO.pal_utility:GetLocalPlayerController(pal_actor)
			local indiv_id = CDO.pal_utility:GetIndividualIDByActor(pal_actor)
			local instance_id = PalUtils.GetPalInstanceIdFromIndivId(indiv_id)

			if not instance_id then
				DebugLog("Instance Id not valid after receiving confirmation")
				return
			end

			local is_leader, is_temp = LeaderStateManager.IsLeader(instance_id)

			if is_temp then
				LeaderStateManager.RemoveTempLeaderInClient(instance_id)
				LeaderStateManager.AddLeader(indiv_id)
			end

			if not is_server and not is_leader and IsValid(controller) then
				DebugLog("Requesting server for leader status for above id")
				-- We hack our way by using this function. By passing Pal instance id inplace of Guild Id, the native code doesn't send
				-- any info back as that guild wont' exist. Instead, we hook into that call on the server, receive our PalID and check if it's a leader.
				-- If so we send confirmation back via SendLog_ToClient
				controller:RequestDebugGuildInfo_ToServer(indiv_id.InstanceId)
			end

			ApplySize(pal_actor, char_param, is_leader)
		end
	)

	RegisterEndPlayPreHook(
		function(Context, EndPlayReason)
			local actor = Context:get()

			if not IsValid(actor) then
				return
			end

			if not CDO.pal_utility:IsPalMonster(actor) then
				return
			end

			local instance_id = PalUtils.GetPalInstanceIdFromActor(actor)
			if instance_id and CDO.pal_utility:IsServer(actor) then
				LeaderStateManager.RemoveLeader(instance_id)
			end

			--DebugLog(
			--	"ACTOR END PLAY | %s | ID: %s | reason=%s",
			--	actor:GetFullName(),
			--	PalUtils.GetStringPalInstanceIDFromActor(actor),
			--	tostring(EndPlayReason:get())
			--)
		end
	)
end

return PalResizer
