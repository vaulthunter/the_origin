public Plugin_init_zombie_features()
{
	g_MsgSetFOV = get_user_msgid("SetFOV")
	register_message(g_MsgSetFOV, "message_setfov")

	cvar_zombie_fov = register_cvar("origin_zombie_fov", "110")
	cvar_zombie_silent = register_cvar("origin_zombie_silent", "1")
}

public message_setfov(msg_id, msg_dest, msg_entity)
{
	if (!is_user_alive(msg_entity) || !origin_is_zombie(msg_entity) || get_msg_arg_int(1) != CS_DEFAULT_FOV)
		return;

	set_msg_arg_int(1, get_msg_argtype(1), get_pcvar_num(cvar_zombie_fov))
}

public origin_fw_infect_post_features(id, attacker)
{
	// Set custom FOV?
	if (get_pcvar_num(cvar_zombie_fov) != CS_DEFAULT_FOV && get_pcvar_num(cvar_zombie_fov) != 0)
	{
		message_begin(MSG_ONE, g_MsgSetFOV, _, id)
		write_byte(get_pcvar_num(cvar_zombie_fov)) // angle
		message_end()
	}

	// Set silent footsteps?
	if (get_pcvar_num(cvar_zombie_silent))
		set_user_footsteps(id, 1)

}

public origin_fw_cure_post_features(id, attacker)
{
	// Restore FOV?
	if (get_pcvar_num(cvar_zombie_fov) != CS_DEFAULT_FOV && get_pcvar_num(cvar_zombie_fov) != 0)
	{
		message_begin(MSG_ONE, g_MsgSetFOV, _, id)
		write_byte(CS_DEFAULT_FOV) // angle
		message_end()
	}

	// Restore normal footsteps?
	if (get_pcvar_num(cvar_zombie_silent))
		set_user_footsteps(id, 0)
}

// Effect
EffectRestoreHealth(id)
{
	if (!is_user_alive(id)) return;

	static Float:origin[3];
	pev(id,pev_origin,origin);

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(restore_health_idspr); // sprites
	write_byte(15); // scale in 0.1's
	write_byte(12); // framerate
	write_byte(14); // flags
	message_end(); // message end

	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade , _, id);
	write_short(1<<10);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(255);//r
	write_byte(0);  //g
	write_byte(0);  //b
	write_byte(75);
	message_end();
}


// Restore health for zombie
zombie_restore_health(id)
{
	if (!origin_is_zombie(id) || !g_GameModeStarted || g_Evolution[id]<2) return;

	static Float:velocity[3]
	pev(id, pev_velocity, velocity)

	if (!velocity[0] && !velocity[1] && !velocity[2])
	{
		if (!g_restore_health[id]) g_restore_health[id] = get_systime()
	}
	else g_restore_health[id] = 0

	if (g_restore_health[id])
	{
		new max_hp = origin_get_maxhealth(id);
		new rh_time = get_systime() - g_restore_health[id]
		if (rh_time == RESTORE_HEALTH_TIME+1 && get_user_health(id) < max_hp)
		{
			// get health add
			new health_add = health_regen[g_Evolution[id]-1]

			// get health new
			new health_new = get_user_health(id)+health_add
			health_new = min(health_new, max_hp)

			// set health
			fm_set_user_health(id, health_new)
			g_restore_health[id] += 1

			// effect
			SendMsgDamage(id)
			EffectRestoreHealth(id)

			// play sound heal
			new sound_name[60]
			origin_zclass_get_sound(origin_zclass_get_current(id), KEY_SOUND_HEAL, sound_name, 59)
			PlaySound(id, sound_name)
		}
	}
}

SendMsgDamage(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, id)
	write_byte(0) // damage save
	write_byte(0) // damage take
	write_long(DMG_NERVEGAS) // damage type - DMG_RADIATION
	write_coord(0) // x
	write_coord(0) // y
	write_coord(0) // z
	message_end()
}

ZombieEvolution(id, num)
{
	if (!num || !is_user_alive(id) || !origin_is_zombie(id) ) return;

	num = g_Evolution[id] > 1 ? 5 : 2

	g_Evolution_progress[id] += num
	if (g_Evolution_progress[id] > MAX_EVOLUTION) g_Evolution_progress[id] = MAX_EVOLUTION

	/*new delete_for
	if ( g_Evolution[id] < 2 )
		delete_for = 3
	if ( 3 > g_Evolution[id] > 1 )
		delete_for = 5

	// update level of zombie
	new evolution_zb = g_Evolution_progress[id] % delete_for
	new levelup = (g_Evolution_progress[id]-evolution_zb)/delete_for*/
	new evolution_zb = g_Evolution_progress[id] % 10
	new levelup = (g_Evolution_progress[id]-evolution_zb)/10
	if (levelup && g_Evolution[id]<MAX_LEVEL_ZOMBIE)
	{
		// update level
		UpdateLevelZombie(id, levelup)

		// set health & armor
		UpdateHealthZombie(id)

		// create effect
		EffectLevelUp(id)

		// Update the model
		if ( g_Evolution[id] > 1 ) origin_set_zhost_model(id)

		// play sound evolution
		new sound_name[60]
		origin_zclass_get_sound(origin_zclass_get_current(id), KEY_SOUND_EVOLUTION, sound_name, 59)
		PlayEmitSound(id, CHAN_VOICE, sound_name)
	}

	// max level zombie
	g_Evolution_progress[id] = g_Evolution_progress[id] % 10
	if (g_Evolution[id] >= MAX_LEVEL_ZOMBIE) g_Evolution_progress[id] = MAX_EVOLUTION

	//client_print(id, print_chat, "PROGRESS: %i | evolution_zb %i | levelup: %i", g_Evolution_progress[id], evolution_zb, levelup)


}

UpdateLevelZombie(id, num)
{
	g_Evolution[id] += num
	if (g_Evolution[id] > MAX_LEVEL_ZOMBIE) g_Evolution[id] = MAX_LEVEL_ZOMBIE
}

UpdateHealthZombie(id)
{
	if ( !origin_is_zombie(id) || g_Evolution[id]<2 ) return;

	// set value
	new health = health_evolution[g_Evolution[id]-1], armor = armor_evolution[g_Evolution[id]-1]
	new min_health = origin_get_maxhealth(id);//origin_zclass_get_max_health(id, origin_zclass_get_current(id));

	// check value
	health = max(min_health, health)
	armor = max(300, armor)

	// set again start value
	// ??? origin_zclass_set_max_health(id, health)

	// give health
	fm_set_user_health(id, health)
	fm_set_user_armor(id, armor)
}

// Effect level up
EffectLevelUp(id)
{
	if (!is_user_alive(id)) return;

	// get origin
	static Float:origin[3]
	pev(id, pev_origin, origin)

	// set color
	new color[3]
	color[0] = get_color_level(id, 0)
	color[1] = get_color_level(id, 1)
	color[2] = get_color_level(id, 2)

	// create effect
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+100.0) // z axis
	write_short(id_sprites_levelup) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(color[0]) // red
	write_byte(color[1]) // green
	write_byte(color[2]) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()

	// create glow shell
	fm_set_rendering(id)
	fm_set_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, 0)
	if (task_exists(id+TASK_GLOWSHELL)) remove_task(id+TASK_GLOWSHELL)
	set_task(get_pcvar_float(cvar_glowshell_time), "RemoveGlowShell", id+TASK_GLOWSHELL)
}

get_color_level(id, num)
{
	new color[3]
	if ( origin_is_zombie(id) )
	{
		switch (g_Evolution[id])
		{
			case 2: color = {251,168,0}
			case 3: color = {255,10,0}
			default: color = {41,138,255}
		}
	}
	else
	{
		switch (g_SurvivorLevel)
		{
			case 1: color = {0,177,0}
			case 2: color = {0,177,0}
			case 3: color = {0,177,0}
			case 4: color = {137,191,20}
			case 5: color = {137,191,20}
			case 6: color = {250,229,0}
			case 7: color = {250,229,0}
			case 8: color = {243,127,1}
			case 9: color = {243,127,1}
			case 10: color = {255,3,0}
			case 11: color = {127,40,208}
			case 12: color = {127,40,208}
			case 13: color = {127,40,208}
			default: color = {0,177,0}
		}
	}

	return color[num];
}
