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

new g_pPlayerInfector[MAX_PLAYERS + 1];
new Float:g_flPlayerTransformationTime[MAX_PLAYERS + 1];
new InfectionState:g_iPlayerInfectionState[MAX_PLAYERS + 1];
new g_iPlayerRoomType[MAX_PLAYERS + 1] = { -1, ... };
new Float:g_flPlayerOrigin[MAX_PLAYERS + 1][3];
new Float:g_flPlayerAngles[MAX_PLAYERS + 1][3];
new Float:g_flPlayerViewAngles[MAX_PLAYERS + 1][3];
new g_iPlayerFlags[MAX_PLAYERS + 1];

new g_pCvarInfectionChance;

new g_pFwInfected;
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

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled", .Post = 0);
    RegisterHam(Ham_Player_PreThink, "player", "OnPlayerPreThink_Post", .Post = 1);
    RegisterHam(Ham_TraceAttack, "player", "OnPlayerTraceAttack", .Post = 0);
    RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage", .Post = 0);
    RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage_Post", .Post = 0);

    g_pCvarInfectionChance = register_cvar("zp_infection_chance", "10");

    g_pFwInfected = CreateMultiForward("ZP_Fw_PlayerInfected", ET_IGNORE, FP_CELL, FP_CELL);
    g_pFwTransformationDeath = CreateMultiForward("ZP_Fw_PlayerTransformationDeath", ET_IGNORE, FP_CELL);
    g_pFwTransformed = CreateMultiForward("ZP_Fw_PlayerTransformed", ET_IGNORE, FP_CELL);
}

public plugin_natives() {
    register_native("ZP_Player_SetInfected", "Native_SetInfected");
    register_native("ZP_Player_IsInfected", "Native_IsPlayerInfected");
    register_native("ZP_Player_IsTransforming", "Native_IsPlayerTransforming");
}

public Native_SetInfected(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    new bool:bValue = bool:get_param(2);

    SetInfected(pPlayer, bValue);
}

public Native_IsPlayerInfected(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    return IsPlayerInfected(pPlayer);
}

public Native_IsPlayerTransforming(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    return IsPlayerInfected(pPlayer) && g_iPlayerInfectionState[pPlayer] >= InfectionState_Transformation;
}

public OnPlayerSpawn_Post(pPlayer) {
    SetInfected(pPlayer, false);
}

public OnPlayerKilled(pPlayer) {
    ResetRoomType(pPlayer);
    HideInfectionIcon(pPlayer);
}

public OnPlayerPreThink_Post(pPlayer) {
    if (!IsPlayerInfected(pPlayer)) {
        return HAM_IGNORED;
    }

    new Float:flTimeLeft = g_flPlayerTransformationTime[pPlayer] - get_gametime();
    if (flTimeLeft <= 0.0) {
        if (g_iPlayerInfectionState[pPlayer] != InfectionState_TransformationDeath) {
            if (!is_user_alive(pPlayer)) {
                return HAM_IGNORED;
            }

            TransformPlayer(pPlayer);
            g_iPlayerInfectionState[pPlayer] = InfectionState_TransformationDeath;
        } else {
            if (is_user_alive(pPlayer)) {
                return HAM_IGNORED;
            }

            EndPlayerTransformation(pPlayer);
        }
    } else if (flTimeLeft <= TRANSFORMATION_DURATION) {
        if (!is_user_alive(pPlayer)) {
            return HAM_IGNORED;
        }

        if (g_iPlayerInfectionState[pPlayer] != InfectionState_Transformation) {
            SendScreenShake(pPlayer);
            client_cmd(pPlayer, "spk %s", ZP_TRANSFORMATION_SOUND);
            g_iPlayerInfectionState[pPlayer] = InfectionState_Transformation;
        }
    } else if (flTimeLeft <= (TRANSFORMATION_DELAY / 2)) {
        if (!is_user_alive(pPlayer)) {
            return HAM_IGNORED;
        }

        if (g_iPlayerInfectionState[pPlayer] != InfectionState_PartialZombie) {
            g_iPlayerRoomType[pPlayer] = floatround(get_member(pPlayer, m_flSndRoomtype));
            SendBlinkEffect(pPlayer);
            SendRoomType(pPlayer);
            client_cmd(pPlayer, "spk %s", ZP_JOLT_SOUNDS[random(sizeof(ZP_JOLT_SOUNDS))]);
            ShowInfectionIcon(pPlayer);
            g_iPlayerInfectionState[pPlayer] = InfectionState_PartialZombie;
        }
    }

    return HAM_HANDLED;
}

public OnPlayerTraceAttack(pPlayer, pAttacker, Float:flDamage, Float:vecDir[3], pTr, iDamageBits) {
    if (!IsPlayerInfected(pPlayer)) {
        return HAM_IGNORED;
    }

    if (!UTIL_IsPlayer(pAttacker)) {
        return HAM_IGNORED;
    }

    if (g_iPlayerInfectionState[pPlayer] < InfectionState_PartialZombie) {
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

public OnPlayerTakeDamage(pPlayer, pInflictor, pAttacker, Float:flDamage, iDamageBits) {
    if (!IsPlayerInfected(pPlayer)) {
        return HAM_IGNORED;
    }

    if (!UTIL_IsPlayer(pAttacker)) {
        return HAM_IGNORED;
    }

    if (g_iPlayerInfectionState[pPlayer] < InfectionState_PartialZombie) {
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

public OnPlayerTakeDamage_Post(pPlayer, pInflictor, pAttacker) {
    if (!UTIL_IsPlayer(pAttacker)) {
        return HAM_IGNORED;
    }

    if (!ZP_Player_IsZombie(pAttacker)) {
        return HAM_IGNORED;
    }

    if (ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    if (random(100) < get_pcvar_num(g_pCvarInfectionChance)) {
        if (SetInfected(pPlayer, true, pAttacker)) {
            client_print(pAttacker, print_chat, "You've infected %n.", pPlayer);
        }
    }

    return HAM_HANDLED;
}

bool:SetInfected(pPlayer, bool:bValue, pInfector = 0) {
    if (bValue) {
        if (IsPlayerInfected(pPlayer)) {
            return false;
        }

        if (!is_user_alive(pPlayer)) {
            return false;
        }

        if (ZP_Player_IsZombie(pPlayer)) {
            return false;
        }

        g_iPlayerInfectionState[pPlayer] = InfectionState_Infected;
        g_flPlayerTransformationTime[pPlayer] = get_gametime() + TRANSFORMATION_DELAY;
        g_pPlayerInfector[pPlayer] = pInfector;

        ExecuteForward(g_pFwInfected, g_iFwResult, pPlayer, pInfector);
    } else {
        g_iPlayerInfectionState[pPlayer] = InfectionState_None;

        ResetRoomType(pPlayer);
        HideInfectionIcon(pPlayer);
    }

    return true;
}

bool:IsPlayerInfected(pPlayer) {
    if (ZP_Player_IsZombie(pPlayer)) {
        return false;
    }

    return g_iPlayerInfectionState[pPlayer] > InfectionState_None;
}

TransformPlayer(pPlayer) {
    pev(pPlayer, pev_origin, g_flPlayerOrigin[pPlayer]);
    pev(pPlayer, pev_angles, g_flPlayerAngles[pPlayer]);
    pev(pPlayer, pev_v_angle, g_flPlayerViewAngles[pPlayer]);
    g_iPlayerFlags[pPlayer] = pev(pPlayer, pev_flags);

    ExecuteForward(g_pFwTransformationDeath, g_iFwResult, pPlayer);
    ExecuteHamB(Ham_Killed, pPlayer, g_pPlayerInfector[pPlayer], 0);
}

EndPlayerTransformation(pPlayer) {
    set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
    ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);

    set_pev(pPlayer, pev_origin, g_flPlayerOrigin[pPlayer]);
    set_pev(pPlayer, pev_angles, g_flPlayerAngles[pPlayer]);
    set_pev(pPlayer, pev_v_angle, g_flPlayerViewAngles[pPlayer]);
    set_pev(pPlayer, pev_flags, g_iPlayerFlags[pPlayer]);

    ExecuteForward(g_pFwTransformed, g_iFwResult, pPlayer);
}

SendRoomType(pPlayer) {
    emessage_begin(MSG_ONE, SVC_ROOMTYPE, _, pPlayer);
    ewrite_short(16);
    emessage_end();
}

ResetRoomType(pPlayer) {
    if (g_iPlayerRoomType[pPlayer] == -1) {
        return;
    }

    emessage_begin(MSG_ONE, SVC_ROOMTYPE, _, pPlayer);
    ewrite_short(g_iPlayerRoomType[pPlayer]);
    emessage_end();

    g_iPlayerRoomType[pPlayer] = -1;
}

ShowInfectionIcon(pPlayer) {
    message_begin(MSG_ONE, gmsgStatusIcon, _, pPlayer);
    write_byte(1);
    write_string(INFECTION_ICON);
    write_byte(255);
    write_byte(120);
    write_byte(0);
    message_end();
}

HideInfectionIcon(pPlayer) {
    message_begin(MSG_ONE, gmsgStatusIcon, _, pPlayer);
    write_byte(0);
    write_string(INFECTION_ICON);
    message_end();
}

SendScreenShake(pPlayer) {
    emessage_begin(MSG_ONE, gmsgScreenShake, _, pPlayer);
    ewrite_short(floatround(2.5 * (1<<12)));
    ewrite_short(floatround(10.0 * (1<<12)));
    ewrite_short(floatround(1.0 * (1<<12)));
    emessage_end();
}

SendBlinkEffect(pPlayer) {
    UTIL_ScreenFade(pPlayer, {0, 0, 0}, 0.25, 0.0, 255, FFADE_IN, false, true);
}
