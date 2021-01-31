#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Panic"
#define AUTHOR "Hedgehog Fog"

#define PANIC_DURATION 5.0
#define PANIC_DELAY 55.0

new bool:g_bPlayerPanic[MAX_PLAYERS + 1];
new Float:g_flPlayerLastPanic[MAX_PLAYERS + 1];

new g_pFwPanic;
new g_pFwResult;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Touch, "weaponbox", "OnItemTouch", .Post = 0);
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);

    g_pFwPanic = CreateMultiForward("ZP_Fw_PlayerPanic", ET_IGNORE, FP_CELL);
}

public plugin_natives() {
    register_native("ZP_Player_Panic", "Native_Panic");
    register_native("ZP_Player_InPanic", "Native_InPanic");
}

public bool:Native_Panic(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    return Panic(pPlayer);
}

public bool:Native_InPanic(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    return g_bPlayerPanic[pPlayer];
}

public OnItemTouch(pItem, pToucher) {
    if (!UTIL_IsPlayer(pToucher)) {
        return HAM_IGNORED;
    }

    if (!g_bPlayerPanic[pToucher]) {
        return HAM_IGNORED;
    }

    return HAM_SUPERCEDE;
}

public OnPlayerSpawn_Post(pPlayer) {
    g_flPlayerLastPanic[pPlayer] = -PANIC_DELAY;
}

bool:Panic(pPlayer) {
    if (g_bPlayerPanic[pPlayer]) {
        return false;
    }

    if (get_member_game(m_bFreezePeriod)) {
        return false;
    }
    
    if (get_gametime() - g_flPlayerLastPanic[pPlayer] < PANIC_DELAY) {
        return false;
    }

    g_bPlayerPanic[pPlayer] = true;
    ZP_Player_DropBackpack(pPlayer);
    ZP_Player_UpdateSpeed(pPlayer);

    set_task(PANIC_DURATION, "Task_EndPanic", pPlayer);

    ExecuteForward(g_pFwPanic, g_pFwResult, pPlayer);

    return true;
}

public Task_EndPanic(iTaskId) {
    new pPlayer = iTaskId;
    g_bPlayerPanic[pPlayer] = false;
    g_flPlayerLastPanic[pPlayer] = get_gametime();
    ZP_Player_UpdateSpeed(pPlayer);
}
