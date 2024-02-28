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

new CE:g_iCeHandler;

public plugin_precache() {
    precache_model(AMMO_BOX_MODEL);

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
    if (pev(this, pev_deadflag) != DEAD_NO) return;

    if (ZP_GameRules_CanItemRespawn(this)) {
        new iAmmoHandler = ZP_Ammo_GetHandler(ZP_AMMO_TYPE);
        new pWeaponBox = UTIL_CreateZpAmmoBox(iAmmoHandler, ZP_Ammo_GetPackSize(iAmmoHandler) * 5);
        UTIL_InitWithSpawner(pWeaponBox, this);
        engfunc(EngFunc_SetModel, pWeaponBox, AMMO_BOX_MODEL);
    } else {
        CE_Kill(this);
    }
}
