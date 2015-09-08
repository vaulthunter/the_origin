#if defined _origin_zclass_included
  #endinput
#endif
#define _origin_zclass_included

#include <origin_engine>
#include <origin_class_zombie_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib origin_class_zombie
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib origin_class_zombie
	#endif
#else
	#pragma library origin_class_zombie
#endif

/**
 * Returns a player's current zombie class ID.
 *
 * @param id		Player index.
 * @return			Internal zombie class ID, or ORIGIN_INVALID_ZOMBIE_CLASS if not yet chosen.
 */
native origin_zclass_get_current(id)

/**
 * SET MODEL OF HOST ZOMBIE
 *
 * @param id		Player index.
 * @return			Internal zombie class ID, or ORIGIN_INVALID_ZOMBIE_CLASS if not yet chosen.
 */
native origin_set_zhost_model(id)

/**
 * Returns a player's next zombie class ID (for the next infection).
 *
 * @param id		Player index.
 * @return			Internal zombie class ID, or ORIGIN_INVALID_ZOMBIE_CLASS if not yet chosen.
 */
native origin_zclass_get_next(id)

/**
 * Sets a player's next zombie class ID (for the next infection).
 *
 * @param id		Player index.
 * @param classid	A valid zombie class ID.
 * @return			True on success, false otherwise.
 */
native origin_zclass_set_next(id, classid)

/**
 * Sets a player's zombie maxhealth.
 *
 * @param id		Player index.
 * @param value	A valid health value.
 * @return			True on success, false otherwise.
 */
native origin_zclass_set_max_health(id, value)

/**
 * Returns the default maximum health for a specific zombie class.
 *
 * Note: does not take into account any kind of HP multipliers.
 *
 * @param id		Player index.
 * @param classid	A valid zombie class ID.
 * @return			Maximum amount of health points, -1 on error.
 */
native origin_zclass_get_max_health(id, classid)

/**
 * Returns the default maximum health for a specific player.
 *
 * Note: takes into account any kind of HP multipliers.
 *
 * @param id        Player index.
 * @return          Num.
 */
native origin_get_maxhealth(id)

/**
 * Registers a custom class which will be added to the zombie classes menu of ZP.
 *
 * Note: The returned zombie class ID can be later used to identify
 * the class when calling the origin_get_user_zombie_class() natives.
 *
 * @param name			Caption to display on the menu.
 * @param description	Brief description of the class.
 * @param health		Class health.
 * @param speed			Class maxspeed (can be a multiplier).
 * @param gravity		Class gravity multiplier.
 * @return				An internal zombie class ID, or ORIGIN_INVALID_ZOMBIE_CLASS on failure.
 */
native origin_zclass_register(const name[], const description[], health, Float:speed, Float:gravity, const sound_heal[], const sound_evolution[], const sound_death1[], const sound_death2[], const sound_heart1[], const sound_heart2[], const sound_infected[])

/**
 * Registers a custom player model for a given zombie class.
 *
 * @param classid		A valid zombie class ID.
 * @param model			Player model's short name.
 * @return				True on success, false otherwise.
 */
native origin_zclass_register_model(classid, const model[])

/**
 * Registers a custom claw model for a given zombie class.
 *
 * @param classid		A valid zombie class ID.
 * @param clawmodel		Claw model filename.
 * @return				True on success, false otherwise.
 */
native origin_zclass_register_claw(classid, const clawmodel[])

/**
 * Registers a zombie class' knockback multiplier.
 *
 * @param classid		A valid zombie class ID.
 * @param knockback		Knockback multiplier.
 * @return				True on success, false otherwise.
 */
native origin_zclass_register_kb(classid, Float:knockback)

/**
 * Returns a zombie class' ID.
 *
 * @param name		Class name to look for.
 * @return			Internal zombie class ID, or ORIGIN_INVALID_ZOMBIE_CLASS if not found.
 */
native origin_zclass_get_id(const real_name[])

/**
 * Returns a zombie class' name.
 *
 * @param classid	A valid zombie class ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native origin_zclass_get_name(classid, name[], len)

/**
 * Returns a zombie class' sounds by name!
 *
 * @param classid	A valid zombie class ID.
 * @param sound_name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native origin_zclass_get_sound(classid, key, sound_name[], len)


/**
 * Returns a zombie class' real name (used when registering the class).
 *
 * @param classid	A valid zombie class ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native origin_zclass_real_name(classid, real_name[], len)

/**
 * Returns a zombie class' description.
 *
 * @param classid		A valid zombie class ID.
 * @param description	The buffer to store the string in.
 * @param len			Character size of the output buffer.
 * @return				True on success, false otherwise.
 */
native origin_zclass_get_desc(classid, description[], len)

/**
 * Returns a zombie class' knockback multiplier.
 *
 * @param classid		A valid zombie class ID.
 * @return				Knockback multiplier (float value).
 */
native Float:origin_zclass_get_kb(classid)

/**
 * Returns number of registered zombie classes.
 *
 * @return			Zombie class count.
 */
native origin_zclass_get_count()

/**
 * Shows menu with available zombie classes to a player.
 *
 * @param id		Player index.
 */
native origin_zclass_show_menu(id)

/**
 * Appends text to a class being displayed on the zombie classes menu.
 * Use this on the class select pre forward.
 *
 * @param text		Additional text to display.
 */
native origin_zclass_menu_text_add(const text[])

/**
 * Called when determining whether a class should be available to a player.
 *
 * Possible return values are:
 *	- ORIGIN_CLASS_AVAILABLE (show in menu, allow selection)
 *	- ORIGIN_CLASS_NOT_AVAILABLE (show in menu, don't allow selection)
 *	- ORIGIN_CLASS_DONT_SHOW (don't show in menu, don't allow selection)
 *
 * @param id			Player index.
 * @param classid		Internal zombie class ID.
 */
forward origin_fw_zclass_select_pre(id, classid)

forward origin_zclass_selected(id, classid)


/* Abilities */

/**
 * Registers a custom ability for a given zombie class.
 *
 * @param classid       A valid zombie class ID.
 * @param skill_name    String of language key for the skill.
 * @return              True on success, false otherwise.
 */
native zombie_register_ability(classid, skill_name[50], default_cooldown)


/**
 * Forces to use valid skill the player with valid id.
 *
 * @param id                A valid player ID.
 * @param skill_id          A valid zombie ability ID.
 * @param custom_cooldown   How long the cooldown is?
 * @param custom_length     How long the length of ability is?
 * @return                  ORIGIN_ABILITY_ACTIVATED on success, ORIGIN_ABILITY_ERROR otherwise.
 */
native zombie_use_ability(id, skill_id, custom_cooldown, custom_length)

/**
 * Returns a zombie class' ability ready status.
 *
 * @param id            A valid player ID.
 * @param skill_id      Ability ID.
 * @return              True on success, false otherwise.
 */
native zombie_ability_ready(id, skill_id)