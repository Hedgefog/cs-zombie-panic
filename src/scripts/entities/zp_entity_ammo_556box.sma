#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] ammo_556box"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "ammo_556box"
#define ZP_AMMO_TYPE ZP_AMMO_RIFLE
#define AMMO_BOX_MODEL "models/w_chainammo.mdl"

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Touch, "weaponbox", "OnWeaponBoxTouch_Post", .Post = 1);
}

public plugin_precache() {
    precache_model(AMMO_BOX_MODEL);

    CE_Register(ENTITY_NAME, _, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 8.0}, _, ZP_AMMO_RESPAWN_TIME);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "OnSpawn");
}

public OnSpawn(pEntity) {
    if (ZP_GameRules_CanItemRespawn(pEntity)) {
        new iAmmoHandler = ZP_Ammo_GetHandler(ZP_AMMO_TYPE);
        new iAmount = ZP_Ammo_GetPackSize(iAmmoHandler) * 5;

        new pWeaponBox = UTIL_CreateZpAmmoBox(iAmmoHandler, iAmount);
        engfunc(EngFunc_SetModel, pWeaponBox, AMMO_BOX_MODEL);
        UTIL_InitWithSpawner(pWeaponBox, pEntity);

        set_pev(pWeaponBox, pev_owner, pEntity);
    } else {
        CE_Kill(pEntity);
    }
}

public OnWeaponBoxTouch_Post(pEntity) {
    if (pev(pEntity, pev_flags) & FL_KILLME) {
        UTIL_SetupSpawnerRespawn(pEntity);
    }
}
