#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define AMBIENT_SOUND_START_SILENT (1<<4)

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_ExtendClass(ENTITY(AmbientGeneric));

  CE_ImplementClassMethod(ENTITY(AmbientGeneric), CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY(AmbientGeneric), CE_Method_Restart, "@Entity_Restart");
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(AmbientGeneric), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  CE_SetMember(this, AMBIENTGENERIC_MEMBER(bStartSilent), !!(pev(this, pev_spawnflags) & AMBIENT_SOUND_START_SILENT));
}

@Entity_Restart(const this) {
  CE_CallBaseMethod();

  if (CE_GetMember(this, AMBIENTGENERIC_MEMBER(bStartSilent))) {
    static szSound[128]; pev(this, pev_message, szSound, charsmax(szSound));
    static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
    engfunc(EngFunc_EmitAmbientSound, this, vecOrigin, szSound, 0, 0, SND_STOP, 0);
  }

  ExecuteHam(Ham_Spawn, this);
}
