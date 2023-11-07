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

new CE:g_iCeHandler;

public plugin_precache() {
    g_iCeHandler = CE_Register(ENTITY_NAME);
    CE_RegisterHook(CEFunction_Init, ENTITY_NAME, "@Entity_Init");
    CE_RegisterHook(CEFunction_Spawned, ENTITY_NAME, "@Entity_Spawned");
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

@Entity_Init(this) {
    UTIL_InitAmmoEntity(this);
}

@Entity_Spawned(this) {
    set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_Think(this) {
    UTIL_AmmoEntityThink(this, ZP_AMMO_TYPE);
}
