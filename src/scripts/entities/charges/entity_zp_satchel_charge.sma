#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_assets>
#include <api_custom_entities>
#include <combat_util>

#include <zombiepanic_internal>

/*--------------------------------[ Assets ]--------------------------------*/

new g_szModel[MAX_RESOURCE_PATH_LENGTH];
new g_szBlipSound[MAX_RESOURCE_PATH_LENGTH];
new g_szGlowSprite[MAX_RESOURCE_PATH_LENGTH];
new g_rgszBounceSounds[4][MAX_RESOURCE_PATH_LENGTH];

new g_iBounceSoundsNum = 0;

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_pTrace;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Satchel), g_szModel, charsmax(g_szModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(SatchelChargeBlip), g_szBlipSound, charsmax(g_szBlipSound));
  Asset_Precache(ASSET_LIBRARY, ASSET_SPRITE(SatchelChargeGlow), g_szGlowSprite, charsmax(g_szGlowSprite));

  g_iBounceSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(GrenadeBounce), g_rgszBounceSounds, sizeof(g_rgszBounceSounds), charsmax(g_rgszBounceSounds[]));

  CE_RegisterClass(ENTITY(SatchelCharge));

  CE_ImplementClassMethod(ENTITY(SatchelCharge), CE_Method_Allocate, "@Entity_Allocate");
  CE_ImplementClassMethod(ENTITY(SatchelCharge), CE_Method_UpdatePhysics, "@Entity_UpdatePhysics");
  CE_ImplementClassMethod(ENTITY(SatchelCharge), CE_Method_Spawn, "@Entity_Spawn");

  CE_RegisterClassMethod(ENTITY(SatchelCharge), SATCHELCHARGE_METHOD(SatchelChargeSlide), "@Entity_SatchelChargeSlide");
  CE_RegisterClassMethod(ENTITY(SatchelCharge), SATCHELCHARGE_METHOD(DetonateUse), "@Entity_DetonateUse");
  CE_RegisterClassMethod(ENTITY(SatchelCharge), SATCHELCHARGE_METHOD(SatchelChargeThink), "@Entity_SatchelChargeThink");
  CE_RegisterClassMethod(ENTITY(SatchelCharge), SATCHELCHARGE_METHOD(Detonate), "@Entity_Detonate");
  CE_RegisterClassMethod(ENTITY(SatchelCharge), SATCHELCHARGE_METHOD(DetonateDestroy), "@Entity_DetonateDestroy");
  CE_RegisterClassMethod(ENTITY(SatchelCharge), SATCHELCHARGE_METHOD(Deactivate), "@Entity_Deactivate");
  CE_RegisterClassMethod(ENTITY(SatchelCharge), SATCHELCHARGE_METHOD(Blink), "@Entity_Blink");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(SatchelCharge), ZP_VERSION, "Hedgehog Fog");
}

public plugin_end() {
  free_tr2(g_pTrace);
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Allocate(const this) {
  CE_CallBaseMethod();

  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-6.0, -6.0, 0.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{6.0, 6.0, 6.0});

  CE_SetMember(this, SATCHELCHARGE_MEMBER(flDamage), 500.0);
  CE_SetMember(this, SATCHELCHARGE_MEMBER(pRemote), FM_NULLENT);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  set_pev(this, pev_sequence, 1);

  set_pev(this, pev_nextthink, get_gametime() + 0.1);

  CE_SetMember(this, SATCHELCHARGE_MEMBER(flNextBlink), get_gametime());

  CE_SetTouch(this, SATCHELCHARGE_METHOD(SatchelChargeSlide));
  CE_SetUse(this, SATCHELCHARGE_METHOD(DetonateUse));
  CE_SetThink(this, SATCHELCHARGE_METHOD(SatchelChargeThink));
}

@Entity_UpdatePhysics(const this) {
  set_pev(this, pev_movetype, MOVETYPE_BOUNCE);
  set_pev(this, pev_solid, SOLID_BBOX);
  set_pev(this, pev_gravity, 0.5);
  set_pev(this, pev_friction, 0.8);
}

@Entity_SatchelChargeSlide(const this) {
  set_pev(this, pev_gravity, 1.0);

  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);

  static Float:vecDown[3];
  xs_vec_copy(vecOrigin, vecDown);
  vecDown[2] -= 10.0;

  engfunc(EngFunc_TraceLine, vecOrigin, vecDown, IGNORE_MONSTERS, this, g_pTrace);

  static Float:flFraction; get_tr2(g_pTrace, TR_flFraction, flFraction);

  if (flFraction < 1.0) {
    xs_vec_mul_scalar(vecVelocity, 0.95, vecVelocity);
    set_pev(this, pev_velocity, vecVelocity);

    // static Float:vecAVelocity[3];
    // pev(this, pev_velocity, vecAVelocity);
    // xs_vec_mul_scalar(vecAVelocity, 0.9, vecAVelocity);
    // set_pev(this, pev_avelocity, vecAVelocity);
  }

  if ((~pev(this, pev_flags) & FL_ONGROUND) && xs_vec_len(vecVelocity) > 10.0) {
    emit_sound(this, CHAN_VOICE, g_rgszBounceSounds[random(g_iBounceSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  }
}

@Entity_DetonateUse(const this) {
  CE_SetThink(this, SATCHELCHARGE_METHOD(Detonate));
  set_pev(this, pev_nextthink, get_gametime());
}

@Entity_SatchelChargeThink(const this) {
  if (!ExecuteHam(Ham_IsInWorld, this)) {
    engfunc(EngFunc_RemoveEntity, this);
    return;
  }

  static Float:flGameTime; flGameTime = get_gametime();

  static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);

  new iWaterLevel = pev(this, pev_waterlevel);
  if (iWaterLevel == 3) {
    set_pev(this, pev_movetype, MOVETYPE_FLY);

    xs_vec_mul_scalar(vecVelocity, 0.8, vecVelocity);
    vecVelocity[2] += 8.0;
    set_pev(this, pev_velocity, vecVelocity);

    static Float:vecAVelocity[3];
    pev(this, pev_avelocity, vecAVelocity);
    xs_vec_mul_scalar(vecAVelocity, 0.9, vecAVelocity);
    set_pev(this, pev_avelocity, vecAVelocity);
  } else if (iWaterLevel == 0) {
    set_pev(this, pev_movetype, MOVETYPE_BOUNCE);
  } else {
    vecVelocity[2] -= 8.0;
    set_pev(this, pev_velocity, vecVelocity);
  }

  if (CE_GetMember(this, SATCHELCHARGE_MEMBER(flNextBlink)) < flGameTime) {
    CE_CallMethod(this, SATCHELCHARGE_METHOD(Blink));
    CE_SetMember(this, SATCHELCHARGE_MEMBER(flNextBlink), flGameTime + 1.0);
  }

  // if (!xs_vec_len_2d(vecVelocity) && (iWaterLevel || pev(this, pev_flags) & FL_ONGROUND)) {
  //   set_pev(this, pev_solid, SOLID_NOT);
  // }

  set_pev(this, pev_nextthink, flGameTime + 0.1);
}

@Entity_Detonate(const this) {
  static Float:flDamage; flDamage = CE_GetMember(this, SATCHELCHARGE_MEMBER(flDamage));

  static Float:vecStart[3]; pev(this, pev_origin, vecStart);
  vecStart[2] += 8.0;

  static Float:flRadius; flRadius = flDamage * 0.75;
  static Float:vecEnd[3]; xs_vec_set(vecEnd, vecStart[0], vecStart[1], vecStart[2] - (flRadius / 2));

  engfunc(EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, this, g_pTrace);
  UTIL_GrenadeExplode(this, flDamage, g_pTrace, DMG_GRENADE | DMG_ALWAYSGIB, flRadius, flDamage * 0.125);

  CE_SetThink(this, SATCHELCHARGE_METHOD(DetonateDestroy));
  set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_DetonateDestroy(const this) {
  UTIL_GrenadeSmoke(this);
  ExecuteHamB(Ham_Killed, this, 0, 0);
}

@Entity_Deactivate(const this) {
  ExecuteHamB(Ham_Killed, this, 0, 0);
}

@Entity_Blink(const this) {
  static bool:bValue; bValue = !pev(this, pev_body);

  set_pev(this, pev_body, bValue);

  if (bValue) {
    static Float:vecOrigin[3]; GetAttachment(this, 0, vecOrigin);
    static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);

    message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
    write_byte(TE_ELIGHT);
    write_short(0);
    write_coord_f(vecOrigin[0]);
    write_coord_f(vecOrigin[1]);
    write_coord_f(vecOrigin[2] + 0.35);
    write_coord_f(1.0);
    write_byte(255);
    write_byte(0);
    write_byte(0);
    write_byte(10);
    write_coord_f(0.0);
    message_end();

    if (xs_vec_len_2d(vecVelocity) < 1.0) {
      message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
      write_byte(TE_GLOWSPRITE);
      write_coord_f(vecOrigin[0]);
      write_coord_f(vecOrigin[1]);
      write_coord_f(vecOrigin[2]);
      write_short(engfunc(EngFunc_ModelIndex, g_szGlowSprite));
      write_byte(2);
      write_byte(1);
      write_byte(120);
      message_end();
    }

    emit_sound(this, CHAN_BODY, g_szBlipSound, VOL_NORM * 0.05, ATTN_IDLE, 0, PITCH_NORM);
  }
}
