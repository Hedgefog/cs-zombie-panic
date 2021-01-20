#include <amxmodx>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] ScoreAttrib"
#define AUTHOR "Hedgehog Fog"

#define SCORE_STATUS_DEAD (1<<0)

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  register_message(get_user_msgid("ScoreAttrib"), "OnMessage");
}

public OnMessage(iMsgId, iDest, pPlayer) {
  new iFlags = get_msg_arg_int(2);

  if (pPlayer && !ZP_Player_IsZombie(pPlayer)) {
    set_msg_arg_int(2, ARG_BYTE, iFlags & ~SCORE_STATUS_DEAD);
  }

  return PLUGIN_CONTINUE;
}
