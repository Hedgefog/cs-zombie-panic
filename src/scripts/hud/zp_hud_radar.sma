#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Radar"
#define AUTHOR "Hedgehog Fog"

#define SCORE_STATUS_DEAD BIT(0)

new gmsgScoreAttrib;
new gmsgHideWeapon;
new gmsgRadar;
new gmsgCrosshair;

new bool:g_rgbPlayerInScore[MAX_PLAYERS + 1];
new g_rgiPlayerHideWeapon[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgScoreAttrib = get_user_msgid("ScoreAttrib");
    gmsgHideWeapon = get_user_msgid("HideWeapon");
    gmsgRadar = get_user_msgid("Radar");
    gmsgCrosshair = get_user_msgid("Crosshair");

    register_message(gmsgScoreAttrib, "Message_ScoreAttrib");
    register_message(gmsgHideWeapon, "Message_HideWeapon");
    register_message(gmsgRadar, "Message_Radar");
}

public Message_Radar(iMsgId, iMsgDest, pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    return PLUGIN_HANDLED;
}

public Message_ScoreAttrib(iMsgId, iMsgDest, pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    if (get_msg_arg_int(1) == pPlayer) {
        set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) | (g_rgbPlayerInScore[pPlayer] ? 0 : SCORE_STATUS_DEAD));
    }

    return PLUGIN_CONTINUE;
}

public Message_HideWeapon(iMsgId, iMsgDest, pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }
    
    g_rgiPlayerHideWeapon[pPlayer] = get_msg_arg_int(1);

    return PLUGIN_CONTINUE;
}
