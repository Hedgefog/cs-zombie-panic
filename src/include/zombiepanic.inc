#if defined _zombiepanic_included
  #endinput
#endif
#define _zombiepanic_included

#pragma reqlib zombiepanic

#include <zombiepanic_const>

enum ZP_CharacterModels {
  CharacterModel_Human,
  CharacterModel_Zombie,
  CharacterModel_Swipe
}

// Player

native bool:ZP_Player_IsZombie(pPlayer);
native bool:ZP_Player_Panic(pPlayer);
native bool:ZP_Player_InPanic(pPlayer);
native bool:ZP_Player_ToggleFlashlight(pPlayer);
native bool:ZP_Player_ToggleZombieVision(pPlayer);
native ZP_Player_PlayZombieAmbient(pPlayer);

forward Zp_Fw_PlayerJoined(pPlayer);

// Player inventory

native ZP_Player_UpdateSpeed(pPlayer);
native ZP_Player_GetCharacter(pPlayer);
native ZP_Player_DropBackpack(pPlayer);
native ZP_Player_GetAmmo(pPlayer, const szAmmo[]);
native ZP_Player_SetAmmo(pPlayer, const szAmmo[], iValue);
native ZP_Player_AddAmmo(pPlayer, const szAmmo[], iValue);
native ZP_Player_NextAmmo(pPlayer);
native ZP_Player_DropAmmo(pPlayer);

// Characters

native ZP_GetCharacterModelPath(iCharacter, const szPath[], iLen);
native ZP_GetCharacterCount();
native ZP_GetCharacterModel(iCharacter, ZP_CharacterModels:iModel, szOut[], iLen);

// Ammo

native ZP_Ammo_GetHandler(const szName[]);
native ZP_Ammo_GetHandlerById(iAmmoId);
native ZP_Ammo_GetId(iHandler);
native ZP_Ammo_GetName(iHandler, szOut[], iLen);
native ZP_Ammo_GetPackSize(iHandler);
native ZP_Ammo_GetPackModel(iHandler, szOut[], iLen);
native ZP_Ammo_GetMaxAmount(iHandler);
native ZP_Ammo_GetCount();

// Game Rules

native bool:ZP_GameRules_GetObjectiveMode();
native ZP_GameRules_SetObjectiveMode(bool:bValue);
native ZP_GameRules_GetZombieLives();
native ZP_GameRules_SetZombieLives(iLives);
native ZP_GameRules_DispatchWin(iTeam);
