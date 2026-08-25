local MOD_NAME = "RandomSizedPals"
local PAL_INITIALIZED = "/Script/Pal.PalCharacterParameterComponent:OnInitializedCharacter"

local UNSIGNED_MAX = 4294967296
local PAL_SIZE = {}
local DEFAULT_CONFIG = {
	SizeVariation = {
        XS = {
            min = -0.15,
            max = 0.35
        },
        S = {
            min = -0.2,
            max = 0.4
        },
        M = {
            min = -0.5,
            max = 0.4
        },
        L = {
            min = -0.5,
            max = -0.15
        },
        XL = {
            min = -0.5,
            max = -0.2
        }
    },
    MinimumScale = 0.1,		
    DebugLogging = false
}

local Config = DEFAULT_CONFIG

local CONFIG_PATH = nil
local local_player_controller = nil


local function log(message)
    print(string.format("[%s] %s\n", MOD_NAME, tostring(message)))
end

local function debug_log(message)
    if Config.DebugLogging then
        log(message)
    end
end


local function get_scripts_dir()
    local source = debug.getinfo(1, "S").source or ""
    source = source:gsub("^@", "")

    return source:match("^(.*)[/\\][^/\\]+$") or "."
end


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

local function validate_config(config)
    if type(config) ~= "table" then
        error("config.lua must return a table")
    end

    if type(config.SizeVariation) ~= "table" then
        error("SizeVariation must be a table")
    end

    for _, name in ipairs({ "XS", "S", "M", "L", "XL" }) do
        local range = config.SizeVariation[name]

        if type(range) ~= "table" then
            error("SizeVariation." .. name .. " must be a table")
        end

        range.min = tonumber(range.min)
        range.max = tonumber(range.max)

        if range.min == nil or range.max == nil then
            error("SizeVariation." .. name .. ".min/max must be numbers")
        end

        if range.min > range.max then
            error("SizeVariation." .. name .. ".min cannot be greater than max")
        end
    end

    config.MinimumScale = tonumber(config.MinimumScale)

    if not config.MinimumScale or config.MinimumScale <= 0 then
        error("MinimumScale must be greater than zero")
    end
		
		return config
end

local function config_text()
    return [[-- RandomSizedPals
--
-- SizeVariation values are ADDITIVE offsets from the Pal's native value for
-- DefaultScale3D.
--
-- Example:
--   XS = { min = 0.0, max = 0.5 }
--   native 1.0 -> final 1.0 .. 1.5
--
--   XL = { min = -0.5, max = 0.0 }
--   native 4.0 -> final 3.5 .. 4.0
--
-- These offsets can also be used to downscale Pals belonging to a specific category by setting max < 0.
-- For e.g, setting XL = { min = -0.5, max = -0.2} will scale all Pals in XL category 
-- such that they fall in the range 0.5 - 0.8 as the default scale for normal non-boss pals is 1.0.
--
-- Likewise, you can also use the opposite setting to upscale native Pals by setting min > 0
-- In any case, just make sure that "min" is less than "max". Both can be negative or positive.
--
-- Alpha/Boss, Raid Boss, Tower Boss and Predator Boss Pals are excluded.
-- Lucky/Rare Pals are intentionally allowed to vary.

return {
    SizeVariation = {
        XS = {
            min = -0.15,
            max = 0.35
        },
        S = {
            min = -0.2,
            max = 0.4
        },
        M = {
            min = -0.5,
            max = 0.4
        },
        L = {
            min = -0.5,
            max = -0.15
        },
        XL = {
            min = -0.5,
            max = -0.2
        }
    },
    MinimumScale = 0.1,		
    DebugLogging = false
}
]]
end

local function config_exists()
    local file = io.open(CONFIG_PATH, "r")

    if not file then
        return false
    end

    file:close()
    return true
end

local function create_default_config()
    if config_exists() then
        return true
    end

    local temporary_path = CONFIG_PATH .. ".tmp"
    local file = io.open(temporary_path, "w")

    if not file then
        return false, "Could not create " .. temporary_path
    end

    local wrote = file:write(config_text())
    file:close()

    if not wrote then
        os.remove(temporary_path)
        return false, "Could not write default config"
    end

    local renamed = os.rename(temporary_path, CONFIG_PATH)

    if not renamed then
        os.remove(temporary_path)
        return false, "Could not rename generated config to config.lua"
    end

    log("Generated config.lua beside main.lua.")
    return true
end

local function read_config()
    if not config_exists() then
        local created, create_error = create_default_config()

        if not created then
            return nil, create_error
        end
    end

    local ok, result = pcall(dofile, CONFIG_PATH)

    if not ok then
        return nil, "Could not load config.lua: " .. tostring(result)
    end

    return validate_config(result)
end

local function load_initial_config()
    local loaded_config, err = read_config()

    if loaded_config then
				log("Using the pre-existing config file that was found.")
        Config = loaded_config
        return
    end

    log(err)
    log("Using built-in defaults.")
    Config = DEFAULT_CONFIG
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
    return Config.SizeVariation[size_name(pal_size)]
        or Config.SizeVariation.M
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
        X = math.max(Config.MinimumScale, base_scale.X + offset),
        Y = math.max(Config.MinimumScale, base_scale.Y + offset),
        Z = math.max(Config.MinimumScale, base_scale.Z + offset)
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

CONFIG_PATH = get_scripts_dir() .. "/config.lua"
load_initial_config()
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