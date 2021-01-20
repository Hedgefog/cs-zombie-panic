#include <amxmodx>
#include <fakemeta>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] DeathMsg"
#define AUTHOR "Hedgehog Fog"

new g_iDeathMsgMessage;

public plugin_init()
{
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
  
  g_iDeathMsgMessage = get_user_msgid("DeathMsg");
  register_message(g_iDeathMsgMessage, "OnMessage_DeathMsg");
}

public OnMessage_DeathMsg(iMsgId, iDest, pPlayer) {
    if (pPlayer) {
      return PLUGIN_CONTINUE;
    }

    new iKiller = get_msg_arg_int(1);
    new iVictim = get_msg_arg_int(2);
    new iHeadshot = get_msg_arg_int(3);

    static szWeapon[32];
    get_msg_arg_string(4, szWeapon, charsmax(szWeapon));
  
    for (new pPlayer = 1; pPlayer <= MAX_PLAYERS; ++pPlayer) {
      if (!is_user_connected(pPlayer)) {
        continue;
      }

      if (!ZP_Player_IsZombie(pPlayer)) {
        continue;
      }

      SendDeathMsg(pPlayer, iKiller, iVictim, iHeadshot, szWeapon);
    }

    return PLUGIN_HANDLED;
}

SendDeathMsg(pPlayer, iKiller, iVictim, iHeadshot, const szWeapon[]) {
  emessage_begin(MSG_ONE, g_iDeathMsgMessage, _, pPlayer);
  ewrite_byte(iKiller);
  ewrite_byte(iVictim);
  ewrite_byte(iHeadshot);
  ewrite_string(szWeapon);
  emessage_end();
}
