---@class UPaths
local UPaths = {}

UPaths.FUNC_PATHS = {
	CLIENT_RESTART = "/Script/Engine.PlayerController:ClientRestart",
	SERVER_ACK_POSSESS = "/Script/Engine.PlayerController:ServerAcknowledgePossession",
	NOTIFY_ON_WORLD_LOAD_TO_SERVER = "/Script/Pal.PalPlayerState:NotifyOnCompleteLoadInitWorldPartition_ToServer",
	ON_PAL_INIT = "/Script/Pal.PalCharacterParameterComponent:OnInitializedCharacter",
	ON_ACTIVE_PAL_CHANGE = "/Script/Pal.PalOtomoHolderComponentBase:OnChangeOtomoActive",
	ON_PARTY_CREATED = "/Script/Pal.PalOtomoHolderComponentBase:OnCreatedCharacterContainer",
	ON_PARTY_SLOT_UPDATED = "/Script/Pal.PalOtomoHolderComponentBase:OnUpdateSlot",
	IS_RESTRICTED_BY_ITEMS = "/Script/Pal.PalPartnerSkillParameterComponent:IsRestrictedByItems",
	CAN_WHISTLE_RIDE_PAL = "/Script/Pal.PalPlayerController:CanPlayWhistleForRideCall",
	GET_PAL_RESTRICT_ITEM = "/Script/Pal.PalUIUtility:GetPalRestrictItemID",
	CAN_AIM = "/Script/Pal.PalShooterComponent:CanAim",
	SET_RIDING_FLAG = "/Script/Pal.PalRideMarkerComponent:SetRidingFlag",
	WORLD_PARTITION_READY = "/Script/Pal.PalPlayerState:OnCompleteLoadWorldPartitionAndAdjustCharacter_InServer",
	PAL_CAPTURE_SUCCESS = "/Script/Pal.PalUtility:PalCaptureSuccess",
	ON_PAL_CAPTURE_SUCCESS = "/Script/Pal.PalCaptureJudgeObject:OnCaptureSuccess",
	SEND_LOG_TO_CLIENT = "/Script/Pal.PalPlayerController:SendLog_ToClient",
	SEND_SCREEN_LOG_TO_CLIENT = "/Script/Pal.PalPlayerController:SendScreenLogToClient",
	REQUEST_DEBUG_GUILD_INFO_TO_SERVER = "/Script/Pal.PalPlayerController:RequestDebugGuildInfo_ToServer",
	CALCULATE_DAMAGE = "/Script/Pal.PalUtility:ProcessDamageAndPlayEffectsByDamageInfo",
	PROCESS_DAMAGE = "/Script/Pal.PalUtility:ProcessDamageAndPlayEffectsByDamageInfo",

	BEGIN_PLAY = "/Game/Pal/Blueprint/Weapon/Other/BP_PalCaptureJudgeObject.BP_PalCaptureJudgeObject_C:ReceiveBeginPlay",
	CAPTURE_SUCCESS = "/Game/Pal/Blueprint/Weapon/Other/BP_PalCaptureJudgeObject.BP_PalCaptureJudgeObject_C:OnCaptureSuccess",
	CAPTURE_FAILED = "/Game/Pal/Blueprint/Weapon/Other/BP_PalCaptureJudgeObject.BP_PalCaptureJudgeObject_C:OnFailedFinish",
	SPHERE_CAPTURE_SUCCESS = "/Game/Pal/Blueprint/Weapon/Other/NewPalSphere/BP_PalSphere_Body.BP_PalSphere_Body_C:CaptureSuccessEvent",

	-- Blueprint funcs
	BP_CAN_COOP = "/Game/Pal/Blueprint/Controller/Monster/BP_MonsterAIController_Otomo.BP_MonsterAIController_Otomo_C:CanCoop",
	BP_WILD_LIFE_ACTION_START = "/Game/Pal/Blueprint/Controller/AIAction/WildPal/BP_AIAction_WildLife.BP_AIAction_WildLife_C:ActionStart",
	BP_PAL_MENU_SET_HANDLES = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C:Set Pal Handles",
	BP_PAL_MENU_PARTNER_SKILL_LOCK = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C:SetPartnerSkillLock",
	BP_PAL_MENU_PSKILL_OPEN_OVERLAY = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C:Open Overlay Info Window",
	BP_PAL_MENU_SETUP_STATUS = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C:Setup Status",
	BP_PAL_COMMON_BUTTON_BASE_ON_HOVERED = "/Game/Pal/Blueprint/UI/System/Style/WBP_PalCommonButtonBase.WBP_PalCommonButtonBase_C:BP_OnHovered",
	BP_PAL_COMMON_BUTTON_BASE_ON_UNHOVERED = "/Game/Pal/Blueprint/UI/System/Style/WBP_PalCommonButtonBase.WBP_PalCommonButtonBase_C:BP_OnUnhovered",


}



UPaths.UOBJ_PATHS = {
	--CDO Instances
	PAL_UTILITY = "/Script/Pal.Default__PalUtility",
	PAL_UI_UTILITY = "/Script/Pal.Default__PalUIUtility",
	PAL_ITEM_UTILITY = "/Script/Pal.Default__PalItemUtility",
	KISMET_SYS_LIB = "/Script/Engine.Default__KismetSystemLibrary",
	KISMET_INTL_LIB = "/Script/Engine.Default__KismetInternationalizationLibrary",
	KISMET_GUID_LIB = "/Script/Engine.Default__KismetGuidLibrary",
	PAL_MASTER_DT_UTILITY = "/Script/Pal.Default__PalMasterDataTablesUtility",
	WIDGET_BLUEPRINT_LIBRARY = "/Script/UMG.Default__WidgetBlueprintLibrary",


	--UClasses
	PAL_SHOOTER_COMPONENT = "/Script/Pal.PalShooterComponent",
	PAL_PSKILL_PARAMETER_COMPONENT = "/Script/Pal.PalPartnerSkillParameterComponent",
	PAL_OTOMO_HOLDER_COMPONENT = "/Script/Pal.PalOtomoHolderComponentBase",
	PAL_RIDE_MARKER_COMPONENT = "/Script/Pal.PalRideMarkerComponent",
	PAL_RIDER_COMPONENT = "/Script/Pal.PalRiderComponent",
	CANVAS_PANEL_CLASS = "/Script/UMG.CanvasPanel",
	BUTTON_CLASS_PATH = "/Script/UMG.Button",
	IMAGE_CLASS_PATH = "/Script/UMG.Image",



	-- DataTables
	GAME_MONSTER_PARAM_DT = "/Game/Pal/DataTable/Character/DT_PalMonsterParameter.DT_PalMonsterParameter",
	GAME_ITEM_DT = "/Game/Pal/DataTable/Item/DT_ItemDataTable.DT_ItemDataTable",
	GAME_PARTNER_SKILL_DT = "/Game/Pal/DataTable/PassiveSkill/DT_PartnerSkillParameter.DT_PartnerSkillParameter",

	--Blueprint Classes
	BP_OTOMO_AI_CONTROLLER = "/Game/Pal/Blueprint/Controller/Monster/BP_MonsterAIController_Otomo.BP_MonsterAIController_Otomo_C",
	BP_PAL_MENU = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C",
	BP_AIACTION_WILD_LIFE = "/Game/Pal/Blueprint/Controller/AIAction/WildPal/BP_AIAction_WildLife.BP_AIAction_WildLife_C",
	BP_PAL_CAPTURE_JUDGE = "/Game/Pal/Blueprint/Weapon/Other/BP_PalCaptureJudgeObject.BP_PalCaptureJudgeObject_C",
	BP_PAL_SPHERE_BODY = "/Game/Pal/Blueprint/Weapon/Other/NewPalSphere/BP_PalSphere_Body.BP_PalSphere_Body_C",
	BP_PAL_COMMON_BUTTON_BASE = "/Game/Pal/Blueprint/UI/System/Style/WBP_PalCommonButtonBase.WBP_PalCommonButtonBase_C",

	--Enums
	PAL_SIZE = "/Script/Pal.EPalSizeType"
}

return UPaths
