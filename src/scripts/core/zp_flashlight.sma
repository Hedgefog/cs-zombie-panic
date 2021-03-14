#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Flashlight"
#define AUTHOR "Hedgehog Fog"

#define TASKID_FLASHLIGHT_HUD 100

#define FLASHLIGHT_MAX_BRIGHTNESS 160.0
#define FLASHLIGHT_RATE 0.025
#define FLASHLIGHT_MAX_DISTANCE 768.0
#define FLASHLIGHT_MAX_CHARGE 100.0
#define FLASHLIGHT_MIN_CHARGE 0.0
#define FLASHLIGHT_DEF_CHARGE FLASHLIGHT_MAX_CHARGE
#define FLASHLIGHT_MIN_CHARGE_TO_ACTIVATE 10.0

enum PlayerFlashlight {
    bool:PlayerFlashlight_On,
    Float:PlayerFlashlight_Charge,
    PlayerFlashlight_ConeEntity,
    Float:PlayerFlashlight_LastThink
}

new gmsgFlashlight;

new g_rgPlayerFlashlight[MAX_PLAYERS + 1][PlayerFlashlight];

new g_pCvarConsumptionRate;
new g_pCvarRecoveryRate;

public plugin_precache() {
    precache_sound(ZP_FLASHLIGHT_SOUND);
    precache_model(ZP_FLASHLIGHT_LIGHTCONE_MODEL);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgFlashlight = get_user_msgid("Flashlight");

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);
    RegisterHam(Ham_Player_PreThink, "player", "OnPlayerPreThink_Post", .Post = 1);

    g_pCvarConsumptionRate = register_cvar("zp_flashlight_consumption_rate", "1.0");
    g_pCvarRecoveryRate = register_cvar("zp_flashlight_recovery_rate", "0.5");
}

public plugin_natives() {
    register_native("ZP_Player_ToggleFlashlight", "Native_Toggle");
}

public bool:Native_Toggle(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    return SetPlayerFlashlight(pPlayer, !g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_On]);
}

public client_disconnected(pPlayer) {
    SetPlayerFlashlight(pPlayer, false);
}

public OnPlayerSpawn_Post(pPlayer) {
    if(!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    SetPlayerFlashlight(pPlayer, false);
    g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge] = FLASHLIGHT_DEF_CHARGE;
    set_pev(pPlayer, pev_framerate, 1.0);
    
    return HAM_HANDLED;
}

public OnPlayerKilled_Post(pPlayer) {
    SetPlayerFlashlight(pPlayer, false);

    return HAM_HANDLED;
}

public OnPlayerPreThink_Post(pPlayer) {
    FlashlightThink(pPlayer);

    return HAM_HANDLED;
}

public FlashlightThink(pPlayer) {
    new Float:flDelta = get_gametime() - g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_LastThink];
    if (flDelta < FLASHLIGHT_RATE) {
        return;
    }

    if (g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_On]) {
        if (g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge] > FLASHLIGHT_MIN_CHARGE) {
            CreatePlayerFlashlightLight(pPlayer);
            g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge] -= (get_pcvar_float(g_pCvarConsumptionRate) * flDelta);
            g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge] = floatmax(g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge], FLASHLIGHT_MIN_CHARGE);
            set_pev(pPlayer, pev_framerate, 0.5);
        } else {
             SetPlayerFlashlight(pPlayer, false);
        }
    } else if (g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge] < FLASHLIGHT_MAX_CHARGE) {
        g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge] += (get_pcvar_float(g_pCvarRecoveryRate) * flDelta);
        g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge] = floatmin(g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge], FLASHLIGHT_MAX_CHARGE);
    }

    g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_LastThink] = get_gametime();
}

bool:SetPlayerFlashlight(pPlayer, bool:bValue) {   
    if (bValue == g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_On]) {
        return true;
    }

    if (bValue) {
        if (get_member_game(m_bFreezePeriod)) {
            return false;
        }

        if (ZP_Player_IsZombie(pPlayer) || !is_user_alive(pPlayer)) {
            return false;
        }

        if (g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge] < FLASHLIGHT_MIN_CHARGE_TO_ACTIVATE) {
            return false;
        }
    }

    g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_On] = bValue;

    remove_task(TASKID_FLASHLIGHT_HUD + pPlayer);

    if (bValue) {
        ShowLightConeEntity(pPlayer);
        set_task(1.0, "Task_FlashlightHud", TASKID_FLASHLIGHT_HUD + pPlayer, _, _, "b");
    } else {
        HideLightConeEntity(pPlayer);
    }

    if (is_user_connected(pPlayer)) {
        UpdateFlashlightHud(pPlayer);
        emit_sound(pPlayer, CHAN_ITEM, ZP_FLASHLIGHT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }

    return true;
}

CreateLightConeEntity(pPlayer) {
    static iszClassname;
    if (!iszClassname) {
        iszClassname = engfunc(EngFunc_AllocString, "info_target");
    }

    new pEntity = engfunc(EngFunc_CreateNamedEntity, iszClassname);

    set_pev(pEntity, pev_classname, "lightcone");
    set_pev(pEntity, pev_movetype, MOVETYPE_FOLLOW);
    set_pev(pEntity, pev_aiment, pPlayer);
    set_pev(pEntity, pev_owner, pPlayer);

    engfunc(EngFunc_SetModel, pEntity, ZP_FLASHLIGHT_LIGHTCONE_MODEL);

    g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_ConeEntity] = pEntity;

    return pEntity;
}

ShowLightConeEntity(pPlayer) {
    new iLightconeEntity = g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_ConeEntity];
    if (!iLightconeEntity) {
        iLightconeEntity = CreateLightConeEntity(pPlayer);
    }

    set_pev(iLightconeEntity, pev_effects, pev(iLightconeEntity, pev_effects) & ~EF_NODRAW);
    set_pev(pPlayer, pev_framerate, 0.5);
}

HideLightConeEntity(pPlayer) {
    new iLightconeEntity = g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_ConeEntity];
    if (iLightconeEntity) {
        set_pev(iLightconeEntity, pev_effects, pev(iLightconeEntity, pev_effects) | EF_NODRAW);
        set_pev(pPlayer, pev_framerate, 1.0);
    }
}

UpdateFlashlightHud(pPlayer) {
    message_begin(MSG_ONE, gmsgFlashlight, _, pPlayer);
    write_byte(g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_On]);
    write_byte(floatround(g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge]));
    message_end();
}

CreatePlayerFlashlightLight(pPlayer) {
    static Float:vecViewOfs[3];
    pev(pPlayer, pev_view_ofs, vecViewOfs);

    static Float:vecStart[3];
    pev(pPlayer, pev_origin, vecStart);
    vecStart[2] += vecViewOfs[2];

    static Float:vecEnd[3];
    pev(pPlayer, pev_v_angle, vecEnd);
    engfunc(EngFunc_MakeVectors, vecEnd); 
    get_global_vector(GL_v_forward, vecEnd);

    for (new i = 0; i < 3; ++i) {
        vecEnd[i] = vecStart[i] + (vecEnd[i] * 8192.0);
    }

    new pTr = create_tr2();
    engfunc(EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTr);
    get_tr2(pTr, TR_vecEndPos, vecEnd);
    free_tr2(pTr);

    new Float:flDistance = get_distance_f(vecStart, vecEnd);
    if (flDistance <= FLASHLIGHT_MAX_DISTANCE) {
        // TODO: Remove this hardcoded shit
        new Float:flDistanceRatio = (flDistance / FLASHLIGHT_MAX_DISTANCE);
        new Float:flBrightness = FLASHLIGHT_MAX_BRIGHTNESS * (1.0 - flDistanceRatio);
        if (flBrightness > 1.0) {
            new iColor[3];
            for (new i = 0; i < 3; ++i) {
                iColor[i] = floatround(flBrightness);
            }

            new Float:flRadius = 4.0 + (16.0 * flDistanceRatio);
            new iLifeTime = max(1, floatround(FLASHLIGHT_RATE * 10));
            new iDecayRate = 10 / iLifeTime;

            UTIL_Message_Dlight(vecEnd, floatround(flRadius), iColor, iLifeTime, iDecayRate);
        }
    }
}

public Task_FlashlightHud(iTaskId) {
    new pPlayer = iTaskId - TASKID_FLASHLIGHT_HUD;

    UpdateFlashlightHud(pPlayer);
}
