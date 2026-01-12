#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_ExtendClass(ENTITY(MultiManager));

  CE_ImplementClassMethod(ENTITY(MultiManager), CE_Method_Restart, "@Entity_Restart");
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(MultiManager), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Restart(const this) {
  new iTargetsNum; iTargetsNum = get_ent_data(this, "CMultiManager", "m_cTargets");

  for (new i = 0; i < iTargetsNum; i++) {
    new iszTarget = get_ent_data(this, "CMultiManager", "m_iTargetName", i);
    static szTarget[64]; engfunc(EngFunc_SzFromIndex, iszTarget, szTarget, charsmax(szTarget));
    
    if (equal(szTarget, NULL_STRING)) continue;

    new pTarget; pTarget = engfunc(EngFunc_FindEntityByString, 0, "targetname", szTarget);
    if (!pTarget) continue;

    if (pev(pTarget, pev_flags) & FL_KILLME) continue;
    if (CE_IsInstanceOf(pTarget, ENTITY(MultiManager))) continue;

    ExecuteHamB(Ham_CS_Restart, pTarget);
  }

  if (pev(this, pev_spawnflags) & SF_MULTIMAN_CLONE) {
    engfunc(EngFunc_RemoveEntity, this);
    return;
  }

  set_ent_data_entity(this, "CBaseToggle", "m_hActivator", FM_NULLENT);
  set_ent_data_float(this, "CMultiManager", "m_startTime", 0.0);
  set_ent_data(this, "CMultiManager", "m_index", 0);
  set_pev(this, pev_nextthink, 0.0);

  ExecuteHam(Ham_Spawn, this);
}
