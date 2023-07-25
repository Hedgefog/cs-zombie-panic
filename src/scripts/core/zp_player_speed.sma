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

new Float:g_rgflPlayerMaxSpeed[MAX_PLAYERS + 1];
new bool:g_rgbPlayerDucking[MAX_PLAYERS + 1];
new bool:g_rgbPlayerMoveBack[MAX_PLAYERS + 1];
new bool:g_rgbPlayerStrafing[MAX_PLAYERS + 1];

new g_pFwPlayerSpeedUpdated;
new g_iFwResult;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHamPlayer(Ham_Item_PreFrame, "HamHook_Player_ItemPreFrame_Post", .Post = 1);
    RegisterHamPlayer(Ham_AddPlayerItem, "HamHook_Player_AddItem_Post", .Post = 1);

    register_forward(FM_CmdStart, "FMHook_CmdStart");

    register_message(get_user_msgid("AmmoPickup"), "Message_AmmoPickup");

    register_clcmd("drop", "Command_Drop");

    g_pFwPlayerSpeedUpdated = CreateMultiForward("ZP_Fw_PlayerSpeedUpdated", ET_IGNORE, FP_CELL);
}

public plugin_natives() {
    register_native("ZP_Player_UpdateSpeed", "Native_UpdateSpeed");
}

public Native_UpdateSpeed(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    UpdatePlayerSpeed(pPlayer);
}

public Command_Drop(pPlayer) {
    set_task(0.1, "Task_UpdateSpeed", pPlayer);

    return PLUGIN_CONTINUE;
}

public HamHook_Player_AddItem_Post(pPlayer) {
    UpdatePlayerSpeed(pPlayer);

    return HAM_HANDLED;
}

public FMHook_CmdStart(pPlayer, pHandle) {
    new iFlags = pev(pPlayer, pev_flags);
    new iButtons = get_uc(pHandle, UC_Buttons);
    new iOldButtons = pev(pPlayer, pev_oldbuttons);
    new bool:bPrevDucking = g_rgbPlayerDucking[pPlayer];

    g_rgbPlayerDucking[pPlayer] = iButtons & IN_DUCK && iFlags & FL_DUCKING;
    g_rgbPlayerMoveBack[pPlayer] = !!(iButtons & IN_BACK);
    g_rgbPlayerStrafing[pPlayer] = !!((iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT) && ~iButtons & IN_FORWARD);

    if ((iButtons & SPEED_BUTTONS) != (iOldButtons & SPEED_BUTTONS) || g_rgbPlayerDucking[pPlayer] != bPrevDucking) {
        UpdatePlayerSpeed(pPlayer);
    }

    return HAM_HANDLED;
}

public Message_AmmoPickup(iMsgId, iMsgDest, pPlayer) {
    UpdatePlayerSpeed(pPlayer);

    return PLUGIN_CONTINUE;
}

public HamHook_Player_ItemPreFrame_Post(pPlayer) {
    static Float:flMaxSpeed;
    pev(pPlayer, pev_maxspeed, flMaxSpeed);
    g_rgflPlayerMaxSpeed[pPlayer] = flMaxSpeed;

    UpdatePlayerSpeed(pPlayer);

    return HAM_HANDLED;
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

    ExecuteForward(g_pFwPlayerSpeedUpdated, g_iFwResult, pPlayer);

    return true;
}

Float:CalculatePlayerMaxSpeed(pPlayer) {
    new Float:flMaxSpeed = floatmin(
        ZP_Player_IsZombie(pPlayer) ? ZP_ZOMBIE_SPEED : ZP_HUMAN_SPEED,
        g_rgflPlayerMaxSpeed[pPlayer]
    );

    flMaxSpeed -= CalculatePlayerInventoryWeight(pPlayer);

    if (ZP_Player_InPanic(pPlayer)) {
        flMaxSpeed *= ZP_PANIC_SPEED_MODIFIER;
    }

    if (g_rgbPlayerDucking[pPlayer]) {
        flMaxSpeed *= ZP_DUCK_SPEED_MODIFIER;
    }

    if (g_rgbPlayerMoveBack[pPlayer]) {
        flMaxSpeed *= ZP_BACKWARD_SPEED_MODIFIER;
    } else if (g_rgbPlayerStrafing[pPlayer]) {
        flMaxSpeed *= ZP_STRAFE_SPEED_MODIFIER;
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
