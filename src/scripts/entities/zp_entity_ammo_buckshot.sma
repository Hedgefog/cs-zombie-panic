#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] ammo_buckshot"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "ammo_buckshot"
#define ZP_AMMO_TYPE ZP_AMMO_SHOTGUN

new g_iCeHandler;

public plugin_precache() {
    g_iCeHandler = CE_Register(ENTITY_NAME, _, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 8.0}, _, ZP_AMMO_RESPAWN_TIME);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "@Entity_Spawn");
    CE_RegisterHook(CEFunction_Think, ENTITY_NAME, "@Entity_Think");
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Touch, "weaponbox", "HamHook_WeaponBox_Touch_Post", .Post = 1);
}

public HamHook_WeaponBox_Touch_Post(pEntity) {
    UTIL_HandleSpawnerItemTouch(pEntity, g_iCeHandler);

    return HAM_HANDLED;
}

@Entity_Spawn(this) {
    set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_Think(this) {
    if (ZP_GameRules_CanItemRespawn(this)) {
        new iAmmoHandler = ZP_Ammo_GetHandler(ZP_AMMO_TYPE);
        new pWeaponBox = UTIL_CreateZpAmmoBox(iAmmoHandler);
        UTIL_InitWithSpawner(pWeaponBox, this);
    } else {
        CE_Kill(this);
    }
}
