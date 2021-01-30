#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Use Pickup"
#define AUTHOR "Hedgehog Fog"

#define HIGHLIGHT_COLOR 96, 64, 16

new const g_rgszPickupEntities[][] = {
  "armoury_entity",
  "item_battery",
  "item_healthkit",
  "armoury_entity",
  "weaponbox",
  "weapon_shield",
  "grenade"
};

new bool:g_bBlockTouch = true;
new Float:g_flPlayerLastFind[MAX_PLAYERS + 1] = { 0.0, ... };
new g_pPlayerAimItem[MAX_PLAYERS + 1] = { -1, ... };

new g_iFwAimItem;
new g_iFwResult;
new g_pCvarUsePickup;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Player_PreThink, "player", "OnPlayerPreThink_Post", .Post = 1);

    for (new i = 0; i < sizeof(g_rgszPickupEntities); ++i) {
      RegisterHam(Ham_Touch, g_rgszPickupEntities[i], "OnItemTouch", .Post = 0);
    }

    register_forward(FM_AddToFullPack, "OnAddToFullPack_Post", 1);

    g_pCvarUsePickup = register_cvar("zp_use_pickup", "1");
    g_iFwAimItem = CreateMultiForward("ZP_Fw_Player_AimItem", ET_IGNORE, FP_CELL, FP_CELL);
}

public OnItemTouch(pPlayer) {
  return get_pcvar_num(g_pCvarUsePickup) && g_bBlockTouch ? HAM_SUPERCEDE : HAM_HANDLED;
}

public OnAddToFullPack_Post(es, e, pEntity, pHost, pHostFlags, pPlayer, pSet) {
  if (!get_pcvar_num(g_pCvarUsePickup)) {
    return FMRES_IGNORED;
  }

  if (!UTIL_IsPlayer(pHost)) {
    return FMRES_IGNORED;
  }

  if (!pev_valid(pEntity)) {
    return FMRES_IGNORED;
  }

  if (pEntity == g_pPlayerAimItem[pHost]) {
    set_es(es, ES_RenderMode, kRenderNormal);
    set_es(es, ES_RenderFx, kRenderFxGlowShell);
    set_es(es, ES_RenderAmt, 1);
    set_es(es, ES_RenderColor, {HIGHLIGHT_COLOR});
  }

  return FMRES_HANDLED;
}

public OnPlayerPreThink_Post(pPlayer) {
  if (ZP_Player_IsZombie(pPlayer)) {
    return HAM_IGNORED;
  }

  new iButtons = pev(pPlayer, pev_button);
  new iOldButtons = pev(pPlayer, pev_oldbuttons);
  new bool:bUsePressed = (iButtons & IN_USE && ~iOldButtons & IN_USE);

  if (!bUsePressed && get_gametime() - g_flPlayerLastFind[pPlayer] < 0.1) {
    return HAM_IGNORED;
  }

  new pPrevAimItem = g_pPlayerAimItem[pPlayer];
  g_pPlayerAimItem[pPlayer] = -1;

  static Float:vecSrc[3];
  ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);

  static Float:vecEnd[3];
  pev(pPlayer, pev_v_angle, vecEnd);
  engfunc(EngFunc_MakeVectors, vecEnd);
  get_global_vector(GL_v_forward, vecEnd);

  for (new i = 0; i < 3; ++i) {
    vecEnd[i] = vecSrc[i] + (vecEnd[i] * 64.0);
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

    if (~pev(pEntity, pev_flags) & FL_ONGROUND) {
      continue;
    }

    static szClassname[32];
    pev(pEntity, pev_classname, szClassname, charsmax(szClassname));

    if (equal(szClassname, "weaponbox") || equali(szClassname, "item_", 5)) {
      g_pPlayerAimItem[pPlayer] = pEntity;

      if (pEntity != pPrevAimItem) {
        ExecuteForward(g_iFwAimItem, g_iFwResult, pPlayer, pEntity);
      }

      if (bUsePressed) {
          g_bBlockTouch = false;
          ExecuteHamB(Ham_Touch, pEntity, pPlayer);
          g_bBlockTouch = true;
      }

      break;
    }
  }

  g_flPlayerLastFind[pPlayer] = get_gametime();

  return HAM_HANDLED;
}
