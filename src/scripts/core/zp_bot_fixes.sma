#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Bot Fixes"
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    register_forward(FM_AddToFullPack, "OnAddToFullPack");
}

public OnAddToFullPack(es, e, pEntity, pHost, pHostFlags, pPlayer, pSet) {
  if (pEntity == pHost) {
    return FMRES_IGNORED;
  }

  if (!UTIL_IsPlayer(pHost)) {
    return FMRES_IGNORED;
  }

  if (!is_user_bot(pHost)) {
    return FMRES_IGNORED;
  }

  static szClassname[32];
  pev(pEntity, pev_classname, szClassname, charsmax(szClassname));

  if (ZP_Player_IsZombie(pHost)) {
      if (equal(szClassname, "weaponbox") || equali(szClassname, "item_", 5)) {
        return FMRES_SUPERCEDE;
      }
  } else {
    if (equal(szClassname, "item_healthkit")) {
      static Float:flMaxHealth;
      pev(pHost, pev_max_health, flMaxHealth);

      static Float:flHealth;
      pev(pHost, pev_health, flHealth);

      if (flHealth >= flMaxHealth) {
        return FMRES_SUPERCEDE;
      }
    } else if (equal(szClassname, "item_healthkit")) {
      static Float:flArmorValue;
      pev(pHost, pev_armorvalue, flArmorValue);
      
      if (flArmorValue >= 100.0) {
        return FMRES_SUPERCEDE;
      }
    }
  }

  return FMRES_IGNORED;
}
