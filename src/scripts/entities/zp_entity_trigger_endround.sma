
#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>
#include <api_custom_entities>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] trigger_endround"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "trigger_endround"
#define SF_FORALL BIT(0)

new g_ceHandler;
new bool:g_bDispatched = false;

new g_bPlayerTouched[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
    
    RegisterHam(Ham_Touch, CE_BASE_CLASSNAME, "OnTouch_Post", .Post = 1);
}

public plugin_precache() {
    g_ceHandler = CE_Register(
        .szName = ENTITY_NAME
    );

    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "OnSpawn");
    CE_RegisterHook(CEFunction_KVD, ENTITY_NAME, "OnKvd");
}

public Round_Fw_RoundStart() {
    g_bDispatched = false;
}

public OnSpawn(pEntity) {
    set_pev(pEntity, pev_solid, SOLID_TRIGGER);
    set_pev(pEntity, pev_movetype, MOVETYPE_NONE);
    set_pev(pEntity, pev_effects, EF_NODRAW);
    ZP_GameRules_SetObjectiveMode(true);
}

public OnKvd(pEntity, const szKey[], const szValue[]) {
    if (equal(szKey, "master")) {
        set_pev(pEntity, pev_message, szValue);
    }
}

public OnTouch_Post(pEntity, pToucher) {
    if (g_ceHandler != CE_GetHandlerByEntity(pEntity)) {
        return HAM_IGNORED;
    }

    if (!UTIL_IsPlayer(pToucher)) {
        return HAM_IGNORED;
    }

    if (ZP_Player_IsZombie(pToucher)) {
        return HAM_IGNORED;
    }

    if (g_bDispatched) {
        return HAM_IGNORED;
    }

    static szMaster[32];
    pev(pEntity, pev_message, szMaster, charsmax(szMaster));

    if (!UTIL_IsMasterTriggered(szMaster, pToucher)) {
        return HAM_IGNORED;
    }

    g_bPlayerTouched[pToucher] = true;

    if (CheckWinConditions(pEntity)) {
        ZP_GameRules_DispatchWin(ZP_HUMAN_TEAM);
        g_bDispatched = true;
    }

    return HAM_HANDLED;
}

public Round_Fw_NewRound() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        g_bPlayerTouched[pPlayer] = false;
    }
}

bool:CheckWinConditions(pEntity) {
    new pToucherCount = 0;
    new iHumanCount = 0;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (!is_user_alive(pPlayer)) {
            continue;
        }

        if (ZP_Player_IsZombie(pPlayer)) {
            continue;
        }

        iHumanCount++;

        if (g_bPlayerTouched[pPlayer]) {
            pToucherCount++;
        }
    }

    if (pev(pEntity, pev_spawnflags) & SF_FORALL) {
        return pToucherCount >= iHumanCount;
    }

    return pToucherCount > 0;
}
