#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>
#include <api_rounds>

#define PLUGIN "[Zombie Panic] Player Speed"
#define AUTHOR "Hedgehog Fog"

#define SPEED_BUTTONS (IN_DUCK | IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT)

new Float:g_flPlayerMaxSpeed[MAX_PLAYERS + 1];
new bool:g_bPlayerDucking[MAX_PLAYERS + 1];
new bool:g_bPlayerMoveBack[MAX_PLAYERS + 1];
new bool:g_bPlayerStrafing[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Item_PreFrame, "player", "OnPlayerItemPreFrame_Post", .Post = 1);
    RegisterHam(Ham_AddPlayerItem, "player", "OnPlayerAddItem_Post", .Post = 1);

    register_forward(FM_CmdStart, "OnCmdStart");

    register_message(get_user_msgid("AmmoPickup"), "OnMessage_AmmoPickup");

    register_clcmd("drop", "OnClCmd_Drop");
}

public plugin_natives() {
    register_native("ZP_Player_UpdateSpeed", "Native_UpdateSpeed");
}

public Native_UpdateSpeed(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    UpdatePlayerSpeed(pPlayer);
}

public OnClCmd_Drop(pPlayer) {
    set_task(0.1, "Task_UpdateSpeed", pPlayer);

    return PLUGIN_CONTINUE;
}

public OnPlayerAddItem_Post(pPlayer) {
    UpdatePlayerSpeed(pPlayer);

    return HAM_HANDLED;
}

public OnCmdStart(pPlayer, pHandle) {
    new iFlags = pev(pPlayer, pev_flags);
    new iButtons = get_uc(pHandle, UC_Buttons);
    new iOldButtons = pev(pPlayer, pev_oldbuttons);
    new bool:bPrevDucking = g_bPlayerDucking[pPlayer];

    g_bPlayerDucking[pPlayer] = iButtons & IN_DUCK && iFlags & FL_DUCKING;
    g_bPlayerMoveBack[pPlayer] = !!(iButtons & IN_BACK);
    g_bPlayerStrafing[pPlayer] = !!((iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT) && ~iButtons & IN_FORWARD);

    if ((iButtons & SPEED_BUTTONS) != (iOldButtons & SPEED_BUTTONS) || g_bPlayerDucking[pPlayer] != bPrevDucking) {
        UpdatePlayerSpeed(pPlayer);
    }

    return HAM_HANDLED;
}

public OnMessage_AmmoPickup(iMsgId, iMsgDest, pPlayer) {
    UpdatePlayerSpeed(pPlayer);

    return PLUGIN_CONTINUE;
}

public OnPlayerItemPreFrame_Post(pPlayer) {
    static Float:flMaxSpeed;
    pev(pPlayer, pev_maxspeed, flMaxSpeed);
    g_flPlayerMaxSpeed[pPlayer] = flMaxSpeed;

    UpdatePlayerSpeed(pPlayer);

    return HAM_HANDLED;
}

public TaskUpdatePlayerSpeed(iTaskId) {
    new pPlayer = iTaskId;
    UpdatePlayerSpeed(pPlayer);
}

bool:UpdatePlayerSpeed(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return false;
    }

    if (get_member_game(m_bFreezePeriod)) {
        return false;
    }

    new Float:flMaxSpeed = CalculatePlayerMaxSpeed(pPlayer);
    set_pev(pPlayer, pev_maxspeed, flMaxSpeed);

    return true;
}

Float:CalculatePlayerMaxSpeed(pPlayer) {
    new Float:flMaxSpeed = floatmin(
        ZP_Player_IsZombie(pPlayer) ? ZP_ZOMBIE_SPEED : ZP_HUMAN_SPEED,
        g_flPlayerMaxSpeed[pPlayer]
    );

    if (g_bPlayerDucking[pPlayer]) {
        flMaxSpeed *= 1.25;
    }

    if (g_bPlayerMoveBack[pPlayer]) {
        flMaxSpeed *= ZP_BACKWARD_SPEED_MODIFIER;
    } else if (g_bPlayerStrafing[pPlayer]) {
        flMaxSpeed *= ZP_STRAFE_SPEED_MODIFIER;
    }

    flMaxSpeed -= CalculatePlayerInventoryWeight(pPlayer);

    if (ZP_Player_InPanic(pPlayer)) {
        flMaxSpeed *= ZP_PANIC_SPEED_MODIFIER;
    }

    return flMaxSpeed;
}

Float:CalculatePlayerInventoryWeight(pPlayer) {
    if (ZP_Player_IsZombie(pPlayer)) {
        return 0.0;
    }

    new Float:flWeight = 0.0;
    flWeight += CalculatePlayerWeaponsWeight(pPlayer);
    flWeight += CalculatePlayerAmmoWeight(pPlayer);

    return flWeight;
}

Float:CalculatePlayerWeaponsWeight(pPlayer) {
    // new pActiveItem = get_member(pPlayer, m_pActiveItem);

    new Float:flWeight = 0.0;

    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(pPlayer, m_rgpPlayerItems, iSlot);

        while (pItem != -1) {
            flWeight += ZP_Weapons_GetWeight(pItem);

            new iAmmoId = get_member(pItem, m_Weapon_iPrimaryAmmoType);
            if (iAmmoId != -1) {
                new iAmmoHandler = ZP_Ammo_GetHandlerById(iAmmoId);
                if (iAmmoHandler != -1) {
                    new iClip = get_member(pItem, m_Weapon_iClip);
                    flWeight += iClip * ZP_Ammo_GetWeight(iAmmoHandler);
                }
            }

            pItem = get_member(pItem, m_pNext);
        }
    }

    return flWeight;
}

Float:CalculatePlayerAmmoWeight(pPlayer) {
    new Float:flWeight = 0.0;

    new iSize = sizeof(AMMO_LIST);
    for (new iAmmoId = 0; iAmmoId < iSize; ++iAmmoId) {
        new iBpAmmo = get_member(pPlayer, m_rgAmmo, iAmmoId);
        new iAmmoHandler = ZP_Ammo_GetHandlerById(iAmmoId);
        if (iAmmoHandler != -1) {
            flWeight += iBpAmmo * ZP_Ammo_GetWeight(iAmmoHandler);
        }
    }

    return flWeight;
}

public Task_UpdateSpeed(iTaskId) {
    new pPlayer = iTaskId;
    UpdatePlayerSpeed(pPlayer);
}
