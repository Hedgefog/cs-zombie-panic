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

new g_pCvarRegenerationRate;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage_Post", .Post = 1);

    g_pCvarRegenerationRate = register_cvar("zp_zombie_regeneration_rate", "5.0");
}

public OnPlayerTakeDamage_Post(pPlayer) {
    if (!ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    remove_task(TASKID_REGENERATE + pPlayer);
    remove_task(TASKID_START_REGENERATE + pPlayer);
    set_task(REGENERATION_START_DELAY, "Task_StartRegenerate", TASKID_START_REGENERATE + pPlayer);

    return HAM_HANDLED;
}

SetupRegenerateTask(pPlayer) {
    set_task(REGENERATION_DELAY, "Task_Regenerate", TASKID_REGENERATE + pPlayer);
}

public Task_StartRegenerate(iTaskId) {
    new pPlayer = iTaskId - TASKID_START_REGENERATE;
    SetupRegenerateTask(pPlayer);
}

public Task_Regenerate(iTaskId) {
    new pPlayer = iTaskId - TASKID_REGENERATE;

    if (ExecuteHamB(Ham_TakeHealth, pPlayer, (get_pcvar_float(g_pCvarRegenerationRate) * REGENERATION_DELAY), 0)) {
        SetupRegenerateTask(pPlayer);
    }
}
