---@class PalTraits
local PalTraits = {}

local Server = require("Server.server")
local PalLifeCycle = require("SharedHooks.pal_lifecycle")

local CDO = require("Utils.cdo")
local UPaths = require("Constants.upaths")
local PalUtils = require("Utils.pal_utils")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local Constants = require("Constants.constants")
local ModConfigManager = require("Managers.mod_config_manager")

-- Aliases used often
local Log = CoreUtils.Log
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local UObjects = UnrealUtils.UObjects
local UOBJ_PATHS = UPaths.UOBJ_PATHS

local LEADER_PASSIVE_SKILL_NAME = Constants.LEADER_PASSIVE_SKILL_NAME
local LEADER_PASSIVE_SKILL_FNAME = FName(LEADER_PASSIVE_SKILL_NAME)

local NO_OVERRIDE_NAME = FName("None")
local ATK_ENUM_NAME = "ShotAttack"
local DEF_ENUM_NAME = "Defense"


local mod_config = ModConfigManager.GetConfig()
local modified_pals_cache = {}
local wild_leader_found_cbs = {}


local function HasNegativeStatSkill(effect_type, effect_val)
	local effect_name = CDO.passive_skill_effect:GetNameByValue(effect_type)
	effect_name = PalUtils.GetSanitizedEnumName(effect_name:ToString())

	if effect_name == ATK_ENUM_NAME and effect_val < 0.0 then
		return true
	elseif effect_name == DEF_ENUM_NAME and effect_val < 0.0 then
		return true
	end
	return false
end

local function UpadteLeaderPassiveSkills(pal_actor)
	local individual_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)

	if not IsValid(individual_param) then
		return false
	end

	local passive_skill_manager = CDO.pal_utility:GetPassiveSkillManager(pal_actor)

	if not IsValid(passive_skill_manager) then
		return false
	end

	local passive_skill_dt = passive_skill_manager.PassiveSkillDataTable

	if not IsValid(passive_skill_dt) then
		return false
	end

	local passive_component = pal_actor:GetComponentByClass(UObjects[UOBJ_PATHS.PAL_PASSIVE_SKILL_COMPONENT])

	if not IsValid(passive_component) then
		return
	end

	-- Make sure PalSchema actually loaded our custom skill.
	local leader_trait_row = passive_skill_dt:FindRow(LEADER_PASSIVE_SKILL_NAME)

	if not leader_trait_row then
		DebugLog("LeaderTrait passive does not exist in DT_PassiveSkill_Main")
		return false
	end

	local passive_skills = individual_param:GetPassiveSkillList()

	if not passive_skills then
		return false
	end


	local best_skill = nil
	local best_skill_rank = math.mininteger
	local continue = false
	for _, skill_name in ipairs(passive_skills) do
		continue = false

		local skill_str = skill_name:get():ToString()
		-- If we found leader skill already then we have already updated this pal's skills. Don't check any further
		if skill_str == LEADER_PASSIVE_SKILL_NAME then
			return true
		end

		local skill_row = passive_skill_dt:FindRow(skill_str)

		if not skill_row then
			goto continue
		end
		--Remove all rank -3 skills from leader
		if skill_row and skill_row.Rank <= -3 then
			individual_param:RemovePassiveSkill(skill_name)
			continue = true
		end

		-- Remove any skills that give negative ATK/DEF to leader pals.
		if HasNegativeStatSkill(skill_row.EffectType1, skill_row.EffectValue1)
			or HasNegativeStatSkill(skill_row.EffectType2, skill_row.EffectValue2)
			or HasNegativeStatSkill(skill_row.EffectType3, skill_row.EffectValue3)
			or HasNegativeStatSkill(skill_row.EffectType4, skill_row.EffectValue4)
		then
			individual_param:RemovePassiveSkill(skill_name)
			continue = true
		end

		--Remove the best possible skill there is as our custom leader skill is actually pretty good
		if not continue and skill_row and skill_row.Rank > best_skill_rank then
			best_skill = skill_name
			best_skill_rank = skill_row.Rank
		end

		::continue::
	end

	local count = #passive_skills

	-- If there is an empty passive slot. Just add our leader skill
	if count < 4 then
		individual_param:AddPassiveSkill(LEADER_PASSIVE_SKILL_FNAME, NO_OVERRIDE_NAME)
		return true
	end


	if not best_skill then
		DebugLog("Failed to find any skill to replace with our leader skill")
		return false
	end

	--If no empty slot then override an existing best skill
	individual_param:AddPassiveSkill(LEADER_PASSIVE_SKILL_FNAME, best_skill)
	return true
end

local function SetLeaderGenderToMale(pal_actor)
	local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)

	if not IsValid(indiv_param) then
		return false
	end

	if indiv_param:GetGenderType() ~= PalUtils.PAL_GENDER.Male then
		indiv_param.SaveParameter.Gender = PalUtils.PAL_GENDER.Male
	end
end

local function CreateUniqueLeaderPal(pal_actor)
	local controller = pal_actor:GetController()

	UpadteLeaderPassiveSkills(pal_actor)
	SetLeaderGenderToMale(pal_actor)

	for _, callback in ipairs(wild_leader_found_cbs) do
		-- Apply the correct size to leaders on server
		callback(pal_actor)
	end
end

local function SetWildPalWorkSuitBonus(indiv_param)
	local categories = nil
	if indiv_param:GetGenderType() == PalUtils.PAL_GENDER.Male then
		categories = mod_config.work_suitability.male
	else
		categories = mod_config.work_suitability.female
	end

	local game_settings = CDO.pal_utility:GetGameSetting(indiv_param)

	for _, worksuit_name in ipairs(categories) do
		local worksuit_val = PalUtils.PAL_WORK_SUITABILITY[worksuit_name]
		if worksuit_val ~= nil and indiv_param:HasWorkSuitability(worksuit_val) then
			local current_rank = indiv_param:GetWorkSuitabilityRank(worksuit_val)

			local max_rank = 10
			if game_settings then
				max_rank = game_settings.WorkSuitabilityMaxRank
			end

			if current_rank < max_rank then
				indiv_param:SetWorkSuitabilityAddRank(worksuit_val, mod_config.work_suitability.wildpal_gender_bonus)
			end
		end
	end
end

local function SetWildPalStats(actor, is_leader)
	local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(actor)
	local id = PalUtils.GetPalInstanceIdFromActor(actor)

	if not id or not IsValid(indiv_param) then
		return
	end

	local gender = indiv_param:GetGenderType()
	local settings = nil

	if is_leader and mod_config.stats.leader_bonus then
		settings = mod_config.stats.leader
	else
		if gender == PalUtils.PAL_GENDER.Male then
			settings = mod_config.stats.male
		else
			settings = mod_config.stats.female
		end
	end

	local rank_bonus = settings.rank_bonus
	local talent_bonus = settings.talent_bonus

	if settings.rank_bonus.enabled then
		indiv_param.SaveParameter.Rank_Attack = math.random(rank_bonus.atk.min, rank_bonus.atk.max)
		indiv_param.SaveParameter.Rank_Defence = math.random(rank_bonus.def.min, rank_bonus.def.max)
		indiv_param.SaveParameter.Rank_HP = math.random(rank_bonus.hp.min, rank_bonus.hp.max)
		indiv_param.SaveParameter.Rank_CraftSpeed = math.random(rank_bonus.work_speed.min, rank_bonus.work_speed.max)
	end

	if settings.talent_bonus.enabled then
		indiv_param.SaveParameter.Talent_Shot = CoreUtils.Clamp(math.random(talent_bonus.atk.min, talent_bonus.atk.max), 0, 255)
		indiv_param.SaveParameter.Talent_Defense = CoreUtils.Clamp(math.random(talent_bonus.def.min, talent_bonus.def.max), 0, 255)
		indiv_param.SaveParameter.Talent_HP = CoreUtils.Clamp(math.random(talent_bonus.hp.min, talent_bonus.hp.max), 0, 255)
	end

	if settings.workspeed_bonus > 0.01 then
		local value = indiv_param.SaveParameter.CraftSpeed * (1 + settings.workspeed_bonus / 100)
		indiv_param.SaveParameter.CraftSpeed = math.floor(value + 0.5)
	end

	-- Since we change Talent/Rank, HP will get changed accordingly. So we fetch the updated max HP value and apply that to current HP	
	local current_max_hp = indiv_param:GetMaxHP()
	indiv_param.SaveParameter.Hp.Value = current_max_hp * 1000
end

---@param context WLActionStartContext
local function OnWildLifeActionStart(context)
	local pal_actor = context.actor
	local pal_controller = pal_actor:GetController()

	if not IsValid(pal_controller) then
		return
	end

	local indiv_param = CDO.pal_utility:GetIndividualCharacterParameterByActor(pal_actor)
	local id = PalUtils.GetPalInstanceIdFromActor(pal_actor)
	if not IsValid(indiv_param) or not id then
		return
	end

	local actor_addr = pal_actor:GetAddress()
	local indiv_param_addr = indiv_param:GetAddress()
	local entry = modified_pals_cache[actor_addr]

	-- If cache has an entry for this pal we already modified it
	if entry and entry.pal_id == id and IsValid(entry.indiv_param) and entry.indiv_param_addr == indiv_param_addr then
		return
	end

	modified_pals_cache[actor_addr] = {
		pal_id = id,
		indiv_param_addr = indiv_param_addr,
		indiv_param = indiv_param
	}

	local is_leader = pal_controller:GetIsSquadBehaviour() and pal_controller:IsLeader()
	local squad = pal_controller:GetSquad()

	if is_leader and IsValid(squad) then
		local member_ids = {}
		squad:GetMemberID(member_ids)

		-- If it's a solo spawn then we create a unique leader pal based on the chance value set in the config.
		if #member_ids < 2 then
			local roll = math.random(0, 1)
			if roll < mod_config.solo_spawn_leader_chance then
				CreateUniqueLeaderPal(pal_actor)
			end
		else
			CreateUniqueLeaderPal(pal_actor)
		end
	end

	if mod_config.stats.gender_bonus or (mod_config.stats.leader_bonus and is_leader) then
		SetWildPalStats(pal_actor, is_leader)
	end

	if mod_config.work_suitability.wildpal_gender_bonus > 0 then
		SetWildPalWorkSuitBonus(indiv_param)
	end
end

---@param context ActorEndPlayContext
local function ClearCacheEntry(context)
	local actor = context.actor
	if not IsValid(actor) then
		return
	end
	modified_pals_cache[actor:GetAddress()] = nil
end

function PalTraits.RegisterOnWildLeaderFoundCb(callback)
	table.insert(wild_leader_found_cbs, callback)
end

function PalTraits.Init()
	PalLifeCycle.RegisterOnWildLifeActionStart(OnWildLifeActionStart)
	PalLifeCycle.RegisterOnActorEndPlay(ClearCacheEntry)
end

return PalTraits
