---@class ConfigUtils
local ConfigUtils = {}

local CoreUtils = require("Utils.core_utils")

-- Aliases
local Log = CoreUtils.Log


local function GetConsoleDisplayPath(path)
	return path:match("([^/]+/[^/]+)$") or path
end

local function IsArray(value)
	local count = 0
	local max_index = -1

	for key in pairs(value) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			return false
		end

		count = count + 1
		if key > max_index then
			max_index = key
		end
	end

	return count > 0 and count == max_index
end

local function ConfigExists(config_path)
	local file = io.open(config_path, "r")

	if not file then
		return false
	end

	file:close()
	return true
end

local function ReadFile(path)
	local file = io.open(path, "r")

	if not file then
		return nil
	end

	local contents = file:read("*a")
	file:close()
	return contents
end

local function ValidateConfig(config, default_config)
	local write_back = false

	for key, def_value in pairs(default_config) do
		local user_value = config[key]

		if type(def_value) == "table" then
			if type(user_value) ~= "table" then
				config[key] = {}
				write_back = true
			end

			if ValidateConfig(config[key], def_value) then
				write_back = true
			end
		elseif user_value == nil or type(user_value) ~= type(def_value) then
			config[key] = def_value
			write_back = true
		end
	end

	return write_back
end

local function ExtractCommentsFromDefaultConfig(default_config_path)
	local contents = ReadFile(default_config_path)

	if not contents then
		error("Failed to read file: " .. GetConsoleDisplayPath(default_config_path))
	end

	local comments = contents:match("^(.*)%s*%-%-%-@class")

	if not comments then
		return ""
	end

	return comments
end


local function SerializeKey(key)
	if type(key) == "string" then
		if key:match("^[%a_][%w_]*$") then
			return key
		end

		return "[" .. string.format("%q", key) .. "]"
	end

	if type(key) == "number" then
		return "[" .. tostring(key) .. "]"
	end

	error("Unsupported config key type: " .. type(key))
end

local function SerializeValue(value, indent)
	indent = indent or 0

	if type(value) == "table" then
		local lines = { "{" }
		local padding = string.rep("\t", indent + 1)

		if IsArray(value) then
			for _, child_value in ipairs(value) do
				table.insert(
					lines,
					string.format(
						"%s%s,",
						padding,
						SerializeValue(child_value, indent + 1)
					)
				)
			end
		else
			for key, child_value in pairs(value) do
				table.insert(
					lines,
					string.format(
						"%s%s = %s,",
						padding,
						SerializeKey(key),
						SerializeValue(child_value, indent + 1)
					)
				)
			end
		end

		table.insert(lines, string.rep("\t", indent) .. "}")
		return table.concat(lines, "\n")
	end

	if type(value) == "string" then
		return string.format("%q", value)
	end

	if type(value) == "number" or type(value) == "boolean" or type(value) == "nil" then
		return tostring(value)
	end

	error("Unsupported config value type: " .. type(value), 0)
end

function ConfigUtils.WriteUserConfig(config_exists, config, config_path, default_config_path)
	local temporary_path = config_path .. ".tmp"
	local file = io.open(temporary_path, "w")

	if not file then
		Log("Failed to create " .. GetConsoleDisplayPath(temporary_path))
		return false
	end

	local comments = ExtractCommentsFromDefaultConfig(default_config_path)

	if comments ~= "" and not comments:match("[\r\n]$") then
		comments = comments .. "\n"
	end

	local wrote = file:write(comments, "return ", SerializeValue(config), "\n")
	file:close()

	if not wrote then
		os.remove(temporary_path)
		Log("Failed to update " .. GetConsoleDisplayPath(config_path) .. " with missing parameters")
		return false
	end

	--Create a backup of original config file before deleting it and renaming tmp to original
	local orig_bkp_path = config_path .. ".bkp"
	if config_exists then
		-- remove any bkp file with this name if it exists
		os.remove(orig_bkp_path)
		if not os.rename(config_path, orig_bkp_path) then
			Log("Failed to backup original file before replacing with updated one" .. GetConsoleDisplayPath(config_path))
			return false
		end
	end

	if not os.rename(temporary_path, config_path) then
		os.remove(temporary_path)

		--rename original backup file back to original
		if config_exists and not os.rename(orig_bkp_path, config_path) then
			Log("Failed to restore original config backup " .. GetConsoleDisplayPath(orig_bkp_path))
		end

		Log("Failed to replace " .. GetConsoleDisplayPath(config_path))
		return false
	end

	os.remove(orig_bkp_path)

	return true
end

function ConfigUtils.LoadConfigFile(config_path, default_config_path, default_config)
	if not ConfigExists(config_path) then
		local check = ConfigUtils.WriteUserConfig(false, default_config, config_path, default_config_path)
		if check then
			Log(GetConsoleDisplayPath(config_path) .. " generated successfully.")
		end
		-- Newly generated config file is identical to default config so we can just return it back
		return default_config
	end

	local ok, config = pcall(dofile, config_path)

	if not ok or type(config) ~= "table" then
		Log("Failed to load: %s. Using built-in defaults.", GetConsoleDisplayPath(config_path))
		return default_config
	end

	local update_config = ValidateConfig(config, default_config)

	if update_config and ConfigUtils.WriteUserConfig(config, config_path, default_config_path) then
		Log(GetConsoleDisplayPath(config_path) .. " updated with missing default parameters.")
	end

	Log(GetConsoleDisplayPath(config_path) .. " read successfully.")
	return config
end

return ConfigUtils
