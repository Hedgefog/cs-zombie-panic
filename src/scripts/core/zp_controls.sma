#pragma semicolon 1

#include <amxmodx>
#include <engine>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Controls"
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    register_clcmd("changeammotype", "Command_NextAmmo");
    register_clcmd("dropammo", "Command_DropAmmo");
    register_clcmd("dua", "Command_DropUnactiveAmmo");
    register_clcmd("panic", "Command_Panic");

    register_clcmd("radio1", "Command_NextAmmo");
    register_clcmd("radio2", "Command_DropAmmo");
    register_clcmd("radio3", "Command_DropUnactiveAmmo");
    register_clcmd("buyequip", "Command_Panic");

    register_impulse(100, "Impulse_100");
}

public Impulse_100(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    if (ZP_Player_IsZombie(pPlayer)) {
        ZP_Player_ToggleZombieVision(pPlayer);
    } else {
        ZP_Player_ToggleFlashlight(pPlayer);
    }

    return PLUGIN_HANDLED;
}

public Command_NextAmmo(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    if (ZP_Player_IsZombie(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    ZP_Player_NextAmmo(pPlayer);
    return PLUGIN_HANDLED;
}

public Command_DropAmmo(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    if (ZP_Player_IsZombie(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    ZP_Player_DropAmmo(pPlayer);
    return PLUGIN_HANDLED;
}

public Command_DropUnactiveAmmo(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    if (ZP_Player_IsZombie(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    ZP_Player_DropUnactiveAmmo(pPlayer);
    return PLUGIN_HANDLED;
}

public Command_Panic(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    if (ZP_Player_IsZombie(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    ZP_Player_Panic(pPlayer);
    return PLUGIN_HANDLED;
}
