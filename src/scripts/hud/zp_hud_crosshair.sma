#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Crosshair HUD"
#define AUTHOR "Hedgehog Fog"

new gmsgHideWeapon;
new gmsgSetFOV;
new gmsgCurWeapon;

new g_rgiPlayerHideWeapon[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgHideWeapon = get_user_msgid("HideWeapon");
    gmsgSetFOV = get_user_msgid("SetFOV");
    gmsgCurWeapon = get_user_msgid("CurWeapon");

    register_message(gmsgHideWeapon, "Message_HideWeapon");

    register_event("HideWeapon", "Event_HideWeapon", "b", "1=1");
    register_event("CurWeapon", "Event_CurWeapon", "b", "1=1");
}

public Message_HideWeapon(iMsgId, iMsgDest, pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    g_rgiPlayerHideWeapon[pPlayer] = get_msg_arg_int(1);

    return PLUGIN_CONTINUE;
}

public Event_HideWeapon(pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    @Player_UpdateCrosshair(pPlayer);

    return PLUGIN_CONTINUE;
}

public Event_CurWeapon(pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    @Player_UpdateCrosshair(pPlayer);

    return PLUGIN_CONTINUE;
}

@Player_UpdateCrosshair(this) {
    emessage_begin(MSG_ONE, gmsgHideWeapon, _, this);
    ewrite_byte(g_rgiPlayerHideWeapon[this] | HIDEHUD_CROSSHAIR | HIDEHUD_OBSERVER_CROSSHAIR);
    emessage_end();

    message_begin(MSG_ONE, gmsgSetFOV, _, this);
    write_byte(89);
    message_end();
    
    if (is_user_alive(this)) {
        new pActiveItem = get_member(this, m_pActiveItem);

        if (pActiveItem != -1) {
            new iWeaponId = get_member(pActiveItem, m_iId);
            new iClip = is_user_alive(this) ? get_member(pActiveItem, m_Weapon_iClip) : 0;

            message_begin(MSG_ONE, gmsgCurWeapon, _, this);
            write_byte(1);
            write_byte(iWeaponId);
            write_byte(iClip);
            message_end();
        }
    }

    message_begin(MSG_ONE, gmsgSetFOV, _, this);
    write_byte(get_member(this, m_iFOV));
    message_end();
}
