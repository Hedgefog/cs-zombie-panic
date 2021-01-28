#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#include <screenfade_util>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Zombie Vision"
#define AUTHOR "Hedgehog Fog"

new bool:g_bPlayerVision[MAX_PLAYERS + 1];

new g_iFwZombieVision;
new g_iFwResult;

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", .Post = 1);
  RegisterHam(Ham_Killed, "player", "OnPlayerKilled", .Post = 1);

  register_forward(FM_AddToFullPack, "OnAddToFullPack_Post", 1);

  g_iFwZombieVision = CreateMultiForward("ZP_Fw_PlayerZombieVision", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_natives() {
  register_native("ZP_Player_ToggleZombieVision", "Native_Toggle");
}

public bool:Native_Toggle(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  return Toggle(pPlayer);
}

public OnClCmd_ZombieVision(pPlayer) {
  Toggle(pPlayer);
  return HAM_HANDLED;
}

public OnPlayerSpawn(pPlayer) {
  if (!is_user_alive(pPlayer)) {
    return HAM_IGNORED;
  }

  SetZombieVision(pPlayer, false);

  if (!ZP_Player_IsZombie(pPlayer)) {
    return HAM_IGNORED;
  }

  return HAM_HANDLED;
}

public OnPlayerKilled(pPlayer) {
  SetZombieVision(pPlayer, false);

  if (!ZP_Player_IsZombie(pPlayer)) {
    return HAM_IGNORED;
  }

  return HAM_HANDLED;
}

public OnAddToFullPack_Post(es, e, pEntity, pHost, pHostFlags, pPlayer, pSet) {
  if (pEntity == pHost) {
    return FMRES_IGNORED;
  }

  if (!UTIL_IsPlayer(pHost)) {
    return FMRES_IGNORED;
  }

  if (!UTIL_IsPlayer(pEntity)) {
    return FMRES_IGNORED;
  }

  if (!is_user_alive(pHost)) {
    return FMRES_IGNORED;
  }

  if (!is_user_alive(pEntity)) {
    return FMRES_IGNORED;
  }
  
  if (g_bPlayerVision[pHost]) {
    set_es(es, ES_RenderMode, kRenderNormal);
    set_es(es, ES_RenderFx, kRenderFxGlowShell);
    set_es(es, ES_RenderAmt, 1);

    if (!ZP_Player_IsZombie(pEntity)) {
      static Float:flMaxHealth;
      pev(pEntity, pev_max_health, flMaxHealth);

      static Float:flHealth;
      pev(pEntity, pev_health, flHealth);

      new Float:flBrightness = (1.0 - (flHealth / flMaxHealth)) * 255.0;
      new iColor[3] = {0, 0, 0};
      iColor[0] = floatround(flBrightness);

      set_es(es, ES_RenderColor, iColor);
    } else {
      set_es(es, ES_RenderColor, { 0, 255, 0});
    }
  }

  return FMRES_HANDLED;
}

bool:Toggle(pPlayer) {
  SetZombieVision(pPlayer, !g_bPlayerVision[pPlayer]);
  return g_bPlayerVision[pPlayer];
}

SetZombieVision(pPlayer, bool:bValue) {
  if (bValue && !ZP_Player_IsZombie(pPlayer)) {
    return;
  }

  g_bPlayerVision[pPlayer] = bValue;

  remove_task(pPlayer);

  if (bValue) {
    set_task(0.1, "TaskLight", pPlayer, _, _, "b");
  }

  ExecuteForward(g_iFwZombieVision, g_iFwResult, pPlayer, bValue);
}

public TaskLight(iTaskId) {
  new pPlayer = iTaskId;

  static Float:vecOrigin[3];
  pev(pPlayer, pev_origin, vecOrigin);

  // new iBrightness = 1;

  // engfunc(EngFunc_MessageBegin, MSG_ONE, SVC_TEMPENTITY, vecOrigin, pPlayer);
  // write_byte(TE_DLIGHT);
  // engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  // engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  // engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  // write_byte(127);
  // write_byte(iBrightness);
  // write_byte(iBrightness);
  // write_byte(iBrightness);
  // write_byte(5);
  // write_byte(0);
  // message_end();

  UTIL_ScreenFade(pPlayer, {255, 195, 195}, 1.0, 0.1125, 20, FFADE_IN, .bExternal = true);
}
