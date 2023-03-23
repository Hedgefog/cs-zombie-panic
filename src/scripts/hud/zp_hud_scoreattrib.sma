#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] ScoreAttrib"
#define AUTHOR "Hedgehog Fog"

#define SCORE_STATUS_DEAD BIT(0)
#define SCORE_STATUS_VIP BIT(2)

new gmsgScoreAttrib;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHamPlayer(Ham_Spawn, "OnPlayerSpawn_Post", .Post = 1);

    gmsgScoreAttrib = get_user_msgid("ScoreAttrib");
    register_message(gmsgScoreAttrib, "OnMessage");
}

public OnPlayerSpawn_Post(pPlayer) {
    if (!ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    for (new pTarget = 1; pTarget <= MaxClients; ++pTarget) {
        if (!is_user_connected(pTarget)) {
            continue;
        }

        if (ZP_Player_IsZombie(pTarget)) {
            continue;
        }

        message_begin(MSG_ONE, gmsgScoreAttrib, _, pPlayer);
        write_byte(pTarget);
        write_byte(ZP_Player_IsInfected(pTarget) ? SCORE_STATUS_VIP : 0);
        message_end();
    }

    return HAM_HANDLED;
}

public OnMessage(iMsgId, iDest, pPlayer) {
    if (!pPlayer) {
        return PLUGIN_CONTINUE;
    }

    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    new iFlags = get_msg_arg_int(2);

    if (ZP_Player_IsZombie(pPlayer)) {
        new pTargetPlayer = get_msg_arg_int(1);
        if (is_user_alive(pTargetPlayer) && ZP_Player_IsInfected(pTargetPlayer)) {
            set_msg_arg_int(2, ARG_BYTE, iFlags & SCORE_STATUS_VIP);
        }
    } else {
        set_msg_arg_int(2, ARG_BYTE, iFlags & ~SCORE_STATUS_DEAD);
    }

    return PLUGIN_CONTINUE;
}

public ZP_Fw_PlayerInfected(pPlayer) {
    UpdateAttribute(pPlayer);
}

public ZP_Fw_PlayerCured(pPlayer) {
    UpdateAttribute(pPlayer);
}

UpdateAttribute(pTarget) {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (!ZP_Player_IsZombie(pPlayer)) {
            continue;
        }

        message_begin(MSG_ONE, gmsgScoreAttrib, _, pPlayer);
        write_byte(pTarget);
        write_byte(ZP_Player_IsInfected(pTarget) ? SCORE_STATUS_VIP : 0);
        message_end();
    }
}
