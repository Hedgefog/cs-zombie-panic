#if defined _zombiepanic_gamemodes_included
  #endinput
#endif

#define _zombiepanic_gamemodes_included

#pragma reqlib zombiepanic_gamemodes

#include <zombiepanic_gamemodes_const>

native ZP_GameMode_Register(const szId[]);
native ZP_GameMode_SetCallback(const szId[], const ZP_GameModes_Callback:callback, const szCallback[]);
native bool:ZP_GameMode_Activate(const szId[]);
native bool:ZP_GameMode_IsActive(const szId[]);
native bool:ZP_GameMode_SetDefault(const szId[]);
native ZP_GameMode_GetDefault(szOut[], iMaxLen);

native ZP_GameMode_SetState(const szState[], any:value);
native any:ZP_GameMode_GetState(const szState[]);
native bool:ZP_GameMode_SetStateString(const szState[], const szValue[]);
native bool:ZP_GameMode_GetStateString(const szState[], szOut[], iMaxLen);
native bool:ZP_GameMode_SetStateVector(const szState[], const Float:vecValue[]);
native bool:ZP_GameMode_GetStateVector(const szState[], Float:vecOut[]);
