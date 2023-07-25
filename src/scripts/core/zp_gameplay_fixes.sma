#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>

#define PLUGIN "[Zombie Panic] Gameplay Fixes"
#define AUTHOR "Hedgehog Fog"

#define AMBIENT_SOUND_START_SILENT (1<<4)

new const g_rgszObjectiveEntities[][] = {
    "func_bomb_target",
    "func_escapezone",
    "func_hostage_rescue",
    // "func_vip_safetyzone", // trigger_endround alias
    "func_buyzone",
    "hostage_entity",
    "info_bomb_target",
    "info_vip_start",
    "info_hostage_rescue",
    "monster_scientist",
    "weapon_c4"
};

new g_pFwEntitySpawn;

public plugin_precache() {
    CreateHiddenBuyZone();

    g_pFwEntitySpawn = register_forward(FM_Spawn, "FMHook_Spawn");
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    unregister_forward(FM_Spawn, g_pFwEntitySpawn);
}

public FMHook_Spawn(pEntity) {
    if (!pev_valid(pEntity)) {
        return FMRES_IGNORED;
    }

    if (IsObjectiveEntity(pEntity)) {
        engfunc(EngFunc_RemoveEntity, pEntity);
    }

    return FMRES_IGNORED;
}

public Round_Fw_RoundStart() {
    ResetEntities();
}

ResetEntities() {
    new pEntity = 0;

    while((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "func_button")) > 0) {
        ResetButton(pEntity);
    }

    while((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "func_door")) > 0) {
        ResetDoor(pEntity);
    }

    while((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "func_wall_toggle")) > 0) {
        ResetWallToggle(pEntity);
    }

    while((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "multi_manager")) > 0) {
        ResetMultiManager(pEntity);
    }

    while((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "multisource")) > 0) {
        ResetMultiSource(pEntity);
    }

    while((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "ambient_generic")) > 0) {
        ResetAmbientGeneric(pEntity);
    }
}

ResetButton(pEntity) {
    new szTarget[32];
    pev(pEntity, pev_target, szTarget, charsmax(szTarget));
    set_ent_data(pEntity, "CBaseToggle", "m_toggle_state", TS_AT_BOTTOM);
    dllfunc(DLLFunc_Think, pEntity);
}

ResetAmbientGeneric(pEntity) {
    new szSound[128];
    pev(pEntity, pev_message, szSound, charsmax(szSound));

    new Float:vecOrigin[3];
    pev(pEntity, pev_origin, vecOrigin);

    new iSpawnFlags = pev(pEntity, pev_spawnflags);
    new bool:bStartSilent = !!(iSpawnFlags & AMBIENT_SOUND_START_SILENT);

    if (!bStartSilent) {
        set_pev(pEntity, pev_spawnflags, iSpawnFlags | AMBIENT_SOUND_START_SILENT);
    }

    engfunc(EngFunc_EmitAmbientSound, pEntity, vecOrigin, szSound, 0, 0, SND_STOP, 0);
    dllfunc(DLLFunc_Spawn, pEntity);

    if (!bStartSilent) {
        ExecuteHamB(Ham_Use, pEntity, 0, 0, USE_TOGGLE, 0.0);
        set_pev(pEntity, pev_spawnflags, iSpawnFlags & ~AMBIENT_SOUND_START_SILENT);
    }
}

ResetDoor(pEntity) {
    dllfunc(DLLFunc_Think, pEntity);
}

ResetMultiSource(pEntity) {
    for(new i = 0; i < 32; i++) {
        set_ent_data(pEntity, "CMultiSource", "m_rgTriggered", 0, i);
    }
}

ResetWallToggle(pEntity) {
    dllfunc(DLLFunc_Spawn, pEntity);
}

ResetMultiManager(pEntity) {
    ExecuteHamB(Ham_CS_Restart, pEntity);
}

bool:IsObjectiveEntity(pEntity) {
    new szClassname[32];
    pev(pEntity, pev_classname, szClassname, charsmax(szClassname));
    
    new iSize = sizeof(g_rgszObjectiveEntities);
    for (new i = 0; i < iSize; ++i) {
        if (equal(szClassname, g_rgszObjectiveEntities[i])) {
            return true;
        }
    }

    return false;
}

CreateHiddenBuyZone() {
    new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
    dllfunc(DLLFunc_Spawn, pEntity);
    engfunc(EngFunc_SetSize, pEntity, {-8192.0, -8192.0, -8192.0}, {-8191.0, -8191.0, -8191.0});
}
