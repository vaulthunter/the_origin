public Plugin_init_native_fwd()
{
	g_Forwards[FW_USER_INFECT_PRE] = CreateMultiForward("origin_fw_infect_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_INFECT] = CreateMultiForward("origin_fw_infect", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_INFECT_POST] = CreateMultiForward("origin_fw_infect_post", ET_IGNORE, FP_CELL, FP_CELL)

	g_Forwards[FW_USER_CURE_PRE] = CreateMultiForward("origin_fw_cure_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_CURE] = CreateMultiForward("origin_fw_cure", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_CURE_POST] = CreateMultiForward("origin_fw_cure_post", ET_IGNORE, FP_CELL, FP_CELL)

	g_Forwards[FW_USER_LAST_ZOMBIE] = CreateMultiForward("origin_fw_last_zombie", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_LAST_HUMAN] = CreateMultiForward("origin_fw_last_human", ET_IGNORE, FP_CELL)

	g_Forwards[FW_USER_SPAWN_POST] = CreateMultiForward("origin_fw_spawn_post", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_RESPAWN_PRE] = CreateMultiForward("origin_fw_dm_respawn_pre", ET_CONTINUE, FP_CELL)

	g_Forwards[FW_GAME_MODE_CHOOSE_PRE] = CreateMultiForward("origin_fw_gmodes_choose_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_GAME_MODE_CHOOSE_POST] = CreateMultiForward("origin_fw_gmodes_choose_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_GAME_MODE_START] = CreateMultiForward("origin_fw_gmodes_start", ET_IGNORE, FP_CELL)
	g_Forwards[FW_GAME_MODE_END] = CreateMultiForward("origin_fw_gmodes_end", ET_IGNORE, FP_CELL)
}

public Plugin_natives_native_fwd()
{
	register_library("origin_engine")
	register_native("origin_is_zombie", "native_origin_is_zombie")
	register_native("origin_is_zhost", "native_origin_is_zhost")
	register_native("origin_get_evolution", "native_origin_get_evolution")
	register_native("origin_get_apower", "native_origin_get_apower")
	register_native("origin_is_first_zombie", "native_origin_is_first_zombie")
	register_native("origin_is_last_zombie", "native_origin_is_last_zombie")
	register_native("origin_is_last_human", "native_origin_is_last_human")
	register_native("origin_get_zombie_count", "native_origin_get_zombie_count")
	register_native("origin_get_human_count", "native_origin_get_human_count")
	register_native("origin_infect", "native_origin_infect")
	register_native("origin_cure", "native_origin_cure")
	register_native("origin_force_infect", "native_origin_force_infect")
	register_native("origin_force_cure", "native_origin_force_cure")
	register_native("origin_respawn_as_zombie", "native_origin_respawn_as_zombie")
	register_native("origin_set_knockback", "native_origin_set_knockback")

	register_library("origin_gamemodes")
	register_native("origin_gmodes_register", "native_gamemodes_register")
	register_native("origin_gmodes_set_default", "native_gamemodes_set_default")
	register_native("origin_gmodes_get_default", "native_gamemodes_get_default")
	register_native("origin_gmodes_get_chosen", "native_gamemodes_get_chosen")
	register_native("origin_gmodes_get_current", "native_gamemodes_get_current")
	register_native("origin_gmodes_get_id", "native_gamemodes_get_id")
	register_native("origin_gmodes_get_name", "native_gamemodes_get_name")
	register_native("origin_gmodes_start", "native_gamemodes_start")
	register_native("origin_gmodes_get_count", "native_gamemodes_get_count")
	register_native("origin_gmodes_set_allow_infect", "_gamemodes_set_allow_infect")
	register_native("origin_gmodes_get_allow_infect", "_gamemodes_get_allow_infect")

	// Initialize dynamic arrays
	g_GameModeName = ArrayCreate(32, 1)
	g_GameModeFileName = ArrayCreate(64, 1)
}
