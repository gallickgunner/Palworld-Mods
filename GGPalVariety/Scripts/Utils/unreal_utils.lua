local UnrealUtils = {}

local CoreUtils = require("Utils.core_utils")

UnrealUtils.UObjects = {}

-- Lazy load Unreal Objects in our UObjects cache
setmetatable(UnrealUtils.UObjects, {
	__index = function(self, path)
		local object = StaticFindObject(path)

		if not object or not object:IsValid() then
			CoreUtils.Log("Failed to find Unreal Object: " .. path)
			return nil
		end

		rawset(self, path, object)

		return object
	end
})

function UnrealUtils.IsValid(obj, ...)
	if not obj then
		return false
	end

	local is_valid = obj:IsValid()

	-- If object not valid and we passed a log message, print it to console
	if not is_valid and select("#", ...) > 0 then
		CoreUtils.DebugLog(...)
	end

	return is_valid
end

function UnrealUtils.GetString(name)
	if type(name) == "string" then
		return name
	end

	if name and name.ToString then
		return name:ToString()
	end

	return ""
end

function UnrealUtils.TryRegisterBPHook(path, callback)
	local success, pre_id, post_id = pcall(RegisterHook, path, callback)

	if not success then
		CoreUtils.Log("Hook function not ready | %s | %s", path, tostring(pre_id))
		return false
	end

	return true
end

return UnrealUtils
