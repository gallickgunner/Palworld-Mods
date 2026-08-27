local Utils = require("Core.utils")

local PAL_INITIALIZED = "/Script/Pal.PalCharacterParameterComponent:OnInitializedCharacter"

local UNSIGNED_MAX = 4294967296
local PAL_SIZE = {}
local CONFIG_PATH = Utils.get_scripts_dir() .. "/config.lua"

local Config = nil
local log = Utils.log
local debug_log = Utils.debug_log

local function initialize_pal_size_enum()
	local size_enum = StaticFindObject("/Script/Pal.EPalSizeType")

	if not size_enum or not size_enum:IsValid() then
		error("Could not find /Script/Pal.EPalSizeType")
	end

	size_enum:ForEachName(function(name, value)
		local full_name =
			type(name) == "string"
			and name
			or name:ToString()

		local sanitized_name = full_name:match("::([^:]+)$")
		if sanitized_name then
			PAL_SIZE[sanitized_name] = tonumber(value)
		end
	end)

	for _, name in ipairs({ "None", "XS", "S", "M", "L", "XL" }) do
		if PAL_SIZE[name] == nil then
			error("EPalSizeType did not expose " .. name)
		end
	end
end

local function unsigned32(value)
	value = tonumber(value)

	if value == nil then
		return nil
	end

	return math.floor(value) % UNSIGNED_MAX
end

local function guid_key(guid)
	if not guid then
		return nil
	end

	local a = unsigned32(guid.A)
	local b = unsigned32(guid.B)
	local c = unsigned32(guid.C)
	local d = unsigned32(guid.D)

	if a == nil or b == nil or c == nil or d == nil then
		return nil
	end

	return string.format("%08X-%08X-%08X-%08X", a, b, c, d)
end

local function get_unique_palID(parameter)
	if not parameter or not parameter:IsValid() then
		return nil
	end

	local handle = parameter.IndividualHandle

	if not handle or not handle:IsValid() then
		return nil
	end

	local individual_id = handle:GetIndividualID()

	if not individual_id then
		return nil
	end

	local player_uid = guid_key(individual_id.PlayerUId)
	local instance_id = guid_key(individual_id.InstanceId)

	if not player_uid or not instance_id then
		return nil
	end

	return player_uid .. "/" .. instance_id
end

local function fnv1a32(text)
	local hash = 2166136261
	local fnv_prime = 16777619
	for i = 1, #text do
		hash = hash ~ string.byte(text, i)
		hash = (hash * fnv_prime) & 0xFFFFFFFF
	end

	return hash
end

--return the hashed id from fnv1a32 in range 0-1
local function normalized_range(unique_id)
	return fnv1a32(unique_id) / UNSIGNED_MAX
end

local function size_name(pal_size)
	if pal_size == PAL_SIZE.XS then
		return "XS"
	elseif pal_size == PAL_SIZE.S then
		return "S"
	elseif pal_size == PAL_SIZE.M then
		return "M"
	elseif pal_size == PAL_SIZE.L then
		return "L"
	elseif pal_size == PAL_SIZE.XL then
		return "XL"
	end

	return "None"
end

local function get_variation_range(pal_size)
	return Config.size_variation[size_name(pal_size)]
		or Config.size_variation.M
end

local function get_offset(unique_id, pal_size)
	local range = get_variation_range(pal_size)
	local unit = normalized_range(unique_id)

	return range.min + unit * (range.max - range.min)
end

local function is_boss(static)
	return static:IsBossPal_Database_ExceptRare()
		or static:IsRaidBossPal()
		or static:IsTowerBossPal()
		or static:IsPredatorBossPal()
end

local function apply_size(character, static, unique_id)
	local mesh = character.Mesh

	if not mesh or not mesh:IsValid() then
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

	local offset = get_offset(unique_id, pal_size)

	local new_scale = {
		X = math.max(Config.minimum_scale, base_scale.X + offset),
		Y = math.max(Config.minimum_scale, base_scale.Y + offset),
		Z = math.max(Config.minimum_scale, base_scale.Z + offset)
	}

	mesh.DefaultScale3D = new_scale

	if mesh:IsRuntimeScaleDefault() then
		mesh:SetRelativeScale3D(new_scale)
	end

	local ratio = new_scale.X / base_scale.X
	static.MeshCapsuleHalfHeight = static.MeshCapsuleHalfHeight * ratio
	static.MeshCapsuleRadius = static.MeshCapsuleRadius * ratio

	debug_log(string.format(
		"Size=%s | offset=%+.4f | %.4f -> %.4f | %s",
		size_name(pal_size),
		offset,
		base_scale.X,
		new_scale.X,
		unique_id
	))
end

Config = Utils.get_config(CONFIG_PATH)
initialize_pal_size_enum()

RegisterHook(
	PAL_INITIALIZED,
	function(Context, Character)
		local parameter = Context:get()
		local character = Character:get()

		if not character or not character:IsValid() then
			return
		end

		local unique_id = get_unique_palID(parameter)

		if not unique_id then
			return
		end

		-- Deliberately delay the application of size offset till 2 frames
		-- This gives us room in case I decide to add other scale based mod that need
		-- to run before this one.
		--
		-- Also if other scale based mods immediately apply scale, then this will also ensure
		-- our mod runs after them.
		ExecuteInGameThreadAfterFrames(2,
			function()
				if not character or not character:IsValid() then
					return
				end

				local static = character.StaticCharacterParameterComponent

				if not static
					or not static:IsValid()
					or static.IsPal ~= true then
					return
				end

				-- Keep Alpha/Boss, Raid, Tower and Predator encounters untouched.
				-- ExceptRare intentionally allows Lucky/Rare Pals to vary.
				if is_boss(static) then
					return
				end
				apply_size(character, static, unique_id)
			end
		)
	end
)

log("Loaded RandomSizedPals mod.")
