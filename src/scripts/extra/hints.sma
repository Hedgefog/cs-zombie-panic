#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_custom_events>
#include <api_player_roles>

#include <zombiepanic>
#include <zombiepanic_gamemodes>
#include <zombiepanic_internal>

/*--------------------------------[ Tasks ]--------------------------------*/

#define TASKID_RESPAWN_MESSAGE 100

/*--------------------------------[ Constants ]--------------------------------*/

#define HUD_CHAR_WIDTH (16.0 / 768.0)
#define DHUD_CHAR_WIDTH (24.0 / 768.0)

#define MESSAGE_HINT_POS -1.0, 0.10
#define MESSAGE_HINT_HOLD_TIME 5.0
#define MESSAGE_HINT_FADEIN_TIME 1.0
#define MESSAGE_HINT_FADEOUT_TIME 1.0

#define MESSAGE_OBJECTIVE_POS -1.0, 0.20
#define MESSAGE_OBJECTIVE_HOLD_TIME 5.0
#define MESSAGE_OBJECTIVE_FADEIN_TIME 1.0
#define MESSAGE_OBJECTIVE_FADEOUT_TIME 1.0

#define MESSAGE_SPEED_WARN_POS -1.0, 0.10
#define MESSAGE_SPEED_HOLD_TIME 5.0
#define MESSAGE_SPEED_FADEIN_TIME 1.0
#define MESSAGE_SPEED_FADEOUT_TIME 1.0

#define MESSAGE_RESPAWN_POS -1.0, -1.0
#define MESSAGE_RESPAWNHOLD_TIME 5.0
#define MESSAGE_RESPAWNFADEIN_TIME 1.0
#define MESSAGE_RESPAWNFADEOUT_TIME 1.0

#define MESSAGE_PICKUP_POS -1.0, 0.65
#define MESSAGE_PICKUP_HOLD_TIME 0.75
#define MESSAGE_PICKUP_FADEIN_TIME 0.5
#define MESSAGE_PICKUP_FADEOUT_TIME 1.0

#define MESSAGE_INFECTION_POS -1.0, 0.30
#define MESSAGE_INFECTION_HOLD_TIME 1.0
#define MESSAGE_INFECTION_FADEIN_TIME 1.0
#define MESSAGE_INFECTION_FADEOUT_TIME 1.0

#define HINTS_KEY "zp_hints"

/*--------------------------------[ Enums ]--------------------------------*/

enum Message {
  Message_Title[64],
  Message_Text[256]
};

enum MessageType {
  MessageType_Info,
  MessageType_Important,
  MessageType_Warn
};

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_rgMessageColors[MessageType][3] = {
  { 117, 255, 127 },
  { 0, 255, 255 },
  { 255, 160, 0 }
};

new g_rgMessage[Message];
new bool:g_bEnabled = false;

/*--------------------------------[ Players State ]--------------------------------*/

new bool:g_rgbPlayerShowObjectiveMessage[MAX_PLAYERS + 1];
new bool:g_rgbPlayerShowSpeedWarning[MAX_PLAYERS + 1];
new Float:g_rgflPlayerLastPickupHint[MAX_PLAYERS + 1];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  register_dictionary(DICTIONARY);
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Hints"), ZP_VERSION, "Hedgehog Fog");

  bind_pcvar_num(register_cvar(CVAR("hints_enabled"), "1"), g_bEnabled);

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);

  CustomEvent_Subscribe(GAMERULES_EVENT(GameInit), "EventSubscriber_GameRules_GameInit");
  CustomEvent_Subscribe(USEPICKUP_EVENT(Hover), "EventSubscriber_UsePickup_Hover");
  CustomEvent_Subscribe(BASE_ROLE_EVENT(UpdateInventoryWeight), "EventSubscriber_BaseRole_UpdateInventoryWeight");
  CustomEvent_Subscribe(INFECTION_EVENT(Set), "EventSubscriber_Infection_Set");
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  @Player_Reset(pPlayer);
}

/*--------------------------------[ Event Subscribers ]--------------------------------*/

public EventSubscriber_GameRules_GameInit() {
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;

    @Player_Reset(pPlayer);
  }
}

public EventSubscriber_Infection_Set(const pPlayer, bool:bValue, const pInfector) {
  if (!bValue) return;
  if (!pInfector) return;

  @Player_ShowInfectionMessage(pInfector, pPlayer);
}

/*--------------------------------[ Player Hooks ]--------------------------------*/

public HamHook_Player_Spawn_Post(pPlayer) {
  if (!g_bEnabled) return HAM_IGNORED;
  if (!@Player_IsHintsEnabled(pPlayer)) return HAM_IGNORED;

  if (ZP_GameRules_IsGameInProgress()) {
    if (g_rgbPlayerShowObjectiveMessage[pPlayer]) {
      @Player_ShowObjectiveMessage(pPlayer);
    }
  } else {
    @Player_ShowRandomHint(pPlayer);
  }

  return HAM_IGNORED;
}

public HamHook_Player_Killed_Post(pPlayer) {
  if (!g_bEnabled) return HAM_IGNORED;
  if (!@Player_IsHintsEnabled(pPlayer)) return HAM_IGNORED;
  if (!ZP_GameRules_IsGameInProgress()) return HAM_IGNORED;

  if (ZP_GameRules_GetVariable(GAMERULES_VARIABLE(bAllowRespawn))) {
    set_task(1.0, "Task_RespawnMessage", TASKID_RESPAWN_MESSAGE + pPlayer);
  }

  return HAM_IGNORED;
}

/*--------------------------------[ Event Subscribers ]--------------------------------*/

public EventSubscriber_BaseRole_UpdateInventoryWeight(const pPlayer) {
  if (!g_bEnabled) return;
  if (!g_rgbPlayerShowSpeedWarning[pPlayer]) return;
  if (!@Player_IsHintsEnabled(pPlayer)) return;
  if (!ZP_GameRules_IsGameInProgress()) return;
  if (PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Zombie))) return;

  static Float:flWeight; flWeight = PlayerRole_Player_GetMember(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_MEMBER(flInventoryWeight));

  if (flWeight > 24.0) {
    @Player_ShowWeightWarning(pPlayer);
    g_rgbPlayerShowSpeedWarning[pPlayer] = false;
  }
}

public EventSubscriber_UsePickup_Hover(const pPlayer, const pIteam) {
  if (!g_bEnabled) return;
  if (!@Player_IsHintsEnabled(pPlayer)) return;
  if (get_gametime() - g_rgflPlayerLastPickupHint[pPlayer] < 1.0) return;

  @Player_ShowPickupHint(pPlayer);  
}

/*--------------------------------[ Player Methods ]--------------------------------*/

@Player_Reset(const &this) {
  g_rgbPlayerShowObjectiveMessage[this] = true;
  g_rgbPlayerShowSpeedWarning[this] = true;
  g_rgflPlayerLastPickupHint[this] = 0.0;
}

@Player_IsHintsEnabled(const &this) {
  static szValue[2]; get_user_info(this, HINTS_KEY, szValue, charsmax(szValue));

  return szValue[0] != '0';
}

@Player_ShowRespawnMessage(const &this) {
  if (is_user_alive(this)) return;

  SetMessageTitle("%L", this, DICTIONARY_KEY(RespawnTitle));

  if (get_ent_data(this, "CBasePlayer", "m_iTeam") == TEAM(Zombies)) {
    new iZombieLives = ZP_GameRules_GetVariable(GAMERULES_VARIABLE(iZombiesValue));

    if (ZP_GameMode_IsActive(GAMEMODE(Survival)) && !iZombieLives) {
      SetMessageText("%L", this, DICTIONARY_KEY(RespawnNoLives));
    } else {
      SetMessageText("%L", this, DICTIONARY_KEY(RespawnZombie));
    }
  } else {
    SetMessageText("%L", this, DICTIONARY_KEY(RespawnHuman));
  }

  @Player_ShowMessage(
    this,
    MessageType_Info,
    MESSAGE_RESPAWN_POS,
    MESSAGE_RESPAWNHOLD_TIME,
    MESSAGE_RESPAWNFADEIN_TIME,
    MESSAGE_RESPAWNFADEOUT_TIME
  );
}

@Player_ShowObjectiveMessage(const &this) {
  if (ZP_GameMode_IsActive(GAMEMODE(Objective))) {
    SetMessageTitle("%L", this, DICTIONARY_KEY(Objective_ObjectiveTitle));

    if (PlayerRole_Player_HasRole(this, PLAYER_ROLE(Zombie))) {
      SetMessageText("%L", this, DICTIONARY_KEY(Objective_ObjectiveZombie));
    } else {
      SetMessageText("%L", this, DICTIONARY_KEY(Objective_ObjectiveHuman));
    }
  } else {
    SetMessageTitle("%L", this, DICTIONARY_KEY(Survival_ObjectiveTitle));

    if (PlayerRole_Player_HasRole(this, PLAYER_ROLE(Zombie))) {
      SetMessageText("%L", this, DICTIONARY_KEY(Survival_ObjectiveZombie));
    } else {
      SetMessageText("%L", this, DICTIONARY_KEY(Survival_ObjectiveHuman));
    }
  }

  g_rgbPlayerShowObjectiveMessage[this] = false;

  @Player_ShowMessage(
    this,
    MessageType_Important,
    MESSAGE_OBJECTIVE_POS,
    MESSAGE_OBJECTIVE_HOLD_TIME,
    MESSAGE_OBJECTIVE_FADEIN_TIME,
    MESSAGE_OBJECTIVE_FADEOUT_TIME
  );
}

@Player_ShowRandomHint(const &this) {
  SetMessageTitle("%L", this, DICTIONARY_KEY(HintTitle));

  switch (random(1)) {
    case 0: SetMessageText("%L", this, DICTIONARY_KEY(HintPanic));
    case 1: SetMessageText("%L", this, DICTIONARY_KEY(HintDropAmmo));
    case 2: SetMessageText("%L", this, DICTIONARY_KEY(HintPickup));
  }

  @Player_ShowMessage(
    this,
    MessageType_Info,
    MESSAGE_HINT_POS,
    MESSAGE_HINT_HOLD_TIME,
    MESSAGE_HINT_FADEIN_TIME,
    MESSAGE_HINT_FADEOUT_TIME
  );
}

@Player_ShowWeightWarning(const &this) {
  SetMessageTitle("%L", this, DICTIONARY_KEY(WarningTitle));
  SetMessageText("%L", this, DICTIONARY_KEY(SpeedWarning));

  @Player_ShowMessage(
    this,
    MessageType_Warn,
    MESSAGE_SPEED_WARN_POS,
    MESSAGE_SPEED_HOLD_TIME,
    MESSAGE_SPEED_FADEIN_TIME,
    MESSAGE_SPEED_FADEOUT_TIME
  );
}

@Player_ShowInfectionMessage(const &this, const &pVictim) {
  SetMessageTitle("%L", this, DICTIONARY_KEY(InfectionWarningTitle));
  SetMessageText("%L", this, DICTIONARY_KEY(InfectionWarningInfector), pVictim);

  @Player_ShowMessage(
    this,
    MessageType_Warn,
    MESSAGE_INFECTION_POS,
    MESSAGE_INFECTION_HOLD_TIME,
    MESSAGE_INFECTION_FADEIN_TIME,
    MESSAGE_INFECTION_FADEOUT_TIME
  );
}

@Player_ShowPickupHint(const &this) {
  SetMessageTitle("%L", this, DICTIONARY_KEY(ItemPickupTitle));
  SetMessageText("%L", this, DICTIONARY_KEY(ItemPickup));

  @Player_ShowMessage(
    this,
    MessageType_Warn,
    MESSAGE_PICKUP_POS,
    MESSAGE_PICKUP_HOLD_TIME,
    MESSAGE_PICKUP_FADEIN_TIME,
    MESSAGE_PICKUP_FADEOUT_TIME
  );

  g_rgflPlayerLastPickupHint[this] = get_gametime();
}

@Player_ShowMessage(const &this, MessageType:iType, Float:flPosX, Float:flPosY, Float:holdTime, Float:fadeInTime, Float:fadeOutTime) {
  new Float:flTitlePosY = -1.0;

  if (flPosY == -1.0) {
    new Float:flTextWidth = HUD_CHAR_WIDTH * UTIL_CalculateHUDLines(g_rgMessage[Message_Text]);
    flTitlePosY = 0.5 - DHUD_CHAR_WIDTH - (flTextWidth / 2);
  } else {
    flTitlePosY = flPosY - DHUD_CHAR_WIDTH;
  }

  set_dhudmessage(g_rgMessageColors[iType][0], g_rgMessageColors[iType][1], g_rgMessageColors[iType][2], flPosX, flTitlePosY, 0, 0.0, holdTime, fadeInTime, fadeOutTime);
  show_dhudmessage(this, g_rgMessage[Message_Title]);

  set_hudmessage(255, 255, 255, flPosX, flPosY, 0, 0.0, holdTime, fadeInTime, fadeOutTime, -1);
  show_hudmessage(this, g_rgMessage[Message_Text]);
}

/*--------------------------------[ Functions ]--------------------------------*/

SetMessageTitle(const szTitle[], any:...) {
  vformat(g_rgMessage[Message_Title], charsmax(g_rgMessage[Message_Title]), szTitle, 2);
}

SetMessageText(const szText[], any:...) {
  vformat(g_rgMessage[Message_Text], charsmax(g_rgMessage[Message_Text]), szText, 2);
}

/*--------------------------------[ Tasks ]--------------------------------*/

public Task_RespawnMessage(iTaskId) {
  new pPlayer = iTaskId - TASKID_RESPAWN_MESSAGE;

  @Player_ShowRespawnMessage(pPlayer);
}

/*--------------------------------[ Stocks ]--------------------------------*/

stock UTIL_CalculateHUDLines(const szText[]) {
  new iLinesNum = 1;
  new iLineLength = 0;

  for (new i = 0; szText[i] != '^0'; ++i) {
    iLineLength++;

    if (szText[i] == '^n' || iLineLength > 68) {
      iLinesNum++;
      iLineLength = 0;
    }
  }

  return iLinesNum;
}
