#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_teams_api>
#include <origin_gamemodes>

new g_MaxPlayers

new cvar_multi_show_hud, cvar_multi_sounds
new cvar_multi_allow_respawn, cvar_respawn_after_last_human

// Settings file
new const ORIGIN_SETTINGS_FILE[] = "origin_zombie_mod.ini"
new const MODE_NAME[] = "Infection Mode"

// Default sounds
new const sound_multi[][] = { "the_origin/zombi_ambience.mp3" }
new const sound_multi_duration[] = { 184 } // duration in seconds of each sound

#define SOUND_MAX_LENGTH 64


new Array:g_sound_multi
new Array:g_sound_multi_duration

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 200
#define HUD_EVENT_G 50
#define HUD_EVENT_B 0

new g_HudSync

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[Origin] Game Mode: Classic2", ORIGIN_VERSION_STR_LONG, "Good_Hash")
	new game_mode_id = origin_gmodes_register(MODE_NAME)
	origin_gmodes_set_default(game_mode_id)	
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_multi_allow_respawn = register_cvar("zp_multi_allow_respawn", "1")
	cvar_respawn_after_last_human = register_cvar("zp_respawn_after_last_human", "1")
	cvar_multi_show_hud = register_cvar("zp_multi_show_hud", "1")
	cvar_multi_sounds = register_cvar("origin_multi_sounds", "1")
	
	// Initialize arrays
	g_sound_multi = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_multi_duration = ArrayCreate(1, 1)
	
	new key[64]
	formatex(key, charsmax(key), "SOUNDS (%s)", MODE_NAME)
	
	// Load from external file
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Ambience sounds", key, g_sound_multi)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_multi) == 0)
	{
		for (index = 0; index < sizeof sound_multi; index++)
			ArrayPushString(g_sound_multi, sound_multi[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Ambience sounds", key, g_sound_multi)
	}
	
	formatex(key, charsmax(key), "DURATIONS (%s)", MODE_NAME)
	
	amx_load_setting_int_arr(ORIGIN_SETTINGS_FILE, "Ambience sounds", key, g_sound_multi_duration)
	
	// If we couldn't load custom sounds from file, use and save default ones
	if (ArraySize(g_sound_multi_duration) == 0)
	{
		for (index = 0; index < sizeof sound_multi_duration; index++)
			ArrayPushCell(g_sound_multi_duration, sound_multi_duration[index])
		// Save to external file
		amx_save_setting_int_arr(ORIGIN_SETTINGS_FILE, "Ambience sounds", key, g_sound_multi_duration)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_multi); index++)
	{
		ArrayGetString(g_sound_multi, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

// Deathmatch module's player respawn forward
public origin_fw_dm_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_multi_allow_respawn))
		return PLUGIN_HANDLED;
	
	// Respawn if only the last human is left?
	if (!get_pcvar_num(cvar_respawn_after_last_human) && origin_get_human_count() == 1)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}


public origin_fw_gmodes_choose_pre(game_mode_id, skipchecks)
{
	/*new alive_count = GetAliveCount()
	
	// Calculate zombie count with current ratio setting
	new zombie_count// = floatround(alive_count * get_pcvar_float(cvar_multi_ratio), floatround_ceil)
	if ( alive_count >= 31 )
		zombie_count = 4
	else if ( alive_count >= 21 )
		zombie_count = 3
	else if ( alive_count >= 11 )
		zombie_count = 2
	else if ( alive_count < 10 )
		zombie_count = 1
	
	// Game mode allowed*/
	return PLUGIN_CONTINUE;
}

public origin_fw_gmodes_start()
{
	// Allow infection for this game mode
	origin_gmodes_set_allow_infect()
	
	// iMaxZombies is rounded up, in case there aren't enough players
	new iZombies, id, alive_count = GetAliveCount()
	new iMaxZombies// = floatround(alive_count * get_pcvar_float(cvar_multi_ratio), floatround_ceil)
	if ( alive_count >= 31 )
		iMaxZombies = 4
	else if ( alive_count >= 21 )
		iMaxZombies = 3
	else if ( alive_count >= 11 )
		iMaxZombies = 2
	else if ( alive_count < 10 )
		iMaxZombies = 1
		
		
	// Randomly turn iMaxZombies players into zombies
	while (iZombies < iMaxZombies)
	{
		// Choose random guy
		id = GetRandomAlive(random_num(1, alive_count))
		
		// Dead or already a zombie
		if (!is_user_alive(id) || origin_is_zombie(id))
			continue;
		
		// Turn into a zombie
		origin_infect(id, 0, 1)
		iZombies++
	}
	
	// Turn the remaining players into humans
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Only those of them who aren't zombies
		if (!is_user_alive(id) || origin_is_zombie(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
		cs_set_user_money(id, 16000)
	}
	
	// Play multi infection sound
	if (get_pcvar_num(cvar_multi_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_multi, random_num(0, ArraySize(g_sound_multi) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_multi_show_hud))
	{
		// Show Multi Infection HUD notice
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_MULTI")
	}
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

// Plays a sound on clients
PlaySoundToClients(const sound[], stop_sounds_first = 0)
{
	if (stop_sounds_first)
	{
		if (equal(sound[strlen(sound)-4], ".mp3"))
			client_cmd(0, "stopsound; mp3 play ^"sound/%s^"", sound)
		else
			client_cmd(0, "mp3 stop; stopsound; spk ^"%s^"", sound)
	}
	else
	{
		if (equal(sound[strlen(sound)-4], ".mp3"))
			client_cmd(0, "mp3 play ^"sound/%s^"", sound)
		else
			client_cmd(0, "spk ^"%s^"", sound)
	}
}
