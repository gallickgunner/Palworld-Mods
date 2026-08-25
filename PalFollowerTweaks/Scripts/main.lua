local MOD_NAME = "PalFollowerTweaks"

local FUNNEL_FOLLOW_CLASS_NAME = "BP_AIAction_FunnelFollow_C"
local TARGET_NATIVE_BASE = "/Script/Pal.PalAIActionBase"
local FUNNEL_ACTION_START_BP = "/Game/Pal/Blueprint/Controller/AIAction/Otomo/BP_AIAction_OtomoFollow.BP_AIAction_OtomoFollow_C:ActionStart"
local FUNNEL_CHARACTER_NATIVE_NAME = "PalFunnelCharacter"
local FUNNEL_ON_ACTIVE = "/Script/Pal.PalFunnelCharacter:OnActive"

local DEFAULT_CONFIG = {
    Forward = { -600,-450,-450,-450,-600 },
    Right = { -500,-300,0,300,500 },
    NUM_ELEMENTS = 5,
    Scale = 0.7
}


local Config = DEFAULT_CONFIG
local CONFIG_PATH = nil
local local_player_controller = nil

local function log(message)
    print(string.format("[%s] %s\n", MOD_NAME, tostring(message)))
end

local function show_notification(message)
   if not local_player_controller
        or not local_player_controller:IsValid() then
        return
    end
		
    local_player_controller:AddKillLog_Client({
        LogType = 2,
        AttackerName = MOD_NAME,
        KilledCharacterName = tostring(message)
    })
end


local function get_scripts_dir()
    local source = debug.getinfo(1, "S").source or ""
    source = source:gsub("^@", "")

    return source:match("^(.*)[/\\][^/\\]+$") or "."
end


local function validate_config(config)
    if type(config) ~= "table" then
        return nil, "config.lua must return a table"
    end

    if type(config.Forward) ~= "table" then
        return nil, "Config.Forward must be a table"
    end

    if type(config.Right) ~= "table" then
        return nil, "Config.Right must be a table"
    end

    local num_elements = tonumber(config.NUM_ELEMENTS)

    if num_elements == nil
        or num_elements <= 0
        or num_elements % 1 ~= 0 then

        return nil, "NUM_ELEMENTS must be a positive integer"
    end

    local scale = tonumber(config.Scale)

    if scale == nil or scale <= 0 then
        return nil, "Scale must be a positive number"
    end

    local validated = {
        Forward = {},
        Right = {},
        NUM_ELEMENTS = num_elements,
        Scale = scale
    }

    for i = 1, num_elements do
        local forward = tonumber(config.Forward[i])
        local right = tonumber(config.Right[i])

        if forward == nil then
            return nil, string.format(
                "Config.Forward[%d] must be a number",
                i
            )
        end

        if right == nil then
            return nil, string.format(
                "Config.Right[%d] must be a number",
                i
            )
        end

        validated.Forward[i] = forward
        validated.Right[i] = right
    end

    return validated
end


local function config_text()
    return [[-- PalFollowerTweaks
--
-- Values are Unreal centimeters:
--   Forward: positive = in front, negative = behind
--   Right:   positive = right,    negative = left
--
-- Palworld has five Funnel formation slots. It selects one based on
-- GetIndexOfFunnelsWithinSameTrainer() and wraps after five.
--
-- Press F4 for hot reload.

return {		
		-- Vanilla defaults are [300, 150, 0, -150, 300]
    Forward = {
        -600,
        -450,
        -450,
        -450,
        -600
    },
		
		-- Vanilla defaults are [-100, -150, -200, -150, -100]
    Right = {
        -500,
        -300,
        0,
        300,
        500
    },
		
		--number of elements in the forward and right list. NO NEED TO CHANGE THIS NOW.
		--This is given for forward compatiblity incase Palworld officially increases party slots and formation slots.
		NUM_ELEMENTS = 5,
		
		-- scale of the following pals, 1.0 = 100%
		Scale = 0.7
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
        Config = loaded_config
        return
    end

    log(err)
    log("Using built-in defaults.")
    Config = DEFAULT_CONFIG
end


local function table_to_string(values, count)
    local parts = {}

    for i = 1, count do
        parts[i] = string.format("%.2f", values[i])
    end

    return "{ " .. table.concat(parts, ", ") .. " }"
end


local function is_funnel_follow_action(action)
    if not action or not action:IsValid() then
        return false
    end

    local class = action:GetClass()

    if not class or not class:IsValid() then
        return false
    end

    return class:GetFName():ToString() == FUNNEL_FOLLOW_CLASS_NAME
end


local function apply_offset(action)
    if not is_funnel_follow_action(action) then
        return false
    end
		
    local forward_list = action.TargetLocationDistanceForwardList
    local right_list = action.TargetLocationDistanceRightList

    if not forward_list or not right_list then
        log("FunnelFollow arrays were not available.")
        return false
    end

    local forward_count = forward_list:GetArrayNum()
    local right_count = right_list:GetArrayNum()

    local count = math.min(
        Config.NUM_ELEMENTS,
        forward_count,
        right_count
    )

    -- UE4SS TArray Lua access is 1-based.
    for i = 1, count do
        forward_list[i] = Config.Forward[i]
        right_list[i] = Config.Right[i]
    end

    log("Applied custom Funnel follow formation.")
    return true
end


local function apply_funnel_default_scale(character, update_visual)
    
		if not character or not character:IsValid() then
        return false
    end
		
    local mesh = character.Mesh
		local static = character.StaticCharacterParameterComponent

		if not static or not static:IsValid()then
				log("Can't access `StaticCharacterParameterComponent`")
				return
		end
				
    if not mesh or not mesh:IsValid() then
        return false
    end
		
		local old_scale = mesh.DefaultScale3D
		
		local new_scale = {
				X = Config.Scale,
				Y = Config.Scale,
				Z = Config.Scale
		}	
		
		local ratio = Config.Scale / old_scale.X
		
    mesh.DefaultScale3D = new_scale

    -- F4 hot reload will find a Funnel that is already fully active. In that case
    -- update the current visual too, provided no runtime scale effect is active.
    if update_visual and mesh:IsRuntimeScaleDefault() then
        mesh:SetRelativeScale3D(new_scale)
    end
				
		static.MeshCapsuleHalfHeight = static.MeshCapsuleHalfHeight * ratio
		static.MeshCapsuleRadius = static.MeshCapsuleRadius * ratio
		
    log(string.format(
        "Applied Funnel scale baseline: "
        .. "%.3f %.3f %.3f -> %.3f %.3f %.3f",
        old_scale.X,
        old_scale.Y,
        old_scale.Z,
        new_scale.X,
        new_scale.Y,
        new_scale.Z
    ))

    return true
end


local function apply_offset_to_existing()
    local actions = FindAllOf(FUNNEL_FOLLOW_CLASS_NAME)

    if not actions then
        return
    end

    for _, action in ipairs(actions) do
        if action and action:IsValid() then
            apply_offset(action)
        end
    end
end


local function apply_scale_to_existing()
    local characters = FindAllOf(FUNNEL_CHARACTER_NATIVE_NAME)

    if not characters then
        return
    end

    for _, character in ipairs(characters) do       
				apply_funnel_default_scale(character,true)
    end
end


local function hot_reload_config()
    local new_config, err = read_config()

    if not new_config then
        log("Hot reload failed: " .. tostring(err))
        log("Keeping current config.")
        return
    end

    Config = new_config

    log("Hot reloading config.lua...")

    ExecuteInGameThread(function()
        apply_offset_to_existing()
        apply_scale_to_existing()

        log("Hot reload complete.")
        show_notification("Config reloaded successfully")
    end)
end


CONFIG_PATH = get_scripts_dir() .. "/config.lua"
load_initial_config()


--Cache local player controller and pawn on Client restarts
RegisterHook(
    "/Script/Engine.PlayerController:ClientRestart",

    function(Context)
        -- pre
    end,

    function(Context)
        local controller = Context:get()

        if not controller
            or not controller:IsValid()
            or not controller:IsLocalPlayerController() then

            return
        end
				
				local_player_controller = controller
				log("Cached local player controller.")				
    end
)

--Check if blueprint is loaded then hook into BP function
NotifyOnNewObject(
    TARGET_NATIVE_BASE,
    function(action)
        if not is_funnel_follow_action(action) then
            return
        end

        RegisterHook(
						FUNNEL_ACTION_START_BP,

						function(Context, ControlledPawn)
								local action = Context:get()
								
								if is_funnel_follow_action(action) then
										apply_offset(action)
								end
						end
				)
				return true
    end
)

RegisterHook(
    FUNNEL_ON_ACTIVE,

    function(Context)
        -- pre
    end,

    function(Context)
        local character = Context:get()								
				apply_funnel_default_scale(character,false)
    end
)

RegisterKeyBind(
    Key.F4,
    function()
        hot_reload_config()
    end
)


log("Loaded.")
log("Hot reload key: F4")