#pragma semicolon 1

#include <amxmodx>

#include <api_rounds>
#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Radio"
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    register_message(get_user_msgid("SendAudio"), "OnMessage_SendAudio");
}

public OnMessage_SendAudio()  {
    static szAudio[8];
    get_msg_arg_string(2, szAudio, charsmax(szAudio));

    return equali(szAudio, "%!MRAD_", 7) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}
