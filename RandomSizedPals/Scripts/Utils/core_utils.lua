---@class CoreUtils
local CoreUtils = {}

local MOD_NAME = nil
local MOD_DIR = nil
CoreUtils.debug_logging = false

function CoreUtils.GetModDir()
	if MOD_DIR then
		return MOD_DIR
	end

	local source = debug.getinfo(1, "S").source or ""
	source = source:gsub("^@", ""):gsub("\\", "/")
	MOD_DIR = source:match("^(.*[/])Scripts[/]")

	if not MOD_DIR then
		error("Failed to resolve mod directory. Aborting.")
	end

	return MOD_DIR
end

function CoreUtils.GetModName()
	if not MOD_NAME then
		local mod_dir = CoreUtils.GetModDir()
		MOD_NAME = mod_dir:match("([^/]+)[/]$")
	end

	if not MOD_NAME then
		error("Failed to find Mod Name from Mod Path. Aborting.")
	end

	return MOD_NAME
end

function CoreUtils.GetDefaultsDir()
	local mod_dir = CoreUtils.GetModDir()
	return mod_dir .. "Scripts/Defaults/"
end

function CoreUtils.GetConfigDir()
	local mod_dir = CoreUtils.GetModDir()
	return mod_dir .. "Config/"
end

function CoreUtils.Log(message, ...)
	if select('#', ...) > 0 then
		message = string.format(message, ...)
	end
	print(string.format("[%s] %s", CoreUtils.GetModName(), message))
end

function CoreUtils.DebugLog(message, ...)
	if CoreUtils.debug_logging then
		CoreUtils.Log(message, ...)
	end
end

return CoreUtils
