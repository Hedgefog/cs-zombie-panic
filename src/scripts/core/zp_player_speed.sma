#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>

#define PLUGIN "[Zombie Panic] Player Speed"
#define AUTHOR "Hedgehog Fog"

#define AMMO_TYPE_COUNT 16

new const Float:g_fWeaponWeight[CSW_P90 + 1] = {
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

new const Float:g_fAmmoWeight[AMMO_TYPE_COUNT] = {
  0.0, // ""
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

new Float:g_fPlayerMaxSpeed[MAX_PLAYERS + 1];
new bool:g_bPlayerDuck[MAX_PLAYERS + 1];

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
  UpdatePlayerSpeed(pPlayer);
  return PLUGIN_CONTINUE;
}

public OnPlayerAddItem_Post(pPlayer) {
    UpdatePlayerSpeed(pPlayer);
    return HAM_HANDLED;
}

public OnMessage_AmmoPickup(iMsgId, iMsgDest, pPlayer) {
    UpdatePlayerSpeed(pPlayer);
    return PLUGIN_CONTINUE;
}

public OnPlayerItemPreFrame_Post(pPlayer) {
    static Float:flMaxSpeed;
    pev(pPlayer, pev_maxspeed, flMaxSpeed);
    g_fPlayerMaxSpeed[pPlayer] = flMaxSpeed;

    UpdatePlayerSpeed(pPlayer);
    return HAM_HANDLED;
}

public OnCmdStart(pPlayer, pHandle) {
  new bool:bDuck = !!(pev(pPlayer, pev_flags) & FL_DUCKING) || !!(get_uc(pHandle, UC_Buttons) & IN_DUCK);

  if (bDuck != g_bPlayerDuck[pPlayer]) {
    g_bPlayerDuck[pPlayer] = bDuck;
    UpdatePlayerSpeed(pPlayer);
  }
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

  // set_hudmessage(0, 200, 30, -1.0, 0.35, 0, 0.0, 1.0);
  // show_hudmessage(pPlayer, "MaxSpeed: %f^nTotal: %f", g_fPlayerMaxSpeed[pPlayer], flMaxSpeed);

  // client_print(pPlayer, print_center, "[%f] MaxSpeed: %f^nTotal: %f", get_gametime(), g_fPlayerMaxSpeed[pPlayer], flMaxSpeed);

  return true;
}

Float:GetPlayerBaseSpeed(pPlayer) {
  return ZP_Player_IsZombie(pPlayer) ? ZP_ZOMBIE_SPEED : ZP_HUMAN_SPEED;
}

Float:CalculatePlayerMaxSpeed(pPlayer) {
  if (ZP_Player_InPanic(pPlayer)) {
    return ZP_HUMAN_SPEED * 1.125;
  }

  new Float:flWeight = CalculatePlayerInventoryWeight(pPlayer);
  new Float:flBaseSpeed = GetPlayerBaseSpeed(pPlayer);
  new Float:flMaxSpeed = floatmin(flBaseSpeed, g_fPlayerMaxSpeed[pPlayer]);

  return (flMaxSpeed * (g_bPlayerDuck[pPlayer] ? 1.125 : 1.0)) - flWeight;
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
        flWeight += g_fWeaponWeight[iWeaponId];
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

  new iAmmoCount = AMMO_TYPE_COUNT;
  for (new iAmmoId = 0; iAmmoId < iAmmoCount; ++iAmmoId) {
    new iBpAmmo = get_member(pPlayer, m_rgAmmo, iAmmoId);
    flWeight += iBpAmmo * g_fAmmoWeight[iAmmoId];
  }

  return flWeight;
}
