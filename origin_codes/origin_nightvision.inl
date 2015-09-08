public plugin_init_nightvision()
{
	g_MsgNVGToggle = get_user_msgid("NVGToggle")
	register_message(g_MsgNVGToggle, "message_nvgtoggle")
	register_clcmd("nightvision", "clcmd_nightvision_toggle")

	cvar_nvision_radius = register_cvar("origin_nvision_radius", "400")
	cvar_nvision_zombie = register_cvar("origin_nvision_zombie", "0") // 1-give only // 2-give and enable // 3-give, enable, remove disabling
	cvar_nvision_zombie_color_R = register_cvar("origin_nvision_zombie_color_R", "0")//1
	cvar_nvision_zombie_color_G = register_cvar("origin_nvision_zombie_color_G", "50")//20
	cvar_nvision_zombie_color_B = register_cvar("origin_nvision_zombie_color_B", "50")//20
}

public origin_fw_infect_post_nvision(id, attacker)
{
	if (get_pcvar_num(cvar_nvision_zombie))
	{
		if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)

		if (get_pcvar_num(cvar_nvision_zombie) >= 2)
		{
			if (!flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else if (flag_get(g_NightVisionActive, id))
			clcmd_nightvision_toggle(id)
	}
	else
	{
		cs_set_user_nvg(id, 0)

		if (flag_get(g_NightVisionActive, id))
			DisableNightVision(id)
	}
}

public origin_cure_post_nvision(id, attacker)
{
	cs_set_user_nvg(id, 0)

	if (flag_get(g_NightVisionActive, id))
		DisableNightVision(id)
}

public clcmd_nightvision_toggle(id)
{
	if (is_user_alive(id))
	{
		// Player owns nightvision?
		if (!cs_get_user_nvg(id))
			return PLUGIN_CONTINUE;
	}

	if (flag_get(g_NightVisionActive, id))
	{
		if (get_pcvar_num(cvar_nvision_zombie) <= 2)
			DisableNightVision(id)
	}
	else
		EnableNightVision(id)

	return PLUGIN_HANDLED;
}

public fw_Pk_Post_nightvision(victim)
{
	// Enable spectators nightvision?
	spectator_nightvision(victim)
}

public Client_putinserver_nightvision(id)
{
	// Enable spectators nightvision?
	set_task(0.1, "spectator_nightvision", id)
}

public spectator_nightvision(id)
{
	// Player disconnected
	if (!is_user_connected(id) || is_user_bot(id))
		return;

	// Not a spectator
	if (is_user_alive(id))
		return;

	if (!flag_get(g_NightVisionActive, id))
		clcmd_nightvision_toggle(id)
}

public Client_disconnect_nightvision(id)
{
	// Reset nightvision flags
	flag_unset(g_NightVisionActive, id)
	//remove_task(id+TASK_NIGHTVISION)
}

// Prevent spectators' nightvision from being turned off when switching targets, etc.
public message_nvgtoggle(msg_id, msg_dest, msg_entity)
{
	return PLUGIN_HANDLED;
}

// Custom Night Vision Task
public custom_nightvision_task(taskid)
{
	//return
	new SPEC = !is_user_alive(ID_NIGHTVISION) ? 1 : 0
	new player = pev(ID_NIGHTVISION, PEV_SPEC_TARGET)

	if (SPEC && (!is_user_alive(player) || !origin_is_zombie(player)))
		return;

	// Get player's origin
	static origin[3]
	get_user_origin(ID_NIGHTVISION, origin)

	// Nightvision message
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, ID_NIGHTVISION)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(get_pcvar_num(cvar_nvision_radius)) // radius

	write_byte(get_pcvar_num(cvar_nvision_zombie_color_R)) // r
	write_byte(get_pcvar_num(cvar_nvision_zombie_color_G)) // g
	write_byte(get_pcvar_num(cvar_nvision_zombie_color_B)) // b

	//write_byte(70) // brightness | not tested!
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

EnableNightVision(id)
{
	flag_set(g_NightVisionActive, id)

	//set_task(0.1, "custom_nightvision_task", id+TASK_NIGHTVISION, _, _, "b")
	cs_set_user_nvg_active(id, 0)
}

DisableNightVision(id)
{
	flag_unset(g_NightVisionActive, id)

	//remove_task(id+TASK_NIGHTVISION)
}

stock cs_set_user_nvg_active(id, active)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_MsgNVGToggle, _, id)
	write_byte(active) // toggle
	message_end()
}
