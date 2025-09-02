#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_RegisterClass(ENTITY(PlayerSpawner));
  CE_ImplementClassMethod(ENTITY(PlayerSpawner), CE_Method_Allocate, "@PlayerSpawner_Allocate");
  CE_ImplementClassMethod(ENTITY(PlayerSpawner), CE_Method_Spawn, "@PlayerSpawner_Spawn");

  CE_RegisterClass(ENTITY(SurvivorSpawner), ENTITY(PlayerSpawner));
  CE_ImplementClassMethod(ENTITY(SurvivorSpawner), CE_Method_Allocate, "@SurvivorSpawner_Allocate");

  CE_RegisterClass(ENTITY(ZombieSpawner), ENTITY(PlayerSpawner));
  CE_ImplementClassMethod(ENTITY(ZombieSpawner), CE_Method_Allocate, "@ZombieSpawner_Allocate");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(PlayerSpawner), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@PlayerSpawner_Allocate(const this) {
  CE_CallBaseMethod();

  CE_SetMember(this, PLAYERSPAWNER_MEMBER(iTeam), 0);
}

@PlayerSpawner_Spawn(const this) {
  CE_CallBaseMethod();

  new iTeam = CE_GetMember(this, PLAYERSPAWNER_MEMBER(iTeam));
  if (!iTeam) return;

  static iszInfoPlayerStart = 0;
  if (!iszInfoPlayerStart) {
    iszInfoPlayerStart = engfunc(EngFunc_AllocString, "info_player_start");
  }

  static iszInfoPlayerDeathmatch;
  if (!iszInfoPlayerDeathmatch) {
    iszInfoPlayerDeathmatch = engfunc(EngFunc_AllocString, "info_player_deathmatch");
  }

  new Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  new Float:vecAngles[3]; pev(this, pev_angles, vecAngles);

  new pEntity = engfunc(EngFunc_CreateNamedEntity, iTeam == TEAM(Survivors) ? iszInfoPlayerStart : iszInfoPlayerDeathmatch);
  engfunc(EngFunc_SetOrigin, pEntity, vecOrigin);
  set_pev(pEntity, pev_angles, vecAngles);

  set_pev(this, pev_flags, FL_KILLME);
  dllfunc(DLLFunc_Think, this);
}

@SurvivorSpawner_Allocate(const this) {
  CE_CallBaseMethod();
  CE_SetMember(this, PLAYERSPAWNER_MEMBER(iTeam), TEAM(Survivors));
}

@ZombieSpawner_Allocate(const this) {
  CE_CallBaseMethod();
  CE_SetMember(this, PLAYERSPAWNER_MEMBER(iTeam), TEAM(Zombies));
}
