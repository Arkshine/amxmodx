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

// Uncomment if you want to have seperate settings for each map
//#define MAPSETTINGS

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define MAXMENUPOS 34

new g_Position[33]
new g_Modified
new g_blockPos[112]
new g_saveFile[64]
new g_Restricted[] = "* This item is restricted *"
new g_szWeapRestr[27] = "00000000000000000000000000"
new g_szEquipAmmoRestr[10] = "000000000"

new const PluginName[] = "Restrict Weapons";

new bool:BlockedItems[39]; // All items.

new g_menuStrings[6][] =
{
	"BuyPistol",
	"BuyShotgun",
	"BuySubMachineGun",
	"BuyRifle",
	"BuyMachineGun",
	"BuyItem"
}

new g_menusNames[7][] =
{
	"pistol", 
	"shotgun", 
	"sub", 
	"rifle", 
	"machine", 
	"equip", 
	"ammo"
}

new const MenuTitleNames[][] =
{
	"Handguns", 
	"Shotguns", 
	"Sub-Machine Guns", 
	"Assault Rifles", 
	"Sniper Rifles", 
	"Machine Guns", 
	"Equipment", 
	"Ammunition"
};

new g_menusSets[7][2] =
{
	{0, 6}, {6, 8}, {8, 13}, {13, 23}, {23, 24}, {24, 32}, {32, 34}
}

new g_AliasBlockNum
new g_AliasBlock[MAXMENUPOS]

// First position is a position of menu (0 for ammo, 1 for pistols, 6 for equipment etc.)
// Second is a key for TERRORIST (all is key are minus one, 1 is 0, 2 is 1 etc.)
// Third is a key for CT
// Position with -1 doesn't exist

new g_Keys[MAXMENUPOS][3] =
{
	{1, 1, 1},	// H&K USP .45 Tactical
	{1, 0, 0},	// Glock18 Select Fire
	{1, 3, 3},	// Desert Eagle .50AE
	{1, 2, 2},	// SIG P228
	{1, 4, -1}, // Dual Beretta 96G Elite
	{1, -1, 4}, // FN Five-Seven
	{2, 0, 0},	// Benelli M3 Super90
	{2, 1, 1},	// Benelli XM1014
	{3, 1, 1},	// H&K MP5-Navy
	{3, -1, 0}, // Steyr Tactical Machine Pistol
	{3, 3, 3},	// FN P90
	{3, 0, -1}, // Ingram MAC-10
	{3, 2, 2},	// H&K UMP45
	{4, 1, -1}, // AK-47
	{4, 0, -1}, // Gali
	{4, -1, 0}, // Famas
	{4, 3, -1}, // Sig SG-552 Commando
	{4, -1, 2}, // Colt M4A1 Carbine
	{4, -1, 3}, // Steyr Aug
	{4, 2, 1},	// Steyr Scout
	{4, 4, 5},	// AI Arctic Warfare/Magnum
	{4, 5, -1}, // H&K G3/SG-1 Sniper Rifle
	{4, -1, 4}, // Sig SG-550 Sniper
	{5, 0, 0},	// FN M249 Para
	{6, 0, 0},	// Kevlar Vest
	{6, 1, 1},	// Kevlar Vest & Helmet
	{6, 2, 2},	// Flashbang
	{6, 3, 3},	// HE Grenade
	{6, 4, 4},	// Smoke Grenade
	{6, -1, 6}, // Defuse Kit
	{6, 5, 5},	// NightVision Goggles
	{6, -1, 7},	// Tactical Shield
	{0, 5, 5},	// Primary weapon ammo
	{0, 6, 6}	// Secondary weapon ammo
}

new g_WeaponNames[MAXMENUPOS][] =
{
	"H&K USP .45 Tactical", 
	"Glock18 Select Fire", 
	"Desert Eagle .50AE", 
	"SIG P228", 
	"Dual Beretta 96G Elite", 
	"FN Five-Seven", 
	"Benelli M3 Super90", 
	"Benelli XM1014", 
	"H&K MP5-Navy", 
	"Steyr Tactical Machine Pistol", 
	"FN P90", 
	"Ingram MAC-10", 
	"H&K UMP45", 
	"AK-47", 
	"Gali", 
	"Famas", 
	"Sig SG-552 Commando", 
	"Colt M4A1 Carbine", 
	"Steyr Aug", 
	"Steyr Scout", 
	"AI Arctic Warfare/Magnum", 
	"H&K G3/SG-1 Sniper Rifle", 
	"Sig SG-550 Sniper", 
	"FN M249 Para", 
	"Kevlar Vest", 
	"Kevlar Vest & Helmet", 
	"Flashbang", 
	"HE Grenade", 
	"Smoke Grenade", 
	"Defuse Kit", 
	"NightVision Goggles", 
	"Tactical Shield", 
	"Primary weapon ammo", 
	"Secondary weapon ammo"
}

new g_MenuItem[MAXMENUPOS][] =
{
	"\yHandguns^n\w^n%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w^n", 

	"\yShotguns^n\w^n%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w^n", 

	"\ySub-Machine Guns^n\w^n%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w^n", 

	"\yAssault Rifles^n\w^n%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w^n", 

	"\ySniper Rifles^n\w^n%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w^n", 

	"\yMachine Guns^n\w^n%d. %s\y\R%L^n\w^n", 

	"\yEquipment^n\w^n%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w^n", 

	"\yAmmunition^n\w^n%d. %s\y\R%L^n\w", 
	"%d. %s\y\R%L^n\w"
}

new g_Aliases[MAXMENUPOS][] =
{
	"usp",		//Pistols
	"glock", 
	"deagle", 
	"p228", 
	"elites", 
	"fn57", 

	"m3",		//Shotguns
	"xm1014", 

	"mp5",		//SMG
	"tmp", 
	"p90", 
	"mac10", 
	"ump45", 

	"ak47",		//Rifles
	"galil", 
	"famas", 
	"sg552", 
	"m4a1", 
	"aug", 
	"scout", 
	"awp", 
	"g3sg1", 
	"sg550", 

	"m249",		//Machine Gun

	"vest",		//Equipment
	"vesthelm", 
	"flash", 
	"hegren", 
	"sgren", 
	"defuser", 
	"nvgs", 
	"shield", 

	"primammo", //Ammo
	"secammo"
}

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

new const ItemsNames[][][] = 
{
	{ "H&K USP .45 Tactical", "Glock18 Select Fire", "Desert Eagle .50AE", "SIG P228", "Dual Beretta 96G Elite", "FN Five-Seven", "", "" },
	{ "Benelli M3 Super90", "Benelli XM1014", "", "", "", "", "", "" },
	{ "H&K MP5-Navy", "Steyr Tactical Machine Pistol", "FN P90", "Ingram MAC-10", "H&K UMP45", "", "", "" },
	{ "AK-47", "Sig SG-552 Commando", "Colt M4A1 Carbine", "Galil", "Famas", "Steyr Aug", "", "" },
	{ "Steyr Scout", "AI Arctic Warfare/Magnum", "H&K G3/SG-1 Sniper Rifle", "Sig SG-550 Sniper", "", "", "", "" },
	{ "FN M249 Para", "", "", "", "", "", "", "" },
	{ "Kevlar Vest", "Kevlar Vest & Helmet", "Flashbang", "HE Grenade", "Smoke Grenade", "Defuse Kit", "NightVision Goggles", "Tactical Shield" },
	{ "Primary weapon ammo", "Secondary weapon ammo", "", "", "", "", "", "" }
};

new const AliasNames[][][] = 
{
	{ "usp", "glock", "deagle", "p228", "elites", "fn57", "", "" },
	{ "m3", "xm1014", "", "", "", "", "", "" },
	{ "mp5", "tmp", "p90", "mac10", "ump45", "", "", "" },
	{ "ak47", "sg552", "m4a1", "galil", "famas", "aug", "", "" },
	{ "scout", "awp", "g3sg1", "sg550", "", "", "", "" },
	{ "m249", "", "", "", "", "", "", "" },
	{ "vest", "vesthelm", "flash", "hegren", "sgren", "defuser", "nvgs", "shield" },
	{ "primammo", "secammo", "", "", "", "", "", "" }
};

new const SlotToItemId[][] = 
{
	{ CSI_USP, CSI_GLOCK18, CSI_DEAGLE, CSI_P228, CSI_ELITE, CSI_FIVESEVEN, -1, -1 },
	{ CSI_M3, CSI_XM1014, -1, -1, -1, -1, -1, -1 },
	{ CSI_MP5NAVY, CSI_TMP, CSI_P90, CSI_MAC10, CSI_UMP45, -1, -1, -1 },
	{ CSI_AK47, CSI_SG552, CSI_M4A1, CSI_GALIL, CSI_FAMAS, CSI_AUG, -1, -1 },
	{ CSI_SCOUT, CSI_AWP, CSI_G3SG1, CSI_SG550, -1, -1, -1, -1 },
	{ CSI_M249, -1, -1, -1, -1, -1, -1, -1 },
	{ CSI_VEST, CSI_VESTHELM, CSI_FLASHBANG, CSI_HEGRENADE, CSI_SMOKEGRENADE, CSI_DEFUSER, CSI_NVGS, CSI_SHIELD },
	{ CSI_PRIAMMO, CSI_SECAMMO, -1, -1, -1, -1, -1, -1 } 
};

setWeapon(a, action)
{
	new b, m = g_Keys[a][0] * 8
	
	if (g_Keys[a][1] != -1)
	{
		b = m + g_Keys[a][1]
		
		if (action == 2)
			g_blockPos[b] = 1 - g_blockPos[b]
		else
			g_blockPos[b] = action
	}

	if (g_Keys[a][2] != -1)
	{
		b = m + g_Keys[a][2] + 56
		
		if (action == 2)
			g_blockPos[b] = 1 - g_blockPos[b]
		else
			g_blockPos[b] = action
	}

	for (new i = 0; i < g_AliasBlockNum; ++i)
		if (g_AliasBlock[i] == a)
		{
			if (!action || action == 2)
			{
				--g_AliasBlockNum
				
				for (new j = i; j < g_AliasBlockNum; ++j)
					g_AliasBlock[j] = g_AliasBlock[j + 1]
			}
			
			return
		}

	if (action && g_AliasBlockNum < MAXMENUPOS)
		g_AliasBlock[g_AliasBlockNum++] = a
}

findMenuId(name[])
{
	for (new i = 0; i < 7 ; ++i)
		if (equali(name, g_menusNames[i]))
			return i
	
	return -1
}

findAliasId(name[])
{
	for (new i = 0; i < MAXMENUPOS ; ++i)
		if (equali(name, g_Aliases[i]))
			return i
	
	return -1
}

switchCommand(id, action)
{
	new c = read_argc()

	if (c < 3)
	{
		for (new x = 0; x < MAXMENUPOS; x++)
			setWeapon(x, action)		

		console_print(id, "%L", id, action ? "EQ_WE_RES" : "EQ_WE_UNRES")
		g_Modified = true
	} else {
		new arg[32], a
		new bool:found = false
		
		for (new b = 2; b < c; ++b)
		{
			read_argv(b, arg, 31)
			
			if ((a = findMenuId(arg)) != -1)
			{
				c = g_menusSets[a][1]
				
				for (new i = g_menusSets[a][0]; i < c; ++i)
					setWeapon(i, action)
				
				console_print(id, "%s %L %L", MenuTitleNames[a], id, (a < 5) ? "HAVE_BEEN" : "HAS_BEEN", id, action ? "RESTRICTED" : "UNRESTRICTED")
				g_Modified = found = true
			}
			else if ((a = findAliasId(arg)) != -1)
			{
				g_Modified = found = true
				setWeapon(a, action)
				console_print(id, "%s %L %L", g_WeaponNames[a], id, "HAS_BEEN", id, action ? "RESTRICTED" : "UNRESTRICTED")
			}
		}

		if (!found)
			console_print(id, "%L", id, "NO_EQ_WE")
	}
}

positionBlocked(a)
{
	new m = g_Keys[a][0] * 8
	new d = (g_Keys[a][1] == -1) ? 0 : g_blockPos[m + g_Keys[a][1]]
	
	d += (g_Keys[a][2] == -1) ? 0 : g_blockPos[m + g_Keys[a][2] + 56]
	
	return d
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

public cmdRest(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new cmd[8]
	
	read_argv(1, cmd, 7)
	
	if (equali("on", cmd))
		switchCommand(id, 1)
	else if (equali("off", cmd))
		switchCommand(id, 0)
	else if (equali("list", cmd))
	{
		new arg1[8]
		new	start = read_argv(2, arg1, 7) ? str_to_num(arg1) : 1
		
		if (--start < 0)
			start = 0
		
		if (start >= MAXMENUPOS)
			start = MAXMENUPOS - 1
		
		new end = start + 10
		
		if (end > MAXMENUPOS)
			end = MAXMENUPOS
		
		new lName[16], lValue[16], lStatus[16], lOnOff[16]
		
		format(lName, 15, "%L", id, "NAME")
		format(lValue, 15, "%L", id, "VALUE")
		format(lStatus, 15, "%L", id, "STATUS")
		
		console_print(id, "^n----- %L: -----", id, "WEAP_RES")
		console_print(id, "     %-32.31s   %-10.9s   %-9.8s", lName, lValue, lStatus)
		
		if (start != -1)
		{
			for (new a = start; a < end; ++a)
			{
				format(lOnOff, 15, "%L", id, positionBlocked(a) ? "ON" : "OFF")
				console_print(id, "%3d: %-32.31s   %-10.9s   %-9.8s", a + 1, g_WeaponNames[a], g_Aliases[a], lOnOff)
			}
		}
		
		console_print(id, "----- %L -----", id, "REST_ENTRIES_OF", start + 1, end, MAXMENUPOS)
		
		if (end < MAXMENUPOS)
			console_print(id, "----- %L -----", id, "REST_USE_MORE", end + 1)
		else
			console_print(id, "----- %L -----", id, "REST_USE_BEGIN")
	}
	else if (equali("save", cmd))
	{
		if (saveSettings(g_saveFile))
		{
			console_print(id, "%L", id, "REST_CONF_SAVED", g_saveFile)
			g_Modified = false
		}
		else
			console_print(id, "%L", id, "REST_COULDNT_SAVE", g_saveFile)
	}
	else if (equali("load", cmd))
	{
		setc(g_blockPos, 112, 0)	// Clear current settings
		new arg1[64]

		if (read_argv(2, arg1, 63))
		{
			new configsdir[32]
			get_configsdir(configsdir, 31)

			format(arg1, 63, "%s/%s", configsdir, arg1)
		}
		
		if (loadSettings(arg1))
		{
			console_print(id, "%L", id, "REST_CONF_LOADED", arg1)
			g_Modified = true
		}
		else
			console_print(id, "%L", id, "REST_COULDNT_LOAD", arg1)
	} else {
		console_print(id, "%L", id, "COM_REST_USAGE")
		console_print(id, "%L", id, "COM_REST_COMMANDS")
		console_print(id, "%L", id, "COM_REST_ON")
		console_print(id, "%L", id, "COM_REST_OFF")
		console_print(id, "%L", id, "COM_REST_ONV")
		console_print(id, "%L", id, "COM_REST_OFFV")
		console_print(id, "%L", id, "COM_REST_LIST")
		console_print(id, "%L", id, "COM_REST_SAVE")
		console_print(id, "%L", id, "COM_REST_LOAD")
		console_print(id, "%L", id, "COM_REST_VALUES")
		console_print(id, "%L", id, "COM_REST_TYPE")
	}

	return PLUGIN_HANDLED
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
		
displayMenu(id, itemType)
{
	if (itemType < 0) 
	{
		return;
	}

	new menuTitle[64], menuBody[128], i;
	formatex(menuTitle, charsmax(menuTitle), "\y%L", id, "REST_WEAP");
	
	new menu = menu_create(menuTitle, "ActionMenu");
	
	// -1 because arrays are zero-based, avoids to do -1 everywhere below.
	if (--itemType < 0)  // Main menu
	{
		for (i = 0; i < sizeof MenuTitleNames; ++i)
		{
			menu_additem(menu, MenuTitleNames[i]);
		}
	}
	else // Sub-menus
	{
		// Add item type title to main title.
		format(menuTitle, charsmax(menuTitle), "%s > \d%s", menuTitle, MenuTitleNames[itemType]);
		menu_setprop(menu, MPROP_TITLE, menuTitle);
		
		for (i = 0; i < 8 && ItemsNames[itemType][i][0] != EOS; ++i)
		{
			formatex(menuBody, charsmax(menuBody), "%s\y\R%L", ItemsNames[itemType][i], id, isItemBlocked(itemType, i) ? "ON" : "OFF");
			menu_additem(menu, menuBody);
		}
	}
	
	// Add blanks until Save is 9 as key.
	menu_fillblanks(menu, itemType >= 0 ? 8 - i : 0, .newLineFirst = true);
		
	// Add Save item.
	formatex(menuBody, charsmax(menuBody), "%L \y\R%s", id, "SAVE_SET", g_Modified ? "*" : "");
	menu_additem(menu, menuBody);
		
	formatex(menuBody, charsmax(menuBody), "%L", id, itemType < 0 ? "EXIT" : "BACK");
	menu_setprop(menu, MPROP_EXITNAME, menuBody);
	menu_setprop(menu, MPROP_PERPAGE, 0);        // Disable pagination.
	menu_setprop(menu, MPROP_EXIT, MEXIT_FORCE); // Force an EXIT item since pagination is disabled.
	
	menu_display(id, menu);
}

public ActionMenu(id, menu, item)
{
	new position = g_Position[id];
	
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
			client_print(id, print_chat, "* %L", id, (g_Modified = !saveSettings(g_saveFile)) ? "CONF_SAV_FAIL" : "CONF_SAV_SUC");
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
			g_Modified = true;
			
			// Toggle item state.
			new itemId = SlotToItemId[position - 1][item];
			BlockedItems[itemId] = !BlockedItems[itemId];
			
			prepareRestrictedItemsToCvars(itemId, position - 1, item, g_szWeapRestr, g_szEquipAmmoRestr, .toggleState = true);
			set_cvar_string("amx_restrweapons", g_szWeapRestr);
			set_cvar_string("amx_restrequipammo", g_szEquipAmmoRestr);
	
			displayMenu(id, position);
		}
	}
	
	// Update position.
	g_Position[id] = position;
	
	// Always!
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public blockcommand(id)
{
	client_print(id, print_center, "%s", g_Restricted)
	return PLUGIN_HANDLED
}

public cmdMenu(id, level, cid)
{
	if (cmd_access(id, level, cid, 1))
	{
		displayMenu(id, g_Position[id] = 0)
	}
	
	return PLUGIN_HANDLED
}

bool:saveSettings(const filename[])
{
	new fp = fopen(filename, "wt");
	
	if (!fp)
	{
		return false;
	}
	
	fprintf(fp, "; Generated by %s Plugin. Do not modify!^n; value name^n", PluginName);

	for (new i = 0, j; i < sizeof ItemsNames; ++i)
	{
		for (j = 0; j < sizeof ItemsNames[] && ItemsNames[i][j][0] != EOS; ++j)
		{
			if (isItemBlocked(i, j))
			{
				fprintf(fp, "%-16.15s ; %s^n", AliasNames[i][j], ItemsNames[i][j]);
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
	
	formatex(g_szEquipAmmoRestr, charsmax(g_szEquipAmmoRestr), "000000000");
	formatex(g_szWeapRestr, charsmax(g_szWeapRestr), "00000000000000000000000000");

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
			prepareRestrictedItemsToCvars(itemId, posType, posItem, g_szWeapRestr, g_szEquipAmmoRestr);
		}
	}

	set_cvar_string("amx_restrweapons", g_szWeapRestr);
	set_cvar_string("amx_restrequipammo", g_szEquipAmmoRestr);

	return true;
}

public CS_OnBuy(index, item)
{
	if (isItemBlocked(item))
	{
		client_print(index, print_center, "%s", g_Restricted);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public plugin_init()
{
	register_plugin(PluginName, AMXX_VERSION_STR, "AMXX Dev Team")
	register_dictionary("restmenu.txt")
	register_dictionary("common.txt")
	register_clcmd("amx_restmenu", "cmdMenu", ADMIN_CFG, "- displays weapons restriction menu")

	register_concmd("amx_restrict", "cmdRest", ADMIN_CFG, "- displays help for weapons restriction")

	register_cvar("amx_restrweapons", "00000000000000000000000000")
	register_cvar("amx_restrequipammo", "000000000")
	
	new configsDir[64];
	get_configsdir(configsDir, 63);
#if defined MAPSETTINGS
	new mapname[32]
	get_mapname(mapname, 31)
	format(g_saveFile, 63, "%s/weaprest_%s.ini", configsDir, mapname)
#else
	format(g_saveFile, 63, "%s/weaprest.ini", configsDir)
#endif
	loadSettings(g_saveFile)
}