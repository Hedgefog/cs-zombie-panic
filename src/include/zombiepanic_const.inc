#if defined _zombiepanic_const_included
  #endinput
#endif
#define _zombiepanic_const_included

#define ZP_TITLE "Zombie Panic"
#define ZP_VERSION "1.6.0"

/*--------------------------------[ Constants ]--------------------------------*/

enum _:ZP_Team {
  ZP_Team_Unassigned = 0,
  ZP_Team_Zombies,
  ZP_Team_Survivors,
  ZP_Team_Spectators
};

enum ZP_PlayerRole_Base_Sound {
  ZP_PlayerRole_Base_Sound_Idle = 0,
  ZP_PlayerRole_Base_Sound_Death,
  ZP_PlayerRole_Base_Sound_Scream,
  ZP_PlayerRole_Base_Sound_Pain,
  ZP_PlayerRole_Base_Sound_Taunt,
  ZP_PlayerRole_Base_Sound_Press
};

enum {
  ZP_WeaponId_Pistol = 3,
  ZP_WeaponId_Magnum,
  ZP_WeaponId_Rifle,
  ZP_WeaponId_Shotgun,
  ZP_WeaponId_Crowbar,
  ZP_WeaponId_Swipe,
  ZP_WeaponId_Grenade,
  ZP_WeaponId_Satchel
};

enum ZP_State_Infection {
  ZP_State_Infection_None,
  ZP_State_Infection_Infected,
  ZP_State_Infection_PartialZombie,
  ZP_State_Infection_Transformation,
  ZP_State_Infection_TransformationDeath,
  ZP_State_Infection_TransformationEnd
};

enum ZP_State_Panic {
  ZP_State_Panic_None,
  ZP_State_Panic_Panic,
  ZP_State_Panic_Rest
};

enum ZP_GameRules_Variable {
  ZP_GameRules_Variable_bAllowRespawn,
  ZP_GameRules_Variable_bCompetitiveMode,
  ZP_GameRules_Variable_flRespawnTime,
  ZP_GameRules_Variable_iPlayersPerZombie,
  ZP_GameRules_Variable_bLimitedRoundTime,
  ZP_GameRules_Variable_iZombiesValue,
  ZP_GameRules_Variable_flPlayerWeightMultiplier
};

enum ZP_PlayerRole_Base_DropFlags (<<=1) {
  ZP_PlayerRole_Base_DropFlag_None = 0,
  ZP_PlayerRole_Base_DropFlag_RandomDirection = 1,
  ZP_PlayerRole_Base_DropFlag_ReverseDirection,
  ZP_PlayerRole_Base_DropFlag_RandomAngles,
  ZP_PlayerRole_Base_DropFlag_SkipActive,
  ZP_PlayerRole_Base_DropFlag_RandomForce,
  ZP_PlayerRole_Base_DropFlag_UseViewAngles,
  ZP_PlayerRole_Base_DropFlag_ReverseAngles
};

/*--------------------------------[ Libraries ]--------------------------------*/

stock const ZP_Library_Core[] = "zombiepanic";
stock const ZP_Library_Gamerules[] = "zombiepanic_gamerules";
stock const ZP_Library_Gamemodes[] = "zombiepanic_gamemodes";
stock const ZP_Library_Ammo[] = "zombiepanic_ammo";
stock const ZP_Library_Infection[] = "zombiepanic_infection";

/*--------------------------------[ Config ]--------------------------------*/

#define ZP_DROPPABLE_SATCHELS

#define ZP_AMMO_RESPAWN_TIME 40.0
#define ZP_WEAPONS_RESPAWN_TIME 60.0
#define ZP_ITEMS_RESPAWN_TIME 60.0

#define ZP_STRAFE_SPEED_MODIFIER 0.612961
#define ZP_BACKWARD_SPEED_MODIFIER 0.5
#define ZP_DUCK_SPEED_MODIFIER 1.066825

/*--------------------------------[ Player Roles ]--------------------------------*/

stock const ZP_PlayerRoleGroup[] = "zombiepanic";

stock const ZP_PlayerRole_Base[] = "zombiepanic-base";
stock const ZP_PlayerRole_Survivor[] = "zombiepanic-survivor";
stock const ZP_PlayerRole_Zombie[] = "zombiepanic-zombie";

stock const ZP_PlayerRole_Base_Method_Equip[] = "Equip";
stock const ZP_PlayerRole_Base_Method_GetMaxSpeed[] = "GetMaxSpeed";
stock const ZP_PlayerRole_Base_Method_GetMaxHealth[] = "GetMaxHealth";
stock const ZP_PlayerRole_Base_Method_Think[] = "Think";
stock const ZP_PlayerRole_Base_Method_Spawn[] = "Spawn";
stock const ZP_PlayerRole_Base_Method_CanPickupItem[] = "CanPickupItem";
stock const ZP_PlayerRole_Base_Method_CanUseButton[] = "CanUseButton";
stock const ZP_PlayerRole_Base_Method_DropAmmo[] = "DropAmmo";
stock const ZP_PlayerRole_Base_Method_DropItem[] = "DropItem";
stock const ZP_PlayerRole_Base_Method_DropWeaponBox[] = "DropWeaponBox";
stock const ZP_PlayerRole_Base_Method_DropAllAmmo[] = "DropAllAmmo";
stock const ZP_PlayerRole_Base_Method_DropAllItems[] = "DropAllItems";
stock const ZP_PlayerRole_Base_Method_DropActiveItem[] = "DropActiveItem";
stock const ZP_PlayerRole_Base_Method_DropInactiveItems[] = "DropInactiveItems";
stock const ZP_PlayerRole_Base_Method_UpdateInventoryWeight[] = "UpdateInventoryWeight";
stock const ZP_PlayerRole_Base_Method_Killed[] = "Killed";
stock const ZP_PlayerRole_Base_Method_DropBackpack[] = "DropBackpack";
// stock const ZP_PlayerRole_Base_Method_RemoveAllItems[] = "RemoveAllItems";
stock const ZP_PlayerRole_Base_Method_UpdateModel[] = "UpdateModel";
stock const ZP_PlayerRole_Base_Method_PlaySound[] = "PlaySound";
stock const ZP_PlayerRole_Base_Method_Taunt[] = "Taunt";
stock const ZP_PlayerRole_Base_Method_Idle[] = "Idle";
stock const ZP_PlayerRole_Base_Method_Pain[] = "Pain";
stock const ZP_PlayerRole_Base_Method_TakeDamage[] = "TakeDamage";
stock const ZP_PlayerRole_Base_Method_CalculateDamage[] = "CalculateDamage";

stock const ZP_PlayerRole_Base_Member_flInventoryWeight[] = "flInventoryWeight";
stock const ZP_PlayerRole_Base_Member_flNextItemPickup[] = "flNextItemPickup";
stock const ZP_PlayerRole_Base_Member_bShouldUpdateInventoryWeight[] = "bShouldUpdateInventoryWeight";
stock const ZP_PlayerRole_Base_Member_flNextIdleSound[] = "flNextIdleSound";
stock const ZP_PlayerRole_Base_Member_szModel[] = "szModel";
stock const ZP_PlayerRole_Base_Member_flTauntChance[] = "flTauntChance";
stock const ZP_PlayerRole_Base_Member_flMinIdleSoundDelay[] = "flMinIdleSoundDelay";
stock const ZP_PlayerRole_Base_Member_flMaxIdleSoundDelay[] = "flMaxIdleSoundDelay";
stock const ZP_PlayerRole_Base_Member_flNextPain[] = "flNextPain"; 
stock const ZP_PlayerRole_Base_Member_flNextSound[] = "flNextSound";
stock const ZP_PlayerRole_Base_Member_flSpeedMultiplier[] = "flSpeedMultiplier";

stock const ZP_PlayerRole_Survivor_Member_iSelectedAmmo[] = "iSelectedAmmo";
stock const ZP_PlayerRole_Survivor_Method_SelectNextAmmo[] = "SelectNextAmmo";
stock const ZP_PlayerRole_Survivor_Method_DropSelectedAmmo[] = "DropSelectedAmmo";

stock const ZP_PlayerRole_Zombie_Method_Regenerate[] = "Regenerate";

stock const ZP_PlayerRole_Zombie_Member_flLastRegeneration[] = "flLastRegeneration";
stock const ZP_PlayerRole_Zombie_Member_flNextRegeneration[] = "flNextRegeneration";
stock const ZP_PlayerRole_Zombie_Member_flRegenerationRate[] = "flRegenerationRate";
stock const ZP_PlayerRole_Zombie_Member_flRegenerationPerSecond[] = "flRegenerationPerSecond";
stock const ZP_PlayerRole_Zombie_Member_flNextMoan[] = "flNextMoan";

/*--------------------------------[ Entities ]--------------------------------*/

stock const ZP_Entity_LightCone[] = "zp_lightcone";
stock const ZP_Entity_HealthKit[] = "zp_item_healthkit";
stock const ZP_Entity_Armor[] = "zp_item_armor";
stock const ZP_Entity_Grenade[] = "zp_grenade";
stock const ZP_Entity_BaseItem[] = "zp_base_item";
stock const ZP_Entity_BaseSpawner[] = "zp_base_spawner";
stock const ZP_Entity_AmmoSpawner[] = "zp_ammo_spawner";
stock const ZP_Entity_WeaponSpawner[] = "zp_weapon_spawner";
stock const ZP_Entity_PistolAmmo[] = "ammo_9mmclip";
stock const ZP_Entity_RifleAmmo[] = "ammo_556AR";
stock const ZP_Entity_RifleAmmoBox[] = "ammo_556box";
stock const ZP_Entity_MagnumAmmo[] = "ammo_357";
stock const ZP_Entity_ShotgunAmmo[] = "ammo_buckshot";
stock const ZP_Entity_CrowbarWeapon[] = "weapon_crowbar";
stock const ZP_Entity_PistolWeapon[] = "weapon_9mmhandgun";
stock const ZP_Entity_RifleWeapon[] = "weapon_556AR";
stock const ZP_Entity_ShotgunWeapon[] = "weapon_shotgun";
stock const ZP_Entity_MagnumWeapon[] = "weapon_357";
stock const ZP_Entity_GrenadeWeapon[] = "weapon_handgrenade";
stock const ZP_Entity_SatchelWeapon[] = "weapon_satchel";
stock const ZP_Entity_SatchelCharge[] = "zp_satchel_charge";
stock const ZP_Entity_WeaponBox[] = "weaponbox";
stock const ZP_Entity_AmbientGeneric[] = "ambient_generic";
stock const ZP_Entity_Breakable[] = "func_breakable";
stock const ZP_Entity_Button[] = "func_button";
stock const ZP_Entity_Train[] = "func_train";
stock const ZP_Entity_Door[] = "func_door";
stock const ZP_Entity_MultiManager[] = "multi_manager";
stock const ZP_Entity_MultiSource[] = "multisource";
stock const ZP_Entity_WallToggle[] = "func_wall_toggle";

/*--------------------------------[ Entity Methods and Members ]--------------------------------*/

stock const ZP_Entity_WeaponBox_Method_PackAmmo[] = "PackAmmo";
stock const ZP_Entity_WeaponBox_Method_PackItem[] = "PackItem";
stock const ZP_Entity_WeaponBox_Method_BounceTouch[] = "BounceTouch";
stock const ZP_Entity_WeaponBox_Method_BounceSound[] = "BounceSound";
stock const ZP_Entity_WeaponBox_Method_ResetBounceSound[] = "ResetBounceSound";

stock const ZP_Entity_WeaponBox_Member_iOldFlags[] = "iOldFlags";
stock const ZP_Entity_WeaponBox_Member_szBounceSound[] = "szBounceSound";
stock const ZP_Entity_WeaponBox_Member_iItemsNum[] = "iItemsNum";
stock const ZP_Entity_WeaponBox_Member_bDirty[] = "bDirty";

stock const ZP_Entity_BaseSpawner_Method_SpawnWeaponBox[] = "SpawnWeaponBox";
stock const ZP_Entity_BaseSpawner_Member_pWeaponBox[] = "pWeaponBox";

stock const ZP_Entity_WeaponSpawner_Member_szWeapon[] = "szWeapon";
stock const ZP_Entity_WeaponSpawner_Method_SpawnItem[] = "SpawnItem";

stock const ZP_Entity_AmmoSpawner_Member_szAmmo[] = "szAmmo";
stock const ZP_Entity_AmmoSpawner_Member_iAmount[] = "iAmount";

stock const ZP_Entity_PlayerSpawner[] = "zp_player_spawner";
stock const ZP_Entity_PlayerSpawner_Member_iTeam[] = "iTeam";

stock const ZP_Entity_SurvivorSpawner[] = "info_player_team1";
stock const ZP_Entity_ZombieSpawner[] = "info_player_team2";

stock const ZP_Entity_EndRoundTrigger[] = "trigger_endround";
stock const ZP_Entity_EndRoundTrigger_Member_iPlayerFlags[] = "iPlayerFlags";

stock const ZP_Entity_Grenade_Method_TumbleThink[] = "TumbleThink";
stock const ZP_Entity_Grenade_Method_BounceTouch[] = "BounceTouch";
stock const ZP_Entity_Grenade_Method_Detonate[] = "Detonate";
stock const ZP_Entity_Grenade_Method_DetonateDestroy[] = "DetonateDestroy";

stock const ZP_Entity_Grenade_Member_flDetonateDelay[] = "flDetonateDelay";
stock const ZP_Entity_Grenade_Member_flDetonateTime[] = "flDetonateTime";
stock const ZP_Entity_Grenade_Member_flNextBounceDamage[] = "flNextBounceDamage";
stock const ZP_Entity_Grenade_Member_flDamage[] = "flDamage";

stock const ZP_Entity_SatchelCharge_Member_flDamage[] = "flDamage";
stock const ZP_Entity_SatchelCharge_Member_pRemote[] = "pRemote";
stock const ZP_Entity_SatchelCharge_Member_flNextBlink[] = "flNextBlink";

stock const ZP_Entity_SatchelCharge_Method_Detonate[] = "Detonate";
stock const ZP_Entity_SatchelCharge_Method_DetonateUse[] = "DetonateUse";
stock const ZP_Entity_SatchelCharge_Method_Deactivate[] = "Deactivate";
stock const ZP_Entity_SatchelCharge_Method_SatchelChargeSlide[] = "SatchelChargeSlide";
stock const ZP_Entity_SatchelCharge_Method_SatchelChargeThink[] = "SatchelChargeThink";
stock const ZP_Entity_SatchelCharge_Method_DetonateDestroy[] = "DetonateDestroy";
stock const ZP_Entity_SatchelCharge_Method_Blink[] = "Blink";

stock const ZP_Entity_Breakable_Member_iSpawnObject[] = "iSpawnObject";
stock const ZP_Entity_Breakable_Method_SpawnObject[] = "SpawnObject";

stock const ZP_Entity_Button_Method_IsUsable[] = "IsUsable";
stock const ZP_Entity_Button_Member_bHumanOnly[] = "bHumanOnly";

stock const ZP_Entity_LightCone_Method_CreateLight[] = "CreateLight";
stock const ZP_Entity_LightCone_Member_flNextLightUpdate[] = "flNextLightUpdate";

stock const ZP_Entity_Train_Member_szFirstTarget[] = "szFirstTarget";
stock const ZP_Entity_Train_Member_flSpeed[] = "flSpeed";

stock const ZP_Entity_AmbientGeneric_Member_bStartSilent[] = "bStartSilent";

stock const ZP_Entity_Button_Member_pfnUse[] = "pfnUse";
stock const ZP_Entity_Button_Member_pfnThink[] = "pfnThink";

/*--------------------------------[ Weapons ]--------------------------------*/

stock const ZP_Weapon_Base[] = "zombiepanic/v100/weapon_base";
stock const ZP_Weapon_Pistol[] = "zombiepanic/v100/weapon_9mmhandgun";
stock const ZP_Weapon_Rifle[] = "zombiepanic/v100/weapon_556AR";
stock const ZP_Weapon_Shotgun[] = "zombiepanic/v100/weapon_shotgun";
stock const ZP_Weapon_Magnum[] = "zombiepanic/v100/weapon_357";
stock const ZP_Weapon_Grenade[] = "zombiepanic/v100/weapon_handgrenade";
stock const ZP_Weapon_Satchel[] = "zombiepanic/v100/weapon_satchel";
stock const ZP_Weapon_Swipe[] = "zombiepanic/v100/weapon_swipe";
stock const ZP_Weapon_Crowbar[] = "zombiepanic/v100/weapon_crowbar";

/*--------------------------------[ Weapon Methods and Members ]--------------------------------*/

stock const ZP_Weapon_Base_Member_bInUnload[] = "bInUnload";
stock const ZP_Weapon_Base_Member_iUnloadAmount[] = "iUnloadAmount";
stock const ZP_Weapon_Base_Member_flWeight[] = "flWeight";
stock const ZP_Weapon_Base_Member_szBounceSound[] = "szBounceSound";

stock const ZP_Weapon_Base_Method_CanUnload[] = "CanUnload";
stock const ZP_Weapon_Base_Method_Unload[] = "Unload";
stock const ZP_Weapon_Base_Method_CompleteUnload[] = "CompleteUnload";
stock const ZP_Weapon_Base_Method_DefaultUnload[] = "DefaultUnload";
stock const ZP_Weapon_Base_Method_HitTextureEffect[] = "HitTextureEffect";

stock const ZP_Weapon_Satchel_Method_UpdateRemoteState[] = "UpdateRemoteState";
stock const ZP_Weapon_Satchel_Method_ShouldUseRemote[] = "ShouldUseRemote";
stock const ZP_Weapon_Satchel_Method_ActivateCharges[] = "ActivateCharges";
stock const ZP_Weapon_Satchel_Method_ThrowCharge[] = "ThrowCharge";

stock const ZP_Weapon_Satchel_Member_bUseRemote[] = "bUseRemote";
stock const ZP_Weapon_Satchel_Member_iChargesNum[] = "iChargesNum";

/*--------------------------------[ Ammo ]--------------------------------*/

stock const ZP_AmmoGroup[] = "zombiepanic";
stock const ZP_Ammo_Pistol[] = "zombiepanic-pistol";
stock const ZP_Ammo_Rifle[] = "zombiepanic-rifle";
stock const ZP_Ammo_Shotgun[] = "zombiepanic-shotgun";
stock const ZP_Ammo_Magnum[] = "zombiepanic-magnum";
stock const ZP_Ammo_Grenade[] = "zombiepanic-grenade";
stock const ZP_Ammo_Satchel[] = "zombiepanic-satchel";
stock const ZP_Ammo_ZombiesValue[] = "zombiepanic-zombies-value";

/*--------------------------------[ Assets ]--------------------------------*/

stock const ZP_AssetLibrary[] = "zombiepanic";

stock const ZP_Asset_Model_FlashlightLightcone[] = "flashlight.lightcone.model";
stock const ZP_Asset_Model_Weaponbox[] = "items.weaponbox.model";
stock const ZP_Asset_Model_SwipeView[] = "weapons.swipe.models.view";
stock const ZP_Asset_Model_PistolView[] = "weapons.pistol.models.view";
stock const ZP_Asset_Model_PistolPlayer[] = "weapons.pistol.models.player";
stock const ZP_Asset_Model_Pistol[] = "weapons.pistol.models.world";
stock const ZP_Asset_Model_MagnumView[] = "weapons.magnum.models.view";
stock const ZP_Asset_Model_MagnumPlayer[] = "weapons.magnum.models.player";
stock const ZP_Asset_Model_Magnum[] = "weapons.magnum.models.world";
stock const ZP_Asset_Model_RifleView[] = "weapons.rifle.models.view";
stock const ZP_Asset_Model_RiflePlayer[] = "weapons.rifle.models.player";
stock const ZP_Asset_Model_Rifle[] = "weapons.rifle.models.world";
stock const ZP_Asset_Model_ShotgunView[] = "weapons.shotgun.models.view";
stock const ZP_Asset_Model_ShotgunPlayer[] = "weapons.shotgun.models.player";
stock const ZP_Asset_Model_Shotgun[] = "weapons.shotgun.models.world";
stock const ZP_Asset_Model_CrowbarView[] = "weapons.crowbar.models.view";
stock const ZP_Asset_Model_CrowbarPlayer[] = "weapons.crowbar.models.player";
stock const ZP_Asset_Model_Crowbar[] = "weapons.crowbar.models.world";
stock const ZP_Asset_Model_GrenadeView[] = "weapons.grenade.models.view";
stock const ZP_Asset_Model_GrenadePlayer[] = "weapons.grenade.models.player";
stock const ZP_Asset_Model_Grenade[] = "weapons.grenade.models.world";
stock const ZP_Asset_Model_SatchelView[] = "weapons.satchel.models.view";
stock const ZP_Asset_Model_SatchelPlayer[] = "weapons.satchel.models.player";
stock const ZP_Asset_Model_Satchel[] = "weapons.satchel.models.world";
stock const ZP_Asset_Model_SatchelRadioView[] = "weapons.satchel-radio.models.view";
stock const ZP_Asset_Model_SatchelRadioPlayer[] = "weapons.satchel-radio.models.player";
stock const ZP_Asset_Model_SatchelRadio[] = "weapons.satchel-radio.models.world";
stock const ZP_Asset_Model_ItemMedkit[] = "items.medkit.model";
stock const ZP_Asset_Model_ItemArmor[] = "items.armor.model";
stock const ZP_Asset_Model_AmmoPistol[] = "ammo.pistol.models.clip";
stock const ZP_Asset_Model_AmmoRifle[] = "ammo.rifle.models.clip";
stock const ZP_Asset_Model_AmmoShotgun[] = "ammo.shotgun.models.clip";
stock const ZP_Asset_Model_AmmoMagnum[] = "ammo.magnum.models.clip";
stock const ZP_Asset_Model_AmmoRifleBox[] = "ammo.rifle.models.box";
stock const ZP_Asset_Model_LightCone[] = "flashlight.lightcone.model";
stock const ZP_Asset_Model_Shell[] = "shell-model";
stock const ZP_Asset_Model_ShotgunShell[] = "shotgun-shell-model";
stock const ZP_Asset_Model_Survivor[] = "player.survivor.model";
stock const ZP_Asset_Model_Zombie[] = "player.zombie.model";

stock const ZP_Asset_Sprite_ObjectiveMark[] = "objective-mark-sprite";
stock const ZP_Asset_Sprite_SatchelChargeGlow[] = "entities.satchel-charge.sprites.glow";

stock const ZP_Asset_Sound_Transformation[] = "player.transformation-sound";
stock const ZP_Asset_Sound_Flashlight[] = "flashlight.sound";
stock const ZP_Asset_Sound_ShotgunShot[] = "weapons.shotgun.sounds.shot";
stock const ZP_Asset_Sound_ShotgunPump[] = "weapons.shotgun.sounds.pump";
stock const ZP_Asset_Sound_CrowbarMiss[] = "weapons.crowbar.sounds.miss";
stock const ZP_Asset_Sound_PistolShot[] = "weapons.pistol.sounds.shot";
stock const ZP_Asset_Sound_MagnumShot[] = "weapons.magnum.sounds.shot";
stock const ZP_Asset_Sound_RifleShot[] = "weapons.rifle.sounds.shot";
stock const ZP_Asset_Sound_ShotgunReload[] = "weapons.shotgun.sounds.reload";
stock const ZP_Asset_Sound_SwipeMiss[] = "weapons.swipe.sounds.miss";
stock const ZP_Asset_Sound_SwipeHit[] = "weapons.swipe.sounds.hit";
stock const ZP_Asset_Sound_CrowbarHitbody[] = "weapons.crowbar.sounds.hitbody";
stock const ZP_Asset_Sound_CrowbarHit[] = "weapons.crowbar.sounds.hit";
stock const ZP_Asset_Sound_CrowbarHitSoft[] = "weapons.crowbar.sounds.hit-soft";
stock const ZP_Asset_Sound_GrenadeBounce[] = "weapons.grenade.sounds.bounce";
stock const ZP_Asset_Sound_GrenadeFuse[] = "weapons.grenade.sounds.fuse";
stock const ZP_Asset_Sound_SatchelRadioPress[] = "weapons.satchel-radio.sounds.press";
stock const ZP_Asset_Sound_SatchelRadioBlip[] = "weapons.satchel-radio.sounds.blip";
stock const ZP_Asset_Sound_SatchelChargeBlip[] = "entities.satchel-charge.sounds.blip";
stock const ZP_Asset_Sound_Startup[] = "startup-sound";
stock const ZP_Asset_Sound_SurvivorDeath[] = "player.survivor.sounds.death";
stock const ZP_Asset_Sound_ZombieDeath[] = "player.zombie.sounds.death";
stock const ZP_Asset_Sound_ZombiePress[] = "player.zombie.sounds.press";
stock const ZP_Asset_Sound_SurvivorScream[] = "player.survivor.sounds.scream";
stock const ZP_Asset_Sound_ZombieIdle[] = "player.zombie.sounds.idle";
stock const ZP_Asset_Sound_PlayerJolt[] = "player.jolt-sound";
stock const ZP_Asset_Sound_ItemMedkit[] = "items.medkit.sound";
stock const ZP_Asset_Sound_ItemArmor[] = "items.armor.sound";
stock const ZP_Asset_Sound_RoundStart[] = "round-start-sound";
stock const ZP_Asset_Sound_SurvivorsWin[] = "survivors-win-sound";
stock const ZP_Asset_Sound_ZombiesWin[] = "zombies-win-sound";
stock const ZP_Asset_Sound_RoundDraw[] = "round-draw-sound";
stock const ZP_Asset_Sound_ZombieVisionOn[] = "zombie-vision.on-sound";
stock const ZP_Asset_Sound_ZombieVisionOff[] = "zombie-vision.off-sound";
stock const ZP_Asset_Sound_WeaponBoxBounce[] = "items.weaponbox.sounds.bounce";

stock const ZP_Asset_Variable_flPistolWeight[] = "weapons.pistol.weight";
stock const ZP_Asset_Variable_flMagnumWeight[] = "weapons.magnum.weight";
stock const ZP_Asset_Variable_flRifleWeight[] = "weapons.rifle.weight";
stock const ZP_Asset_Variable_flShotgunWeight[] = "weapons.shotgun.weight";
stock const ZP_Asset_Variable_flGrenadeWeight[] = "weapons.grenade.weight";
stock const ZP_Asset_Variable_flSatchelWeight[] = "weapons.satchel.weight";
stock const ZP_Asset_Variable_flCrowbarWeight[] = "weapons.crowbar.weight";
stock const ZP_Asset_Variable_flPistolAmmoWeight[] = "ammo.pistol.weight";
stock const ZP_Asset_Variable_flRifleAmmoWeight[] = "ammo.rifle.weight";
stock const ZP_Asset_Variable_flShotgunAmmoWeight[] = "ammo.shotgun.weight";
stock const ZP_Asset_Variable_flMagnumAmmoWeight[] = "ammo.magnum.weight";

stock const ZP_Asset_Music[] = "music";

/*--------------------------------[ States ]--------------------------------*/

stock const ZP_StateContext_Infection[] = "zombiepanic-infection";
stock const ZP_StateContext_Panic[] = "zombiepanic-panic";

/*--------------------------------[ Events ]--------------------------------*/

stock const ZP_Event_GameRules_PlayerRespawn[] = "zombiepanic-gamerules-player-respawn";
stock const ZP_Event_GameRules_PlayerRespawned[] = "zombiepanic-gamerules-player-respawned";
stock const ZP_Event_GameRules_GameStart[] = "zombiepanic-gamerules-game-start";
stock const ZP_Event_GameRules_GameEnd[] = "zombiepanic-gamerules-game-end";
stock const ZP_Event_GameRules_CheckWinConditions[] = "zombiepanic-gamerules-check-win-conditions";
stock const ZP_Event_GameRules_RoundExpired[] = "zombiepanic-gamerules-round-expired";
stock const ZP_Event_GameRules_GameInit[] = "zombiepanic-gamerules-game-init";
stock const ZP_Event_GameRules_TeamPreferenceChanged[] = "zombiepanic-gamerules-team-preference-changed";
stock const ZP_Event_GameRules_VariableChanged[] = "zombiepanic-gamerules-variable-changed";

stock const ZP_Event_GameMode_Activated[] = "zombiepanic-gamemode-activated";
stock const ZP_Event_GameMode_Deactivated[] = "zombiepanic-gamemode-deactivated";

stock const ZP_Event_UsePickup_Hover[] = "zombiepanic-use-pickup-hover";

stock const ZP_Event_Panic_Start[] = "zombiepanic-panic-start";
stock const ZP_Event_Panic_End[] = "zombiepanic-panic-end";

stock const ZP_Event_Infection_Set[] = "zombiepanic-infection-set";
stock const ZP_Event_Infection_Reset[] = "zombiepanic-infection-reset";

stock const ZP_Event_BaseRole_UpdateInventoryWeight[] = "zombiepanic-base-role-update-inventory-weight";

stock const ZP_Event_BaseRole_UpdateModel[] = "zombiepanic-base-role-update-model";
stock const ZP_Event_BaseRole_PlaySound[] = "zombiepanic-base-role-play-sound";

/*--------------------------------[ Game Modes ]--------------------------------*/

stock const ZP_GameMode_Survival[] = "survival";
stock const ZP_GameMode_Objective[] = "objective";

stock const ZP_GameMode_Objective_State_bObjectiveCompleted[] = "bObjectiveCompleted";

stock const ZP_Ammo_Metadata_szName[] = "szName";
stock const ZP_Ammo_Metadata_flWeight[] = "flWeight";
stock const ZP_Ammo_Metadata_iPackSize[] = "iPackSize";
stock const ZP_Ammo_Metadata_szPackModel[] = "szPackModel";
stock const ZP_Ammo_Metadata_iSequence[] = "iSequence";
stock const ZP_Ammo_Metadata_szBounceSound[] = "szBounceSound";

/*--------------------------------[ Misc ]--------------------------------*/

stock const ZP_Sprite_ObjectiveMark[] = "sprites/zombiepanic/v100/objective_mark.spr";

/*--------------------------------[ Dictionary ]--------------------------------*/

stock const ZP_Dictionary[] = "zombiepanic.txt";

stock const ZP_DictionaryKey_InfectionWarningTitle[]  = "ZP_WARN_INFECTION_TITLE";
stock const ZP_DictionaryKey_InfectionWarningInfector[]  = "ZP_WARN_INFECTOR";

stock const ZP_DictionaryKey_Survival_ObjectiveTitle[]  = "ZP_OBJECTIVE_TITLE";
stock const ZP_DictionaryKey_Survival_ObjectiveZombie[]  = "ZP_OBJECTIVE_ZOMBIE";
stock const ZP_DictionaryKey_Survival_ObjectiveHuman[]  = "ZP_OBJECTIVE_HUMAN";

stock const ZP_DictionaryKey_Objective_ObjectiveTitle[]  = "ZP_OBJECTIVE_TITLE";
stock const ZP_DictionaryKey_Objective_ObjectiveZombie[]  = "ZP_OBJECTIVE_ZOMBIE";
stock const ZP_DictionaryKey_Objective_ObjectiveHuman[]  = "ZP_OBJECTIVE_HUMAN";

stock const ZP_DictionaryKey_HintTitle[]  = "ZP_HINT_TITLE";
stock const ZP_DictionaryKey_HintPanic[]  = "ZP_HINT_PANIC";
stock const ZP_DictionaryKey_HintDropAmmo[]  = "ZP_HINT_DROP_AMMO";
stock const ZP_DictionaryKey_HintPickup[]  = "ZP_HINT_PICKUP";
stock const ZP_DictionaryKey_WarningTitle[]  = "ZP_WARN_TITLE";
stock const ZP_DictionaryKey_SpeedWarning[]  = "ZP_WARN_SPEED";
stock const ZP_DictionaryKey_ItemPickupTitle[]  = "ZP_ITEM_PICKUP_TITLE";
stock const ZP_DictionaryKey_ItemPickup[]  = "ZP_ITEM_PICKUP";
stock const ZP_DictionaryKey_RespawnTitle[]  = "ZP_RESPAWN_TITLE";
stock const ZP_DictionaryKey_RespawnNoLives[]  = "ZP_RESPAWN_NOLIVES";
stock const ZP_DictionaryKey_RespawnZombie[]  = "ZP_RESPAWN_ZOMBIE";
stock const ZP_DictionaryKey_RespawnHuman[]  = "ZP_RESPAWN_HUMAN";
