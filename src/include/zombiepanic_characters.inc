#if defined _zombiepanic_characters_included
  #endinput
#endif
#define _zombiepanic_characters_included

#pragma reqlib zombiepanic_characters

native bool:ZP_Player_SetCharacter(const pPlayer, const szCharacter[]);

forward ZP_Characters_OnPlayerCharacterUpdated(const pPlayer);
forward ZP_Characters_OnPlayerModelUpdated(const pPlayer);
