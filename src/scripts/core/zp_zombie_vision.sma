#pragma semicolon 1

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
#define TASKID_ACTIVATE_VISION 200

#define VISION_SCREEN_FADE_COLOR 255, 195, 195
#define VISION_EFFECT_TIME 0.5
#define VISION_ALPHA 20
#define MAX_BRIGHTNESS 150

new bool:g_rgbPlayerVision[MAX_PLAYERS + 1];
new bool:g_rgbPlayerExternalFade[MAX_PLAYERS + 1];
new bool:g_bIgnoreFadeMessage;

new g_pFwZombieVision;
new g_iFwResult;

new g_pCvarAuto;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn", .Post = 1);
    RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed", .Post = 1);

    register_message(get_user_msgid("ScreenFade"), "Message_ScreenFade");

    register_forward(FM_AddToFullPack, "FMHook_AddToFullPack_Post", 1);

    g_pFwZombieVision = CreateMultiForward("ZP_Fw_PlayerZombieVision", ET_IGNORE, FP_CELL, FP_CELL);

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
    g_rgbPlayerVision[pPlayer] = false;
    g_rgbPlayerExternalFade[pPlayer] = false;
}

public client_disconnected(pPlayer) {
    remove_task(TASKID_FIX_FADE + pPlayer);
}

public Command_ZombieVision(pPlayer) {
    Toggle(pPlayer);
    return HAM_HANDLED;
}

public HamHook_Player_Spawn(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    SetZombieVision(pPlayer, false);

    if (!ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    if (get_pcvar_num(g_pCvarAuto) > 0) {
        set_task(0.1, "Task_ActivateVision", TASKID_ACTIVATE_VISION + pPlayer);
    }

    return HAM_HANDLED;
}

public HamHook_Player_Killed(pPlayer) {
    SetZombieVision(pPlayer, false);
    remove_task(TASKID_ACTIVATE_VISION + pPlayer);

    if (!ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    return HAM_HANDLED;
}

public FMHook_AddToFullPack_Post(es, e, pEntity, pHost, pHostFlags, pPlayer, pSet) {
    if (!IS_PLAYER(pHost)) {
        return FMRES_IGNORED;
    }

    if (!is_user_alive(pHost)) {
        return FMRES_IGNORED;
    }

    if (!pev_valid(pEntity)) {
        return FMRES_IGNORED;
    }

    new pTargetPlayer = 0;
    if (IS_PLAYER(pEntity)) {
        pTargetPlayer = pEntity;
    } else {
        new pAimEnt = pev(pEntity, pev_aiment);
        if (IS_PLAYER(pAimEnt)) {
            pTargetPlayer = pAimEnt;
        }
    }

    if (pTargetPlayer == pHost) {
        return FMRES_IGNORED;
    }

    if (!is_user_alive(pTargetPlayer)) {
        return FMRES_IGNORED;
    }

    if (g_rgbPlayerVision[pHost]) {
        set_es(es, ES_RenderMode, kRenderNormal);
        set_es(es, ES_RenderFx, kRenderFxGlowShell);
        set_es(es, ES_RenderAmt, 1);

        static iColor[3];

        if (!ZP_Player_IsZombie(pTargetPlayer)) {
            if (ZP_Player_IsInfected(pTargetPlayer)) {
                iColor[0] = 255;
                iColor[1] = 120;
                iColor[2] = 0;
            } else {
                static Float:flMaxHealth;
                pev(pTargetPlayer, pev_max_health, flMaxHealth);

                static Float:flHealth;
                pev(pTargetPlayer, pev_health, flHealth);

                iColor[0] = floatround(MAX_BRIGHTNESS * (1.0 - (flHealth / flMaxHealth)));
                iColor[1] = 0;
                iColor[2] = 0;
            }
        } else {
            iColor[0] = 0;
            iColor[1] = MAX_BRIGHTNESS;
            iColor[2] = 0;
        }

        set_es(es, ES_RenderColor, iColor);
    }

    return FMRES_HANDLED;
}

public Message_ScreenFade(iMsgId, iMsgDest, pPlayer) {
    if (g_bIgnoreFadeMessage) {
        return PLUGIN_CONTINUE;
    }

    new Float:flDuration = (float(get_msg_arg_int(1)) / (1<<12)) + (float(get_msg_arg_int(2)) / (1<<12));
    if (flDuration > 0.0) {
        if (pPlayer > 0) {
            HandleExternalFade(pPlayer, flDuration);
        } else {
            for (new pTargetPlayer = 1; pTargetPlayer <= MaxClients; ++pTargetPlayer) {
                if (!is_user_connected(pTargetPlayer)) {
                    continue;
                }

                HandleExternalFade(pTargetPlayer, flDuration);
            }
        }
    }

    return PLUGIN_CONTINUE;
}

bool:Toggle(pPlayer) {
    SetZombieVision(pPlayer, !g_rgbPlayerVision[pPlayer]);
    return g_rgbPlayerVision[pPlayer];
}

SetZombieVision(pPlayer, bool:bValue) {
    if (bValue == g_rgbPlayerVision[pPlayer]) {
        return;
    }
    
    if (bValue) {
        if (!ZP_Player_IsZombie(pPlayer)) {
            return;
        }

        if (g_rgbPlayerVision[pPlayer]) {
            return;
        }
    }

    VisionFadeEffect(pPlayer, bValue);
    g_rgbPlayerVision[pPlayer] = bValue;

    ExecuteForward(g_pFwZombieVision, g_iFwResult, pPlayer, bValue);
}

VisionFadeEffect(pPlayer, bool:bValue) {
    if (g_rgbPlayerExternalFade[pPlayer]) {
        return;
    }

    g_bIgnoreFadeMessage = true;
    UTIL_ScreenFade(pPlayer, {VISION_SCREEN_FADE_COLOR}, VISION_EFFECT_TIME, 0.0, VISION_ALPHA, (bValue ? FFADE_OUT | FFADE_STAYOUT : FFADE_IN), .bExternal = true);
    g_bIgnoreFadeMessage = false;
}

HandleExternalFade(pPlayer, Float:flHoldTime) {
    g_rgbPlayerExternalFade[pPlayer] = true;
    set_task(flHoldTime, "Task_FixVisionScreenFade", TASKID_FIX_FADE + pPlayer);
}

public Task_FixVisionScreenFade(iTaskId) {
    new pPlayer = iTaskId - TASKID_FIX_FADE;

    if (is_user_connected(pPlayer) && g_rgbPlayerVision[pPlayer]) {
        VisionFadeEffect(pPlayer, true);
    }

    g_rgbPlayerExternalFade[pPlayer] = false;
}

public Task_ActivateVision(iTaskId) {
    new pPlayer = iTaskId - TASKID_ACTIVATE_VISION;

    SetZombieVision(pPlayer, true);
}
