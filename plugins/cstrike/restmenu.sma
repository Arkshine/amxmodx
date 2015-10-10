/* AMX Mod X
 *   Restrict Weapons Plugin
 *
 * by the AMX Mod X Development Team
 *  originally developed by OLO
 *
 * This file is part of AMX Mod X.
 *
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software Foundation,
 *  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 *  In addition, as a special exception, the author gives permission to
 *  link the code of this program with the Half-Life Game Engine ("HL
 *  Engine") and Modified Game Libraries ("MODs") developed by Valve,
 *  L.L.C ("Valve"). You must obey the GNU General Public License in all
 *  respects for all of the code used other than the HL Engine and MODs
 *  from Valve. If you modify this file, you may extend this exception
 *  to your version of the file, but you are not obligated to do so. If
 *  you do not wish to do so, delete this exception statement from your
 *  version.
 */
#include <amxmodx>
#include <amxmisc>
#include <cstrike>

new const PluginName[] = "Restrict Weapons";

new MenuPosition[MAX_PLAYERS + 1];
new ModifiedState;
new ConfigFileName[64];

new WeaponRestrCvar[] = "00000000000000000000000000";
new EquipAmmoRestrCvar[] = "000000000";

new RestrSettingsCvarPointer;
new RestWeaponsCvarPointer;
new RestEquipAmmoCvarPointer;

new bool:BlockedItems[39]; // All CSI_* items.

enum
{
	ItemType_Handguns,
	ItemType_Shotguns,
	ItemType_SubMachineGuns,
	ItemType_AssaultRifles,
	ItemType_SniperRifles,
	ItemType_MachineGuns,
	ItemType_Equipment,
	ItemType_Ammunition,
//  --
	ItemType_Count
};

new const MenuAliasNames[][] =
{
	"pistol",
	"shotgun",
	"sub",
	"rifle",
	"sniper",
	"machine",
	"equip",
	"ammo"
};

new const MenuTitleNames[][] =
{
	"MENU_TITLE_HANDGUNS",
	"MENU_TITLE_SHOTGUNS",
	"MENU_TITLE_SUBMACHINES",
	"MENU_TITLE_RIFLES",
	"MENU_TITLE_SNIPERS",
	"MENU_TITLE_MACHINE",
	"MENU_TITLE_EQUIPMENT",
	"MENU_TITLE_AMMUNITION"
};

new const ItemsNames[][][] =
{
	{ "MENU_ITEM_USP"  , "MENU_ITEM_GLOCK18", "MENU_ITEM_DEAGLE", "MENU_ITEM_P228", "MENU_ITEM_ELITE", "MENU_ITEM_FIVESEVEN", "", "" },
	{ "MENU_ITEM_M3"   , "MENU_ITEM_XM1014" , "", "", "", "", "", "" },
	{ "MENU_ITEM_MP5N" , "MENU_ITEM_TMP"    , "MENU_ITEM_P90"   , "MENU_ITEM_MAC10", "MENU_ITEM_UMP45", "", "", "" },
	{ "MENU_ITEM_AK47" , "MENU_ITEM_SG552"  , "MENU_ITEM_M4A1"  , "MENU_ITEM_GALIL", "MENU_ITEM_FAMAS", "MENU_ITEM_AUG", "", "" },
	{ "MENU_ITEM_SCOUT", "MENU_ITEM_AWP"    , "MENU_ITEM_G3SG1" , "MENU_ITEM_SG550", "", "", "", "" },
	{ "MENU_ITEM_M249" , "", "", "", "", "", "", "" },
	{ "MENU_ITEM_VEST" , "MENU_ITEM_VESTHELM", "MENU_ITEM_FLASHBANG", "MENU_ITEM_HEGRENADE", "MENU_ITEM_SMOKEGREN", "MENU_ITEM_DEFUSEKIT", "MENU_ITEM_NVGS", "MENU_ITEM_SHIELD" },
	{ "MENU_ITEM_PRIAMMO", "MENU_ITEM_SECAMMO", "", "", "", "", "", "" }
};

new const AliasNames[][][] =
{
	{ "usp" , "glock" , "deagle", "p228", "elites", "fn57", "", "" },
	{ "m3"  , "xm1014", "", "", "", "", "", "" },
	{ "mp5" , "tmp"   , "p90"  , "mac10", "ump45", "", "", "" },
	{ "ak47", "sg552" , "m4a1" , "galil", "famas", "aug", "", "" },
	{ "scout", "awp"  , "g3sg1", "sg550", "", "", "", "" },
	{ "m249" , "", "", "", "", "", "", "" },
	{ "vest" , "vesthelm", "flash", "hegren", "sgren", "defuser", "nvgs", "shield" },
	{ "primammo", "secammo", "", "", "", "", "", "" }
};

new const SlotToItemId[][] =
{
	{ CSI_USP, CSI_GLOCK18, CSI_DEAGLE, CSI_P228, CSI_ELITE, CSI_FIVESEVEN, -1, -1 },
	{ CSI_M3 , CSI_XM1014, -1, -1, -1, -1, -1, -1 },
	{ CSI_MP5NAVY, CSI_TMP, CSI_P90, CSI_MAC10, CSI_UMP45, -1, -1, -1 },
	{ CSI_AK47 , CSI_SG552, CSI_M4A1 , CSI_GALIL, CSI_FAMAS, CSI_AUG, -1, -1 },
	{ CSI_SCOUT, CSI_AWP  , CSI_G3SG1, CSI_SG550, -1, -1, -1, -1 },
	{ CSI_M249, -1, -1, -1, -1, -1, -1, -1 },
	{ CSI_VEST, CSI_VESTHELM, CSI_FLASHBANG, CSI_HEGRENADE, CSI_SMOKEGRENADE, CSI_DEFUSER, CSI_NVGS, CSI_SHIELD },
	{ CSI_PRIAMMO, CSI_SECAMMO, -1, -1, -1, -1, -1, -1 }
};

public plugin_init()
{
	register_plugin(PluginName, AMXX_VERSION_STR, "AMXX Dev Team");

	register_dictionary("restmenu.txt");
	register_dictionary("common.txt");

	register_clcmd("amx_restmenu", "ClientCommand_Menu", ADMIN_CFG, _T("REG_CMD_MENU"));
	register_concmd("amx_restrict", "ConsoleCommand_WeaponRestriction", ADMIN_CFG, _T("REG_CMD_REST"));

	RestrSettingsCvarPointer = register_cvar("amx_restrsettings" , "0");
	RestWeaponsCvarPointer   = register_cvar("amx_restrweapons"  , "00000000000000000000000000");
	RestEquipAmmoCvarPointer = register_cvar("amx_restrequipammo", "000000000");
}

public OnConfigsExecuted()
{
	new configsDir[64];
	get_configsdir(configsDir, charsmax(configsDir));
	
	if (get_pcvar_num(RestrSettingsCvarPointer) > 0)
	{
		new mapname[32]
		get_mapname(mapname, charsmax(mapname));
		formatex(ConfigFileName, charsmax(ConfigFileName), "%s/weaprest_%s.ini", configsDir, mapname);
	}
	else
	{
		formatex(ConfigFileName, charsmax(ConfigFileName), "%s/weaprest.ini", configsDir);
	}
	
	loadSettings(ConfigFileName);
}

public CS_OnBuy(index, item)
{
	if (isItemBlocked(item))
	{
		client_print(index, print_center, "%l", "RESTRICTED_ITEM");
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public ClientCommand_Menu(id, level, cid)
{
	if (cmd_access(id, level, cid, 1))
	{
		displayMenu(id, MenuPosition[id] = 0);
	}

	return PLUGIN_HANDLED;
}

public ConsoleCommand_WeaponRestriction(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED;
	}

	new command[8];
	read_argv(1, command, charsmax(command));

	trim(command);
	strtolower(command);

	new ch1 = command[0];
	new ch2 = command[1];

	if (ch1 == 'o')  // on/off
	{
		new bool:status = (ch2 == 'n');
		new numArgs = read_argc();

		if (numArgs < 3)
		{
			arrayset(BlockedItems, status, sizeof BlockedItems);
			console_print(id, "%l", status ? "EQ_WE_RES" : "EQ_WE_UNRES");
			ModifiedState = true;
		}
		else
		{
			new argument[32];
			new bool:found, a;

			for (new i = 2, j; i < numArgs; ++i)
			{
				read_argv(i, argument, charsmax(argument));

				if ((a = findMenuId(argument)) != -1)
				{
					for (j = 0; j < sizeof ItemsNames[] && ItemsNames[a][j][0] != EOS; ++j)
					{
						BlockedItems[SlotToItemId[a][j]] = status;
					}

					console_print(id, "%s %l %l", MenuAliasNames[a], (a < 5) ? "HAVE_BEEN" : "HAS_BEEN", status ? "RESTRICTED" : "UNRESTRICTED");
					ModifiedState = found = true;
				}
				else if ((a = findItemIdFromAlias(argument)) != -1)
				{
					BlockedItems[a] = status;

					console_print(id, "%l %l %l", ItemsNames[a][j], "HAS_BEEN", status ? "RESTRICTED" : "UNRESTRICTED");
					ModifiedState = found = true;
				}
			}

			if (!found)
			{
				console_print(id, "%l", "NO_EQ_WE");
			}
		}
	}
	else if(ch1 == 'l' && ch2 == 'i')  // list
	{
		new argument[8], item = -1, i;

		if (read_argv(2, argument, charsmax(argument)))
		{
			item = clamp(str_to_num(argument) - 1, 0, charsmax(ItemsNames));
		}

		console_print(id, "^n----- %l: -----^n", "WEAP_RES");

		if (item == -1) // Item types.
		{
			for (i = 0; i < sizeof MenuTitleNames; ++i)
			{
				console_print(id, "%3d: %-32.31s", i + 1, _T(MenuTitleNames[i], id));
			}
		}
		else // Items list.
		{
			new langName[16], langValue[16], langStatus[16], langOnOff[16];

			LookupLangKey(langName, charsmax(langName), "NAME", id);
			LookupLangKey(langValue, charsmax(langValue), "VALUE", id);
			LookupLangKey(langStatus, charsmax(langStatus), "STATUS", id);

			console_print(id, "  %-32.31s   %-10.9s   %-9.8s", langName, langValue, langStatus);

			for (i = 0; i < sizeof ItemsNames[] && ItemsNames[item][i][0] != EOS; ++i)
			{
				LookupLangKey(langOnOff, charsmax(langOnOff), isItemBlocked(item, i) ? "ON" : "OFF", id);
				console_print(id, "  %-32.31s   %-10.9s   %-9.8s", _T(ItemsNames[item][i], id), AliasNames[item][i], langOnOff);
			}
		}
	}
	else if(ch1 == 's')  // save
	{
		if (saveSettings(ConfigFileName))
		{
			ModifiedState = false;
		}

		console_print(id, "%l", ModifiedState ? "REST_COULDNT_SAVE" : "REST_CONF_SAVED", ConfigFileName);
	}
	else if(ch1 == 'l' && ch2 == 'o')  // load
	{
		// Clear current settings.
		arrayset(BlockedItems, 0, sizeof BlockedItems);

		new argument[64];

		if (read_argv(2, argument, charsmax(argument)))
		{
			new configsDir[64];
			get_configsdir(configsDir, charsmax(configsDir));

			format(argument, charsmax(argument), "%s/%s", configsDir, argument);
		}

		if (loadSettings(argument))
		{
			ModifiedState = true;
		}

		console_print(id, "%l", ModifiedState ? "REST_CONF_LOADED" : "REST_COULDNT_LOAD", argument);
	}
	else
	{
		console_print(id, "%l", "COM_REST_USAGE");
		console_print(id, "%l", "COM_REST_COMMANDS");
		console_print(id, "%l", "COM_REST_ON");
		console_print(id, "%l", "COM_REST_OFF");
		console_print(id, "%l", "COM_REST_ONV");
		console_print(id, "%l", "COM_REST_OFFV");
		console_print(id, "%l", "COM_REST_LIST");
		console_print(id, "%l", "COM_REST_SAVE");
		console_print(id, "%l", "COM_REST_LOAD");
		console_print(id, "%l", "COM_REST_VALUES");
		console_print(id, "%l", "COM_REST_TYPE");
	}

	return PLUGIN_HANDLED;
}

displayMenu(id, itemType)
{
	if (itemType < 0)
	{
		return;
	}

	SetGlobalTransTarget(id);

	new menuTitle[64], menuBody[128], i;
	formatex(menuTitle, charsmax(menuTitle), "\y%l", "REST_WEAP");

	new menu = menu_create(menuTitle, "ActionMenu");

	// -1 because arrays are zero-based, avoids to do -1 everywhere below.
	if (--itemType < 0)  // Main menu
	{
		for (i = 0; i < sizeof MenuTitleNames; ++i)
		{
			menu_additem(menu, _T(MenuTitleNames[i], id));
		}
	}
	else // Sub-menus
	{
		// Add item type title to main title.
		format(menuTitle, charsmax(menuTitle), "%s > \d%l", menuTitle, MenuTitleNames[itemType]);
		menu_setprop(menu, MPROP_TITLE, menuTitle);

		for (i = 0; i < 8 && ItemsNames[itemType][i][0] != EOS; ++i)
		{
			formatex(menuBody, charsmax(menuBody), "%l\y\R%l", ItemsNames[itemType][i], isItemBlocked(itemType, i) ? "ON" : "OFF");
			menu_additem(menu, menuBody);
		}
	}

	// Add blanks until Save is 9 as key.
	menu_fillblanks(menu, itemType >= 0 ? 8 - i : 0, .newLineFirst = true);

	// Add Save item.
	formatex(menuBody, charsmax(menuBody), "%l \y\R%s", "SAVE_SET", ModifiedState ? "*" : "");
	menu_additem(menu, menuBody);

	menu_setprop(menu, MPROP_EXITNAME, _T(itemType < 0 ? "EXIT" : "BACK", id));
	menu_setprop(menu, MPROP_PERPAGE, 0);        // Disable pagination.
	menu_setprop(menu, MPROP_EXIT, MEXIT_FORCE); // Force an EXIT item since pagination is disabled.

	menu_display(id, menu);
}

public ActionMenu(id, menu, item)
{
	new position = MenuPosition[id];

	if (item < 0)
	{
		if (position)
		{	// We are in a sub-menu and we want to go back to main menu.
			displayMenu(id, position = 0);
		}
	}
	else
	{
		if (item == 8)
		{
			// Save item(s).
			client_print(id, print_chat, "* %l", (ModifiedState = !saveSettings(ConfigFileName)) ? "CONF_SAV_FAIL" : "CONF_SAV_SUC");
			displayMenu(id, position);
		}
		else if (!position)
		{
			// We are right now in the main menu, go to sub-menu.
			displayMenu(id, position = item + 1);
		}
		else
		{	// We are right now in a sub-menu.
			// We hit an item.
			ModifiedState = true;

			// Toggle item state.
			new itemId = SlotToItemId[position - 1][item];
			BlockedItems[itemId] = !BlockedItems[itemId];

			prepareRestrictedItemsToCvars(itemId, position - 1, item, WeaponRestrCvar, EquipAmmoRestrCvar, .toggleState = true);
			set_pcvar_string(RestWeaponsCvarPointer, WeaponRestrCvar);
			set_pcvar_string(RestEquipAmmoCvarPointer, EquipAmmoRestrCvar);

			displayMenu(id, position);
		}
	}

	// Update position.
	MenuPosition[id] = position;

	// Always!
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

findMenuId(const name[])
{
	for (new i = 0; i < sizeof MenuAliasNames ; ++i)
	{
		if (equali(name, MenuAliasNames[i]))
		{
			return i;
		}
	}

	return -1;
}

bool:isItemBlocked(position, slot = -1)
{
	new itemId = (slot != -1) ? SlotToItemId[position][slot] : position;

	return BlockedItems[itemId];
}

findItemIdFromAlias(const alias[], &i = 0, &j = 0)
{
	for (i = 0; i < sizeof AliasNames; ++i)
	for (j = 0; j < sizeof AliasNames[] && AliasNames[i][j][0] != EOS; ++j)
	{
		if (equali(alias, AliasNames[i][j]))
		{
			return SlotToItemId[i][j];
		}
	}

	return -1;
}

prepareRestrictedItemsToCvars(itemId, posType, posItem, weapRestr[], equipAmmoRestr[], bool:toggleState = false)
{
	// Item type start index from multidimensional to flat array (e.g. AliasNames array format, item type -> {items list}).
	// Fast way to translate from plugin array format (which is already in right order but multidimensional) to cvars format (flat).
	static const baseItemIndexes[] = {/* weapon: */ 0, 6, 8, 13, 19, 23, /* equip: */ 0, 7};
	new offset = baseItemIndexes[posType] + posItem;

	if (posType >= ItemType_Equipment)
	{
		if (itemId != CSI_SHIELD)
		{
			equipAmmoRestr[offset] = toggleState ? (equipAmmoRestr[offset] == '1' ? '0' : '1') : '1';
		}
		else
		{	// Special case for shields which needs to be considered as weapon.
			weapRestr[25] = toggleState ? (weapRestr[25] == '1' ? '0' : '1') : '1';
		}
	}
	else// Weapons
	{	// +1 to skip knife at index 0.
		weapRestr[offset + 1] = toggleState ? (weapRestr[offset + 1] == '1' ? '0' : '1') : '1';
	}
}

menu_fillblanks(menu, count, bool:newLineFirst = false)
{
	if (newLineFirst)
	{
		menu_addblank(menu, .slot = false);
	}

	if (count > 0)
	{
		while (--count >=0)
		{
			menu_addblank2(menu);
		}
	}
}

bool:saveSettings(const filename[])
{
	new fp = fopen(filename, "wt");

	if (!fp)
	{
		return false;
	}

	SetGlobalTransTarget(LANG_SERVER);

	fprintf(fp, "%l", "CONFIG_FILE_HEADER", PluginName);

	for (new i = 0, j; i < sizeof ItemsNames; ++i)
	{
		for (j = 0; j < sizeof ItemsNames[] && ItemsNames[i][j][0] != EOS; ++j)
		{
			if (isItemBlocked(i, j))
			{
				fprintf(fp, "%-16.15s ; %l^n", AliasNames[i][j], ItemsNames[i][j]);
			}
		}
	}

	fclose(fp);

	return true;
}

bool:loadSettings(const filename[])
{
	new fp = fopen(filename, "rt");

	if (!fp)
	{
		return false;
	}

	new lineRead[16];
	new ch, itemId, length;
	new posType, posItem;

	formatex(EquipAmmoRestrCvar, charsmax(EquipAmmoRestrCvar), "000000000");
	formatex(WeaponRestrCvar, charsmax(WeaponRestrCvar), "00000000000000000000000000");

	while (!feof(fp))
	{
		length = fgets(fp, lineRead, charsmax(lineRead));
		length -= trim(lineRead);

		if (!length || (ch = lineRead[0]) == EOS || ch == ';')
		{
			continue;
		}

		parse(lineRead, lineRead, charsmax(lineRead));

		if ((itemId = findItemIdFromAlias(lineRead, posType, posItem)) != -1)
		{
			BlockedItems[itemId] = true;
			prepareRestrictedItemsToCvars(itemId, posType, posItem, WeaponRestrCvar, EquipAmmoRestrCvar);
		}
	}

	set_pcvar_string(RestWeaponsCvarPointer, WeaponRestrCvar);
	set_pcvar_string(RestEquipAmmoCvarPointer, EquipAmmoRestrCvar);

	fclose(fp);

	return true;
}

// Is it somehow used by others plugins?
public blockcommand(id)
{
	client_print(id, print_center, "%l", "RESTRICTED_ITEM");
	return PLUGIN_HANDLED;
}

// Inline translation for readability sake.
_T(const key[], lang = LANG_SERVER)
{
	new buffer[256];
	LookupLangKey(buffer, charsmax(buffer), key, lang);
	
	return buffer;
}
