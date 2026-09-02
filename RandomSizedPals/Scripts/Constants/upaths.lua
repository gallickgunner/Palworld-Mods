---@class UPaths
local UPaths = {}

UPaths.FUNC_PATHS = {
	CLIENT_RESTART = "/Script/Engine.PlayerController:ClientRestart",
	ON_PAL_INIT = "/Script/Pal.PalCharacterParameterComponent:OnInitializedCharacter",
	ON_ACTIVE_PAL_CHANGE = "/Script/Pal.PalOtomoHolderComponentBase:OnChangeOtomoActive",
	ON_PARTY_CREATED = "/Script/Pal.PalOtomoHolderComponentBase:OnCreatedCharacterContainer",
	ON_PARTY_SLOT_UPDATED = "/Script/Pal.PalOtomoHolderComponentBase:OnUpdateSlot",
	IS_PARTNER_SKILL_RESTRICTED = "/Script/Pal.PalPartnerSkillParameterComponent:IsRestrictedByItems",
	CAN_WHISTLE_RIDE_PAL = "/Script/Pal.PalPlayerController:CanPlayWhistleForRideCall",
	GET_PAL_RESTRICT_ITEM = "/Script/Pal.PalUIUtility:GetPalRestrictItemID",
	BP_CAN_COOP = "/Game/Pal/Blueprint/Controller/Monster/BP_MonsterAIController_Otomo.BP_MonsterAIController_Otomo_C:CanCoop",
	BP_PAL_MENU_SET_HANDLES = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C:Set Pal Handles",
	BP_PAL_MENU_PARTNER_SKILL_LOCK = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C:SetPartnerSkillLock",
	BP_PAL_MENU_PSKILL_OPEN_OVERLAY = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C:Open Overlay Info Window",

}

UPaths.UOBJ_PATHS = {
	--CDO Instances
	PAL_UTILITY = "/Script/Pal.Default__PalUtility",
	KISMET_SYS_LIB = "/Script/Engine.Default__KismetSystemLibrary",
	KISMET_INTL_LIB = "/Script/Engine.Default__KismetInternationalizationLibrary",
	PAL_MASTER_DT_UTILITY = "/Script/Pal.Default__PalMasterDataTablesUtility",

	--UClasses
	PAL_PSKILL_PARAMETER_COMPONENT = "/Script/Pal.PalPartnerSkillParameterComponent",
	PAL_OTOMO_HOLDER_COMPONENT = "/Script/Pal.PalOtomoHolderComponentBase",
	PAL_RIDE_MARKER_COMPONENT = "/Script/Pal.PalRideMarkerComponent",
	PAL_RIDER_COMPONENT = "/Script/Pal.PalRiderComponent",
	GAME_ITEM_DATA_TABLE = "/Game/Pal/DataTable/Item/DT_ItemDataTable.DT_ItemDataTable",

	--Blueprint Classes
	BP_OTOMO_AI_CONTROLLER = "/Game/Pal/Blueprint/Controller/Monster/BP_MonsterAIController_Otomo.BP_MonsterAIController_Otomo_C",
	BP_PAL_MENU = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C",

	--Enums
	PAL_SIZE = "/Script/Pal.EPalSizeType"
}

return UPaths
