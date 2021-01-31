#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <zombiepanic>
#include <api_rounds>

#define PLUGIN "[Zombie Panic] Gameplay Fixes"
#define AUTHOR "Hedgehog Fog"

new const g_rgszObjectiveEntities[][] = {
    "func_bomb_target",
    "func_escapezone",
    "func_hostage_rescue",
    "func_vip_safetyzone",
    "func_buyzone",
    "hostage_entity",
    "info_bomb_target",
    "info_vip_start",
    "info_hostage_rescue",
    "monster_scientist",
    "weapon_c4"
};

new const g_rgszDelayEntities[][] = {
    "trigger_auto",
    "trigger_changetarget",
    "trigger_relay",
    "button_target",
    "func_door",
    "func_door_rotating",
    "func_button",
    "func_rotating",
    "func_rot_button",
    "func_tracktrain",
    "func_train",
    "momentary_door",
    "momentary_rot_button",
    "trigger_multiple",
    "trigger_once",
    "trigger_push"
};

new g_pCvarRoundTime;
new g_iFwEntitySpawn;
new Array:g_irgObjectiveEntities;

public plugin_precache() {
    g_irgObjectiveEntities = ArrayCreate();

    CreateHiddenBuyZone();

    g_iFwEntitySpawn = register_forward(FM_Spawn, "OnSpawn");

    RegisterHam(Ham_Spawn, "game_score", "OnGameScoreSpawn", .Post = 1);

    g_pCvarRoundTime = get_cvar_pointer("mp_roundtime");
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    unregister_forward(FM_Spawn, g_iFwEntitySpawn);

    RemoveObjectiveEntities();
}

public plugin_end() {
    ArrayDestroy(g_irgObjectiveEntities);
}

public OnGameScoreSpawn(pEntity) {
    engfunc(EngFunc_RemoveEntity, pEntity);
}

public OnSpawn(pEntity) {
    if (!pev_valid(pEntity)) {
        return FMRES_IGNORED;
    }

    if (IsObjectiveEntity(pEntity)) {
        ArrayPushCell(g_irgObjectiveEntities, pEntity);
    } else if (IsDelayEntity(pEntity)) {
        if (get_ent_data_float(pEntity, "CBaseToggle", "m_flWait") < 0.0) {
            set_ent_data_float(pEntity, "CBaseToggle", "m_flWait", get_pcvar_num(g_pCvarRoundTime) * 60.0 + 1.0);
        }
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
}

ResetButton(pEntity) {
    new szTarget[32];
    pev(pEntity, pev_target, szTarget, charsmax(szTarget));
    set_ent_data(pEntity, "CBaseToggle", "m_toggle_state", TS_AT_BOTTOM);
    dllfunc(DLLFunc_Think, pEntity);
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

bool:IsDelayEntity(pEntity) {
    new szClassname[32];
    pev(pEntity, pev_classname, szClassname, charsmax(szClassname));
    
    new iSize = sizeof(g_rgszDelayEntities);
    for (new i = 0; i < iSize; ++i) {
        if (equal(szClassname, g_rgszDelayEntities[i])) {
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

RemoveObjectiveEntities() {
    for (new i = ArraySize(g_irgObjectiveEntities) - 1; i >= 0; --i) {
        new pEntity = ArrayGetCell(g_irgObjectiveEntities, i);
        if (pev_valid(pEntity) && IsObjectiveEntity(pEntity)) {
            engfunc(EngFunc_RemoveEntity, pEntity);
        }

        ArrayDeleteItem(g_irgObjectiveEntities, i);
    }
}
