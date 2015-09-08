#include <amxmodx>
#include <engine>
#include <origin_engine>
#include <origin_gamemodes_const>

#define MAX_BUFF_LEN 512

#include "includes/origin_hud.inl"

public plugin_init()
{
	register_plugin("[Origin] Hud install", ORIGIN_VERSION, "Good_Hash")
	register_event("DeathMsg", "event_death", "a", "1>0")
	register_concmd("origin_install", "test")

	g_msgScenario = get_user_msgid("Scenario")
	g_msgStatusIcon = get_user_msgid("StatusIcon")
}

public plugin_natives()
{
	register_library("origin_hud")
	register_native("origin_hud_show_ability", "native_origin_hud_show_ability")
	register_native("origin_hud_hide_ability", "native_origin_hud_hide_ability")
}

public native_origin_hud_show_ability(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d) | Ability", id)
		return 0;
	}

	new sprname[33]
	get_string(2, sprname, charsmax(sprname))
	if ( strlen(sprname) < 1 )
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid sprite (%s) | Ability", sprname)
		return 0;
	}

	show_hud(id, sprname, get_param(3), get_param(4), get_param(5), get_param(6))

	return 1
}

public native_origin_hud_hide_ability(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d) | Ability", id)
		return 0;
	}

	hide_hud(id)

	return 1
}

public plugin_precache()
{
	//precache_generic("origin_hud2.cmd")
	//precache_generic("hud.txt")

	new i
	for ( i=0; i < sizeof(human_level); i++ )
		precache_model(human_level[i])
	for ( i=0; i < sizeof(zombie_level); i++ )
		precache_model(zombie_level[i])

	precache_model(hud_kill_dl)
	precache_model(hud_ability_fastrun)
	precache_model(hud_help)
	//precache_model(hud_rf_dl)
	//precache_model(hud_rc_dl)
}


public origin_fw_gmodes_end()
{
	//if ( origin_get_human_count() )
	//{
	//	show_hud(0, hud_round_clear)
	//} else show_hud(0, hud_round_fail)

	//if (task_exists(TASK_HIDE_HUD)) remove_task(TASK_HIDE_HUD)
	//set_task(5.0, "task_hide_hud", TASK_HIDE_HUD)
}

public event_death()
{
	new iKiller = read_data(1)
	new iVictim = read_data(2)
	//new iHeadshot = read_data(3)

	if(iKiller == iVictim)
		return PLUGIN_CONTINUE

	show_hud(iKiller, hud_kill)
	if (task_exists(iKiller+TASK_HIDE_HUD_KILL)) remove_task(iKiller+TASK_HIDE_HUD_KILL)
	set_task(2.0, "task_hide_hud_kill", iKiller+TASK_HIDE_HUD_KILL)

	return PLUGIN_CONTINUE
}


public client_PostThink(id)
{
	show_player_level(id)
}


public test(id)
{

	new sBuffer[MAX_BUFF_LEN], iLen

	iLen = formatex(sBuffer, charsmax(sBuffer), "<html><head>")
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<h1>Install CSO hud?</h1>")
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<br>We will upload you one text file")
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "to update the hud system!<br>")
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<b><font color=red size=22>")
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<a href=^"origin_hud2.cmd^">INSTALL</a>")
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "</font></b><br></body></html>")

	show_motd(id, sBuffer, "The Origin : H.I.")

	return PLUGIN_HANDLED
}
