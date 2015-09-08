public plugin_init_deathmatch()
{
	cvar_respawn_delay = register_cvar("origin_respawn_delay", "5")
	cvar_respawn_zombies = register_cvar("origin_respawn_zombies", "1")
	cvar_respawn_on_suicide = register_cvar("origin_respawn_on_suicide", "0")
}


// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post_dm(id)
{
	// Not alive or didn't join a team yet
	//if (!is_user_alive(id) || !cs_get_user_team(id))
	//	return;
	
	flag_set(g_RespawnAsZombie, id)
	
	// Remove respawn task
	task_exists(id+TASK_RESPAWN) ? remove_task(id+TASK_RESPAWN) : 0
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post_dm(victim, attacker, headshot)
{
	if ( origin_is_zombie(victim) )
	{
		// Respawn on suicide?
		if (!get_pcvar_num(cvar_respawn_on_suicide) && (victim == attacker || !is_user_connected(attacker)))
				return;
				
		// Respawn if human/zombie?
		if (!get_pcvar_num(cvar_respawn_zombies))
			return;
				
		if(!headshot)
		{	
			origin_respawnwait[victim] = get_pcvar_num(cvar_respawn_delay)
			// Set the respawn task
			set_task(get_pcvar_float(cvar_respawn_delay), "respawn_player_task", victim+TASK_RESPAWN)
			
			zp_zbrespawn(victim)
			zp_zbrespawn_msg(victim)
		}
		else
		{
			zp_zbrespawn_msg2(victim)
		}
	}
}


public zp_zbrespawn(iVictim)
{
	if (!g_GameModeStarted || !is_user_connected(iVictim) || is_user_alive(iVictim))
		return

	origin_effect_respawn(iVictim)
	set_task(2.0, "zp_zbrespawn", iVictim)
	
	return
}

public zp_zbrespawn_msg(iVictim)
{
	if (!g_GameModeStarted || !is_user_connected(iVictim))
		return
		
	new iText[64], time_one[30], time_some[30], time_many[30]
	
	lang_GetTimeName ( TIME_SECONS_ONE, LANG_PLAYER, time_one, 30 )
	lang_GetTimeName ( TIME_SECONS_SOME, LANG_PLAYER, time_some, 30 )
	lang_GetTimeName ( TIME_SECONS_MANY, LANG_PLAYER, time_many, 30 )
	
	format(iText, charsmax(iText), "%L", LANG_PLAYER, "ORIGIN_ZOMBIERESPAWN_MSG", get_correct_str( origin_respawnwait[iVictim], time_one, time_some, time_many ) )
	client_print(iVictim, print_center, iText)
	
	origin_respawnwait[iVictim] -= 1
	
	if(origin_respawnwait[iVictim] >= 1)
	{
		set_task(1.0, "zp_zbrespawn_msg", iVictim)
	}
	
	return
}

zp_zbrespawn_msg2(iVictim)
{
	if (!g_GameModeStarted || !is_user_connected(iVictim) || is_user_alive(iVictim))
		return
		
	new iText[64]

	format(iText, charsmax(iText), "%L", LANG_PLAYER, "ZP_CSO_ZOMBIERESPAWN_MSG2")
	client_print(iVictim, print_center, iText)
	
	return
}

// Respawn Player Task (deathmatch)
public respawn_player_task(taskid)
{
	// Get player's team
	new CsTeams:team = cs_get_user_team(ID_RESPAWN)
	
	// Player moved to spectators
	if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		return;
	
	if (g_GameModeStarted) origin_respawn_as_zombie(ID_RESPAWN, true)
	
	// Allow other plugins to decide whether player can respawn or not
	ExecuteForward(g_Forwards[FW_USER_RESPAWN_PRE], g_ForwardResult, ID_RESPAWN)
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;
	
	respawn_player_manually(ID_RESPAWN)
}

// Respawn Player Manually (called after respawn checks are done)
respawn_player_manually(id)
{
	// Respawn!
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public client_disconnect_dm(id)
{
	// Remove tasks on disconnect
	remove_task(id+TASK_RESPAWN)
}

public origin_fw_gamemodes_end_dm()
{
	// Stop respawning after game mode ends
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
		remove_task(id+TASK_RESPAWN)
}

origin_effect_respawn(iVictim)
{
	static Float: zp_origin[3]
	
	pev(iVictim, pev_origin, zp_origin)
    
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	
	write_byte(TE_EXPLOSION)
	
	write_coord(floatround(zp_origin[0]))
	write_coord(floatround(zp_origin[1]))
	write_coord(floatround(zp_origin[2]))
	
	write_short(g_sprite_zombie_respawn)
	
	write_byte(10)
	write_byte(20)
	write_byte(14)
	
	message_end()
}
