#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>

#define PLUGIN "[Zombie Panic] Player Speed"
#define AUTHOR "Hedgehog Fog"

new const Float:g_pFweaponWeight[CSW_LAST_WEAPON + 1] = {
    1.0, // weapon_p228
    0.0, // weapon_shield
    2.2, // weapon_scout
    0.0, // weapon_hegrenade
    2.5, // weapon_xm1014
    0.0, // weapon_c4
    2.2, // weapon_mac10
    2.7, // weapon_aug
    0.0, // weapon_smokegrenade
    1.0, // weapon_elite
    1.0, // weapon_fiveseven
    2.2, // weapon_ump45
    2.7, // weapon_sg550
    2.5, // weapon_galil
    2.5, // weapon_famas
    1.0, // weapon_usp
    1.0, // weapon_glock18
    3.5, // weapon_awp
    2.20, // weapon_mp5navy
    3.5, // weapon_m249
    1.6, // weapon_m3
    2.63, // weapon_m4a1
    2.2, // weapon_tmp
    3.2, // weapon_g3sg1
    0.0, // weapon_flashbang
    1.3, // weapon_deagle
    2.7, // weapon_sg552
    2.70, // weapon_ak47
    0.5, // weapon_knife
    2.2, // weapon_p90
};

new const Float:g_fAmmoWeight[] = {
    0.0,
    0.1083, // "338Magnum"
    0.07, // "762Nato"
    0.07, // "556NatoBox"
    0.07, // "556Nato"
    0.20, // "buckshot"
    0.07, // "45ACP"
    0.07, // "57mm"
    0.07, // "50AE"
    0.07, // "357SIG"
    0.07, // "9mm"
    0.8, // "Flashbang"
    0.8, // "HEGrenade"
    0.8, // "SmokeGrenade"
    0.8 // "C4"
};

new Float:g_flPlayerBaseSpeed[MAX_PLAYERS + 1];
new Float:g_flPlayerMaxSpeed[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Item_PreFrame, "player", "OnPlayerItemPreFrame_Post", .Post = 1);
    RegisterHam(Ham_AddPlayerItem, "player", "OnPlayerAddItem_Post", .Post = 1);
    RegisterHam(Ham_Player_PreThink, "player", "OnPlayerPreThink_Post", .Post = 1);

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
    UpdatePlayerSpeed(pPlayer);

    return PLUGIN_CONTINUE;
}

public OnPlayerAddItem_Post(pPlayer) {
    UpdatePlayerSpeed(pPlayer);

    return HAM_HANDLED;
}

public OnPlayerPreThink_Post(pPlayer) {
    g_flPlayerBaseSpeed[pPlayer] = ZP_Player_IsZombie(pPlayer) ? ZP_ZOMBIE_SPEED : ZP_HUMAN_SPEED;

    new iButtons = pev(pPlayer, pev_button);
    new iOldButtons = pev(pPlayer, pev_oldbuttons);
    new iSpeedButtons = IN_DUCK | IN_BACK;

    if (iButtons & IN_BACK) {
        g_flPlayerBaseSpeed[pPlayer] *= 0.5;
    }

    if (iButtons & IN_DUCK && pev(pPlayer, pev_flags) & FL_DUCKING) {
        g_flPlayerBaseSpeed[pPlayer] *= 1.125;
    }

    if ((iButtons & iSpeedButtons) != (iOldButtons & iSpeedButtons)) {
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
    new Float:flBaseSpeed = g_flPlayerBaseSpeed[pPlayer];
    new Float:flWeight = CalculatePlayerInventoryWeight(pPlayer);
    new Float:flMaxSpeed = floatmin(flBaseSpeed, g_flPlayerMaxSpeed[pPlayer]);

    if (ZP_Player_InPanic(pPlayer)) {
        flMaxSpeed *= 1.125;
    } else {
        flMaxSpeed -= flWeight;
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
    new pActiveItem = get_member(pPlayer, m_pActiveItem);
    
    new Float:flWeight = 0.0;

    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(pPlayer, m_rgpPlayerItems, iSlot);

        while (pItem != -1) {
            if (pItem != pActiveItem) {
                new iWeaponId = get_member(pItem, m_iId);
                flWeight += g_pFweaponWeight[iWeaponId];
            }

            new iAmmoId = get_member(pItem, m_Weapon_iPrimaryAmmoType);
            if (iAmmoId != -1) {
                new iClip = get_member(pItem, m_Weapon_iClip);
                flWeight += iClip * g_fAmmoWeight[iAmmoId];
            }

            pItem = get_member(pItem, m_pNext);
        }
    }

    return flWeight;
}

Float:CalculatePlayerAmmoWeight(pPlayer) {
    new Float:flWeight = 0.0;

    new iSize = sizeof(g_fAmmoWeight);
    for (new iAmmoId = 0; iAmmoId < iSize; ++iAmmoId) {
        new iBpAmmo = get_member(pPlayer, m_rgAmmo, iAmmoId);
        flWeight += iBpAmmo * g_fAmmoWeight[iAmmoId];
    }

    return flWeight;
}
