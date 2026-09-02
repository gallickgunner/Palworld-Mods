---@class PalUtils
local PalUtils = {}

local UnrealUtils = require("Utils.unreal_utils")
local CoreUtils = require("Utils.core_utils")
local UPaths = require("Constants.upaths")

-- Aliases used often
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local UObjects = UnrealUtils.UObjects

-- Module Variables and Functions
PalUtils.PAL_SIZE = {}
PalUtils.pal_utility = UObjects[UOBJ_PATHS.PAL_UTILITY]

-- Local helper
local function InitializePalSizeEnum()
	local size_enum = UObjects[UOBJ_PATHS.PAL_SIZE]

	size_enum:ForEachName(function(name, value)
		local full_name = type(name) == "string" and name or name:ToString()

		local sanitized_name = full_name:match("::([^:]+)$")
		if sanitized_name then
			local val = tonumber(value)
			PalUtils.PAL_SIZE[sanitized_name] = val

			-- Create dual-indexing
			PalUtils.PAL_SIZE[val] = sanitized_name
		end
	end)

	for _, name in ipairs({ "None", "XS", "S", "M", "L", "XL" }) do
		if PalUtils.PAL_SIZE[name] == nil then
			DebugLog("EPalSizeType did not expose " .. name)
		end
	end
end

-- Module exported functions

function PalUtils.GetUniquePalIDFromActor(pal_actor)
	return PalUtils.pal_utility:Convert_PalInstanceIDToString(PalUtils.pal_utility:GetIndividualIDByActor(pal_actor)):ToString()
end

function PalUtils.GetUniquePalIDFromHandle(handle)
	return PalUtils.pal_utility:Convert_PalInstanceIDToString(PalUtils.pal_utility:GetIndividualID(handle)):ToString()
end

function PalUtils.GetPalActorFullName(pal_actor)
	if IsValid(pal_actor) then
		return pal_actor:GetFullName()
	end
	return ""
end

-- Check if Pal is rideable regardless of any item restrictions.
function PalUtils.IsPalRideableFromActor(pal_actor)
	local marker = pal_actor:GetComponentByClass(UObjects[UOBJ_PATHS.PAL_RIDE_MARKER_COMPONENT])
	return IsValid(marker)
end

-- Check if Pal is rideable regardless of any item restrictions from a handle. Returns nil if error in accessing UObjects or false/true if pal is actually rideable or not
function PalUtils.IsPalRideableFromHandle(handle)
	local actor = handle:TryGetIndividualActor()

	if IsValid(actor) then
		return PalUtils.IsPalRideableFromActor(actor)
	end

	local parameter = handle:TryGetIndividualParameter()

	if not IsValid(parameter, "Invalid Parameter while checking Pal Rideability") then
		return nil
	end

	local master_dt_utility = UObjects[UOBJ_PATHS.PAL_MASTER_DT_UTILITY]
	local item_table = UObjects[UOBJ_PATHS.GAME_ITEM_DATA_TABLE]

	if not IsValid(master_dt_utility, "Failed to find : %s", UOBJ_PATHS.PAL_MASTER_DT_UTILITY) then
		return nil
	end

	if not IsValid(item_table, "Failed to find : %s", UOBJ_PATHS.GAME_ITEM_DATA_TABLE) then
		return nil
	end

	local pskill_param_dt = master_dt_utility:GetPartnerSkillParameterDataTable(parameter)

	if not IsValid(pskill_param_dt, "Failed to get a valid : PartnerSkillParamterDataTable") then
		return nil
	end

	local character_id = parameter:GetCharacterID():ToString()
	local partner_row = pskill_param_dt:FindRow(character_id)

	if not partner_row then
		DebugLog("Partner row invalid")
		return nil
	end

	local active_skill_name = partner_row.ActiveSkill.SkillName:ToString()

	-- Special weapon/melee mounts. For e.g Grizzbolt's machine gun. These Skills have the word "Ride" in them.
	if active_skill_name:find("Ride", 1, true) then
		return true
	end

	-- Ordinary saddle mounts. These Skills have a restriction item that has the word "Saddle" in their IconName
	local restriction_items = partner_row.RestrictionItems
	for i = 1, #restriction_items do
		local restriction = restriction_items[i]
		local item_row = item_table:FindRow(restriction.Key:ToString())

		if item_row then
			local icon_name = item_row.IconName:ToString()

			if icon_name:find("Saddle", 1, true) then
				return true
			end
		end
	end
	return false
end

function PalUtils.IsLocalPlayersOtomo(pal_actor)
	local individual_id = PalUtils.pal_utility:GetIndividualIDByActor(pal_actor)

	if individual_id and individual_id.PlayerUId then
		local controller = PalUtils.pal_utility:GetPlayerControllerByPlayerUId(pal_actor, individual_id.PlayerUId)

		if IsValid(controller) and controller:IsLocalPlayerController() then
			return true
		end
	end

	return false
end

InitializePalSizeEnum()

return PalUtils
