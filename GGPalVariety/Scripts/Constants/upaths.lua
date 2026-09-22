---@class UPaths
local UPaths = {}

---@class FuncPaths
UPaths.FUNC_PATHS = {
	-- Engine / server lifecycle
	CLIENT_RESTART = "/Script/Engine.PlayerController:ClientRestart",
	SERVER_ACK_POSSESS = "/Script/Engine.PlayerController:ServerAcknowledgePossession",
	NOTIFY_ON_WORLD_LOAD_TO_SERVER = "/Script/Pal.PalPlayerState:NotifyOnCompleteLoadInitWorldPartition_ToServer",
	ON_CHARACTER_INIT = "/Script/Pal.PalCharacterParameterComponent:OnInitializedCharacter",

	-- Party / ride
	ON_PARTY_CREATED = "/Script/Pal.PalOtomoHolderComponentBase:OnCreatedCharacterContainer",
	IS_RESTRICTED_BY_ITEMS = "/Script/Pal.PalPartnerSkillParameterComponent:IsRestrictedByItems",

	-- Pal state / trust / combat
	ON_CHAR_SAVE_PARAM_REPLICATE = "/Script/Pal.PalIndividualCharacterParameter:OnRep_SaveParameter",
	ON_UPDATE_WORKER_FRIENDSHIP_RANK = "/Script/Pal.PalBaseCampWorkerDirector:OnUpdateWorkerFriendshipRank",
	ON_REP_IS_PAL_ACTIVE_ACTOR = "/Script/Pal.PalCharacter:OnRep_IsPalActiveActor",
	SET_ACTIVE_ACTOR = "/Script/Pal.PalCharacter:SetActiveActor",
	ON_DEAD_CHARACTER = "/Script/Pal.PalCharacter:OnDeadCharacter",
	PROCESS_DAMAGE = "/Script/Pal.PalUtility:ProcessDamageAndPlayEffectsByDamageInfo",

	-- Wild Pal lifecycle
	BP_WILD_LIFE_ACTION_START = "/Game/Pal/Blueprint/Controller/AIAction/WildPal/BP_AIAction_WildLife.BP_AIAction_WildLife_C:ActionStart",

	-- Pal menu
	BP_PAL_MENU_PARTNER_SKILL_LOCK = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C:SetPartnerSkillLock",
	BP_PAL_MENU_PSKILL_OPEN_OVERLAY = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C:Open Overlay Info Window",
	BP_PAL_MENU_SETUP_STATUS = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C:Setup Status",
	BP_PAL_COMMON_BUTTON_BASE_ON_HOVERED = "/Game/Pal/Blueprint/UI/System/Style/WBP_PalCommonButtonBase.WBP_PalCommonButtonBase_C:BP_OnHovered",
	BP_PAL_COMMON_BUTTON_BASE_ON_UNHOVERED = "/Game/Pal/Blueprint/UI/System/Style/WBP_PalCommonButtonBase.WBP_PalCommonButtonBase_C:BP_OnUnhovered",
}

---@class UObjPaths
UPaths.UOBJ_PATHS = {
	-- CDOs / libraries
	PAL_UTILITY = "/Script/Pal.Default__PalUtility",
	KISMET_SYS_LIB = "/Script/Engine.Default__KismetSystemLibrary",
	KISMET_INTL_LIB = "/Script/Engine.Default__KismetInternationalizationLibrary",
	KISMET_GUID_LIB = "/Script/Engine.Default__KismetGuidLibrary",
	KISMET_MATH_LIB = "/Script/Engine.Default__KismetMathLibrary",
	PAL_MASTER_DT_UTILITY = "/Script/Pal.Default__PalMasterDataTablesUtility",
	WIDGET_BLUEPRINT_LIBRARY = "/Script/UMG.Default__WidgetBlueprintLibrary",

	-- Classes / components
	PAL_PASSIVE_SKILL_COMPONENT = "/Script/Pal.PalPassiveSkillComponent",
	PAL_RIDE_MARKER_COMPONENT = "/Script/Pal.PalRideMarkerComponent",
	PAL_BASE_CAMP_MODEL = "/Script/Pal.PalBaseCampModel",
	IMAGE_CLASS_PATH = "/Script/UMG.Image",

	-- Data tables
	GAME_MONSTER_PARAM_DT = "/Game/Pal/DataTable/Character/DT_PalMonsterParameter.DT_PalMonsterParameter",
	GAME_ITEM_DT = "/Game/Pal/DataTable/Item/DT_ItemDataTable.DT_ItemDataTable",
	GAME_PARTNER_SKILL_DT = "/Game/Pal/DataTable/PassiveSkill/DT_PartnerSkillParameter.DT_PartnerSkillParameter",

	-- Blueprint classes
	BP_AIACTION_WILD_LIFE = "/Game/Pal/Blueprint/Controller/AIAction/WildPal/BP_AIAction_WildLife.BP_AIAction_WildLife_C",
	BP_PAL_MENU = "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Pal/WBP_MainMenu_Pal_00.WBP_MainMenu_Pal_00_C",
	BP_PAL_COMMON_BUTTON_BASE = "/Game/Pal/Blueprint/UI/System/Style/WBP_PalCommonButtonBase.WBP_PalCommonButtonBase_C",

	-- Enums
	PAL_SIZE = "/Script/Pal.EPalSizeType",
	PAL_GENDER = "/Script/Pal.EPalGenderType",
	PAL_WORK_SUITABILITY = "/Script/Pal.EPalWorkSuitability",
	PASSIVE_SKILL_EFFECT_TYPE = "/Script/Pal.EPalPassiveSkillEffectType",

	-- Resources
	RES_WHITE_TEXTURE = "/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture",
}

return UPaths
