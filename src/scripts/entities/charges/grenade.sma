#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>

#include <api_assets>
#include <api_custom_entities>
#include <combat_util>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

/*--------------------------------[ Assets ]--------------------------------*/

new g_szModel[MAX_RESOURCE_PATH_LENGTH];
new g_rgszBounceSounds[4][MAX_RESOURCE_PATH_LENGTH];

new g_iBounceSoundsNum = 0;

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_pTrace;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Grenade), g_szModel, charsmax(g_szModel));

  g_iBounceSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(GrenadeBounce), g_rgszBounceSounds, sizeof(g_rgszBounceSounds), charsmax(g_rgszBounceSounds[]));

  CE_RegisterClass(ENTITY(Grenade));

  CE_ImplementClassMethod(ENTITY(Grenade), CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY(Grenade), CE_Method_InitPhysics, "@Entity_InitPhysics");
  CE_ImplementClassMethod(ENTITY(Grenade), CE_Method_Spawn, "@Entity_Spawn");

  CE_RegisterClassMethod(ENTITY(Grenade), GRENADE_METHOD(TumbleThink), "@Entity_TumbleThink");
  CE_RegisterClassMethod(ENTITY(Grenade), GRENADE_METHOD(BounceTouch), "@Entity_BounceTouch");
  CE_RegisterClassMethod(ENTITY(Grenade), GRENADE_METHOD(Detonate), "@Entity_Detonate");
  CE_RegisterClassMethod(ENTITY(Grenade), GRENADE_METHOD(DetonateDestroy), "@Entity_DetonateDestroy");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(Grenade), ZP_VERSION, "Hedgehog Fog");
}

public plugin_end() {
  free_tr2(g_pTrace);
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMemberString(this, CE_Member_szModel, g_szModel);

  CE_SetMember(this, GRENADE_MEMBER(flDetonateDelay), 3.0);
  CE_SetMember(this, GRENADE_MEMBER(flDetonateTime), 0.0);
  CE_SetMember(this, GRENADE_MEMBER(flNextBounceDamage), 0.0);
  CE_SetMember(this, GRENADE_MEMBER(flDamage), 300.0);
}

@Entity_Spawn(const this) {
  static Float:flGameTime; flGameTime = get_gametime();
  static Float:flDetonateDelay; flDetonateDelay = CE_GetMember(this, GRENADE_MEMBER(flDetonateDelay));

  CE_CallBaseMethod();

  CE_SetTouch(this, GRENADE_METHOD(BounceTouch));
  CE_SetThink(this, GRENADE_METHOD(TumbleThink));

  CE_SetMember(this, GRENADE_MEMBER(flDetonateTime), flGameTime + flDetonateDelay);

  if (flDetonateDelay < 0.1) {
    set_pev(this, pev_nextthink, flGameTime);
    set_pev(this, pev_velocity, NULL_VECTOR);
  } else {
    set_pev(this, pev_nextthink, flGameTime + 0.1);
  }

  set_pev(this, pev_sequence, random_num(3, 7));
  set_pev(this, pev_framerate, 1.0);
}

@Entity_InitPhysics(const this) {
  set_pev(this, pev_movetype, MOVETYPE_BOUNCE);
  set_pev(this, pev_solid, SOLID_BBOX);
  set_pev(this, pev_gravity, 0.5);
  set_pev(this, pev_friction, 0.8);
}

@Entity_TumbleThink(const this) {
  if (!ExecuteHam(Ham_IsInWorld, this)) {
    set_pev(this, pev_flags, FL_KILLME);
    set_pev(this, pev_targetname, 0);
    CE_SetThink(this, NULL_STRING);
    dllfunc(DLLFunc_Think, this);
    return;
  }

  static Float:flGameTime; flGameTime = get_gametime();

  static Float:flDetonateTime; flDetonateTime = CE_GetMember(this, GRENADE_MEMBER(flDetonateTime));
  if (flDetonateTime <= flGameTime) {
    CE_CallMethod(this, GRENADE_METHOD(Detonate));
  }

  if (pev(this, pev_waterlevel) != 0) {
    static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);
    xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
    set_pev(this, pev_velocity, vecVelocity);
    set_pev(this, pev_framerate, 0.2);
  }

  set_pev(this, pev_nextthink, flGameTime + 0.1);
}

@Entity_BounceTouch(const this, pOther) {
  static pOwner; pOwner = pev(this, pev_owner);
  if (pOther == pOwner)  return;

  static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);

  // only do damage if we're moving fairly fast
  if (CE_GetMember(this, GRENADE_MEMBER(flNextBounceDamage)) < get_gametime() && xs_vec_len(vecVelocity) > 100.0) {
    if (IS_PLAYER(pOwner) && IS_PLAYER(pOther) && rg_is_player_can_takedamage(pOther, pOwner)) {
      static Float:vecForward[3]; get_global_vector(GL_v_forward, vecForward);
      rg_multidmg_clear();
      ExecuteHamB(Ham_TraceAttack, pOther, pOwner, 1.0, vecForward, g_pTrace, DMG_CLUB); 
      rg_multidmg_apply(this, pOwner);
    }

    CE_SetMember(this, GRENADE_MEMBER(flNextBounceDamage), get_gametime() + 1.0);
  }

  if (pev(this, pev_flags) & FL_ONGROUND) {
    xs_vec_mul_scalar(vecVelocity, 0.8, vecVelocity);
    set_pev(this, pev_velocity, vecVelocity);
    set_pev(this, pev_sequence, 1);
  } else {
    emit_sound(this, CHAN_VOICE, g_rgszBounceSounds[random(g_iBounceSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  }
  
  new Float:flFramerate = floatmin(xs_vec_len(vecVelocity) / 200.0, 1.0);
  if (flFramerate < 0.5) {
    flFramerate = 0.0;
  }

  set_pev(this, pev_framerate, flFramerate);
}

@Entity_Detonate(const this) {
  static Float:flDamage; flDamage = CE_GetMember(this, GRENADE_MEMBER(flDamage));

  static Float:vecStart[3]; pev(this, pev_origin, vecStart);
  vecStart[2] += 8.0;

  static Float:vecEnd[3]; xs_vec_set(vecEnd, vecStart[0], vecStart[1], vecStart[2] - 40.0);

  engfunc(EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, this, g_pTrace);
  UTIL_GrenadeExplode(this, flDamage, g_pTrace, DMG_GRENADE | DMG_ALWAYSGIB, flDamage * 0.75, flDamage * 0.125);

  CE_CallMethod(this, GRENADE_METHOD(DetonateDestroy));
  set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_DetonateDestroy(const this) {
  UTIL_GrenadeSmoke(this);
  ExecuteHamB(Ham_Killed, this, 0, 0);
}
