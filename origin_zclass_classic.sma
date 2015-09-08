/*================================================================================

	-----------------------------------
	-*- [Origin] Class: Zombie: Classic -*-
	-----------------------------------

================================================================================*/

#include <amxmodx>
#include <engine>
#include <origin_class_zombie>
#include <origin_hud>
#include <cs_maxspeed_api>

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

// Classic Zombie Attributes
new const zombieclass1_name[] = "Regular zombie"
new const zombieclass1_info[] = "Scientist"
new const zombieclass1_models[][] = { "zb1origin_2", "zb1host2" }
new const zombieclass1_clawmodels[][] = { "models/origin/v_origin_zknife.mdl" }
new const zombieclass1_healing[] = "the_origin/zombi_heal.wav"
new const zombieclass1_evolution[] = "the_origin/zombi_evolution.wav"
new const zombieclass1_death1[] = "the_origin/zombi_death_1.wav"
new const zombieclass1_death2[] = "the_origin/zombi_death_2.wav"
new const zombieclass1_hurt1[] = "the_origin/zombi_hurt_01.wav"
new const zombieclass1_hurt2[] = "the_origin/zombi_hurt_02.wav"
new const zombieclass1_infect[] = "the_origin/human_death_01.wav"
const zombieclass1_health = 2000
const Float:zombieclass1_speed = 1.16
const Float:zombieclass1_gravity = 0.8
const Float:zombieclass1_knockback = 1.5

new g_ZombieClassID, g_IsFastRun, g_FastRun_Wait
new Float:g_user_speed[33]

new g_Ability, spr_skill[] = "g_fastrun"
new const sound_ability_activate[] = "the_origin/zombi_pressure.wav"
new const sound_ability_middle[][]  = { "the_origin/zombi_pre_idle_1.wav", "the_origin/zombi_pre_idle_2.wav" }

#define TASK_FASTRUN		231312
#define ID_FASTRUN 		(taskid - TASK_FASTRUN)

#define TASK_FASTRUN_HEARTBEAT	231412
#define ID_FASTRUN_HEARTBEAT (taskid - TASK_FASTRUN_HEARTBEAT)

#define TASK_FASTRUN_WAIT	231512
#define ID_FASTRUN_WAIT (taskid - TASK_FASTRUN_WAIT)

public plugin_precache()
{
	register_plugin("[Origin] Class: Zombie: Classic", ORIGIN_VERSION_STR_LONG, "Good_Hash")
	register_clcmd("drop", "cmd_fastrun")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")

	precache_sound(sound_ability_activate)
	new i
	for (i = 0; i < sizeof sound_ability_middle; i++)
	{
		precache_sound(sound_ability_middle[i])
	}

	new index
	g_ZombieClassID = origin_zclass_register(zombieclass1_name, zombieclass1_info, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity,
	zombieclass1_healing, zombieclass1_evolution, zombieclass1_death1, zombieclass1_death2, zombieclass1_hurt1, zombieclass1_hurt2, zombieclass1_infect)
	origin_zclass_register_kb(g_ZombieClassID, zombieclass1_knockback)
	for (index = 0; index < sizeof zombieclass1_models; index++)
		origin_zclass_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
		origin_zclass_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])

	g_Ability = zombie_register_ability(g_ZombieClassID, "Rage", 10)
}

public origin_fw_infect_post(id, attacker)
{
	if (g_ZombieClassID!=origin_zclass_get_current(id))
		return

	//if (origin_get_evolution(id)>1)
	origin_hud_show_ability(id, spr_skill)
	//if (attacker && origin_get_evolution(attacker)>1)
	//	origin_hud_show_ability(attacker, spr_skill)
}

public origin_fw_cure_post(id, attacker)
{
	if (g_ZombieClassID!=origin_zclass_get_current(id))
		return

	origin_hud_hide_ability(id)
}

// Cmd fast run
public cmd_fastrun(id)
{
	if ( !is_user_alive(id) || !origin_is_zombie(id) || origin_get_evolution(id)<2 ) return PLUGIN_CONTINUE

	new Float:health= entity_get_float(id, EV_FL_health)
	health -= 500.0

	if (g_ZombieClassID==origin_zclass_get_current(id) && health>0 && !flag_get(g_IsFastRun, id) && !flag_get(g_FastRun_Wait, id))
	{
		origin_set_knockback(id, 0.8);

		// set current speed
		g_user_speed[id] = entity_get_float(id, EV_FL_maxspeed)
		entity_set_float(id, EV_FL_gravity, 0.7)
		cs_set_player_maxspeed(id, 390.0)

		// set fastrun
		flag_set(g_IsFastRun, id)

		// set glow shell
		set_rendering(id, kRenderFxGlowShell, 255, 3, 0, kRenderNormal, 0)

		// set effect
		EffectFastrun(id, 105)

		origin_hud_show_ability(id, spr_skill, 2, 255)

		// set health
		entity_set_float(id, EV_FL_health, health)

		// task fastrun
		if (task_exists(id+TASK_FASTRUN)) remove_task(id+TASK_FASTRUN)

		new Float:time = 10.0;
		if (origin_get_evolution(id)<1)
			time /= 2;
		zombie_use_ability(id, g_Ability, floatround(time)+5, floatround(time))
		set_task(time, "RemoveFastRun", id+TASK_FASTRUN)

		// play sound start
		PlayEmitSound(id, sound_ability_activate)

		// task fastrun sound heartbeat
		if (task_exists(id+TASK_FASTRUN_HEARTBEAT)) remove_task(id+TASK_FASTRUN_HEARTBEAT)
		set_task(2.0, "FastRunHeartBeat", id+TASK_FASTRUN_HEARTBEAT, _, _, "b")

		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public RemoveFastRun(taskid)
{
	new id = ID_FASTRUN
	if ( !is_user_connected(id) )
		return

	flag_unset(g_IsFastRun, id)
	origin_set_knockback(id);
	set_rendering(id);
	entity_set_float(id, EV_FL_gravity, 0.8)
	cs_set_player_maxspeed(id, g_user_speed[id])
	origin_hud_show_ability(id, spr_skill,_,150,150)
	EffectFastrun(id)
	if (task_exists(taskid)) remove_task(taskid)

	flag_set(g_FastRun_Wait, id)
	if (task_exists(id+TASK_FASTRUN_WAIT)) remove_task(id+TASK_FASTRUN_WAIT)
	set_task(5.0, "RemoveWaitFastRun", id+TASK_FASTRUN_WAIT)
}

public RemoveWaitFastRun(taskid)
{
	new id = ID_FASTRUN_WAIT
	if ( !is_user_connected(id) )
		return

	flag_unset(g_FastRun_Wait, id)
	if (task_exists(taskid)) remove_task(taskid)
	origin_hud_show_ability(id, spr_skill )
}

public FastRunHeartBeat(taskid)
{
	new id = ID_FASTRUN_HEARTBEAT
	if ( !is_user_connected(id) )
		return

	if (flag_get(g_IsFastRun, id))
	{
		PlayEmitSound(id, sound_ability_middle[random_num(0, sizeof (sound_ability_middle)-1)])
	}
	else if (task_exists(taskid)) remove_task(taskid)
}

EffectFastrun(id, num = 90)
{
	message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
	write_byte(num)
	message_end()
}

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public event_round_start()
{
	for (new id=1; id<33; id++)
	{
		if (!is_user_connected(id)) continue;

		reset_value_player(id)
	}
}

public Death()
{
	new victim = read_data(2)

	origin_hud_hide_ability(victim)
	reset_value_player(victim)
}

reset_value_player(id)
{
	if (task_exists(id+TASK_FASTRUN)) remove_task(id+TASK_FASTRUN)
	if (task_exists(id+TASK_FASTRUN_HEARTBEAT)) remove_task(id+TASK_FASTRUN_HEARTBEAT)
	if (task_exists(id+TASK_FASTRUN_WAIT)) remove_task(id+TASK_FASTRUN_WAIT)

	if ( is_user_connected(id) )
	{
		if (g_user_speed[id] && entity_get_float(id, EV_FL_maxspeed) > g_user_speed[id] )
			cs_set_player_maxspeed(id, g_user_speed[id] )
		set_rendering(id)
	}


	flag_unset(g_IsFastRun, id)
	flag_unset(g_FastRun_Wait, id)
	g_user_speed[id] = 0.0
}
