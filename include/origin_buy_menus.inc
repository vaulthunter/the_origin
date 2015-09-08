#if defined _origin_buy_menus_included
  #endinput
#endif
#define _origin_buy_menus_included

#include <origin_engine>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib origin_buy_menus
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib origin_buy_menus
	#endif
#else
	#pragma library origin_buy_menus
#endif


/**
 * Shows available buy menus for player and enables them
 * back again if automatic weapon selection was enabled.
 *
 * @param id		Player index.
 */
native origin_buy_menus_show(id)

/**
 * Registers a custom item which will be added to the extra items menu of ORIGIN.
 *
 * Note: The returned item ID can be later used to catch item
 * selection events for the origin_item_select_() forwards.
 *
 * @param name			Caption to display on the menu.
 * @param cost			Cost to display on the menu.
 * @return				An internal item ID, or ORIGIN_INVALID_ITEM on failure.
 */
native origin_register_buy_item(const name[], cost, weapon_type)

/**
 * Called when determining whether an item should be available to a player.
 *
 * Possible return values are:
 *	- ORIGIN_ITEM_AVAILABLE (show in menu, allow selection)
 *	- ORIGIN_ITEM_NOT_AVAILABLE (show in menu, don't allow selection)
 *	- ORIGIN_ITEM_DONT_SHOW (don't show in menu, don't allow selection)
 *
 * @param id			Player index.
 * @param itemid		Internal item ID.
 * @param ignorecost	Whether item cost should be ignored.
 */
forward origin_fw_items_select_pre(id, itemid, ignorecost)

/**
 * Called after a player selected an item from the extra items menu.
 *
 * @param id			Player index.
 * @param itemid		Internal item ID.
 * @param ignorecost	Whether item cost should be ignored.
 */
forward origin_fw_items_select_post(id, itemid, ignorecost)
