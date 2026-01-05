#if defined _zombiepanic_internal_included
  #endinput
#endif

#define _zombiepanic_internal_included

#include <zombiepanic_const>

/*--------------------------------[ Utils ]--------------------------------*/

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

/*--------------------------------[ Entities ]--------------------------------*/

// #define WEAPONBOX_ENTITY "weaponbox"
// #define BREAKABLE_ENTITY "func_breakable"
// #define BUTTON_ENTITY "func_button"
// #define TRAIN_ENTITY "func_train"
// #define DOOR_ENTITY "func_door"

/*--------------------------------[ Core ]--------------------------------*/

#define NAMESPACE(%1) ZP_%1
#define NAMESPACE_FIELD<%1>(%2) NAMESPACE(%1)_%2

#define ENTITY(%1) NAMESPACE_FIELD<Entity>(%1)
#define ENTITY_DATA<%1>(%2,%3) ENTITY(%2)_%1_%3
#define ENTITY_METHOD<%1>(%2) ENTITY_DATA<Method>(%1,%2)
#define ENTITY_MEMBER<%1>(%2) ENTITY_DATA<Member>(%1,%2)

#define PLAYER_ROLE(%1) NAMESPACE_FIELD<PlayerRole>(%1)
#define PLAYER_ROLE_GROUP NAMESPACE(PlayerRoleGroup)
#define PLAYER_ROLE_DATA<%1>(%2,%3) PLAYER_ROLE(%2)_%1_%3
#define PLAYER_ROLE_METHOD<%1>(%2) PLAYER_ROLE_DATA<Method>(%1,%2)
#define PLAYER_ROLE_MEMBER<%1>(%2) PLAYER_ROLE_DATA<Member>(%1,%2)

#define WEAPON(%1) NAMESPACE_FIELD<Weapon>(%1)
#define WEAPON_ID(%1) NAMESPACE_FIELD<WeaponId>(%1)
#define WEAPON_DATA<%1>(%2,%3) WEAPON(%2)_%1_%3
#define WEAPON_METHOD<%1>(%2) WEAPON_DATA<Method>(%1,%2)
#define WEAPON_MEMBER<%1>(%2) WEAPON_DATA<Member>(%1,%2)

#define AMMO(%1) NAMESPACE_FIELD<Ammo>(%1)
#define AMMO_METADATA(%1) NAMESPACE_FIELD<Ammo_Metadata>(%1)
#define AMMO_GROUP NAMESPACE(AmmoGroup)

#define TEAM(%1) NAMESPACE_FIELD<Team>(%1)

#define ASSET(%1) NAMESPACE_FIELD<Asset>(%1)
#define ASSET_LIBRARY NAMESPACE(AssetLibrary)
#define ASSET_MODEL(%1) ASSET(Model_%1)
#define ASSET_SOUND(%1) ASSET(Sound_%1)
#define ASSET_SPRITE(%1) ASSET(Sprite_%1)
#define ASSET_VARIABLE(%1) ASSET(Variable_%1)

#define STATE_CONTEXT(%1) NAMESPACE_FIELD<StateContext>(%1)
#define STATE<%1>(%2) NAMESPACE_FIELD<State>(%1)_%2
#define STATE_TYPE(%1) NAMESPACE_FIELD<State>(%1)

#define EVENT(%1) NAMESPACE_FIELD<Event>(%1)

/*--------------------------------[ Libraries Shortcuts ]--------------------------------*/

#define LIBRARY(%1) NAMESPACE_FIELD<Library>(%1)

/*--------------------------------[ Infection Shortcuts ]--------------------------------*/

#define INFECTION_STATE(%1) STATE<Infection>(%1)
#define INFECTION_STATE_CONTEXT STATE_CONTEXT(Infection)
#define INFECTION_STATE_TYPE STATE_TYPE(Infection)

#define INFECTION_EVENT(%1) EVENT(Infection_%1)

/*--------------------------------[ Panic Shortcuts ]--------------------------------*/

#define PANIC_STATE(%1) STATE<Panic>(%1)
#define PANIC_STATE_CONTEXT STATE_CONTEXT(Panic)
#define PANIC_STATE_TYPE STATE_TYPE(Panic)

#define PANIC_EVENT(%1) EVENT(Panic_%1)

/*--------------------------------[ Player Roles Shortcuts ]--------------------------------*/

#define BASE_ROLE_MEMBER(%1) PLAYER_ROLE_MEMBER<Base>(%1)
#define BASE_ROLE_METHOD(%1) PLAYER_ROLE_METHOD<Base>(%1)
#define BASE_ROLE_DROP_FLAG(%1) ZP_PlayerRole_Base_DropFlag_%1

#define BASE_ROLE_EVENT(%1) EVENT(BaseRole_%1)
#define BASE_ROLE_SOUND(%1) PLAYER_ROLE(Base)_Sound_%1

#define SURVIVOR_MEMBER(%1) PLAYER_ROLE_MEMBER<Survivor>(%1)
#define SURVIVOR_METHOD(%1) PLAYER_ROLE_METHOD<Survivor>(%1)

#define ZOMBIE_MEMBER(%1) PLAYER_ROLE_MEMBER<Zombie>(%1)
#define ZOMBIE_METHOD(%1) PLAYER_ROLE_METHOD<Zombie>(%1)

/*--------------------------------[ Entities Shortcuts ]--------------------------------*/

#define WEAPONBOX_MEMBER(%1) ENTITY_MEMBER<WeaponBox>(%1)
#define WEAPONBOX_METHOD(%1) ENTITY_METHOD<WeaponBox>(%1)

#define WEAPONSPAWNER_MEMBER(%1) ENTITY_MEMBER<WeaponSpawner>(%1)
#define WEAPONSPAWNER_METHOD(%1) ENTITY_METHOD<WeaponSpawner>(%1)

#define AMMOSPAWNER_MEMBER(%1) ENTITY_MEMBER<AmmoSpawner>(%1)
#define AMMOSPAWNER_METHOD(%1) ENTITY_METHOD<AmmoSpawner>(%1)

#define BASESPAWNER_MEMBER(%1) ENTITY_MEMBER<BaseSpawner>(%1)
#define BASESPAWNER_METHOD(%1) ENTITY_METHOD<BaseSpawner>(%1)

#define PLAYERSPAWNER_MEMBER(%1) ENTITY_MEMBER<PlayerSpawner>(%1)
#define PLAYERSPAWNER_METHOD(%1) ENTITY_METHOD<PlayerSpawner>(%1)

#define ENDROUNDTRIGGER_MEMBER(%1) ENTITY_MEMBER<EndRoundTrigger>(%1)
#define ENDROUNDTRIGGER_METHOD(%1) ENTITY_METHOD<EndRoundTrigger>(%1)

#define BREAKABLE_MEMBER(%1) ENTITY_MEMBER<Breakable>(%1)
#define BREAKABLE_METHOD(%1) ENTITY_METHOD<Breakable>(%1)

#define BUTTON_MEMBER(%1) ENTITY_MEMBER<Button>(%1)
#define BUTTON_METHOD(%1) ENTITY_METHOD<Button>(%1)

#define LIGHTCONE_MEMBER(%1) ENTITY_MEMBER<LightCone>(%1)
#define LIGHTCONE_METHOD(%1) ENTITY_METHOD<LightCone>(%1)

#define TRAIN_MEMBER(%1) ENTITY_MEMBER<Train>(%1)
#define TRAIN_METHOD(%1) ENTITY_METHOD<Train>(%1)

#define GRENADE_MEMBER(%1) ENTITY_MEMBER<Grenade>(%1)
#define GRENADE_METHOD(%1) ENTITY_METHOD<Grenade>(%1)

#define SATCHELCHARGE_MEMBER(%1) ENTITY_MEMBER<SatchelCharge>(%1)
#define SATCHELCHARGE_METHOD(%1) ENTITY_METHOD<SatchelCharge>(%1)

#define AMBIENTGENERIC_MEMBER(%1) ENTITY_MEMBER<AmbientGeneric>(%1)
#define AMBIENTGENERIC_METHOD(%1) ENTITY_METHOD<AmbientGeneric>(%1)

/*--------------------------------[ Weapons Shortcuts ]--------------------------------*/

#define WEAPON_BASE_METHOD(%1) WEAPON_METHOD<Base>(%1)
#define WEAPON_BASE_MEMBER(%1) WEAPON_MEMBER<Base>(%1)

#define WEAPON_SATCHEL_METHOD(%1) WEAPON_METHOD<Satchel>(%1)
#define WEAPON_SATCHEL_MEMBER(%1) WEAPON_MEMBER<Satchel>(%1)

/*--------------------------------[ Gamemodes Shortcuts ]--------------------------------*/

#define GAMEMODE(%1) NAMESPACE_FIELD<GameMode>(%1)
#define GAMEMODE_CALLBACK(%1) NAMESPACE_FIELD<GameModes_Callback>(%1)
#define GAMEMODE_STATE<%1>(%2) GAMEMODE(%1)_State_%2

#define GAMEMODE_SURVIVAL_STATE(%1) GAMEMODE_STATE<Survival>(%1)
#define GAMEMODE_OBJECTIVE_STATE(%1) GAMEMODE_STATE<Objective>(%1)

#define GAMEMODE_EVENT(%1) EVENT(GameMode_%1)

/*--------------------------------[ Game Rules Shortcuts ]--------------------------------*/

#define GAMERULES_EVENT(%1) EVENT(GameRules_%1)
#define GAMEMODE_SURVIVAL_EVENT(%1) EVENT(GameMode_Survival_%1)
#define GAMERULES_VARIABLE(%1) NAMESPACE_FIELD<GameRules_Variable>(%1)

/*--------------------------------[ Weapons Shortcuts ]--------------------------------*/

#define BASEGRENADE_MEMBER(%1) Weapon_BaseThrowable_Member_%1
#define BASEGRENADE_METHOD(%1) Weapon_BaseThrowable_Method_%1

/*--------------------------------[ Use Pickup Shortcuts ]--------------------------------*/

#define USEPICKUP_EVENT(%1) EVENT(UsePickup_%1)

/*--------------------------------[ Plugin Shortcuts ]--------------------------------*/

#define PLUGIN_NAME(%1) "[Zombie Panic] " + %1
#define ENTITY_PLUGIN(%1) "[Entity] Zombie Panic " + #%1
#define ENTITY_EXTENSION_PLUGIN(%1) "[Entity Extension] Zombie Panic " + #%1
#define WEAPON_PLUGIN(%1) "[Weapon] Zombie Panic " + #%1
#define ROLE_PLUGIN(%1) "[Role] Zombie Panic " + #%1

#define CVAR(%1) "zombiepanic_" + %1

/*--------------------------------[ Dictionary Shortcuts ]--------------------------------*/

#define DICTIONARY_KEY(%1) NAMESPACE_FIELD<DictionaryKey>(%1)

#define DICTIONARY NAMESPACE(Dictionary)
