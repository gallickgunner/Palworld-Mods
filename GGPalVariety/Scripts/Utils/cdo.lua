---@class CDO
local CDO = {}

local UnrealUtils = require("Utils.unreal_utils")
local UPaths = require("Constants.upaths")
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local UObjects = UnrealUtils.UObjects

CDO.pal_utility = UObjects[UOBJ_PATHS.PAL_UTILITY]
CDO.kismet_guid_lib = UObjects[UOBJ_PATHS.KISMET_GUID_LIB]
CDO.kismet_string_lib = UObjects[UOBJ_PATHS.KISMET_SYS_LIB]
CDO.kismet_math_lib = UObjects[UOBJ_PATHS.KISMET_MATH_LIB]
CDO.passive_skill_effect = UObjects[UOBJ_PATHS.PASSIVE_SKILL_EFFECT_TYPE]
return CDO
