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
#define SPRITE_SCALE 0.03125
#define SPRITE_AMT 50.0
#define MARK_UPDATE_DELAY 0.1
#define MARK_MAX_VELOCITY 200.0
#define MARK_MAX_MOVE_STEP_LENGTH 1000.0
#define MARK_MAX_SCALE_STEP 0.0625
#define MARK_MAX_SCALE_STEP_LENGTH 50.0

enum _:Frame { TopLeft, TopRight, BottomLeft, BottomRight };

enum PlayerData {
  Float:Player_Origin[3],
  Float:Player_MarkOrigin[3],
  Float:Player_MarkAngles[3],
  Float:Player_MarkUpdateTime,
  Float:Player_MarkScale
}

new Array:g_irgMarks;
new g_iMarkModelIndex;

new g_rgPlayerData[MAX_PLAYERS][12][PlayerData];

public plugin_precache() {
  g_irgMarks = ArrayCreate();
  g_iMarkModelIndex = precache_model(SPRITE_NAME);

  RegisterHam(Ham_Spawn, "func_button", "OnButtonSpawn_Post", .Post = 1);
}

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);

  register_forward(FM_AddToFullPack, "OnAddToFullPack", 0);
  register_forward(FM_AddToFullPack, "OnAddToFullPack_Post", 1);
  register_forward(FM_CheckVisibility, "OnCheckVisibility");
}

public plugin_end() {
  ArrayDestroy(g_irgMarks);
}

public OnButtonSpawn_Post(pButton) {
  new pMark = CreateMark(pButton);
  set_pev(pMark, pev_iuser1, ArraySize(g_irgMarks));
  ArrayPushCell(g_irgMarks, pButton);
}

public OnPlayerSpawn_Post(pPlayer) {
  for (new iMarkIndex = 0; iMarkIndex < ArraySize(g_irgMarks); ++iMarkIndex) {
    g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkUpdateTime] = 0.0;
  }
}

public OnAddToFullPack(es, e, pEntity, pHost, pHostFlags, pPlayer, pSet) {
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
  
  new iMarkIndex = pev(pEntity, pev_iuser1);
  new Float:flDelta = get_gametime() - g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkUpdateTime];
  if (!g_rgPlayerData[pHost][iMarkIndex][Player_MarkUpdateTime] || flDelta >= MARK_UPDATE_DELAY) {
    CalculateMark(pEntity, pHost);
  }

  return FMRES_HANDLED;
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

  new iMarkIndex = pev(pEntity, pev_iuser1);
  set_es(es, ES_Angles, g_rgPlayerData[pHost][iMarkIndex][Player_MarkAngles]);
  set_es(es, ES_Origin, g_rgPlayerData[pHost][iMarkIndex][Player_MarkOrigin]);
  set_es(es, ES_Scale, g_rgPlayerData[pHost][iMarkIndex][Player_MarkScale]);

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
  set_pev(pMark, pev_renderamt, SPRITE_AMT);
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

CalculateMark(pMark, pPlayer) {
  new iMarkIndex = pev(pMark, pev_iuser1);
  new Float:flDelta = get_gametime() - g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkUpdateTime];

  static Float:vecOrigin[3];
  ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecOrigin);

  static Float:vecTarget[3];
  pev(pMark, pev_origin, vecTarget);

  // ANCHOR: Smooth movement
  if (g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkUpdateTime] > 0.0) {
    new Float:flMaxStep = MARK_MAX_VELOCITY * flDelta;
    new Float:flDirLen = xs_vec_distance(vecOrigin, g_rgPlayerData[pPlayer][iMarkIndex][Player_Origin]);

    if (flDirLen > flMaxStep && flDirLen < MARK_MAX_MOVE_STEP_LENGTH) {
      for (new i = 0; i < 3; ++i) {
        vecOrigin[i] = g_rgPlayerData[pPlayer][iMarkIndex][Player_Origin][i] + (((vecOrigin[i] - g_rgPlayerData[pPlayer][iMarkIndex][Player_Origin][i]) / flDirLen) * flMaxStep);
      }
    }
  }

  // ANCHOR: Caclulate angles
  static Float:vecDir[3];
  xs_vec_sub(vecTarget, vecOrigin, vecDir);

  static Float:vecAngles[3];
  xs_vec_normalize(vecDir, vecAngles);
  vector_to_angle(vecAngles, vecAngles);
  vecAngles[0] = -vecAngles[0];

  // ANCHOR: Calculate origin
  static Float:vecForward[3];
  angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

  static Float:vecUp[3];
  angle_vector(vecAngles, ANGLEVECTOR_UP, vecUp);

  static Float:vecRight[3];
  angle_vector(vecAngles, ANGLEVECTOR_RIGHT, vecRight);

  static Float:rgvecFrameEnd[Frame][3];
  CreateFrame(vecTarget, SPRITE_WIDTH * SPRITE_SCALE, SPRITE_HEIGHT * SPRITE_SCALE, vecUp, vecRight, rgvecFrameEnd);
  TraceFrame(vecOrigin, rgvecFrameEnd, pPlayer, rgvecFrameEnd);

  for (new i = 0; i < 3; ++i) {
    vecTarget[i] = (rgvecFrameEnd[TopLeft][i] + rgvecFrameEnd[BottomRight][i]) * 0.5;
  }

  // ANCHOR: Calculate scale
  new Float:flScale = SPRITE_SCALE * (xs_vec_distance(vecOrigin, vecTarget) / 100);
  
  // ANCHOR: Smooth scale
  if (g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkUpdateTime] > 0.0) {
    new Float:flMaxStep = 1 + ((MARK_MAX_SCALE_STEP / g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkScale]) * flDelta);
    new Float:flScaleRatio = flScale / g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkScale];
    new Float:flLastDistance = xs_vec_distance(g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkOrigin], g_rgPlayerData[pPlayer][iMarkIndex][Player_Origin]);
    new Float:flDistance = xs_vec_distance(vecTarget, vecOrigin);

    if (floatabs(flLastDistance - flDistance) < MARK_MAX_SCALE_STEP_LENGTH) {
      if (flScaleRatio > flMaxStep) {
            flScale = g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkScale] * flMaxStep;
        } else if (flScaleRatio < (1.0 / flMaxStep)) {
          flScale = g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkScale] * (1.0 / flMaxStep);
        }
    } else {
      flScale = 0.005;
    }
  }

  // ANCHOR: Fix frame position accounting to scale
  CreateFrame(vecTarget, SPRITE_WIDTH * flScale, SPRITE_HEIGHT * flScale, vecUp, vecRight, rgvecFrameEnd);
  for (new i = 0; i < Frame; ++i) {
    for (new j = 0; j < 3; ++j) {
      rgvecFrameEnd[i][j] -= (vecForward[j] * ((SPRITE_WIDTH * flScale) / 2.0));
    }
  }

  // ANCHOR: Get target point
  for (new i = 0; i < 3; ++i) {
    vecTarget[i] = (rgvecFrameEnd[TopLeft][i] + rgvecFrameEnd[BottomRight][i]) * 0.5;
  }

  xs_vec_copy(vecOrigin, g_rgPlayerData[pPlayer][iMarkIndex][Player_Origin]);
  xs_vec_copy(vecTarget, g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkOrigin]);
  xs_vec_copy(vecAngles, g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkAngles]);
  g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkScale] = flScale;
  g_rgPlayerData[pPlayer][iMarkIndex][Player_MarkUpdateTime] = get_gametime();
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

  if (~pev(pButton, pev_spawnflags) & ZP_BUTTON_FLAG_HUMAN_ONLY) {
    return false;
  }

  return true;
}


CreateFrame(const Float:vecOrigin[3], Float:flWidth, Float:flHeight, const Float:vecUp[3], const Float:vecRight[3], Float:rgvecFrameOut[Frame][3]) {
  new Float:flHalfWidth = flWidth / 2.0;
  new Float:flHalfHeight = flHeight / 2.0;

  for (new i = 0; i < 3; ++i) {
    rgvecFrameOut[TopLeft][i] = vecOrigin[i] + (vecRight[i] * -flHalfWidth) +  (vecUp[i] * flHalfHeight);
    rgvecFrameOut[TopRight][i] = vecOrigin[i] + (vecRight[i] * flHalfWidth) + (vecUp[i] * flHalfHeight);
    rgvecFrameOut[BottomLeft][i] = vecOrigin[i] + (vecRight[i] * -flHalfWidth) + (vecUp[i] * -flHalfHeight);
    rgvecFrameOut[BottomRight][i] = vecOrigin[i] + (vecRight[i] * flHalfWidth) + (vecUp[i] * -flHalfHeight);
  }
}

Float:TraceFrame(const Float:vecSrc[3], const Float:rgvecFrame[Frame][3], pIgnore, Float:rgvecFrameOut[Frame][3]) {
  new pTr = create_tr2();

  new Float:flMinFraction = 1.0;

  for (new i = 0; i < Frame; ++i) {
    engfunc(EngFunc_TraceLine, vecSrc, rgvecFrame[i], IGNORE_GLASS, pIgnore, pTr);

    static Float:flFraction;
    get_tr2(pTr, TR_flFraction, flFraction);

    if (flFraction < flMinFraction) {
      flMinFraction = flFraction;
    }
  }

  free_tr2(pTr);

  if (flMinFraction < 1.0) {
    for (new i = 0; i < Frame; ++i) {
      for (new j = 0; j < 3; ++j) {
        rgvecFrameOut[i][j] = vecSrc[j] + ((rgvecFrame[i][j] - vecSrc[j]) * flMinFraction);
      }
    }
  }

  return flMinFraction;
}
