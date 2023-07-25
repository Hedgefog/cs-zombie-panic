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

new gmsgScreenShake;

new bool:g_rgbPlayerPanic[MAX_PLAYERS + 1];
new Float:g_rgflPlayerLastPanic[MAX_PLAYERS + 1];

new g_pFwPanic;
new g_iFwResult;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgScreenShake = get_user_msgid("ScreenShake");

    RegisterHam(Ham_Touch, "weaponbox", "HamHook_WeaponBox_Touch", .Post = 0);
    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);

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

    return g_rgbPlayerPanic[pPlayer];
}

public HamHook_WeaponBox_Touch(pItem, pToucher) {
    if (!IS_PLAYER(pToucher)) {
        return HAM_IGNORED;
    }

    if (!g_rgbPlayerPanic[pToucher]) {
        return HAM_IGNORED;
    }

    return HAM_SUPERCEDE;
}

public HamHook_Player_Spawn_Post(pPlayer) {
    g_rgflPlayerLastPanic[pPlayer] = -PANIC_DELAY;
}

bool:Panic(pPlayer) {
    if (g_rgbPlayerPanic[pPlayer]) {
        return false;
    }

    if (get_member_game(m_bFreezePeriod)) {
        return false;
    }
    
    if (get_gametime() - g_rgflPlayerLastPanic[pPlayer] < PANIC_DELAY) {
        return false;
    }

    g_rgbPlayerPanic[pPlayer] = true;
    ZP_Player_DropUnactiveWeapons(pPlayer);
    ZP_Player_DropUnactiveAmmo(pPlayer);
    // ZP_Player_UpdateSpeed(pPlayer);

    emessage_begin(MSG_ONE, gmsgScreenShake, _, pPlayer);
    ewrite_short(floatround(1.5 * (1<<12)));
    ewrite_short(floatround(1.0 * (1<<12)));
    ewrite_short(floatround(1.0 * (1<<12)));
    emessage_end();

    set_task(PANIC_DURATION, "Task_EndPanic", pPlayer);

    ExecuteForward(g_pFwPanic, g_iFwResult, pPlayer);

    return true;
}

public Task_EndPanic(iTaskId) {
    new pPlayer = iTaskId;
    g_rgbPlayerPanic[pPlayer] = false;
    g_rgflPlayerLastPanic[pPlayer] = get_gametime();
    ZP_Player_UpdateSpeed(pPlayer);
}
