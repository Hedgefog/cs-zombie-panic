/*
    1.4.0
        Additions and improvements:
            Infected players with symptoms can now pickup healthkit
            Healthkit is now suspends infection
            Player disconnection now affets zombie lives
            Increased flashlight consumption rate
            Bots no longer affect items respawn
            Reduced respawn control range for not visible items
            Added bodyindex property to Character API
            Added inherit property to Characters API
            Reduced weapon drop velocity
            Force disable minmodels
            Added weapon_crowbar entity
            Updated humans win message
            Increased duration for win message screen fade effect
            Improved team menu
            Added plugin to fix and improve bots behavior

        Cvars:
            Added zp_healthkit_suspend_infection cvar

        Fixes:
            Fixed weaponbox cleanup
            Fixed a bug when weapons overflow entities storage
            Grenades can no longer be dropped at the start of a throw
            Fixed melee hit detection
            Fixed respawn task for spectators
            Fixed respawn hints
            Fixed infected attribute updating
            Fixed weapon animations for spectators
            Fixed crosshair for spectators
            Fixed team info for spectators
            Fixed game messages on zpo_contingency map

    1.3.0
        Additions and improvements:
            Removed default pain sound
            Infected players no longer bleed
            Increased fade in time for win message
            Increased objective mark max velocity
            Weapons and items are now respawnable
            Reduced pickups respawn time
            Pickups will no longer respawn when players are nearby
            Added competitive mode
            Reduced 556ar spread

        Cvars:
            zombiepanic_version cvar is now visible for monitoring
            Added zp_competitive cvar

        Fixes:
            Fixed win conditions for spectators
            Fixed death sound for infected players
            Fixed melee secondary attack for bots
            Fixed first shot spread calculation
            Fixed death sound on transformation
            Fixed death message icons

    1.2.0
        Additions and improvements:
            Reduced crowbar damage to 25
            Added crowbar knockback
            Zombie lives are now related to the number of survivors
            Zombies number are now related to the number of survivors
            Added chooseteam command for spectators
            Zombies no longer respawn after round ends
            Magnum no longer eject brass when shooting
            Added blink effect at the end of the transformation
            Added unselectable characters support

        Cvars:
            Added zp_zombie_lives_per_player cvar

        Fixes:
            Fixed client crashes related to weapon icon names
            Fixed crosshair flickering
            Fixed zombie vision external fade handling
            Fixed zombie vision fade effect when respawning

    1.1.0
        Additions and improvements:
            Added infection (10% chance by default)
            Satchel charges are now can be picked up
            Improved spread and recoil system
            Added damage range modifier
            Reduced zombie damage to 25

        Cvars:
            Added zp_infection_chance cvar
            Added zp_healthkit_cure_chance cvar

        Fixes:
            Fixed decals
            Fixed client crashes when using melee weapons
*/

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
native bool:ZP_Player_IsInfected(pPlayer);
native bool:ZP_Player_IsTransforming(pPlayer);
native bool:ZP_Player_IsPartialZombie(pPlayer);
native ZP_Player_SetInfected(pPlayer, bool:bValue, pInfector = 0);
native ZP_Player_GetInfector(pPlayer);
native bool:ZP_Player_SetCharacter(pPlayer, const szCharacter[]);

forward ZP_Fw_PlayerJoined(pPlayer);
forward ZP_Fw_PlayerPanic(pPlayer);
forward ZP_Fw_PlayerZombieVision(pPlayer, bool:bValue);
forward ZP_Fw_PlayerAimItem(pPlayer, pItem);
forward ZP_Fw_PlayerInfected(pPlayer, pInfector);
forward ZP_Fw_PlayerCured(pPlayer);
forward ZP_Fw_PlayerTransformationDeath(pPlayer);
forward ZP_Fw_PlayerTransformed(pPlayer);
forward ZP_Fw_PlayerEquiped(pPlayer);
forward ZP_Fw_PlayerSpeedUpdated(pPlayer);
forward ZP_Fw_PlayerCharacterUpdated(pPlayer);
forward ZP_Fw_PlayerModelUpdated(pPlayer);

// Player inventory

native ZP_Player_UpdateSpeed(pPlayer);
native ZP_Player_DropUnactiveWeapons(pPlayer);
native ZP_Player_DropUnactiveAmmo(pPlayer);
native ZP_Player_GetAmmo(pPlayer, const szAmmo[]);
native ZP_Player_SetAmmo(pPlayer, const szAmmo[], iValue);
native ZP_Player_AddAmmo(pPlayer, const szAmmo[], iValue);
native ZP_Player_NextAmmo(pPlayer);
native ZP_Player_DropAmmo(pPlayer);
native ZP_Player_GetSelectedAmmo(pPlayer);
native ZP_Player_SetSelectedAmmo(pPlayer, const szAmmo[]);

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
native ZP_GameRules_CanItemRespawn(pItem);
native ZP_GameRules_IsCompetitive();

forward ZP_Fw_NewRound();
forward ZP_Fw_RoundStarted();
forward ZP_Fw_RoundEnd(iWinnerTeam);
forward ZP_Fw_ZombieLivesChanged(iLives);

// Map Info

native ZP_ShowMapInfo(pPlayer);
