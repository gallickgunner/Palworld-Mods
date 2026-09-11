---@class PalUtils
local PalUtils = {}

local UnrealUtils = require("Utils.unreal_utils")
local CoreUtils = require("Utils.core_utils")
local UPaths = require("Constants.upaths")
local CDO = require("Utils.cdo")
local UEHelpers = require("UEHelpers")
-- Aliases used often
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local UObjects = UnrealUtils.UObjects

-- Module Variables and Functions
PalUtils.PAL_SIZE = {}
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
function PalUtils.GetWorldSaveDirName()
	local game_instance = UEHelpers.GetGameInstance()

	-- If we got a new valid game instance get the world save directory name and load its captured leader data
	if not IsValid(game_instance) then
		DebugLog("GameInstance invalid")
		return nil
	end

	return game_instance:GetSelectedWorldSaveDirectoryName():ToString()
end

function PalUtils.IsWildLeader(pal_actor)
	if not IsValid(pal_actor) then
		return false
	end

	if not UObjects.PalUtility:IsPalMonster(pal_actor) then
		return false
	end

	if not UObjects.PalUtility:IsWildNPC(pal_actor) then
		return false
	end

	local controller = pal_actor:GetController()

	if not IsValid(controller) then
		return false
	end

	return controller:IsLeader()
end

function PalUtils.GetPalSize(pal_actor)
	local static_char_param = pal_actor.StaticCharacterParameterComponent

	local is_boss = PalUtils.IsBossIncludingRare(static_char_param)

	if not is_boss then
		return static_char_param.Size
	end

	local char_param = pal_actor:GetCharacterParameterComponent()

	if not IsValid(char_param) then
		return nil
	end

	local indiv_param = char_param:GetIndividualParameter()

	if not IsValid(indiv_param) then
		return nil
	end

	local monster_param_dt = UObjects[UOBJ_PATHS.GAME_MONSTER_PARAM_DT]
	local out_tribe_id_name = {}

	CDO.pal_utility:GetTribeIDNameFromParameter(pal_actor, indiv_param, out_tribe_id_name)
	local tribe_id_name = out_tribe_id_name.outTribeIDName

	if not tribe_id_name then
		DebugLog("Failed to get Tribe ID Name in when looking up boss's original size category")
		return nil
	end

	local tribe_id_str = tribe_id_name:ToString()
	local row = monster_param_dt:FindRow(tribe_id_str)

	if not row or not row.Size then
		return nil
	end

	return row.Size
end

function PalUtils.GetCharacterIDFromActor(pal_actor)
	if not IsValid(pal_actor) then
		return nil
	end

	local parameter_component = pal_actor.CharacterParameterComponent

	if not IsValid(parameter_component) then
		return nil
	end

	local parameter = parameter_component:GetIndividualParameter()

	if not IsValid(parameter) then
		return nil
	end

	local character_id = parameter:GetCharacterID()

	if not character_id then
		return nil
	end

	return character_id:ToString()
end

function PalUtils.GetBossPalOriginalSizeCategory(pal_actor)
	local char_param = pal_actor:GetCharacterParameterComponent()

	if not IsValid(char_param) then
		return nil
	end

	local indiv_param = char_param:GetIndividualParameter()

	if not IsValid(indiv_param) then
		return nil
	end

	local monster_param_dt = UObjects[UOBJ_PATHS.GAME_MONSTER_PARAM_DT]
	local out_tribe_id_name = {}

	CDO.pal_utility:GetTribeIDNameFromParameter(pal_actor, indiv_param, out_tribe_id_name)
	local tribe_id_name = out_tribe_id_name.outTribeIDName

	if not tribe_id_name then
		DebugLog("Failed to get Tribe ID Name in when looking up boss's original size category")
		return nil
	end

	local tribe_id_str = tribe_id_name:ToString()
	local row = monster_param_dt:FindRow(tribe_id_str)

	if not row or not row.Size then
		return nil
	end

	return row.Size
end

function PalUtils.GetPalInstanceIdFromActor(pal_actor)
	local indiv_id = CDO.pal_utility:GetIndividualIDByActor(pal_actor)
	if indiv_id and not CDO.pal_utility:IsValidInstanceID(indiv_id) then
		return nil
	end
	return CDO.kismet_guid_lib:Conv_GuidToString(indiv_id.InstanceId):ToString()
end

function PalUtils.GetPalInstanceIdFromHandle(handle)
	local indiv_id = CDO.pal_utility:GetIndividualID(handle)
	if indiv_id and not CDO.pal_utility:IsValidInstanceID(indiv_id) then
		return nil
	end
	return CDO.kismet_guid_lib:Conv_GuidToString(indiv_id.InstanceId):ToString()
end

function PalUtils.GetPalInstanceIdFromIndivId(indiv_id)
	if not CDO.pal_utility:IsValidInstanceID(indiv_id) then
		return nil
	end
	return CDO.kismet_guid_lib:Conv_GuidToString(indiv_id.InstanceId):ToString()
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
	local item_table = UObjects[UOBJ_PATHS.GAME_ITEM_DT]

	if not IsValid(master_dt_utility, "Failed to find : %s", UOBJ_PATHS.PAL_MASTER_DT_UTILITY) then
		return nil
	end

	if not IsValid(item_table, "Failed to find : %s", UOBJ_PATHS.GAME_ITEM_DT) then
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
	local individual_id = CDO.pal_utility:GetIndividualIDByActor(pal_actor)

	if individual_id and individual_id.PlayerUId then
		local controller = CDO.pal_utility:GetPlayerControllerByPlayerUId(pal_actor, individual_id.PlayerUId)

		if IsValid(controller) and controller:IsLocalPlayerController() then
			return true
		end
	end

	return false
end

function PalUtils.IsBossExcludingRare(static_char_param)
	return static_char_param:IsBossPal_Database_ExceptRare()
		or static_char_param:IsRaidBossPal()
		or static_char_param:IsTowerBossPal()
		or static_char_param:IsPredatorBossPal()
end

function PalUtils.IsBossIncludingRare(static_char_param)
	return static_char_param:IsBossPal_Database()
		or static_char_param:IsRaidBossPal()
		or static_char_param:IsTowerBossPal()
		or static_char_param:IsPredatorBossPal()
end

function PalUtils.DebugLogActor(message, actor)
	if CoreUtils.debug_logging then
		CoreUtils.Log(message .. " | Pal Name: %s | PalID: %s", actor:GetFullName(), PalUtils.GetPalInstanceIdFromActor(actor))
	end
end

InitializePalSizeEnum()

return PalUtils
