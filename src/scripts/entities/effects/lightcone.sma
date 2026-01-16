#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_assets>
#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Helpers ]--------------------------------*/

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

/*--------------------------------[ Constants ]--------------------------------*/

#define LIGHT_UPDATE_RATE 0.025
#define LIGHT_MAX_BRIGHTNESS 160.0
#define LIGHT_MAX_DISTANCE 768.0

/*--------------------------------[ Assets ]--------------------------------*/

new g_szModel[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_pTrace;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(LightCone), g_szModel, charsmax(g_szModel));

  CE_RegisterClass(ENTITY(LightCone));
  CE_ImplementClassMethod(ENTITY(LightCone), CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY(LightCone), CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY(LightCone), CE_Method_Think, "@Entity_Think");

  CE_RegisterClassMethod(ENTITY(LightCone), LIGHTCONE_METHOD(CreateLight), "@Entity_CreateLight");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(LightCone), ZP_VERSION, "Hedgehog Fog");
}

public plugin_end() {
  free_tr2(g_pTrace);
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  set_pev(this, pev_nextthink, get_gametime());
}

@Entity_Think(const this) {
  static Float:flGameTime; flGameTime = get_gametime();

  CE_CallBaseMethod();

  if (~pev(this, pev_effects) & EF_NODRAW) {
    if (Float:CE_GetMember(this, LIGHTCONE_MEMBER(flNextLightUpdate)) <= flGameTime) {
      CE_CallMethod(this, LIGHTCONE_METHOD(CreateLight));
      CE_SetMember(this, LIGHTCONE_MEMBER(flNextLightUpdate), flGameTime + LIGHT_UPDATE_RATE);
    }
  }

  set_pev(this, pev_nextthink, flGameTime + 0.01);
}

@Entity_CreateLight(const this) {
  static Float:vecSrc[3];
  static Float:vecAngles[3];

  if (pev(this, pev_movetype) == MOVETYPE_FOLLOW) {
    static pAimEnt; pAimEnt = pev(this, pev_aiment);

    if (IS_PLAYER(pAimEnt)) {
      ExecuteHam(Ham_Player_GetGunPosition, pAimEnt, vecSrc);
      pev(pAimEnt, pev_v_angle, vecAngles);
    } else {
      pev(pAimEnt, pev_origin, vecSrc);
      pev(pAimEnt, pev_angles, vecAngles);
    }
  } else {
    pev(this, pev_origin, vecSrc);
    pev(this, pev_angles, vecAngles);
  }

  static Float:vecDirection[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecDirection);

  static Float:vecEnd[3]; xs_vec_add_scaled(vecSrc, vecDirection, 8192.0, vecEnd);
  engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, this, g_pTrace);
  get_tr2(g_pTrace, TR_vecEndPos, vecEnd);

  static Float:flDistance; flDistance = get_distance_f(vecSrc, vecEnd);
  if (flDistance > LIGHT_MAX_DISTANCE) return;

  static Float:flDistanceRatio; flDistanceRatio = (flDistance / LIGHT_MAX_DISTANCE);
  static Float:flBrightness; flBrightness = LIGHT_MAX_BRIGHTNESS * (1.0 - flDistanceRatio);

  if (flBrightness <= 1.0) return;

  static rgiColor[3];
  for (new i = 0; i < 3; ++i) {
    rgiColor[i] = floatround(flBrightness);
  }

  static Float:flRadius; flRadius = 4.0 + (16.0 * flDistanceRatio);
  static iLifeTime; iLifeTime = max(1, floatround(LIGHT_UPDATE_RATE * 10));
  static iDecayRate; iDecayRate = 10 / iLifeTime;

  engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEnd, 0);
  write_byte(TE_DLIGHT);
  engfunc(EngFunc_WriteCoord, vecEnd[0]);
  engfunc(EngFunc_WriteCoord, vecEnd[1]);
  engfunc(EngFunc_WriteCoord, vecEnd[2]);
  write_byte(floatround(flRadius));
  write_byte(rgiColor[0]);
  write_byte(rgiColor[1]);
  write_byte(rgiColor[2]);
  write_byte(iLifeTime);
  write_byte(iDecayRate);
  message_end();
}
