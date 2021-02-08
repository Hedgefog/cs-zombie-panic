#include <amxmodx>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] StatusValue"
#define AUTHOR "Hedgehog Fog"

enum StatusValueFlag {
    StatusValueFlag_IsTeammate = 1,
    StatusValueFlag_Player,
    StatusValueFlag_Health
}

new gmsgStatusValue;

new g_statusValue[StatusValueFlag];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgStatusValue = get_user_msgid("StatusValue");
    register_message(gmsgStatusValue, "OnMessage");
}

public OnMessage(iMsgId, iDest, pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    if (ZP_Player_IsZombie(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    if (UTIL_IsPlayerSpectator(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    new StatusValueFlag:iFlag = StatusValueFlag:get_msg_arg_int(1);
    new iValue = get_msg_arg_int(2);

    if (!iValue) {
        return PLUGIN_CONTINUE;
    }

    g_statusValue[iFlag] = iValue;

    if (g_statusValue[StatusValueFlag_IsTeammate] == 2) {
        return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}
