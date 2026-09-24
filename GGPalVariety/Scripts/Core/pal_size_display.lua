---@class PalSizeDisplay
local PalSizeDisplay = {}

local CDO = require("Utils.cdo")
local ModConfigManager = require("Managers.mod_config_manager")
local CoreUtils = require("Utils.core_utils")
local UnrealUtils = require("Utils.unreal_utils")
local PalUtils = require("Utils.pal_utils")
local UPaths = require("Constants.upaths")

-- Aliases used often
local DebugLog = CoreUtils.DebugLog
local IsValid = UnrealUtils.IsValid
local FUNC_PATHS = UPaths.FUNC_PATHS
local UOBJ_PATHS = UPaths.UOBJ_PATHS
local UObjects = UnrealUtils.UObjects

local size_rows = {}
local size_rows_by_button = {}

local work_suitability_y = nil
local food_panel_y = nil
local stats_info_height = nil
local button_hovered_hook_reg = false
local button_unhovered_hook_reg = false
local setup_status_hook_reg = false
local mod_config = ModConfigManager.GetConfig()


--------------------- Basic helper to construct UI widget objects -------------------------

local function ConstructWidget(menu, widget_class)
	if not IsValid(menu) or not widget_class then
		return nil
	end

	local widget_tree = menu.WidgetTree

	if not widget_tree then
		DebugLog("Pal size row: WidgetTree not found")
		return nil
	end

	local widget = StaticConstructObject(widget_class, widget_tree)

	if not IsValid(widget) then
		DebugLog("Failed to construct a widget %s", widget_class:GetFullName())
		return nil
	end

	return widget
end

local function CreateUserWidget(menu, widget_class)
	if not IsValid(menu) or not widget_class or not CDO.widget_bp_lib then
		return nil
	end

	local player_controller = menu:GetOwningPlayer()

	if not IsValid(player_controller) then
		player_controller = CDO.pal_utility:GetLocalPlayerController(menu)
	end

	if not IsValid(player_controller) then
		DebugLog("Pal size row: failed to resolve owning player")
		return nil
	end

	local widget = CDO.widget_bp_lib:Create(menu, widget_class, player_controller)

	if not IsValid(widget) then
		DebugLog("Pal size row: failed to create Pal invisible button")
		return nil
	end

	return widget
end

------------------------- Internal helpers to copy native UI widget attributes/style to our new size row widget -------------------------------------------
local function CopyCanvasSlot(source_widget, target_widget)
	if not IsValid(source_widget) or not IsValid(target_widget) then
		return
	end

	local source_slot = source_widget.Slot
	local target_slot = target_widget.Slot

	if not IsValid(source_slot) or not IsValid(target_slot) then
		return
	end

	target_slot:SetAnchors(source_slot:GetAnchors())
	target_slot:SetPosition(source_slot:GetPosition())
	target_slot:SetSize(source_slot:GetSize())
	target_slot:SetAlignment(source_slot:GetAlignment())
	target_slot:SetAutoSize(source_slot:GetAutoSize())
	target_slot:SetZOrder(source_slot:GetZOrder())
end

local function CopyVerticalSlot(source_widget, target_widget)
	local source_slot = source_widget.Slot
	local target_slot = target_widget.Slot

	if not IsValid(source_slot) or not IsValid(target_slot) then
		return
	end

	target_slot:SetPadding(source_slot.Padding)
	target_slot:SetSize(source_slot.Size)
	target_slot:SetHorizontalAlignment(source_slot.HorizontalAlignment)
	target_slot:SetVerticalAlignment(source_slot.VerticalAlignment)
end

local function CopyHorizontalSlot(source_widget, target_widget)
	if not IsValid(source_widget) or not IsValid(target_widget) then
		return
	end

	local source_slot = source_widget.Slot
	local target_slot = target_widget.Slot

	if not IsValid(source_slot) or not IsValid(target_slot) then
		return
	end

	target_slot:SetPadding(source_slot.Padding)
	target_slot:SetSize(source_slot.Size)
	target_slot:SetHorizontalAlignment(source_slot.HorizontalAlignment)
	target_slot:SetVerticalAlignment(source_slot.VerticalAlignment)
end

local function CopyImageStyle(source_image, target_image)
	if not IsValid(source_image) or not IsValid(target_image) then
		return
	end

	target_image:SetBrush(source_image.Brush)
	target_image:SetColorAndOpacity(source_image.ColorAndOpacity)
	target_image:SetRenderOpacity(source_image:GetRenderOpacity())
end

local function CopyTextStyle(source_text, target_text)
	if not IsValid(source_text) or not IsValid(target_text) then
		return
	end

	target_text:SetFont(source_text.Font)
	target_text:SetColorAndOpacity(source_text.ColorAndOpacity)
	target_text:SetShadowOffset(source_text.ShadowOffset)
	target_text:SetShadowColorAndOpacity(source_text.ShadowColorAndOpacity)
	target_text:SetJustification(source_text.Justification)
end

local function CopyCanvasImage(source_image, target_canvas, menu)
	local image = ConstructWidget(menu, source_image:GetClass())

	if not IsValid(image) then
		return nil
	end

	local slot = target_canvas:AddChildToCanvas(image)

	if not IsValid(slot) then
		return nil
	end

	CopyImageStyle(source_image, image)
	CopyCanvasSlot(source_image, image)

	return image
end

------------------------------------ Creating a custom size row widget logic and integrate into native pal details menu -------------------------------------------------------------
local function GetNativeRowParts(menu)
	if not IsValid(menu.Text_WorkSpeedValue) or not IsValid(menu.Text_RangeAttackValue) then
		return nil
	end

	local work_value = menu.Text_WorkSpeedValue
	local work_hbox = work_value:GetParent()

	if not IsValid(work_hbox) or work_hbox:GetChildrenCount() < 4 then
		return nil
	end

	local work_canvas = work_hbox:GetParent()

	if not IsValid(work_canvas) then
		return nil
	end

	local stats_box = work_canvas:GetParent()

	if not IsValid(stats_box) then
		return nil
	end

	-- Native Work row:
	-- 0 = StatusIcon_2
	-- 1 = "Work Speed" text
	-- 2 = Spacer_1
	-- 3 = Text_WorkSpeedValue
	local work_icon = work_hbox:GetChildAt(0)
	local work_label = work_hbox:GetChildAt(1)
	local work_spacer = work_hbox:GetChildAt(2)

	if not IsValid(work_icon) or not IsValid(work_label) or not IsValid(work_spacer) then
		return nil
	end

	-- Attack row has the same structure.
	local attack_hbox = menu.Text_RangeAttackValue:GetParent()

	if not IsValid(attack_hbox) or attack_hbox:GetChildrenCount() < 1 then
		return nil
	end

	local attack_icon = attack_hbox:GetChildAt(0)
	local ImageClass = UObjects[UOBJ_PATHS.IMAGE_CLASS_PATH]
	if not IsValid(attack_icon) or not attack_icon:IsA(ImageClass) then
		return nil
	end

	return {
		work_canvas = work_canvas,
		work_hbox = work_hbox,
		stats_box = stats_box,
		work_icon = work_icon,
		work_label = work_label,
		work_spacer = work_spacer,
		work_value = work_value,
		attack_icon = attack_icon
	}
end

local function GetNativeRowHeight(work_hbox)
	if not IsValid(work_hbox) then
		return nil
	end

	local slot = work_hbox.Slot

	if not IsValid(slot) then
		return nil
	end

	local position = slot:GetPosition()
	local size = slot:GetSize()

	return tonumber(position.Y) + tonumber(size.Y)
end

local function ShiftCanvasPanel(panel, original_y, offset_y)
	if not IsValid(panel) then
		return original_y
	end

	local slot = panel.Slot

	if not IsValid(slot) then
		return original_y
	end

	local position = slot:GetPosition()

	if original_y == nil then
		original_y = tonumber(position.Y)
	end

	slot:SetPosition({
		X = position.X,
		Y = original_y + offset_y
	})

	return original_y
end

local function ShiftLowerStatusSections(menu, row_height)
	if IsValid(menu.UniformGrid_Suitability) then
		local suitability_panel = menu.UniformGrid_Suitability:GetParent()
		work_suitability_y = ShiftCanvasPanel(suitability_panel, work_suitability_y, row_height)
	end

	if IsValid(menu.WBP_MainMenu_Pal_FoodAmount) then
		local food_panel = menu.WBP_MainMenu_Pal_FoodAmount:GetParent()
		food_panel_y = ShiftCanvasPanel(food_panel, food_panel_y, row_height)
	end
end

local function ExpandStatsInfo(stats_box, row_height)
	local pal_status_info = stats_box:GetParent()

	if not IsValid(pal_status_info) then
		return
	end

	local slot = pal_status_info.Slot

	if not IsValid(slot) then
		return
	end

	local size = slot:GetSize()

	if stats_info_height == nil then
		stats_info_height = tonumber(size.Y)
	end

	slot:SetSize({
		X = size.X,
		Y = stats_info_height + row_height
	})
end

local function AddHorizontalChild(horizontal_box, widget, source_widget)
	local slot = horizontal_box:AddChildToHorizontalBox(widget)

	if not IsValid(slot) then
		return false
	end

	CopyHorizontalSlot(source_widget, widget)

	return true
end

local function CreateSizeRowContent(menu, size_canvas, native)
	local size_hbox = ConstructWidget(menu, native.work_hbox:GetClass())

	if not IsValid(size_hbox) then
		return nil
	end

	local hbox_slot = size_canvas:AddChildToCanvas(size_hbox)

	if not IsValid(hbox_slot) then
		return nil
	end

	-- Gives our entire content row exactly the same authored
	-- position and dimensions as the Work Speed content row.
	CopyCanvasSlot(native.work_hbox, size_hbox)

	-- Use the Attack icon's artwork.
	local size_icon = ConstructWidget(menu, native.attack_icon:GetClass())

	if not IsValid(size_icon) then
		return nil
	end

	CopyImageStyle(native.attack_icon, size_icon)

	if not AddHorizontalChild(size_hbox, size_icon, native.attack_icon) then
		return nil
	end

	-- Exact Work Speed label class/style/slot.
	local size_label = ConstructWidget(menu, native.work_label:GetClass())

	if not IsValid(size_label) then
		return nil
	end

	CopyTextStyle(native.work_label, size_label)
	size_label:SetText(FText("Size"))

	if not AddHorizontalChild(size_hbox, size_label, native.work_label) then
		return nil
	end

	-- Clone the native flexible spacer rather than calculating any X offset.
	local size_spacer = ConstructWidget(menu, native.work_spacer:GetClass())

	if not IsValid(size_spacer) then
		return nil
	end

	size_spacer:SetSize(native.work_spacer.Size)

	if not AddHorizontalChild(size_hbox, size_spacer, native.work_spacer) then
		return nil
	end

	-- Exact Work Speed numeric value class/style/slot.
	local size_value = ConstructWidget(menu, native.work_value:GetClass())

	if not IsValid(size_value) then
		return nil
	end

	CopyTextStyle(native.work_value, size_value)
	size_value:SetText(FText("--%"))

	if not AddHorizontalChild(size_hbox, size_value, native.work_value) then
		return nil
	end

	return {
		hbox = size_hbox,
		icon = size_icon,
		label = size_label,
		value = size_value
	}
end

local function CreateSizeRow(menu)
	local menu_key = menu:GetAddress()
	local existing = size_rows[menu_key]

	if existing and IsValid(existing.canvas) then
		return existing
	end

	local native = GetNativeRowParts(menu)

	if not native then
		DebugLog("Pal size row: failed to resolve native status row")
		return nil
	end

	local row_height = GetNativeRowHeight(native.work_hbox)

	if not row_height or row_height <= 0 then
		DebugLog("Pal size row: failed to determine native row height")
		return nil
	end

	local size_row_canvas = ConstructWidget(menu, native.work_canvas:GetClass())

	if not IsValid(size_row_canvas) then
		return nil
	end

	local row_slot = native.stats_box:AddChildToVerticalBox(size_row_canvas)

	if not IsValid(row_slot) then
		return nil
	end

	-- Make the size row behave in VerticalBox_0 (the box containing ATK, DEF and Workspeed stats) exactly like the native Workspeed row.
	CopyVerticalSlot(native.work_canvas, size_row_canvas)

	-- Make room for our custom size row in the stat box (ATK/DEF/Workspeed)
	ExpandStatsInfo(native.stats_box, row_height)

	-- Shift the lower UI blocks (Work Suitability and Food) now that our size row was added and apply proper spacing
	ShiftLowerStatusSections(menu, row_height)

	-- Copy native Work Speed background/decorations.
	-- The arrow implying ATK/DEF has been boosted by a bonus is intentionally omitted.	
	local ImageClass = UObjects[UOBJ_PATHS.IMAGE_CLASS_PATH]
	for i = 0, native.work_canvas:GetChildrenCount() - 1 do
		local child = native.work_canvas:GetChildAt(i)

		if IsValid(child) and child:IsA(ImageClass) then
			local child_name = child:GetFName():ToString()

			if not child_name:find("^IconRankArrow") then
				CopyCanvasImage(child, size_row_canvas, menu)
			end
		end
	end

	local size_row_content = CreateSizeRowContent(menu, size_row_canvas, native)

	if not size_row_content then
		return nil
	end

	local work_button = menu.WBP_PalInvisibleButton_Work

	if not IsValid(work_button) then
		DebugLog("Pal size row: Work Speed invisible button not found")
		return nil
	end

	local size_button = CreateUserWidget(menu, work_button:GetClass())

	if not IsValid(size_button) then
		return nil
	end

	local size_btn_slot = size_row_canvas:AddChildToCanvas(size_button)

	if not IsValid(size_btn_slot) then
		return nil
	end

	CopyCanvasSlot(work_button, size_button)

	local row = {
		menu = menu,
		canvas = size_row_canvas,
		hbox = size_row_content.hbox,
		icon = size_row_content.icon,
		label = size_row_content.label,
		size_text = size_row_content.value,
		hit_target = size_button,
		button_addr = size_button:GetAddress(),
		popup_info = "",
		popup_sub_info = ""
	}

	size_rows[menu_key] = row
	size_rows_by_button[size_button:GetAddress()] = row

	return row
end

------------------- Add a size row to the native GUI containing ATK/DEF/Workspeed stats -----------------------

local function GetScale(pal_actor)
	if not IsValid(pal_actor) then
		return nil
	end

	local mesh = pal_actor.Mesh

	if not IsValid(mesh) then
		return nil
	end

	local scale = mesh.DefaultScale3D

	if not scale then
		return nil
	end

	local scale_x = tonumber(scale.X)

	if not scale_x or scale_x <= 0 then
		return nil
	end

	return scale_x
end

local function GetMinimumRideScale(pal_actor)
	if not IsValid(pal_actor) then
		return nil
	end

	local static = pal_actor.StaticCharacterParameterComponent

	if not IsValid(static) then
		return nil
	end

	local pal_size = PalUtils.GetPalSize(pal_actor)

	if pal_size == nil then
		return nil
	end

	local pal_size_key = PalUtils.PAL_SIZE[pal_size]

	if not pal_size_key or not mod_config.rideability.min_ride_scales then
		return nil
	end

	return tonumber(mod_config.rideability.min_ride_scales[pal_size_key])
end

local function GetPalSizeRange(pal_actor)
	local size = PalUtils.GetPalSize(pal_actor) or 2
	local size_category = PalUtils.PAL_SIZE[size]
	local static_char_param = pal_actor.StaticCharacterParameterComponent

	if not IsValid(static_char_param) then
		return mod_config.normal_pal_scales[size_category]
	end

	if PalUtils.IsBossExcludingRare(static_char_param) then
		return mod_config.boss_pal_scales[size_category]
	end

	if static_char_param:IsRarePal() then
		return mod_config.rare_pal_scales[size_category]
	end

	return mod_config.normal_pal_scales[size_category]
end

local function AddSizeRow(menu, handle)
	local pal_actor = handle:TryGetIndividualActor()

	if not IsValid(pal_actor) then
		return
	end

	local scale = GetScale(pal_actor)

	if not scale then
		return
	end

	local row = CreateSizeRow(menu)

	if not row then
		return
	end

	local monster_param_dt = UObjects[UOBJ_PATHS.GAME_MONSTER_PARAM_DT]

	if not monster_param_dt then
		DebugLog("Failed to load Monster paramter Datatable")
		return
	end
	local size_range = GetPalSizeRange(pal_actor)
	local size_percent = math.floor(scale * 100.0 + 0.5)
	local max_size = math.floor(size_range.max * 100.0 + 0.5)


	local pal_data = monster_param_dt:FindRow(PalUtils.GetCharacterIDFromActor(pal_actor))

	if not pal_data then
		DebugLog("Failed to read pal data row from monster param datatable")
		return
	end
	local run_speed = tonumber(pal_data.RunSpeed) or 100
	local ride_sprint_speed = tonumber(pal_data.RideSprintSpeed) or 200

	row.size_text:SetText(FText(string.format("%d%%", size_percent)))
	row.popup_info = string.format("Max size %d%%", max_size)

	if not PalUtils.IsPalRideableFromActor(pal_actor) then
		row.popup_sub_info = nil
		return
	end

	row.popup_sub_info = string.format("Ride %d\nSprint %d", run_speed, ride_sprint_speed)

	if not mod_config.rideability.restricted_by_size then
		return
	end

	local min_ride_scale = GetMinimumRideScale(pal_actor)

	if not min_ride_scale or min_ride_scale <= 0.01 then
		return
	end

	local ride_percent = math.floor(min_ride_scale * 100.0 + 0.5)
	row.popup_info = row.popup_info .. string.format("\nMin size for riding %d%%", ride_percent)
end

local function PurgeDeadRows()
	for menu_key, row in pairs(size_rows) do
		if not row or not IsValid(row.menu) or not IsValid(row.canvas) or not IsValid(row.hit_target) then
			if row and row.button_addr then
				size_rows_by_button[row.button_addr] = nil
			end

			size_rows[menu_key] = nil
		end
	end
end
------------------- HOVER ON SIZE ROW, OPEN POPUP LOGIC -----------------------

local function OpenSizeOverlay(row)
	if not row or not IsValid(row.menu) or not IsValid(row.hit_target) then
		return
	end

	local open_overlay = row.menu["Open Overlay Info Window"]

	if not open_overlay then
		return
	end

	open_overlay(
		row.menu,
		row.hit_target,
		{ X = 0.0, Y = 0.5 },
		{ X = 1.05, Y = 0.0 },
		FText("Size"),
		FText(row.popup_info or ""),
		FText(row.popup_sub_info or "")
	)
end

local function CloseSizeOverlay(row)
	if not row or not IsValid(row.menu) then
		return
	end

	local close_overlay = row.menu["Close Overlay Info Window"]

	if not close_overlay then
		return
	end

	close_overlay(row.menu)
end

local function RegisterHoverHooks()
	NotifyOnNewObject(
		UOBJ_PATHS.BP_PAL_COMMON_BUTTON_BASE,
		function()
			if not button_hovered_hook_reg then
				button_hovered_hook_reg = UnrealUtils.TryRegisterBPHook(
					FUNC_PATHS.BP_PAL_COMMON_BUTTON_BASE_ON_HOVERED,
					function(Context)
						local button = Context:get()

						if not IsValid(button) then
							return
						end

						local row = size_rows_by_button[button:GetAddress()]

						if row then
							OpenSizeOverlay(row)
						end
					end
				)
			end

			if not button_unhovered_hook_reg then
				button_unhovered_hook_reg = UnrealUtils.TryRegisterBPHook(
					FUNC_PATHS.BP_PAL_COMMON_BUTTON_BASE_ON_UNHOVERED,
					function(Context)
						local button = Context:get()

						if not IsValid(button) then
							return
						end

						local row = size_rows_by_button[button:GetAddress()]

						if row then
							CloseSizeOverlay(row)
						end
					end
				)
			end
			return button_hovered_hook_reg and button_unhovered_hook_reg
		end
	)
end

function PalSizeDisplay.Init()
	RegisterHoverHooks()

	NotifyOnNewObject(
		UOBJ_PATHS.BP_PAL_MENU,
		function()
			if not setup_status_hook_reg then
				setup_status_hook_reg = UnrealUtils.TryRegisterBPHook(
					FUNC_PATHS.BP_PAL_MENU_SETUP_STATUS,
					function(Context, Handle)
						local menu = Context:get()
						local handle = Handle:get()

						if not IsValid(menu) or not IsValid(handle) then
							return
						end
						PurgeDeadRows()
						AddSizeRow(menu, handle)
					end
				)
			end
			return setup_status_hook_reg
		end
	)
end

return PalSizeDisplay
