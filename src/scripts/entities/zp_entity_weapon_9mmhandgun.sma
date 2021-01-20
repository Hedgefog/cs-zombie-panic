#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <api_custom_weapons>
#include <api_custom_entities>

#include <zombiepanic>

#define PLUGIN "[Entity] weapon_9mmhandgun"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "weapon_9mmhandgun"

new CW:g_iCwHandler;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public plugin_precache() {
    g_iCwHandler = CW_GetHandler(ZP_WEAPON_PISTOL);
    if (g_iCwHandler == CW_INVALID_HANDLER) {
        return;
    }

    CE_Register(
        .szName = ENTITY_NAME,
        .vMins = Float:{-8.0, -8.0, 0.0},
        .vMaxs = Float:{8.0, 8.0, 8.0}
    );

    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "OnSpawn");
}

public OnSpawn(pEntity) {
    new Float:vecOrigin[3];
    pev(pEntity, pev_origin, vecOrigin);

    new Float:vecAngles[3];
    pev(pEntity, pev_angles, vecAngles);

    new iWeaponBox = CW_SpawnWeaponBox(g_iCwHandler);
    engfunc(EngFunc_SetOrigin, iWeaponBox, vecOrigin);
    set_pev(iWeaponBox, pev_angles, vecAngles);
}
