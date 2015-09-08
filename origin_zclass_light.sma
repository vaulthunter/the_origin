/*================================================================================

	-----------------------------------
	-*- [Origin] Class: Zombie: Light -*-
	-----------------------------------

================================================================================*/

#include <amxmodx>
#include <engine>
#include <origin_class_zombie>
#include <fakemeta>
#include <origin_hud>
#include <bd_advanced>
#include <cs_maxspeed_api>

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

// Light Zombie Attributes
new const zombieclass1_name[] = "Light zombie"
new const zombieclass1_info[] = "Press G to vanish"
new const zombieclass1_models[][] = { "speed_zombi_origin", "speed_zombi_host" }
new const zombieclass1_clawmodels[][] = { "models/origin/v_light_normal.mdl" }
new const zhands_ability[] = { "models/origin/v_light_invisible.mdl" }
new const zombieclass1_healing[] = "the_origin/zombi_heal_female.wav"
new const zombieclass1_evolution[] = "the_origin/zombi_evolution_female.wav"
new const zombieclass1_death1[] = "the_origin/zombi_death_female_1.wav"
new const zombieclass1_death2[] = "the_origin/zombi_death_female_2.wav"
new const zombieclass1_hurt1[] = "the_origin/zombi_hurt_female_1.wav"
new const zombieclass1_hurt2[] = "the_origin/zombi_hurt_female_2.wav"
new const zombieclass1_infect[] = "the_origin/zombi_female_laugh.wav"
const zombieclass1_health = 800
const Float:zombieclass1_speed = 1.24
const Float:zombieclass1_gravity = 0.64//49
const Float:zombieclass1_knockback = 2.5//1.5

new g_ZombieClassID, g_IsFastRun, g_FastRun_Wait
new Float:g_user_speed[33]

new g_Ability, spr_skill[] = "g_invisible"
new const sound_ability_activate[] = "the_origin/zombi_pressure_female.wav"

#define TASK_FASTRUN		241312
#define ID_FASTRUN 		(taskid - TASK_FASTRUN)

#define TASK_FASTRUN_WAIT	241512
#define ID_FASTRUN_WAIT (taskid - TASK_FASTRUN_WAIT)

new const g_VGhost [] = "models/origin/v_zombibomb_speed_zombi.mdl"
new const g_VGhostInvis [] = "models/origin/v_zombibomb_speed_zombi_invis.mdl"

public plugin_precache()
{
	register_plugin("[Origin] Class: Zombie: Light", ORIGIN_VERSION_STR_LONG, "Good_Hash")
	register_clcmd("drop", "cmd_ability")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event ( "CurWeapon", "EV_CurWeapon", "be", "1=1" )
	register_event("DeathMsg", "Death", "a")
	register_forward(FM_CmdStart, "fw_CmdStart")

	precache_sound(sound_ability_activate)
	precache_model(zhands_ability)
	precache_model(zombieclass1_clawmodels[0])

	new index
	g_ZombieClassID = origin_zclass_register(zombieclass1_name, zombieclass1_info, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity,
	zombieclass1_healing, zombieclass1_evolution, zombieclass1_death1, zombieclass1_death2, zombieclass1_hurt1, zombieclass1_hurt2, zombieclass1_infect)
	origin_zclass_register_kb(g_ZombieClassID, zombieclass1_knockback)
	for (index = 0; index < sizeof zombieclass1_models; index++)
		origin_zclass_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
	{
		origin_zclass_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])
	}

	precache_model(g_VGhost)
	precache_model(g_VGhostInvis)

	g_Ability = zombie_register_ability(g_ZombieClassID, "Invisiblity", 10)
}

public EV_CurWeapon ( id )
{
	if ( !is_user_alive ( id ) || !origin_is_zombie ( id ) )
		return PLUGIN_CONTINUE

	if (g_ZombieClassID!=origin_zclass_get_current(id))
		return PLUGIN_CONTINUE

	set_wpnmodel(id)

	return PLUGIN_HANDLED
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

// Cmd ability
public cmd_ability(id)
{
	if ( !is_user_alive(id) || !origin_is_zombie(id) || origin_get_evolution(id)<2 ) return PLUGIN_CONTINUE

	new Float:health= entity_get_float(id, EV_FL_health)
	health -= 0.0

	if (g_ZombieClassID==origin_zclass_get_current(id) && health>0 && !flag_get(g_IsFastRun, id) && !flag_get(g_FastRun_Wait, id))
	{
		// set current speed
		g_user_speed[id] = entity_get_float(id, EV_FL_maxspeed)
		entity_set_float(id, EV_FL_gravity, 0.8)
		cs_set_player_maxspeed(id, g_user_speed[id]-60.0) // -80.0

		// set fastrun
		flag_set(g_IsFastRun, id)

		origin_hud_show_ability(id, spr_skill, 2, 255)

		// set model
		set_wpnmodel(id)

		// set health
		entity_set_float(id, EV_FL_health, health)

		// task fastrun
		if (task_exists(id+TASK_FASTRUN)) remove_task(id+TASK_FASTRUN)
		new Float:time = 35.0;
		if (origin_get_evolution(id)<1)
			time /= 20;
		zombie_use_ability(id, g_Ability, floatround(time)+15, floatround(time))
		set_task(time, "RemoveFastRun", id+TASK_FASTRUN)

		// play sound start
		PlayEmitSound(id, sound_ability_activate)

		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || !origin_is_zombie(id)) return;

	if (g_ZombieClassID==origin_zclass_get_current(id))
	{
		// check invisible
		if (flag_get(g_IsFastRun, id) && !flag_get(g_FastRun_Wait, id))
		{
			// set invisible
			new Float:velocity[3], velo, alpha
			pev(id, pev_velocity, velocity)
			velo = sqroot(floatround(velocity[0] * velocity[0] + velocity[1] * velocity[1] + velocity[2] * velocity[2]))/10
			alpha = floatround(float(velo)*4.0)
			set_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, alpha)
		}
	}

	return;
}

set_wpnmodel(id)
{
	if (!is_user_alive(id)) return;

	// set model wpn invisible
	new wpn = get_user_weapon(id)
	if (wpn == CSW_KNIFE)
	{
		if (flag_get(g_IsFastRun, id)) set_pev(id, pev_viewmodel2, zhands_ability)
		else set_pev(id, pev_viewmodel2, zombieclass1_clawmodels[0])
	}
	if (wpn == CSW_SMOKEGRENADE)
	{
		if (flag_get(g_IsFastRun, id)) set_pev(id, pev_viewmodel2, g_VGhostInvis)
		else set_pev(id, pev_viewmodel2, g_VGhost)
	}
}

public RemoveFastRun(taskid)
{
	new id = ID_FASTRUN
	if ( !is_user_connected(id) )
		return

	flag_unset(g_IsFastRun, id)
	set_wpnmodel(id)
	cs_set_player_maxspeed(id, g_user_speed[id])
	set_rendering(id)
	origin_hud_show_ability(id, spr_skill,_,150,150)
	entity_set_float(id, EV_FL_gravity, zombieclass1_gravity)

	if (task_exists(taskid)) remove_task(taskid)

	flag_set(g_FastRun_Wait, id)
	if (task_exists(id+TASK_FASTRUN_WAIT)) remove_task(id+TASK_FASTRUN_WAIT)
	set_task(15.0, "RemoveWaitFastRun", id+TASK_FASTRUN_WAIT)
}

public RemoveWaitFastRun(taskid)
{
	new id = ID_FASTRUN_WAIT
	if ( !is_user_connected(id) )
		return

	flag_unset(g_FastRun_Wait, id)
	if (task_exists(taskid)) remove_task(taskid)
	origin_hud_show_ability(id, spr_skill)
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
