#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>

#define PLUGIN "[Zombie Panic] Zombie Lives"
#define AUTHOR "Hedgehog Fog"

#define TASKID_PLAYER_RESPAWN 100

new g_pCvarRespawnTime;

new g_iLives = 0;

new g_pFwLivesChanged;
new g_iFwResult;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);
    
    g_pCvarRespawnTime = register_cvar("zp_zombie_respawn_time", "6.0");

    g_pFwLivesChanged = CreateMultiForward("ZP_Fw_ZombieLivesChanged", ET_IGNORE, FP_CELL);
}

public plugin_natives() {
    register_native("ZP_GameRules_GetZombieLives", "Native_GetZombieLives");
    register_native("ZP_GameRules_SetZombieLives", "Native_SetZombieLives");
    register_native("ZP_GameRules_RespawnAsZombie", "Native_RespawnAsZombie");
}

public Native_GetZombieLives(iPluginId, iArgc) {
    return g_iLives;
}

public Native_SetZombieLives(iPluginId, iArgc) {
    new iValue = get_param(1);
    SetLives(iValue);
}

public Native_RespawnAsZombie(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
    SetupRespawnTask(pPlayer);
}

public ZP_Fw_PlayerJoined(pPlayer) {
    ExecuteHam(Ham_Player_PreThink, pPlayer);

    if (!is_user_alive(pPlayer)) {
        SetupRespawnTask(pPlayer);
    }

    return PLUGIN_HANDLED;
}

public OnPlayerSpawn_Post(pPlayer) {
    remove_task(pPlayer);
}

public OnPlayerKilled_Post(pPlayer) {
    if (!ZP_Player_IsZombie(pPlayer) && !ZP_GameRules_GetObjectiveMode()) {
        SetLives(g_iLives + 1);
    }

    if (get_member(pPlayer, m_iTeam) != 3) {
        SetupRespawnTask(pPlayer);
    }
}

SetupRespawnTask(pPlayer) {
    if (ZP_GameRules_IsCompetitive() && !ZP_Player_IsZombie(pPlayer)) {
        return;
    }

    remove_task(TASKID_PLAYER_RESPAWN + pPlayer);
    set_task(get_pcvar_float(g_pCvarRespawnTime), "Task_RespawnPlayer", TASKID_PLAYER_RESPAWN + pPlayer);
}

RespawnPlayer(pPlayer) {
    if (!g_iLives || get_member_game(m_bFreezePeriod)) {
        SetupRespawnTask(pPlayer);
        return;
    }

    if (Round_IsRoundEnd()) {
        return;
    }

    if (!is_user_connected(pPlayer)) {
        return;
    }

    if (is_user_alive(pPlayer)) {
        return;
    }

    if (ZP_Player_IsZombie(pPlayer)) {
        if (!ZP_GameRules_GetObjectiveMode()) {
            SetLives(g_iLives - 1);
        }
    } else {
        set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
    }

    ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);
}

SetLives(iValue) {
    g_iLives = iValue;
    ExecuteForward(g_pFwLivesChanged, g_iFwResult, g_iLives);
}

public Task_RespawnPlayer(iTaskId) {
    new pPlayer = iTaskId - TASKID_PLAYER_RESPAWN;
    RespawnPlayer(pPlayer);
}
