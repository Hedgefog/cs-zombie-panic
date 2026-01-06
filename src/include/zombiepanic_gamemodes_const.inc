#if defined _zombiepanic_gamemodes_const_included
  #endinput
#endif

#define _zombiepanic_gamemodes_const_included

#define GAMEMODE_SURVIVAL "survival"

enum ZP_GameModes_Callback {
  ZP_GameModes_Callback_Activate,
  ZP_GameModes_Callback_Deactivate,
  ZP_GameModes_Callback_GameInit,
  ZP_GameModes_Callback_GameStart,
  ZP_GameModes_Callback_GameEnd,
  ZP_GameModes_Callback_CheckWinConditions,
  ZP_GameModes_Callback_CanPlayerRespawn,
  ZP_GameModes_Callback_PlayerRespawn,
  ZP_GameModes_Callback_PlayerRespawned
};
