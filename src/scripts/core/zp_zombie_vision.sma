#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#include <screenfade_util>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Zombie Vision"
#define AUTHOR "Hedgehog Fog"

#define TASKID_FIX_FADE 100

#define VISION_SCREEN_FADE_COLOR 255, 195, 195
#define VISION_EFFECT_TIME 0.5
#define VISION_ALPHA 20

new bool:g_bPlayerVision[MAX_PLAYERS + 1];
new bool:g_bPlayerExternalFade[MAX_PLAYERS + 1];
new bool:g_bIgnoreFadeMessage;

new g_iFwZombieVision;
new g_iFwResult;

new g_pCvarAuto;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", .Post = 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled", .Post = 1);

    register_message(get_user_msgid("ScreenFade"), "OnMessage_ScreenFade");

    register_forward(FM_AddToFullPack, "OnAddToFullPack_Post", 1);

    g_iFwZombieVision = CreateMultiForward("ZP_Fw_PlayerZombieVision", ET_IGNORE, FP_CELL, FP_CELL);

    g_pCvarAuto = register_cvar("zp_zombievision_auto", "1");
}

public plugin_natives() {
    register_native("ZP_Player_ToggleZombieVision", "Native_Toggle");
}

public bool:Native_Toggle(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    return Toggle(pPlayer);
}

public client_connect(pPlayer) {
    g_bPlayerVision[pPlayer] = false;
    g_bPlayerExternalFade[pPlayer] = false;
}

public client_disconnected(pPlayer) {
    remove_task(TASKID_FIX_FADE + pPlayer);
}

public OnClCmd_ZombieVision(pPlayer) {
    Toggle(pPlayer);
    return HAM_HANDLED;
}

public OnPlayerSpawn(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    SetZombieVision(pPlayer, false);

    if (!ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    if (get_pcvar_num(g_pCvarAuto) > 0) {
        SetZombieVision(pPlayer, true);
    }

    return HAM_HANDLED;
}

public OnPlayerKilled(pPlayer) {
    SetZombieVision(pPlayer, false);

    if (!ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    return HAM_HANDLED;
}

public OnAddToFullPack_Post(es, e, pEntity, pHost, pHostFlags, pPlayer, pSet) {
    if (pEntity == pHost) {
        return FMRES_IGNORED;
    }

    if (!UTIL_IsPlayer(pHost)) {
        return FMRES_IGNORED;
    }

    if (!UTIL_IsPlayer(pEntity)) {
        return FMRES_IGNORED;
    }

    if (!is_user_alive(pHost)) {
        return FMRES_IGNORED;
    }

    if (!is_user_alive(pEntity)) {
        return FMRES_IGNORED;
    }
    
    if (g_bPlayerVision[pHost]) {
        set_es(es, ES_RenderMode, kRenderNormal);
        set_es(es, ES_RenderFx, kRenderFxGlowShell);
        set_es(es, ES_RenderAmt, 1);

        if (!ZP_Player_IsZombie(pEntity)) {
            static Float:flMaxHealth;
            pev(pEntity, pev_max_health, flMaxHealth);

            static Float:flHealth;
            pev(pEntity, pev_health, flHealth);

            new Float:flBrightness = (1.0 - (flHealth / flMaxHealth)) * 255.0;
            new iColor[3] = {0, 0, 0};
            iColor[0] = floatround(flBrightness);

            set_es(es, ES_RenderColor, iColor);
        } else {
            set_es(es, ES_RenderColor, { 0, 255, 0});
        }
    }

    return FMRES_HANDLED;
}

public OnMessage_ScreenFade(iMsgId, iMsgDest, pPlayer) {
    if (g_bIgnoreFadeMessage) {
        return PLUGIN_CONTINUE;
    }

    new Float:flHoldTime = float(get_msg_arg_int(2) * (1>>12));
    if (flHoldTime > 0.0) {
        g_bPlayerExternalFade[pPlayer] = true;
        set_task(flHoldTime, "Task_FixVisionScreenFade", TASKID_FIX_FADE + pPlayer);
    }

    return PLUGIN_CONTINUE;
}

bool:Toggle(pPlayer) {
    SetZombieVision(pPlayer, !g_bPlayerVision[pPlayer]);
    return g_bPlayerVision[pPlayer];
}

SetZombieVision(pPlayer, bool:bValue) {
    if (bValue && !ZP_Player_IsZombie(pPlayer)) {
        return;
    }

    if (bValue == g_bPlayerVision[pPlayer]) {
        return;
    }

    VisionFadeEffect(pPlayer, bValue);
    g_bPlayerVision[pPlayer] = bValue;

    ExecuteForward(g_iFwZombieVision, g_iFwResult, pPlayer, bValue);
}

VisionFadeEffect(pPlayer, bool:bValue) {
    if (g_bPlayerExternalFade[pPlayer]) {
        return;
    }

    g_bIgnoreFadeMessage = true;
    UTIL_ScreenFade(pPlayer, {VISION_SCREEN_FADE_COLOR}, VISION_EFFECT_TIME, 0.0, VISION_ALPHA, (bValue ? FFADE_OUT | FFADE_STAYOUT : FFADE_IN), .bExternal = true);
    g_bIgnoreFadeMessage = false;
}

public Task_FixVisionScreenFade(iTaskId) {
    new pPlayer = iTaskId - TASKID_FIX_FADE;

    if (is_user_connected(pPlayer) && g_bPlayerVision[pPlayer]) {
        VisionFadeEffect(pPlayer, true);
    }

    g_bPlayerExternalFade[pPlayer] = false;
}
