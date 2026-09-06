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
	local file = io.open(path, "rb")

	if not file then
		return nil
	end

	local contents = file:read("*a")
	file:close()
	return contents
end

local function WriteFile(path, contents)
	local file = io.open(path, "wb")

	if not file then
		return nil
	end

	local wrote = file:write(contents)
	file:close()

	if not wrote then
		return nil
	end
	return true
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

-- Recursively iterate over the given config object and serialize the data
local function SerializeValue(value, indent, schema)
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
			-- If we have a schema, then serialize according to order defined by it
			local serialized_keys = {}
			if schema and type(schema.__order) == "table" then
				for _, key in ipairs(schema.__order) do
					local child_value = value[key]
					local child_schema = schema[key]
					local suffix = type(child_value) == "table" and "\n" or ""

					table.insert(
						lines,
						string.format(
							"%s%s = %s,%s",
							padding,
							SerializeKey(key),
							SerializeValue(child_value, indent + 1, child_schema),
							suffix
						)
					)
					serialized_keys[key] = true
				end
			end

			-- Don't silently lose keys that were accidentally omitted from the schema.
			-- They are appended in deterministic alphabetical order.
			local remaining_keys = {}

			for key in pairs(value) do
				if not serialized_keys[key] then
					table.insert(remaining_keys, key)
				end
			end

			table.sort(remaining_keys, function(a, b)
				return tostring(a) < tostring(b)
			end)

			for _, key in ipairs(remaining_keys) do
				local child_value = value[key]
				local child_schema = schema and schema[key] or nil
				local suffix = type(child_value) == "table" and "\n" or ""
				table.insert(
					lines,
					string.format(
						"%s%s = %s,",
						padding,
						SerializeKey(key),
						SerializeValue(child_value, indent + 1, child_schema),
						suffix
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

	--Remove stale keys
	for key, _ in pairs(config) do
		if default_config[key] == nil then
			config[key] = nil
		end
	end
	return write_back
end

local function CreateUserConfigWithDefaults(config, config_path, default_config_path)
	local default_config_contents = ReadFile(default_config_path)

	if not default_config_contents then
		error("Failed to read Default Config file from : " .. GetConsoleDisplayPath(default_config_path))
	end

	local written = WriteFile(config_path, default_config_contents)

	if not written then
		Log("Failed to create " .. GetConsoleDisplayPath(config_path))
	end

	Log(GetConsoleDisplayPath(config_path) .. " generated successfully.")
end

local function UpdateUserConfigFile(config, default_config_schema, config_path, default_config_path)
	local comments = ExtractCommentsFromDefaultConfig(default_config_path)

	if comments ~= "" and not comments:match("[\r\n]$") then
		comments = comments .. "\n"
	end

	--Create a backup of original config file before writing
	local orig_bkp_path = config_path .. ".bkp"

	-- remove any bkp file with this name if it exists
	os.remove(orig_bkp_path)
	if not os.rename(config_path, orig_bkp_path) then
		Log("Failed to backup original file before replacing with updated one" .. GetConsoleDisplayPath(config_path))
		return false
	end

	local file = io.open(config_path, "w")

	if not file then
		Log("Failed to create " .. GetConsoleDisplayPath(config_path))
		return false
	end

	local wrote = file:write(comments, "return ", SerializeValue(config, 0, default_config_schema), "\n")
	file:close()

	if not wrote then
		os.remove(config_path)
		Log("Failed to update " .. GetConsoleDisplayPath(config_path) .. " with missing parameters")

		--rename original backup file back to original
		os.rename(orig_bkp_path, config_path)

		Log("Failed to replace " .. GetConsoleDisplayPath(config_path))
		return false
	end

	os.remove(orig_bkp_path)
	return true
end

function ConfigUtils.LoadConfigFile(config_path, default_config_path, default_config, default_config_schema)
	if not ConfigExists(config_path) then
		CreateUserConfigWithDefaults(default_config, config_path, default_config_path)
		-- Newly generated config file is identical to default config so we can just return the default_config back
		return default_config
	end

	local ok, config = pcall(dofile, config_path)

	if not ok or type(config) ~= "table" then
		Log("Failed to load: %s. Using built-in defaults.", GetConsoleDisplayPath(config_path))
		CreateUserConfigWithDefaults(default_config, config_path, default_config_path)
		return default_config
	end

	local update_config = ValidateConfig(config, default_config)

	if update_config and UpdateUserConfigFile(config, default_config_schema, config_path, default_config_path) then
		Log(GetConsoleDisplayPath(config_path) .. " updated with missing default parameters.")
	end

	Log(GetConsoleDisplayPath(config_path) .. " read successfully.")
	return config
end

return ConfigUtils
