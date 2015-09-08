public Plugin_init_gameplay_fixes()
{
	register_message(get_user_msgid("Health"), "message_health")
	
	cvar_block_suicide = register_cvar("origin_block_suicide", "1")
	cvar_disable_minmodels = register_cvar("originp_disable_minmodels", "1")
	cvar_block_pushables = register_cvar("origin_block_pushables", "1")
}

public Client_putinserver_fixes(id)
{
	// Disable minmodels for clients to see zombies properly?
	if (get_pcvar_num(cvar_disable_minmodels))
		set_task(0.1, "disable_minmodels_task", id)
}

public disable_minmodels_task(id)
{
	if (is_user_connected(id))
		client_cmd(id, "cl_minmodels 0")
}


// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post_fix(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;
	
	// Remove respawn task
	remove_task(id+TASK_RESPAWN)
}

// Client Disconnecting (prevent Game Commencing bug after last player on a team leaves)
public Client_disconnect_fixes(leaving_player)
{
	// Player was not alive
	if (!is_user_alive(leaving_player))
		return;
	
	// Last player, dont bother
	if (GetAliveCount() == 1)
		return;
	
	new id
	
	// Prevent empty teams when no game mode is in progress
	if (!g_GameModeStarted)
	{
		// Last Terrorist
		if ((cs_get_user_team(leaving_player) == CS_TEAM_T) && (GetAliveTCount() == 1))
		{
			// Find replacement and move him to T team
			while ((id = GetRandomAlive(random_num(1, GetAliveCount()))) == leaving_player ) { /* keep looping */ }
			cs_set_player_team(id, CS_TEAM_T)
		}
		// Last CT
		else if ((cs_get_user_team(leaving_player) == CS_TEAM_CT) && (GetAliveCTCount() == 1))
		{
			// Find replacement and move him to CT team
			while ((id = GetRandomAlive(random_num(1, GetAliveCount()))) == leaving_player ) { /* keep looping */ }
			cs_set_player_team(id, CS_TEAM_CT)
		}
	}
	// Prevent no zombies/humans after game mode started
	else
	{
		// Last Zombie
		if (origin_is_zombie(leaving_player) && origin_get_zombie_count() == 1)
		{
			// Only one CT left, don't leave an empty CT team
			if (origin_get_human_count() == 1 && GetCTCount() == 1)
				return;
			
			// Find replacement
			while ((id = GetRandomAlive(random_num(1, GetAliveCount()))) == leaving_player ) { /* keep looping */ }
			
			new name[32]
			get_user_name(id, name, charsmax(name))
			origin_colored_print(0, "%L", LANG_PLAYER, "LAST_ZOMBIE_LEFT", name)
			
			origin_infect(id, id)
		}
		// Last Human
		else if (!origin_is_zombie(leaving_player) && origin_get_human_count() == 1)
		{
			// Only one T left, don't leave an empty T team
			if (origin_get_zombie_count() == 1 && GetTCount() == 1)
				return;
			
			// Find replacement
			while ((id = GetRandomAlive(random_num(1, GetAliveCount()))) == leaving_player ) { /* keep looping */ }
			
			new name[32]
			get_user_name(id, name, charsmax(name))
			origin_colored_print(0, "%L", LANG_PLAYER, "LAST_HUMAN_LEFT", name)
			
			origin_cure(id, id)
		}
	}
}

public origin_fw_gmodes_start_fixes()
{
	
	// Block suicides by choosing a different team
	if (get_pcvar_num(cvar_block_suicide))
	{
		new id
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			if (!is_user_alive(id))
				continue;
			
			// Disable any opened team change menus (bugfix)
			if (get_pdata_int(id, OFFSET_CSMENUCODE) == MENUCODE_TEAMSELECT)
				set_pdata_int(id, OFFSET_CSMENUCODE, 0)
		}
	}
}

// Client Kill Forward
public fw_ClientKill_fixes()
{
	// Prevent players from killing themselves?
	if (get_pcvar_num(cvar_block_suicide) && g_GameModeStarted)
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

// Fix for the HL engine bug when HP is multiples of 256
public message_health(msg_id, msg_dest, msg_entity)
{
	// Get player's health
	new health = get_msg_arg_int(1)
	
	if ( !health ) return
		
	/*// Don't bother
	if (health < 256) return;
	
	// Check if we need to fix it
	if (health % 256 == 0)
		set_user_health(msg_entity, get_user_health(msg_entity) + 1)
	
	// HUD can only show as much as 255 hp*/
	new max_hp = origin_is_zombie(msg_entity) ? origin_get_maxhealth(msg_entity) : get_pcvar_num(cvar_human_health_default)
	new this_percent, Float:fhealth
	pev(msg_entity, pev_health, fhealth)
	
	this_percent = floatround(fhealth*100/max_hp)
	set_msg_arg_int(1, get_msg_argtype(1), this_percent)
}

// Get Alive CTs -returns number of CTs alive-
GetAliveCTCount()
{
	new iCTs, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
			iCTs++
	}
	
	return iCTs;
}

// Get Alive Ts -returns number of Ts alive-
GetAliveTCount()
{
	new iTs, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_T)
			iTs++
	}
	
	return iTs;
}

// Get CTs -returns number of CTs connected-
GetCTCount()
{
	new iCTs, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_connected(id) && cs_get_user_team(id) == CS_TEAM_CT)
			iCTs++
	}
	
	return iCTs;
}

// Get Ts -returns number of Ts connected-
GetTCount()
{
	new iTs, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_connected(id) && cs_get_user_team(id) == CS_TEAM_T)
			iTs++
	}
	
	return iTs;
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}
