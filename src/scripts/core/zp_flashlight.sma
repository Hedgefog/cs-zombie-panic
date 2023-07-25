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

    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
    RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);
    RegisterHamPlayer(Ham_Player_PreThink, "HamHook_Player_PreThink_Post", .Post = 1);

    g_pCvarConsumptionRate = register_cvar("zp_flashlight_consumption_rate", "1.0");
    g_pCvarRecoveryRate = register_cvar("zp_flashlight_recovery_rate", "0.5");
}

public plugin_natives() {
    register_native("ZP_Player_ToggleFlashlight", "Native_Toggle");
}

public bool:Native_Toggle(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    return @Player_SetFlashlight(pPlayer, !g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_On]);
}

public client_disconnected(pPlayer) {
    @Player_SetFlashlight(pPlayer, false);
}

public HamHook_Player_Spawn_Post(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    @Player_SetFlashlight(pPlayer, false);
    g_rgPlayerFlashlight[pPlayer][PlayerFlashlight_Charge] = FLASHLIGHT_DEF_CHARGE;
    set_pev(pPlayer, pev_framerate, 1.0);
    
    return HAM_HANDLED;
}

public HamHook_Player_Killed_Post(pPlayer) {
    @Player_SetFlashlight(pPlayer, false);

    return HAM_HANDLED;
}

public HamHook_Player_PreThink_Post(pPlayer) {
    @Player_FlashlightThink(pPlayer);

    return HAM_HANDLED;
}

public @Player_FlashlightThink(this) {
    new Float:flDelta = get_gametime() - g_rgPlayerFlashlight[this][PlayerFlashlight_LastThink];
    if (flDelta < FLASHLIGHT_RATE) {
        return;
    }

    if (g_rgPlayerFlashlight[this][PlayerFlashlight_On]) {
        if (g_rgPlayerFlashlight[this][PlayerFlashlight_Charge] > FLASHLIGHT_MIN_CHARGE) {
            @Player_CreateFlashlightLight(this);
            g_rgPlayerFlashlight[this][PlayerFlashlight_Charge] -= (get_pcvar_float(g_pCvarConsumptionRate) * flDelta);
            g_rgPlayerFlashlight[this][PlayerFlashlight_Charge] = floatmax(g_rgPlayerFlashlight[this][PlayerFlashlight_Charge], FLASHLIGHT_MIN_CHARGE);
            set_pev(this, pev_framerate, 0.5);
        } else {
             @Player_SetFlashlight(this, false);
        }
    } else if (g_rgPlayerFlashlight[this][PlayerFlashlight_Charge] < FLASHLIGHT_MAX_CHARGE) {
        g_rgPlayerFlashlight[this][PlayerFlashlight_Charge] += (get_pcvar_float(g_pCvarRecoveryRate) * flDelta);
        g_rgPlayerFlashlight[this][PlayerFlashlight_Charge] = floatmin(g_rgPlayerFlashlight[this][PlayerFlashlight_Charge], FLASHLIGHT_MAX_CHARGE);
    }

    g_rgPlayerFlashlight[this][PlayerFlashlight_LastThink] = get_gametime();
}

bool:@Player_SetFlashlight(this, bool:bValue) {   
    if (bValue == g_rgPlayerFlashlight[this][PlayerFlashlight_On]) {
        return true;
    }

    if (bValue) {
        if (get_member_game(m_bFreezePeriod)) {
            return false;
        }

        if (ZP_Player_IsZombie(this) || !is_user_alive(this)) {
            return false;
        }

        if (g_rgPlayerFlashlight[this][PlayerFlashlight_Charge] < FLASHLIGHT_MIN_CHARGE_TO_ACTIVATE) {
            return false;
        }
    }

    g_rgPlayerFlashlight[this][PlayerFlashlight_On] = bValue;

    remove_task(TASKID_FLASHLIGHT_HUD + this);

    if (bValue) {
        @Player_ShowLightConeEntity(this);
        set_task(1.0, "Task_FlashlightHud", TASKID_FLASHLIGHT_HUD + this, _, _, "b");
    } else {
        @Player_HideLightConeEntityy(this);
    }

    if (is_user_connected(this)) {
        @Player_UpdateFlashlightHud(this);
        emit_sound(this, CHAN_ITEM, ZP_FLASHLIGHT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }

    return true;
}

@Player_CreateLightConeEntity(this) {
    static iszClassname;
    if (!iszClassname) {
        iszClassname = engfunc(EngFunc_AllocString, "info_target");
    }

    new pEntity = engfunc(EngFunc_CreateNamedEntity, iszClassname);

    set_pev(pEntity, pev_classname, "lightcone");
    set_pev(pEntity, pev_movetype, MOVETYPE_FOLLOW);
    set_pev(pEntity, pev_aiment, this);
    set_pev(pEntity, pev_owner, this);

    engfunc(EngFunc_SetModel, pEntity, ZP_FLASHLIGHT_LIGHTCONE_MODEL);

    g_rgPlayerFlashlight[this][PlayerFlashlight_ConeEntity] = pEntity;

    return pEntity;
}

@Player_ShowLightConeEntity(this) {
    new iLightconeEntity = g_rgPlayerFlashlight[this][PlayerFlashlight_ConeEntity];
    if (!iLightconeEntity) {
        iLightconeEntity = @Player_CreateLightConeEntity(this);
    }

    set_pev(iLightconeEntity, pev_effects, pev(iLightconeEntity, pev_effects) & ~EF_NODRAW);
    set_pev(this, pev_framerate, 0.5);
}

@Player_HideLightConeEntityy(this) {
    new iLightconeEntity = g_rgPlayerFlashlight[this][PlayerFlashlight_ConeEntity];
    if (iLightconeEntity) {
        set_pev(iLightconeEntity, pev_effects, pev(iLightconeEntity, pev_effects) | EF_NODRAW);
        set_pev(this, pev_framerate, 1.0);
    }
}

@Player_UpdateFlashlightHud(this) {
    message_begin(MSG_ONE, gmsgFlashlight, _, this);
    write_byte(g_rgPlayerFlashlight[this][PlayerFlashlight_On]);
    write_byte(floatround(g_rgPlayerFlashlight[this][PlayerFlashlight_Charge]));
    message_end();
}

@Player_CreateFlashlightLight(this) {
    static Float:vecViewOfs[3];
    pev(this, pev_view_ofs, vecViewOfs);

    static Float:vecStart[3];
    pev(this, pev_origin, vecStart);
    vecStart[2] += vecViewOfs[2];

    static Float:vecEnd[3];
    pev(this, pev_v_angle, vecEnd);
    engfunc(EngFunc_MakeVectors, vecEnd); 
    get_global_vector(GL_v_forward, vecEnd);

    for (new i = 0; i < 3; ++i) {
        vecEnd[i] = vecStart[i] + (vecEnd[i] * 8192.0);
    }

    new pTr = create_tr2();
    engfunc(EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, this, pTr);
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

    @Player_UpdateFlashlightHud(pPlayer);
}
