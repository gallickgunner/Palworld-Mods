---@class PalLifecycle
local PalLifecycle = {}
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local UPaths = require("Constants.upaths")
local UEHelpers = require("UEHelpers")

-- Aliases used often
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local FUNC_PATHS = UPaths.FUNC_PATHS
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local on_end_play_cbs = {}
local on_pal_init_cbs = {}
local on_wildlife_action_start_cbs = {}
local aiaction_wildlife_hook_reg = false

function PalLifecycle.RegisterOnActorEndPlay(cb)
	table.insert(on_end_play_cbs, cb)
end

function PalLifecycle.RegisterOnWildLifeActionStart(cb)
	table.insert(on_wildlife_action_start_cbs, cb)
end

function PalLifecycle.RegisterOnInitializedCharacter(cb)
	table.insert(on_pal_init_cbs, cb)
end

function PalLifecycle.Init()
	RegisterHook(
		FUNC_PATHS.ON_CHARACTER_INIT,
		function()
		end,
		function(Context, Character)
			local char_param = Context:get()
			local actor = Character:get()

			if not IsValid(char_param) or not IsValid(actor) then
				return
			end

			---@class CharInitContext
			---@field actor any
			---@field char_param any
			local context = {
				actor = actor,
				char_param = char_param
			}

			for _, callback in ipairs(on_pal_init_cbs) do
				callback(context)
			end
		end
	)

	NotifyOnNewObject(UOBJ_PATHS.BP_AIACTION_WILD_LIFE,
		function()
			if not aiaction_wildlife_hook_reg then
				aiaction_wildlife_hook_reg = UnrealUtils.TryRegisterBPHook(
					FUNC_PATHS.BP_WILD_LIFE_ACTION_START,
					function(Context, ControlledPawn)
						local action = Context:get()
						local pal_actor = ControlledPawn:get()

						if not IsValid(pal_actor) or not IsValid(action) then
							return
						end

						---@class WLActionStartContext
						---@field actor any
						---@field action any
						local context = {
							actor = pal_actor,
							action = action
						}

						for _, callback in ipairs(on_wildlife_action_start_cbs) do
							callback(context)
						end
					end
				)
			end

			if aiaction_wildlife_hook_reg then
				return true
			end
		end
	)

	RegisterEndPlayPreHook(
		function(Context, EndPlayReason)
			local actor = Context:get()

			if not IsValid(actor) then
				return
			end

			---@class ActorEndPlayContext
			---@field actor any
			local context = {
				actor = actor,
			}

			for _, callback in ipairs(on_end_play_cbs) do
				callback(context)
			end
		end
	)
end

return PalLifecycle
