#pragma semicolon 1

#include <amxmodx>
#include <engine>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Money HUD"
#define AUTHOR "Hedgehog Fog"

#define HIDEHUD_MONEY (1<<5)

new gmsgHideWeapon;

new g_iPlayerHideWeapon[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgHideWeapon = get_user_msgid("HideWeapon");

    register_event("ResetHUD", "OnResetHUD", "b");
    register_message(gmsgHideWeapon, "OnMessage_HideWeapon");
}

public OnResetHUD(pPlayer) {
    emessage_begin(MSG_ONE, gmsgHideWeapon, _, pPlayer);
    ewrite_byte(HIDEHUD_MONEY);
    emessage_end();
    
    return PLUGIN_CONTINUE;
}

public OnMessage_HideWeapon(iMsgId, iMsgDest, pPlayer) {
    set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | HIDEHUD_MONEY);
    g_iPlayerHideWeapon[pPlayer] = get_msg_arg_int(1);

    return PLUGIN_CONTINUE;
}
