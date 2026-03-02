#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_ExtendClass(ENTITY(Door));

  CE_ImplementClassMethod(ENTITY(Door), CE_Method_Restart, "@Entity_Restart");
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(Door), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Restart(const this) {
  static Float:vecStartPosition[3]; get_ent_data_vector(this, "CBaseToggle", "m_vecPosition1", vecStartPosition);
  static Float:vecAngles[3]; CE_GetMemberVec(this, CE_Member_vecAngles, vecAngles);

  static szMovingSound[64]; pev(this, pev_noise1, szMovingSound, charsmax(szMovingSound));

  set_ent_data_entity(this, "CBaseToggle", "m_hActivator", FM_NULLENT);
  set_ent_data(this, "CBaseToggle", "m_toggle_state", TS_AT_BOTTOM);
  set_ent_data_vector(this, "CBaseToggle", "m_vecFinalDest", vecStartPosition);

  engfunc(EngFunc_SetOrigin, this, vecStartPosition);

  set_pev(this, pev_angles, vecAngles);
  set_pev(this, pev_nextthink, -1.0);
  set_pev(this, pev_velocity, NULL_VECTOR);

  emit_sound(this, CHAN_STATIC, szMovingSound, VOL_NORM, ATTN_NONE, SND_STOP, PITCH_NORM);

  ExecuteHam(Ham_Spawn, this);
}
