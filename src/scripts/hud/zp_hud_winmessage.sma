#include <amxmodx>
#include <fakemeta>

#include <zombiepanic>

#include <screenfade_util>

#define PLUGIN "[Zombie Panic] Win Message"
#define AUTHOR "Hedgehog Fog"

public plugin_init()
{
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    register_message(get_user_msgid("TextMsg"), "OnMessage_OnTextMsg");
    register_message(get_user_msgid("SendAudio"), "OnMessage_SendAudio");
}

public OnMessage_OnTextMsg(iMsgId, iDest, pPlayer) {
    static szMessage[32];
    get_msg_arg_string(2, szMessage, charsmax(szMessage));

    if (equal(szMessage, ZP_ZOMBIE_WIN_MESSAGE)) {
        ShowWinMessage("%s have conquered...", ZP_ZOMBIE_TEAM_NAME);
    } else if (equal(szMessage, ZP_HUMAN_WIN_MESSAGE)) {
        ShowWinMessage("%s win!", ZP_HUMAN_TEAM_NAME);
    } else {
        return PLUGIN_CONTINUE;
    }

    return PLUGIN_HANDLED;
}

ShowWinMessage(const szMessage[], any:...) {
    new szBuffer[128];
    vformat(szBuffer, charsmax(szBuffer), szMessage, 2);

    UTIL_ScreenFade(0, {0, 0, 0}, 1.0, ZP_NEW_ROUND_DELAY, 255, FFADE_OUT | FFADE_STAYOUT);
    set_dhudmessage(255, 255, 255, -1.0, -1.0);
    show_dhudmessage(0, szBuffer);
}

public OnMessage_SendAudio(iMsgId, iDest, pPlayer) {
    static szMessage[32];
    get_msg_arg_string(2, szMessage, charsmax(szMessage));

    if (equal(szMessage[7], "terwin")) {
        return PLUGIN_HANDLED;
    }

    if (equal(szMessage[7], "ctwin")) {
        return PLUGIN_HANDLED;
    }

    if (equal(szMessage[7], "rounddraw")) {
        return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}
