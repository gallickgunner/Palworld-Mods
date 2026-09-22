---@class LocalizationManager
local LocalizationManager = {}

local ConfigUtils = require("Utils.config_utils")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local UPaths = require("Constants.upaths")

--local reload_callbacks = {}
-- Aliases
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local UObjects = UnrealUtils.UObjects
local IsValid = UnrealUtils.IsValid

-- Local vars and funcs

---@type LocalizationConfig
local config = nil
local DEFAULT_CONFIG = require("Defaults.localization")
local DEFAULT_CONFIG_SCHEMA = require("Defaults.localization_schema")
local USER_CONFIG_PATH = CoreUtils.GetConfigDir() .. "localization.lua"
local DEFAULT_CONFIG_PATH = CoreUtils.GetDefaultsDir() .. "localization.lua"
local DEFAULT_LOCALE = "en"
local CURR_LOCALE = "en"


local function LoadConfig()
	config = ConfigUtils.LoadConfigFile(USER_CONFIG_PATH, DEFAULT_CONFIG_PATH, DEFAULT_CONFIG, DEFAULT_CONFIG_SCHEMA)
end

local function LoadCurrentLocale()
	local kismet_intl_lib = UObjects[UOBJ_PATHS.KISMET_INTL_LIB]

	if not IsValid(kismet_intl_lib) then
		CoreUtils.Log("Failed to get current game locale. Using the default '%s'", DEFAULT_LOCALE)
		return
	end

	local locale = kismet_intl_lib:GetCurrentLanguage()

	if locale then
		CURR_LOCALE = locale:ToString()
	end
end

function LocalizationManager.GetConfig()
	if not config then
		LoadConfig()
	end

	return config
end

function LocalizationManager.GetLocalizedText(key)
	local locale_config = config[CURR_LOCALE]
	local text_options = locale_config and locale_config[key]
	local len = nil

	if type(text_options) == "table" then
		len = #text_options
	end

	if not len or len == 0 then
		local default_config = config[DEFAULT_LOCALE]
		text_options = default_config and default_config[key]
		len = #text_options
	end

	if type(text_options) ~= "table" or len == 0 then
		return "No suitable text found. Ensure localization config file is proper."
	end

	if len > 1 then
		return text_options[math.random(len)]
	end

	return text_options[1]
end

function LocalizationManager.Init()
	LoadCurrentLocale()
	config = LocalizationManager.GetConfig()
end

-- LocalizationManager doesn't support hot reloading
--
--function LocalizationManager.Reload()
--	LoadConfig()
--	for _, callback in ipairs(reload_callbacks) do
--		callback(config)
--	end
--end
--
--function LocalizationManager.RegisterHotReloadCallback(callback)
--	table.insert(reload_callbacks, callback)
--end

-- Load the current game language


return LocalizationManager
