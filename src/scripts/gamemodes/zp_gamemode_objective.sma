#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_custom_events>

#include <zombiepanic>
#include <zombiepanic_gamemodes>
#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define GAMEMODE_ID GAMEMODE(Objective)

/*--------------------------------[ Plugin State ]--------------------------------*/

new Float:g_flZombieRespawnTime;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  ZP_GameMode_Register(GAMEMODE_ID);
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(Activate), "Callback_GameMode_Activate");
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(GameStart), "Callback_GameMode_GameStart");
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(GameEnd), "Callback_GameMode_GameEnd");
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(CheckWinConditions), "Callback_GameMode_CheckWinConditions");
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(PlayerRespawn), "Callback_GameMode_PlayerRespawn");

  CustomEvent_Subscribe(GAMERULES_EVENT(TeamPreferenceChanged), "EventSubscriber_GameRules_TeamPreferenceChanged");
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("(Game Mode) Objective"), ZP_VERSION, "Hedgehog Fog");

  bind_pcvar_float(register_cvar(CVAR("zombie_respawn_time"), "6.0"), g_flZombieRespawnTime);
}

/*--------------------------------[ Callbacks ]--------------------------------*/

public Callback_GameMode_Activate() {
  ZP_GameRules_SetVariable(GAMERULES_VARIABLE(bAllowRespawn), true);
}

public Callback_GameMode_GameStart() {
  ZP_GameMode_SetState(GAMEMODE_OBJECTIVE_STATE(bObjectiveCompleted), false);
}

public Callback_GameMode_GameEnd() {
  ZP_GameMode_SetState(GAMEMODE_OBJECTIVE_STATE(bObjectiveCompleted), false);
}

public Callback_GameMode_CheckWinConditions() {
  if (ZP_GameRules_IsGameInProgress()) {
    if (ZP_GameMode_GetState(GAMEMODE_OBJECTIVE_STATE(bObjectiveCompleted))) {
      ZP_GameRules_DispatchWin(TEAM(Survivors));
      return;
    }
  }

  new iPlayersNum = 0;
  new iAliveSurvivorsNum = 0;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;

    new iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");
    switch (iTeam) {
      case TEAM(Survivors): {
        if (is_user_alive(pPlayer)) iAliveSurvivorsNum++;
        iPlayersNum++;
      }
      case TEAM(Zombies): {
        iPlayersNum++;
      }
    }
  }

  if (iPlayersNum > 1) {
    if (!iAliveSurvivorsNum) {
      ZP_GameRules_DispatchWin(TEAM(Zombies));
      return;
    }
  }
}

public Callback_GameMode_PlayerRespawn(const pPlayer) {
  static iTeam; iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");

  if (iTeam == TEAM(Survivors)) {
    set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Zombies));
  }
}

/*--------------------------------[ Event Subscribers ]--------------------------------*/

public EventSubscriber_GameRules_TeamPreferenceChanged(const pPlayer, const iPreferredTeam) {
  if (!ZP_GameMode_IsActive(GAMEMODE_ID)) return;
  if (!ZP_GameRules_IsGameInProgress()) return;

  new iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");

  switch (iPreferredTeam) {
    case TEAM(Survivors): {
      if (iTeam != TEAM(Survivors) && ZP_GameRules_IsGameInProgress()) {
        set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Zombies));
      }
    }
    case TEAM(Zombies): {
      if (iTeam != TEAM(Zombies) && is_user_alive(pPlayer)) {
        ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
      }
    }
  }
}
