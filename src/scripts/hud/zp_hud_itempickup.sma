#pragma semicolon 1

#include <amxmodx>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Item Pickup HUD"
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  register_message(get_user_msgid("WeapPickup"), "OnMessage");
}

public OnMessage(iMsgId, iDest, pPlayer) {
  return ZP_Player_IsZombie(pPlayer) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}
