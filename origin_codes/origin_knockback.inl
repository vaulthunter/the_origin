public Plugin_init_kb()
{
	cvar_knockback_damage = register_cvar("origin_knockback_damage", "1")
	cvar_knockback_power = register_cvar("origin_knockback_power", "1")
	cvar_knockback_obey_class = register_cvar("origin_knockback_obey_class", "1")
	cvar_knockback_zvel = register_cvar("origin_knockback_zvel", "0")
	cvar_knockback_ducking = register_cvar("origin_knockback_ducking", "0.25")
	cvar_knockback_distance = register_cvar("origin_knockback_distance", "1000")
}

public Plugin_precache_kb()
{
	new index
	for (index = 1; index < sizeof WEAPONENTNAMES_UP; index++)
	{
		if (kb_weapon_power[index] == -1.0)
			continue;

		if (!amx_load_setting_float(ORIGIN_SETTINGS_FILE, "Knockback Power for Weapons", WEAPONENTNAMES_UP[index][7], kb_weapon_power[index]))
			amx_save_setting_float(ORIGIN_SETTINGS_FILE, "Knockback Power for Weapons", WEAPONENTNAMES_UP[index][7], kb_weapon_power[index])
	}
}

// Ham Trace Attack Post Forward
public fw_TraceAttack_Post_kb(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return;

	// Victim isn't zombie or attacker isn't human
	if (!origin_is_zombie(victim) || origin_is_zombie(attacker) || g_Knockback[victim] < 0.0)
		return;

	// Not bullet damage
	if (!(damage_type & DMG_BULLET))
		return;

	// Knockback only if damage is done to victim
	if (damage <= 0.0 || GetHamReturnStatus() == HAM_SUPERCEDE || get_tr2(tracehandle, TR_pHit) != victim)
		return;

	// Get whether the victim is in a crouch state
	new ducking = pev(victim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)

	// Zombie knockback when ducking disabled
	if (ducking && get_pcvar_float(cvar_knockback_ducking) == 0.0)
		return;

	// Get distance between players
	static origin1[3], origin2[3]
	get_user_origin(victim, origin1)
	get_user_origin(attacker, origin2)

	// Max distance exceeded
	if (get_distance(origin1, origin2) > get_pcvar_num(cvar_knockback_distance))
		return ;

	// Get victim's velocity
	static Float:velocity[3]
	pev(victim, pev_velocity, velocity)

	// Use damage on knockback calculation
	if (get_pcvar_num(cvar_knockback_damage))
		xs_vec_mul_scalar(direction, damage, direction)

	// Get attacker's weapon id
	new attacker_weapon = get_user_weapon(attacker)

	// Use weapon power on knockback calculation
	if (get_pcvar_num(cvar_knockback_power) && kb_weapon_power[attacker_weapon] > 0.0)
		xs_vec_mul_scalar(direction, kb_weapon_power[attacker_weapon], direction)

	if ( g_Knockback[victim] > 0.0 ) xs_vec_mul_scalar(direction, g_Knockback[victim], direction)

	// Apply ducking knockback multiplier
	if (ducking)
		xs_vec_mul_scalar(direction, get_pcvar_float(cvar_knockback_ducking), direction)

	if (get_pcvar_num(cvar_knockback_obey_class))
	{
		// Apply zombie class knockback multiplier
		xs_vec_mul_scalar(direction, origin_zclass_get_kb(origin_zclass_get_current(victim)), direction)
	}

	// Add up the new vector
	xs_vec_add(velocity, direction, direction)

	// Should knockback also affect vertical velocity?
	if (!get_pcvar_num(cvar_knockback_zvel))
		direction[2] = velocity[2]

	// Set the knockback'd victim's velocity
	set_pev(victim, pev_velocity, direction)
}
