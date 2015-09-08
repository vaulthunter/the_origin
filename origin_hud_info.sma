#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <origin_class_zombie>

const Float:HUD_SPECT_X = 0.6
const Float:HUD_SPECT_Y = 0.8
const Float:HUD_STATS_X = 0.47//0.02
const Float:HUD_STATS_Y = 0.9

const HUD_STATS_ZOMBIE_R = 255
const HUD_STATS_ZOMBIE_G = 255
const HUD_STATS_ZOMBIE_B = 255

const HUD_STATS_HUMAN_R = 0
const HUD_STATS_HUMAN_G = 200
const HUD_STATS_HUMAN_B = 250

const HUD_STATS_SPEC_R = 255
const HUD_STATS_SPEC_G = 255
const HUD_STATS_SPEC_B = 255

#define TASK_SHOWHUD 100
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

const PEV_SPEC_TARGET = pev_iuser2

new g_MsgSync
new g_ScoreHumans, g_ScoreZombies, g_roundhud

public plugin_init()
{
	register_plugin("[Origin] HUD Information", ORIGIN_VERSION_STR_LONG, "Good_Hash")
	register_event("TeamScore", "team_score", "a");
	register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
	//set_task (0.6,"showScore",_,_,_,"b")

	g_MsgSync = CreateHudSyncObj()
}

public event_roundstart()
{
	g_roundhud += 1

	if (g_roundhud == 1)
	{
		g_ScoreHumans = 0
	}

}

public team_score()
{
	new team[32];
	read_data(1,team,31);
	if (equal(team,"CT"))
	{
		g_ScoreHumans = read_data(2);
	}
	else if (equal(team,"TERRORIST"))
	{
		g_ScoreZombies = read_data(2);
	}
}

public client_putinserver(id)
{
	if (!is_user_bot(id))
	{
		// Set the custom HUD display task
		set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, _, _, "b")
	}
}

public client_disconnect(id)
{
	remove_task(id+TASK_SHOWHUD)
}

// Show HUD Task
public ShowHUD(taskid)
{
	new player = ID_SHOWHUD

	// Player dead?
	if (!is_user_alive(player))
	{
		// Get spectating target
		player = pev(player, PEV_SPEC_TARGET)

		// Target not alive
		if (!is_user_alive(player))
			return;
	}

	// Format classname
	static class_name[32], transkey[64]
	new red, green, blue

	if (origin_is_zombie(player)) // zombies
	{
		red = HUD_STATS_ZOMBIE_R
		green = HUD_STATS_ZOMBIE_G
		blue = HUD_STATS_ZOMBIE_B

		origin_zclass_get_name(origin_zclass_get_current(player), class_name, charsmax(class_name))

		// ML support for class name
		formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", class_name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, transkey)
	}
	else // humans
	{
		red = HUD_STATS_HUMAN_R
		green = HUD_STATS_HUMAN_G
		blue = HUD_STATS_HUMAN_B

		//zp_class_human_get_name(zp_class_human_get_current(player), class_name, charsmax(class_name))

		// ML support for class name
		//formatex(transkey, charsmax(transkey), "HUMANNAME %s", class_name)
		//if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, transkey)
	}

	// Spectating someone else?
	if (player != ID_SHOWHUD)
	{
		new player_name[32]
		get_user_name(player, player_name, charsmax(player_name))

		// Show name, health, class, and money
		set_hudmessage(HUD_STATS_SPEC_R, HUD_STATS_SPEC_G, HUD_STATS_SPEC_B, HUD_SPECT_X, HUD_SPECT_Y, 0, 6.0, 1.1, 0.0, 0.0, -1)

		if (origin_is_zombie(player))
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "%L: %s^nHP: %d / %d - %L %s - %L $ %d", ID_SHOWHUD, "SPECTATING", player_name, get_user_health(player), origin_get_maxhealth(player), ID_SHOWHUD, "CLASS_CLASS", class_name, ID_SHOWHUD, "MONEY1", cs_get_user_money(player))
		else
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "%L: %s^nHP: %d - %L $ %d", ID_SHOWHUD, "SPECTATING", player_name, get_user_health(player), ID_SHOWHUD, "MONEY1", cs_get_user_money(player))
	}
	else
	{
		// Show health, class
		set_hudmessage(red, green, blue, HUD_STATS_X, HUD_STATS_Y, 0, 6.0, 1.1, 0.0, 0.0, -1)

		if (origin_is_zombie(player))
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "HP: %d / %d - %L %s / %L %i", get_user_health(ID_SHOWHUD), origin_get_maxhealth(ID_SHOWHUD), ID_SHOWHUD, "CLASS_CLASS", class_name, ID_SHOWHUD, "HUD_EVOLUTION", origin_get_evolution(ID_SHOWHUD))
		else
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "HP: %d / %L %i", get_user_health(ID_SHOWHUD), ID_SHOWHUD, "HUD_ATTACK_POWER", origin_get_apower(ID_SHOWHUD))
	}
}

public showScore()
{
	set_dhudmessage(255, 255, 20, -1.0, 0.0, 0, 0.0, 0.01)
	show_dhudmessage(0, "%L", LANG_PLAYER, "ORIGIN_SCORE", fn_get_humans(),g_roundhud,fn_get_zombies(),g_ScoreHumans,g_ScoreZombies)
}

fn_get_humans()
{
	static iAlive, id
	iAlive = 0

	for (id = 1; id <= 32; id++)
	{
		if (is_user_alive(id) && !origin_is_zombie(id))
			iAlive++
	}

	return iAlive;
}

fn_get_zombies()
{
	static iAlive, id
	iAlive = 0

	for (id = 1; id <= 32; id++)
	{
		if (is_user_alive(id) && origin_is_zombie(id))
			iAlive++
	}

	return iAlive;
}