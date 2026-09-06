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
local DebugLogActor = PalUtils.DebugLogActor
local IsValid = UnrealUtils.IsValid
local UObjects = UnrealUtils.UObjects

--local vars
local mod_config = ModConfigManager.GetConfig()
local saddle_items_cache = {}
local weapon_saddles_cache = {}

-- Inorder to filter the partner skill items only for ride pals. We need to perform 2 checs
-- First check whether in the Item Data Table, the current item id has the word "Saddle" the IconName
-- For, mounts with special weapons/abilities however this name is different. For those check
-- if in the partner skill parameter table, the active skill name contains the word "Ride"	
local function IsItemForRidePal(item_id, item_dt, partner_skill_dt)
	local item_data = item_dt:FindRow(item_id)

	if item_data then
		local icon_name = item_data.IconName:ToString()

		if icon_name:find("Saddle", 1, true) then
			return true
		end
	end
	-- If we didn't find "Saddle" now look for "Ride" in active skill name
	-- Strip "SkillUnlock_" to get the Pal Name which can be used for lookup in the PartnerSkillParameter table
	local pal_name = item_id:match("^SkillUnlock_(.+)$")

	if not pal_name then
		return false
	end

	-- An edge case. Maybe a typo by the devs. PartnerSkillParameter has the key "ThunderDog_Ice" where as item id has the suffix with the small "d"
	if pal_name == "Thunderdog_Ice" then
		pal_name = "ThunderDog_Ice"
	end

	local partner_skill_data = partner_skill_dt:FindRow(pal_name)

	if not partner_skill_data then
		return false
	end

	-- Check if the active skill name has "Ride" in it. If so then this is rideable pal
	local active_skill = partner_skill_data.ActiveSkill
	if not active_skill or not active_skill.SkillName then
		return false
	end

	local skill_name = active_skill.SkillName:ToString()
	local is_weapon = not active_skill.IsRidingActiveSkillNotWeapon
	local isRide = skill_name:find("Ride", 1, true)

	return isRide ~= nil, is_weapon
end

local function InitItemCache(world_context)
	if #saddle_items_cache ~= 0 and #weapon_saddles_cache ~= 0 then
		return true
	end

	--Build ride cache if not available
	local randomizer_manager = PalUtils.pal_utility:GetRandomizerManager(world_context)

	if not IsValid(randomizer_manager) then
		DebugLog("Building Ride Item Cache: RandomizerManager is not ready")
		return nil
	end

	-- Palworld keeps a list of all partner skill required items in `RandomizerManager.InitialLoginGrantItems`
	local partner_skill_items = randomizer_manager.InitialLoginGrantItems

	if not partner_skill_items or partner_skill_items:GetArrayNum() == 0 then
		DebugLog("Ride Item Cache: InitialLoginGrantItems is not ready")
		return nil
	end

	local item_dt = UObjects[UOBJ_PATHS.GAME_ITEM_DT]
	local partner_skill_dt = UObjects[UOBJ_PATHS.GAME_PARTNER_SKILL_DT]

	if not IsValid(item_dt) then
		DebugLog("Ride Item Cache: DT_ItemDataTable is not ready")
		return nil
	end

	if not IsValid(partner_skill_dt) then
		DebugLog("Ride Item Cache: DT_PartnerSkillParameter is not ready")
		return nil
	end

	partner_skill_items:ForEach(
		function(_, item)
			local item_id = item:Get():ToString() or ""
			local is_ride_item, is_weapon = IsItemForRidePal(item_id, item_dt, partner_skill_dt)

			if is_ride_item then
				if is_weapon then
					table.insert(weapon_saddles_cache, item_id)
				else
					table.insert(saddle_items_cache, item_id)
				end
			end
		end
	)

	if #saddle_items_cache == 0 and #weapon_saddles_cache == 0 then
		DebugLog("Ride Item Cache is empty: No ride gear was found")
		return false
	else
		DebugLog("Ride Item Cache built with. Saddles: %d | Weapon_Saddles: %d", #saddle_items_cache, #weapon_saddles_cache)
	end

	if CoreUtils.debug_logging then
		for _, item_id in ipairs(saddle_items_cache) do
			DebugLog("Saddle Item: " .. item_id)
		end
		for _, item_id in ipairs(weapon_saddles_cache) do
			DebugLog("Saddle Weapon Item: " .. item_id)
		end
	end
	return true
end

local function GrantRideItems(player_state)
	--local inventory_data = GetPlayerInventory(player_controller)
	if not IsValid(player_state) then
		DebugLog("Player State was not valid in GetPlayerInventory() while granting ride items")
		return
	end

	local inventory_data = player_state:GetInventoryData()

	if not IsValid(inventory_data) then
		DebugLog("Inventory Data was not valid in GetPlayerInventory() while granting ride items")
		return
	end

	local granted_count = 0
	if mod_config.grant_saddles then
		for _, item_str in ipairs(saddle_items_cache) do
			local item_id = FName(item_str)

			-- If this item doesn't already exist, grant it to the player
			if not inventory_data:IsExistItem(item_id) then
				local result = inventory_data:AddItem_ServerInternal(item_id, 1, false, 0.0, false)

				DebugLog("Adding Item: %s | Result: %s", item_str, tostring(result))

				granted_count = granted_count + 1
			end
		end
	end

	if mod_config.grant_saddle_weapons then
		for _, item_str in ipairs(weapon_saddles_cache) do
			local item_id = FName(item_str)

			-- If this item doesn't already exist, grant it to the player
			if not inventory_data:IsExistItem(item_id) then
				local result = inventory_data:AddItem_ServerInternal(item_id, 1, false, 0.0, false)

				DebugLog("Adding Item: %s | Result: %s", item_str, tostring(result))

				granted_count = granted_count + 1
			end
		end
	end

	DebugLog("Pal Gear check complete for %s | Added: %d", player_state:GetPlayerController():GetFullName(), granted_count)
end

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
		return curr_scale.X < mod_config.min_ride_scales.XS
	elseif pal_size == PAL_SIZE.S then
		return curr_scale.X < mod_config.min_ride_scales.S
	elseif pal_size == PAL_SIZE.M then
		return curr_scale.X < mod_config.min_ride_scales.M
	elseif pal_size == PAL_SIZE.L then
		return curr_scale.X < mod_config.min_ride_scales.L
	elseif pal_size == PAL_SIZE.XL then
		return curr_scale.X < mod_config.min_ride_scales.XL
	end
end

local function IsBuiltInRandomizerEnabled(world_context)
	local randomizer_manager = PalUtils.pal_utility:GetRandomizerManager(world_context)

	if not IsValid(randomizer_manager) then
		return false
	end

	local randomizer_type = randomizer_manager:GetRandomizerType()

	DebugLog(
		"Randomizer | Type: %s | Initialized: %s",
		tostring(randomizer_type),
		tostring(randomizer_manager:IsInitializedRandomizer())
	)

	-- Comparison to None goes here once we confirm the Lua enum value.
end

local function wrapTextInRed(text)
	return "<NumRed_13>" .. text .. "</>"
end

local function RegisterGrantRideItemsHook()
	RegisterHook(
		FUNC_PATHS.NOTIFY_ON_WORLD_LOAD_TO_SERVER,
		function()
		end,
		function(Context)
			local player_state = Context:get()

			if not IsValid(player_state) then
				DebugLog("Player State was not valid in: %s", FUNC_PATHS.NOTIFY_ON_WORLD_LOAD_TO_SERVER)
				return
			end

			-- If player is playing with built in randmoizer on, then return as it already grants all partner skill items.
			if IsBuiltInRandomizerEnabled(player_state) then
				return
			end

			local inventory_data = player_state:GetInventoryData()

			if not IsValid(inventory_data) then
				DebugLog("Player inventory was not valid in: %s", FUNC_PATHS.NOTIFY_ON_WORLD_LOAD_TO_SERVER)
				return
			end

			if not InitItemCache(player_state) then
				return
			end

			GrantRideItems(player_state)
		end
	)
end

-- Module exported functions
local function RegisterDisableTinyRideHooks()
	-- This function is used in locking the partner/mount skill in the main game. Also the widget padlock on the bottom center.
	RegisterHook(
		FUNC_PATHS.IS_RESTRICTED_BY_ITEMS,
		function()
		end,
		function(Context, ReturnValue, Trainer)
			--DebugLog("Inside IsRestricted")
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
				--DebugLogActor("Marker Not Found for", pal_actor)
				return
			end

			if not PalUtils.IsLocalPlayersOtomo(pal_actor) then
				return
			end

			if IsRidePalTiny(pal_actor) then
				--DebugLogActor("Pal size too small, locking pskill.", pal_actor)
				ReturnValue:set(true)
			end

			--if mod_config.disable_saddle_requirement then
			--	DebugLogActor("Saddle Requirements disabled.", pal_actor)
			--	ReturnValue:set(false)
			--end
		end
	)
	-- Show padlock and text on Pal menu and overlays (when hovering over padlock in Pal details) if pal is too tiny to ride
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

					if not IsRidePalTiny(pal) then
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

					if not IsRidePalTiny(pal) then
						return
					end

					local info = Info:get()
					local sub_info = SubInfo:get()
					local localized_text = string.format(LocalizationManager.GetLocalizedText(LocalizeTextKeys.PAL_MENU_OVERLAY_TEXT), "4")
					local localized_text = wrapTextInRed(localized_text)

					if info and Title:get() then
						widget.WBP_MainMenu_PalSkillInfo:DisplayCommonInfo(Title:get(), info, FText(localized_text))
					end
				end
			)
			return true
		end
	)
end

function Ride.Init()
	local min_ride_scales = mod_config.min_ride_scales

	if min_ride_scales.XS == 0 and
		min_ride_scales.S == 0 and
		min_ride_scales.M == 0 and
		min_ride_scales.L == 0 and
		min_ride_scales.XL == 0 then
		return
	end
	RegisterDisableTinyRideHooks()

	if mod_config.grant_saddle_weapons or mod_config.grant_saddles then
		RegisterGrantRideItemsHook()
	end
end

return Ride
