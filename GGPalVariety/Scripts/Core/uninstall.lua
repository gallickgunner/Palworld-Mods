---@class Uninstall
local Uninstall = {}

local CDO = require("Utils.cdo")
local CoreUtils = require("Utils.core_utils")
local PalUtils = require("Utils.pal_utils")
local UnrealUtils = require("Utils.unreal_utils")
local UPaths = require("Constants.upaths")
local Constants = require("Constants.constants")

local Log = CoreUtils.Log
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local FUNC_PATHS = UPaths.FUNC_PATHS

local LEADER_PASSIVE_SKILL_NAME = Constants.LEADER_PASSIVE_SKILL_NAME
local LEADER_PASSIVE_SKILL_FNAME = FName(LEADER_PASSIVE_SKILL_NAME)

local base_cleanup_done = false

local function CleanupHandle(handle)
	if not handle then
		return false
	end

	local individual_param = handle:TryGetIndividualParameter()

	if not IsValid(individual_param) then
		return false
	end

	if not IsValid(individual_param) then
		return false
	end

	if not PalUtils.HasPassiveSkill(individual_param, LEADER_PASSIVE_SKILL_NAME) then
		return false
	end

	individual_param:RemovePassiveSkill(LEADER_PASSIVE_SKILL_FNAME)
	return true
end

local function CleanupContainer(container)
	if not IsValid(container) then
		return 0
	end

	local removed_count = 0
	local slots = container:GetSlots()

	for _, slot in pairs(slots) do
		slot = slot:get()
		if IsValid(slot) and not slot:IsEmpty() then
			local handle = slot:GetHandle()

			if CleanupHandle(handle) then
				removed_count = removed_count + 1
			end
		end
	end

	return removed_count
end

local function CleanupParty(holder)
	if not IsValid(holder) then
		return 0
	end

	local container = holder.CharacterContainer

	if not IsValid(container) then
		DebugLog("Uninstall cleanup: Party container was invalid")
		return 0
	end

	return CleanupContainer(container)
end

local function CleanupPalbox(controller)
	if not IsValid(controller) then
		return 0
	end

	local player_uid = controller:GetPlayerUId()
	local pal_storage = CDO.pal_utility:GetPalStorageDataByPlayerUID(controller, player_uid)

	if not IsValid(pal_storage) then
		DebugLog("Uninstall cleanup: Failed to get Pal storage")
		return 0
	end

	local container = pal_storage.TargetContainer

	if not IsValid(container) then
		DebugLog("Uninstall cleanup: Pal storage container was invalid")
		return 0
	end

	return CleanupContainer(container)
end

local function CleanupBaseCamps()
	if base_cleanup_done then
		return 0
	end

	local base_models = FindAllOf("PalBaseCampModel")

	if not base_models then
		DebugLog("Uninstall cleanup: No BaseCamp models found")
		return 0
	end

	local removed_count = 0

	for _, base_model in pairs(base_models) do
		if IsValid(base_model) then
			local worker_director = base_model.WorkerDirector

			if IsValid(worker_director) then
				removed_count = removed_count + CleanupContainer(worker_director.CharacterContainer)
			end
		end
	end

	return removed_count
end

function Uninstall.Init()
	RegisterHook(
		FUNC_PATHS.ON_PARTY_CREATED,
		function()
		end,
		function(context)
			local holder = context:get()

			if not IsValid(holder) then
				return
			end

			local controller = holder:GetOwner()

			if not IsValid(controller) or not controller:IsPlayerController() then
				return
			end

			local party_removed = CleanupParty(holder)
			local palbox_removed = CleanupPalbox(controller)
			local base_camp_pals = CleanupBaseCamps()
			base_cleanup_done = true
			Log("Uninstall cleanup: Leader Skill removed | Party: %d | Palbox: %d | Base Camp: %d", party_removed, palbox_removed, base_camp_pals)
		end
	)
end

return Uninstall
