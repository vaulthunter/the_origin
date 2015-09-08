#include <amxmodx>
#include <amxmisc>
#include <amx_settings_api>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <xs>
#include <hamsandwich>
#include <cs_teams_api>
#include <origin_engine>
#include <origin_colorchat>
#include <origin_gamemodes>
#include <origin_class_zombie>
#include <origin_tutor>

#include "origin_codes/origin_constants.inl"
#include "origin_codes/origin_lang.inl"
#include "origin_codes/origin_objectives_remover.inl"
#include "origin_codes/origin_zombie_features.inl"
#include "origin_codes/origin_gameplay_fixes.inl"
#include "origin_codes/origin_effects_infect.inl"
#include "origin_codes/origin_human_armor.inl"
#include "origin_codes/origin_nightvision.inl"
#include "origin_codes/origin_rewards.inl"
#include "origin_codes/origin_weapon_drop.inl"
#include "origin_codes/origin_deathmatch.inl"
#include "origin_codes/origin_natives_fwds.inl"
#include "origin_codes/origin_gamemodes.inl"
#include "origin_codes/origin_team_scoring.inl"
#include "origin_codes/origin_knockback.inl"
#include "origin_codes/origin_human.inl"

public plugin_init()
{
	register_plugin("[Origin] Engine", ORIGIN_VERSION, "Good_Hash")

	// Register dictionary
	register_dictionary("zm_the_origin.txt")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "event_death", "a", "1>0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_message(get_user_msgid("TextMsg"), "message_textmsg")
	register_message(get_user_msgid("SendAudio"), "message_sendaudio")
	register_event("TextMsg", "event_game_restart", "a", "2=#Game_will_restart_in")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_AddPlayerItem, "player", "fw_AddPlayerItem")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_pushable", "fw_UsePushable")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	register_forward(FM_ClientKill, "fw_ClientKill")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_event("30", "event_intermission", "a")


	new WpnName[32]
	for(new i=1; i<=CSW_P90; i++)
	{
		if( !(NOCLIP_WEAPONS_BIT_SUM & (1<<i)) && get_weaponname(i, WpnName, charsmax(WpnName)) )
		{

			RegisterHam(Ham_Weapon_PrimaryAttack, WpnName, "fw_primary_attack")
			RegisterHam(Ham_Weapon_PrimaryAttack, WpnName, "fw_primary_attack_post",1)
		}
	}

	register_clcmd("chooseteam", "clcmd_changeteam")
	register_clcmd("jointeam", "clcmd_changeteam")

	g_MaxPlayers = get_maxplayers()
	g_msgScreenFade = get_user_msgid("ScreenFade");
	g_msgDamage = get_user_msgid("Damage")

	// To help players find Origin servers
	register_cvar("origin_version", ORIGIN_VERSION_STR_LONG, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("origin_version", ORIGIN_VERSION_STR_LONG)

	cvar_lighting = register_cvar("origin_lighting", "d")
	cvar_triggered_lights = register_cvar("origin_triggered_lights", "1")
	cvar_glowshell_time = register_cvar("origin_glowshell_time", "5")
	cvar_human_health_default = register_cvar("origin_human_health_default", "1000")
	cvar_painshockfree_zombie = register_cvar("origin_painshockfree_zombie", "1") // 1-all // 2-first only // 3-last only
	cvar_painshockfree_human = register_cvar("origin_painshockfree_human", "0") // 1-all // 2-last only

	// Use our includes
	Plugin_init_obj_remover()
	plugin_init_nightvision()
	Plugin_init_zombie_features()
	Plugin_init_gameplay_fixes()
	Plugin_init_infEffect()
	Plugin_init_human_armor()
	Plugin_init_rewards()
	Plugin_init_weapon_drop()
	Plugin_init_native_fwd()
	Plugin_init_gamemodes()
	plugin_init_deathmatch()
	Plugin_init_teamscoring()
	Plugin_init_kb()

	// Set a random skybox?
	if (g_sky_custom_enable)
	{
		new skyname[SKYNAME_MAX_LENGTH]
		ArrayGetString(g_sky_names, g_SkyArrayIndex, skyname, charsmax(skyname))
		set_cvar_string("sv_skyname", skyname)
	}

	// Disable sky lighting so it doesn't mess with our custom lighting
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)
}

public plugin_precache()
{
	// Initialize arrays
	g_sky_names = ArrayCreate(SKYNAME_MAX_LENGTH, 1)

	// Load from external file
	if (!amx_load_setting_int(ORIGIN_SETTINGS_FILE, "Custom Skies", "ENABLE", g_sky_custom_enable))
		amx_save_setting_int(ORIGIN_SETTINGS_FILE, "Custom Skies", "ENABLE", g_sky_custom_enable)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Custom Skies", "SKY NAMES", g_sky_names)

	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_sky_names) == 0)
	{
		for (index = 0; index < sizeof sky_names; index++)
			ArrayPushString(g_sky_names, sky_names[index])

		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Custom Skies", "SKY NAMES", g_sky_names)
	}

	if (g_sky_custom_enable)
	{
		// Choose random sky and precache sky files
		new path[128], skyname[SKYNAME_MAX_LENGTH]
		g_SkyArrayIndex = random_num(0, ArraySize(g_sky_names) - 1)
		ArrayGetString(g_sky_names, g_SkyArrayIndex, skyname, charsmax(skyname))
		formatex(path, charsmax(path), "gfx/env/%sbk.tga", skyname)
		precache_generic(path)
		formatex(path, charsmax(path), "gfx/env/%sdn.tga", skyname)
		precache_generic(path)
		formatex(path, charsmax(path), "gfx/env/%sft.tga", skyname)
		precache_generic(path)
		formatex(path, charsmax(path), "gfx/env/%slf.tga", skyname)
		precache_generic(path)
		formatex(path, charsmax(path), "gfx/env/%srt.tga", skyname)
		precache_generic(path)
		formatex(path, charsmax(path), "gfx/env/%sup.tga", skyname)
		precache_generic(path)
	}


	g_ambience_sounds_handle = ArrayCreate(1, 1)
	g_ambience_durations_handle = ArrayCreate(1, 1)

	new modename[32], key[64]
	for (index = 0; index < origin_gmodes_get_count(); index++)
	{
		origin_gmodes_get_name(index, modename, charsmax(modename))

		new Array:ambience_sounds = ArrayCreate(64, 1)
		formatex(key, charsmax(key), "SOUNDS (%s)", modename)
		amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Ambience Sounds", key, ambience_sounds)
		if (ArraySize(ambience_sounds) > 0)
		{
			// Precache ambience sounds
			new sound_index, sound[64], sound_path[96]
			for (sound_index = 0; sound_index < ArraySize(ambience_sounds); sound_index++)
			{
				ArrayGetString(ambience_sounds, sound_index, sound, charsmax(sound))
				if (equal(sound[strlen(sound)-4], ".mp3"))
				{
					formatex(sound_path, charsmax(sound_path), "sound/%s", sound)
					precache_generic(sound)
				}
				else
					precache_sound(sound)
			}
		}
		else
		{
			ArrayDestroy(ambience_sounds)
			amx_save_setting_string(ORIGIN_SETTINGS_FILE, "Ambience Sounds", key, "")
		}
		ArrayPushCell(g_ambience_sounds_handle, ambience_sounds)

		new Array:ambience_durations = ArrayCreate(1, 1)
		formatex(key, charsmax(key), "DURATIONS (%s)", modename)
		amx_load_setting_int_arr(ORIGIN_SETTINGS_FILE, "Ambience Sounds", key, ambience_durations)
		if (ArraySize(ambience_durations) <= 0)
		{
			ArrayDestroy(ambience_durations)
			amx_save_setting_string(ORIGIN_SETTINGS_FILE, "Ambience Sounds", key, "")
		}
		ArrayPushCell(g_ambience_durations_handle, ambience_durations)
	}

	restore_health_idspr = precache_model(restore_health_spr)
	id_sprites_levelup = precache_model(sprites_effects_levelup)
	g_sprite_zombie_respawn = precache_model(sprite_zombie_respawn)
	precache_sound(sound_selecting_round);

	// Use our includes
	plugin_precache_obj_remover()
	Plugin_precache_human_armor()
	Plugin_precache_teamscoring()
	Plugin_precache_gamemodes()
	Plugin_precache_kb()
}

public plugin_cfg()
{
	// Get configs dir
	new cfgdir[32]
	get_configsdir(cfgdir, charsmax(cfgdir))

	// Execute config file (zombieplague.cfg)
	server_cmd("exec %s/zombie_the_origin.cfg", cfgdir)

	// Prevents seeing enemies in the dark exploit
	server_cmd("mp_playerid 1")

	// Lighting task
	lighting_task()
	set_task(5.0, "lighting_task", _, _, _, "b")
}

public client_PreThink(id) {
	if ( flag_get(g_NightVisionActive, id) ) {
		custom_nightvision_task(id+TASK_NIGHTVISION)
	}
}

public event_round_start()
{
	// Remove lights?
	if (!get_pcvar_num(cvar_triggered_lights))
		set_task(0.1, "remove_lights")


	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_connected(id))
		{
			reset_value(id)
			strip_weapons(id, PRIMARY_ONLY)
			strip_weapons(id, SECONDARY_ONLY)
		}
	}

	g_SurvivorLevel = 0

	// Use our includes
	Event_round_start_gamemodes()
}

public plugin_natives()
{
	// Use our includes
	Plugin_natives_native_fwd()
}

public client_putinserver(id)
{
	// Use our includes
	Client_putinserver_fixes(id)
	Client_putinserver_nightvision(id)
}

public client_disconnect(id)
{
	// Use our includes
	Client_disconnect_fixes(id)
	client_disconnect_dm(id)
	Client_disconnect_nightvision(id)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id))
	{
		return FMRES_IGNORED
	}

	/*if (get_uc(uc_handle, UC_Impulse) == IMPULSE_FLASHLIGHT)
	{
		if ( origin_is_zombie(id) )
			set_uc(uc_handle, UC_Impulse, 0)
	}*/

	// restore health
	zombie_restore_health(id)

	// zombie weak
	//zombie_weak(id)

	return FMRES_IGNORED
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was zombie before disconnecting)
	flag_unset(g_IsZombie, id)
	flag_unset(g_IsZombieHost, id)
	flag_unset(g_RespawnAsZombie, id)

	// This should be called AFTER client disconnects (post forward)
	CheckLastZombieHuman()

	// Use our includes
	fw_ClientDisc_Post_gamemodes(id)
}

public grenade_throw(id, gid, wid) {
	// fix grenade throw.
	if ( origin_is_zombie(id) && wid == CSW_HEGRENADE ) {
		engfunc(EngFunc_RemoveEntity, gid);
	}
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if ( !attacker || !victim )
		return HAM_IGNORED

	if ( attacker == victim && origin_is_zombie(attacker) )
		return HAM_SUPERCEDE

	if ( (damage_type & DMG_FALL) && origin_is_zombie(attacker) ) {
		return HAM_SUPERCEDE
	}

	if (!origin_is_zombie(attacker))
	{
		g_restore_health[victim] = 0

		new Float:dmg_boos = 1.0

		new HUMAN_AP = origin_get_apower(attacker)
		HUMAN_AP = HUMAN_AP > 0 ? HUMAN_AP : 1

		if ((damage_type & DMG_HEGRENADE))
		{
			dmg_boos *= 5.0 * HUMAN_AP
		}
		else if (HUMAN_AP)
		{
			dmg_boos = damage*str_to_float(XDAMAGE[HUMAN_AP])
		}

		if ( dmg_boos > 1.0 ) SetHamParamFloat(4, dmg_boos)
	}
	else
	{
		// Last human is killed to trigger round end
		if (origin_get_human_count() == 1)
		{
			SetHamParamFloat(4, float(get_user_health(victim) * 5 ))
			return HAM_IGNORED
		}
	}

	// Use our includes
	if ( fw_TakeDamage_armor(victim, inflictor, attacker, damage, damage_type) == HAM_SUPERCEDE )
		return HAM_SUPERCEDE
	if ( fw_TakeDamage_gamemodes(victim, inflictor, attacker, damage, damage_type) == HAM_SUPERCEDE )
		return HAM_SUPERCEDE


	return HAM_IGNORED
}

public fw_TakeDamage_Post(victim)
{
	// Is zombie?
	if (origin_is_zombie(victim))
	{
		// Check if zombie should be pain shock free
		switch (get_pcvar_num(cvar_painshockfree_zombie))
		{
			case 0: return;
				case 2: if (!origin_is_first_zombie(victim)) return;
				case 3: if (!origin_is_last_zombie(victim)) return;
			}
	}
	else
	{
		// Check if human should be pain shock free
		switch (get_pcvar_num(cvar_painshockfree_human))
		{
			case 0: return;
				case 2: if (!origin_is_last_human(victim)) return;
			}
	}

	// Set pain shock free offset
	set_pdata_float(victim, OFFSET_PAINSHOCK,  1.0)
}

public fw_primary_attack(ent)
{
	new id = pev(ent,pev_owner)
	pev(id,pev_punchangle,cl_pushangle[id])

	return HAM_IGNORED
}
public fw_primary_attack_post(ent)
{
	new id = pev(ent,pev_owner)
	new HUMAN_AP = origin_get_apower(id)
	if (!origin_is_zombie(id) && HUMAN_AP )
	{
		//Recoil Wpn
		new Float: xrecoil = str_to_float(XRECOIL[HUMAN_AP])
		new Float:push[3]
		pev(id,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[id],push)
		xs_vec_mul_scalar(push,xrecoil,push)
		xs_vec_add(push,cl_pushangle[id],push)
		set_pev(id,pev_punchangle,push)
	}

	return HAM_IGNORED
}

public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	CheckLastZombieHuman()

	// Use our includes
	fw_Pk_Post_nightvision(victim)
	fw_PlayerKilled_Post_gamemodes(victim, attacker, shouldgib)
}

public event_death()
{
	new iKiller = read_data(1)
	new iVictim = read_data(2)
	new iHeadshot = read_data(3)

	fw_PlayerKilled_Post_dm(iVictim, iKiller, iHeadshot)

	if(iKiller == iVictim)
		return PLUGIN_CONTINUE

	if (!origin_is_zombie(iKiller) ) {
		g_SurvivorLevel++
		if(flag_get(g_IsZombieHost, iVictim) ) flag_unset(g_IsZombieHost, iVictim)
	}
	else
		ZombieEvolution(iKiller, 1)

	return PLUGIN_CONTINUE
}

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;

	// Prevent attacks when no game mode is active
	if (g_CurrentGameMode == ORIGIN_NO_GAME_MODE)
		return HAM_SUPERCEDE;

	// Prevent friendly fire
	if (origin_is_zombie(attacker) == origin_is_zombie(victim))
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public fw_TraceAttack_Post(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Use our includes
	fw_TraceAttack_Post_kb(victim, attacker, damage, direction, tracehandle, damage_type)
}

public fw_ClientKill()
{
	// Use our includes
	if ( fw_ClientKill_fixes() == FMRES_SUPERCEDE )
		return FMRES_SUPERCEDE

	return FMRES_IGNORED;
}

public fw_UsePushable()
{
	// Prevent speed bug with pushables?
	if (get_pcvar_num(cvar_block_pushables))
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}


// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Use our includes
	fw_EmitSound_objectives(id, channel, sample, volume, attn, flags, pitch)
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Use our includes
}

public origin_fw_gmodes_end()
{
	g_GameModeStarted = false

	// Stop ambience sounds
	remove_task(TASK_AMBIENCESOUNDS)

	// Use our includes
	origin_fw_gamemodes_end_dm()
	origin_fw_gmodes_end_tscoring()
}

public origin_fw_gmodes_start(game_mode_id)
{
	g_GameModeStarted = true

	// Use our includes
	origin_fw_gmodes_start_fixes()
}

public message_textmsg()
{
	new textmsg[22]
	get_msg_arg_string(2, textmsg, charsmax(textmsg))

	// Game restarting/game commencing, reset scores
	if (equal(textmsg, "#Game_will_restart_in") || equal(textmsg, "#Game_Commencing"))
	{
		g_ScoreHumans = 0
		g_ScoreZombies = 0
	}
	// Block round end related messages
	else if (equal(textmsg, "#Hostages_Not_Rescued") || equal(textmsg, "#Round_Draw") || equal(textmsg, "#Terrorists_Win") || equal(textmsg, "#CTs_Win"))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public message_sendaudio()
{
	new audio[17]
	get_msg_arg_string(2, audio, charsmax(audio))

	if(equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw"))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public message_teamscore()
{
	// Use our includes
	message_teamscore_teamscoring()
}

public origin_fw_infect_post(id, attacker)
{
	if(flag_get(g_IsZombieHost, id) )
	{
		g_Evolution[id] = 2
		g_Evolution_progress[id] = 3
	}
	else
	{
		g_Evolution[id] = 1
		ZombieEvolution(attacker, 1)
	}

	new sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_zombie_respawn, random_num(0, ArraySize(g_sound_zombie_respawn) - 1), sound, charsmax(sound))
	PlaySoundToClients(sound, 0)

	//ArrayGetString(g_sound_human_infect, random_num(0, ArraySize(g_sound_human_infect) - 1), sound, charsmax(sound))
	//PlayEmitSound(id, CHAN_VOICE, sound)
	new zclass = origin_zclass_get_current(id) || origin_zclass_get_next(id)
	origin_zclass_get_sound(zclass, KEY_SOUND_INFECTED, sound, charsmax(sound))
	PlayEmitSound(id, CHAN_VOICE, sound)

	g_Knockback[id] = 1.0

	// Use our includes
	origin_fw_infect_post_nvision(id, attacker)
	origin_fw_infect_post_effects(id, attacker)
	origin_fw_infect_post_rewards(id, attacker)
	origin_fw_infect_post_features(id, attacker)
	origin_fw_infect_post_gamemodes(id, attacker)
}

public origin_fw_cure_post(id, attacker)
{
	origin_fw_cure_post_armor(id, attacker)
	origin_cure_post_nvision(id, attacker)
	origin_cure_post_human(id)
	origin_cure_post_gamemodes(id, attacker)
	origin_fw_cure_post_features(id, attacker)
}

public origin_fw_infect(id, attacker)
{
	// Use our includes
	origin_fw_infect_weapon_drop(id, attacker)
}

public fw_SetModel(entity, const model[])
{
	// Use our includes
	fw_SetModel_weapon_drop(entity, model)
}

public fw_TouchWeapon(weapon, id)
{
	// Block weapon pickup for zombies?
	if (get_pcvar_num(cvar_zombie_block_pickup) && is_user_alive(id) && origin_is_zombie(id))
		return HAM_SUPERCEDE;
	return HAM_IGNORED;
}

public fw_AddPlayerItem(id, weapon_ent)
{
	// Use our includes
	fw_AddPlayerItem_weapon_drop(id, weapon_ent)
}

// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;

	// ZP Spawn Forward
	ExecuteForward(g_Forwards[FW_USER_SPAWN_POST], g_ForwardResult, id)

	// Set zombie/human attributes upon respawn
	if (flag_get(g_RespawnAsZombie, id))
		InfectPlayer(id)
	else
		CurePlayer(id)

	// Reset flag afterwards
	flag_unset(g_RespawnAsZombie, id)

	// Use our includes
	fw_PlayerSpawn_Post_dm(id)
	fw_PlayerSpawn_Post_fix(id)
}


// Ham Use Stationary Gun Forward
public fw_UseStationary(entity, caller, activator, use_type)
{
	// Prevent zombies from using stationary guns
	if (use_type == STATIONARY_USING && is_user_alive(caller) && origin_is_zombie(caller))
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

// Event Map Ended
public event_intermission()
{
	// Remove ambience sounds task
	remove_task(TASK_AMBIENCESOUNDS)
}

InfectPlayer(id, attacker = 0)
{
	ExecuteForward(g_Forwards[FW_USER_INFECT_PRE], g_ForwardResult, id, attacker)

	// One or more plugins blocked infection
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;

	ExecuteForward(g_Forwards[FW_USER_INFECT], g_ForwardResult, id, attacker)

	flag_set(g_IsZombie, id)

	if (GetZombieCount() == 1)
		flag_set(g_IsFirstZombie, id)
	else
		flag_unset(g_IsFirstZombie, id)

	ExecuteForward(g_Forwards[FW_USER_INFECT_POST], g_ForwardResult, id, attacker)

	CheckLastZombieHuman()
}

CurePlayer(id, attacker = 0)
{
	ExecuteForward(g_Forwards[FW_USER_CURE_PRE], g_ForwardResult, id, attacker)

	// One or more plugins blocked cure
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;

	ExecuteForward(g_Forwards[FW_USER_CURE], g_ForwardResult, id, attacker)

	flag_unset(g_IsZombie, id)
	flag_unset(g_IsZombieHost, id)

	ExecuteForward(g_Forwards[FW_USER_CURE_POST], g_ForwardResult, id, attacker)

	CheckLastZombieHuman()
}

// Last Zombie/Human Check
CheckLastZombieHuman()
{
	new id, last_zombie_id, last_human_id
	new zombie_count = GetZombieCount()
	new human_count = GetHumanCount()

	if (zombie_count == 1)
	{
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			// Last zombie
			if (is_user_alive(id) && flag_get(g_IsZombie, id))
			{
				flag_set(g_IsLastZombie, id)
				last_zombie_id = id
			}
			else
				flag_unset(g_IsLastZombie, id)
		}
	}
	else
	{
		g_LastZombieForwardCalled = false

		for (id = 1; id <= g_MaxPlayers; id++)
			flag_unset(g_IsLastZombie, id)
	}

	// Last zombie forward
	if (last_zombie_id > 0 && !g_LastZombieForwardCalled)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_ZOMBIE], g_ForwardResult, last_zombie_id)
		g_LastZombieForwardCalled = true
	}

	if (human_count == 1)
	{
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			// Last human
			if (is_user_alive(id) && !flag_get(g_IsZombie, id))
			{
				flag_set(g_IsLastHuman, id)
				last_human_id = id
			}
			else
				flag_unset(g_IsLastHuman, id)
		}
	}
	else
	{
		g_LastHumanForwardCalled = false

		for (id = 1; id <= g_MaxPlayers; id++)
			flag_unset(g_IsLastHuman, id)
	}

	// Last human forward
	if (last_human_id > 0 && !g_LastHumanForwardCalled)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_HUMAN], g_ForwardResult, last_human_id)
		g_LastHumanForwardCalled = true
	}
}

public native_origin_is_zombie(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d) | Plugin id (%d)", id, plugin_id)
		return -1;
	}

	return flag_get_boolean(g_IsZombie, id);
}

public native_origin_is_zhost(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return -1;
	}

	return flag_get_boolean(g_IsZombieHost, id);
}

public native_origin_get_evolution(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return -1;
	}

	return g_Evolution_progress[id];
}

public native_origin_get_apower(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return -1;
	}

	return g_SurvivorLevel;
}

public native_origin_is_first_zombie(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return -1;
	}

	return flag_get_boolean(g_IsFirstZombie, id);
}

public native_origin_is_last_zombie(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return -1;
	}

	return flag_get_boolean(g_IsLastZombie, id);
}

public native_origin_is_last_human(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return -1;
	}

	return flag_get_boolean(g_IsLastHuman, id);
}

public native_origin_get_zombie_count(plugin_id, num_params)
{
	return GetZombieCount();
}

public native_origin_get_human_count(plugin_id, num_params)
{
	return GetHumanCount();
}

public native_origin_infect(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return false;
	}

	if (flag_get(g_IsZombie, id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Player already infected (%d)", id)
		return false;
	}

	new attacker = get_param(2)
	new host = get_param(3)
	if ( host )
	{
		if (!flag_get(g_IsZombieHost, id))
		{
			flag_set(g_IsZombieHost, id)
		}
	}

	InfectPlayer(id, attacker)
	return true;
}

public native_origin_cure(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return false;
	}

	if (!flag_get(g_IsZombie, id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Player not infected (%d)", id)
		return false;
	}

	new attacker = get_param(2)

	CurePlayer(id, attacker)
	return true;
}

public native_origin_force_infect(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return false;
	}

	InfectPlayer(id)
	return true;
}

public native_origin_force_cure(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return false;
	}

	CurePlayer(id)
	return true;
}

public native_origin_respawn_as_zombie(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return false;
	}

	new respawn_as_zombie = get_param(2)

	if (respawn_as_zombie)
		flag_set(g_RespawnAsZombie, id)
	else
		flag_unset(g_RespawnAsZombie, id)

	return true;
}

public native_origin_set_knockback(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Origin] Invalid Player (%d)", id)
		return false;
	}

	new Float:knockback_power = get_param_f(2)

	if (knockback_power)
		g_Knockback[id] = knockback_power
	else
		g_Knockback[id] = 0.0

	return true;
}

// Get Zombie Count -returns alive zombies number-
GetZombieCount()
{
	new iZombies, id

	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsZombie, id))
			iZombies++
	}

	return iZombies;
}

// Get Human Count -returns alive humans number-
GetHumanCount()
{
	new iHumans, id

	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && !flag_get(g_IsZombie, id))
			iHumans++
	}

	return iHumans;
}

// Lighting Task
public lighting_task()
{
	if (!get_pcvar_num(cvar_nvision_zombie)) {
		return;
	}
	// Get lighting style
	new lighting[2]
	get_pcvar_string(cvar_lighting, lighting, charsmax(lighting))

	// Lighting disabled? ["0"]
	if (lighting[0] == '0')
		return

	engfunc(EngFunc_LightStyle, 0, lighting)
}

// Remove Stuff Task
public remove_lights()
{
	new ent

	// Triggered lights
	ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "light")) != 0)
	{
		dllfunc(DLLFunc_Use, ent, 0); // turn off the light
		set_pev(ent, pev_targetname, 0) // prevent it from being triggered
	}
}

// Team Change Commands
public clcmd_changeteam(id)
{
	// Block suicides by choosing a different team
	if (get_pcvar_num(cvar_block_suicide) && g_GameModeStarted && is_user_alive(id))
	{
		origin_colored_print(id, "%L", id, "CANT_CHANGE_TEAM")
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
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

PlaySound(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}

PlayEmitSound(id, type, const sound[])
{
	emit_sound(id, type, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock fm_set_user_health(id, health)
{
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}

stock fm_set_user_armor(id, armor)
{
	set_pev(id, pev_armorvalue, float(min(armor, 999)))
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)

	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

public RemoveGlowShell(taskid)
{
	fm_set_rendering(ID_GLOWSHELL)
	if (task_exists(taskid)) remove_task(taskid)
}

reset_value(id)
{
	if (task_exists(id+TASK_GLOWSHELL)) remove_task(id+TASK_GLOWSHELL)

	g_Evolution[id] = 0
	g_Evolution_progress[id] = 0
	g_Knockback[id] = -1.0

	if (is_user_alive(id))
	{
		fm_set_rendering(id)
	}
}

public cmd_block(id)
{
	return PLUGIN_CONTINUE
}
