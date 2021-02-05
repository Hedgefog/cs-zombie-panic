#if defined _zombiepanic_included
  #endinput
#endif
#define _zombiepanic_included

#pragma reqlib zombiepanic

#include <zombiepanic_const>

// Player

native bool:ZP_Player_IsZombie(pPlayer);
native bool:ZP_Player_Panic(pPlayer);
native bool:ZP_Player_InPanic(pPlayer);
native bool:ZP_Player_ToggleFlashlight(pPlayer);
native bool:ZP_Player_ToggleZombieVision(pPlayer);

forward ZP_Fw_PlayerJoined(pPlayer);
forward ZP_Fw_PlayerPanic(pPlayer);
forward ZP_Fw_PlayerZombieVision(pPlayer, bool:bValue);
forward ZP_Fw_Player_AimItem(pPlayer, pItem);

// Player inventory

native ZP_Player_UpdateSpeed(pPlayer);
native ZP_Player_DropBackpack(pPlayer);
native ZP_Player_GetAmmo(pPlayer, const szAmmo[]);
native ZP_Player_SetAmmo(pPlayer, const szAmmo[], iValue);
native ZP_Player_AddAmmo(pPlayer, const szAmmo[], iValue);
native ZP_Player_NextAmmo(pPlayer);
native ZP_Player_DropAmmo(pPlayer);

// Weapons

native ZP_Weapons_Register(CW:iCwHandler, Float:flWeight);
native Float:ZP_Weapons_GetWeight(pEntity);

// Ammo

native ZP_Ammo_GetHandler(const szName[]);
native ZP_Ammo_GetHandlerById(iAmmoId);
native ZP_Ammo_GetId(iHandler);
native ZP_Ammo_GetName(iHandler, szOut[], iLen);
native ZP_Ammo_GetPackSize(iHandler);
native ZP_Ammo_GetPackModel(iHandler, szOut[], iLen);
native ZP_Ammo_GetMaxAmount(iHandler);
native Float:ZP_Ammo_GetWeight(iHandler);
native ZP_Ammo_GetCount();

// Game Rules

native bool:ZP_GameRules_GetObjectiveMode();
native ZP_GameRules_SetObjectiveMode(bool:bValue);
native ZP_GameRules_GetZombieLives();
native ZP_GameRules_SetZombieLives(iLives);
native ZP_GameRules_RespawnAsZombie(pPlayer);
native ZP_GameRules_DispatchWin(iTeam);

// Map Info

native ZP_ShowMapInfo(pPlayer);
