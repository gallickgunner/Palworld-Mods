local Utils = {}

local MOD_NAME = "RandomSizedPals"
local DEFAULT_CONFIG = require("Core.defaults")
local debug_logging = DEFAULT_CONFIG.debug_logging

local function get_core_dir()
	local source = debug.getinfo(1, "S").source or ""
	source = source:gsub("^@", "")

	return source:match("^(.*)[/\\][^/\\]+$") or "."
end

local function validate_config(config)
	if type(config) ~= "table" then
		return nil, "config.lua must return a table"
	end

	if type(config.size_variation) ~= "table" then
		return nil, "size_variation must be a table"
	end

	for _, name in ipairs({ "XS", "S", "M", "L", "XL" }) do
		local range = config.size_variation[name]

		if type(range) ~= "table" then
			return nil, "size_variation." .. name .. " must be a table"
		end

		range.min = tonumber(range.min)
		range.max = tonumber(range.max)

		if range.min == nil or range.max == nil then
			return nil, "size_variation." .. name .. ".min/max must be numbers"
		end

		if range.min > range.max then
			return nil, "size_variation." .. name .. ".min cannot be greater than max"
		end
	end

	config.minimum_scale = tonumber(config.minimum_scale)

	if not config.minimum_scale or config.minimum_scale <= 0 then
		return nil, "minimum_scale must be greater than zero"
	end

	return config
end

local function config_exists(config_path)
	local file = io.open(config_path, "r")

	if not file then
		return false
	end

	file:close()
	return true
end

local function create_default_config(config_path)
	local defaults_path = get_core_dir() .. "/defaults.lua"
	local defaults_file = io.open(defaults_path, "r")

	if not defaults_file then
		error("Could not open defaults.lua")
	end

	local contents = defaults_file:read("*a")
	defaults_file:close()

	local marker = "%-%-<<CONFIG_START>>[\r\n]*"
	local _, marker_end = contents:find(marker)

	if not marker_end then
		error("Could not find config marker in defaults.lua")
	end

	contents = "-- CONFIG FILE\n" .. contents:sub(marker_end + 1)

	local temporary_path = config_path .. ".tmp"
	local config_file = io.open(temporary_path, "w")

	if not config_file then
		return false, "Could not create " .. temporary_path
	end

	local wrote = config_file:write(contents)
	config_file:close()

	if not wrote then
		os.remove(temporary_path)
		return false, "Could not write default config"
	end

	local renamed = os.rename(temporary_path, config_path)

	if not renamed then
		os.remove(temporary_path)
		return false, "Could not rename generated config to config.lua"
	end

	Utils.log("Generated config.lua from defaults.lua.")
	return true
end


function Utils.log(message)
	print(string.format("[%s] %s\n", MOD_NAME, tostring(message)))
end

function Utils.debug_log(message)
	if debug_logging then
		Utils.log(message)
	end
end

function Utils.get_scripts_dir()
	local source = debug.getinfo(1, "S").source or ""
	source = source:gsub("^@", "")
	local core_dir = get_core_dir()

	return core_dir:match("^(.*)[/\\][^/\\]+$") or "."
end

function Utils.get_config(config_path)
	if not config_exists(config_path) then
		local created, create_error = create_default_config(config_path)

		if not created then
			Utils.log(create_error)
		end
		-- Since newly generated config file is generated from defaults.lua we can return DEFAULT_CONFIG here
		return DEFAULT_CONFIG
	end

	-- If config file already exists, read and validate
	local ok, result = pcall(dofile, config_path)

	if not ok then
		Utils.log("Could not load config.lua: " .. tostring(result))
		Utils.log("Using built-in defaults.")
		return DEFAULT_CONFIG
	end

	local loaded_config, err = validate_config(result)

	if not loaded_config then
		Utils.log(err)
		Utils.log("Using built-in defaults.")
		return DEFAULT_CONFIG
	end

	Utils.log("Existing Config file read successfully.")
	debug_logging = loaded_config.debug_logging
	return loaded_config
end

return Utils
