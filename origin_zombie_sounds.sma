#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <origin_engine>
#include <origin_class_zombie>

// Settings file
new const ORIGIN_SETTINGS_FILE[] = "origin_zombie_mod.ini"

// Default sounds
new const sound_zombie_fall[][] = { "the_origin/zombie_fall1.wav" }
new const sound_zombie_miss_slash[][] = { "the_origin/zombi_swing_3.wav" , "the_origin/zombi_swing_2.wav", "the_origin/zombi_swing_1.wav" }
new const sound_zombie_miss_wall[][] = { "the_origin/zombi_wall_3.wav" , "the_origin/zombi_wall_2.wav" , "the_origin/zombi_wall_1.wav"}
new const sound_zombie_hit_normal[][] = { "the_origin/zombi_attack_3.wav" , "the_origin/zombi_attack_2.wav" , "the_origin/zombi_attack_1.wav" }
new const sound_zombie_hit_stab[][] = { "the_origin/zombi_attack_3.wav" }
new const sound_zombie_idle[][] = { "the_origin/idle_breath_04.wav" , "the_origin/idle_breath_03.wav" , "the_origin/idle_breath_06.wav" }
new const sound_zombie_idle_last[][] = { "nihilanth/nil_thelast.wav" }

#define SOUND_MAX_LENGTH 64

// Custom sounds
new Array:g_sound_zombie_fall
new Array:g_sound_zombie_miss_slash
new Array:g_sound_zombie_miss_wall
new Array:g_sound_zombie_hit_normal
new Array:g_sound_zombie_hit_stab
new Array:g_sound_zombie_idle
new Array:g_sound_zombie_idle_last

#define TASK_IDLE_SOUNDS 100
#define ID_IDLE_SOUNDS (taskid - TASK_IDLE_SOUNDS)

new cvar_zombie_sounds_pain, cvar_zombie_sounds_attack, cvar_zombie_sounds_idle

public plugin_init()
{
	register_plugin("[Origin] Zombie Sounds", ORIGIN_VERSION_STR_LONG, "Good_Hash")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	
	cvar_zombie_sounds_pain = register_cvar("origin_zombie_sounds_pain", "1")
	cvar_zombie_sounds_attack = register_cvar("origin_zombie_sounds_attack", "1")
	cvar_zombie_sounds_idle = register_cvar("origin_zombie_sounds_idle", "0")
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_zombie_fall = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_miss_slash = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_miss_wall = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_hit_normal = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_hit_stab = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_idle = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_idle_last = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE FALL", g_sound_zombie_fall)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE MISS SLASH", g_sound_zombie_miss_slash)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE MISS WALL", g_sound_zombie_miss_wall)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE HIT NORMAL", g_sound_zombie_hit_normal)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE HIT STAB", g_sound_zombie_hit_stab)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE", g_sound_zombie_idle)
	amx_load_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE LAST", g_sound_zombie_idle_last)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_zombie_fall) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_fall; index++)
			ArrayPushString(g_sound_zombie_fall, sound_zombie_fall[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE FALL", g_sound_zombie_fall)
	}
	if (ArraySize(g_sound_zombie_miss_slash) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_miss_slash; index++)
			ArrayPushString(g_sound_zombie_miss_slash, sound_zombie_miss_slash[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE MISS SLASH", g_sound_zombie_miss_slash)
	}
	if (ArraySize(g_sound_zombie_miss_wall) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_miss_wall; index++)
			ArrayPushString(g_sound_zombie_miss_wall, sound_zombie_miss_wall[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE MISS WALL", g_sound_zombie_miss_wall)
	}
	if (ArraySize(g_sound_zombie_hit_normal) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_hit_normal; index++)
			ArrayPushString(g_sound_zombie_hit_normal, sound_zombie_hit_normal[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE HIT NORMAL", g_sound_zombie_hit_normal)
	}
	if (ArraySize(g_sound_zombie_hit_stab) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_hit_stab; index++)
			ArrayPushString(g_sound_zombie_hit_stab, sound_zombie_hit_stab[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE HIT STAB", g_sound_zombie_hit_stab)
	}
	if (ArraySize(g_sound_zombie_idle) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_idle; index++)
			ArrayPushString(g_sound_zombie_idle, sound_zombie_idle[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE", g_sound_zombie_idle)
	}
	if (ArraySize(g_sound_zombie_idle_last) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_idle_last; index++)
			ArrayPushString(g_sound_zombie_idle_last, sound_zombie_idle_last[index])
		
		// Save to external file
		amx_save_setting_string_arr(ORIGIN_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE LAST", g_sound_zombie_idle_last)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	
	for (index = 0; index < ArraySize(g_sound_zombie_fall); index++)
	{
		ArrayGetString(g_sound_zombie_fall, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_miss_slash); index++)
	{
		ArrayGetString(g_sound_zombie_miss_slash, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_miss_wall); index++)
	{
		ArrayGetString(g_sound_zombie_miss_wall, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_hit_normal); index++)
	{
		ArrayGetString(g_sound_zombie_hit_normal, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_hit_stab); index++)
	{
		ArrayGetString(g_sound_zombie_hit_stab, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_idle); index++)
	{
		ArrayGetString(g_sound_zombie_idle, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_idle_last); index++)
	{
		ArrayGetString(g_sound_zombie_idle_last, index, sound, charsmax(sound))
		precache_sound(sound)
	}
}


// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Replace these next sounds for zombies only
	if (!is_user_connected(id) || !origin_is_zombie(id))
		return FMRES_IGNORED;
	
	static sound[SOUND_MAX_LENGTH]
	if (get_pcvar_num(cvar_zombie_sounds_pain))
	{
		// Zombie being hit
		if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
		{
			origin_zclass_get_sound(origin_zclass_get_current(id), random_num(0,1) ? KEY_SOUND_HURT1 : KEY_SOUND_HURT2, sound, SOUND_MAX_LENGTH)
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		
		// Zombie dies
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			origin_zclass_get_sound(origin_zclass_get_current(id), random_num(0,1) ? KEY_SOUND_DEATH1: KEY_SOUND_DEATH2, sound, SOUND_MAX_LENGTH)
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		
		// Zombie falls off
		if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
		{
			ArrayGetString(g_sound_zombie_fall, random_num(0, ArraySize(g_sound_zombie_fall) - 1), sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}
	
	if (get_pcvar_num(cvar_zombie_sounds_attack))
	{
		// Zombie attacks with knife
		if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
			{
				ArrayGetString(g_sound_zombie_miss_slash, random_num(0, ArraySize(g_sound_zombie_miss_slash) - 1), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if (sample[17] == 'w') // wall
				{
					ArrayGetString(g_sound_zombie_miss_wall, random_num(0, ArraySize(g_sound_zombie_miss_wall) - 1), sound, charsmax(sound))
					emit_sound(id, channel, sound, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				else
				{
					ArrayGetString(g_sound_zombie_hit_normal, random_num(0, ArraySize(g_sound_zombie_hit_normal) - 1), sound, charsmax(sound))
					emit_sound(id, channel, sound, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
			}
			if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
			{
				ArrayGetString(g_sound_zombie_hit_stab, random_num(0, ArraySize(g_sound_zombie_hit_stab) - 1), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
	}
	
	return FMRES_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Remove idle sounds task
	remove_task(victim+TASK_IDLE_SOUNDS)
}

public client_disconnect(id)
{
	// Remove idle sounds task
	remove_task(id+TASK_IDLE_SOUNDS)
}

public origin_fw_infect_post(id, attacker)
{
	// Remove previous tasks
	remove_task(id+TASK_IDLE_SOUNDS)
	
	
	// Idle sounds?
	if (get_pcvar_num(cvar_zombie_sounds_idle))
		set_task(random_float(50.0, 70.0), "zombie_idle_sounds", id+TASK_IDLE_SOUNDS, _, _, "b")
}

public origin_fw_cure_post(id, attacker)
{
	// Remove idle sounds task
	remove_task(id+TASK_IDLE_SOUNDS)
}

// Play idle zombie sounds
public zombie_idle_sounds(taskid)
{
	static sound[SOUND_MAX_LENGTH]
	
	// Last zombie?
	if (origin_is_last_zombie(ID_IDLE_SOUNDS))
	{
		ArrayGetString(g_sound_zombie_idle_last, random_num(0, ArraySize(g_sound_zombie_idle_last) - 1), sound, charsmax(sound))
		emit_sound(ID_IDLE_SOUNDS, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else
	{
		ArrayGetString(g_sound_zombie_idle, random_num(0, ArraySize(g_sound_zombie_idle) - 1), sound, charsmax(sound))
		emit_sound(ID_IDLE_SOUNDS, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
