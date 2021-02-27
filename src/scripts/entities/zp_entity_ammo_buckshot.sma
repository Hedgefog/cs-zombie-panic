#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] ammo_buckshot"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "ammo_buckshot"
#define ZP_AMMO_TYPE ZP_AMMO_SHOTGUN

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Touch, "weaponbox", "OnWeaponBoxTouch_Post", .Post = 1);
}

public plugin_precache() {
    CE_Register(ENTITY_NAME, _, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 8.0}, _, ZP_AMMO_RESPAWN_TIME);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "OnSpawn");
}

public OnSpawn(pEntity) {
    if (UTIL_CanItemRespawn(pEntity)) {
        new pWeaponBox = UTIL_CreateZpAmmoBox(ZP_Ammo_GetHandler(ZP_AMMO_TYPE));
        UTIL_InitWithSpawner(pWeaponBox, pEntity);
    } else {
        CE_Kill(pEntity);
    }
}

public OnWeaponBoxTouch_Post(pEntity) {
    if (pev(pEntity, pev_flags) & FL_KILLME) {
        UTIL_SetupSpawnerRespawn(pEntity);
    }
}
