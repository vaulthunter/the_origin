/*================================================================================

	--------------------------------------
	-*- [Origin] Class: Zombie: Heavy -*-
	--------------------------------------

================================================================================*/
#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <origin_class_zombie>
#include <cs_maxspeed_api>

new const zclass_name[] = "Heavy"
new const zclass_info[] = "Press G To Spawn Trap"
new const zclass_model[] = "heavy_zombi_host"
new const zombieclass1_models[][] = { "heavy_zombi_origin", "heavy_zombi_host" }
new const zclass_clawmodel[][] = {"models/origin/v_knife_heavy_zombi.mdl"}
const zclass_health = 3000
const Float:zclass_speed = 1.14
const Float:zclass_gravity = 0.84 // 1.13
const Float:zclass_knockback = 0.3

const MAX_TRAP = 30
new const trap_classname[] = "nstzb3_traps"
new idclass
const trap_total = 3
const Float:trap_timewait = 10.0
const Float:trapped_time = 8.0
new const model_trap[] = "models/origin/zombitrap.mdl"
new const sound_trapsetup[] = "the_origin/zombi_trapsetup.wav"
new const sound_trapped[] = "the_origin/zombi_trapped.wav"
new const zombieclass1_evolution[] = "the_origin/zombi_evolution.wav"
const Float:trap_timesetup = 0.1
const trap_invisible = 40

new const zombieclass1_healing[] = "the_origin/zombi_heal.wav"
new const zombieclass1_death1[] = "the_origin/zombi_death_1.wav"
new const zombieclass1_death2[] = "the_origin/zombi_death_2.wav"
new const zombieclass1_hurt1[] = "the_origin/zombi_hurt_01.wav"
new const zombieclass1_hurt2[] = "the_origin/zombi_hurt_02.wav"
new const zombieclass1_infect[] = "the_origin/human_death_01.wav"

new g_total_traps[33], g_trapping[33], g_player_trapped[33], g_waitsetup[33], TrapOrigins[33][MAX_TRAP][4]
new Float:g_temp_speed[33]
new g_msgScreenShake, g_msgSayText
new g_maxplayers
new g_roundend

new const g_Gren [] = "models/origin/v_zombibomb_heavy_zombi.mdl"
new g_Ability

enum (+= 100)
{
	TASK_TRAPSETUP = 2000,
	TASK_REMOVETRAP,
	TASK_REMOVE_TIMEWAIT,
	TASK_BOT_USE_SKILL
}

#define ID_TRAPSETUP (taskid - TASK_TRAPSETUP)
#define ID_REMOVETRAP (taskid - TASK_REMOVETRAP)
#define ID_REMOVE_TIMEWAIT (taskid - TASK_REMOVE_TIMEWAIT)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_init()
{
	register_plugin("[Origin] Class: Zombie: Heavy", ORIGIN_VERSION_STR_LONG, "Good_Hash")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_event("CurWeapon","EventCurWeapon","be","1=1")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")

	register_forward(FM_CmdStart, "fw_CmdStart")

	register_clcmd("drop", "cmd_setuptrap")

	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msgSayText = get_user_msgid("SayText")
	g_maxplayers = get_maxplayers()
}

// Forward Player PreThink
public fw_PlayerPreThink(id)
{
	// Checks...
	if (!is_user_alive(id))
		return;

	if (!origin_is_zombie(id)) return;

	if (idclass!=origin_zclass_get_current(id))
		return

	if (pev(id, pev_bInDuck)) {
		cs_set_player_maxspeed(id, (250.0)*zclass_speed*1.3)
	} else {
		cs_set_player_maxspeed(id, (250.0)*zclass_speed)
	}
}

public plugin_precache()
{
	precache_model(model_trap)
	precache_sound(sound_trapsetup)
	precache_sound(sound_trapped)

	new index
	//idclass = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	idclass = origin_zclass_register(zclass_name, zclass_info, zclass_health, zclass_speed, zclass_gravity,
	zombieclass1_healing, zombieclass1_evolution, zombieclass1_death1, zombieclass1_death2, zombieclass1_hurt1, zombieclass1_hurt2,
	zombieclass1_infect)
	origin_zclass_register_kb(idclass, zclass_knockback)
	for (index = 0; index < sizeof zombieclass1_models; index++)
		origin_zclass_register_model(idclass, zombieclass1_models[index])
	for (index = 0; index < sizeof zclass_clawmodel; index++)
	{
		origin_zclass_register_claw(idclass, zclass_clawmodel[index])
	}

	g_Ability = zombie_register_ability(idclass, "Trap", 10)
}

public client_putinserver(id)
{
	reset_value_player(id)
}

public client_disconnect(id)
{
	reset_value_player(id)
}

public event_round_start()
{
	g_roundend = 0

	for (new id=1; id<=g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;

		reset_value_player(id)
	}
}

public logevent_round_end()
{
	g_roundend = 1

	remove_traps()
}

public Death()
{
	new id = read_data(2)

	remove_trapped_when_infected(id)
	reset_value_player(id)
}

public origin_fw_infect_post(id, attacker)
{
	remove_trapped_when_infected(id)
	reset_value_player(id)

	if (idclass!=origin_zclass_get_current(id))
		return

	if(is_user_bot(id))
	{
		set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		return
	}

	//zp_colored_print(id, "^x04[ZP]^x01 Your skill is^x04 Spawn Trap^x01. Cooldown^x04 %.1f ^x01seconds.", trap_timewait)
}

public origin_fw_cure_post(id, attacker)
{
	remove_trapped_when_infected(id)
	reset_value_player(id)
}

public EventCurWeapon(id)
{
	if (!is_user_alive(id)) return;

	if (origin_is_zombie(id)) return;

	new ent_trap = g_player_trapped[id]
	if (ent_trap && pev_valid(ent_trap))
	{
		set_pev(id, pev_maxspeed, 1.0)
	}

	return;
}

public cmd_setuptrap(id)
{
	if (g_roundend) return PLUGIN_CONTINUE

	if (!is_user_alive(id) || !origin_is_zombie(id)) return PLUGIN_CONTINUE

	if (idclass==origin_zclass_get_current(id) && !g_trapping[id] && !g_waitsetup[id])
	{
		if (g_total_traps[id]>=trap_total)
		{
			//zp_colored_print(id, "^x04[ZP]^x01 You only can spawn^x04 %d ^x01traps at the same time.", trap_total)

			return PLUGIN_HANDLED
		}

		g_trapping[id] = 1

		remove_task(id+TASK_TRAPSETUP)

		set_task(trap_timesetup, "TrapSetup", id+TASK_TRAPSETUP)

		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public TrapSetup(taskid)
{
	new id = ID_TRAPSETUP

	remove_setuptrap(id)

	create_w_class(id)

	PlayEmitSound(id, sound_trapsetup)

	remove_task(taskid)

	g_waitsetup[id] = 1

	remove_task(id+TASK_REMOVE_TIMEWAIT)

	new Float:time = trap_timewait;
	if (origin_get_evolution(id)<1)
		time /= 2;
	zombie_use_ability(id, g_Ability, floatround(time), 1)

	set_task(time, "RemoveTimeWait", id+TASK_REMOVE_TIMEWAIT)
}

remove_setuptrap(id)
{
	g_trapping[id] = 0
	g_waitsetup[id] = 0

	remove_task(id+TASK_TRAPSETUP)
	remove_task(id+TASK_REMOVE_TIMEWAIT)
}

create_w_class(id)
{
	if (g_roundend) return -1;

	if (!origin_is_zombie(id)) return -1;

	new user_flags = pev(id, pev_flags)
	if (!(user_flags & FL_ONGROUND))
	{
		return 0;
	}

	new Float:origin[3]
	pev(id, pev_origin, origin)

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) return -1;

	set_pev(ent, pev_classname, trap_classname)
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_owner, id)
	new Float:mins[3] = { -20.0, -20.0, 0.0 }
	new Float:maxs[3] = { 20.0, 20.0, 30.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	engfunc(EngFunc_SetModel, ent, model_trap)
	set_pev(ent, pev_origin, origin)
	drop_to_floor(ent)
	set_rendering(ent,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, trap_invisible)

	g_total_traps[id] += 1
	TrapOrigins[id][g_total_traps[id]][0] = ent
	TrapOrigins[id][g_total_traps[id]][1] = FloatToNum(origin[0])
	TrapOrigins[id][g_total_traps[id]][2] = FloatToNum(origin[1])
	TrapOrigins[id][g_total_traps[id]][3] = FloatToNum(origin[2])

	return -1;
}

public RemoveTimeWait(taskid)
{
	new id = ID_REMOVE_TIMEWAIT

	g_waitsetup[id] = 0

	//zp_colored_print(id, "^x04[ZP]^x01 Your skill^x04 Spawn Trap^x01 is ready.")
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL

	if (!is_user_alive(id)) return;

	cmd_setuptrap(id)

	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || !origin_is_zombie(id)) return;

	new ent_trap = g_player_trapped[id]
	if (ent_trap && pev_valid(ent_trap))
	{
		static classname[32]
		pev(ent_trap, pev_classname, classname, charsmax(classname))
		if (equal(classname, classname))
		{
			if (pev(ent_trap, pev_sequence) != 1)
			{
				set_pev(ent_trap, pev_sequence, 1)
				set_pev(ent_trap, pev_frame, 0.0)
			}
			else
			{
				if (pev(ent_trap, pev_frame) > 230)
					set_pev(ent_trap, pev_frame, 20.0)
				else
					set_pev(ent_trap, pev_frame, pev(ent_trap, pev_frame) + 1.0)
			}
		}
	}

	return;
}

public pfn_touch(ent, victim)
{
	if(pev_valid(ent))
	{
		new classname[32]
		pev(ent, pev_classname, classname, charsmax(classname))

		if(equal(classname, trap_classname))
		{
			if (!g_roundend && is_user_alive(victim) && !origin_is_zombie(victim) && !g_player_trapped[victim])
			{
				Trapped(victim, ent)
			}
		}
	}
}

Trapped(id, ent_trap)
{
	for (new i=1; i<=g_maxplayers; i++)
	{
		if (is_user_connected(i) && g_player_trapped[i]==ent_trap) return;
	}

	g_player_trapped[id] = ent_trap

	new shock[3]
	shock[0] = random_num(2,20)
	shock[1] = random_num(2,5)
	shock[2] = random_num(2,20)
	message_begin(MSG_ONE, g_msgScreenShake, _, id)
	write_short((1<<12)*shock[0])
	write_short((1<<12)*shock[1])
	write_short((1<<12)*shock[2])
	message_end()

	pev(id, pev_maxspeed, g_temp_speed[id]) //get temp speed
	set_pev(id, pev_maxspeed, 1.0) //set lower speed prevent move

	PlayEmitSound(id, sound_trapped)
	set_rendering(ent_trap)
	//zp_colored_print(id, "^x04[ZP]^x01 You are trapped for^x04 %.1f ^x01seconds.", trapped_time)

	remove_task(id+TASK_REMOVETRAP)
	set_task(trapped_time, "RemoveTrapAndTrappedUser", id+TASK_REMOVETRAP)

	UpdateTrap(ent_trap)
}

public RemoveTrapAndTrappedUser(taskid)
{
	new id = ID_REMOVETRAP

	remove_trapped_when_infected(id)

	// set previous speed for player
	set_pev(id, pev_maxspeed, g_temp_speed[id])
	//zp_colored_print(id, "^x04[ZP]^x01 Now you^x04 Can Move^x01. Go! Go! Go!", trap_timewait)

	remove_task(taskid)
}

UpdateTrap(ent_trap)
{
	new id = pev(ent_trap, pev_owner)

	new total, TrapOrigins_new[MAX_TRAP][4]
	for (new i = 1; i <= g_total_traps[id]; i++)
	{
		if (TrapOrigins[id][i][0] != ent_trap)
		{
			total += 1
			TrapOrigins_new[total][0] = TrapOrigins[id][i][0]
			TrapOrigins_new[total][1] = TrapOrigins[id][i][1]
			TrapOrigins_new[total][2] = TrapOrigins[id][i][2]
			TrapOrigins_new[total][3] = TrapOrigins[id][i][3]
		}
	}
	TrapOrigins[id] = TrapOrigins_new
	g_total_traps[id] = total
}

remove_trapped_when_infected(id)
{
	new p_trapped = g_player_trapped[id]
	if (p_trapped)
	{
		if (pev_valid(p_trapped)) engfunc(EngFunc_RemoveEntity, p_trapped)

		g_player_trapped[id] = 0
	}
}

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

FloatToNum(Float:floatn)
{
	new str[64], num
	float_to_str(floatn, str, 63)
	num = str_to_num(str)

	return num
}

remove_traps()
{
	new nextitem  = find_ent_by_class(-1, trap_classname)
	while(nextitem)
	{
		remove_entity(nextitem)
		nextitem = find_ent_by_class(-1, trap_classname)
	}
}

remove_traps_player(id)
{
	for (new i = 1; i <= g_total_traps[id]; i++)
	{
		new trap_ent = TrapOrigins[id][i][0]
		if (is_valid_ent(trap_ent)) engfunc(EngFunc_RemoveEntity, trap_ent)
	}

	new TrapOrigins_pl[MAX_TRAP][4]
	TrapOrigins[id] = TrapOrigins_pl
}

reset_value_player(id)
{
	g_total_traps[id] = 0
	g_trapping[id] = 0
	g_player_trapped[id] = 0
	g_waitsetup[id] = 0

	remove_task(id+TASK_TRAPSETUP)
	remove_task(id+TASK_REMOVETRAP)
	remove_task(id+TASK_REMOVE_TIMEWAIT)
	remove_task(id+TASK_BOT_USE_SKILL)

	remove_traps_player(id)
}

zp_colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()

	if (!target)
	{
		static player
		for (player = 1; player <= g_maxplayers; player++)
		{
			if (!is_user_connected(player))
				continue;

			static changed[5], changedcount
			changedcount = 0

			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}

			vformat(buffer, charsmax(buffer), message, 3)

			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()

			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	else
	{
		vformat(buffer, charsmax(buffer), message, 3)

		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
