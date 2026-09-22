---@class GroupBehavior
local GroupBehavior = {}

local CDO = require("Utils.cdo")
local PalUtils = require("Utils.pal_utils")
local UnrealUtils = require("Utils.unreal_utils")
local PalLifecycle = require("SharedHooks.pal_lifecycle")
local CoreUtils = require("Utils.core_utils")

local IsValid = UnrealUtils.IsValid
local DebugLog = CoreUtils.DebugLog

local follower_states = {}

local PATH_ACCEPTANCE_RADIUS = 200.0
local HEIGHT_UP_OFFSET = 1000.0
local HEIGHT_DOWN_OFFSET = 1000.0
local SPAWN_MAX_ATTEMPTS = 12


---@class PalSpawnRadius
---@field min_radius number
---@field max_radius number

---@type table<string, PalSpawnRadius>
local PAL_SPAWN_RADIUS = {
	None = {
		min_radius = 200.0,
		max_radius = 800.0,
	},
	XS = {
		min_radius = 100.0,
		max_radius = 500.0,
	},
	S = {
		min_radius = 170.0,
		max_radius = 650.0,
	},
	M = {
		min_radius = 300.0,
		max_radius = 900.0,
	},
	L = {
		min_radius = 550.0,
		max_radius = 1300.0,
	},
	XL = {
		min_radius = 600.0,
		max_radius = 1500.0,
	}
}




local function GetSquadPalActors(world_context, member_ids)
	local character_manager = CDO.pal_utility:GetCharacterManager(world_context)

	if not IsValid(character_manager) then
		return nil
	end

	local pal_actors = {}

	for _, member_id_param in ipairs(member_ids) do
		local member_id = member_id_param:get()

		if not member_id then
			return nil
		end

		local individual_handle = character_manager:GetIndividualHandle(member_id)

		if not IsValid(individual_handle) then
			return nil
		end

		local pal_actor = individual_handle:TryGetIndividualActor()

		if not IsValid(pal_actor) then
			return nil
		end

		pal_actors[#pal_actors + 1] = pal_actor
	end

	return pal_actors
end


local function ResolveReachableLocation(controller, candidate)
	if not IsValid(controller) or not candidate then
		return nil
	end

	local out_goal = {}

	local has_path = controller:IsExistPathForLocation_ForBP_HeightRangeCheck(
		candidate,
		PATH_ACCEPTANCE_RADIUS,
		HEIGHT_UP_OFFSET,
		HEIGHT_DOWN_OFFSET,
		out_goal
	)

	if not has_path then
		return nil
	end

	return out_goal
end


local function GenerateSpawnLocation(pal_actor, leader_location)
	local static_char_param = pal_actor.StaticCharacterParameterComponent

	if not IsValid(static_char_param) then
		return nil
	end

	local size_category = PalUtils.PAL_SIZE[static_char_param.Size]
	local radius_range = PAL_SPAWN_RADIUS[size_category]

	if not radius_range then
		return nil
	end

	local theta = math.random() * math.pi * 2.0

	local min_radius_squared = radius_range.min_radius * radius_range.min_radius
	local max_radius_squared = radius_range.max_radius * radius_range.max_radius
	local radius = math.sqrt(min_radius_squared + math.random() * (max_radius_squared - min_radius_squared))

	local candidate = {
		X = leader_location.X + radius * math.cos(theta),
		Y = leader_location.Y + radius * math.sin(theta),
		Z = leader_location.Z
	}

	return candidate
end


local function TeleportPal(pal_actor, resolved_location)
	local actor_location = pal_actor:K2_GetActorLocation()

	if not actor_location then
		return false
	end

	local floor_location = CDO.pal_utility:GetFloorLocationByActor(pal_actor)

	if not floor_location then
		return false
	end

	local actor_height_offset = actor_location.Z - floor_location.Z

	local teleport_location = {
		X = resolved_location.X,
		Y = resolved_location.Y,
		Z = resolved_location.Z + actor_height_offset
	}

	local actor_rotation = pal_actor:K2_GetActorRotation()

	return pal_actor:K2_TeleportTo(teleport_location, actor_rotation)
end


local function ScatterSquad(pal_actors, leader, squad_addr)
	local leader_location = leader:K2_GetActorLocation()

	if not leader_location then
		return false
	end

	for _, pal_actor in ipairs(pal_actors) do
		local actor_addr = pal_actor:GetAddress()

		if actor_addr ~= leader:GetAddress() and not follower_states[actor_addr] then
			local controller = pal_actor:GetController()

			if not IsValid(controller) then
				goto continue
			end

			for attempt = 1, SPAWN_MAX_ATTEMPTS do
				local candidate = GenerateSpawnLocation(pal_actor, leader_location)

				if candidate then
					local resolved_location = ResolveReachableLocation(controller, candidate)

					if resolved_location and TeleportPal(pal_actor, resolved_location) then
						follower_states[actor_addr] = true
						break
					end
				end
			end

			::continue::
		end
	end

	return true
end


---@param context WLActionStartContext
local function TryScatterSquad(context)
	local leader_actor = context.actor
	local controller = leader_actor:GetController()

	if not IsValid(controller) or not controller:GetIsSquadBehaviour() or not controller:IsLeader() then
		return
	end

	local squad = controller:GetSquad()

	if not IsValid(squad) then
		return
	end

	local actor_address = leader_actor:GetAddress()
	local state = follower_states[actor_address]

	if state then
		return
	end

	local member_ids = {}
	squad:GetMemberID(member_ids)

	if #member_ids == 0 then
		return
	end

	local pal_actors = GetSquadPalActors(controller, member_ids)

	if not pal_actors then
		return
	end

	if #pal_actors ~= #member_ids then
		return
	end

	DebugLog("Scattering wild pal spawn locations")
	ScatterSquad(pal_actors, leader_actor, actor_address)
end

---@param context ActorEndPlayContext
local function CleanupStateOnActorEndPlay(context)
	local actor = context.actor

	if not CDO.pal_utility:IsPalMonster(actor) then
		return
	end

	local actor_address = actor:GetAddress()
	follower_states[actor_address] = nil
end

function GroupBehavior.Init()
	PalLifecycle.RegisterOnWildLifeActionStart(TryScatterSquad)
	PalLifecycle.RegisterOnActorEndPlay(CleanupStateOnActorEndPlay)
end

return GroupBehavior
