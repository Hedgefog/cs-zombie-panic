#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_custom_events>

#include <zombiepanic>
#include <zombiepanic_internal>
#include <zombiepanic_gamemodes>

/*--------------------------------[ Constants ]--------------------------------*/

#define GAMEMODE_ID GAMEMODE(Survival)

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_iDefaultZombieLives;
new g_iZombieLivesStartMax;
new g_iZombieLivesPerPlayer;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  ZP_GameMode_Register(GAMEMODE_ID);
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(Activate), "Callback_GameMode_Activate");
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(GameStart), "Callback_GameMode_GameStart");
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(GameEnd), "Callback_GameMode_GameEnd");
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(CheckWinConditions), "Callback_GameMode_CheckWinConditions");
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(CanPlayerRespawn), "Callback_GameMode_CanPlayerRespawn");
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(PlayerRespawn), "Callback_GameMode_PlayerRespawn");
  ZP_GameMode_SetCallback(GAMEMODE_ID, GAMEMODE_CALLBACK(PlayerRespawned), "Callback_GameMode_PlayerRespawned");

  ZP_GameMode_SetDefault(GAMEMODE_ID);

  CustomEvent_Subscribe(GAMERULES_EVENT(TeamPreferenceChanged), "EventSubscriber_GameRules_TeamPreferenceChanged");
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("(Game Mode) Survival"), ZP_VERSION, "Hedgehog Fog");

  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);

  bind_pcvar_num(create_cvar(CVAR("zombie_lives"), "8"), g_iDefaultZombieLives);
  bind_pcvar_num(create_cvar(CVAR("zombie_lives_per_player"), "1"), g_iZombieLivesPerPlayer);
  bind_pcvar_num(create_cvar(CVAR("zombie_lives_start_max"), "10"), g_iZombieLivesStartMax);
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_disconnected(pPlayer) {
  if (is_user_alive(pPlayer)) {
    new iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");

    if (iTeam == TEAM(Zombies)) {
      SetZombieLives(GetZombieLives() + 1);
    } else {
      SetZombieLives(GetZombieLives() - 1);
    }
  }
}

/*--------------------------------[ Callbacks ]--------------------------------*/

public Callback_GameMode_Activate() {
  ZP_GameRules_SetVariable(GAMERULES_VARIABLE(bAllowRespawn), true);
  ZP_GameRules_SetVariable(GAMERULES_VARIABLE(bLimitedRoundTime), true);
}

public Callback_GameMode_GameStart() {
  new iHumanCount = CalculatePlayerCount(TEAM(Survivors));

  new iZombieLives = min(g_iDefaultZombieLives + (iHumanCount * g_iZombieLivesPerPlayer), g_iZombieLivesStartMax);

  SetZombieLives(iZombieLives);
}

public Callback_GameMode_GameEnd() {
  SetZombieLives(0);
}

public Callback_GameMode_CheckWinConditions() {
  if (ZP_GameRules_IsRoundExpired()) {
    ZP_GameRules_DispatchWin(TEAM(Survivors));
    log_amx("Round expired, survivors win!");
    return;
  }

  new iPlayersNum = 0;
  new iAliveSurvivorsNum = 0;
  new iAliveZombiesNum = 0;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;

    new iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");
    switch (iTeam) {
      case TEAM(Survivors): {
        if (is_user_alive(pPlayer)) iAliveSurvivorsNum++;
        iPlayersNum++;
      }
      case TEAM(Zombies): {
        if (is_user_alive(pPlayer)) iAliveZombiesNum++;
        iPlayersNum++;
      }
    }
  }

  if (iPlayersNum > 1) {
    if (!iAliveZombiesNum && !GetZombieLives()) {
      ZP_GameRules_DispatchWin(TEAM(Survivors));
      return;
    }

    if (!iAliveSurvivorsNum) {
      ZP_GameRules_DispatchWin(TEAM(Zombies));
      return;
    }
  } else {
    if (!iAliveSurvivorsNum && !iAliveZombiesNum && !GetZombieLives()) {
      ZP_GameRules_DispatchWin(TEAM(Survivors));
      return;
    }
  }
}

public Callback_GameMode_CanPlayerRespawn(const pPlayer) {
  if (!GetZombieLives()) return false;

  return true;
}

public Callback_GameMode_PlayerRespawn(const pPlayer) {
  static iTeam; iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");

  if (iTeam == TEAM(Survivors)) {
    set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Zombies));
  }
}

public Callback_GameMode_PlayerRespawned(const pPlayer) {
  static iTeam; iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");

  if (iTeam == TEAM(Zombies)) {
    SetZombieLives(GetZombieLives() - 1);
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

/*--------------------------------[ Hooks ]--------------------------------*/

public HamHook_Player_Killed_Post(const pPlayer) {
  if (!ZP_GameMode_IsActive(GAMEMODE_ID)) return HAM_IGNORED;

  static iTeam; iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");

  if (iTeam != TEAM(Zombies)) {
    SetZombieLives(GetZombieLives() + 2);
  }

  return HAM_HANDLED;
}

/*--------------------------------[ Functions ]--------------------------------*/

SetZombieLives(const iValue) {
  ZP_GameRules_SetVariable(GAMERULES_VARIABLE(iZombiesValue), max(iValue, 0));
}

GetZombieLives() {
  return ZP_GameRules_GetVariable(GAMERULES_VARIABLE(iZombiesValue));
}

CalculatePlayerCount(iTeam = -1) {
  new iPlayersNum = 0;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;
    if (iTeam != -1 && iTeam != get_ent_data(pPlayer, "CBasePlayer", "m_iTeam")) continue;

    iPlayersNum++;
  }

  return iPlayersNum;
}
