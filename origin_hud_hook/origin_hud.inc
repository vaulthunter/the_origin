#if defined _origin_hud_included
  #endinput
#endif
#define _origin_hud_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib origin_hud
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib origin_hud
	#endif
#else
	#pragma library origin_hud
#endif

/**
 * Sets a custom hud for a player.
 *
 *
 * @param id					Player index.
 * @param sprite_name			From hud.txt
 */
native origin_hud_show_ability(id, const sprite[], show_type=1, red=0, green=0, blue=0)

/**
 * Hides a custom sprite for a player.
 *
 * @param id					Player index.
 */
native origin_hud_hide_ability(id)
