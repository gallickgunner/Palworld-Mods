---@class CDO
---@field pal_utility any
---@field widget_bp_lib any
---@field kismet_guid_lib any
---@field kismet_string_lib any
---@field kismet_math_lib any
---@field passive_skill_effect any
local CDO = {}

local UnrealUtils = require("Utils.unreal_utils")
local UPaths = require("Constants.upaths")

local UOBJ_PATHS = UPaths.UOBJ_PATHS
local UObjects = UnrealUtils.UObjects

local CDO_PATHS = {
	pal_utility = UOBJ_PATHS.PAL_UTILITY,
	widget_bp_lib = UOBJ_PATHS.WIDGET_BLUEPRINT_LIBRARY,
	kismet_guid_lib = UOBJ_PATHS.KISMET_GUID_LIB,
	kismet_string_lib = UOBJ_PATHS.KISMET_SYS_LIB,
	kismet_math_lib = UOBJ_PATHS.KISMET_MATH_LIB,
	passive_skill_effect = UOBJ_PATHS.PASSIVE_SKILL_EFFECT_TYPE,
}

setmetatable(CDO, {
	__index = function(self, key)
		local path = CDO_PATHS[key]

		if not path then
			return nil
		end

		local object = UObjects[path]

		if not object then
			return nil
		end

		rawset(self, key, object)

		return object
	end
})

return CDO
