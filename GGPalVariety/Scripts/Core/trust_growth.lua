---@class TrustGrowth
local TrustGrowth = {}

local ModConfigManager = require("Managers.mod_config_manager")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local PalUtils = require("Utils.pal_utils")
local UPaths = require("Constants.upaths")
local CDO = require("Utils.cdo")
local Server = require("Server.server")

-- Aliases used often
local Log = CoreUtils.Log
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local FUNC_PATHS = UPaths.FUNC_PATHS
local UObjects = UnrealUtils.UObjects

local BASE_PAL_GROWTH_UPDATE_MS = 60000
local MIN_HEALTHY_SANITY = 60.0

local WORKING_STATE = 2
local HUNGER_DEFAULT = 0
local WORKER_SICK_NONE = 0

local mod_config = ModConfigManager.GetConfig()
local game_settings = nil
local base_camp_models = {}
local base_pals_highest_trust = {}

local on_base_pals_growth_cbs = {}



local function GetBasePalSlots(base_model)
	if not base_model:IsAvailable() then
		return nil
	end

	local worker_director = base_model.WorkerDirector

	if not IsValid(worker_director) then
		return nil
	end

	local container = worker_director.CharacterContainer

	if not IsValid(container) then
		return nil
	end

	local slots = container:GetSlots()

	if not slots then
		return nil
	end

	return slots
end

local function UpdateBasePalTrust(slot)
	if not IsValid(slot) or slot:IsEmpty() then
		return
	end

	local handle = slot:GetHandle()

	if not IsValid(handle) then
		return
	end

	local pal_actor = handle:TryGetIndividualActor()

	-- The slot can exist even if its actual Pal actor isn't loaded on this process.
	if not IsValid(pal_actor) or not pal_actor:IsInitialized() then
		return
	end

	local char_param = pal_actor:GetCharacterParameterComponent()
	local indiv_param = handle:TryGetIndividualParameter()

	if not IsValid(char_param) or not IsValid(indiv_param) then
		return
	end


	local sanity = indiv_param:GetSanityValue()
	local hunger_type = indiv_param:GetHungerType()
	local worker_sick = indiv_param:GetWorkerSick()
	local options = mod_config.trust
	local trust_negative_modifier = 0

	if sanity < MIN_HEALTHY_SANITY then
		trust_negative_modifier = trust_negative_modifier + options.basepal_trust_unhealthy
	end

	if hunger_type ~= HUNGER_DEFAULT then
		trust_negative_modifier = trust_negative_modifier + options.basepal_trust_unhealthy
	end

	if worker_sick ~= WORKER_SICK_NONE then
		trust_negative_modifier = trust_negative_modifier + options.basepal_trust_unhealthy
	end

	if trust_negative_modifier < 0 then
		indiv_param:AddFriendShip(trust_negative_modifier, false)
		return
	end

	if indiv_param:GetFriendshipRank() >= options.basepal_trust_gains_maxlvl then
		return
	end

	if char_param:IsAssignedToAnyWork() and char_param.WorkingState == WORKING_STATE then
		indiv_param:AddFriendShip(options.basepal_trust_working, false)
	end
end

local function UpdateBasePalsGrowth(slot)
	if not IsValid(slot) or slot:IsEmpty() then
		return
	end

	local handle = slot:GetHandle()

	if not IsValid(handle) then
		return
	end

	local pal_actor = handle:TryGetIndividualActor()

	for _, callback in ipairs(on_base_pals_growth_cbs) do
		callback(pal_actor)
	end
end

local function CacheBaseCampModels()
	NotifyOnNewObject(
		UOBJ_PATHS.PAL_BASE_CAMP_MODEL,
		function(base_model)
			if not IsValid(base_model) then
				return
			end

			local id = CDO.kismet_guid_lib.Conv_GuidToString(base_model:GetId()):ToString()

			if not id then
				return
			end

			base_camp_models[id] = base_model
		end
	)
end

local function CacheBasePalsCurrentTrust(player_state)
	for id, base_model in pairs(base_camp_models) do
		local slots = GetBasePalSlots(base_model)

		if not slots then
			return
		end

		for _, slot_param in ipairs(slots) do
			local slot = slot_param:get()
			if not IsValid(slot) or slot:IsEmpty() then
				goto continue
			end

			local handle = slot:GetHandle()

			if not IsValid(handle) then
				goto continue
			end
			local indiv_param = handle:TryGetIndividualParameter()

			if not IsValid(indiv_param) then
				goto continue
			end
			local id = PalUtils.GetPalInstanceIdFromHandle(handle)

			if not id then
				goto continue
			end

			if base_pals_highest_trust[id] == nil then
				base_pals_highest_trust[id] = indiv_param:GetFriendshipRank()
			end

			::continue::
		end
	end
end

local function ModifyTrustGainWorldSetting(controller)
	game_settings = CDO.pal_utility:GetGameSetting(controller)

	if not IsValid(game_settings) then
		DebugLog("Failed to load Game Setting")
		return
	end


	local options = mod_config.trust
	game_settings.FriendshipPoint_Petting = options.pal_trust_petting
	-- Since it's incremented every 5 minute we multiply our per minute value by 5
	game_settings.FriendshipPoint_AutoIncrementOtomo = options.partypal_trust_passive * 5
	game_settings.FriendshipPoint_AutoIncrementActiveOtomo = options.partypal_trust_active * 5
end

local function StartBasePalTrustGrowthChecker()
	-- Start a BASE_PAL_GROWTH_UPDATE_MS timer that updates base pal size based on friendship changes
	LoopInGameThreadWithDelay(
		BASE_PAL_GROWTH_UPDATE_MS,
		function()
			for id, base_model in pairs(base_camp_models) do
				if not IsValid(base_model) then
					base_camp_models[id] = nil
					goto continue
				end

				local slots = GetBasePalSlots(base_model)

				if not slots then
					goto continue
				end

				for _, slot_param in ipairs(slots) do
					local slot = slot_param:get()

					if mod_config.trust.basepals_grow then
						DebugLog("Updating base Pals Size based on Trust")
						UpdateBasePalsGrowth(slot)
					end

					-- Friendship is authoritative state. Only modify it on the server.
					if mod_config.trust.modify_trust_gains and CDO.pal_utility:IsServer(base_model) then
						DebugLog("Updating Base Pals Trust points")
						UpdateBasePalTrust(slot)
					end
				end

				::continue::
			end
		end
	)
end

local function ModifyTrustOnBattleResult()
	RegisterHook(
		FUNC_PATHS.ON_DEAD_CHARACTER,
		function(Context, DeadInfo)
			local dead_actor = Context:get()
			local dead_info = DeadInfo:get()


			if not IsValid(dead_actor) or not dead_info or not CDO.pal_utility:IsServer(dead_actor:GetController()) then
				return
			end

			--
			-- Our Pal was knocked out.
			--
			local dead_pal_otomo = CDO.pal_utility:IsOtomo(dead_actor)
			local debug_dead_pal = tostring(dead_pal_otomo)
			if dead_pal_otomo then
				local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(dead_actor)

				if not IsValid(indiv_param) then
					return
				end

				DebugLog("BATTLE FRIENDSHIP | Otomo defeated | Pal=%s | Dead Pal Otomo? =%s", dead_actor:GetFullName(), debug_dead_pal)
				indiv_param:AddFriendShip(mod_config.trust.activepal_trust_on_death, false)
				return
			end

			--
			-- We only care about defeated wild Pals from here.
			--
			if not CDO.pal_utility:IsWildNPC(dead_actor) then
				return
			end

			local attacker = dead_info.LastAttacker

			if not IsValid(attacker) then
				return
			end

			--
			-- Otomo got the killing blow.
			--
			if CDO.pal_utility:IsOtomo(attacker) then
				local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(attacker)

				if not IsValid(indiv_param) then
					return
				end
				DebugLog("BATTLE FRIENDSHIP | Otomo defeated wild Pal | Pal=%s | DeadPal Otomo?= %s", attacker:GetFullName(), debug_dead_pal)
				indiv_param:AddFriendShip(mod_config.trust.activepal_trust_on_kill, false)
			end
		end
	)
end

local function RegisterWorkSuitabilityRankUpHook()
	RegisterHook(
		FUNC_PATHS.ON_UPDATE_WORKER_FRIENDSHIP_RANK,
		function(Context, IndividualParameter, NewRank, OldRank, bIsFirstRankup)
			local worker_director = Context:get()
			local indiv_param = IndividualParameter:get()
			local new_rank = NewRank:get()
			local old_rank = OldRank:get()

			if not IsValid(worker_director) or not IsValid(indiv_param) or not CDO.pal_utility:IsServer(worker_director) then
				return
			end

			local id = PalUtils.GetPalInstanceIdFromIndivId(indiv_param.IndividualId)

			if not id then
				return
			end

			-- Trust went down. Work suitability is permanent, so do nothing.
			if new_rank <= old_rank or new_rank <= 0 then
				return
			end

			-- If this is the first time this base pal ranked up cache it. If not, then check the highest trust this base pal had reached.
			-- If the new rank is less than that we don't add work suitability rank as this represents the case of trust falling down and going up again.
			-- This however only works for the current session. For permanent solution we'd need to save this data to a file.
			if base_pals_highest_trust[id] == nil then
				base_pals_highest_trust[id] = new_rank
			elseif new_rank <= base_pals_highest_trust[id] then
				return
			end

			local gender = indiv_param:GetGenderType()
			local gender_based_gains = mod_config.work_suitability.gender_based_gains
			local male_worksuits = mod_config.work_suitability.male
			local female_worksuits = mod_config.work_suitability.female

			for worksuit_name, worksuit_val in pairs(PalUtils.PAL_WORK_SUITABILITY) do
				-- since our enum is dual indexed by key and val we only need the values/numbers here
				if type(worksuit_val) ~= "number" then
					goto continue
				end

				if indiv_param:HasWorkSuitability(worksuit_val) then
					if gender_based_gains and gender == PalUtils.PAL_GENDER.Male and not CoreUtils.Contains(male_worksuits, worksuit_name) then
						goto continue
					elseif gender_based_gains and gender == PalUtils.PAL_GENDER.Female and not CoreUtils.Contains(female_worksuits, worksuit_name) then
						goto continue
					end

					local current_rank = indiv_param:GetWorkSuitabilityRank(worksuit_val)

					local max_rank = 10
					if game_settings then
						max_rank = game_settings.WorkSuitabilityMaxRank
					end

					if current_rank < max_rank then
						DebugLog("Adding WorkSuit rank to base Pal on Trust Level up | ID=%s", id)
						indiv_param:SetWorkSuitabilityAddRank(worksuit_val, 1)
					end
				end
				::continue::
			end
		end
	)
end

function TrustGrowth.RegisterOnUpdateBasePalsGrowth(cb)
	table.insert(on_base_pals_growth_cbs, cb)
end

function TrustGrowth.Init()
	local options = mod_config.trust

	CacheBaseCampModels()
	Server.RegisterOnNotifyWorldLoadedToServer(CacheBasePalsCurrentTrust, true)

	if options.modify_trust_gains then
		Server.RegisterOnNewWorldLoadedCallback(ModifyTrustGainWorldSetting)
		ModifyTrustOnBattleResult()
	end

	if mod_config.work_suitability.basepals_gain_worksuit then
		RegisterWorkSuitabilityRankUpHook()
	end

	if options.basepals_grow or options.modify_trust_gains then
		StartBasePalTrustGrowthChecker()
	end
end

return TrustGrowth
