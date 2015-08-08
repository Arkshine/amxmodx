// vim: set ts=4 sw=4 tw=99 noet:
//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
// Copyright (C) The AMX Mod X Development Team.
//
// Codebase from Ivan, -g-s-ivan@web.de (AMX 0.9.3)
// Modification by Olaf Reusch, kenterfie@hlsw.de (AMXX 0.16, AMX 0.96)
// Modification by David Anderson, dvander@tcwonline.org (AMXx 0.20)
//
// This software is licensed under the GNU General Public License, version 3 or higher.
// Additional exceptions apply. For full license details, see LICENSE.txt or visit:
//     https://alliedmods.net/amxmodx-license

//
// Sockets Module
//

#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#if defined _WIN32
// #	pragma comment(lib, "wsock32.lib")
// #	pragma comment(lib, "ws2_32.lib")

// #	include <WinSock2.h>
#	include <winsock.h>
#	include <io.h>
#else
#	include <unistd.h>
#	include <sys/types.h>
#	include <sys/socket.h>
#	include <netinet/in.h>
#	include <netdb.h>
#	include <arpa/inet.h>

#	define closesocket(s) close(s)
#endif

#include "amxxmodule.h"

#include <sh_string.h>

// Initial size for recv() function's output buffer.
//
#define INITIAL_RECV_SIZE (8192)

// Socket type for socket() function.
//
enum AmxxSocketType
{
	SOCKET_TCP = 1,
	SOCKET_UDP
};

// socket_open(Hostname[], Port, Protocol = SOCKET_TCP, &errorNum)
//
static cell AMX_NATIVE_CALL socket_open(AMX * pAmx, cell * pParams)
{
	// Gets hostname, hostname's length and error address.
	//
	int Length = 0;
	char * pName = MF_GetAmxString(pAmx, pParams[1], 0, &Length);
	cell * pError = MF_GetAmxAddr(pAmx, pParams[4]);

	// Hostname parameter is empty.
	//
	if (Length < 1)
	{
		*pError = 2;
		return -1;
	};

	// Opens new socket.
	//
	int Socket = (int)socket(AF_INET, AmxxSocketType(pParams[3]) == SOCKET_TCP ? SOCK_STREAM : SOCK_DGRAM, 0);
	if (Socket < 0)
	{
		*pError = 1;
		return -1;
	};

	// Server information.
	//
	struct sockaddr_in Server;
	memset(&Server, 0, sizeof Server);

	// Gets address.
	//
	unsigned long Addr = 0UL;
	if ((Addr = inet_addr(pName)) != INADDR_NONE)
		memcpy((char *)&Server.sin_addr, &Addr, sizeof Addr);

	else
	{
		struct hostent * pInfo = gethostbyname(pName);
		if (!pInfo)
		{
			*pError = 2;
			return -1;
		};

		memcpy((char *)&Server.sin_addr, pInfo->h_addr, pInfo->h_length);
	};

	Server.sin_family = AF_INET;
	Server.sin_port = htons((unsigned short)pParams[2]);

	// Connects.
	//
	if (connect(Socket, (struct sockaddr *)&Server, sizeof Server) < 0)
	{
		*pError = 3;
		return -1;
	};

	// Done, no errors.
	//
	*pError = 0;
	return Socket;
};

// socket_close(Socket)
//
static cell AMX_NATIVE_CALL socket_close(AMX *, cell * pParams)
{
	// Invalid socket.
	//
	if (pParams[1] < 0)
		return 0;

	// Closes socket.
	//
	closesocket(pParams[1]);
	return 1;
};

// socket_change(Socket, Timeout = 100000)
//
static cell AMX_NATIVE_CALL socket_change(AMX *, cell * pParams)
{
	// Gets the socket.
	//
	int Socket = pParams[1];
	if (Socket < 0)
		return 0;

	unsigned int Timeout = (unsigned int)pParams[2];

	fd_set Set;
	FD_ZERO(&Set);
	FD_SET(Socket, &Set);

	struct timeval TV;
	TV.tv_sec = 0;
	TV.tv_usec = Timeout;

	return select(Socket + 1, &Set, NULL, NULL, &TV) > 0 ? 1 : 0;
};

// socket_recv(Socket, Data[], maxLength)
//
static cell AMX_NATIVE_CALL socket_recv(AMX * pAmx, cell * pParams)
{
	// Gets the socket.
	//
	int Socket = pParams[1];
	if (Socket < 0)
		return -1;

	// Gets the maximum length.
	//
	size_t maxLength = (size_t)pParams[3];

	// Data to store buffer in.
	//
	String Buffer;
	int Res = 0;

	// While getting data.
	//
	do
	{
		// Allocates new block.
		//
		char * pRecv = (char *)malloc(INITIAL_RECV_SIZE + 1);

		// No memory.
		//
		if (!pRecv)
			break;

		// Receiving block.
		//
		Res = recv(Socket, pRecv, INITIAL_RECV_SIZE, 0);

		// Block has size.
		//
		if (Res > 0)
		{
			// Truncates where needed.
			//
			pRecv[Res] = char('\000');

			// Appends block to buffer.
			//
			Buffer.append(pRecv);
		};

		// Frees the memory block.
		//
		free(pRecv);
		pRecv = NULL;
	} while (Res > 0);

	// Sets the output string.
	//
	size_t Written = 0;
	cell * pDestination = MF_GetAmxAddr(pAmx, pParams[2]);
	while (maxLength > Written)
		*pDestination++ = (cell)Buffer.at(Written++);

	*pDestination = (cell)char('\000');

	// Returns written bytes.
	//
	return (cell)(maxLength < Buffer.size() ? maxLength : Buffer.size());
};

// native socket_send(Socket, Data[], Length)
//
static cell AMX_NATIVE_CALL socket_send(AMX * pAmx, cell * pParams)
{
	// Gets the socket.
	//
	int Socket = pParams[1];
	if (Socket < 0)
		return -1;

	size_t reqLen = (size_t)pParams[3];

	int curLen = 0;
	char * pData = MF_GetAmxString(pAmx, pParams[2], 0, &curLen);
	if (reqLen > (size_t)curLen)
		reqLen = curLen;

	return send(Socket, pData, reqLen, 0);
};

// socket_send2(Socket, Data[], Length)
//
static cell AMX_NATIVE_CALL socket_send2(AMX * pAmx, cell * pParams)
{
	// Gets the socket.
	//
	int Socket = pParams[1];
	if (Socket < 0)
		return -1;

	// Gets the desired length.
	//
	unsigned int reqLength = (unsigned int)pParams[3];

	// Allocates buffer.
	//
	String Buffer;

	// Gets data.
	//
	cell * pData = MF_GetAmxAddr(pAmx, pParams[2]);

	// Appends data to the buffer.
	//
	size_t curLen = 0;
	while (*pData)
	{
		Buffer.append(char(*pData++));
		curLen++;
	};

	if (reqLength > curLen)
		reqLength = curLen;

	// Sends buffer.
	//
	return send(Socket, Buffer.c_str(), reqLength, 0);
};

AMX_NATIVE_INFO sockets_natives[] =
{
	{ "socket_open", socket_open },
	{ "socket_close", socket_close },
	{ "socket_change", socket_change },
	{ "socket_recv", socket_recv },
	{ "socket_send", socket_send },
	{ "socket_send2", socket_send2 },

	{ NULL, NULL }
};

void OnAmxxAttach(void)
{
	MF_AddNatives(sockets_natives);

#if defined _WIN32
	WSADATA Data;
	if (WSAStartup(MAKEWORD(1, 1), &Data))
		MF_Log("Sockets Module @ WSAStartup() :  Error while starting up WinSock environment!");
#endif
};

void OnAmxxDetach(void)
{
#if defined _WIN32
	WSACleanup();
#endif
};
