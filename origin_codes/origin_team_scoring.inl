public Plugin_init_teamscoring()
{
	cvar_winner_show_hud = register_cvar("origin_winner_show_hud", "1")
	cvar_winner_sounds = register_cvar("origin_winner_sounds", "1")
}

public Plugin_precache_teamscoring()
{
	// Initialize arrays
	g_sound_win_zombies = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_win_humans = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "WIN ZOMBIES", g_sound_win_zombies)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "WIN HUMANS", g_sound_win_humans)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_win_zombies) == 0)
	{
		for (index = 0; index < sizeof sound_win_zombies; index++)
			ArrayPushString(g_sound_win_zombies, sound_win_zombies[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "WIN ZOMBIES", g_sound_win_zombies)
	}
	if (ArraySize(g_sound_win_humans) == 0)
	{
		for (index = 0; index < sizeof sound_win_humans; index++)
			ArrayPushString(g_sound_win_humans, sound_win_humans[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "WIN HUMANS", g_sound_win_humans)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_win_zombies); index++)
	{
		ArrayGetString(g_sound_win_zombies, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_win_humans); index++)
	{
		ArrayGetString(g_sound_win_humans, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

public origin_fw_gmodes_end_tscoring()
{
	// Determine round winner, show HUD notice
	new sound[SOUND_MAX_LENGTH]
	if (!origin_get_human_count())
	{
		// Zombie team wins
		if (get_pcvar_num(cvar_winner_show_hud))
		{
			set_hudmessage(200, 0, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
			ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "WIN_ZOMBIE")
		}
		
		if (get_pcvar_num(cvar_winner_sounds))
		{
			ArrayGetString(g_sound_win_zombies, random_num(0, ArraySize(g_sound_win_zombies) - 1), sound, charsmax(sound))
			PlaySoundToClients(sound, 1)
		}
		
		g_ScoreZombies++
	}
	else
	{
		// Human team wins
		if (get_pcvar_num(cvar_winner_show_hud))
		{
			set_hudmessage(0, 0, 200, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
			ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "WIN_HUMAN")
		}
		
		if (get_pcvar_num(cvar_winner_sounds))
		{
			ArrayGetString(g_sound_win_humans, random_num(0, ArraySize(g_sound_win_humans) - 1), sound, charsmax(sound))
			PlaySoundToClients(sound, 1)
		}
		
		g_ScoreHumans++
	}
}


// Send actual team scores (T = zombies // CT = humans)
public message_teamscore_teamscoring()
{
	new team[2]
	get_msg_arg_string(1, team, charsmax(team))
	
	switch (team[0])
	{
		// CT
		case 'C': set_msg_arg_int(2, get_msg_argtype(2), g_ScoreHumans)
		// Terrorist
		case 'T': set_msg_arg_int(2, get_msg_argtype(2), g_ScoreZombies)
	}
}
