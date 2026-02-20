#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_rounds>
#include <api_custom_events>
#include <api_player_roles>
#include <api_custom_weapons>

#include <zombiepanic>
#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define DEFAULT_FOV 90
#define SCORE_STATUS_DEAD (1<<0)

/*--------------------------------[ Enums ]--------------------------------*/

enum StatusBarState {
  StatusBarState_TargetType = 1,
  StatusBarState_Target
};

/*--------------------------------[ Global Variables ]--------------------------------*/

new gmsgHideWeapon;
new gmsgSetFOV;
new gmsgCurWeapon;
new gmsgDeathMsg;
new gmsgWeapPickup;
new gmsgScoreAttrib;
new gmsgRadar;
new gmsgScoreInfo;
new gmsgStatusValue;
new gmsgTeamInfo;
new gmsgAmmoX;

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_rgStatusBarHeader[StatusBarState];
new g_iZombiesValue = 0;

/*--------------------------------[ Player State ]--------------------------------*/

new g_rgiPlayerHideWeapon[MAX_PLAYERS + 1];
new g_rgiPlayerScoreAttrib[MAX_PLAYERS + 1];
new bool:g_rgbPlayerInScore[MAX_PLAYERS + 1];
new g_rgiPlayerDeaths[MAX_PLAYERS + 1];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_init() {
  register_plugin(PLUGIN_NAME("Crosshair HUD"), ZP_VERSION, "Hedgehog Fog");

  gmsgHideWeapon = get_user_msgid("HideWeapon");
  gmsgSetFOV = get_user_msgid("SetFOV");
  gmsgCurWeapon = get_user_msgid("CurWeapon");
  gmsgDeathMsg = get_user_msgid("DeathMsg");
  gmsgWeapPickup = get_user_msgid("WeapPickup");
  gmsgScoreAttrib = get_user_msgid("ScoreAttrib");
  gmsgRadar = get_user_msgid("Radar");
  gmsgScoreInfo = get_user_msgid("ScoreInfo");
  gmsgStatusValue = get_user_msgid("StatusValue");
  gmsgTeamInfo = get_user_msgid("TeamInfo");
  gmsgAmmoX = get_user_msgid("AmmoX");

  register_event("TeamInfo", "Event_Global_TeamInfo", "a");
  register_event("ScoreInfo", "Event_Global_ScoreInfo", "a");
  register_event("ResetHUD", "Event_Single_ResetHUD", "b");
  register_event("HideWeapon", "Event_Single_HideWeapon", "b", "1=1");
  register_event("CurWeapon", "Event_Single_CurWeapon", "b", "1=1");
  register_event("StatusValue", "Event_Single_StatusValue", "b");

  register_message(gmsgStatusValue, "Message_StatusValue");
  register_message(gmsgTeamInfo, "Message_TeamInfo");
  register_message(gmsgScoreInfo, "Message_ScoreInfo");
  register_message(gmsgScoreAttrib, "Message_ScoreAttrib");
  register_message(gmsgRadar, "Message_Radar");
  register_message(gmsgWeapPickup, "Message_WeapPickup");
  register_message(gmsgDeathMsg, "Message_DeathMsg");
  register_message(gmsgHideWeapon, "Message_HideWeapon");

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed", .Post = 0);

  CustomEvent_Subscribe(GAMERULES_EVENT(GameStart), "EventSubscriber_GameRules_GameStart");
  CustomEvent_Subscribe(GAMERULES_EVENT(VariableChanged), "EventSubscriber_GameRules_VariableChanged");
}

/*--------------------------------[ Events Hooks ]--------------------------------*/

public Event_Single_HideWeapon(const pPlayer) {
  @Player_UpdateCrosshair(pPlayer);
}

public Event_Single_CurWeapon(const pPlayer) {
  @Player_UpdateCrosshair(pPlayer);
}

public Event_Single_ResetHUD(const pPlayer) {
  @Player_UpdateHideHUD(pPlayer);  
}

public Event_Global_TeamInfo() {
  new pTargetPlayer = read_data(1);

  SendPlayerTeamInfo(pTargetPlayer);
}

public Event_Global_ScoreInfo() {
  new pTargetPlayer = read_data(1);

  SendPlayerScoreInfo(pTargetPlayer);

  return PLUGIN_HANDLED;
}

public Event_Single_StatusValue(const pPlayer) {
  new StatusBarState:iState = StatusBarState:read_data(1);

  if (_:iState == _:StatusBarState - 1 && g_rgStatusBarHeader[StatusBarState_Target]) {
    // The whole StatusValue header is received, overwrite it with the new values
    new bool:bShouldSeeTarget = @Player_ShouldSeePlayerInfo(pPlayer, g_rgStatusBarHeader[StatusBarState_Target]);

    message_begin(MSG_ONE, gmsgStatusValue, _, pPlayer);
    write_byte(_:StatusBarState_TargetType);
    write_short(bShouldSeeTarget ? g_rgStatusBarHeader[StatusBarState_TargetType] : 0);
    message_end();

    message_begin(MSG_ONE, gmsgStatusValue, _, pPlayer);
    write_byte(_:StatusBarState_Target);
    write_short(g_rgStatusBarHeader[StatusBarState_Target]);
    message_end();
  }
}

/*--------------------------------[ Messages Hooks ]--------------------------------*/

public Message_DeathMsg(const iMsgId, const iDest, const pPlayer) {
  if (pPlayer) return PLUGIN_CONTINUE;

  new pKiller = get_msg_arg_int(1);
  new pVictim = get_msg_arg_int(2);
  new iHeadshot = get_msg_arg_int(3);

  static szWeapon[32]; get_msg_arg_string(4, szWeapon, charsmax(szWeapon));

  SendDeathMsg(pKiller, pVictim, iHeadshot, szWeapon);

  return PLUGIN_HANDLED;
}

public Message_StatusValue(const iMsgId, const iDest, const pPlayer) {
  static StatusBarState:iState; iState = StatusBarState:get_msg_arg_int(1);
  static iValue; iValue = get_msg_arg_int(2);

  if (_:iState < sizeof(g_rgStatusBarHeader)) {
    g_rgStatusBarHeader[iState] = iValue;
  }

  // If not null target type (not status reset)
  if (g_rgStatusBarHeader[StatusBarState_TargetType]) {
    // Waiting for target state to be set
    if (iState < StatusBarState) return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}

public Message_ScoreAttrib(const iMsgId, const iDest, const pPlayer) {
  if (is_user_bot(pPlayer)) return PLUGIN_CONTINUE;

  static pTargetPlayer; pTargetPlayer = get_msg_arg_int(1);

  g_rgiPlayerScoreAttrib[pPlayer] = get_msg_arg_int(2);

  // !HACK! Hide Radar HUD
  if (pTargetPlayer == pPlayer) {
    if (!g_rgbPlayerInScore[pPlayer]) {
      set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) | SCORE_STATUS_DEAD);
    }
  } else {
    if (!@Player_ShouldSeePlayerInfo(pPlayer, pTargetPlayer)) {
      set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) & ~SCORE_STATUS_DEAD);
    }
  }

  return PLUGIN_CONTINUE;
}

public Message_HideWeapon(const iMsgId, const iDest, const pPlayer) {
  if (is_user_bot(pPlayer)) return PLUGIN_CONTINUE;

  g_rgiPlayerHideWeapon[pPlayer] = get_msg_arg_int(1);

  set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | @Player_GetHideWeaponBits(pPlayer));

  return PLUGIN_CONTINUE;
}

public Message_WeapPickup(const iMsgId, const iDest, const pPlayer) {
  if (is_user_bot(pPlayer)) return PLUGIN_CONTINUE;

  return PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Zombie)) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public Message_TeamInfo(const iMsgId, const iDest, const pPlayer) {
  return pPlayer ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public Message_ScoreInfo(const iMsgId, const iDest, const pPlayer) {
  return pPlayer ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public Message_Radar(const iMsgId, const iDest, const pPlayer) {
  return is_user_bot(pPlayer) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

/*--------------------------------[ Events Subscribers ]--------------------------------*/

public EventSubscriber_GameRules_GameStart() {
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;

    g_rgiPlayerDeaths[pPlayer] = get_ent_data(pPlayer, "CBasePlayer", "m_iDeaths");
  }
}

public EventSubscriber_GameRules_VariableChanged(const ZP_GameRules_Variable:iVariable, any:value) {
  if (iVariable == GAMERULES_VARIABLE(iZombiesValue)) {
    g_iZombiesValue = value;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
      if (!is_user_connected(pPlayer)) continue;

      @Player_UpdateZombiesValue(pPlayer);
    }
  }
}

/*--------------------------------[ Player Hooks ]--------------------------------*/

public HamHook_Player_Spawn_Post(const pPlayer) {
  @Player_UpdatePlayersInfo(pPlayer);
  @Player_UpdateZombiesValue(pPlayer);

  return HAM_HANDLED;
}

public HamHook_Player_Killed(const pPlayer) {
  @Player_UpdatePlayersInfo(pPlayer);

  return HAM_HANDLED;
}

/*--------------------------------[ Player Methods ]--------------------------------*/

@Player_UpdatePlayersInfo(const &this) {
  for (new pTargetPlayer = 1; pTargetPlayer <= MaxClients; ++pTargetPlayer) {
    if (!is_user_connected(pTargetPlayer)) continue;

    @Player_UpdatePlayerScoreInfo(this, pTargetPlayer);
    @Player_UpdatePlayerTeam(this, pTargetPlayer);
  }
}

@Player_UpdatePlayerScoreInfo(const &this, const &pPlayer) {
  new iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");
  new iTargetScore = get_user_frags(pPlayer);
  new iTargetDeaths = get_ent_data(pPlayer, "CBasePlayer", "m_iDeaths");
  new iTargetClassId = 0;
  new iTargetPlayerTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");

  if (@Player_ShouldSeePlayerInfo(this, pPlayer)) {
    @Player_SendPlayerScoreInfo(this, pPlayer, iTargetScore, iTargetDeaths, iTargetClassId, iTargetPlayerTeam);
  } else {
    @Player_SendPlayerScoreInfo(this, pPlayer, iTargetScore, g_rgiPlayerDeaths[pPlayer], iTargetClassId, iTeam);
  }
}

@Player_UpdatePlayerTeam(const &this, const &pPlayer) {
  static iTeam; iTeam = get_ent_data(this, "CBasePlayer", "m_iTeam");

  static iTargetTeam; iTargetTeam = @Player_ShouldSeePlayerInfo(this, pPlayer)
    ? get_ent_data(pPlayer, "CBasePlayer", "m_iTeam")
    : iTeam;

  @Player_SendPlayerTeam(this, pPlayer, iTargetTeam);
}

bool:@Player_ShouldSeePlayerInfo(const &this, const &pTargetPlayer) {
  if (pTargetPlayer == this) return true;
  if (is_user_bot(this)) return true;
  if (!is_user_alive(this)) return true;
  if (ZP_GameRules_GetVariable(GAMERULES_VARIABLE(bCompetitiveMode))) return true;

  new iTeam = get_ent_data(this, "CBasePlayer", "m_iTeam");
  if (iTeam != TEAM(Survivors)) return true;

  new iTargetTeam = get_ent_data(pTargetPlayer, "CBasePlayer", "m_iTeam");
  if (iTeam == iTargetTeam && is_user_alive(pTargetPlayer)) return true;

  return false;
}

@Player_UpdateHideHUD(const &this) {
  if (is_user_bot(this)) return;

  emessage_begin(MSG_ONE, gmsgHideWeapon, _, this);
  ewrite_byte(@Player_GetHideWeaponBits(this));
  emessage_end();
}

@Player_UpdateCrosshair(const &this) {
  if (is_user_bot(this)) return;
  
  emessage_begin(MSG_ONE, gmsgHideWeapon, _, this);
  ewrite_byte(g_rgiPlayerHideWeapon[this] | HIDEHUD_CROSSHAIR | HIDEHUD_OBSERVER_CROSSHAIR);
  emessage_end();

  message_begin(MSG_ONE, gmsgSetFOV, _, this);
  write_byte(DEFAULT_FOV - 1);
  message_end();
  
  if (is_user_alive(this)) {
    new pActiveItem = get_ent_data_entity(this, "CBasePlayer", "m_pActiveItem");

    if (pActiveItem != FM_NULLENT) {
      new iWeaponId = get_ent_data(pActiveItem, "CBasePlayerItem", "m_iId");
      new iClip = is_user_alive(this) ? get_ent_data(pActiveItem, "CBasePlayerWeapon", "m_iClip") : 0;

      message_begin(MSG_ONE, gmsgCurWeapon, _, this);
      write_byte(1);
      write_byte(iWeaponId);
      write_byte(iClip);
      message_end();
    }
  }

  message_begin(MSG_ONE, gmsgSetFOV, _, this);
  write_byte(get_ent_data(this, "CBasePlayer", "m_iFOV"));
  message_end();
}

@Player_SendPlayerScoreInfo(const &this, const &pPlayer, iScore, iDeaths, iClassId, iTeam) {
  emessage_begin(MSG_ONE, gmsgScoreInfo, _, this);
  ewrite_byte(pPlayer);
  ewrite_short(iScore);
  ewrite_short(iDeaths);
  ewrite_short(iClassId);
  ewrite_short(iTeam);
  emessage_end();
}

@Player_SendPlayerTeam(const &this, const &pPlayer, iTeam) {
  static const rgszTeams[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" };
  if (iTeam > 3 || iTeam < 0) iTeam = TEAM(Unassigned);

  emessage_begin(MSG_ONE, gmsgTeamInfo, _, this);
  ewrite_byte(pPlayer);
  ewrite_string(rgszTeams[iTeam]);
  emessage_end();
}

@Player_SendDeathMsg(const &this, const &pKiller, const &pVictim, iHeadshot, const szWeapon[]) {
  emessage_begin(MSG_ONE, gmsgDeathMsg, _, this);
  ewrite_byte(pKiller);
  ewrite_byte(pVictim);
  ewrite_byte(iHeadshot);
  ewrite_string(szWeapon);
  emessage_end();
}

@Player_GetHideWeaponBits(const &this) {
  new iValue = 0;

  iValue |= HIDEHUD_MONEY;

  if (!Round_IsFreezePeriod()) {
    if (!ZP_GameRules_GetVariable(GAMERULES_VARIABLE(bLimitedRoundTime))) {
      iValue |= HIDEHUD_TIMER;
    }
  }

  if (g_iZombiesValue == -1 && PlayerRole_Player_HasRole(this, PLAYER_ROLE(Zombie))) {
    iValue |= HIDEHUD_WEAPONS;
  }

  return iValue;
}

@Player_UpdateZombiesValue(const &this) {
  if (!PlayerRole_Player_HasRole(this, PLAYER_ROLE(Zombie))) return;
  
  message_begin(MSG_ONE, gmsgAmmoX, _, this);
  write_byte(CW_Ammo_GetType(AMMO(ZombiesValue)));
  write_byte(g_iZombiesValue);
  message_end();
}

/*--------------------------------[ Functions ]--------------------------------*/

SendDeathMsg(const &pKiller, const &pVictim, iHeadshot, const szWeapon[]) {
  for (new pTargetPlayer = 1; pTargetPlayer <= MaxClients; ++pTargetPlayer) {
    if (!is_user_connected(pTargetPlayer)) continue;
    if (!@Player_ShouldSeePlayerInfo(pTargetPlayer, pVictim)) continue;

    @Player_SendDeathMsg(pTargetPlayer, pKiller, pVictim, iHeadshot, szWeapon);
  }
}

SendPlayerTeamInfo(const &pPlayer) {
  for (new pTargetPlayer = 1; pTargetPlayer <= MaxClients; ++pTargetPlayer) {
    if (!is_user_connected(pTargetPlayer)) continue;

    @Player_UpdatePlayerTeam(pTargetPlayer, pPlayer);
  }
}

SendPlayerScoreInfo(const &pPlayer) {
  for (new pTargetPlayer = 1; pTargetPlayer <= MaxClients; ++pTargetPlayer) {
    if (!is_user_connected(pTargetPlayer)) continue;

    @Player_UpdatePlayerScoreInfo(pTargetPlayer, pPlayer);
  }
}
