#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Player Equipment"
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "OnPlayerSpawnEquip");
}

public OnPlayerSpawnEquip(pPlayer) {
  rg_remove_all_items(pPlayer);

  set_member(pPlayer, m_szAnimExtention, "c4");

  new Float:flMaxHealth;
  pev(pPlayer, pev_max_health, flMaxHealth);

  set_pev(pPlayer, pev_health, flMaxHealth);
  set_pev(pPlayer, pev_armorvalue, 0.0);
  set_member(pPlayer, m_iKevlar, 0);

  if (!get_member_game(m_bFreezePeriod)) {
    EquipPlayer(pPlayer);
  }

  return HC_SUPERCEDE;
}

public Round_Fw_RoundStart() {
  for (new pPlayer = 1; pPlayer <= MAX_PLAYERS; ++pPlayer) {
    if (!is_user_connected(pPlayer)) {
        continue;
    }

    if (!is_user_alive(pPlayer)) {
        continue;
    }

    EquipPlayer(pPlayer);
  }
}

EquipPlayer(pPlayer) {
  if (ZP_Player_IsZombie(pPlayer)) {
    set_pev(pPlayer, pev_max_health, ZP_ZOMBIE_HEALTH);
    CW_GiveWeapon(pPlayer, ZP_WEAPON_SWIPE);
  } else {
    set_pev(pPlayer, pev_max_health, 100.0);
    CW_GiveWeapon(pPlayer, ZP_WEAPON_CROWBAR);
    CW_GiveWeapon(pPlayer, ZP_WEAPON_PISTOL);
  }
}
