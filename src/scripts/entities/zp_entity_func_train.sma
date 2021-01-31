#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_rounds>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] func_train"
#define AUTHOR "Hedgehog Fog"

enum _:Train {
    Train_Id,
    Train_FirstTarget[32]
}

new Array:g_iTrainEntity;
new Array:g_fTrainSpeed;
new Array:g_szTrainFirstTarget;
new g_iTrainEntityCount = 0;

public plugin_precache() {
    g_iTrainEntity = ArrayCreate(1, 1);
    g_fTrainSpeed = ArrayCreate(1, 1);
    g_szTrainFirstTarget = ArrayCreate(32, 1);

    RegisterHam(Ham_Spawn, "func_train", "OnSpawn", .Post = 0);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public plugin_destroy() {
    ArrayDestroy(g_iTrainEntity);
    ArrayDestroy(g_fTrainSpeed);
    ArrayDestroy(g_szTrainFirstTarget);
}

public OnSpawn(pEntity) {
    if (!pev_valid(pEntity)) {
            return HAM_IGNORED;
    }

    new szTarget[32];
    pev(pEntity, pev_target, szTarget, charsmax(szTarget));

    new Float:flSpeed;
    pev(pEntity, pev_speed, flSpeed);

    ArrayPushCell(g_iTrainEntity, pEntity);
    ArrayPushCell(g_fTrainSpeed, flSpeed);
    ArrayPushString(g_szTrainFirstTarget, szTarget);

    g_iTrainEntityCount++;

    return HAM_HANDLED;
}

public Round_Fw_RoundStart() {
    for (new i = 0; i < g_iTrainEntityCount; ++i) {
        Reset(i);
    }
}

Reset(iIndex) {
    new pEntity = ArrayGetCell(g_iTrainEntity, iIndex);

    static szTarget[32];
    ArrayGetString(g_szTrainFirstTarget, iIndex, szTarget, charsmax(szTarget));
    new target = engfunc(EngFunc_FindEntityByString, -1, "targetname", szTarget);
    pev(target, pev_target, szTarget, charsmax(szTarget));
    set_pev(pEntity, pev_target, szTarget);

    set_pev(pEntity, pev_velocity, NULL_VECTOR);
    set_pev(pEntity, pev_avelocity, NULL_VECTOR);
    set_pev(pEntity, pev_enemy, 0);
    set_pev(pEntity, pev_message, 0);
    set_pev(pEntity, pev_spawnflags, pev(pEntity, pev_spawnflags) | SF_TRAIN_WAIT_RETRIGGER);
    set_pev(pEntity, pev_nextthink, 0);
    set_pev(pEntity, pev_speed, ArrayGetCell(g_fTrainSpeed, iIndex));
    
    set_ent_data(pEntity, "CFuncTrain", "m_activated", 0);
    // set_ent_data_entity(pEntity, "CFuncTrain", "m_pevCurrentTarget", pev(pEntity, pev_target));
    set_ent_data(pEntity, "CBaseToggle", "m_pfnCallWhenMoveDone", 0);
    set_ent_data_vector(pEntity, "CBaseToggle", "m_vecFinalDest", Float:{0.0, 0.0, 0.0});
    set_ent_data_vector(pEntity, "CBaseToggle", "m_vecFinalAngle", Float:{0.0, 0.0, 0.0});
    
    static szNoiseSound[32];
    pev(pEntity, pev_noise, szNoiseSound, charsmax(szNoiseSound));
    emit_sound(pEntity, CHAN_STATIC, szNoiseSound, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
    
    set_ent_data(pEntity, "CBaseEntity", "m_pfnThink", 0);
    
    ExecuteHamB(Ham_CS_Restart, pEntity);
}
