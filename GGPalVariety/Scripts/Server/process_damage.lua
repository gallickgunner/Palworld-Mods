---@class ProcessDamage
local ProcessDamage = {}

local CDO = require("Utils.cdo")
local Server = require("Server.server")
local UPaths = require("Constants.upaths")
local PalUtils = require("Utils.pal_utils")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local ModConfigManager = require("Managers.mod_config_manager")

local Log = CoreUtils.Log
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local FUNC_PATHS = UPaths.FUNC_PATHS
local UOBJ_PATHS = UPaths.UOBJ_PATHS

local option_subsystem = nil
--local default_damage_rate_to_pals = nil
--local default_damage_rate_from_pals = nil
local damage_setting_stack = {}
local debug_damage_depth = 0

local function OnNewWorldLoaded(controller)
	option_subsystem = CDO.pal_utility:GetOptionSubsystem(controller)

	if not IsValid(option_subsystem) then
		DebugLog("Failed to load option subsystem")
		return
	end

	local game_settings = CDO.pal_utility:GetGameSetting(controller)

	if not IsValid(game_settings) then
		DebugLog("Failed to load Game Setting")
		return
	end

	local config = ModConfigManager.GetConfig()

	--default_damage_rate_to_pals = world_settings.PalDamageRateDefense
	--default_damage_rate_from_pals = world_settings.PalDamageRateAttack

	game_settings.WazaReselectTimeoutSeconds = config.difficulty.skill_reselect_timeout
	game_settings.CommonAttackSkipTimeoutSeconds = config.difficulty.default_atk_skip_timeout
	game_settings.OtomoDamageRate_Defense = config.difficulty.partypal_damage_taken
	game_settings.DamageRate_WealPoint = config.difficulty.weakpoint_damage_rate
	game_settings.DamageRate_StrongPoint = config.difficulty.strongpoint_damage_rate
end


local function GetDamageRateToPal(defender_pal)
	if not IsValid(defender_pal.StaticCharacterParameterComponent) then
		return nil
	end

	local mod_config = ModConfigManager.GetConfig()
	local is_boss = PalUtils.IsBossExcludingRare(defender_pal.StaticCharacterParameterComponent)

	if is_boss then
		return mod_config.difficulty.damage_rate_to_boss
	end

	if PalUtils.IsWildLeader(defender_pal) then
		return mod_config.difficulty.damage_rate_to_leader
	end

	return mod_config.difficulty.damage_rate_to_normal
end


local function GetDamageRateFromPal(attacker_pal)
	if not IsValid(attacker_pal.StaticCharacterParameterComponent) then
		return nil
	end
	local mod_config = ModConfigManager.GetConfig()
	local is_boss = PalUtils.IsBossExcludingRare(attacker_pal.StaticCharacterParameterComponent)

	if is_boss then
		return mod_config.difficulty.damage_rate_from_boss
	end

	if PalUtils.IsWildLeader(attacker_pal) then
		return mod_config.difficulty.damage_rate_from_leader
	end

	return mod_config.difficulty.damage_rate_from_normal
end

local function ProcessDamagePreHook(attacker, defender)
	debug_damage_depth = debug_damage_depth + 1
	DebugLog("PROCESS DAMAGE PRE | depth=%i", debug_damage_depth)

	local settings = option_subsystem.OptionWorldSettings

	if not settings then
		DebugLog("OptionWorldSettings nil")
		return
	end

	local is_attacker_wildpal = CDO.pal_utility:IsPalMonster(attacker) and CDO.pal_utility:IsWildNPC(attacker)
	local is_defender_wildpal = CDO.pal_utility:IsPalMonster(defender) and CDO.pal_utility:IsWildNPC(defender)
	local new_damage_rate = nil
	local entry = {}

	if is_defender_wildpal then
		new_damage_rate = GetDamageRateToPal(defender)

		local old_pal_damage_rate = tonumber(settings.PalDamageRateDefense)

		if not old_pal_damage_rate then
			return
		end

		entry.old_defense = old_pal_damage_rate
		settings.PalDamageRateDefense = old_pal_damage_rate * new_damage_rate
		DebugLog("Pal Damage Rate Defense  | Old=%s | New=%s", tostring(old_pal_damage_rate), tostring(settings.PalDamageRateDefense))
	end

	if is_attacker_wildpal then
		new_damage_rate = GetDamageRateFromPal(attacker)
		local old_pal_damage_rate = tonumber(settings.PalDamageRateAttack)

		if not old_pal_damage_rate then
			return
		end
		entry.old_attack = old_pal_damage_rate
		settings.PalDamageRateAttack = old_pal_damage_rate * new_damage_rate
		DebugLog("Pal Damage Rate Attack  | Old=%s | New=%s", tostring(old_pal_damage_rate), tostring(settings.PalDamageRateAttack))
	end

	table.insert(damage_setting_stack, entry)
end

local function ProcessDamagePostHook(entry)
	DebugLog("PROCESS DAMAGE POST | depth=%i", debug_damage_depth)
	debug_damage_depth = debug_damage_depth - 1

	if not IsValid(option_subsystem) then
		return
	end

	if entry.old_defense then
		option_subsystem.OptionWorldSettings.PalDamageRateDefense = entry.old_defense
	end

	if entry.old_attack then
		option_subsystem.OptionWorldSettings.PalDamageRateAttack = entry.old_attack
	end
end

function ProcessDamage.Init()
	Server.RegisterOnNewWorldLoadedCallback(OnNewWorldLoaded)

	local mod_config = ModConfigManager.GetConfig()

	if not mod_config.difficulty.enable_damage_multiplier then
		return
	end

	-- These hooks were tested to only work on SP and COOP. They dont fire on dedicated servers. We abuse the native settings for
	-- damage to/from pals and players and modify them after checking who the attacker/defender is. Let palworld calculate based on our modified
	-- rates then swap back to default after damage is calculated.
	RegisterHook(
		FUNC_PATHS.PROCESS_DAMAGE,
		function(Context, Attacker, Defender, DamageInfo)
			local attacker = Attacker:get()
			local defender = Defender:get()

			if not IsValid(attacker) or not IsValid(defender) or not IsValid(option_subsystem) then
				return
			end

			ProcessDamagePreHook(attacker, defender)
		end,
		function(Context, Attacker, Defender, DamageInfo)
			local entry = table.remove(damage_setting_stack)
			if not entry then
				return
			end
			ProcessDamagePostHook(entry)
		end
	)
end

return ProcessDamage
