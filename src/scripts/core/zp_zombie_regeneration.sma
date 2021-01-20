#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Zombie Regeneration"
#define AUTHOR "Hedgehog Fog"

#define TASKID_START_REGENERATE 100
#define TASKID_REGENERATE 200

#define REGENERATION_START_DELAY 10.0
#define REGENERATION_DELAY 0.25
#define REGENERATION_HPS 5.0

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage_Post", .Post = 1);
}

public OnPlayerTakeDamage_Post(pPlayer) {
  if (!ZP_Player_IsZombie(pPlayer)) {
    return HAM_IGNORED;
  }

  remove_task(TASKID_REGENERATE + pPlayer);
  remove_task(TASKID_START_REGENERATE + pPlayer);
  set_task(REGENERATION_START_DELAY, "TaskStartRegenerate", TASKID_START_REGENERATE + pPlayer);

  return HAM_HANDLED;
}

public TaskStartRegenerate(iTaskId) {
  new pPlayer = iTaskId - TASKID_START_REGENERATE;
  SetupRegenerateTask(pPlayer);
}

public TaskRegenerate(iTaskId) {
  new pPlayer = iTaskId - TASKID_REGENERATE;

  if (ExecuteHamB(Ham_TakeHealth, pPlayer, (REGENERATION_HPS * REGENERATION_DELAY), 0)) {
    SetupRegenerateTask(pPlayer);
  }
}

SetupRegenerateTask(pPlayer) {
  set_task(REGENERATION_DELAY, "TaskRegenerate", TASKID_REGENERATE + pPlayer);
}
