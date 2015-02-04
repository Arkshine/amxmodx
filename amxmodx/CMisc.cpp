// vim: set ts=4 sw=4 tw=99 noet:
//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
// Copyright (C) The AMX Mod X Development Team.
//
// This software is licensed under the GNU General Public License, version 3 or higher.
// Additional exceptions apply. For full license details, see LICENSE.txt or visit:
//     https://alliedmods.net/amxmodx-license

#include "amxmodx.h"
#include "newmenus.h"
#include "CFile.h"

// *****************************************************
// class CPlayer
// *****************************************************

void CPlayer::Init(edict_t* e, int i)
{
	index = i;
	pEdict = e;
	initialized = false;
	ingame = false;
	authorized = false;
	teamIdsInitialized = false;

	current = 0;
	teamId = -1;
	deaths = 0;
	aiming = 0;
	menu = 0;
	keys = 0;
	menuexpire = 0.0;
	newmenu = -1;

	death_weapon.clear();
	name.clear();
	ip.clear();
	team.clear();
}

void CPlayer::Disconnect()
{
	ingame = false;
	initialized = false;
	authorized = false;
	teamIdsInitialized = false;

	if (Menu *pMenu = get_menu_by_id(newmenu))
		pMenu->Close(index);

	List<ClientCvarQuery_Info *>::iterator iter, end=queries.end();
	for (iter=queries.begin(); iter!=end; iter++)
	{
		unregisterSPForward((*iter)->resultFwd);
		delete [] (*iter)->params;
		delete (*iter);
	}
	queries.clear();

	menu = 0;
	newmenu = -1;
}

void CPlayer::PutInServer()
{
	playtime = gpGlobals->time;
	ingame = true;
}

int CPlayer::NextHUDChannel()
{
	int ilow = 1;

	for (int i=ilow+1; i<=4; i++)
	{
		if (channels[i] < channels[ilow])
			ilow = i;
	}

	return ilow;
}

bool CPlayer::Connect(const char* connectname, const char* ipaddress)
{
	name.assign(connectname);
	ip.assign(ipaddress);
	time = gpGlobals->time;
	death_killer = 0;
	menu = 0;
	newmenu = -1;
	
	memset(flags, 0, sizeof(flags));
	memset(weapons, 0, sizeof(weapons));
	
	initialized = true;
	authorized = false;

	for (int i=0; i<=4; i++)
	{
		channels[i] = 0.0f;
		hudmap[i] = 0;
	}

	List<ClientCvarQuery_Info *>::iterator iter, end=queries.end();
	for (iter=queries.begin(); iter!=end; iter++)
	{
		unregisterSPForward((*iter)->resultFwd);
		delete [] (*iter)->params;
		delete (*iter);
	}
	queries.clear();

	const char* authid = GETPLAYERAUTHID(pEdict);

	if ((authid == 0) || (*authid == 0) || (strcmp(authid, "STEAM_ID_PENDING") == 0))
		return true;

	return false;
}

// *****************************************************
// class Grenades
// *****************************************************

void Grenades::put(edict_t* grenade, float time, int type, CPlayer* player)
{
	Obj* a = new Obj;
	if (a == 0) return;
	a->player = player;
	a->grenade = grenade;
	a->time = gpGlobals->time + time;
	a->type = type;
	a->next = head;
	head = a;
}

bool Grenades::find(edict_t* enemy, CPlayer** p, int& type)
{
	bool found = false;
	Obj** a = &head;
	
	while (*a)
	{
		if ((*a)->time > gpGlobals->time)
		{
			if ((*a)->grenade == enemy)
			{
				found = true;
				(*p) = (*a)->player;
				type = (*a)->type;
			}
		} else {
			Obj* b = (*a)->next;
			delete *a;
			*a = b;
			continue;
		}
		a = &(*a)->next;
	}
	
	return found;
}

void Grenades::clear()
{
	while (head)
	{
		Obj* a = head->next;
		delete head;
		head = a;
	}
}

// *****************************************************
// class XVars
// *****************************************************

void XVars::clear()
{
	delete[] head;
	head = 0;
	num = 0;
	size = 0;
}

int XVars::put(AMX* p, cell* v)
{
	for (int a = 0; a < num; ++a)
	{
		if ((head[a].amx == p) && (head[a].value == v))
			return a;
	}

	if ((num >= size) && realloc_array(size ? (size * 2) : 8))
		return -1;

	head[num].value = v;
	head[num].amx = p;
	
	return num++;
}

int XVars::realloc_array(int nsize)
{
	XVarEle* me = new XVarEle[nsize];
	
	if (me)
	{
		for (int a = 0 ; a < num; ++a)
			me[a] = head[a];
		
		delete[] head;
		head = me;
		size = nsize;
		return 0;
	}
	
	return 1;
}

// *****************************************************
// class TeamIds
// *****************************************************

TeamIds::TeamIds() { head = 0; newTeam = 0; }

TeamIds::~TeamIds()
{
	while (head)
	{
		TeamEle* a = head->next;
		delete head;
		head = a;
	}
}

void TeamIds::registerTeam(const char* n, int s)
{
	TeamEle** a = &head;
	
	while (*a)
	{
		if (strcmp((*a)->name.c_str(),n) == 0)
		{
			if (s != -1)
			{
				(*a)->id = s;
				newTeam &= ~(1<<(*a)->tid);				
			}
			
			return;
		}
		a = &(*a)->next;
	}

	*a = new TeamEle(n, s);
	
	if (*a == 0)
		return;
	
	newTeam |= (1<<(*a)->tid);
}

int TeamIds::findTeamId(const char* n)
{
	TeamEle* a = head;
	
	while (a)
	{
		if (!stricmp(a->name.c_str(), n))
			return a->id;
		a = a->next;
	}
	
	return -1;
}

int TeamIds::findTeamIdCase(const char* n)
{
	TeamEle* a = head;
	
	while (a)
	{
		if (!strcmp(a->name.c_str(), n))
			return a->id;
		a = a->next;
	}
	
	return -1;
}

char TeamIds::TeamEle::uid = 0;


// *****************************************************
// class TemporaryExploitFix
// *****************************************************

TemporaryExploitFix ExploitFixManager;

#undef CMD_ARGV
#undef CMD_ARGS

const char* CMD_ARGS()
{
	return ExploitFixManager.OnCmdArgs();
}

const char* CMD_ARGV(int i)
{
	return ExploitFixManager.OnCmdArgv(i);
}


TemporaryExploitFix::TemporaryExploitFix()
{
	m_GameTitles.init();
}

TemporaryExploitFix::~TemporaryExploitFix()
{
	m_GameTitles.clear();
}

void TemporaryExploitFix::AddTitlesFromFile(const char* file)
{
	File h(build_pathname("%s", file), "rt");

	if (h)
	{
		char previousLineRead[64]; // Lazy parsing, but should be okay.
		char lineRead[64];

		while (h >> lineRead)
		{
			if (*lineRead == '{')
			{
				if (*previousLineRead)
				{
					InsertTitle(previousLineRead);
				}
			}
			else if (isalpha(*lineRead))
			{
				memcpy(previousLineRead, lineRead, sizeof(lineRead));
			}
		}
	}
}

bool TemporaryExploitFix::ContainsTitle(const char* aKey)
{
	CharsAndLength key(aKey);
	StringHashSet::Result r = m_GameTitles.find(key);

	return r.found();
}

bool TemporaryExploitFix::InsertTitle(const char* aKey)
{
	CharsAndLength key(aKey);
	StringHashSet::Insert i = m_GameTitles.findForAdd(key);

	if (i.found() || !m_GameTitles.add(i, aKey))
	{
		return false;
	}

	return true;
}

size_t TemporaryExploitFix::FilterFormat(char* string)
{
	size_t count = 0;
	
	for (char* buffer = string; buffer && *buffer != '\0'; ++buffer)
	{
		if (*buffer < ' ')
		{
			*buffer = ' ';
		}
		else if (*buffer == '%')
		{
			char next_ch = *(buffer + 1);

			if (next_ch != ' ' && next_ch != 'l' && next_ch)
			{
				*buffer = ' ';
				++count;
			}
		}
	}

	return count;
}

size_t TemporaryExploitFix::FilterLocalizedWord(char* string)
{
	char word[32];
	size_t count = 0;

	for (char* buffer = string; buffer && *buffer != '\0'; ++buffer)
	{
		if (*buffer == '#')
		{
			char* word_buffer = word;
			char* word_start  = buffer;

			for (++buffer; isalnum(*buffer); ++word_buffer, ++buffer)
			{
				*word_buffer = *buffer;
			}

			*word_buffer = '\0';

			if ((g_bmod_cstrike && (!strncmp(word, "Cstrike", 7) || !strncmp(word, "CZero", 5) || !strncmp(word, "Career", 6)))
				|| ContainsTitle(word))
			{
				*word_start = '*';
				++count;
			}

			buffer = word_start;
		}
	}

	return count;
}

size_t TemporaryExploitFix::FilterFormatAndAmpersand(char* string)
{
	size_t count = 0;
	char* buffer;

	for (buffer = string; buffer && *buffer != '\0'; ++buffer)
	{
		if (*buffer == '%' || *buffer == '&')
		{
			*buffer = ' ';
			++count;
		}
	}

	return count;
}

void TemporaryExploitFix::OnClientUserInfoChanged(edict_t* pEntity, char* infobuffer)
{
	const char* bufferName = INFOKEY_VALUE(infobuffer, "name");

	if (!pEntity->v.netname || (pEntity->v.netname && *STRING(pEntity->v.netname) != '\0' && strcmp(STRING(pEntity->v.netname), bufferName)))
	{
		char newName[32];  size_t count = 0;
		UTIL_Format(newName, sizeof(newName) - 1, "%s", bufferName);

		count  = FilterFormatAndAmpersand(newName);
		count += FilterLocalizedWord(newName);

		if (count)
		{
			SET_CLIENT_KEYVALUE(ENTINDEX(pEntity), infobuffer, "name", newName);
		}
	}
}

const char* TemporaryExploitFix::OnCmdArgv(int index)
{
	const char* argv = g_engfuncs.pfnCmd_Argv(index);

	// Make sure argv is valid and this is not an empty say/say_team.
	// We are willing to filter up to 2 arguments.

	if (argv && *argv && index >= 0 && index <= 2 && CMD_ARGC() >= 2)
	{
		if (index == 0 && !m_CheckArg)
		{
			m_CheckArg = !strcmp(argv, "say") || !strcmp(argv, "say_team");
		}
		else if (index >= 1 && m_CheckArg)
		{
			char* buffer = m_ArgvBuffer[--index];

			if (!*buffer) // Not cached yet.
			{
				size_t count = 0;
				strncopy(buffer, argv, strlen(argv) + 1);

				count  = FilterFormat(buffer);
				count += FilterLocalizedWord(buffer);

				m_SupercedeCommand = count > 0;
			}

			return m_ArgvBuffer[index];
		}
	}

	return argv;
}

const char* TemporaryExploitFix::OnCmdArgs()
{
	const char* args = g_engfuncs.pfnCmd_Args();

	if (m_CheckArg && args && *args)
	{
		if (!*m_ArgsBuffer) // Not cached yet.
		{
			strncopy(m_ArgsBuffer, args, strlen(args) + 1);

			FilterFormat(m_ArgsBuffer);
			FilterLocalizedWord(m_ArgsBuffer);
		}

		return m_ArgsBuffer;
	}

	return args;
}

bool TemporaryExploitFix::SendFilteredCmd()
{
	return m_SupercedeCommand;
}

void TemporaryExploitFix::ClearCachedArgs()
{
	m_CheckArg = false;
	m_SupercedeCommand = false;

	*m_ArgsBuffer = '\0';
	*m_ArgvBuffer[0] = '\0';
	*m_ArgvBuffer[1] = '\0';
}

