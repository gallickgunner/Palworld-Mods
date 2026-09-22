---@class PalVisuals
local PalVisuals = {}

local ModConfigManager = require("Managers.mod_config_manager")
local PalTraits = require("Server.pal_traits")
local PalLifeCycle = require("SharedHooks.pal_lifecycle")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local PalUtils = require("Utils.pal_utils")
local UPaths = require("Constants.upaths")
local Constants = require("Constants.constants")
local TrustGrowth = require("Core.trust_growth")
local CDO = require("Utils.cdo")
local Server = require("Server.server")

-- Aliases used often
local Log = CoreUtils.Log
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local Clamp = CoreUtils.Clamp
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local FUNC_PATHS = UPaths.FUNC_PATHS
local UObjects = UnrealUtils.UObjects

-- Local vars and funcs
local VALUE_PARAM = FName("Value")
local SATURATION_PARAM = FName("Saturation")
local CHANGE_COLOR_PARAM = FName("ChangeColor")
local CHANGE_COLOR_RATE_PARAM = FName("ChangeColor Rate")
local CHANGE_COLOR_MASK_PARAM = FName("ChangeColor Mask")
local BODY_MATERIAL_BASE_NAME = "MI_PalLit_CharacterBodyBase"

local DEFAULT_SATURATION_VAL = 0.0
local DEFAULT_VALUE_VAL = 1.2
local DEFAULT_COLOR_CHANGE_RATE = 0.0

local LEADER_PASSIVE_SKILL_NAME = Constants.LEADER_PASSIVE_SKILL_NAME
local MIN_PAL_SCALE = 0.1
local DEFAULT_GROWTH_EXPONENT = 1.3

local mod_config = ModConfigManager.GetConfig()
local scaled_leaders = {}
local client_session =
{
	controller_address = nil,
	world_address = nil
}


local function GetFriendshipGrowthProgress(indiv_param, world_context)
	if not IsValid(indiv_param) then
		return 0.0
	end

	local friendship_point = indiv_param:GetFriendshipPoint()
	local friendship_rank = indiv_param:GetFriendshipRank()

	-- Negative friendship is below our growth baseline.
	if friendship_rank < 0 or friendship_point <= 0 then
		return 0.0
	end

	local database = CDO.pal_utility:GetDatabaseCharacterParameter(world_context)

	if not IsValid(database) then
		return 0.0
	end

	local max_rank = database:GetMaxFriendshipRank()

	if max_rank <= 0 then
		return 0.0
	end

	if friendship_rank >= max_rank then
		return 1.0
	end

	local rank_progress = Clamp(database:CalcFriendshipProgress(friendship_point), 0.0, 1.0)
	local growth_progress = (friendship_rank + rank_progress) / max_rank

	return Clamp(growth_progress, 0.0, 1.0)
end

local function GetGrowthExponent(start_scale, target_scale, ride_scale)
	if not ride_scale or start_scale >= ride_scale or ride_scale >= target_scale then
		return DEFAULT_GROWTH_EXPONENT
	end

	local ride_fraction = (ride_scale - start_scale) / (target_scale - start_scale)
	ride_fraction = Clamp(ride_fraction, 0.0, 0.999999)

	local required_exponent = math.log(1.0 - ride_fraction) / math.log(1.0 - mod_config.rideability.size_eligiblity_by_trust_progression)

	-- 30% is the latest target, not something we force a nearly rideable Pal to wait for.
	return math.max(DEFAULT_GROWTH_EXPONENT, required_exponent)
end

local function GetGrowthScale(start_scale, target_scale, ride_scale, growth_progress)
	if target_scale <= start_scale then
		return start_scale
	end

	growth_progress = Clamp(growth_progress, 0.0, 1.0)

	local exponent = GetGrowthExponent(start_scale, target_scale, ride_scale)
	local scale_progress = 1.0 - ((1.0 - growth_progress) ^ exponent)

	return start_scale + ((target_scale - start_scale) * scale_progress)
end

local function FnvHash(id_str)
	id_str = id_str
	local hash = 2166136261
	local fnv_prime = 16777619

	for i = 1, #id_str do
		hash = hash ~ string.byte(id_str, i)
		hash = (hash * fnv_prime) & 0xFFFFFFFF
	end

	return hash
end

local function GetWeightedColor(unique_id, colors)
	-- Find weighted color using Gumbel-Max trick
	local selected_color = nil
	local best_score = math.huge

	for _, color in ipairs(colors) do
		local weight = color.weight or 1.0

		if weight > 0.0 then
			local hash = FnvHash(unique_id .. color.id)

			local unit = hash / Constants.UNSIGNED_MAX
			local score = -math.log(unit) / weight

			if score < best_score then
				best_score = score
				selected_color = color
			end
		end
	end

	if selected_color then
		return CDO.kismet_math_lib:MakeColor(selected_color.r, selected_color.g, selected_color.b, 1.0)
	else
		return nil
	end
end

local function IsBodyBaseMaterial(material)
	if not IsValid(material) then
		return false
	end

	local species_material = material.Parent

	if not IsValid(species_material) then
		return false
	end

	-- Prevent things such as SamuraiDog's weapon, which also inherits BodyBase.
	if not string.find(species_material:GetFullName(), "_Body", 1, true) then
		return false
	end

	local current = species_material

	while IsValid(current) do
		if string.find(current:GetFullName(), BODY_MATERIAL_BASE_NAME, 1, true) then
			return true
		end

		local class_name = current:GetClass():GetFullName()

		if not string.find(class_name, "MaterialInstance", 1, true) then
			break
		end

		current = current.Parent
	end

	return false
end

local function GetDeterministicValue(unique_id, val_min, val_max)
	local hash = FnvHash(unique_id)
	local unit = hash / Constants.UNSIGNED_MAX
	local value = val_min + unit * (val_max - val_min)
	return value
end

local function GetUniqueScale(unique_id, range, is_boss)
	-- Get normalized hashed id from Fnv1a32 in range 0-1
	local unit = FnvHash(unique_id) / Constants.UNSIGNED_MAX
	-- if not a boss, subtract a small value to ensure everybody is smaller than the leader and leader is visually distinguishable
	local max_val = is_boss and range.max or math.max(range.min, range.max - mod_config.leader_pal_scale_offset)
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

local function ApplySize(pal_actor, is_leader)
	local static = pal_actor.StaticCharacterParameterComponent

	if not IsValid(static) then
		return false
	end

	if PalUtils.IsBossExcludingRare(static) and not mod_config.boss_pal_scales.enabled then
		return nil
	end

	if static:IsRarePal() and not mod_config.rare_pal_scales.enabled then
		return nil
	end

	local unique_id = PalUtils.GetPalInstanceIdFromActor(pal_actor)

	if not unique_id then
		return false
	end

	unique_id = unique_id .. mod_config.randomize_seed_size

	local size_range = nil
	local new_scale = 1.0
	local pal_size_key = ""

	local size = PalUtils.GetPalSize(pal_actor)

	if not size then
		return false
	end

	pal_size_key = PalUtils.PAL_SIZE[size]
	size_range = GetSizeRange(pal_size_key, static)

	if is_leader then
		ApplyNewScale(pal_actor, size_range.max)
		return true
	end

	new_scale = GetUniqueScale(unique_id, size_range, PalUtils.IsBossExcludingRare(static))

	-- If wild pal or pals grow with trust setting is disabled then just apply the scale
	if CDO.pal_utility:IsWildNPC(pal_actor) or not mod_config.trust.pals_grow_with_trust then
		ApplyNewScale(pal_actor, new_scale)
		return true
	end

	-- If captured pal, then grow based on trust value if setting enabled
	local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)

	if not IsValid(indiv_param) then
		return false
	end
	local target_scale = size_range.max
	local growth_progress = GetFriendshipGrowthProgress(indiv_param, pal_actor)
	local ride_scale = mod_config.rideability.min_ride_scales[pal_size_key]
	local final_scale = GetGrowthScale(new_scale, target_scale, ride_scale, growth_progress)

	ApplyNewScale(pal_actor, final_scale)
	return true
end

local function ApplyColor(pal_actor)
	local mesh = pal_actor.Mesh

	if not IsValid(mesh) then
		return
	end

	if PalUtils.IsBossExcludingRare(pal_actor.StaticCharacterParameterComponent) and not mod_config.color_variety.apply_color_to_bosses then
		return
	end

	local unique_id = PalUtils.GetPalInstanceIdFromActor(pal_actor)

	if not unique_id then
		return
	end

	unique_id = unique_id .. mod_config.randomize_seed_color

	local white_texture_mask = UObjects[UOBJ_PATHS.RES_WHITE_TEXTURE]
	if not IsValid(white_texture_mask) then
		DebugLog("WhiteSquareTexture not found for use as color mask when applying color")
		return
	end

	local color_settings = mod_config.color_variety
	local apply_color_roll = GetDeterministicValue(unique_id .. "_color_roll", 0.0, 1.0)

	-- This pal id failed to provide a high enough chance value so we skip applying color
	if apply_color_roll > color_settings.color_variation_chance then
		return
	end

	local material_count = mesh:GetNumMaterials()

	for i = 0, material_count - 1 do
		local material = mesh:GetMaterial(i)

		if not IsValid(material) then
			goto continue
		end

		if not IsBodyBaseMaterial(material) then
			goto continue
		end

		local saturation_orig = material:K2_GetScalarParameterValue(SATURATION_PARAM)
		local value_orig = material:K2_GetScalarParameterValue(VALUE_PARAM)

		local new_saturation = GetDeterministicValue(unique_id .. "_saturation", color_settings.saturation_min, color_settings.saturation_max)
		local value_offset = GetDeterministicValue(unique_id .. "_value", color_settings.value_offset_min, color_settings.value_offset_max)
		local new_value = value_orig + value_offset

		material:SetScalarParameterValue(VALUE_PARAM, new_value)
		material:SetScalarParameterValue(SATURATION_PARAM, new_saturation)

		local new_color = GetWeightedColor(unique_id .. "_color", color_settings.colors)

		if not new_color then
			return
		end

		local new_color_change_rate = GetDeterministicValue(unique_id .. "_color_lerp", color_settings.color_lerp_factor_min, color_settings.color_lerp_factor_max)
		material:SetTextureParameterValue(CHANGE_COLOR_MASK_PARAM, white_texture_mask)
		material:SetVectorParameterValue(CHANGE_COLOR_PARAM, new_color)
		material:SetScalarParameterValue(CHANGE_COLOR_RATE_PARAM, new_color_change_rate)

		::continue::
	end
end

local function ClearColorSettings(pal_actor)
	local mesh = pal_actor.Mesh

	if not IsValid(mesh) then
		return
	end

	if PalUtils.IsBossExcludingRare(pal_actor.StaticCharacterParameterComponent) and not mod_config.color_variety.apply_color_to_bosses then
		return
	end

	local white_texture_mask = UObjects[UOBJ_PATHS.RES_WHITE_TEXTURE]

	if not IsValid(white_texture_mask) then
		DebugLog("WhiteSquareTexture not found for use as color mask when applying color")
		return
	end

	local color_settings = mod_config.color_variety
	local unique_id = PalUtils.GetPalInstanceIdFromActor(pal_actor) .. mod_config.randomize_seed_color
	local apply_color_roll = GetDeterministicValue(unique_id .. "_color_roll", 0.0, 1.0)

	-- This pal id failed to provide a high enough chance value originally so we skip clearing as it is already default
	if apply_color_roll > color_settings.color_variation_chance then
		return
	end

	local material_count = mesh:GetNumMaterials()


	for i = 0, material_count - 1 do
		local material = mesh:GetMaterial(i)

		if not IsValid(material) then
			goto continue
		end

		if not IsBodyBaseMaterial(material) then
			goto continue
		end

		material:SetScalarParameterValue(SATURATION_PARAM, DEFAULT_SATURATION_VAL)
		material:SetScalarParameterValue(VALUE_PARAM, DEFAULT_VALUE_VAL)
		material:SetTextureParameterValue(CHANGE_COLOR_MASK_PARAM, white_texture_mask)
		material:SetVectorParameterValue(CHANGE_COLOR_PARAM, CDO.kismet_math_lib:MakeColor(0.0, 0.0, 0.0, 1.0))
		material:SetScalarParameterValue(CHANGE_COLOR_RATE_PARAM, DEFAULT_COLOR_CHANGE_RATE)

		::continue::
	end
end

local function RerandomizePals()
	local pal_actors = FindAllOf("PalMonsterCharacter")

	if not pal_actors then
		DebugLog("No spawned Pal actors found during hot reload")
		return
	end

	local reapplied_count = 0

	for _, pal_actor in ipairs(pal_actors) do
		if IsValid(pal_actor) then
			if not mod_config.randomize_captured_pals and CDO.pal_utility:IsOtomo(pal_actor) then
				goto continue
			end

			local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)

			if IsValid(indiv_param) then
				local is_leader = PalUtils.HasPassiveSkill(indiv_param, LEADER_PASSIVE_SKILL_NAME)
				ApplySize(pal_actor, is_leader)
				ClearColorSettings(pal_actor)
				reapplied_count = reapplied_count + 1
			end

			::continue::
		end
	end
	DebugLog("Reapplied scale to %d spawned Pals", reapplied_count)

	ExecuteInGameThreadWithDelay(1500,
		function()
			local pal_actors = FindAllOf("PalMonsterCharacter")

			if not pal_actors then
				DebugLog("No spawned Pal actors found during hot reload")
				return
			end

			for _, pal_actor in ipairs(pal_actors) do
				if IsValid(pal_actor) then
					if not mod_config.randomize_captured_pals and CDO.pal_utility:IsOtomo(pal_actor) then
						goto continue
					end

					local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)

					if IsValid(indiv_param) then
						local is_leader = PalUtils.HasPassiveSkill(indiv_param, LEADER_PASSIVE_SKILL_NAME)

						if mod_config.color_variety.enable_color_variation then
							if not mod_config.color_variety.apply_color_to_leaders and is_leader then
								goto continue
							end

							if PalUtils.IsBossExcludingRare(pal_actor.StaticCharacterParameterComponent) and not mod_config.color_variety.apply_color_to_bosses then
								goto continue
							end
							ApplyColor(pal_actor)
						end
					end
					::continue::
				end
			end
		end
	)
end

local function OnHotReload(updated_config)
	mod_config = updated_config
	RerandomizePals()
end

-- Apply size to wild leaders on the server. Server code initializes pals first and only later does the game sets who the leader is.
local function OnWildLeaderFoundOnServer(pal_actor)
	if not IsValid(pal_actor) then
		return
	end

	local char_param = pal_actor:GetCharacterParameterComponent()

	if not IsValid(char_param) then
		return
	end

	ApplySize(pal_actor, true)

	-- Clear Color Settings as we'd have applied in PAL_INIT when the leader wasn't identifiable
	ClearColorSettings(pal_actor)
end

local function ResetLeaderCacheOnClientHook()
	-- We reset our runtime leader state on remote clients whenever client disconnect/reconnect. This is so
	-- when a client joins a different world it rebuilds a fresh runtime scaled leader cache
	RegisterHook(
		FUNC_PATHS.CLIENT_RESTART,
		function(Context)
			local controller = Context:get()
			local world = controller:GetWorld()

			-- Only work for remote clients. As on singleplayer mode, local machine acts as the server thus
			-- leader cache will get cleared by the server hook
			if CDO.pal_utility:IsServer(controller) then
				return
			end

			if not IsValid(world) then
				DebugLog("World wasn't valid at Client Restart Hook")
				return
			end

			local controller_address = controller:GetAddress()
			local world_address = world:GetAddress()

			if client_session.controller_address == controller_address and client_session.world_address == world_address then
				return
			end

			-- Reset if this is a new world or the controller is new
			scaled_leaders = {}
			client_session.controller_address = controller_address
			client_session.world_address = world_address
			DebugLog("New client session | controller=%s | world=%s", tostring(controller_address), tostring(world_address))
		end
	)
end

local function ResetStateOnServerLoadedNewWorld(controller)
	scaled_leaders = {}
end

local function UpdateBasePalsGrowth(pal_actor)
	if not IsValid(pal_actor) or not pal_actor:IsInitialized() then
		return
	end

	local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)

	if not IsValid(indiv_param) or PalUtils.HasPassiveSkill(indiv_param, LEADER_PASSIVE_SKILL_NAME) then
		return
	end

	ApplySize(pal_actor, false)
end

local function CheckPartyPalsTrustGrowth()
	-- Since there is no proper hook to detect friendship point changes, In order to grow party pals, we apply size
	-- whenever they are summoned.

	-- This hook is used to detect party pals activation on the local client and other remote clients incase of a dedicated server
	RegisterHook(
		FUNC_PATHS.ON_REP_IS_PAL_ACTIVE_ACTOR,
		function(Context, PrevIsActiveActor)
			local pal_actor = Context:get()

			if not IsValid(pal_actor) then
				return
			end

			local prev_is_active = PrevIsActiveActor:get()
			local is_active = pal_actor:GetActiveActorFlag()

			if prev_is_active or not is_active then
				return
			end

			local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)
			if not IsValid(indiv_param) then
				return
			end

			if PalUtils.HasPassiveSkill(indiv_param, LEADER_PASSIVE_SKILL_NAME) then
				return
			end

			ApplySize(pal_actor, false)
		end
	)

	-- This hook is used to detect party pal activation on the server.
	-- Authoritative activation change.
	RegisterHook(
		FUNC_PATHS.SET_ACTIVE_ACTOR,
		function(Context, Active)
			local pal_actor = Context:get()
			local is_active = Active:get()

			if not IsValid(pal_actor) or not is_active or not CDO.pal_utility:IsOtomo(pal_actor) then
				return
			end

			local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)
			if not IsValid(indiv_param) then
				return
			end

			if PalUtils.HasPassiveSkill(indiv_param, LEADER_PASSIVE_SKILL_NAME) then
				return
			end

			ApplySize(pal_actor, false)
		end
	)
end

-- Apply size variation after pals initialize
---@param context CharInitContext
local function OnPalInit(context)
	local pal_actor = context.actor
	local char_param = context.char_param

	-- If it's not a "Pal" no need to apply size variation
	if not CDO.pal_utility:IsPalMonster(pal_actor) then
		return
	end

	local indiv_param = char_param:GetIndividualParameter()
	local instance_id = PalUtils.GetPalInstanceIdFromActor(pal_actor)

	if not instance_id or not IsValid(indiv_param) then
		return
	end

	local is_leader = PalUtils.HasPassiveSkill(indiv_param, LEADER_PASSIVE_SKILL_NAME)
	if not mod_config.randomize_captured_pals and CDO.pal_utility:IsOtomo(pal_actor) then
		DebugLog("PAL INIT | leader Skill found | ID: %s", instance_id)
		return
	end

	DebugLog("Applying Size | Pal ID = %s", instance_id)
	local success = ApplySize(pal_actor, is_leader)
	if success and is_leader then
		scaled_leaders[instance_id] = pal_actor:GetAddress()
	end

	if mod_config.color_variety.enable_color_variation then
		if not mod_config.color_variety.apply_color_to_leaders and is_leader then
			return
		end
		DebugLog("Applying Color | ID=%s", instance_id)
		ApplyColor(pal_actor)
	end
end

--Clean up alread scaled leaders cache. This is necessary as pal actor addresses can change meaning it got spawned/despawned and thus need to be resized.
-- If we don't clear our cache we will skip applying size in some wierd cases.
---@param context ActorEndPlayContext
local function OnPalActorEndPlay(context)
	if not CDO.pal_utility:IsPalMonster(context.actor) then
		return
	end

	local instance_id = PalUtils.GetPalInstanceIdFromActor(context.actor)

	if instance_id then
		scaled_leaders[instance_id] = nil
	end
end

function PalVisuals.Init()
	ModConfigManager.RegisterHotReloadCallback(OnHotReload)

	-- Reset Leader Cache on Server everytime a new world is loaded
	Server.RegisterOnNewWorldLoadedCallback(ResetStateOnServerLoadedNewWorld)

	--Reset Leader Cache on Clients
	ResetLeaderCacheOnClientHook()

	-- Apply size to wild leaders on server. On Clients we handle it by checking Leader pal unique skill in Pal Initializaiton and CharParam Replication hooks
	PalTraits.RegisterOnWildLeaderFoundCb(OnWildLeaderFoundOnServer)

	-- Apply size to base pals as trust growth for base pals is checked/updated every minute
	TrustGrowth.RegisterOnUpdateBasePalsGrowth(UpdateBasePalsGrowth)

	-- Check Trust growth and Apply Size to party pals on the server + client whenever they activate.
	CheckPartyPalsTrustGrowth()


	-- Apply size on pal character initialization.
	PalLifeCycle.RegisterOnInitializedCharacter(OnPalInit)

	-- Remove pal from leader cache once the actor expires.
	PalLifeCycle.RegisterOnActorEndPlay(OnPalActorEndPlay)


	-- In some cases our custom leader skill added from the server replicates on client after the actor has already initialized.
	-- In such cases we apply the leader size here as well
	RegisterHook(
		FUNC_PATHS.ON_CHAR_SAVE_PARAM_REPLICATE,
		function()
		end,
		function(Context)
			local indiv_param = Context:get()

			if not IsValid(indiv_param) or not PalUtils.HasPassiveSkill(indiv_param, LEADER_PASSIVE_SKILL_NAME) then
				return
			end

			local pal_actor = indiv_param:GetIndividualActor()
			local pal_id = PalUtils.GetPalInstanceIdFromIndivId(indiv_param.IndividualId)

			if not IsValid(pal_actor) or not pal_actor:IsInitialized() or not pal_id or scaled_leaders[pal_id] == pal_actor:GetAddress() then
				return
			end

			-- Clear Color Settings as we'd have applied in PAL_INIT when the leader wasn't identifiable
			DebugLog("Appyling size in Replicate Save Param | ID=%s", pal_id)
			ClearColorSettings(pal_actor)
			local success = ApplySize(pal_actor, true)
			DebugLog("Leader skill found for ID=%s | test_skill=%s | applySize success = %s", pal_id, LEADER_PASSIVE_SKILL_NAME, tostring(success))

			-- Since OnRep_SaveParam fires multiple times for a single pal we cache all scaled leaders to avoid applying size continuously for no reason
			if success == true then
				scaled_leaders[pal_id] = pal_actor:GetAddress()
			end
		end
	)
end

return PalVisuals
