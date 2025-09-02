#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_ExtendClass(ENTITY(Train));
  CE_ImplementClassMethod(ENTITY(Train), CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY(Train), CE_Method_Activate, "@Entity_Activate");
  CE_ImplementClassMethod(ENTITY(Train), CE_Method_Restart, "@Entity_Restart");
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(Train), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Spawn(const this) {
  new szTarget[32]; pev(this, pev_target, szTarget, charsmax(szTarget));
  new Float:flSpeed; pev(this, pev_speed, flSpeed);

  CE_SetMemberString(this, TRAIN_MEMBER(szFirstTarget), szTarget);

  CE_SetMember(this, TRAIN_MEMBER(flSpeed), flSpeed);

  CE_CallBaseMethod();
}

@Entity_Activate(const this) {
  CE_CallBaseMethod();
}

@Entity_Restart(const this) {
  static szFirstTarget[32]; CE_GetMemberString(this, TRAIN_MEMBER(szFirstTarget), szFirstTarget, charsmax(szFirstTarget));

  static szNoiseSound[32]; pev(this, pev_noise, szNoiseSound, charsmax(szNoiseSound));
  static Float:vecStartPosition[3]; CE_GetMemberVec(this, CE_Member_vecOrigin, vecStartPosition);

  set_pev(this, pev_nextthink, 0.0);
  set_pev(this, pev_velocity, NULL_VECTOR);
  set_pev(this, pev_avelocity, NULL_VECTOR);
  set_pev(this, pev_enemy, 0);
  set_pev(this, pev_message, 0);
  set_pev(this, pev_target, szFirstTarget);
  set_pev(this, pev_speed, Float:CE_GetMember(this, TRAIN_MEMBER(flSpeed)));

  set_ent_data(this, "CFuncTrain", "m_activated", false);
  set_ent_data(this, "CBaseEntity", "m_pfnThink", 0);
  set_ent_data(this, "CBaseToggle", "m_pfnCallWhenMoveDone", 0);
  set_ent_data_entity(this, "CBaseToggle", "m_hActivator", FM_NULLENT);
  set_ent_data_entity(this, "CFuncTrain", "m_pevCurrentTarget", FM_NULLENT);
  set_ent_data_vector(this, "CBaseToggle", "m_vecFinalDest", Float:{0.0, 0.0, 0.0});
  set_ent_data_vector(this, "CBaseToggle", "m_vecFinalAngle", Float:{0.0, 0.0, 0.0});

  emit_sound(this, CHAN_STATIC, szNoiseSound, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);

  engfunc(EngFunc_SetOrigin, this, vecStartPosition);
  ExecuteHam(Ham_Spawn, this);
  ExecuteHam(Ham_Activate, this);
}
