#if defined _origin_gmodes_included
  #endinput
#endif
#define _origin_gmodes_included

#include <origin_engine>
#include <origin_gamemodes_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib origin_gamemodes
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib origin_gamemodes
	#endif
#else
	#pragma library origin_gamemodes
#endif


/**
 * Registers a new game mode.
 *
 * @param name		Game mode name.
 * @return			An internal game mode ID, or ORIGIN_INVALID_GAME_MODE on failure.
 */
native origin_gmodes_register(const name[])

/**
 * Sets a default game mode (to start if no other game mode can been started).
 *
 * @param game_mode_id		A valid game mode ID.
 * @return					True on success, false otherwise.
 */
native origin_gmodes_set_default(game_mode_id)

/**
 * Returns default game mode.
 *
 * @return					A valid game mode ID.
 */
native origin_gmodes_get_default()

/**
 * Returns game mode that was chosen for the current round.
 *
 * @return			An internal game mode ID, or ORIGIN_NO_GAME_MODE.
 */
native origin_gmodes_get_chosen()

/**
 * Returns game mode that is currently in progress.
 *
 * @return			An internal game mode ID, or ORIGIN_NO_GAME_MODE.
 */
native origin_gmodes_get_current()

/**
 * Returns a game mode's ID.
 *
 * @param name		Game mode name to look for.
 * @return			Internal game mode ID, or ORIGIN_INVALID_GAME_MODE if not found.
 */
native origin_gmodes_get_id(const name[])

/**
 * Returns a game mode's name.
 *
 * @param game_mode_id	A valid game mode ID.
 * @param name			The buffer to store the string in.
 * @param len			Character size of the output buffer.
 * @return				True on success, false otherwise.
 */
native origin_gmodes_get_name(game_mode_id, name[], len)

/**
 * Forces a game mode to start.
 *
 * @param game_mode_id		A valid game mode ID.
 * @param target_player		Player ID to be passed to game mode (optional).
 * @return					True on success, false if game mode can't start.
 */
native origin_gmodes_start(game_mode_id, target_player = RANDOM_TARGET_PLAYER)

/**
 * Returns number of registered game modes.
 *
 * @return			Game mode count.
 */
native origin_gmodes_get_count()

/**
 * Sets whether zombies can infect humans for the current game mode.
 *
 * @param allow			True to allow, false otherwise.
 */
native origin_gmodes_set_allow_infect(allow = true)

/**
 * Returns whether zombies are allowed to infect humans for the current game mode.
 *
 * @return			True if allowed, false otherwise.
 */
native origin_gmodes_get_allow_infect()

/**
 * Called when ORIGIN tries to choose a game mode for the current
 * round. Returning PLUGIN_HANDLED here will tell the game modes
 * manager that your mode can't be chosen (useful to set custom
 * conditions, like a min amount of players, etc.)
 *
 * @param game_mode_id		Internal game mode ID.
 * @param skipchecks		True when mode is being started by an admin.
 */
forward origin_fw_gmodes_choose_pre(game_mode_id, skipchecks)

/**
 * Called when a game mode is chosen for the current round.
 *
 * @param game_mode_id		Internal ID for the game mode that was chosen.
 * @param target_player		Player ID passed to game mode (can be RANDOM_TARGET_PLAYER).
 */
forward origin_fw_gmodes_choose_post(game_mode_id, target_player)

/**
 * Called when a game mode starts.
 *
 * @param game_mode_id		Internal ID for the game mode that was started.
 */
forward origin_fw_gmodes_start(game_mode_id)

/**
 * Called when a game mode ends.
 *
 * Note: this can pass ORIGIN_NO_GAME_MODE (if no game mode was in progress).
 *
 * @param game_mode_id		Internal ID for the game mode that ended.
 */
forward origin_fw_gmodes_end(game_mode_id)
