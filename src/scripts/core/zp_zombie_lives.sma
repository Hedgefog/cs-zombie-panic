#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <api_rounds>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Zombie Lives"
#define AUTHOR "Hedgehog Fog"

#define TASKID_PLAYER_RESPAWN 100

#define SPAWN_DELAY 5.0

new g_iLives = 0;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);
}

public plugin_natives() {
  register_native("ZP_GameRules_GetZombieLives", "Native_GetZombieLives");
  register_native("ZP_GameRules_SetZombieLives", "Native_SetZombieLives");
  register_native("ZP_GameRules_RespawnAsZombie", "Native_RespawnAsZombie");
}

public Native_GetZombieLives(iPluginId, iArgc) {
  return g_iLives;
}

public Native_SetZombieLives(iPluginId, iArgc) {
  g_iLives = get_param(1);
}

public Native_RespawnAsZombie(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
  SetupRespawnTask(pPlayer);
}

public Zp_Fw_PlayerJoined(pPlayer) {
    ExecuteHam(Ham_Player_PreThink, pPlayer);

    if (!is_user_alive(pPlayer)) {
      SetupRespawnTask(pPlayer);
    }

    return PLUGIN_HANDLED;
}

public OnPlayerSpawn_Post(pPlayer) {
  remove_task(pPlayer);
}

public OnPlayerKilled_Post(pPlayer) {
  if (!ZP_Player_IsZombie(pPlayer) && !ZP_GameRules_GetObjectiveMode()) {
    g_iLives++;
  }

  if (!get_member_game(m_bFreezePeriod) && get_member(pPlayer, m_iTeam) != 3) {
    SetupRespawnTask(pPlayer);
  }
}

SetupRespawnTask(pPlayer) {
    remove_task(pPlayer);
    set_task(SPAWN_DELAY, "Task_RespawnPlayer", TASKID_PLAYER_RESPAWN + pPlayer);
}

RespawnPlayer(pPlayer) {
  if (!g_iLives) {
    SetupRespawnTask(pPlayer);
    return;
  }

  if (!is_user_connected(pPlayer)) {
      return;
  }

  if (is_user_alive(pPlayer)) {
      return;
  }

  if (ZP_Player_IsZombie(pPlayer)) {
    if (!ZP_GameRules_GetObjectiveMode()) {
      g_iLives--;
    }
  } else {
    set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
  }

  ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);
}

public Task_RespawnPlayer(iTaskId) {
  new pPlayer = iTaskId - TASKID_PLAYER_RESPAWN;
  RespawnPlayer(pPlayer);
}
