#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Flashlight"
#define AUTHOR "Hedgehog Fog"

#define FLASHLIGHT_CHARGE_MAX 100.0
#define FLASHLIGHT_CHARGE_DEF FLASHLIGHT_CHARGE_MAX
#define FLASHLIGHT_RATE 0.025
#define FLASHLIGHT_CONSUMPTION_RATE 0.5
#define FLASHLIGHT_RECOVERY_RATE 0.5
#define FLASHLIGHT_MAX_DISTANCE 1024.0
#define FLASHLIGHT_MAX_CHARGE 100.0
#define FLASHLIGHT_MIN_CHARGE 0.0

#define TASKID_FLASHLIGHT 100
#define TASKID_FLASHLIGHT_HUD 200

enum PlayerFlashlight {
  bool:PlayerFlashlight_On,
  Float:PlayerFlashlight_Charge,
  PlayerFlashlight_ConeEntity,
  Float:PlayerFlashlight_LastThink
}

new gmsgFlashlight;

new g_playerFlashlight[MAX_PLAYERS + 1][PlayerFlashlight];

public plugin_precache() {
  precache_sound(ZP_FLASHLIGHT_SOUND);
  precache_model(ZP_FLASHLIGHT_LIGHTCONE_MODEL);
}

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
  RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);
  RegisterHam(Ham_Player_PreThink, "player", "OnPlayerPreThink_Post", .Post = 1);

  gmsgFlashlight = get_user_msgid("Flashlight");
}

public plugin_natives() {
  register_native("ZP_Player_ToggleFlashlight", "Native_Toggle");
}

public bool:Native_Toggle(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  return SetPlayerFlashlight(pPlayer, !g_playerFlashlight[pPlayer][PlayerFlashlight_On]);
}

public OnPlayerSpawn_Post(pPlayer) {
  if(!is_user_alive(pPlayer)) {
    return HAM_IGNORED;
  }

  if (ZP_Player_IsZombie(pPlayer)) {
    SetPlayerFlashlight(pPlayer, false);
  }

  g_playerFlashlight[pPlayer][PlayerFlashlight_Charge] = FLASHLIGHT_CHARGE_DEF;
  set_pev(pPlayer, pev_framerate, 1.0);
  
  return HAM_HANDLED;
}

public OnPlayerKilled_Post(pPlayer) {
  SetPlayerFlashlight(pPlayer, false);
  return HAM_HANDLED;
}

public OnPlayerPreThink_Post(pPlayer) {
  FlashlightThink(pPlayer);
}

bool:SetPlayerFlashlight(pPlayer, bool:bValue) {
  if (bValue == g_playerFlashlight[pPlayer][PlayerFlashlight_On]) {
    return true;
  }

  if (bValue && get_member_game(m_bFreezePeriod)) {
    return false;
  }

  if (bValue && (ZP_Player_IsZombie(pPlayer) || !is_user_alive(pPlayer))) {
    return false;
  }

  g_playerFlashlight[pPlayer][PlayerFlashlight_On] = bValue;

  remove_task(pPlayer + TASKID_FLASHLIGHT);
  remove_task(pPlayer + TASKID_FLASHLIGHT_HUD);

  if (bValue) {
    ShowLightConeEntity(pPlayer);
    set_task(1.0, "TaskFlashlightHud", pPlayer + TASKID_FLASHLIGHT_HUD, _, _, "b");
  } else {
    HideLightConeEntity(pPlayer);
  }

  UpdateFlashlightHud(pPlayer);
  emit_sound(pPlayer, CHAN_ITEM, ZP_FLASHLIGHT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

  return true;
}

CreateLightConeEntity(pPlayer) {
  static iszClassname;
  if (!iszClassname) {
    iszClassname = engfunc(EngFunc_AllocString, "info_target");
  }

  new pEntity = engfunc(EngFunc_CreateNamedEntity, iszClassname);

  set_pev(pEntity, pev_classname, "lightcone");
  set_pev(pEntity, pev_movetype, MOVETYPE_FOLLOW);
  set_pev(pEntity, pev_aiment, pPlayer);
  set_pev(pEntity, pev_owner, pPlayer);

  engfunc(EngFunc_SetModel, pEntity, ZP_FLASHLIGHT_LIGHTCONE_MODEL);

  g_playerFlashlight[pPlayer][PlayerFlashlight_ConeEntity] = pEntity;

  return pEntity;
}

ShowLightConeEntity(pPlayer) {
    new iLightconeEntity = g_playerFlashlight[pPlayer][PlayerFlashlight_ConeEntity];
    if (!iLightconeEntity) {
      iLightconeEntity = CreateLightConeEntity(pPlayer);
    }

    set_pev(iLightconeEntity, pev_effects, pev(iLightconeEntity, pev_effects) & ~EF_NODRAW);
    set_pev(pPlayer, pev_framerate, 0.5);
}

HideLightConeEntity(pPlayer) {
  new iLightconeEntity = g_playerFlashlight[pPlayer][PlayerFlashlight_ConeEntity];

  if (iLightconeEntity) {
    set_pev(iLightconeEntity, pev_effects, pev(iLightconeEntity, pev_effects) | EF_NODRAW);
    set_pev(pPlayer, pev_framerate, 1.0);
  }
}

UpdateFlashlightHud(pPlayer) {
  message_begin(MSG_ONE, gmsgFlashlight, _, pPlayer);
  write_byte(g_playerFlashlight[pPlayer][PlayerFlashlight_On]);
  write_byte(floatround(g_playerFlashlight[pPlayer][PlayerFlashlight_Charge]));
  message_end();
}

public FlashlightThink(pPlayer) {
  new Float:flDelta = get_gametime() - g_playerFlashlight[pPlayer][PlayerFlashlight_LastThink];
  if (flDelta < FLASHLIGHT_RATE) {
    return;
  }

  if (g_playerFlashlight[pPlayer][PlayerFlashlight_On]) {
    if (g_playerFlashlight[pPlayer][PlayerFlashlight_Charge] > FLASHLIGHT_MIN_CHARGE) {
      CreatePlayerFlashlightLight(pPlayer);
      g_playerFlashlight[pPlayer][PlayerFlashlight_Charge] -= (FLASHLIGHT_CONSUMPTION_RATE * flDelta);
      g_playerFlashlight[pPlayer][PlayerFlashlight_Charge] = floatmax(g_playerFlashlight[pPlayer][PlayerFlashlight_Charge], FLASHLIGHT_MIN_CHARGE);
      set_pev(pPlayer, pev_framerate, 0.5);
    } else {
       SetPlayerFlashlight(pPlayer, false);
    }
  } else if (g_playerFlashlight[pPlayer][PlayerFlashlight_Charge] < FLASHLIGHT_MAX_CHARGE) {
    g_playerFlashlight[pPlayer][PlayerFlashlight_Charge] += (FLASHLIGHT_RECOVERY_RATE * flDelta);
    g_playerFlashlight[pPlayer][PlayerFlashlight_Charge] = floatmin(g_playerFlashlight[pPlayer][PlayerFlashlight_Charge], FLASHLIGHT_MAX_CHARGE);
  }

  g_playerFlashlight[pPlayer][PlayerFlashlight_LastThink] = get_gametime();
}

CreatePlayerFlashlightLight(pPlayer) {
  static Float:vecViewOfs[3];
  pev(pPlayer, pev_view_ofs, vecViewOfs);

  static Float:vecStart[3];
  pev(pPlayer, pev_origin, vecStart);
  vecStart[2] += vecViewOfs[2];

  static Float:vecEnd[3];
  pev(pPlayer, pev_v_angle, vecEnd);
  engfunc(EngFunc_MakeVectors, vecEnd); 
  get_global_vector(GL_v_forward, vecEnd);
  xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd);
  xs_vec_add(vecEnd, vecStart, vecEnd);

  new pTr = create_tr2();
  engfunc(EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTr);
  get_tr2(pTr, TR_vecEndPos, vecEnd);
  free_tr2(pTr);

  new Float:flDistance = get_distance_f(vecStart, vecEnd);
  if (flDistance <= FLASHLIGHT_MAX_DISTANCE) {
    // TODO: Remove this hardcoded shit
    new Float:flRadius = 4.0 + (flDistance / 64.0);
    new Float:flBrightness = floatmax(255.0 - flDistance / 4.0, 0.0);

    new iColor[3];
    for (new i = 0; i < 3; ++i) {
      iColor[i] = floatround(flBrightness);
    }

    new iLifeTime = max(1, floatround(FLASHLIGHT_RATE * 10));
    new iDecayRate = 10 / iLifeTime;
    UTIL_Message_Dlight(vecEnd, floatround(flRadius), iColor, iLifeTime, iDecayRate);
  }
}

public TaskFlashlightHud(iTaskId) {
  new pPlayer = iTaskId - TASKID_FLASHLIGHT_HUD;

  UpdateFlashlightHud(pPlayer);
}
