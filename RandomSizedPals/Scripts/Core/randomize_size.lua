---@class RandomizeSize
local RandomizeSize = {}

local ModConfigManager = require("Managers.mod_config_manager")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local PalUtils = require("Utils.pal_utils")
local UPaths = require("Constants.upaths")

-- Aliases used often
local Log = CoreUtils.Log
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local FUNC_PATHS = UPaths.FUNC_PATHS
local UObjects = UnrealUtils.UObjects

-- Local vars and funcs
local mod_config = ModConfigManager.GetConfig()
local UNSIGNED_MAX = 4294967296
local MIN_PAL_SCALE = 0.1
-- This is subtracted from non leader pals when randmoizing so the leader pal is guaranteed to standout
local LEADER_PAL_SCALE_DIFF = 0.2

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

	if CoreUtils.debug_logging then
		DebugLog(
			"%s | ID= %s | %.4f -> %.4f",
			pal_actor:GetFullName(),
			PalUtils.GetUniquePalIDFromActor(pal_actor),
			old_scale,
			new_scale.X
		)
	end
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

	local unique_id = PalUtils.GetUniquePalIDFromActor(pal_actor)

	if not unique_id then
		return
	end

	local size_range = nil
	local new_scale = 1.0
	local pal_size_key = ""

	-- Boss pals don't expose their original, unscaled size category. So we have to get that from their TribeID information
	if PalUtils.IsBossIncludingRare(static) then
		local monster_param_dt = UObjects[UOBJ_PATHS.GAME_MONSTER_PARAM_DT]
		local out_tribe_id_name = {}

		PalUtils.pal_utility:GetTribeIDNameFromParameter(pal_actor, indiv_param, out_tribe_id_name)
		local tribe_id_name = out_tribe_id_name.outTribeIDName

		if not tribe_id_name then
			DebugLog("Failed to get Tribe ID Name in RandomizeSize")
			return
		end

		local tribe_id_str = tribe_id_name:ToString()
		DebugLog("Boss Pal: %s | ID: %s", pal_actor:GetFullName(), PalUtils.GetUniquePalIDFromActor(pal_actor))

		local row = monster_param_dt:FindRow(tribe_id_str)

		if not row or not row.Size then
			return
		end

		pal_size_key = PalUtils.PAL_SIZE[row.Size]
	else
		pal_size_key = PalUtils.PAL_SIZE[tonumber(static.Size)]
	end

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
				local static = pal_actor.StaticCharacterParameterComponent
				local pal_controller = pal_actor:GetController()

				local is_leader = IsValid(static) and IsValid(pal_controller) and pal_controller:GetIsSquadBehaviour() and pal_controller:IsLeader()
				ApplySize(pal_actor, char_param, is_leader)
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

function RandomizeSize.Init()
	ModConfigManager.RegisterHotReloadCallback(OnHotReload)

	-- Apply size variation after pals initialize
	RegisterHook(
		FUNC_PATHS.ON_PAL_INIT,
		function()
		end,
		function(Context, Character)
			local char_param = Context:get()
			local actor = Character:get()

			if not IsValid(char_param) or not IsValid(actor) then
				return
			end

			-- If it's not a "Pal" no need to apply size variation
			if not PalUtils.pal_utility:IsPalMonster(actor) then
				return
			end

			ApplySize(actor, char_param, false)
		end
	)

	--Make the leader pal the largest
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

					ApplySize(pal_actor, char_param, true)
				end
			)
			Log("IN NOTIFY IN NOTIFY")
			return true
		end
	)
end

return RandomizeSize
