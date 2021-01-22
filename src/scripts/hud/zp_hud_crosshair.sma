#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Crosshair HUD"
#define AUTHOR "Hedgehog Fog"

new gmsgHideWeapon;
new gmsgSetFOV;
new gmsgCurWeapon;

new g_iPlayerHideWeapon[MAX_PLAYERS + 1];

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  gmsgHideWeapon = get_user_msgid("HideWeapon");
  gmsgSetFOV = get_user_msgid("SetFOV");
  gmsgCurWeapon = get_user_msgid("CurWeapon");

  register_message(gmsgHideWeapon, "OnMessage_HideWeapon");
  
  register_event("CurWeapon", "OnEvent_CurWeapon", "be", "1=1");
}

public OnMessage_HideWeapon(iMsgId, iMsgDest, pPlayer) {
  g_iPlayerHideWeapon[pPlayer] = get_msg_arg_int(1);
}

public OnEvent_CurWeapon(pPlayer) {
  message_begin(MSG_ONE, gmsgHideWeapon, _, pPlayer);
  write_byte(g_iPlayerHideWeapon[pPlayer] | HIDEHUD_CROSSHAIR | BIT(7));
  message_end();

  message_begin(MSG_ONE, gmsgSetFOV, _, pPlayer);
  write_byte(89);
  message_end();

  message_begin(MSG_ONE, gmsgCurWeapon, _, pPlayer);
  write_byte(read_data(1));
  write_byte(read_data(2));
  write_byte(read_data(3));
  message_end();

  message_begin(MSG_ONE, gmsgSetFOV, _, pPlayer);
  write_byte(get_member(pPlayer, m_iFOV));
  message_end();
}
