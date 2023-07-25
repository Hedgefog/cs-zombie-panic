#pragma semicolon 1

#include <amxmodx>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Item Pickup HUD"
#define AUTHOR "Hedgehog Fog"

new gmsgWeapPickup;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgWeapPickup = get_user_msgid("WeapPickup");
    register_message(gmsgWeapPickup, "Message_WeapPickup");
}

public Message_WeapPickup(iMsgId, iDest, pPlayer) {
    if (is_user_bot(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    return ZP_Player_IsZombie(pPlayer) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}
