public Plugin_init_human_armor()
{
	cvar_human_armor_protect = register_cvar("origin_human_armor_protect", "0")
	cvar_human_armor_default = register_cvar("origin_human_armor_default", "100")
}

public Plugin_precache_human_armor()
{
	precache_sound(g_sound_armor_hit)
}

public origin_fw_cure_post_armor(id, attacker)
{
	new Float:armor
	pev(id, pev_armorvalue, armor)
	
	//if (armor < get_pcvar_float(cvar_human_armor_default))
	set_pev(id, pev_armorvalue, get_pcvar_float(cvar_human_armor_default))
		
	new Float:health
	pev(id, pev_health, health)
	if ( health < get_pcvar_float(cvar_human_health_default))
		set_pev(id, pev_health, get_pcvar_float(cvar_human_health_default))
}

// Ham Take Damage Forward
public fw_TakeDamage_armor(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Zombie attacking human...
	if (origin_is_zombie(attacker) && !origin_is_zombie(victim))
	{
		// Ignore damage coming from a HE grenade (bugfix)
		if (damage_type & DMG_HEGRENADE)
			return HAM_IGNORED;
		
		// Does human armor need to be reduced before infecting/damaging?
		if (!get_pcvar_num(cvar_human_armor_protect))
			return HAM_IGNORED;
		
		// Get victim armor
		static Float:armor
		pev(victim, pev_armorvalue, armor)
		
		// If he has some, block damage and reduce armor instead
		if (armor > 0.0)
		{
			emit_sound(victim, CHAN_BODY, g_sound_armor_hit, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			if (armor - damage > 0.0)
				set_pev(victim, pev_armorvalue, armor - damage)
			else
				cs_set_user_armor(victim, 0, CS_ARMOR_NONE)
			
			// Block damage, but still set the pain shock offset
			set_pdata_float(victim, OFFSET_PAINSHOCK, 0.5)
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}
