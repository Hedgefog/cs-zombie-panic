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
    PISTOL_WEIGHT, // weapon_p228
    0.0, // weapon_shield
    SNIPER_WEIGHT, // weapon_scout
    0.0, // weapon_hegrenade
    RIFLE_WEIGHT, // weapon_xm1014
    0.0, // weapon_c4
    RIFLE_WEIGHT, // weapon_mac10
    RIFLE_WEIGHT, // weapon_aug
    0.0, // weapon_smokegrenade
    PISTOL_WEIGHT, // weapon_elite
    PISTOL_WEIGHT, // weapon_fiveseven
    RIFLE_WEIGHT, // weapon_ump45
    RIFLE_WEIGHT, // weapon_sg550
    RIFLE_WEIGHT, // weapon_galil
    RIFLE_WEIGHT, // weapon_famas
    PISTOL_WEIGHT, // weapon_usp
    PISTOL_WEIGHT, // weapon_glock18
    SNIPER_WEIGHT, // weapon_awp
    RIFLE_WEIGHT, // weapon_mp5navy
    BFF_WEIGHT, // weapon_m249
    RIFLE_WEIGHT, // weapon_m3
    RIFLE_WEIGHT, // weapon_m4a1
    RIFLE_WEIGHT, // weapon_tmp
    SNIPER_WEIGHT, // weapon_g3sg1
    0.0, // weapon_flashbang
    MAGNUM_WEIGHT, // weapon_deagle
    RIFLE_WEIGHT, // weapon_sg552
    RIFLE_WEIGHT, // weapon_ak47
    MELEE_WEIGHT, // weapon_knife
    RIFLE_WEIGHT, // weapon_p90
};

new const Float:g_fAmmoWeight[] = {
    0.0,
    MAGNUM_AMMO_WEIGHT, // "338Magnum"
    RIFLE_AMMO_WEIGHT, // "762Nato"
    RIFLE_AMMO_WEIGHT, // "556NatoBox"
    RIFLE_AMMO_WEIGHT, // "556Nato"
    0SHOTGUN_AMMO_WEIGHT, // "buckshot"
    PISTOL_AMMO_WEIGHT, // "45ACP"
    PISTOL_AMMO_WEIGHT, // "57mm"
    PISTOL_AMMO_WEIGHT, // "50AE"
    PISTOL_AMMO_WEIGHT, // "357SIG"
    PISTOL_AMMO_WEIGHT, // "9mm"
    GRENADE_WEIGHT, // "Flashbang"
    GRENADE_WEIGHT, // "HEGrenade"
    GRENADE_WEIGHT, // "SmokeGrenade"
    GRENADE_WEIGHT // "C4"
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
