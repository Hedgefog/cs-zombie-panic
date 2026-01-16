#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_assets>
#include <api_rounds>
#include <api_custom_events>
#include <api_player_roles>
#include <api_custom_entities>
#include <api_custom_weapons>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define CHOOSE_TEAM_VGUI_MENU_ID 2
#define CHOOSE_TEAM1_CLASS_VGUI_MENU_ID 26
#define CHOOSE_TEAM2_CLASS_VGUI_MENU_ID 27

/*--------------------------------[ Enums ]--------------------------------*/

enum PlayerMoveFlags (<<=1) {
  PlayerMoveFlag_None = 0,
  PlayerMoveFlag_Ducking = 1,
  PlayerMoveFlag_MoveBack,
  PlayerMoveFlag_Strafing,
  PlayerMoveFlag_Run
};

enum _:TeamMenuItem {
  TeamMenuItem_Survivor,
  TeamMenuItem_Zombie,
  TeamMenuItem_Spectator = 5,
};

/*--------------------------------[ Assets ]--------------------------------*/

new g_szRoundStartSound[MAX_RESOURCE_PATH_LENGTH];
new g_szSurvivorsWinSound[MAX_RESOURCE_PATH_LENGTH];
new g_szZombiesWinSound[MAX_RESOURCE_PATH_LENGTH];
new g_szRoundDrawSound[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Cvar Pointers ]--------------------------------*/

new g_pCvarCompetitive;
new g_pCvarRespawnTime;
new g_pCvarPlayerWeightMultiplier;

/*--------------------------------[ Menu Pointers ]--------------------------------*/

new g_pTeamPreferenceMenu;

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_pTrace;

new bool:g_bGameInProgress = false;
new Float:g_flRespawnTime = 0.0;
new bool:g_bAllowRespawn = false;
new bool:g_bCompetitiveMode = false;
new g_iPlayersPerZombie = 0;
new bool:g_bLimitedRoundTime = false;
new Float:g_flPlayerWeightMultiplier = 0.0;
new g_iZombiesValue = -1;
new bool:g_bRoundExpired = false;

new bool:g_rgbVariableModified[ZP_GameRules_Variable];

/*--------------------------------[ Player State ]--------------------------------*/

new g_rgiPlayerTeamPreference[MAX_PLAYERS + 1];
new Float:g_rgflPlayerRespawnTime[MAX_PLAYERS + 1];
new Float:g_rgflPlayerNextRoleThink[MAX_PLAYERS + 1];
new PlayerMoveFlags:g_rgiPlayerMoveFlags[MAX_PLAYERS + 1];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(RoundStart), g_szRoundStartSound, charsmax(g_szRoundStartSound));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(SurvivorsWin), g_szSurvivorsWinSound, charsmax(g_szSurvivorsWinSound));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(ZombiesWin), g_szZombiesWinSound, charsmax(g_szZombiesWinSound));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(RoundDraw), g_szRoundDrawSound, charsmax(g_szRoundDrawSound));

  CustomEvent_Register(GAMERULES_EVENT(PlayerRespawn), CEP_Cell);
  CustomEvent_Register(GAMERULES_EVENT(PlayerRespawned), CEP_Cell);
  CustomEvent_Register(GAMERULES_EVENT(GameStart));
  CustomEvent_Register(GAMERULES_EVENT(GameEnd), CEP_Cell);
  CustomEvent_Register(GAMERULES_EVENT(CheckWinConditions));
  CustomEvent_Register(GAMERULES_EVENT(RoundExpired));
  CustomEvent_Register(GAMERULES_EVENT(GameInit));
  CustomEvent_Register(GAMERULES_EVENT(TeamPreferenceChanged), CEP_Cell, CEP_Cell);
  CustomEvent_Register(GAMERULES_EVENT(VariableChanged), CEP_Cell, CEP_Cell);
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Gamerules"), ZP_VERSION, "Hedgehog Fog");

  g_pCvarCompetitive = register_cvar(CVAR("competitive"), "0");
  g_pCvarRespawnTime = register_cvar(CVAR("respawn_time"), "6.0");
  g_pCvarPlayerWeightMultiplier = register_cvar(CVAR("player_weight_multiplier"), "1.0");

  g_pTeamPreferenceMenu = CreateTeamPreferenceMenu();

  register_forward(FM_CmdStart, "FMHook_CmdStart");
  register_forward(FM_ClientKill, "FMHook_ClientKill");

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn", .Post = 0);
  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed", .Post = 0);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);
  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage", .Post = 0);
  RegisterHamPlayer(Ham_Player_PostThink, "HamHook_Player_PostThink_Post", .Post = 1);
  RegisterHamPlayer(Ham_Item_PreFrame, "HamHook_Player_ItemPreFrame_Post", .Post = 1);

  RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "HC_Player_SpawnEquip");
  RegisterHookChain(RG_CBasePlayer_CanSwitchTeam, "HC_Player_CanSwitchTeam");
  RegisterHookChain(RG_CSGameRules_DeadPlayerWeapons, "HC_Player_DeadPlayerWeapons");

  register_message(get_user_msgid("ShowMenu"), "Message_ShowMenu");
  register_message(get_user_msgid("VGUIMenu"), "Message_VGUIMenu");

  register_clcmd("chooseteam", "Command_ChangeTeam");
  register_clcmd("jointeam", "Command_ChangeTeam");
  register_clcmd("joinclass", "Command_ChangeTeam");

  CustomEvent_Subscribe(BASE_ROLE_EVENT(UpdateInventoryWeight), "EventSubscriber_BaseRole_UpdateInventoryWeight");

  #if defined _reapi_included
    set_member_game(m_bCTCantBuy, 1);
    set_member_game(m_bTCantBuy, 1);
  #else
    set_gamerules_int("CHalfLifeMultiplay", "m_bCTCantBuy", 1);
    set_gamerules_int("CHalfLifeMultiplay", "m_bTCantBuy", 1);
  #endif
}

public plugin_end() {
  free_tr2(g_pTrace);
}

public plugin_natives() {
  register_library(LIBRARY(Gamerules));
  register_native("ZP_GameRules_DispatchWin", "Native_DispatchWin");
  register_native("ZP_GameRules_CanItemRespawn", "Native_CanItemRespawn");
  register_native("ZP_GameRules_CanPickupItem", "Native_CanPickupItem");
  register_native("ZP_GameRules_CheckWinConditions", "Native_CheckWinConditions");
  register_native("ZP_GameRules_SetVariable", "Native_SetVariable");
  register_native("ZP_GameRules_GetVariable", "Native_GetVariable");
  register_native("ZP_GameRules_ResetVariables", "Native_ResetVariables");
  register_native("ZP_GameRules_IsGameInProgress", "Native_IsGameInProgress");
  register_native("ZP_GameRules_IsRoundExpired", "Native_IsRoundExpired");
}

/*--------------------------------[ Natives ]--------------------------------*/

public Native_DispatchWin(const iPluginId, const iArgc) {
  new iTeam = get_param(1);

  DispatchWin(iTeam);
}

public bool:Native_CanItemRespawn(const iPluginId, const iArgc) {
  static pItem; pItem = get_param(1);

  if (!g_bGameInProgress) return true;
  if (get_gametime() - Round_GetStartTime() <= 1.0) return true;

  static Float:vecOrigin[3]; pev(pItem, pev_origin, vecOrigin);

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_alive(pPlayer)) continue;

    static Float:vecPlayerOrigin[3]; pev(pPlayer, pev_origin, vecPlayerOrigin);
    engfunc(EngFunc_TraceLine, vecOrigin, vecPlayerOrigin, IGNORE_MONSTERS | IGNORE_GLASS, pPlayer, g_pTrace);
    
    static Float:flFraction; get_tr2(g_pTrace, TR_flFraction, flFraction);
    static Float:flMinRange; flMinRange = PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Zombie)) ? 256.0 :  512.0;

    if (flFraction < 1.0) {
      flMinRange /= 2;
    }

    if (get_distance_f(vecOrigin, vecPlayerOrigin) <= flMinRange) return false;
  }

  return true;
}

public bool:Native_CanPickupItem(const iPluginId, const iArgc) {
  static pItem; pItem = get_param(1);
  static pPlayer; pPlayer = get_param(2);

  if (!IS_PLAYER(pPlayer)) return false;
  if (!is_user_alive(pPlayer)) return false;
  if (!g_bGameInProgress) return false;
  if (PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Zombie))) return false;

  if (!PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_METHOD(CanPickupItem), pItem)) {
    return false;
  }

  return true;
}

public Native_SetVariable(const iPluginId, const iArgc) {
  SetVariable(ZP_GameRules_Variable:get_param(1), any:get_param(2));
}

public any:Native_GetVariable(const iPluginId, const iArgc) {
  return GetVariable(ZP_GameRules_Variable:get_param(1));
}

public Native_ResetVariables(const iPluginId, const iArgc) {
  ResetVariables();
}

public Native_CheckWinConditions(const iPluginId, const iArgc) {
  CheckWinConditions();
}

public bool:Native_IsGameInProgress(const iPluginId, const iArgc) {
  return g_bGameInProgress;
}

public bool:Native_IsRoundExpired(const iPluginId, const iArgc) {
  return g_bRoundExpired;
}

/*--------------------------------[ Forwards ]--------------------------------*/

public ZP_OnConfigLoaded() {
  ResetVariables();
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  g_rgflPlayerRespawnTime[pPlayer] = 0.0;
  g_rgflPlayerNextRoleThink[pPlayer] = 0.0;
  g_rgiPlayerTeamPreference[pPlayer] = TEAM(Survivors);
  g_rgiPlayerMoveFlags[pPlayer] = PlayerMoveFlag_None;
}

public client_disconnected(pPlayer) {
  CheckWinConditions(pPlayer);
}

/*--------------------------------[ Round Forwards ]--------------------------------*/

public Round_OnNewRound() {
  g_bRoundExpired = false;
  
  ResetPlayerTeamPreferences();
  ShuffleTeams();

  CustomEvent_Emit(GAMERULES_EVENT(GameInit));
}

public Round_OnRoundStart() {
  DistributeTeams();

  g_bGameInProgress = true;

  RespawnPlayers();
  CustomEvent_Emit(GAMERULES_EVENT(GameStart));
  PlayGameSound(g_szRoundStartSound);
  
  CheckWinConditions();
}

public Round_OnRoundExpired() {
  if (!GetVariable(GAMERULES_VARIABLE(bLimitedRoundTime))) return;

  g_bRoundExpired = true;

  CustomEvent_Emit(GAMERULES_EVENT(RoundExpired));

  CheckWinConditions();

  g_bGameInProgress = false;
}

public Round_OnRoundEnd(iWinnerTeam) {
  g_bGameInProgress = false;

  switch (iWinnerTeam) {
    case TEAM(Zombies): PlayGameSound(g_szZombiesWinSound);
    case TEAM(Survivors): PlayGameSound(g_szSurvivorsWinSound);
    case TEAM(Spectators): PlayGameSound(g_szRoundDrawSound);
  }

  CustomEvent_Emit(GAMERULES_EVENT(GameEnd), iWinnerTeam);
}

public Round_CheckResult:Round_OnCheckRoundStart() {
  new iPlayersNum = 0;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;
    if (UTIL_IsPlayerSpectator(pPlayer)) continue;

    iPlayersNum++;
  }

  return iPlayersNum > 0 ? Round_CheckResult_Continue : Round_CheckResult_Supercede;
}

public Round_CheckResult:Round_OnCheckWinConditions() {
  return Round_CheckResult_Supercede;
}

/*--------------------------------[ Commands ]--------------------------------*/

public Command_ChangeTeam(const pPlayer) {
  if (get_ent_data(pPlayer, "CBasePlayer", "m_iTeam") == TEAM(Spectators)) {
    OpenTeamPreferenceMenu(pPlayer);
  }

  return PLUGIN_HANDLED;
}

/*--------------------------------[ Event Subscribers ]--------------------------------*/

public EventSubscriber_BaseRole_UpdateInventoryWeight(const pPlayer) {
  @Player_UpdateSpeed(pPlayer);
}

/*--------------------------------[ Message Hooks ]--------------------------------*/

public Message_ShowMenu(const iMsgId, const iDest, const pPlayer) {
  static szBuffer[32]; get_msg_arg_string(4, szBuffer, charsmax(szBuffer));

  if (equal(szBuffer, "#Team_Select", 12)) {
    set_task(0.1, "Task_Join", pPlayer);
    return PLUGIN_HANDLED;
  }

  get_msg_arg_string(4, szBuffer, charsmax(szBuffer));
  if (equal(szBuffer, "#Terrorist_Select", 17) || equal(szBuffer, "#CT_Select", 10)) {
    return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}

public Message_VGUIMenu(const iMsgId, const iDest, const pPlayer) {
  new iMenuId = get_msg_arg_int(1);

  if (iMenuId == CHOOSE_TEAM_VGUI_MENU_ID) {
    set_task(0.1, "Task_Join", pPlayer);
    return PLUGIN_HANDLED;
  }

  if (iMenuId == CHOOSE_TEAM1_CLASS_VGUI_MENU_ID) return PLUGIN_HANDLED;
  if (iMenuId == CHOOSE_TEAM2_CLASS_VGUI_MENU_ID) return PLUGIN_HANDLED;

  return PLUGIN_CONTINUE;
}

/*--------------------------------[ Player Hooks ]--------------------------------*/

public FMHook_ClientKill(const pPlayer) {
  return g_bGameInProgress ? FMRES_HANDLED : FMRES_SUPERCEDE;
}

public FMHook_CmdStart(const pPlayer, const pHandle) {
  static iFlags; iFlags = pev(pPlayer, pev_flags);
  static iButtons; iButtons = get_uc(pHandle, UC_Buttons);
  static PlayerMoveFlags:iOldMoveFlags; iOldMoveFlags = g_rgiPlayerMoveFlags[pPlayer];

  g_rgiPlayerMoveFlags[pPlayer] = PlayerMoveFlag_None;

  if (iButtons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT)) {
    if (iButtons & IN_DUCK && iFlags & FL_DUCKING) {
      g_rgiPlayerMoveFlags[pPlayer] |= PlayerMoveFlag_Ducking;
    }

    if (iButtons & IN_BACK) {
      g_rgiPlayerMoveFlags[pPlayer] |= PlayerMoveFlag_MoveBack;
    }

    if ((iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT) && ~iButtons & IN_FORWARD) {
      g_rgiPlayerMoveFlags[pPlayer] |= PlayerMoveFlag_Strafing;
    }

    if (iButtons & IN_RUN) {
      g_rgiPlayerMoveFlags[pPlayer] |= PlayerMoveFlag_Run;
    }
  }

  if (g_rgiPlayerMoveFlags[pPlayer] != iOldMoveFlags) {
    @Player_UpdateSpeed(pPlayer);
  }

  return FMRES_HANDLED;
}

public HamHook_Player_ItemPreFrame_Post(const pPlayer) {
  @Player_UpdateSpeed(pPlayer);

  return HAM_HANDLED;
}

public HamHook_Player_Spawn(const pPlayer) {
  if (g_bGameInProgress) {
    static iTeam; iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");
    PlayerRole_Player_AssignRole(pPlayer, iTeam == TEAM(Zombies) ? PLAYER_ROLE(Zombie) : PLAYER_ROLE(Survivor));
  } else {
    PlayerRole_Player_AssignRole(pPlayer, PLAYER_ROLE(Survivor));
  }

  return HAM_HANDLED;
}

public HamHook_Player_Spawn_Post(const pPlayer) {
  if (!is_user_alive(pPlayer)) return HAM_IGNORED;

  PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_METHOD(Spawn));
  PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_METHOD(UpdateModel));

  if (!g_bGameInProgress) {
    set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Survivors));
    set_pev(pPlayer, pev_takedamage, DAMAGE_NO);
    OpenTeamPreferenceMenu(pPlayer);
  } else {
    CheckWinConditions();
  }

  // Block player from switching team
  set_ent_data(pPlayer, "CBasePlayer", "m_bTeamChanged", true);

  return HAM_HANDLED;
}

public HamHook_Player_Killed(const pPlayer) {
  PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_METHOD(DropActiveItem));
  PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_METHOD(DropInactiveItems));

  return HAM_HANDLED;
}

public HamHook_Player_Killed_Post(const pPlayer) {
  PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_METHOD(Killed));

  if (GetVariable(GAMERULES_VARIABLE(bAllowRespawn))) {
    g_rgflPlayerRespawnTime[pPlayer] = get_gametime() + Float:GetVariable(GAMERULES_VARIABLE(flRespawnTime));
  }

  CheckWinConditions();

  return HAM_HANDLED;
}

public HamHook_Player_TakeDamage(const pPlayer) {
  return g_bGameInProgress ? HAM_HANDLED : HAM_SUPERCEDE;
}

public HamHook_Player_PostThink_Post(const pPlayer) {
  if (is_user_alive(pPlayer)) {
    if (g_rgflPlayerNextRoleThink[pPlayer] < get_gametime()) {
      PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_METHOD(Think));
      g_rgflPlayerNextRoleThink[pPlayer] = get_gametime() + 0.125;
    }
  } else {
    if (GetVariable(GAMERULES_VARIABLE(bAllowRespawn))) {
      @Player_RespawnThink(pPlayer);
    }
  }

  return HAM_HANDLED;
}

public HC_Player_SpawnEquip(const pPlayer) {
  // Make sure player is not wearing any items left from previous round
  rg_remove_all_items(pPlayer);

  set_pev(pPlayer, pev_armorvalue, 0.0);
  set_pev(pPlayer, pev_armortype, 0);
  set_ent_data(pPlayer, "CBasePlayer", "m_iKevlar", 0);

  if (g_bGameInProgress) {
    PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), "Equip");
  }

  /*
    Update player health base on max health.
    Fix for: https://github.com/rehlds/ReGameDLL_CS/blob/24744cd75ab019dad41ab6f154ad5ec3c115f672/regamedll/dlls/player.cpp#L5715
  */
  static Float:flMaxHealth; pev(pPlayer, pev_max_health, flMaxHealth);
  set_pev(pPlayer, pev_health, flMaxHealth);

  return HC_SUPERCEDE;
}

public HC_Player_CanSwitchTeam(const pPlayer) {
  SetHookChainReturn(ATYPE_BOOL, false);

  return HC_SUPERCEDE;
}

public HC_Player_DeadPlayerWeapons(const pPlayer) {
  SetHookChainReturn(ATYPE_INTEGER, GR_PLR_DROP_GUN_NO);

  return HC_SUPERCEDE;
}

/*--------------------------------[ Player Methods ]--------------------------------*/

@Player_RespawnThink(const &this) {
  if (!g_bGameInProgress) return; 

  static iTeam; iTeam = get_ent_data(this, "CBasePlayer", "m_iTeam");
  if (iTeam != TEAM(Survivors) && iTeam != TEAM(Zombies)) return;

  new Float:flGameTime = get_gametime();
  
  if (g_rgflPlayerRespawnTime[this] > flGameTime) return;

  if (!@Player_Respawn(this)) {
    g_rgflPlayerRespawnTime[this] = flGameTime + 1.0;
  }
}

bool:@Player_Respawn(const &this) {
  if (UTIL_IsPlayerSpectator(this)) return false;

  CustomEvent_SetToken(this);

  if (CustomEvent_Emit(GAMERULES_EVENT(PlayerRespawn), this) != CER_Continue) {
    return false;
  }

  ExecuteHamB(Ham_CS_RoundRespawn, this);

  if (!is_user_alive(this)) return false;

  CustomEvent_SetToken(this);
  CustomEvent_Emit(GAMERULES_EVENT(PlayerRespawned), this);

  return true;
}

bool:@Player_UpdateSpeed(const &this) {
  if (!is_user_alive(this)) return false;
  if (!PlayerRole_Player_HasRole(this, ZP_PlayerRole_Base)) return false;

  if (Round_IsRoundStarted()) {
    set_pev(this, pev_maxspeed, CalculatePlayerMaxSpeed(this));
  } else {
    set_pev(this, pev_maxspeed, 0.001);
  }

  return true;
}

/*--------------------------------[ Functions ]--------------------------------*/

ResetVariables() {
  SetVariable(GAMERULES_VARIABLE(flPlayerWeightMultiplier), 0.0);
  SetVariable(GAMERULES_VARIABLE(flRespawnTime), 0.0);
  SetVariable(GAMERULES_VARIABLE(bCompetitiveMode), false);
  SetVariable(GAMERULES_VARIABLE(iPlayersPerZombie), 0);
  SetVariable(GAMERULES_VARIABLE(bAllowRespawn), false);
  SetVariable(GAMERULES_VARIABLE(bLimitedRoundTime), false);
  SetVariable(GAMERULES_VARIABLE(iZombiesValue), -1);

  for (new ZP_GameRules_Variable:iVariable = ZP_GameRules_Variable:0; iVariable < ZP_GameRules_Variable; iVariable++) {
    g_rgbVariableModified[iVariable] = false;
  }
}

any:GetVariable(const ZP_GameRules_Variable:iVariable) {
  static bool:bModified; bModified = g_rgbVariableModified[iVariable];

  switch (iVariable) {
    case GAMERULES_VARIABLE(flPlayerWeightMultiplier): return bModified ? g_flPlayerWeightMultiplier : get_pcvar_float(g_pCvarPlayerWeightMultiplier);
    case GAMERULES_VARIABLE(bAllowRespawn): return bModified ? g_bAllowRespawn : false;
    case GAMERULES_VARIABLE(bCompetitiveMode): return bModified ? g_bCompetitiveMode : bool:get_pcvar_num(g_pCvarCompetitive);
    case GAMERULES_VARIABLE(flRespawnTime): return bModified ? g_flRespawnTime : get_pcvar_float(g_pCvarRespawnTime);
    case GAMERULES_VARIABLE(iPlayersPerZombie): return bModified ? g_iPlayersPerZombie : GetVariable(GAMERULES_VARIABLE(bCompetitiveMode)) ? 2 : 6;
    case GAMERULES_VARIABLE(bLimitedRoundTime): return bModified ? g_bLimitedRoundTime : false;
    case GAMERULES_VARIABLE(iZombiesValue): return bModified ? g_iZombiesValue : -1;
  }

  return 0;
}

SetVariable(const ZP_GameRules_Variable:iVariable, any:value) {
  switch (iVariable) {
    case GAMERULES_VARIABLE(flPlayerWeightMultiplier): g_flPlayerWeightMultiplier = value;
    case GAMERULES_VARIABLE(bAllowRespawn): g_bAllowRespawn = value;
    case GAMERULES_VARIABLE(bCompetitiveMode): g_bCompetitiveMode = value;
    case GAMERULES_VARIABLE(flRespawnTime): g_flRespawnTime = value;
    case GAMERULES_VARIABLE(iPlayersPerZombie): g_iPlayersPerZombie = value;
    case GAMERULES_VARIABLE(bLimitedRoundTime): g_bLimitedRoundTime = value;
    case GAMERULES_VARIABLE(iZombiesValue): g_iZombiesValue = value;
  }

  g_rgbVariableModified[iVariable] = true;

  CustomEvent_Emit(GAMERULES_EVENT(VariableChanged), iVariable, value);
}

CheckWinConditions(pIgnorePlayer = 0) {
  if (!g_bGameInProgress) return;

  new iSurvivorsNum = 0;
  new iZombiesNum = 0;
  new iPlayersNum = 0;
  new iAliveZombiesNum = 0;
  new iAliveSurvivorsNum = 0;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (pPlayer == pIgnorePlayer) continue;
    if (!is_user_connected(pPlayer)) continue;

    new iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");

    switch (iTeam) {
      case TEAM(Survivors): {
        iPlayersNum++;
        iSurvivorsNum++;
        if (is_user_alive(pPlayer)) iAliveSurvivorsNum++;
      }
      case TEAM(Zombies): {
        iPlayersNum++;
        iZombiesNum++;
        if (is_user_alive(pPlayer)) iAliveZombiesNum++;
      }
    }
  }

  if (!iPlayersNum) return;

  if (iPlayersNum > 1) {
    if (!iSurvivorsNum) {
      DispatchWin(TEAM(Zombies));
      return;
    }

    if (!iZombiesNum) {
      DispatchWin(TEAM(Survivors));
      return;
    }
  }

  CustomEvent_SetToken(pIgnorePlayer);
  if (CustomEvent_Emit(GAMERULES_EVENT(CheckWinConditions)) != CER_Continue) return;

  if (iPlayersNum > 1) {
    if (!iAliveZombiesNum && iAliveSurvivorsNum) {
      DispatchWin(TEAM(Survivors));
    } else if (!iAliveSurvivorsNum && iAliveZombiesNum) {
      DispatchWin(TEAM(Zombies));
    } else if (!iAliveZombiesNum && !iAliveSurvivorsNum) {
      DispatchWin(TEAM(Spectators));
    }

    return;
  }
  
  if (iPlayersNum) {
    if (iAliveZombiesNum + iAliveSurvivorsNum < iSurvivorsNum + iZombiesNum) {
      DispatchWin(TEAM(Spectators));
      return;
    }
  }
}

DispatchWin(const iTeam) {
  if (!g_bGameInProgress) return;

  Round_DispatchWin(iTeam);
}

DistributeTeams() {
  new iPlayersNum = 0;
  
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;
    if (is_user_hltv(pPlayer)) continue;
    if (UTIL_IsPlayerSpectator(pPlayer)) continue;

    if (g_rgiPlayerTeamPreference[pPlayer] != TEAM(Spectators)) {
      set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Survivors));
    }

    iPlayersNum++;
  }

  new iPlayersPerZombie = GetVariable(GAMERULES_VARIABLE(iPlayersPerZombie));
  new iRequiredZombieCount = iPlayersPerZombie && iPlayersNum > 1 ? floatround(float(iPlayersNum) / iPlayersPerZombie, floatround_ceil) : 0;
  new iZombiesNum = ProcessZombiePlayers(iRequiredZombieCount);

  if (iZombiesNum) {
    log_amx("Respawned %d zombies", iZombiesNum);
  }

  if (iZombiesNum < iRequiredZombieCount) {
    log_amx("Not enough zombies, a random players will be moved to the zombie team...");
    
    new iCompensationNum = iRequiredZombieCount - iZombiesNum;
    for (new i = 0; i < iCompensationNum; ++i) {
      ChooseRandomZombie();
    }
  }

  return iPlayersNum;
}

ShuffleTeams() {
  static rgpPlayers[MAX_PLAYERS + 1];
  static iPlayersNum; iPlayersNum = 0;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;
    if (UTIL_IsPlayerSpectator(pPlayer)) continue;

    rgpPlayers[iPlayersNum] = pPlayer;
    iPlayersNum++;
  }

  for (new i = 0; i < iPlayersNum; ++i) {
    UTIL_Swap(rgpPlayers[i], rgpPlayers[random(iPlayersNum)]);
  }

  for (new i = 0; i < iPlayersNum; ++i) {
    new iTeam = i % 2 ? TEAM(Survivors) : TEAM(Zombies);
    set_ent_data(rgpPlayers[i], "CBasePlayer", "m_iTeam", iTeam);
  }
}

ProcessZombiePlayers(iMaxZombies) {
  new iZombiesNum = 0;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (iMaxZombies && iZombiesNum >= iMaxZombies) break;

    if (!is_user_connected(pPlayer)) continue;
    if (UTIL_IsPlayerSpectator(pPlayer)) continue;
    if (g_rgiPlayerTeamPreference[pPlayer] != TEAM(Zombies)) continue;

    log_amx("Player ^"%n^" has chosen a zombie team", pPlayer);
    set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Zombies));
    iZombiesNum++;
  }

  return iZombiesNum;
}

ChooseRandomZombie() {
  static rgpPlayers[MAX_PLAYERS + 1];

  new iPlayersNum = 0;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;
    if (UTIL_IsPlayerSpectator(pPlayer)) continue;
    if (get_ent_data(pPlayer, "CBasePlayer", "m_iTeam") == TEAM(Zombies)) continue;

    rgpPlayers[iPlayersNum] = pPlayer;
    iPlayersNum++;
  }

  new pPlayer = rgpPlayers[random(iPlayersNum)];
  set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Zombies));

  log_amx("Player ^"%n^" was randomly moved to the zombie team", pPlayer);
}

ResetPlayerTeamPreferences() {
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer) || is_user_hltv(pPlayer)) continue;

    g_rgiPlayerTeamPreference[pPlayer] = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam") == TEAM(Spectators)
      ? TEAM(Spectators)
      : TEAM(Survivors);
  }
}

RespawnPlayers() {
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;
    if (UTIL_IsPlayerSpectator(pPlayer)) continue;

    ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);
  }
}

Float:CalculatePlayerMaxSpeed(const &pPlayer) {
  static Float:flMaxSpeed; flMaxSpeed = PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_METHOD(GetMaxSpeed));
  static Float:flInventoryWeight; flInventoryWeight = PlayerRole_Player_GetMember(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_MEMBER(flInventoryWeight));
  static Float:flSpeedMultiplier; flSpeedMultiplier = PlayerRole_Player_GetMember(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_MEMBER(flSpeedMultiplier));

  flMaxSpeed *= flSpeedMultiplier;

  if (flInventoryWeight > 0.0) {
    flMaxSpeed -= (flInventoryWeight * Float:GetVariable(GAMERULES_VARIABLE(flPlayerWeightMultiplier)));
  }

  flMaxSpeed = floatmax(flMaxSpeed, 1.0);

  // if (ZP_Player_InPanic(pPlayer)) {
  //   flMaxSpeed *= ZP_PANIC_SPEED_MODIFIER;
  // }

  if (g_rgiPlayerMoveFlags[pPlayer] & PlayerMoveFlag_Ducking) {
    flMaxSpeed *= ZP_DUCK_SPEED_MODIFIER;
  }

  if (g_rgiPlayerMoveFlags[pPlayer] & PlayerMoveFlag_MoveBack) {
    flMaxSpeed *= ZP_BACKWARD_SPEED_MODIFIER;
  }
  
  if (g_rgiPlayerMoveFlags[pPlayer] & PlayerMoveFlag_Strafing) {
    flMaxSpeed *= ZP_STRAFE_SPEED_MODIFIER;
  }

  return floatmax(flMaxSpeed, 1.0);
}

PlayGameSound(const szSound[]) {
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;
    if (is_user_bot(pPlayer)) continue;
    client_cmd(pPlayer, "spk ^"%s^"", szSound);
  }
}

/*--------------------------------[ Tasks ]--------------------------------*/

public Task_Join(const iTaskId) {
  new pPlayer = iTaskId;

  if (!is_user_connected(pPlayer)) return;
  if (is_user_hltv(pPlayer)) return;

  set_ent_data(pPlayer, "CBasePlayer", "m_bTeamChanged", get_ent_data(pPlayer, "CBasePlayer", "m_bTeamChanged") & ~BIT(8));
  set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Survivors));
  set_ent_data(pPlayer, "CBasePlayer", "m_iJoiningState", 5);

  ExecuteHam(Ham_Player_PreThink, pPlayer);
}

/*--------------------------------[ Team Menu ]--------------------------------*/

CreateTeamPreferenceMenu() {
  new iMenu = menu_create("Team Menu", "Callback_MenuHandler_TeamPreference");

  for (new i = 0; i < TeamMenuItem; ++i) {
    switch (i) {
      case TeamMenuItem_Survivor: menu_additem(iMenu, "Stay with the survivors");
      case TeamMenuItem_Zombie: menu_additem(iMenu, "Join Zombies");
      case TeamMenuItem_Spectator: menu_additem(iMenu, "Spectate");
      default: menu_addblank2(iMenu);
    }
  }

  return iMenu;
}

OpenTeamPreferenceMenu(const pPlayer) {
  menu_display(pPlayer, g_pTeamPreferenceMenu, 0);
}

public Callback_MenuHandler_TeamPreference(pPlayer, iMenu, iItem) {
  switch (iItem) {
    case TeamMenuItem_Survivor: g_rgiPlayerTeamPreference[pPlayer] = TEAM(Survivors);
    case TeamMenuItem_Zombie: g_rgiPlayerTeamPreference[pPlayer] = TEAM(Zombies);
    case TeamMenuItem_Spectator: g_rgiPlayerTeamPreference[pPlayer] = TEAM(Spectators);
  }

  if (g_rgiPlayerTeamPreference[pPlayer] != TEAM(Spectators)) {
    if (!g_bGameInProgress) {
      set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Survivors));
    }
  } else {
    set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Spectators));

    if (is_user_alive(pPlayer)) {
      ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
    }
  }

  CustomEvent_SetToken(pPlayer);
  CustomEvent_Emit(GAMERULES_EVENT(TeamPreferenceChanged), pPlayer, g_rgiPlayerTeamPreference[pPlayer]);

  return PLUGIN_HANDLED;
}

/*--------------------------------[ Stocks ]--------------------------------*/

stock UTIL_Swap(&any:a, &any:b) {
  static any:c; c = a;
  a = b;
  b = c;
}

stock bool:UTIL_IsPlayerSpectator(pPlayer) {
  static iTeam; iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");

  if (iTeam == TEAM(Zombies)) return false;
  if (iTeam == TEAM(Survivors)) return false;

  return true;
}
