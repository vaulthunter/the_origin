new const human_level[][64] = {
	"sprites/the_origin/level/human/1.spr",
	"sprites/the_origin/level/human/2.spr",
	"sprites/the_origin/level/human/3.spr",
	"sprites/the_origin/level/human/4.spr"
}
new const zombie_level[][64] = {
	"sprites/the_origin/level/zombie/0.spr",
	"sprites/the_origin/level/zombie/101.spr",
	"sprites/the_origin/level/zombie/102.spr",
	"sprites/the_origin/level/zombie/103.spr",
	"sprites/the_origin/level/zombie/104.spr",
	"sprites/the_origin/level/zombie/11.spr",
	"sprites/the_origin/level/zombie/12.spr",
	"sprites/the_origin/level/zombie/13.spr",
	"sprites/the_origin/level/zombie/14.spr",
	"sprites/the_origin/level/zombie/21.spr",
	"sprites/the_origin/level/zombie/22.spr",
	"sprites/the_origin/level/zombie/23.spr",
	"sprites/the_origin/level/zombie/24.spr",
	"sprites/the_origin/level/zombie/31.spr",
	"sprites/the_origin/level/zombie/32.spr",
	"sprites/the_origin/level/zombie/33.spr",
	"sprites/the_origin/level/zombie/34.spr",
	"sprites/the_origin/level/zombie/41.spr",
	"sprites/the_origin/level/zombie/42.spr",
	"sprites/the_origin/level/zombie/43.spr",
	"sprites/the_origin/level/zombie/44.spr",
	"sprites/the_origin/level/zombie/51.spr",
	"sprites/the_origin/level/zombie/52.spr",
	"sprites/the_origin/level/zombie/53.spr",
	"sprites/the_origin/level/zombie/54.spr",
	"sprites/the_origin/level/zombie/61.spr",
	"sprites/the_origin/level/zombie/62.spr",
	"sprites/the_origin/level/zombie/63.spr",
	"sprites/the_origin/level/zombie/64.spr",
	"sprites/the_origin/level/zombie/71.spr",
	"sprites/the_origin/level/zombie/72.spr",
	"sprites/the_origin/level/zombie/73.spr",
	"sprites/the_origin/level/zombie/74.spr",
	"sprites/the_origin/level/zombie/81.spr",
	"sprites/the_origin/level/zombie/82.spr",
	"sprites/the_origin/level/zombie/83.spr",
	"sprites/the_origin/level/zombie/84.spr",
	"sprites/the_origin/level/zombie/91.spr",
	"sprites/the_origin/level/zombie/92.spr",
	"sprites/the_origin/level/zombie/93.spr",
	"sprites/the_origin/level/zombie/94.spr"
}

new const hud_kill_dl[] = "sprites/the_origin/zbs_kill.spr"
new const hud_ability_fastrun[] = "sprites/the_origin/g_fastrun.spr"
new const hud_help[] = "sprites/the_origin/zb_hudhelp.spr"
//new const hud_rc_dl[] = "sprites/the_origin/human_win.spr"
//new const hud_rf_dl[] = "sprites/the_origin/zombie_win.spr"


// hud spr name
new const hud_kill[] = "zbs_kill"
//new const hud_round_clear[] = "zbs_round_clear"
//new const hud_round_fail[] = "zbs_round_fail"

new g_msgScenario, g_msgStatusIcon

new Float:g_level_delay[33], g_level_effect[33]

// Config Value
const MAX_LEVEL_HUMAN = 10
const MAX_LEVEL_ZOMBIE = 3
const MAX_EVOLUTION = 30

// Task offsets
enum (+= 100)
{
    TASK_HIDE_HUD,
    TASK_HIDE_HUD_KILL
}

#define ID_HIDE_HUD_KILL (taskid - TASK_HIDE_HUD_KILL)

show_player_level(id)
{
	if (!is_user_alive(id)) return;

	if ((g_level_delay[id]) > get_gametime()) 
	{
		return
	}
	g_level_delay[id] = get_gametime() + 0.1
	

	g_level_effect[id] += 1
	if (g_level_effect[id]>8) g_level_effect[id] = 1
	
	new level, sprname[64]
	if (origin_is_zombie(id))
	{
		new MaxEvo = MAX_EVOLUTION/MAX_LEVEL_ZOMBIE
		level = min(origin_get_evolution(id), MaxEvo)
		if (level) format(sprname, charsmax(sprname), "zombie_level_%i%i", level, g_level_effect[id])
		else format(sprname, charsmax(sprname), "zombie_level_%i", level)
	}
	else
	{
		level = min(origin_get_apower(id), MAX_LEVEL_HUMAN)
		format(sprname, charsmax(sprname), "human_level_%i", level)
	}
	
	message_begin(MSG_ONE, g_msgScenario, _, id)
	write_byte(1)//  Active
	write_string(sprname)//  Sprite
	write_byte(1000)//  Alpha
	write_short(3)//  FlashRate
	write_short(0)//  Unknown
	message_end()
}

stock show_hud(player, const sprname[], show_type=1, red=0,green=0, blue=0)
{    
	new color[3]
	color[0]=red;color[1]=green;color[2]=blue;
	hide_hud(player)
	sendmsg_StatusIcon(player, sprname, show_type, color)
}

hide_hud(player=0)
{    
	hide_hud_kill(player)
	//sendmsg_StatusIcon(player, hud_round_clear, 0)
	//sendmsg_StatusIcon(player, hud_round_fail, 0)
}

hide_hud_kill(player=0)
{    
	sendmsg_StatusIcon(player, hud_kill, 0)
}

sendmsg_StatusIcon(player, const sprname[], run, color[3]={0,0,0})
{    
	new dest
	if (player && is_user_connected(player)) dest = MSG_ONE
	else dest = MSG_ALL
    
	message_begin(dest, g_msgStatusIcon, {0,0,0}, player)
	write_byte(run)     // status (0=hide, 1=show, 2=flash)
	write_string(sprname)     // sprite name
	if (color[0] || color[1] || color[2])
	{
		write_byte(color[0])     // red
		write_byte(color[1])     // green
		write_byte(color[2])     // blue
	}
	message_end();
}

public task_hide_hud_kill(taskid)
{
	new id = ID_HIDE_HUD_KILL
	hide_hud_kill(id)
}

public task_hide_hud()
{
	hide_hud()
}
