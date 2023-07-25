#pragma semicolon 1

#include <amxmodx>
#include <engine>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Money HUD"
#define AUTHOR "Hedgehog Fog"

new gmsgHideWeapon;

new g_rgiPlayerHideWeapon[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgHideWeapon = get_user_msgid("HideWeapon");

    register_event("ResetHUD", "Event_ResetHUD", "b");
    register_message(gmsgHideWeapon, "Message_HideWeapon");
}

public Event_ResetHUD(pPlayer) {
    emessage_begin(MSG_ONE, gmsgHideWeapon, _, pPlayer);
    ewrite_byte(HIDEHUD_MONEY);
    emessage_end();
    
    return PLUGIN_CONTINUE;
}

public Message_HideWeapon(iMsgId, iMsgDest, pPlayer) {
    set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | HIDEHUD_MONEY);
    g_rgiPlayerHideWeapon[pPlayer] = get_msg_arg_int(1);

    return PLUGIN_CONTINUE;
}
