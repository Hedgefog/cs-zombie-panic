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

new g_bPlayerInScore[MAX_PLAYERS + 1];
new g_iPlayerHideWeapon[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgScoreAttrib = get_user_msgid("ScoreAttrib");
    gmsgHideWeapon = get_user_msgid("HideWeapon");
    gmsgRadar = get_user_msgid("Radar");
    gmsgCrosshair = get_user_msgid("Crosshair");

    register_message(gmsgScoreAttrib, "OnMessage_ScoreAttrib");
    register_message(gmsgHideWeapon, "OnMessage_HideWeapon");
    register_message(gmsgRadar, "OnMessage_Radar");

    // register_forward(FM_CmdStart, "OnCmdStart");
}

public OnMessage_Radar(iMsgId, iMsgDest, pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    return PLUGIN_HANDLED;
}

public OnMessage_ScoreAttrib(iMsgId, iMsgDest, pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    if(get_msg_arg_int(1) == pPlayer) {
        set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) | (g_bPlayerInScore[pPlayer] ? 0 : SCORE_STATUS_DEAD));
    }

    return PLUGIN_CONTINUE;
}

public OnMessage_HideWeapon(iMsgId, iMsgDest, pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }
    
    g_iPlayerHideWeapon[pPlayer] = get_msg_arg_int(1);

    return PLUGIN_CONTINUE;
}

public OnCmdStart(pPlayer, pCmd) {
    // new iButtons = pev(pPlayer, pev_button);
    new iButtons = get_uc(pCmd, UC_Buttons);
    new iOldButtons = pev(pPlayer, pev_oldbuttons);

    if (iButtons & IN_SCORE == iOldButtons & IN_SCORE)    {
        return PLUGIN_CONTINUE;
    }

    g_bPlayerInScore[pPlayer] = !!(iButtons & IN_SCORE);

    emessage_begin(MSG_ONE, gmsgScoreAttrib, _, pPlayer);
    ewrite_byte(pPlayer);
    ewrite_byte(g_bPlayerInScore[pPlayer] ? 0 : SCORE_STATUS_DEAD);
    emessage_end();

    emessage_begin(MSG_ONE, gmsgHideWeapon, _, pPlayer);
    if (g_bPlayerInScore[pPlayer]) {
        ewrite_byte(g_iPlayerHideWeapon[pPlayer] | HIDEHUD_ALL);
    } else {
        ewrite_byte(g_iPlayerHideWeapon[pPlayer] & ~HIDEHUD_ALL);
    }
    emessage_end();

    emessage_begin(MSG_ONE, gmsgCrosshair, _, pPlayer);
    ewrite_byte(0);
    emessage_end();

    return PLUGIN_CONTINUE;
}
