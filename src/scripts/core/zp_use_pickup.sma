#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Use Pickup"
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Player_PreThink, "player", "OnPlayerPreThink_Post", .Post = 1);
}

public OnPlayerPreThink_Post(pPlayer) {
  new iButtons = pev(pPlayer, pev_button);
  new iOldButtons = pev(pPlayer, pev_oldbuttons);

  if (~iButtons & IN_USE) {
    return HAM_IGNORED;
  }

  if (iOldButtons & IN_USE) {
    return HAM_IGNORED;
  }

  static Float:vecSrc[3];
  ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);

  static Float:vecEnd[3];
  pev(pPlayer, pev_v_angle, vecEnd);
  engfunc(EngFunc_MakeVectors, vecEnd);
  get_global_vector(GL_v_forward, vecEnd);

  for (new i = 0; i < 3; ++i) {
    vecEnd[i] = vecSrc[i] + (vecEnd[i] * 52.0);
  }

  new pTr = create_tr2();
  engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTr);
  get_tr2(pTr, TR_vecEndPos, vecEnd);
  free_tr2(pTr);

  new pEntity;
  while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecEnd, 1.0)) != 0) {
    if (pev(pEntity, pev_solid) == SOLID_NOT) {
      continue;
    }

    static szClassname[32];
    pev(pEntity, pev_classname, szClassname, charsmax(szClassname));

    if (equal(szClassname, "weaponbox") || equali(szClassname, "item_", 5)) {
      ExecuteHamB(Ham_Touch, pEntity, pPlayer);
      break;
    }
  }

  return HAM_HANDLED;
}
