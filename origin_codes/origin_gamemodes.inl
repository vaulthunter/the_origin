public Plugin_init_gamemodes()
{
	g_HudSync = CreateHudSyncObj()
	cvar_gamemode_delay = register_cvar("zp_gamemode_delay", "20")
	cvar_round_start_show_hud = register_cvar("zp_round_start_show_hud", "1")
}

public Plugin_precache_gamemodes()
{
	// Initialize arrays
	g_sound_start_warning = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_respawn = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_countdown = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_human_infect = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "20SEC WARNING", g_sound_start_warning)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE RESPAWN", g_sound_zombie_respawn)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "TIMER COUNTDOWN", g_sound_countdown)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "HUMAN INFECT", g_sound_human_infect)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_start_warning) == 0)
	{
		for (index = 0; index < sizeof sound_start_warning; index++)
			ArrayPushString(g_sound_start_warning, sound_start_warning[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "20SEC WARNING", g_sound_start_warning)
	}
	if (ArraySize(g_sound_zombie_respawn) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_respawn; index++)
			ArrayPushString(g_sound_zombie_respawn, sound_zombie_respawn[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE RESPAWN", g_sound_zombie_respawn)
	}
	if (ArraySize(g_sound_countdown) == 0)
	{
		for (index = 0; index < sizeof sound_countdown; index++)
			ArrayPushString(g_sound_countdown, sound_countdown[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "TIMER COUNTDOWN", g_sound_countdown)
	}
	if (ArraySize(g_sound_human_infect) == 0)
	{
		for (index = 0; index < sizeof sound_human_infect; index++)
			ArrayPushString(g_sound_human_infect, sound_human_infect[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "HUMAN INFECT", g_sound_human_infect)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_start_warning); index++)
	{
		ArrayGetString(g_sound_start_warning, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_human_infect); index++)
	{
		ArrayGetString(g_sound_human_infect, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_respawn); index++)
	{
		ArrayGetString(g_sound_zombie_respawn, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_countdown); index++)
	{
		ArrayGetString(g_sound_countdown, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

public native_gamemodes_register(plugin_id, num_params)
{
	new name[32], filename[64]
	get_string(1, name, charsmax(name))
	get_plugin(plugin_id, filename, charsmax(filename))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Can't register game mode with an empty name")
		return ORIGIN_INVALID_GAME_MODE;
	}
	
	new index, gamemode_name[32]
	for (index = 0; index < g_GameModeCount; index++)
	{
		ArrayGetString(g_GameModeName, index, gamemode_name, charsmax(gamemode_name))
		if (equali(name, gamemode_name))
		{
			log_error(AMX_ERR_NATIVE, "[Origin] Game mode already registered (%s)", name)
			return ORIGIN_INVALID_GAME_MODE;
		}
	}
	
	ArrayPushString(g_GameModeName, name)
	ArrayPushString(g_GameModeFileName, filename)
	
	// Pause Game Mode plugin after registering
	pause("ac", filename)
	
	g_GameModeCount++
	return g_GameModeCount - 1;
}

public native_gamemodes_set_default(plugin_id, num_params)
{
	new game_mode_id = get_param(1)
	
	if (game_mode_id < 0 || game_mode_id >= g_GameModeCount)
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid game mode id (%d)", game_mode_id)
		return false;
	}
	
	g_DefaultGameMode = game_mode_id
	return true;
}

public native_gamemodes_get_default(plugin_id, num_params)
{
	return g_DefaultGameMode;
}

public native_gamemodes_get_chosen(plugin_id, num_params)
{
	return g_ChosenGameMode;
}

public native_gamemodes_get_current(plugin_id, num_params)
{
	return g_CurrentGameMode;
}

public native_gamemodes_get_id(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))
	
	// Loop through every game mode
	new index, gamemode_name[32]
	for (index = 0; index < g_GameModeCount; index++)
	{
		ArrayGetString(g_GameModeName, index, gamemode_name, charsmax(gamemode_name))
		if (equali(name, gamemode_name))
			return index;
	}
	
	return ORIGIN_INVALID_GAME_MODE;
}

public native_gamemodes_get_name(plugin_id, num_params)
{
	new game_mode_id = get_param(1)
	
	if (game_mode_id < 0 || game_mode_id >= g_GameModeCount)
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid game mode id (%d)", game_mode_id)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_GameModeName, game_mode_id, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}

public native_gamemodes_start(plugin_id, num_params)
{
	new game_mode_id = get_param(1)
	
	if (game_mode_id < 0 || game_mode_id >= g_GameModeCount)
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid game mode id (%d)", game_mode_id)
		return false;
	}
	
	new target_player = get_param(2)
	
	if (target_player != RANDOM_TARGET_PLAYER && !is_user_alive(target_player))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid player (%d)", target_player)
		return false;
	}
	
	// Game modes can only be started at roundstart
	if (!task_exists(TASK_GAMEMODE))
		return false;
	
	new previous_mode, filename_previous[64]
	
	// Game mode already chosen?
	if (g_ChosenGameMode != ORIGIN_NO_GAME_MODE)
	{
		// Pause previous game mode before picking a new one
		ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename_previous, charsmax(filename_previous))
		pause("ac", filename_previous)
		previous_mode = true
	}
	
	// Set chosen game mode id
	g_ChosenGameMode = game_mode_id
	
	// Unpause game mode once it's chosen
	new filename[64]
	ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
	unpause("ac", filename)
	
	// Execute game mode choose attempt forward (skip checks = true)
	ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, true)
	
	// Game mode can't be started
	if (g_ForwardResult >= PLUGIN_HANDLED)
	{
		// Pause the game mode we were trying to start
		pause("ac", filename)
		
		// Unpause previously chosen game mode
		if (previous_mode) unpause("ac", filename_previous)
		
		return false;
	}
	
	// Execute game mode chosen forward
	ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, target_player)
	
	// Override task and start game mode manually
	remove_task(TASK_GAMEMODE)
	start_game_mode_task()
	return true;
}

public native_gamemodes_get_count(plugin_id, num_params)
{
	return g_GameModeCount;
}

public _gamemodes_set_allow_infect(plugin_id, num_params)
{
	g_AllowInfection = get_param(1)
}

public _gamemodes_get_allow_infect(plugin_id, num_params)
{
	return g_AllowInfection;
}

public event_game_restart()
{
	logevent_round_end()
}

public logevent_round_end()
{
	ExecuteForward(g_Forwards[FW_GAME_MODE_END], g_ForwardResult, g_CurrentGameMode)
	
	if (g_ChosenGameMode != ORIGIN_NO_GAME_MODE)
	{
		// pause game mode after its round ends
		new filename[64]
		ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
		pause("ac", filename)
	}
	
	g_CurrentGameMode =ORIGIN_NO_GAME_MODE
	g_ChosenGameMode = ORIGIN_NO_GAME_MODE
	g_AllowInfection = false
	
	// Stop game mode task
	remove_task(TASK_GAMEMODE)
	remove_task(TASK_GAMEMODE_END)
	
	// Balance the teams
	balance_teams()
}

public Event_round_start_gamemodes()
{
	// Players respawn as humans when a new round begins
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id))
			continue;
		
		origin_respawn_as_zombie(id, false)
	}
	
	// No game modes registered?
	if (g_GameModeCount < 1)
	{
		set_fail_state("[Origin] No game modes registered!")
		return;
	}
	
	PlaySoundToClients(sound_selecting_round, 0)
	
	// Start ambience sounds after a mode begins
	remove_task(TASK_AMBIENCESOUNDS)
	set_task(1.2 + get_pcvar_float(cvar_gamemode_delay), "ambience_sound_effects", TASK_AMBIENCESOUNDS)
	
	// Pick game mode for the current round (delay needed because not all players are alive at this point)
	set_task(0.1, "choose_game_mode", TASK_GAMEMODE)
	
	// Start game mode task (delay should be greater than choose_game_mode task)
	set_task(1.2 + get_pcvar_float(cvar_gamemode_delay), "start_game_mode_task", TASK_GAMEMODE_END)

	// counter!
	game_start_in_counter(get_pcvar_num(cvar_gamemode_delay)+TASK_COUNTER)
	
	if (get_pcvar_num(cvar_round_start_show_hud))
	{
		// Show T-virus HUD notice
		set_hudmessage(0, 125, 200, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_VIRUS_FREE")
	}
}

public game_start_in_counter(num)
{
	num -= TASK_COUNTER
	if ( num >= 1 &&  task_exists(TASK_GAMEMODE_END) )
	{
		new sound[SOUND_MAX_LENGTH]
		
		if ( num == 20 )
		{
			ArrayGetString(g_sound_start_warning, random_num(0, ArraySize(g_sound_start_warning) - 1), sound, charsmax(sound))
			PlaySoundToClients(sound, 0)
		}
		new iText[64], time_one[30], time_some[30], time_many[30]
	
		lang_GetTimeName ( TIME_SECONS_ONE, LANG_SERVER, time_one, 30 )
		lang_GetTimeName ( TIME_SECONS_SOME, LANG_SERVER, time_some, 30 )
		lang_GetTimeName ( TIME_SECONS_MANY, LANG_SERVER, time_many, 30 )
	
		format(iText, charsmax(iText), "%L", LANG_SERVER, "ORIGIN_GMODE_INTRO", get_correct_str(num, time_one, time_some, time_many ) )
		
		client_print(0, print_center, iText)
		
		if ( num>0 && num <= 10 )
		{
			ArrayGetString(g_sound_countdown, num-1, sound, charsmax(sound))
			PlaySoundToClients(sound, 0)
		}
		
		num--
			
		set_task(1.0, "game_start_in_counter", num+TASK_COUNTER)
	} else client_print(0, print_center, "")
}

public choose_game_mode()
{
	// No players joined yet
	if (GetAliveCount() <= 0)
		return;
	
	new index, filename[64]
	
	// Try choosing a game mode
	for (index = 0; index<g_GameModeCount; index++)
	{
		// Set chosen game mode index
		g_ChosenGameMode = index
		// Unpause game mode once it's chosen
		ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
		unpause("ac", filename)
		
		// Starting non-default game mode?
		if (index != g_DefaultGameMode)
		{
			// Execute game mode choose attempt forward (skip checks = false)
			ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, false)
			
			// Custom game mode can start?
			if (g_ForwardResult < PLUGIN_HANDLED)
			{
				// Execute game mode chosen forward
				ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, RANDOM_TARGET_PLAYER)
				break;
			}
		}
		else
		{
			// Execute game mode choose attempt forward (skip checks = true)
			ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, true)
			
			// Default game mode can start?
			if (g_ForwardResult < PLUGIN_HANDLED)
			{
				// Execute game mode chosen forward
				ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, RANDOM_TARGET_PLAYER)
				return;
			}
			else
			{
				remove_task(TASK_GAMEMODE)
				abort(AMX_ERR_GENERAL, "[Origin] Default game mode can't be started. Check server settings.")
				break;
			}
		}
		
		// Game mode already chosen?
		if (g_ChosenGameMode != ORIGIN_NO_GAME_MODE)
		{
			// Pause previous game mode before picking a new one
			ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
			pause("ac", filename)
		}
	}
	
	//for (index = g_DefaultGameMode + 1; /*no condition*/; index++)
	/*{
		// Start over when we reach the end
		if (index >= g_GameModeCount)
			index = 0
		
		// Game mode already chosen?
		if (g_ChosenGameMode != ORIGIN_NO_GAME_MODE)
		{
			// Pause previous game mode before picking a new one
			ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
			pause("ac", filename)
		}
		
		// Set chosen game mode index
		g_ChosenGameMode = index
		
		// Unpause game mode once it's chosen
		ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
		unpause("ac", filename)
		
		// Starting non-default game mode?
		if (index != g_DefaultGameMode)
		{
			// Execute game mode choose attempt forward (skip checks = false)
			ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, false)
			
			// Custom game mode can start?
			if (g_ForwardResult < PLUGIN_HANDLED)
			{
				// Execute game mode chosen forward
				ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, RANDOM_TARGET_PLAYER)
				break;
			}
		}
		else
		{
			// Execute game mode choose attempt forward (skip checks = true)
			ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, true)
			
			// Default game mode can start?
			if (g_ForwardResult < PLUGIN_HANDLED)
			{
				// Execute game mode chosen forward
				ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, RANDOM_TARGET_PLAYER)
				break;
			}
			else
			{
				remove_task(TASK_GAMEMODE)
				abort(AMX_ERR_GENERAL, "[Origin] Default game mode can't be started. Check server settings.")
				break;
			}
		}
	}*/
}

public start_game_mode_task()
{
	// No game mode was chosen (not enough players)
	if (g_ChosenGameMode == ORIGIN_NO_GAME_MODE)
	{
		return;
	}
	
	// Set current game mode
	g_CurrentGameMode = g_ChosenGameMode
	
	// Execute game mode started forward
	ExecuteForward(g_Forwards[FW_GAME_MODE_START], g_ForwardResult, g_CurrentGameMode)
}

// Client Disconnected Post Forward
public fw_ClientDisc_Post_gamemodes(id)
{
	// Are there any other players? (if not, round end is automatically triggered after last player leaves)
	if (task_exists(TASK_GAMEMODE))
	{
		// Choose game mode again (to check game mode conditions such as min players)
		choose_game_mode()
	}
}

// Player Killed Post Forward
public fw_PlayerKilled_Post_gamemodes(victim, attacker, shouldgib)
{
	// Are there any other players? (if not, round end is automatically triggered after last player dies)
	if (task_exists(TASK_GAMEMODE))
	{
		// Choose game mode again (to check game mode conditions such as min players)
		choose_game_mode()
	}
}

// Ham Take Damage Forward (needed to block explosion damage too)
public fw_TakeDamage_gamemodes(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when no game mode is active
	if (g_CurrentGameMode == ORIGIN_NO_GAME_MODE)
		return HAM_SUPERCEDE;
	
	// Prevent friendly fire
	if (origin_is_zombie(attacker) == origin_is_zombie(victim))
		return HAM_SUPERCEDE;
	
	// Mode allows infection and zombie attacking human...
	if (g_AllowInfection && origin_is_zombie(attacker) && !origin_is_zombie(victim))
	{
		// Prevent infection/damage by HE grenade (bugfix)
		if (damage_type & DMG_HEGRENADE)
			return HAM_SUPERCEDE;
		
		// Infect only if damage is done to victim
		if (damage > 0.0 && GetHamReturnStatus() != HAM_SUPERCEDE)
		{
			// Infect victim!
			origin_infect(victim, attacker)
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

public origin_fw_infect_post_gamemodes(id, attacker)
{
	if (g_CurrentGameMode != ORIGIN_NO_GAME_MODE)
	{
		// Zombies are switched to Terrorist team
		cs_set_player_team(id, CS_TEAM_T)
	}
}

public origin_cure_post_gamemodes(id, attacker)
{
	if (g_CurrentGameMode != ORIGIN_NO_GAME_MODE)
	{
		// Humans are switched to CT team
		cs_set_player_team(id, CS_TEAM_CT)
	}
}


// Balance Teams
balance_teams()
{
	// Get amount of users playing
	new players_count = GetPlayingCount()
	
	// No players, don't bother
	if (players_count < 1) return;
	
	// Split players evenly
	new iTerrors
	new iMaxTerrors = players_count / 2
	new id, CsTeams:team
	
	// First, set everyone to CT
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Skip if not connected
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		// Skip if not playing
		if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
			continue;
		
		// Set team
		cs_set_player_team(id, CS_TEAM_CT, 0)
	}
	
	// Then randomly move half of the players to Terrorists
	while (iTerrors < iMaxTerrors)
	{
		// Keep looping through all players
		if (++id > g_MaxPlayers) id = 1
		
		// Skip if not connected
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		// Skip if not playing or already a Terrorist
		if (team != CS_TEAM_CT)
			continue;
		
		// Random chance
		if (random_num(0, 1))
		{
			cs_set_player_team(id, CS_TEAM_T, 0)
			iTerrors++
		}
	}
}

// Get Playing Count -returns number of users playing-
GetPlayingCount()
{
	new iPlaying, id, CsTeams:team
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		if (team != CS_TEAM_SPECTATOR && team != CS_TEAM_UNASSIGNED)
			iPlaying++
	}
	
	return iPlaying;
}

// Ambience Sound Effects Task
public ambience_sound_effects(taskid)
{
	if (g_CurrentGameMode == ORIGIN_NO_GAME_MODE)
		return;
	
	// Play a random sound depending on game mode
	new current_game_mode = origin_gmodes_get_current()+1
	new Array:sounds_handle = ArrayGetCell(g_ambience_sounds_handle, current_game_mode)
	new Array:durations_handle = ArrayGetCell(g_ambience_durations_handle, current_game_mode)

	// No ambience sounds loaded for this mode
	if (sounds_handle == Invalid_Array || durations_handle == Invalid_Array)
		return;

	// Get random sound from array
	new sound[64], iRand, duration
	iRand = random_num(0, ArraySize(sounds_handle) - 1)
	ArrayGetString(sounds_handle, iRand, sound, charsmax(sound))
	duration = ArrayGetCell(durations_handle, iRand)

	// Play it on clients
	PlaySoundToClients(sound)

	// Set the task for when the sound is done playing
	set_task(float(duration), "ambience_sound_effects", TASK_AMBIENCESOUNDS)
}
