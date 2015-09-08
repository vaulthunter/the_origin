public Plugin_init_infEffect()
{
	g_MsgDeathMsg = get_user_msgid("DeathMsg")
	g_MsgScoreAttrib = get_user_msgid("ScoreAttrib")
	
	cvar_infect_show_notice = register_cvar("origin_infect_show_notice", "1")
}

public origin_fw_infect_post_effects(id, attacker)
{	
	// Attacker is valid?
	if (attacker && is_user_connected(attacker))
	{
		// Show infection death notice?
		if (get_pcvar_num(cvar_infect_show_notice))
		{
			// Send death notice and fix the "dead" attrib on scoreboard
			SendDeathMsg(attacker, id)
			FixDeadAttrib(id)
		}
	}
}

// Send Death Message for infections
SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, g_MsgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(1) // headshot flag
	write_string("knife") // killer's weapon
	message_end()
}

// Fix Dead Attrib on scoreboard
FixDeadAttrib(id)
{
	message_begin(MSG_BROADCAST, g_MsgScoreAttrib)
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}
