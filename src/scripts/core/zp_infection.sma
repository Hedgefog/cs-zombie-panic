#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>
#include <screenfade_util>

#define PLUGIN "[Zombie Panic] Infection"
#define AUTHOR "Hedgehog Fog"

#define TRANSFORMATION_DELAY 60.0
#define TRANSFORMATION_DURATION 7.0
#define INFECTION_ICON "dmg_bio"

enum InfectionState {
    InfectionState_None,
    InfectionState_Infected,
    InfectionState_PartialZombie,
    InfectionState_Transformation,
    InfectionState_TransformationDeath
}

new gmsgScreenShake;
new gmsgStatusIcon;

new g_rgpPlayerInfector[MAX_PLAYERS + 1];
new Float:g_rgflPlayerTransformationTime[MAX_PLAYERS + 1];
new InfectionState:g_rgiPlayerInfectionState[MAX_PLAYERS + 1];
new g_rgiPlayerRoomType[MAX_PLAYERS + 1] = { -1, ... };
new Float:g_rgflPlayerOrigin[MAX_PLAYERS + 1][3];
new Float:g_rgflPlayerAngles[MAX_PLAYERS + 1][3];
new Float:g_rgflPlayerViewAngles[MAX_PLAYERS + 1][3];
new g_rgiPlayerFlags[MAX_PLAYERS + 1];

new g_pCvarInfectionChance;

new g_pFwInfected;
new g_pFwCured;
new g_pFwTransformationDeath;
new g_pFwTransformed;
new g_iFwResult;

public plugin_precache() {
    for (new i = 0; i < sizeof(ZP_JOLT_SOUNDS); ++i) {
        precache_sound(ZP_JOLT_SOUNDS[i]);
    }

    precache_sound(ZP_TRANSFORMATION_SOUND);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgScreenShake = get_user_msgid("ScreenShake");
    gmsgStatusIcon = get_user_msgid("StatusIcon");

    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
    RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed", .Post = 0);
    RegisterHamPlayer(Ham_Player_PreThink, "HamHook_Player_PreThink_Post", .Post = 1);
    RegisterHamPlayer(Ham_TraceAttack, "HamHook_Player_TraceAttack", .Post = 0);
    RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage", .Post = 0);
    RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 0);
    RegisterHamPlayer(Ham_BloodColor, "HamHook_Player_BloodColor", .Post = 0);

    g_pCvarInfectionChance = register_cvar("zp_infection_chance", "5");

    g_pFwInfected = CreateMultiForward("ZP_Fw_PlayerInfected", ET_IGNORE, FP_CELL, FP_CELL);
    g_pFwCured = CreateMultiForward("ZP_Fw_PlayerCured", ET_IGNORE, FP_CELL);
    g_pFwTransformationDeath = CreateMultiForward("ZP_Fw_PlayerTransformationDeath", ET_IGNORE, FP_CELL);
    g_pFwTransformed = CreateMultiForward("ZP_Fw_PlayerTransformed", ET_IGNORE, FP_CELL);
}

public plugin_natives() {
    register_native("ZP_Player_SetInfected", "Native_SetInfected");
    register_native("ZP_Player_IsInfected", "Native_IsPlayerInfected");
    register_native("ZP_Player_IsPartialZombie", "Native_IsPlayerPartialZombie");
    register_native("ZP_Player_IsTransforming", "Native_IsPlayerTransforming");
    register_native("ZP_Player_GetInfector", "Native_GetInfector");
}

public Native_SetInfected(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    new bool:bValue = bool:get_param(2);
    new pInfector = get_param(3);

    @Player_SetInfected(pPlayer, bValue, pInfector);
}

public Native_IsPlayerInfected(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    return @Player_IsInfected(pPlayer);
}

public bool:Native_IsPlayerPartialZombie(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    return @Player_IsInfected(pPlayer) && g_rgiPlayerInfectionState[pPlayer] >= InfectionState_PartialZombie;
}

public bool:Native_IsPlayerTransforming(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    return @Player_IsInfected(pPlayer) && g_rgiPlayerInfectionState[pPlayer] >= InfectionState_Transformation;
}

public Native_GetInfector(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    if (!@Player_IsInfected(pPlayer)) {
        return -1;
    }

    return g_rgpPlayerInfector[pPlayer];
}

public HamHook_Player_Spawn_Post(pPlayer) {
    @Player_SetInfected(pPlayer, false, 0);
}

public HamHook_Player_Killed(pPlayer) {
    @Player_ResetRoomType(pPlayer);
    @Player_HideInfectionIcon(pPlayer);
}

public HamHook_Player_PreThink_Post(pPlayer) {
    if (!@Player_IsInfected(pPlayer)) {
        return HAM_IGNORED;
    }

    new Float:flTimeLeft = g_rgflPlayerTransformationTime[pPlayer] - get_gametime();
    if (flTimeLeft <= 0.0) {
        if (g_rgiPlayerInfectionState[pPlayer] != InfectionState_TransformationDeath) {
            if (!is_user_alive(pPlayer)) {
                return HAM_IGNORED;
            }

            @Player_Transform(pPlayer);
            g_rgiPlayerInfectionState[pPlayer] = InfectionState_TransformationDeath;
        } else {
            if (is_user_alive(pPlayer)) {
                return HAM_IGNORED;
            }

            @Player_EndTransformation(pPlayer);
            @Player_SendBlinkEffect(pPlayer);
        }
    } else if (flTimeLeft <= TRANSFORMATION_DURATION) {
        if (!is_user_alive(pPlayer)) {
            return HAM_IGNORED;
        }

        if (g_rgiPlayerInfectionState[pPlayer] != InfectionState_Transformation) {
            @Player_SendScreenShake(pPlayer);
            client_cmd(pPlayer, "spk %s", ZP_TRANSFORMATION_SOUND);
            g_rgiPlayerInfectionState[pPlayer] = InfectionState_Transformation;
        }
    } else if (flTimeLeft <= (TRANSFORMATION_DELAY / 2)) {
        if (!is_user_alive(pPlayer)) {
            return HAM_IGNORED;
        }

        if (g_rgiPlayerInfectionState[pPlayer] != InfectionState_PartialZombie) {
            g_rgiPlayerRoomType[pPlayer] = floatround(get_member(pPlayer, m_flSndRoomtype));
            @Player_SendBlinkEffect(pPlayer);
            @Player_SendRoomType(pPlayer);
            client_cmd(pPlayer, "spk %s", ZP_JOLT_SOUNDS[random(sizeof(ZP_JOLT_SOUNDS))]);
            @Player_ShowInfectionIcon(pPlayer);
            g_rgiPlayerInfectionState[pPlayer] = InfectionState_PartialZombie;
        }
    }

    return HAM_HANDLED;
}

public HamHook_Player_TraceAttack(pPlayer, pAttacker, Float:flDamage, Float:vecDir[3], pTr, iDamageBits) {
    if (!@Player_IsInfected(pPlayer)) {
        return HAM_IGNORED;
    }

    if (!IS_PLAYER(pAttacker)) {
        return HAM_IGNORED;
    }

    if (g_rgiPlayerInfectionState[pPlayer] < InfectionState_PartialZombie) {
        return HAM_IGNORED;
    }

    new iTeam = get_member(pPlayer, m_iTeam);
    if (iTeam != ZP_HUMAN_TEAM) {
        return HAM_IGNORED;
    }

    new iAttackerTeam = get_member(pAttacker, m_iTeam);
    if (iTeam != iAttackerTeam) {
        return HAM_IGNORED;
    }

    set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
    ExecuteHam(Ham_TraceAttack, pPlayer, pAttacker, flDamage, vecDir, pTr, iDamageBits);
    set_member(pPlayer, m_iTeam, ZP_HUMAN_TEAM);

    return HAM_SUPERCEDE;
}

public HamHook_Player_TakeDamage(pPlayer, pInflictor, pAttacker, Float:flDamage, iDamageBits) {
    if (!@Player_IsInfected(pPlayer)) {
        return HAM_IGNORED;
    }

    if (!IS_PLAYER(pAttacker)) {
        return HAM_IGNORED;
    }

    if (g_rgiPlayerInfectionState[pPlayer] < InfectionState_PartialZombie) {
        return HAM_IGNORED;
    }

    new iTeam = get_member(pPlayer, m_iTeam);
    if (iTeam != ZP_HUMAN_TEAM) {
        return HAM_IGNORED;
    }

    new iAttackerTeam = get_member(pAttacker, m_iTeam);
    if (iTeam != iAttackerTeam) {
        return HAM_IGNORED;
    }

    set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
    ExecuteHam(Ham_TakeDamage, pPlayer, pInflictor, pAttacker, flDamage, iDamageBits);
    set_member(pPlayer, m_iTeam, ZP_HUMAN_TEAM);

    return HAM_SUPERCEDE;
}

public HamHook_Player_TakeDamage_Post(pPlayer, pInflictor, pAttacker) {
    if (!IS_PLAYER(pAttacker)) {
        return HAM_IGNORED;
    }

    if (!ZP_Player_IsZombie(pAttacker)) {
        return HAM_IGNORED;
    }

    if (ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    if (random(100) < get_pcvar_num(g_pCvarInfectionChance)) {
        if (@Player_SetInfected(pPlayer, true, pAttacker)) {
            client_print(pAttacker, print_chat, "You've infected %n.", pPlayer);
        }
    }

    return HAM_HANDLED;
}

public HamHook_Player_BloodColor(pPlayer) {
    if (g_rgiPlayerInfectionState[pPlayer] < InfectionState_PartialZombie) {
        return HAM_IGNORED;
    }

    SetHamReturnInteger(-1);
    return HAM_SUPERCEDE;
}

bool:@Player_SetInfected(this, bool:bValue, pInfector) {
    if (bValue == @Player_IsInfected(this)) {
        return false;
    }

    if (bValue) {
        if (ZP_GameRules_IsCompetitive()) {
            return false;
        }

        if (!is_user_alive(this)) {
            return false;
        }

        if (ZP_Player_IsZombie(this)) {
            return false;
        }

        g_rgiPlayerInfectionState[this] = InfectionState_Infected;
        g_rgflPlayerTransformationTime[this] = get_gametime() + TRANSFORMATION_DELAY;
        g_rgpPlayerInfector[this] = pInfector;

        ExecuteForward(g_pFwInfected, g_iFwResult, this, pInfector);
    } else {
        g_rgiPlayerInfectionState[this] = InfectionState_None;

        @Player_ResetRoomType(this);
        @Player_HideInfectionIcon(this);
        ExecuteForward(g_pFwCured, g_iFwResult, this);
    }

    return true;
}

bool:@Player_IsInfected(this) {
    // if (ZP_Player_IsZombie(this)) {
    //     return false;
    // }

    return g_rgiPlayerInfectionState[this] > InfectionState_None;
}

@Player_Transform(this) {
    pev(this, pev_origin, g_rgflPlayerOrigin[this]);
    pev(this, pev_angles, g_rgflPlayerAngles[this]);
    pev(this, pev_v_angle, g_rgflPlayerViewAngles[this]);
    g_rgiPlayerFlags[this] = pev(this, pev_flags);

    ExecuteForward(g_pFwTransformationDeath, g_iFwResult, this);
    ExecuteHamB(Ham_Killed, this, g_rgpPlayerInfector[this], 0);
    emit_sound(this, CHAN_VOICE, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

@Player_EndTransformation(this) {
    set_member(this, m_iTeam, ZP_ZOMBIE_TEAM);
    ExecuteHamB(Ham_CS_RoundRespawn, this);

    set_pev(this, pev_origin, g_rgflPlayerOrigin[this]);
    set_pev(this, pev_angles, g_rgflPlayerAngles[this]);
    set_pev(this, pev_v_angle, g_rgflPlayerViewAngles[this]);
    set_pev(this, pev_flags, g_rgiPlayerFlags[this]);

    ExecuteForward(g_pFwTransformed, g_iFwResult, this);
}

@Player_SendRoomType(this) {
    emessage_begin(MSG_ONE, SVC_ROOMTYPE, _, this);
    ewrite_short(16);
    emessage_end();
}

@Player_ResetRoomType(this) {
    if (g_rgiPlayerRoomType[this] == -1) {
        return;
    }

    emessage_begin(MSG_ONE, SVC_ROOMTYPE, _, this);
    ewrite_short(g_rgiPlayerRoomType[this]);
    emessage_end();

    g_rgiPlayerRoomType[this] = -1;
}

@Player_ShowInfectionIcon(this) {
    message_begin(MSG_ONE, gmsgStatusIcon, _, this);
    write_byte(1);
    write_string(INFECTION_ICON);
    write_byte(255);
    write_byte(120);
    write_byte(0);
    message_end();
}

@Player_HideInfectionIcon(this) {
    message_begin(MSG_ONE, gmsgStatusIcon, _, this);
    write_byte(0);
    write_string(INFECTION_ICON);
    message_end();
}

@Player_SendScreenShake(this) {
    emessage_begin(MSG_ONE, gmsgScreenShake, _, this);
    ewrite_short(floatround(2.5 * (1<<12)));
    ewrite_short(floatround(10.0 * (1<<12)));
    ewrite_short(floatround(1.0 * (1<<12)));
    emessage_end();
}

@Player_SendBlinkEffect(this) {
    UTIL_ScreenFade(this, {0, 0, 0}, 0.25, 0.0, 255, FFADE_IN, false, true);
}
