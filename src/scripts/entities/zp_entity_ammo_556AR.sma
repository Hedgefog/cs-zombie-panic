
#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>

#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] ammo_556AR"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "ammo_556AR"
#define ZP_AMMO_TYPE ZP_AMMO_RIFLE
#define AMMO_BOX_MODEL ZP_AMMO_RIFLE_MODEL

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public plugin_precache() {
    precache_model(AMMO_BOX_MODEL);
    CE_Register(ENTITY_NAME, _, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 8.0});
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "OnSpawn");
}

public OnSpawn(pEntity) {
    new Float:vecOrigin[3];
    pev(pEntity, pev_origin, vecOrigin);

    new Float:vecAngles[3];
    pev(pEntity, pev_angles, vecAngles);

    new iAmmoHandler = ZP_Ammo_GetHandler(ZP_AMMO_TYPE);
    new iWeaponBox = UTIL_CreateAmmoBox(ZP_Ammo_GetId(iAmmoHandler), ZP_Ammo_GetPackSize(iAmmoHandler));
    engfunc(EngFunc_SetOrigin, iWeaponBox, vecOrigin);
    set_pev(iWeaponBox, pev_angles, vecAngles);
    engfunc(EngFunc_SetModel, iWeaponBox, AMMO_BOX_MODEL);

    if (ZP_AMMO_RESPAWN_TIME > 0.0) {
        SetThink(pEntity, "ThinkSpawn");
        set_pev(pEntity, pev_nextthink, get_gametime() + ZP_AMMO_RESPAWN_TIME);
    }
}

public ThinkSpawn(pEntity) {
    if (pev(pEntity, pev_nextthink) > get_gametime()) {
        return;
    }

    dllfunc(DLLFunc_Spawn, pEntity);
}
