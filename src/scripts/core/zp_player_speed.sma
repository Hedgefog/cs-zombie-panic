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
    ZP_WEIGHT_PISTOL, // weapon_p228
    0.0, // weapon_shield
    ZP_WEIGHT_SNIPER, // weapon_scout
    0.0, // weapon_hegrenade
    ZP_WEIGHT_RIFLE, // weapon_xm1014
    0.0, // weapon_c4
    ZP_WEIGHT_RIFLE, // weapon_mac10
    ZP_WEIGHT_RIFLE, // weapon_aug
    0.0, // weapon_smokegrenade
    ZP_WEIGHT_PISTOL, // weapon_elite
    ZP_WEIGHT_PISTOL, // weapon_fiveseven
    ZP_WEIGHT_RIFLE, // weapon_ump45
    ZP_WEIGHT_RIFLE, // weapon_sg550
    ZP_WEIGHT_RIFLE, // weapon_galil
    ZP_WEIGHT_RIFLE, // weapon_famas
    ZP_WEIGHT_PISTOL, // weapon_usp
    ZP_WEIGHT_PISTOL, // weapon_glock18
    ZP_WEIGHT_SNIPER, // weapon_awp
    ZP_WEIGHT_RIFLE, // weapon_mp5navy
    ZP_WEIGHT_BFF, // weapon_m249
    ZP_WEIGHT_RIFLE, // weapon_m3
    ZP_WEIGHT_RIFLE, // weapon_m4a1
    ZP_WEIGHT_RIFLE, // weapon_tmp
    ZP_WEIGHT_SNIPER, // weapon_g3sg1
    0.0, // weapon_flashbang
    ZP_WEIGHT_MAGNUM, // weapon_deagle
    ZP_WEIGHT_RIFLE, // weapon_sg552
    ZP_WEIGHT_RIFLE, // weapon_ak47
    ZP_WEIGHT_MELEE, // weapon_knife
    ZP_WEIGHT_RIFLE, // weapon_p90
};

new const Float:g_fAmmoWeight[] = {
    0.0,
    ZP_WEIGHT_MAGNUM_AMMO, // "338Magnum"
    ZP_WEIGHT_RIFLE_AMMO, // "762Nato"
    ZP_WEIGHT_RIFLE_AMMO, // "556NatoBox"
    ZP_WEIGHT_RIFLE_AMMO, // "556Nato"
    ZP_WEIGHT_SHOTGUN_AMMO, // "buckshot"
    ZP_WEIGHT_PISTOL_AMMO, // "45ACP"
    ZP_WEIGHT_PISTOL_AMMO, // "57mm"
    ZP_WEIGHT_PISTOL_AMMO, // "50AE"
    ZP_WEIGHT_PISTOL_AMMO, // "357SIG"
    ZP_WEIGHT_PISTOL_AMMO, // "9mm"
    ZP_WEIGHT_GRENADE, // "Flashbang"
    ZP_WEIGHT_GRENADE, // "HEGrenade"
    ZP_WEIGHT_GRENADE, // "SmokeGrenade"
    ZP_WEIGHT_GRENADE // "C4"
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
    new iSpeedButtons = IN_DUCK | IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT;

    if (iButtons & IN_BACK || ((iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT) && ~iButtons & IN_FORWARD)) {
        g_flPlayerBaseSpeed[pPlayer] *= 0.85;
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
    // new pActiveItem = get_member(pPlayer, m_pActiveItem);

    new Float:flWeight = 0.0;

    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(pPlayer, m_rgpPlayerItems, iSlot);

        while (pItem != -1) {
            // if (pItem != pActiveItem) {
            new iWeaponId = get_member(pItem, m_iId);
            flWeight += g_pFweaponWeight[iWeaponId];
            // }

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
