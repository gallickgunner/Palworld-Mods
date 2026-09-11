---@class ModConfigManager
local ModConfigManager = {}

local ConfigUtils = require("Utils.config_utils")
local CoreUtils = require("Utils.core_utils")

local DEFAULT_CONFIG = require("Defaults.mod_config")
local DEFAULT_CONFIG_SCHEMA = require("Defaults.mod_config_schema")
local USER_CONFIG_PATH = CoreUtils.GetConfigDir() .. "config.lua"
local DEFAULT_CONFIG_PATH = CoreUtils.GetDefaultsDir() .. "mod_config.lua"
local reload_callbacks = {}

---@type DefaultModConfig
local config = nil


local function ValidateHotReloadKey()
	local reload_key = config.hot_reload_key
	if not Key[reload_key] then
		CoreUtils.Log("Invalid hot_reload_key '%s'. Using the default '%s'.", reload_key, DEFAULT_CONFIG.hot_reload_key)
		config.hot_reload_key = DEFAULT_CONFIG.hot_reload_key
	end
end

local function LoadConfig()
	config = ConfigUtils.LoadConfigFile(USER_CONFIG_PATH, DEFAULT_CONFIG_PATH, DEFAULT_CONFIG, DEFAULT_CONFIG_SCHEMA)
	CoreUtils.debug_logging = config.debug_logging
	ValidateHotReloadKey()
end

function ModConfigManager.Reload()
	LoadConfig()
	for _, callback in ipairs(reload_callbacks) do
		-- Sending the updated mod config isn't necessary but it's elegant. Shows the intent
		callback(config)
	end
end

function ModConfigManager.RegisterHotReloadCallback(callback)
	table.insert(reload_callbacks, callback)
end

function ModConfigManager.GetConfig()
	if not config then
		LoadConfig()
	end

	return config
end

function ModConfigManager.Init()
	config = ModConfigManager.GetConfig()
end

return ModConfigManager
