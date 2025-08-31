
#pragma semicolon 1

#include <amxmodx>

#include <api_player_roles>
#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_gamemodes>
#include <zombiepanic_internal>

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

public plugin_precache() {
  CE_RegisterClass(ENTITY(EndRoundTrigger), CE_Class_BaseTrigger);

  CE_ImplementClassMethod(ENTITY(EndRoundTrigger), CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY(EndRoundTrigger), CE_Method_CanTrigger, "@Entity_CanTrigger");
  CE_ImplementClassMethod(ENTITY(EndRoundTrigger), CE_Method_Trigger, "@Entity_Trigger");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(EndRoundTrigger), ZP_VERSION, "Hedgehog Fog");
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  CE_SetMember(this, ENDROUNDTRIGGER_MEMBER(iPlayerFlags), 0);

  ZP_GameMode_Activate(GAMEMODE(Objective));
}

@Entity_CanTrigger(const this, pActivator) {
  if (!IS_PLAYER(pActivator))  return false;
  if (!ZP_GameRules_IsGameInProgress()) return false;
  if (!PlayerRole_Player_HasRole(pActivator, PLAYER_ROLE(Survivor))) return false;

  return CE_CallBaseMethod(pActivator);
}

@Entity_Trigger(const this, const pActivator) {
  if (ZP_GameMode_GetState(GAMEMODE_OBJECTIVE_STATE(bObjectiveCompleted))) return;

  CE_CallBaseMethod(pActivator);

  new iPlayerFlags = CE_GetMember(this, ENDROUNDTRIGGER_MEMBER(iPlayerFlags));

  CE_SetMember(this, ENDROUNDTRIGGER_MEMBER(iPlayerFlags), iPlayerFlags | (1<<(pActivator & 31)));

  ZP_GameMode_SetState(GAMEMODE_OBJECTIVE_STATE(bObjectiveCompleted), true);
  ZP_GameRules_CheckWinConditions();
}
