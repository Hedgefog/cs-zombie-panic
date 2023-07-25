#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] RoundTimer HUD"
#define AUTHOR "Hedgehog Fog"

new gmsgHideWeapon;

new g_iPlayerHideWeapon[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgHideWeapon = get_user_msgid("HideWeapon");

    register_event("ResetHUD", "Event_ResetHUD", "b");
    register_message(gmsgHideWeapon, "Message_HideWeapon");
}

public Event_ResetHUD(pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    if (!ZP_GameRules_GetObjectiveMode()) {
        return PLUGIN_CONTINUE;
    }

    if (get_member_game(m_bFreezePeriod)) {
        return PLUGIN_CONTINUE;
    }

    emessage_begin(MSG_ONE, gmsgHideWeapon, _, pPlayer);
    ewrite_byte(HIDEHUD_TIMER);
    emessage_end();
    
    return PLUGIN_CONTINUE;
}

public Message_HideWeapon(iMsgId, iMsgDest, pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    if (!ZP_GameRules_GetObjectiveMode()) {
        return PLUGIN_CONTINUE;
    }

    if (get_member_game(m_bFreezePeriod)) {
        return PLUGIN_CONTINUE;
    }

    set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | HIDEHUD_TIMER);
    g_iPlayerHideWeapon[pPlayer] = get_msg_arg_int(1);

    return PLUGIN_CONTINUE;
}
