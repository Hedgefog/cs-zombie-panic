#include <amxmodx>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] StatusValue"
#define AUTHOR "Hedgehog Fog"

enum StatusValueFlag {
  StatusValueFlag_IsTeammate = 1,
  StatusValueFlag_Player,
  StatusValueFlag_Health
}

new g_statusValue[StatusValueFlag];

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  register_message(get_user_msgid("StatusValue"), "OnMessage");
}

public OnMessage(iMsgId, iDest, pPlayer) {
  new StatusValueFlag:iFlag = StatusValueFlag:get_msg_arg_int(1);
  new iValue = get_msg_arg_int(2);

  if (!iValue) {
    return PLUGIN_CONTINUE;
  }

  g_statusValue[iFlag] = iValue;

  if (!ZP_Player_IsZombie(pPlayer) && g_statusValue[StatusValueFlag_IsTeammate] == 2) {
    return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}
