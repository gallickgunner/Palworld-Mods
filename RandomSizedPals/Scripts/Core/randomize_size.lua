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


local function FnvHash(text)
	local hash = 2166136261
	local fnv_prime = 16777619

	for i = 1, #text do
		hash = hash ~ string.byte(text, i)
		hash = (hash * fnv_prime) & 0xFFFFFFFF
	end

	return hash
end

--return the hashed id from Fnv1a32 in range 0-1
local function NormalizedRange(unique_id)
	return FnvHash(unique_id) / UNSIGNED_MAX
end

local function GetVariationRange(pal_size)
	return mod_config.size_variation[PalUtils.PAL_SIZE[pal_size]] or mod_config.size_variation.M
end

local function GetOffset(unique_id, pal_size)
	local range = GetVariationRange(pal_size)
	local unit = NormalizedRange(unique_id)

	return range.min + unit * (range.max - range.min)
end

local function IsBoss(static)
	return static:IsBossPal_Database_ExceptRare()
		or static:IsRaidBossPal()
		or static:IsTowerBossPal()
		or static:IsPredatorBossPal()
end

local function ApplyRandomSize(pal_actor, unique_id)
	local mesh = pal_actor.Mesh
	local static = pal_actor.StaticCharacterParameterComponent

	if not IsValid(mesh) then
		return
	end

	local base_scale = mesh.DefaultScale3D

	if not base_scale
		or base_scale.X <= 0
		or base_scale.Y <= 0
		or base_scale.Z <= 0 then
		return
	end

	local pal_size = tonumber(static.Size)

	if pal_size == nil then
		return
	end

	local offset = GetOffset(unique_id, pal_size)

	local new_scale = {
		X = math.max(mod_config.minimum_scale, base_scale.X + offset),
		Y = math.max(mod_config.minimum_scale, base_scale.Y + offset),
		Z = math.max(mod_config.minimum_scale, base_scale.Z + offset)
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

	--DebugLog(
	--	"%s | ID= %s | Size=%s | offset=%+.4f | %.4f -> %.4f",
	--	pal_actor:GetFullName(),
	--	unique_id,
	--	PalUtils.PAL_SIZE[pal_size],
	--	offset,
	--	base_scale.X,
	--	new_scale.X
	--)
	--DebugLog("Applying Size to Pal : %s | ID: %s | Address: %s", pal_actor:GetFullName(), unique_id, tostring(pal_actor:GetAddress()))
end

local function OnHotReload(updated_config)
	mod_config = updated_config
end

function RandomizeSize.Init()
	ModConfigManager.RegisterHotReloadCallback(OnHotReload)

	-- Apply size variation after pals initialize
	RegisterHook(
		FUNC_PATHS.ON_PAL_INIT,
		function(Context, Character)
			local actor = Character:get()

			if not IsValid(actor) then
				return
			end

			-- If it's not a "Pal" no need to apply size variation
			if not PalUtils.pal_utility:IsPalMonster(actor) then
				return
			end

			local unique_pal_id = PalUtils.GetUniquePalIDFromActor(actor)

			if not unique_pal_id then
				return
			end

			-- Deliberately delay the application of size offset till 2 frames
			-- This gives us room in case I decide to add other scale based mod that need
			-- to run before this one.
			--
			-- Also if other scale based mods immediately apply scale, then this will also ensure
			-- our mod runs after them.
			--ExecuteInGameThreadAfterFrames(2,
			--	function()
			if not IsValid(actor) then
				return
			end

			local static = actor.StaticCharacterParameterComponent

			if not IsValid(static) then
				return
			end

			-- Keep Alpha/Boss, Raid, Tower and Predator encounters untouched.
			-- ExceptRare intentionally allows Lucky/Rare Pals to vary.
			if IsBoss(static) then
				return
			end

			ApplyRandomSize(actor, unique_pal_id)
			--end
			--)
		end
	)
end

return RandomizeSize
