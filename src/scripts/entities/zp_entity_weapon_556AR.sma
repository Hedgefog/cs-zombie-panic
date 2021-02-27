#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_custom_weapons>
#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] weapon_556AR"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "weapon_556AR"

new CW:g_iCwHandler;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Touch, "weaponbox", "OnWeaponBoxTouch_Post", .Post = 1);
}

public plugin_precache() {
    g_iCwHandler = CW_GetHandler(ZP_WEAPON_RIFLE);
    if (g_iCwHandler == CW_INVALID_HANDLER) {
        return;
    }

    CE_Register(ENTITY_NAME, _, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 8.0}, _, ZP_WEAPONS_RESPAWN_TIME);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "OnSpawn");
}

public OnSpawn(pEntity) {
    new pWeaponBox = CW_SpawnWeaponBox(g_iCwHandler);
    UTIL_InitWithSpawner(pWeaponBox, pEntity);
}

public OnWeaponBoxTouch_Post(pEntity) {
    if (pev(pEntity, pev_flags) & FL_KILLME) {
        UTIL_SetupSpawnerRespawn(pEntity);
    }
}
