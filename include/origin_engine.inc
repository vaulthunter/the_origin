#if defined _origin_engine_included
  #endinput
#endif
#define _origin_engine_included

#include <origin_const>

#pragma library origin_engine

/**
 * Returns whether a player is a zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native origin_is_zombie(id)


/**
 * Returns whether a player is a host zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native origin_is_zhost(id)

/**
 * Returns player's evolution level.
 *
 * @param id		Player index.
 * @return			Num.
 */
native origin_get_evolution(id)

/**
 * Returns player's attack power.
 *
 * @param id		Player index.
 * @return			Num.
 */
native origin_get_apower(id)

/**
 * Turns a player into a zombie.
 *
 * @param id		Player index to be infected.
 * @param attacker	Player who triggered the infection. (optional)
 * @return			True on success, false otherwise.
 */
native origin_infect(id, attacker = 0, host = 0)

/**
 * Returns whether a player is the last zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native origin_is_last_zombie(id)

/**
 * Returns whether a player is the last human.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native origin_is_last_human(id)

/**
 * Returns whether a player is the 1st zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native origin_is_first_zombie(id)

/**
 * Turns a player into a human.
 *
 * @param id		Player index to be cured.
 * @param attacker	Player who triggered the cure. (optional)
 * @return			True on success, false otherwise.
 */
native origin_cure(id, attacker = 0)

/**
 * Switch knockback for zombie player.
 *
 * @param id        Player index to be cured.
 * @param volume    1/0
 * @return          True on success, false otherwise.
 */
native origin_set_knockback(id, Float:knockback = 1.0)

/**
 * Called when a player gets infected.
 *
 * @param id		Player index who was infected.
 * @param attacker	Player who triggered the infection.
 *					(0 if not available, id = attacker if he infected himself)
 */
forward origin_fw_infect(id, attacker)
forward origin_fw_infect_post(id, attacker)

/**
 * Called when a player turns back to human.
 *
 * @param id		Player index who was cured.
 * @param attacker	Player who triggered the cure.
 *					(0 if not available, id = attacker if he cured himself)
 */
forward origin_fw_cure(id, attacker)
forward origin_fw_cure_post(id, attacker)

/**
 * Returns number of alive zombies.
 *
 * @return		Zombie count.
 */
native origin_get_zombie_count()

/**
 * Returns number of alive humans.
 *
 * @return		Human count.
 */
native origin_get_human_count()

/**
 * Sets whether the player will be respawned as zombie or human.
 *
 * @param id			Player index.
 * @param zombie		True to respawn as zombie, false otherwise.
 */
native origin_respawn_as_zombie(id, zombie = true)

/**
 * Called before the deathmatch module respawns a player.
 * Returning PLUGIN_HANDLED will block respawn.
 *
 * @param id		Player index.
 */
forward origin_fw_dm_respawn_pre(id)