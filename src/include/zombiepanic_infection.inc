#if defined _zombiepanic_infection_included
  #endinput
#endif
#define _zombiepanic_infection_included

#pragma reqlib zombiepanic_infection

native bool:ZP_Infection_IsPlayerInfected(pPlayer);
native bool:ZP_Infection_IsPlayerTransforming(pPlayer);
native bool:ZP_Infection_IsPlayerPartialZombie(pPlayer);
native ZP_Infection_SetPlayerInfected(pPlayer, bool:bValue, pInfector = 0);
native ZP_Infection_GetPlayerInfector(pPlayer);
