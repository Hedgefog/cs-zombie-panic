
#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_custom_entities>

#include <zombiepanic>

#define PLUGIN "[Entity] func_vip_safetyzone"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "func_vip_safetyzone"

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public plugin_precache() {
    RegisterHam(Ham_Spawn, ENTITY_NAME, "OnSpawn_Post", .Post = 1);
}

public OnSpawn_Post(pEntity) {
    new szModel[32];
    pev(pEntity, pev_model, szModel, charsmax(szModel));

    new Float:vecOrigin[3];
    pev(pEntity, pev_origin, vecOrigin);

    engfunc(EngFunc_RemoveEntity, pEntity);

    new iEndroundTrigger = CE_Create("trigger_endround", vecOrigin, .temp = false);
    dllfunc(DLLFunc_Spawn, iEndroundTrigger);
    engfunc(EngFunc_SetModel, iEndroundTrigger, szModel);
    set_pev(iEndroundTrigger, pev_spawnflags, (1<<0));

    return HAM_HANDLED;
}
