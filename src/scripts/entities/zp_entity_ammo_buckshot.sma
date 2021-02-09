#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>

#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] ammo_buckshot"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "ammo_buckshot"
#define ZP_AMMO_TYPE ZP_AMMO_SHOTGUN
#define AMMO_BOX_MODEL ZP_AMMO_SHOTGUN_MODEL

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public plugin_precache() {
    precache_model(AMMO_BOX_MODEL);
    CE_Register(ENTITY_NAME, _, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 8.0}, _, ZP_AMMO_RESPAWN_TIME);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "OnSpawn");
}

public OnSpawn(pEntity) {
    new Float:vecOrigin[3];
    pev(pEntity, pev_origin, vecOrigin);

    new Float:vecAngles[3];
    pev(pEntity, pev_angles, vecAngles);

    new iAmmoHandler = ZP_Ammo_GetHandler(ZP_AMMO_TYPE);
    new pWeaponBox = UTIL_CreateAmmoBox(ZP_Ammo_GetId(iAmmoHandler), ZP_Ammo_GetPackSize(iAmmoHandler));
    engfunc(EngFunc_SetOrigin, pWeaponBox, vecOrigin);
    set_pev(pWeaponBox, pev_angles, vecAngles);
    engfunc(EngFunc_SetModel, pWeaponBox, AMMO_BOX_MODEL);

    CE_Kill(pEntity);
}
