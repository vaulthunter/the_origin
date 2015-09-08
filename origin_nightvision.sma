#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <amx_settings_api>
#include <origin_class_zombie>

// Lighting
new cvar_lighting, cvar_vlighting, cvar_triggered_lights

// Night Vision
new g_msgScreenFade

new g_item[33], g_active[33]

new cvar_vcolor_human_r, cvar_vcolor_human_g, cvar_vcolor_human_b
new cvar_vcolor_zombie_r, cvar_vcolor_zombie_g, cvar_vcolor_zombie_b

public plugin_init() 
{
    register_plugin("[Origin] New Lighting System", "1.0", "ADN")
    
    register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
    register_clcmd("nightvision", "vision_switch")
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)

    cvar_lighting = register_cvar("zp_lighting", "g")
    cvar_vlighting = register_cvar("zp_lighting_vision", "m")
    cvar_triggered_lights = register_cvar("zp_triggered_lights", "1")
    
    // Night Vision Colors
    cvar_vcolor_human_r = register_cvar("zp_nvision_human_color_R", "0")
    cvar_vcolor_human_g = register_cvar("zp_nvision_human_color_G", "0")
    cvar_vcolor_human_b = register_cvar("zp_nvision_human_color_B", "255")
    
    cvar_vcolor_zombie_r = register_cvar("zp_nvision_zombie_color_R", "155")
    cvar_vcolor_zombie_g = register_cvar("zp_nvision_zombie_color_G", "0")
    cvar_vcolor_zombie_b = register_cvar("zp_nvision_zombie_color_B", "0")
    
    register_message(g_msgScreenFade, "message_screenfade")
    g_msgScreenFade = get_user_msgid("ScreenFade")
    
}

public plugin_cfg()
{
    server_cmd("mp_playerid 1")
    
    set_task(5.0, "lighting_task", _, _, _, "b")
    
    // Call roundstart manually
    event_round_start()
    
}

// EVENTS ==========================================================================================

public event_round_start()
{
    // Remove lights?
    if (!get_pcvar_num(cvar_triggered_lights))
        set_task(0.1, "remove_lights")

}

public client_putinserver(id)
{
    set_task(3.0, "set_vision_spec", id)
}

public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
    set_vision_spec(victim)
}

public origin_fw_dm_respawn_pre(id) // must be POST
{    
    g_item[id] = false
    
    set_task(0.5, "set_vision_off", id)
}

public origin_fw_cure_post(id, attacker)
{
    /*if(zp_class_survivor_get(id) || zp_class_sniper_get(id))
    {
        g_item[id] = true
        set_task(0.5, "set_vision_color", id)
    }
    else
    {*/
    g_item[id] = false
    set_task(0.5, "set_vision_off", id)
    //}
}
    
public origin_fw_infect_post(id, attacker)
{
    g_item[id] = true
    set_task(0.5, "set_vision_color", id)
}    
    
public client_disconnect(id)
{
    g_item[id] = false
    g_active[id] = false
}
// LIGHTING TASK ===================================================================================

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

public lighting_task()
{

    new lighting[2]
    get_pcvar_string(cvar_lighting, lighting, charsmax(lighting))
    
    // Lighting disabled? ["0"]
    if (lighting[0] == '0')
        return;

    
    new Players[32], Num, id
    get_players(Players, Num)
    for(new i; i <= Num; i++)
    {
        id = Players[i]
        
        if(!g_active[id])
        {
            set_player_light(id, lighting) 
        }
        
    }
    
    
}

// SET NIGHT VISION ================================================================================

public vision_switch(id)
{
    if(g_item[id] || !is_user_alive(id))
    {
    
        if(!g_active[id])
        {
            set_vision_color(id)
        }
        
        else
        {
            set_vision_off(id)
        }
    }
}

public set_vision_spec(id)
{
    if(!is_user_alive(id))
    {
    
        set_vision_color(id)
    }
}

public set_vision_color(id)
{
    if(origin_is_zombie(id))
    {
        set_vision_on(id, get_pcvar_num(cvar_vcolor_zombie_r), get_pcvar_num(cvar_vcolor_zombie_g), get_pcvar_num(cvar_vcolor_zombie_b))
    }
    else
    {
        set_vision_on(id, get_pcvar_num(cvar_vcolor_human_r), get_pcvar_num(cvar_vcolor_human_g), get_pcvar_num(cvar_vcolor_human_b))
    }
}

// EXECUTE TASK ====================================================================================

public set_vision_on(id, R, G, B)
{
    if(is_user_connected(id))
    {
    
        new vlighting[2]
        get_pcvar_string(cvar_vlighting, vlighting, charsmax(vlighting))
        
        message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
        write_short((1<<12))
        write_short(0)
        write_short(0x0004)
        write_byte(R)
        write_byte(G)
        write_byte(B)
        write_byte(50)
        message_end()
        
        set_player_light(id, vlighting)
        g_active[id] = true
        
    }
    
}
    
public set_vision_off(id)
{
    if(is_user_connected(id))
    {
    
        new lighting[2]
        get_pcvar_string(cvar_lighting, lighting, charsmax(lighting))
        
        message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
        write_short((1<<12))
        write_short(0)
        write_short(0x0004)
        write_byte(0)
        write_byte(0)
        write_byte(0)
        write_byte(0)
        message_end()
        
        set_player_light(id, lighting)
        
        g_active[id] = false
        
        
    }
    
}    
    
public set_player_light(id, const LightStyle[])
{
    if(is_user_connected(id))
    {

        message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id)
        write_byte(0)
        write_string(LightStyle)
        message_end()
    }
    
}  