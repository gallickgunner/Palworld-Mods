---@class Ride
local Ride = {}

local ModConfigManager = require("Managers.mod_config_manager")
local LocalizationManager = require("Managers.localization_manager")
local UnrealUtils = require("Utils.unreal_utils")
local CoreUtils = require("Utils.core_utils")
local PalUtils = require("Utils.pal_utils")
local UPaths = require("Constants.upaths")
local LocalizeTextKeys = require("Constants.localization_text_keys")

-- Aliases used often
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local FUNC_PATHS = UPaths.FUNC_PATHS
local Log = CoreUtils.Log
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local UObjects = UnrealUtils.UObjects

--local vars
local mod_config = ModConfigManager.GetConfig()

local function IsRidePalTiny(pal)
	local mesh = pal.Mesh
	local static = pal.StaticCharacterParameterComponent

	if not IsValid(mesh) or not IsValid(static) then
		return nil
	end

	local pal_size = tonumber(static.Size)

	if pal_size == nil then
		return nil
	end

	-- We use DefaultScale3D instead of RelativeScale3D to check because RelativeScale3D is interpolated from 0
	-- to DefaultScale3D when you summon Pals.
	local curr_scale = mesh.DefaultScale3D

	if not curr_scale
		or curr_scale.X <= 0
		or curr_scale.Y <= 0
		or curr_scale.Z <= 0 then
		return nil
	end

	--Log(curr_scale.X)
	local PAL_SIZE = PalUtils.PAL_SIZE

	if pal_size == PAL_SIZE.XS then
		return curr_scale.X < 1.0
	elseif pal_size == PAL_SIZE.S then
		return curr_scale.X < mod_config.min_ride_scale_s
	elseif pal_size == PAL_SIZE.M then
		return curr_scale.X < mod_config.min_ride_scale_m
	elseif pal_size == PAL_SIZE.L then
		return curr_scale.X < mod_config.min_ride_scale_l
	elseif pal_size == PAL_SIZE.XL then
		return curr_scale.X < mod_config.min_ride_scale_xl
	end
end

local function wrapTextInRed(text)
	return "<NumRed_13>" .. text .. "</>"
end

local function OnHotReload(updated_config)
	mod_config = updated_config
end

-- Module exported functions
local function RegisterRideHooks()
	NotifyOnNewObject(UOBJ_PATHS.BP_OTOMO_AI_CONTROLLER,
		function()
			RegisterHook(
				FUNC_PATHS.BP_CAN_COOP,
				function(Context, CanCoop)
					if not mod_config.disable_saddle_requirement then
						return
					end

					-- Vanilla already allows the action. Nothing for us to do.
					if CanCoop:get() then
						return
					end

					local ai_controller = Context:get()

					if not IsValid(ai_controller) then
						return
					end

					local pal_actor = ai_controller:K2_GetPawn()

					if not IsValid(pal_actor) then
						return
					end

					if not PalUtils.IsLocalPlayersOtomo(pal_actor) or not PalUtils.IsPalRideableFromActor(pal_actor) then
						return
					end

					-- Tiny-Pal restriction takes priority over saddle removal.
					if mod_config.disable_tiny_ride_pals and IsRidePalTiny(pal_actor) then
						return
					end

					local partner_skill = pal_actor:GetComponentByClass(UObjects[UOBJ_PATHS.PAL_PSKILL_PARAMETER_COMPONENT])

					if not IsValid(partner_skill) then
						return
					end

					-- Only bypass an actual item restriction.
					if not partner_skill:IsRestrictedByItems(nil) then
						return
					end

					-- Vanilla checks this after IsRestrictedByItems().
					-- Don't bypass cooldown/state/etc.
					if not partner_skill:CanExec() then
						return
					end

					DebugLog("Ignoring Pal Gear restriction for mounting: %s", pal_actor:GetFullName())
					CanCoop:set(true)
				end
			)
			return true
		end
	)

	RegisterHook(
		FUNC_PATHS.IS_PARTNER_SKILL_RESTRICTED,
		function()
		end,
		function(Context, ReturnValue, Trainer)
			DebugLog("Inside IsRestricted")
			local partner_skill = Context:get()

			if not IsValid(partner_skill) then
				return
			end

			local pal_actor = partner_skill:GetOwner()

			if not IsValid(pal_actor) then
				return
			end

			local marker = pal_actor:GetComponentByClass(UObjects[UOBJ_PATHS.PAL_RIDE_MARKER_COMPONENT])

			if not IsValid(marker) then
				DebugLog("Marker Not Found for PalName: %s | ID: %s", pal_actor:GetFullName(), PalUtils.GetUniquePalIDFromActor(pal_actor))
				return
			end

			DebugLog(
				"Restriction check | Pal: %s | IsPlayersOtomo: %s | OldPartyCheck: %s | OriginalResult: %s",
				pal_actor:GetFullName(),
				tostring(PalUtils.pal_utility:IsPlayersOtomo(pal_actor)),
				tostring(PalUtils.IsLocalPlayersOtomo(pal_actor)),
				tostring(ReturnValue:get()))
			if not PalUtils.IsLocalPlayersOtomo(pal_actor) then
				return
			end

			if mod_config.disable_tiny_ride_pals and IsRidePalTiny(pal_actor) then
				DebugLog("Pal size too small, locking pskill. PalName: %s | ID: %s", pal_actor:GetFullName(), PalUtils.GetUniquePalIDFromActor(pal_actor))
				ReturnValue:set(true)
			end

			--if mod_config.disable_saddle_requirement then
			--	DebugLog("Saddle Requirements disabled. PalName: %s | ID: %s", pal_actor:GetFullName(), PalUtils.GetUniquePalIDFromActor(pal_actor))
			--	ReturnValue:set(false)
			--end
		end
	)

	RegisterHook(
		FUNC_PATHS.GET_PAL_RESTRICT_ITEM,

		function()
		end,

		function(Context, ReturnValue, WorldContextObject, CharacterID, ItemID)
			if not mod_config.disable_saddle_requirement then
				return
			end

			local world_context = WorldContextObject:get()

			if not IsValid(world_context) then
				return
			end

			if not world_context:IsA(UObjects[UOBJ_PATHS.BP_PAL_MENU]) then
				return
			end

			local handle = world_context.CachedIndividualHandle

			if not IsValid(handle) then
				return
			end

			local parameter = handle:TryGetIndividualParameter()

			if not IsValid(parameter) then
				return
			end

			local character_id = CharacterID:get()
			local handle_character_id = parameter:GetCharacterID()

			if character_id:ToString() ~= handle_character_id:ToString() then
				return
			end

			if not PalUtils.IsPalRideableFromHandle(handle) then
				return
			end

			DebugLog("Ignoring Partner Skill restriction item for rideable Pal: %s", character_id:ToString())

			ReturnValue:set(false)
			--ItemID:set(FName("None"))
		end
	)

	-- Show padlock and text on Pal menu and overlays if pal is too tiny to ride
	NotifyOnNewObject(
		UOBJ_PATHS.BP_PAL_MENU,
		function()
			RegisterHook(
				FUNC_PATHS.BP_PAL_MENU_PARTNER_SKILL_LOCK,
				function(Context, CharacterID)
					local widget = Context:get()

					if not IsValid(widget) then
						return
					end

					local handle = widget.CachedIndividualHandle

					if not IsValid(handle) then
						return
					end

					local pal = handle:TryGetIndividualActor()

					if not IsValid(pal, "Pal Actor wasn't created in post hook: %s", FUNC_PATHS.BP_PAL_MENU_PARTNER_SKILL_LOCK) then
						return
					end

					-- Not a rideable pal, return
					if not PalUtils.IsPalRideableFromActor(pal) then
						return
					end

					if not mod_config.disable_tiny_ride_pals or not IsRidePalTiny(pal) then
						return
					end

					local localized_text = LocalizationManager.GetLocalizedText(LocalizeTextKeys.PAL_MAIN_MENU_TEXT)
					local party_menu_lock_text = FText(localized_text)
					local pal_menu_detail_text = FText(localized_text)

					widget.CanvasPanelLockText:SetVisibility(0x4)
					widget.BackgroundBlur_Lock_1:SetVisibility(0x4)
					widget.CanvasPanelLockText_1:SetVisibility(0x4)

					widget.CanvasPanel_PartnerSkill:SetRenderOpacity(0.6)
					widget.CanvasPanelLock_1:SetRenderOpacity(0.6)

					widget.Text_PartnerSkillLockItem:SetText(pal_menu_detail_text)
					widget.BP_PalTextBlock_C_2:SetText(party_menu_lock_text)
				end
			)

			RegisterHook(
				FUNC_PATHS.BP_PAL_MENU_PSKILL_OPEN_OVERLAY,
				function(Context, RelativeWidget, AnchorPosition, OverrideInfoWidgetAlignment, Title, Info, SubInfo)
					local widget = Context:get()
					if not IsValid(widget) then
						return
					end

					local relative_widget = RelativeWidget:get()
					local lock_button = widget.WBP_PalInvisibleButton_Lock

					if not IsValid(relative_widget) or not IsValid(lock_button) then
						return
					end

					if relative_widget:GetAddress() ~= lock_button:GetAddress() then
						return
					end

					local handle = widget.CachedIndividualHandle

					if not IsValid(handle) then
						return
					end

					local pal = handle:TryGetIndividualActor()
					if not IsValid(pal, "Actor not valid in: %s", FUNC_PATHS.BP_PAL_MENU_PSKILL_OPEN_OVERLAY) then
						return
					end

					if not mod_config.disable_tiny_ride_pals or not IsRidePalTiny(pal) then
						return
					end

					local info = Info:get()
					local sub_info = SubInfo:get()
					local localized_text = string.format(LocalizationManager.GetLocalizedText(LocalizeTextKeys.PAL_MENU_OVERLAY_TEXT), "4")
					local localized_text = wrapTextInRed(localized_text)
					DebugLog("BEFORE DISPLAY COMMON INFO")
					if info and Title:get() then
						widget.WBP_MainMenu_PalSkillInfo:DisplayCommonInfo(Title:get(), info, FText(localized_text))
					end
					DebugLog("AFTER DISPLAY COMMON INFO")
					--[[
					local info_widget = widget.WBP_MainMenu_PalSkillInfo

					if not IsValid(info_widget) or not IsValid(info_widget.BP_PalRichTextBlock_SubInfo) or not IsValid(info_widget.BP_PalRichTextBlock_Info) then
						return
					end


					--if info then
					--	local text = info:ToString()
					--	text = text:gsub("^Can be ridden[^\r\n]*", "Partner Skill locked: This Pal is too young.")
					--	info_widget.BP_PalRichTextBlock_Info:SetText(FText(text))
					--end

					if sub_info then
						local localized_text = string.format(LocalizationManager.GetLocalizedText(LocalizeTextKeys.PAL_MENU_OVERLAY_TEXT), "4")
						local localized_text = wrapTextInRed(localized_text)
						info_widget.BP_PalRichTextBlock_SubInfo:SetVisibility(0x4)

						info_widget.BP_PalRichTextBlock_SubInfo:SetText(FText(localized_text))
					end--]]
				end
			)
			return true
		end
	)
end

function Ride.Init()
	if not mod_config.disable_tiny_ride_pals then
		return
	end
	ModConfigManager.RegisterHotReloadCallback(OnHotReload)
	RegisterRideHooks()
end

return Ride
