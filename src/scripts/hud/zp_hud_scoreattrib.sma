#include <amxmodx>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] ScoreAttrib"
#define AUTHOR "Hedgehog Fog"

#define SCORE_STATUS_DEAD BIT(0)

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

    if (ZP_Player_IsZombie(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    new iFlags = get_msg_arg_int(2);
    set_msg_arg_int(2, ARG_BYTE, iFlags & ~SCORE_STATUS_DEAD);

    return PLUGIN_CONTINUE;
}
