#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Objective Marks"
#define AUTHOR "Hedgehog Fog"

#define MARK_CLASSNAME "_mark"
#define SPRITE_NAME "sprites/zombiepanic/b2/objective_mark.spr"
#define SPRITE_WIDTH 128.0
#define SPRITE_HEIGHT 128.0
#define SPRITE_SCALE 0.125

new Array:g_iszButtons;
new g_iMarkModelIndex;

public plugin_precache() {
  g_iszButtons = ArrayCreate();
  g_iMarkModelIndex = precache_model(SPRITE_NAME);

  RegisterHam(Ham_Spawn, "func_button", "OnButtonSpawn_Post", .Post = 1);
}

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  register_forward(FM_AddToFullPack, "OnAddToFullPack_Post", 1);
  register_forward(FM_CheckVisibility, "OnCheckVisibility");
}

public plugin_end() {
  ArrayDestroy(g_iszButtons);
}

public OnButtonSpawn_Post(pButton) {
  ArrayPushCell(g_iszButtons, pButton);

  new pMark = CreateMark(pButton);
  set_pev(pButton, pev_iuser1, pMark);
}

public OnAddToFullPack_Post(es, e, pEntity, pHost, pHostFlags, pPlayer, pSet) {
  if (!UTIL_IsPlayer(pHost)) {
    return FMRES_IGNORED;
  }

  if (!pev_valid(pEntity)) {
    return FMRES_IGNORED;
  }

  static szClassname[32];
  pev(pEntity, pev_classname, szClassname, charsmax(szClassname));

  if (!equal(szClassname, MARK_CLASSNAME)) {
    return FMRES_IGNORED;
  }

  new pButton = pev(pEntity, pev_owner);
  if (!IsUsableObjective(pHost, pButton)) {
    return FMRES_SUPERCEDE;
  }

  DrawMark(pEntity, pHost, es);

  return FMRES_HANDLED;
}

public OnCheckVisibility(pEntity) {
  if (!pev_valid(pEntity)) {
  return FMRES_IGNORED;
  }

  static szClassname[32];
  pev(pEntity, pev_classname, szClassname, charsmax(szClassname));

  if (!equal(szClassname, MARK_CLASSNAME)) {
      return FMRES_IGNORED;
  }

  forward_return(FMV_CELL, 1);
  return FMRES_SUPERCEDE;
}

CreateMark(pButton) {
  new pMark = rg_create_entity("info_target");
  
  set_pev(pMark, pev_classname, MARK_CLASSNAME);
  set_pev(pMark, pev_scale, SPRITE_SCALE);
  set_pev(pMark, pev_modelindex, g_iMarkModelIndex);
  set_pev(pMark, pev_rendermode, kRenderTransAdd);
  set_pev(pMark, pev_renderamt, 120.0);
  set_pev(pMark, pev_movetype, MOVETYPE_FLYMISSILE);
  set_pev(pMark, pev_solid, SOLID_NOT);
  set_pev(pMark, pev_spawnflags, SF_SPRITE_STARTON);
  set_pev(pMark, pev_owner, pButton);

  dllfunc(DLLFunc_Spawn, pMark);

  static Float:vecOrigin[3];
  ExecuteHam(Ham_BodyTarget, pButton, 0, vecOrigin);
  engfunc(EngFunc_SetOrigin, pMark, vecOrigin);

  return pMark;
}

DrawMark(pMark, pPlayer, es) {
  enum _:Frame { TopLeft, TopRight, BottomLeft, BottomRight };

  static Float:vecTarget[3];
  pev(pMark, pev_origin, vecTarget);

  static Float:vecEyes[3];
  ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecEyes);

  static Float:vecDir[3];
  xs_vec_sub(vecTarget, vecEyes, vecDir);

  new Float:flDistance = xs_vec_len(vecDir);

  for (new i = 0; i < 3; ++i) {
    vecTarget[i] = vecEyes[i] + ((vecDir[i] / flDistance) * 250.0);
  }

  static Float:vecAngles[3];
  xs_vec_normalize(vecDir, vecAngles);
  vector_to_angle(vecAngles, vecAngles);
  vecAngles[0] = -vecAngles[0];

  static Float:vecUp[3];
  angle_vector(vecAngles, ANGLEVECTOR_UP, vecUp);

  static Float:vecRight[3];
  angle_vector(vecAngles, ANGLEVECTOR_RIGHT, vecRight);

  static Float:vecForward[3];
  angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

  new Float:flHalfWidth = (SPRITE_WIDTH * SPRITE_SCALE) / 2.0;
  new Float:flHalfHeight = (SPRITE_HEIGHT * SPRITE_SCALE) / 2.0;

  static Float:rgvecFrameSrc[Frame][3];
  for (new i = 0; i < 3; ++i) {
    rgvecFrameSrc[TopLeft][i] = vecEyes[i] + (vecRight[i] * -flHalfWidth) +  (vecUp[i] * flHalfHeight);
    rgvecFrameSrc[TopRight][i] = vecEyes[i] + (vecRight[i] * flHalfWidth) + (vecUp[i] * flHalfHeight);
    rgvecFrameSrc[BottomLeft][i] = vecEyes[i] + (vecRight[i] * -flHalfWidth) + (vecUp[i] * -flHalfHeight);
    rgvecFrameSrc[BottomRight][i] = vecEyes[i] + (vecRight[i] * flHalfWidth) + (vecUp[i] * -flHalfHeight);
  }

  static Float:rgvecFrameEnd[Frame][3];
  for (new i = 0; i < 3; ++i) {
    rgvecFrameEnd[TopLeft][i] = vecTarget[i] + (vecRight[i] * -flHalfWidth) +  (vecUp[i] * flHalfHeight);
    rgvecFrameEnd[TopRight][i] = vecTarget[i] + (vecRight[i] * flHalfWidth) + (vecUp[i] * flHalfHeight);
    rgvecFrameEnd[BottomLeft][i] = vecTarget[i] + (vecRight[i] * -flHalfWidth) + (vecUp[i] * -flHalfHeight);
    rgvecFrameEnd[BottomRight][i] = vecTarget[i] + (vecRight[i] * flHalfWidth) + (vecUp[i] * -flHalfHeight);
  }

  new Float:flSmallestFraction = 1.0;

  new pTr = create_tr2();

  for (new i = 0; i < Frame; ++i) {
    // engfunc(EngFunc_TraceLine, rgvecFrameSrc[i], rgvecFrameEnd[i], IGNORE_GLASS, pPlayer, pTr);
    engfunc(EngFunc_TraceLine, vecEyes, rgvecFrameEnd[i], IGNORE_GLASS, pPlayer, pTr);
    // UTIL_BeamPoints(rgvecFrameSrc[i], rgvecFrameEnd[i], {0, 255, 0}, 1);

    static Float:flFraction;
    get_tr2(pTr, TR_flFraction, flFraction);

    if (flFraction < flSmallestFraction) {
      flSmallestFraction = flFraction;
    }
  }

  free_tr2(pTr);

  if (flSmallestFraction < 1.0) {
    for (new i = 0; i < Frame; ++i) {
      for (new j = 0; j < 3; ++j) {
        rgvecFrameEnd[i][j] = rgvecFrameSrc[i][j] + ((rgvecFrameEnd[i][j] - rgvecFrameSrc[i][j]) * flSmallestFraction) - (vecForward[j] * flHalfWidth);
      }
    }
  }

  for (new i = 0; i < Frame; ++i) {
    UTIL_BeamPoints(rgvecFrameSrc[i], rgvecFrameEnd[i], {0, 0, 255}, 1);
    UTIL_BeamPoints(vecEyes, rgvecFrameEnd[i], {255, 0, 0}, 1);
  }

  for (new i = 0; i < 3; ++i) {
    vecTarget[i] = (rgvecFrameEnd[TopLeft][i] + rgvecFrameEnd[BottomRight][i]) * 0.5;
  }

  // UTIL_BeamPoints(vecEyes, vecTarget, {255, 0, 0}, 1);

  new Float:flScale = floatmax(SPRITE_SCALE / xs_vec_distance(vecEyes, vecTarget), 0.005);

  log_amx("flScale %f", flScale);

  set_es(es, ES_Scale, flScale);
  set_es(es, ES_Angles, vecAngles);
  set_es(es, ES_Origin, vecTarget);
}

bool:IsUsableObjective(pPlayer, pButton) {
  new iszMaster = get_ent_data(pButton, "CBaseToggle", "m_sMaster");

  if (iszMaster > 0) {
    static szMaster[32];
    engfunc(EngFunc_SzFromIndex, iszMaster, szMaster, charsmax(szMaster));

    if (!UTIL_IsMasterTriggered(szMaster, pPlayer)) {
      return false;
    }
  } 

  if (!get_ent_data(pButton, "CBaseToggle", "m_toggle_state")) {
    return false;
  }

  if (~pev(pButton, pev_spawnflags) & BIT(9)) {
    return false;
  }

  return true;
}
