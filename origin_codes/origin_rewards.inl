public Plugin_init_rewards()
{
	g_MsgScoreInfo = get_user_msgid("ScoreInfo")
}

public origin_fw_infect_post_rewards(id, attacker)
{
	if (is_user_connected(attacker) && attacker != id)
	{
		// Reward frags, deaths
		UpdateFrags(attacker, id, 1, 1, 1)
	}
}

// Update Player Frags and Deaths
UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	// Set attacker frags
	set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) + frags))
	
	// Set victim deaths
	fm_cs_set_user_deaths(victim, cs_get_user_deaths(victim) + deaths)
	
	// Update scoreboard with attacker and victim info
	if (scoreboard)
	{
		message_begin(MSG_BROADCAST, g_MsgScoreInfo)
		write_byte(attacker) // id
		write_short(pev(attacker, pev_frags)) // frags
		write_short(cs_get_user_deaths(attacker)) // deaths
		write_short(0) // class?
		write_short(_:cs_get_user_team(attacker)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, g_MsgScoreInfo)
		write_byte(victim) // id
		write_short(pev(victim, pev_frags)) // frags
		write_short(cs_get_user_deaths(victim)) // deaths
		write_short(0) // class?
		write_short(_:cs_get_user_team(victim)) // team
		message_end()
	}
}

// Set User Deaths
stock fm_cs_set_user_deaths(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_CSDEATHS, value)
}
