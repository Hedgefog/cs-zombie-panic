/*
    1.5.0
        Common:
            Refactored the entire codebase using AMXX Modding Kit

        Additions and Improvements:
            Added ability to unload weapons
            Increased maximum satchel capacity to 10
            Increased maximum grenade capacity to 10
            Added light and sound emission to satchel charges
            Satchel Charges now attach to the remote instead of the player
            Satchel Remote can now be dropped independently
            Satchel Charges can now be dropped as ammo
            Expanded character sound types in API
            Added material-specific hit effects for weapons
            Weaponboxes now bounce upon dropping
            Reworked Gamemode API
            Added mouth controller support for player models
            Updated backpack model
            Added round win sounds
            Added round start sound
            Added Zombie Vision sound
            Updated Flashlight sound
            Readjusted weapon spread and damage parameters
            Added blood decals when zombies hit world objects

        Fixes:
            Fixed bug when players can't pickup satchel charges in the water

    1.4.3
        Fixes:
            Fixed handgrenade respawn
            Fixed handgrenade and satchel errors

    1.4.2
        Additions and improvements:
            Add ambient_generic reset

    1.4.1
        Additions and improvements:
            Reduced shotgun spread
            Reduced shotgun range modifier
            Reduced default infection chance
            Map information is no longer showing by default
            Bots can now pick multiple secondary weapons
            Added hu localization (by regener)

        Cvars:
            Added zp_mapinfo cvar

        Fixes:
            Fixed satchels drop
            Fixed and optimized objective marks
            Fixed custom weapons prediction
            Fixed bots interaction with doors blocked by master
            Fixed en localization

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

native ZP_GameRules_DispatchWin(iTeam);
native ZP_GameRules_CanItemRespawn(const pItem);
native bool:ZP_GameRules_CanPickupItem(const pItem, const pPlayer);
native ZP_GameRules_SetVariable(ZP_GameRules_Variable:variable, any:value);
native any:ZP_GameRules_GetVariable(ZP_GameRules_Variable:variable);
native ZP_GameRules_ResetVariables();
native ZP_GameRules_CheckWinConditions();
native bool:ZP_GameRules_IsGameInProgress();
native bool:ZP_GameRules_IsRoundExpired();

forward ZP_OnConfigLoaded();
