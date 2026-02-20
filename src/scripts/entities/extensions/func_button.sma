#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_custom_entities>
#include <api_player_roles>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define FLAG_HUMAN_ONLY (1<<9)

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_ExtendClass(ENTITY(Button));

  CE_ImplementClassMethod(ENTITY(Button), CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY(Button), CE_Method_Restart, "@Entity_Restart");
  CE_ImplementClassMethod(ENTITY(Button), CE_Method_Use, "@Entity_Use");

  CE_RegisterClassMethod(ENTITY(Button), BUTTON_METHOD(IsUsable), "@Entity_IsUsable", CE_Type_Cell);
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(Button), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Spawn(const this) {
  CE_SetMember(this, BUTTON_MEMBER(bHumanOnly), !!(pev(this, pev_spawnflags) & FLAG_HUMAN_ONLY));

  CE_CallBaseMethod();
}

@Entity_Restart(const this) {
  static Float:vecStartPosition[3]; get_ent_data_vector(this, "CBaseToggle", "m_vecPosition1", vecStartPosition);
  static Float:vecAngles[3]; CE_GetMemberVec(this, CE_Member_vecAngles, vecAngles);

  set_ent_data_entity(this, "CBaseToggle", "m_hActivator", FM_NULLENT);
  set_ent_data(this, "CBaseToggle", "m_toggle_state", TS_AT_BOTTOM);
  set_ent_data_vector(this, "CBaseToggle", "m_vecFinalDest", vecStartPosition);
  
  engfunc(EngFunc_SetOrigin, this, vecStartPosition);

  set_pev(this, pev_angles, vecAngles);
  set_pev(this, pev_frame, 0.0);
  set_pev(this, pev_nextthink, -1.0);
  set_pev(this, pev_velocity, NULL_VECTOR);

  ExecuteHam(Ham_Spawn, this);
}

@Entity_Use(const this, const pActivator, const pCaller, iUseType, Float:flValue) {
  if (!CE_CallMethod(this, BUTTON_METHOD(IsUsable), pActivator)) return;

  CE_CallBaseMethod(pActivator, pCaller, iUseType, flValue);
}

@Entity_IsUsable(const this, const pActivator) {
  if (!CE_CallNativeMethod(this, CE_Method_IsMasterTriggered, pActivator)) return false;

  static iToggleState; iToggleState = get_ent_data(this, "CBaseToggle", "m_toggle_state");

  if (pev(this, pev_spawnflags) & SF_BUTTON_TOGGLE) {
    if (iToggleState != TS_AT_BOTTOM && iToggleState != TS_AT_TOP) return false;
  } else {
    if (iToggleState != TS_AT_BOTTOM) return false;
  }


  if (CE_GetMember(this, BUTTON_MEMBER(bHumanOnly))) {
    if (PlayerRole_Player_HasRole(pActivator, PLAYER_ROLE(Zombie))) return false;
  }

  return true;
}
