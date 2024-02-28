#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] ammo_9mmclip"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "ammo_9mmclip"
#define ZP_AMMO_TYPE ZP_AMMO_PISTOL

new CE:g_iCeHandler;

public plugin_precache() {
    g_iCeHandler = CE_Register(ENTITY_NAME);
    CE_RegisterHook(ENTITY_NAME, CEFunction_Init, "@Entity_Init");
    CE_RegisterHook(ENTITY_NAME, CEFunction_Spawned, "@Entity_Spawned");
    CE_RegisterHook(ENTITY_NAME, CEFunction_Think, "@Entity_Think");
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
