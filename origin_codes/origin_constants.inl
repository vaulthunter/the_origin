new cvar_lighting, cvar_triggered_lights
new cvar_zombie_fov
new cvar_zombie_silent
new cvar_block_suicide
new cvar_disable_minmodels
new cvar_infect_show_notice
new cvar_human_armor_protect
new cvar_human_armor_default, cvar_human_health_default
new cvar_nvision_radius
new cvar_nvision_zombie, cvar_nvision_zombie_color_R, cvar_nvision_zombie_color_G, cvar_nvision_zombie_color_B
new cvar_zombie_drop_weapons, cvar_zombie_strip_weapons, cvar_zombie_strip_grenades, cvar_zombie_strip_armor
new cvar_zombie_block_pickup
new cvar_remove_dropped_weapons
new cvar_respawn_delay, cvar_respawn_zombies, cvar_respawn_on_suicide
new cvar_gamemode_delay, cvar_round_start_show_hud
new cvar_winner_show_hud, cvar_winner_sounds
new cvar_knockback_damage, cvar_knockback_power, cvar_knockback_obey_class
new cvar_knockback_zvel, cvar_knockback_ducking, cvar_knockback_distance
new cvar_block_pushables
new cvar_glowshell_time
new cvar_painshockfree_zombie, cvar_painshockfree_human

// Settings file
new const ORIGIN_SETTINGS_FILE[] = "origin_zombie_mod.ini"


// Player's data
new origin_respawnwait[33], g_Evolution_progress[33], g_Evolution[33], g_SurvivorLevel, g_restore_health[33], Float:cl_pushangle[33],
Float:g_Knockback[33]

#define CS_DEFAULT_FOV 				90
#define CLASSNAME_MAX_LENGTH 			32
#define MAXPLAYERS 				32
#define MENUCODE_TEAMSELECT 			1
#define SKYNAME_MAX_LENGTH 			32
#define SOUND_MAX_LENGTH 			64
#define RESTORE_HEALTH_TIME			3
#define DMG_FALL (1<<5)

const STATIONARY_USING = 2


// Config Value
const MAX_LEVEL_HUMAN = 10
const MAX_LEVEL_ZOMBIE = 3
const MAX_EVOLUTION = 30
const Float:HUMAN_GRAVITY = 1.0

new g_MsgSetFOV
new g_MsgDeathMsg, g_MsgScoreAttrib, g_MsgScoreInfo, g_msgScreenFade, g_msgDamage
new g_NightVisionActive
new g_MsgNVGToggle
new g_ScoreHumans, g_ScoreZombies

new g_sky_custom_enable = 1
new Array:g_sky_names
new g_SkyArrayIndex

new const sky_names[][] = { "space" }
new const objective_ents[][] = { "func_bomb_target" , "info_bomb_target" , "info_vip_start" , "func_vip_safetyzone" , "func_escapezone" , "hostage_entity" , "monster_scientist" , "func_hostage_rescue" , "info_hostage_rescue" }
new const health_regen[] = { 0, 200, 500 }
new const health_evolution[] = { 0, 7000, 14000 }
new const armor_evolution[] = { 0, 500, 999 }

// Custom sounds
new Array:g_ambience_sounds_handle
new Array:g_ambience_durations_handle
new Array:g_sound_win_zombies
new Array:g_sound_human_infect
new Array:g_sound_win_humans
new Array:g_sound_start_warning
new Array:g_sound_zombie_respawn
new Array:g_sound_countdown
new restore_health_idspr, id_sprites_levelup, g_sprite_zombie_respawn

// Default sounds
new const sound_selecting_round[] = { "the_origin/zombie_start.wav" }
new const sound_win_zombies[][] = { "the_origin/win_zombie.wav" }
new const sound_win_humans[][] = { "the_origin/win_human.wav" }
new const sound_start_warning[][] = {"the_origin/count/20secremain.wav"}
new const sound_zombie_respawn[][] = {"the_origin/zombi_coming_1.mp3"}
new const restore_health_spr[] = "sprites/the_origin/zb_restore_health.spr"
new const sprites_effects_levelup[] = "sprites/the_origin/levelup.spr"
new const sprite_zombie_respawn[] = "sprites/the_origin/zb_respawn.spr"
new const sound_countdown[10][] =
{
	"the_origin/count/1.wav",
	"the_origin/count/2.wav",
	"the_origin/count/3.wav",
	"the_origin/count/4.wav",
	"the_origin/count/5.wav",
	"the_origin/count/6.wav",
	"the_origin/count/7.wav",
	"the_origin/count/8.wav",
	"the_origin/count/9.wav",
	"the_origin/count/10.wav"
}
new const sound_human_infect[][] = { "the_origin/human_death_01.wav", "the_origin/human_death_01.wav" }

new Array:g_objective_ents
new g_fwSpawn
new g_fwPrecacheSound

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))


// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_RESPAWN_PRE = 0,
	FW_USER_INFECT_PRE,
	FW_USER_INFECT,
	FW_USER_INFECT_POST,
	FW_USER_CURE_PRE,
	FW_USER_CURE,
	FW_USER_CURE_POST,
	FW_USER_LAST_ZOMBIE,
	FW_USER_LAST_HUMAN,
	FW_USER_SPAWN_POST,
	FW_GAME_MODE_CHOOSE_PRE,
	FW_GAME_MODE_CHOOSE_POST,
	FW_GAME_MODE_START,
	FW_GAME_MODE_END,
}
new g_MaxPlayers
new g_HudSync
new g_IsZombie
new g_IsZombieHost
new g_IsFirstZombie
new g_IsLastZombie
new g_LastZombieForwardCalled
new g_IsLastHuman
new g_LastHumanForwardCalled
new g_RespawnAsZombie
new g_ForwardResult
new g_Forwards[TOTAL_FORWARDS]


// Game Modes data
new Array:g_GameModeName
new Array:g_GameModeFileName
new g_GameModeCount
new g_DefaultGameMode = 0 // first game mode is used as default if none specified
new g_ChosenGameMode = ORIGIN_NO_GAME_MODE
new g_CurrentGameMode = ORIGIN_NO_GAME_MODE
new g_AllowInfection


// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205
// CS Player PData Offsets (win32)
const OFFSET_PAINSHOCK = 108 // ConnorMcLeod

const IMPULSE_FLASHLIGHT = 100

// CS Player PData Offsets (win32)
const PDATA_SAFE = 2

// HACK: pev_ field used to store additional ammo on weapons
const PEV_ADDITIONAL_AMMO = pev_iuser1
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_CSDEATHS = 444

const PEV_SPEC_TARGET = pev_iuser2

// Some constants
const DMG_HEGRENADE = (1<<24)


// HUD messages
const Float:HUD_EVENT_X = -1.0
const Float:HUD_EVENT_Y = 0.12


new g_GameModeStarted

#define PRIMARY_ONLY 1
#define SECONDARY_ONLY 2
#define PRIMARY_AND_SECONDARY 3
#define GRENADES_ONLY 4

#define TASK_NIGHTVISION			100
#define ID_NIGHTVISION				(taskid - TASK_NIGHTVISION)

#define TASK_RESPAWN				200
#define ID_RESPAWN				(taskid - TASK_RESPAWN)

#define TASK_GAMEMODE				300
#define TASK_GAMEMODE_END			400
#define TASK_GLOWSHELL				500
#define ID_GLOWSHELL (taskid - TASK_GLOWSHELL)
#define TASK_AMBIENCESOUNDS 			600

#define TASK_COUNTER				6003


new const g_sound_armor_hit[] = "player/bhit_helmet-1.wav"

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const GRENADES_WEAPONS_BIT_SUM = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)
const NOCLIP_WEAPONS_BIT_SUM  = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

// Ammo IDs for weapons
new const AMMOID[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10,
			1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

// Knockback Power values for weapons
// Note: negative values will disable knockback power for the weapon
new Float:kb_weapon_power[] =
{
	-1.0,	// ---
	2.4,	// P228
	-1.0,	// ---
	6.5,	// SCOUT
	-1.0,	// ---
	8.0,	// XM1014
	-1.0,	// ---
	2.3,	// MAC10
	5.0,	// AUG
	-1.0,	// ---
	2.4,	// ELITE
	2.0,	// FIVESEVEN
	2.4,	// UMP45
	5.3,	// SG550
	5.5,	// GALIL
	5.5,	// FAMAS
	2.2,	// USP
	2.0,	// GLOCK18
	10.0,	// AWP
	2.5,	// MP5NAVY
	5.2,	// M249
	8.0,	// M3
	5.0,	// M4A1
	2.4,	// TMP
	6.5,	// G3SG1
	-1.0,	// ---
	5.3,	// DEAGLE
	5.0,	// SG552
	6.0,	// AK47
	-1.0,	// ---
	2.0		// P90
}

// Weapon entity names (uppercase)
new const WEAPONENTNAMES_UP[][] = { "", "WEAPON_P228", "", "WEAPON_SCOUT", "WEAPON_HEGRENADE", "WEAPON_XM1014", "WEAPON_C4", "WEAPON_MAC10",
			"WEAPON_AUG", "WEAPON_SMOKEGRENADE", "WEAPON_ELITE", "WEAPON_FIVESEVEN", "WEAPON_UMP45", "WEAPON_SG550",
			"WEAPON_GALIL", "WEAPON_FAMAS", "WEAPON_USP", "WEAPON_GLOCK18", "WEAPON_AWP", "WEAPON_MP5NAVY", "WEAPON_M249",
			"WEAPON_M3", "WEAPON_M4A1", "WEAPON_TMP", "WEAPON_G3SG1", "WEAPON_FLASHBANG", "WEAPON_DEAGLE", "WEAPON_SG552",
			"WEAPON_AK47", "WEAPON_KNIFE", "WEAPON_P90" }


// X Damage value
new const XDAMAGE[11][] = {
	"1.0",
	"1.1",
	"1.2",
	"1.3",
	"1.4",
	"1.5",
	"1.6",
	"1.7",
	"1.8",
	"1.9",
	"2.0"
}
// X Recoil value
new const XRECOIL[11][] = {
	"1.0",
	"0.9",
	"0.8",
	"0.7",
	"0.6",
	"0.5",
	"0.4",
	"0.3",
	"0.2",
	"0.1",
	"0.0"
}
