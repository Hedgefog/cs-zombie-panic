#include <amxmodx>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] ScoreAttrib"
#define AUTHOR "Hedgehog Fog"

#define SCORE_STATUS_DEAD BIT(0)
#define SCORE_STATUS_VIP BIT(2)

new gmsgScoreAttrib;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgScoreAttrib = get_user_msgid("ScoreAttrib");
    register_message(gmsgScoreAttrib, "OnMessage");
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

public ZP_Fw_PlayerInfected(pInfectedPlayer) {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (!ZP_Player_IsZombie(pPlayer)) {
            continue;
        }

        message_begin(MSG_ONE, gmsgScoreAttrib, _, pPlayer);
        write_byte(pInfectedPlayer);
        write_byte(SCORE_STATUS_VIP);
        message_end();
    }
}
