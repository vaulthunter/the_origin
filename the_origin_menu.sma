#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#define LIBRARY_BUYMENUS "origin_buy_menus"
#include <origin_buy_menus>
#define LIBRARY_ZOMBIECLASSES "origin_class_zombie"
#include <origin_class_zombie>
#include <origin_colorchat>

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_ChooseTeamOverrideActive

new cvar_buy_custom_primary, cvar_buy_custom_secondary, cvar_buy_custom_grenades

public plugin_init()
{
	register_plugin("[Origin] Main Menu", ORIGIN_VERSION_STR_LONG, "Good_Hash")
	
	register_clcmd("chooseteam", "clcmd_chooseteam")
	
	register_clcmd("say /menu", "clcmd_menu")
	register_clcmd("say menu", "clcmd_menu")
	
	// Menus
	register_menu("Main Menu", KEYSMENU, "menu_main")
}

public clcmd_menu(id)
{
	show_menu_main(id)
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_BUYMENUS) || equal(module, LIBRARY_ZOMBIECLASSES))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public plugin_cfg()
{
	cvar_buy_custom_primary = get_cvar_pointer("origin_buy_custom_primary")
	cvar_buy_custom_secondary = get_cvar_pointer("origin_buy_custom_secondary")
	cvar_buy_custom_grenades = get_cvar_pointer("origin_buy_custom_grenades")
}

public clcmd_chooseteam(id)
{
	if (flag_get(g_ChooseTeamOverrideActive, id))
	{
		show_menu_main(id)
		return PLUGIN_HANDLED;
	}
	
	flag_set(g_ChooseTeamOverrideActive, id)
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	flag_set(g_ChooseTeamOverrideActive, id)
}

// Main Menu
show_menu_main(id)
{
	static menu[250]
	new len
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\yThe Origin %s^n^n", ORIGIN_VERSION_STR_LONG)
	
	// 1. Buy menu
	/*if (LibraryExists(LIBRARY_BUYMENUS, LibType_Library) && (get_pcvar_num(cvar_buy_custom_primary)
	|| get_pcvar_num(cvar_buy_custom_secondary) || get_pcvar_num(cvar_buy_custom_grenades)) && is_user_alive(id))
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_BUY")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L^n", id, "MENU_BUY")*/
	len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_BUY")
	
	// 2. Zombie class
	if (LibraryExists(LIBRARY_ZOMBIECLASSES, LibType_Library) &&origin_zclass_get_count() > 1)
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L^n", id, "MENU_ZCLASS")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d2. %L^n", id, "MENU_ZCLASS")
	
	// 3. Help
	len += formatex(menu[len], charsmax(menu) - len, "\r3.\r %L^n^n", id, "MENU_REGISTER")
	
	// 5. Choose Team
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L^n^n", id, "MENU_CHOOSE_TEAM")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "Main Menu")
}

// Main Menu
public menu_main(id, key)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	switch (key)
	{
		case 0: // Buy Menu
		{
			// Custom buy menus enabled?
			/*if (LibraryExists(LIBRARY_BUYMENUS, LibType_Library) && (get_pcvar_num(cvar_buy_custom_primary)
			|| get_pcvar_num(cvar_buy_custom_secondary) || get_pcvar_num(cvar_buy_custom_grenades)))
			{
				// Check whether the player is able to buy anything
				if (is_user_alive(id))
					origin_buy_menus_show(id)
				else
					origin_colored_print(id, "%L", id, "CANT_BUY_WEAPONS_DEAD")
			}
			else
				origin_colored_print(id, "%L", id, "CUSTOM_BUY_DISABLED")*/
			client_cmd(id, "buy")
		}
		case 1: // Zombie Classes
		{
			if (LibraryExists(LIBRARY_ZOMBIECLASSES, LibType_Library) && origin_zclass_get_count() > 1)
				origin_zclass_show_menu(id)
			else
				origin_colored_print(id, "%L", id, "CMD_NOT_ZCLASSES")
		}
		case 2: // Help Menu
		{
			//show_help(id)
			client_cmd(id, "la2a_menu")
		}
		case 4: // Menu override
		{
			flag_unset(g_ChooseTeamOverrideActive, id)
			client_cmd(id, "chooseteam")
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_buy(id)
{
	origin_buy_menus_show(id)
}

// Help MOTD
show_help(id)
{
	static motd[1024]
	new len
	
	len += formatex(motd[len], charsmax(motd) - len, "%L", id, "MOTD_INFO11", "The Origin Zombie Mod", ORIGIN_VERSION_STR_LONG, "Good_Hash")
	len += formatex(motd[len], charsmax(motd) - len, "%L", id, "MOTD_INFO12")
	
	show_motd(id, motd)
}
