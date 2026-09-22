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

---@class PAL_SIZE
PalUtils.PAL_SIZE = {
	None = 0,
	XS = 1,
	S = 2,
	M = 3,
	L = 4,
	XL = 5
}

---@class PAL_GENDER
PalUtils.PAL_GENDER = {
	None = 0,
	Male = 1,
	Female = 2
}

---@class PAL_WORK_SUITABILITY
PalUtils.PAL_WORK_SUITABILITY = {
	None = 0,
	EmitFlame = 1,
	Watering = 2,
	Seeding = 3,
	GenerateElectricity = 4,
	Handcraft = 5,
	Collection = 6,
	Deforest = 7,
	Mining = 8,
	OilExtraction = 9,
	ProductMedicine = 10,
	Cool = 11,
	Transport = 12,
	MonsterFarm = 13,
	Anyone = 14,
	MAX = 15
}

-- Local helper

local function InitializePalSizeEnum()
	local size_enum = UObjects[UOBJ_PATHS.PAL_SIZE]

	size_enum:ForEachName(function(name, value)
		local full_name = type(name) == "string" and name or name:ToString()

		local sanitized_name = PalUtils.GetSanitizedEnumName(full_name)
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

local function InitializePalGenderEnum()
	local gender_enum = UObjects[UOBJ_PATHS.PAL_GENDER]

	gender_enum:ForEachName(function(name, value)
		local full_name = type(name) == "string" and name or name:ToString()

		local sanitized_name = PalUtils.GetSanitizedEnumName(full_name)
		if sanitized_name then
			local val = tonumber(value)

			PalUtils.PAL_GENDER[sanitized_name] = val
			-- Create dual-indexing
			PalUtils.PAL_GENDER[val] = sanitized_name
		end
	end)

	for _, name in ipairs({ "None", "Male", "Female" }) do
		if PalUtils.PAL_GENDER[name] == nil then
			DebugLog("EPalGenderType did not expose " .. name)
		end
	end
end

local function InitializePalWorkSuitabilityEnum()
	local work_suitability_enum = UObjects[UOBJ_PATHS.PAL_WORK_SUITABILITY]

	work_suitability_enum:ForEachName(function(name, value)
		local full_name = type(name) == "string" and name or name:ToString()

		local sanitized_name = PalUtils.GetSanitizedEnumName(full_name)
		if sanitized_name then
			local val = tonumber(value)

			PalUtils.PAL_WORK_SUITABILITY[sanitized_name] = val

			-- Create dual-indexing
			PalUtils.PAL_WORK_SUITABILITY[val] = sanitized_name
		end
	end)

	for _, name in ipairs({
		"None",
		"EmitFlame",
		"Watering",
		"Seeding",
		"GenerateElectricity",
		"Handcraft",
		"Collection",
		"Deforest",
		"Mining",
		"OilExtraction",
		"ProductMedicine",
		"Cool",
		"Transport",
		"MonsterFarm",
		"Anyone",
		"MAX",
	}) do
		if PalUtils.PAL_WORK_SUITABILITY[name] == nil then
			DebugLog("EPalWorkSuitability did not expose " .. name)
		end
	end
end

-- Module exported functions

function PalUtils.GetSanitizedEnumName(name_str)
	local sanitized_name = name_str:match("::([^:]+)$")

	return sanitized_name or ""
end

function PalUtils.GetWorldSaveDirName()
	local game_instance = UEHelpers.GetGameInstance()

	-- If we got a new valid game instance get the world save directory name and load its captured leader data
	if not IsValid(game_instance) then
		DebugLog("GameInstance invalid")
		return nil
	end

	return game_instance:GetSelectedWorldSaveDirectoryName():ToString()
end

function PalUtils.GetFriendshipPoint(indiv_param)
	if not IsValid(indiv_param) then
		return nil
	end

	local save_parameter = indiv_param.SaveParameter

	if not save_parameter then
		return nil
	end

	return save_parameter.FriendshipPoint
end

function PalUtils.GetFriendshipProgress(indiv_param, world_context)
	local friendship_point = PalUtils.GetFriendshipPoint(indiv_param)

	if friendship_point == nil then
		return 0.0
	end

	local database = CDO.pal_utility:GetDatabaseCharacterParameter(world_context)

	if not IsValid(database) then
		return 0.0
	end

	local min_rank = database:GetMinFriendshipRank()
	local max_rank = database:GetMaxFriendshipRank()
	local current_rank = database:GetFriendshipRank(friendship_point)

	local rank_progress = CoreUtils.Clamp(database:CalcFriendshipProgress(friendship_point), 0.0, 1.0)
	local friendship_progress = ((current_rank - min_rank) + rank_progress) / (max_rank - min_rank)

	return CoreUtils.Clamp(friendship_progress, 0.0, 1.0)
end

function PalUtils.IsWildLeader(pal_actor)
	if not IsValid(pal_actor) then
		return false
	end

	if not CDO.pal_utility:IsPalMonster(pal_actor) then
		return false
	end

	if not CDO.pal_utility:IsWildNPC(pal_actor) then
		return false
	end

	local controller = pal_actor:GetController()

	if not IsValid(controller) then
		return false
	end

	return controller:IsLeader()
end

function PalUtils.HasPassiveSkill(individual_param, target_skill)
	local passive_skills = individual_param:GetPassiveSkillList()

	for _, skill in pairs(passive_skills) do
		local skill_name = skill:get():ToString()

		if skill_name == target_skill then
			return true
		end
	end

	return false
end

function PalUtils.GetPalSize(pal_actor)
	local static_char_param = pal_actor.StaticCharacterParameterComponent

	local is_boss = PalUtils.IsBossIncludingRare(static_char_param)

	if not is_boss then
		return static_char_param.Size
	end

	local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)

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
	local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)

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

function PalUtils.GetPalActorFromId(world_context, id)
	local character_manager = CDO.pal_utility:GetCharacterManager(world_context)

	if not IsValid(character_manager) then
		return nil
	end

	local individual_handle = character_manager:GetIndividualHandle(id)
	if not IsValid(individual_handle) then
		return nil
	end

	local pal_actor = individual_handle:TryGetIndividualActor()

	if not IsValid(pal_actor) then
		return nil
	end

	return pal_actor
end

function PalUtils.GetPalInstanceIdFromActor(pal_actor)
	local indiv_id = CDO.pal_utility:GetIndividualIDByActor(pal_actor)
	if not indiv_id or not CDO.pal_utility:IsValidInstanceID(indiv_id) then
		return nil
	end
	return CDO.kismet_guid_lib:Conv_GuidToString(indiv_id.InstanceId):ToString()
end

function PalUtils.GetPalInstanceIdFromHandle(handle)
	local indiv_id = CDO.pal_utility:GetIndividualID(handle)
	if not indiv_id or not CDO.pal_utility:IsValidInstanceID(indiv_id) then
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

function PalUtils.IsLocalPlayersOtomo(pal_actor)
	if not IsValid(pal_actor) then
		return false
	end

	if not CDO.pal_utility:IsOtomo(pal_actor) then
		return false
	end

	local char_param = pal_actor:GetCharacterParameterComponent()

	if not IsValid(char_param) then
		return false
	end

	local trainer = char_param.Trainer

	if not IsValid(trainer) then
		return false
	end

	local player_controller = trainer:GetController()

	if not IsValid(player_controller) then
		return false
	end

	return player_controller:IsLocalPlayerController()
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

function PalUtils.Init()
	InitializePalSizeEnum()
	InitializePalGenderEnum()
	InitializePalWorkSuitabilityEnum()
end

return PalUtils
