#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_player_roles>
#include <api_custom_events>
#include <api_assets>
#include <api_states>
#include <screenfade_util>
#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_internal>

/*--------------------------------[ Helpers ]--------------------------------*/

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

/*--------------------------------[ Constants ]--------------------------------*/

#define TRANSFORMATION_DELAY 60.0
#define TRANSFORMATION_DURATION (TRANSFORMATION_DELAY / 8.5)
#define INFECTION_ICON "dmg_bio"

#define SCORE_STATUS_VIP (1<<2)

/*--------------------------------[ Global Variables ]--------------------------------*/

new gmsgScreenShake;
new gmsgStatusIcon;
new gmsgScoreAttrib;

/*--------------------------------[ Assets ]--------------------------------*/

new g_szSound_Transformation[MAX_RESOURCE_PATH_LENGTH];
new g_rgszJoltSounds[4][MAX_RESOURCE_PATH_LENGTH];
new g_iJoltSoundsNum = 0;

/*--------------------------------[ Plugin State ]--------------------------------*/

new Float:g_flInfectionChance;
new Float:g_flCureChance;
new bool:g_bSuspendInfectionOnHeal;

/*--------------------------------[ Players State ]--------------------------------*/

new g_rgpPlayerInfector[MAX_PLAYERS + 1];
new g_rgiPlayerRoomType[MAX_PLAYERS + 1] = { -1, ... };
new Float:g_rgflPlayerOrigin[MAX_PLAYERS + 1][3];
new Float:g_rgflPlayerAngles[MAX_PLAYERS + 1][3];
new Float:g_rgflPlayerViewAngles[MAX_PLAYERS + 1][3];
new g_rgiPlayerFlags[MAX_PLAYERS + 1];
new StateManager:g_rgPlayerStateManagers[MAX_PLAYERS + 1]  = { StateManager_Invalid, ... };

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Sound_Transformation), g_szSound_Transformation, charsmax(g_szSound_Transformation));
  g_iJoltSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET(Sound_PlayerJolt), g_rgszJoltSounds, sizeof(g_rgszJoltSounds), charsmax(g_rgszJoltSounds[]));

  State_Context_Register(INFECTION_STATE_CONTEXT, INFECTION_STATE(None));
  State_Context_RegisterChangeGuard(INFECTION_STATE_CONTEXT, "@State_ChangeGuard");
  State_Context_RegisterChangeHook(INFECTION_STATE_CONTEXT, "@State_Change");
  State_Context_RegisterEnterHook(INFECTION_STATE_CONTEXT, INFECTION_STATE(None), "@State_Reset");
  State_Context_RegisterEnterHook(INFECTION_STATE_CONTEXT, INFECTION_STATE(Infected), "@State_Infected");
  State_Context_RegisterEnterHook(INFECTION_STATE_CONTEXT, INFECTION_STATE(PartialZombie), "@State_PartialZombie");
  State_Context_RegisterEnterHook(INFECTION_STATE_CONTEXT, INFECTION_STATE(Transformation), "@State_Transformation");
  State_Context_RegisterEnterHook(INFECTION_STATE_CONTEXT, INFECTION_STATE(TransformationDeath), "@State_TransformationDeath");
  State_Context_RegisterEnterHook(INFECTION_STATE_CONTEXT, INFECTION_STATE(TransformationEnd), "@State_TransformationEnd");
  State_Context_RegisterTransitionHook(INFECTION_STATE_CONTEXT, INFECTION_STATE(PartialZombie), INFECTION_STATE(Infected), "@State_Suspend");

  CustomEvent_Register(INFECTION_EVENT(Set), CEP_Cell, CEP_Cell, CEP_Cell);
  CustomEvent_Register(INFECTION_EVENT(Reset), CEP_Cell);
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Infection"), ZP_VERSION, "Hedgehog Fog");

  gmsgScoreAttrib = get_user_msgid("ScoreAttrib");
  gmsgScreenShake = get_user_msgid("ScreenShake");
  gmsgStatusIcon = get_user_msgid("StatusIcon");

  bind_pcvar_float(register_cvar(CVAR("infection_chance"), "5"), g_flInfectionChance);
  bind_pcvar_float(register_cvar(CVAR("infection_healthkit_cure_chance"), "25"), g_flCureChance);
  bind_pcvar_num(register_cvar(CVAR("infection_healthkit_suspend"), "1"), g_bSuspendInfectionOnHeal);

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);
  RegisterHamPlayer(Ham_TraceAttack, "HamHook_Player_TraceAttack", .Post = 0);
  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage", .Post = 0);
  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 0);
  RegisterHamPlayer(Ham_BloodColor, "HamHook_Player_BloodColor", .Post = 0);

  register_message(gmsgScoreAttrib, "Message_ScoreAttrib");

  CE_RegisterClassMethodHook(ENTITY(HealthKit), CE_Method_Pickup, "CEHook_HealthKit_Pickup_Post", true);
}

public plugin_natives() {
  register_library("zombiepanic_infection");
  register_native("ZP_Infection_IsPlayerInfected", "Native_SetInfected");
  register_native("ZP_Infection_IsPlayerTransforming", "Native_IsPlayerInfected");
  register_native("ZP_Infection_IsPlayerPartialZombie", "Native_IsPlayerPartialZombie");
  register_native("ZP_Infection_SetPlayerInfected", "Native_IsPlayerTransforming");
  register_native("ZP_Infection_GetPlayerInfector", "Native_GetInfector");
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  g_rgPlayerStateManagers[pPlayer] = State_Manager_Create(INFECTION_STATE_CONTEXT, pPlayer);
}

public client_disconnected(pPlayer) {
  State_Manager_Destroy(g_rgPlayerStateManagers[pPlayer]);
}

/*--------------------------------[ Natives ]--------------------------------*/

public Native_SetInfected(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);
  new bool:bValue = bool:get_param(2);
  new pInfector = get_param(3);

  @Player_SetInfected(pPlayer, bValue, pInfector);
}

public Native_IsPlayerInfected(const iPluginId, const iArgc) {
  static pPlayer; pPlayer = get_param(1);

  return @Player_IsInfected(pPlayer);
}

public bool:Native_IsPlayerPartialZombie(const iPluginId, const iArgc) {
  static pPlayer; pPlayer = get_param(1);

  return @Player_IsInfected(pPlayer) && State_Manager_GetState(g_rgPlayerStateManagers[pPlayer]) >= INFECTION_STATE(PartialZombie);
}

public bool:Native_IsPlayerTransforming(const iPluginId, const iArgc) {
  static pPlayer; pPlayer = get_param(1);

  return @Player_IsInfected(pPlayer) && State_Manager_GetState(g_rgPlayerStateManagers[pPlayer]) >= INFECTION_STATE(Transformation);
}

public Native_GetInfector(const iPluginId, const iArgc) {
  static pPlayer; pPlayer = get_param(1);

  if (!@Player_IsInfected(pPlayer)) return -1;

  return g_rgpPlayerInfector[pPlayer];
}

/*--------------------------------[ Hooks ]--------------------------------*/

public HamHook_Player_Spawn_Post(const pPlayer) {
  if (!is_user_alive(pPlayer)) return;

  State_Manager_SetState(g_rgPlayerStateManagers[pPlayer], INFECTION_STATE(None), _, true);

  for (new pTarget = 1; pTarget <= MaxClients; ++pTarget) {
    if (!is_user_connected(pTarget)) continue;
    @Player_SendInfectionAttrib(pPlayer, pTarget);
  }
}

public HamHook_Player_Killed_Post(const pPlayer) {
  if (State_Manager_GetState(g_rgPlayerStateManagers[pPlayer]) != INFECTION_STATE(TransformationDeath)) {
    State_Manager_SetState(g_rgPlayerStateManagers[pPlayer], INFECTION_STATE(None), _, true);
  }
}

public HamHook_Player_TraceAttack(const pPlayer, const pAttacker, Float:flDamage, Float:vecDir[3], const pTr, iDamageBits) {
  if (!IS_PLAYER(pAttacker)) return HAM_IGNORED;
  if (!@Player_IsInfected(pPlayer)) return HAM_IGNORED;
  if (State_Manager_GetState(g_rgPlayerStateManagers[pPlayer]) < INFECTION_STATE(PartialZombie)) return HAM_IGNORED;

  static iTeam; iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");
  static iAttackerTeam; iAttackerTeam = get_ent_data(pAttacker, "CBasePlayer", "m_iTeam");
  if (iTeam != iAttackerTeam) return HAM_IGNORED;

  set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Zombies));
  ExecuteHam(Ham_TraceAttack, pPlayer, pAttacker, flDamage, vecDir, pTr, iDamageBits);
  set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Survivors));

  return HAM_SUPERCEDE;
}

public HamHook_Player_TakeDamage(const pPlayer, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  if (!IS_PLAYER(pAttacker)) return HAM_IGNORED;
  if (!@Player_IsInfected(pPlayer)) return HAM_IGNORED;
  if (State_Manager_GetState(g_rgPlayerStateManagers[pPlayer]) < INFECTION_STATE(PartialZombie)) return HAM_IGNORED;

  static iTeam; iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");
  static iAttackerTeam; iAttackerTeam = get_ent_data(pAttacker, "CBasePlayer", "m_iTeam");
  if (iTeam != iAttackerTeam) return HAM_IGNORED;

  set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Zombies));
  ExecuteHam(Ham_TakeDamage, pPlayer, pInflictor, pAttacker, flDamage, iDamageBits);
  set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Survivors));

  return HAM_SUPERCEDE;
}

public HamHook_Player_TakeDamage_Post(const pPlayer, const pInflictor, const pAttacker) {
  if (!IS_PLAYER(pAttacker)) return HAM_IGNORED;
  if (!PlayerRole_Player_HasRole(pAttacker, PLAYER_ROLE(Zombie))) return HAM_IGNORED;
  if (PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Zombie))) return HAM_IGNORED;

  if (random(100) < g_flInfectionChance) {
    if (@Player_SetInfected(pPlayer, true, pAttacker)) {
      client_print(pAttacker, print_chat, "You've infected %n.", pPlayer);
    }
  }

  return HAM_HANDLED;
}

public HamHook_Player_BloodColor(const pPlayer) {
  if (State_Manager_GetState(g_rgPlayerStateManagers[pPlayer]) < INFECTION_STATE(PartialZombie)) return HAM_IGNORED;

  SetHamReturnInteger(-1);
  return HAM_SUPERCEDE;
}

public CEHook_HealthKit_Pickup_Post(const pHealthkit, const pPlayer) {
  static INFECTION_STATE_TYPE:iState; iState = State_Manager_GetState(g_rgPlayerStateManagers[pPlayer]);

  if (iState < INFECTION_STATE(Infected)) return CE_IGNORED;
  if (iState >= INFECTION_STATE(Transformation)) return CE_IGNORED;

  if (random(100) < g_flCureChance) {
    State_Manager_SetState(g_rgPlayerStateManagers[pPlayer], INFECTION_STATE(None), _, true);
  } else if (g_bSuspendInfectionOnHeal) {
    State_Manager_SetState(g_rgPlayerStateManagers[pPlayer], INFECTION_STATE(Infected), _, true);
  }

  return CE_HANDLED;
}

public Message_ScoreAttrib(const iMsgId, const iDest, const pPlayer) {
  if (!pPlayer) return PLUGIN_CONTINUE;
  if (is_user_bot(pPlayer)) return PLUGIN_CONTINUE;

  if (PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Zombie))) {
    new pTargetPlayer = get_msg_arg_int(1);

    if (is_user_alive(pTargetPlayer) && @Player_IsInfected(pTargetPlayer)) {
      set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) & SCORE_STATUS_VIP);
    }
  }

  return PLUGIN_CONTINUE;
}

/*--------------------------------[ State Hooks ]--------------------------------*/

@State_ChangeGuard(const StateManager:this, INFECTION_STATE_TYPE:iFromState, INFECTION_STATE_TYPE:iToState) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  if (iFromState == INFECTION_STATE(None)) {
    if (ZP_GameRules_GetVariable(GAMERULES_VARIABLE(bCompetitiveMode))) return STATE_GUARD_BLOCK;
    if (!is_user_alive(pPlayer)) return STATE_GUARD_BLOCK;
    if (PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Zombie))) return STATE_GUARD_BLOCK;
  }

  return STATE_GUARD_CONTINUE;
}

@State_Change(const StateManager:this, INFECTION_STATE_TYPE:iFromState, INFECTION_STATE_TYPE:iToState) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  new bool:bShouldUpdate; bShouldUpdate = (iFromState == INFECTION_STATE(None) || iToState == INFECTION_STATE(None));

  if (bShouldUpdate) {
    for (new pReceiver = 1; pReceiver <= MaxClients; ++pReceiver) {
      if (!is_user_connected(pReceiver)) continue;
      if (!PlayerRole_Player_HasRole(pReceiver, PLAYER_ROLE(Zombie))) continue;
      @Player_SendInfectionAttrib(pReceiver, pPlayer);
    }
  }
}

@State_Reset(const StateManager:this) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  @Player_SetSoundEcho(pPlayer, false);
  @Player_SetInfectionIcon(pPlayer, false);
  CustomEvent_Emit(INFECTION_EVENT(Reset), pPlayer);
}

@State_Suspend(const StateManager:this) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  @Player_SetSoundEcho(pPlayer, false);
  @Player_SetInfectionIcon(pPlayer, false);
}

@State_Infected(const StateManager:this) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  State_Manager_SetState(this, INFECTION_STATE(PartialZombie), TRANSFORMATION_DELAY / 2);

  static Float:flMaxHealth; pev(pPlayer, pev_max_health, flMaxHealth);
  static Float:flHealth; pev(pPlayer, pev_health, flHealth);

  if (flHealth == flMaxHealth) {
    set_pev(pPlayer, pev_health, floatmax(flHealth - 1.0, 1.0));
  }
}

@State_PartialZombie(const StateManager:this) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  g_rgiPlayerRoomType[pPlayer] = floatround(get_ent_data_float(pPlayer, "CBasePlayer", "m_flSndRoomtype"));
  @Player_SendBlinkEffect(pPlayer);
  @Player_SetSoundEcho(pPlayer, true);
  @Player_SetInfectionIcon(pPlayer, true);
  client_cmd(pPlayer, "spk %s", g_rgszJoltSounds[random(g_iJoltSoundsNum)]);

  State_Manager_SetState(this, INFECTION_STATE(Transformation), (TRANSFORMATION_DELAY / 2) - TRANSFORMATION_DURATION);
}

@State_Transformation(const StateManager:this) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  @Player_SendScreenShake(pPlayer);
  client_cmd(pPlayer, "spk %s", g_szSound_Transformation);

  State_Manager_SetState(this, INFECTION_STATE(TransformationDeath), TRANSFORMATION_DURATION);
}

@State_TransformationDeath(const StateManager:this) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  pev(pPlayer, pev_origin, g_rgflPlayerOrigin[pPlayer]);
  pev(pPlayer, pev_angles, g_rgflPlayerAngles[pPlayer]);
  pev(pPlayer, pev_v_angle, g_rgflPlayerViewAngles[pPlayer]);
  g_rgiPlayerFlags[pPlayer] = pev(pPlayer, pev_flags);

  ExecuteHamB(Ham_Killed, pPlayer, g_rgpPlayerInfector[pPlayer], 0);
  emit_sound(pPlayer, CHAN_VOICE, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

  State_Manager_SetState(this, INFECTION_STATE(TransformationEnd));
}

@State_TransformationEnd(const StateManager:this) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  set_ent_data(pPlayer, "CBasePlayer", "m_iTeam", TEAM(Zombies));
  ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);

  set_pev(pPlayer, pev_origin, g_rgflPlayerOrigin[pPlayer]);
  set_pev(pPlayer, pev_angles, g_rgflPlayerAngles[pPlayer]);
  set_pev(pPlayer, pev_v_angle, g_rgflPlayerViewAngles[pPlayer]);
  set_pev(pPlayer, pev_flags, g_rgiPlayerFlags[pPlayer]);

  @Player_SendBlinkEffect(pPlayer);

  State_Manager_SetState(g_rgPlayerStateManagers[pPlayer], INFECTION_STATE(None));
}

/*--------------------------------[ Player Methods ]--------------------------------*/

bool:@Player_IsInfected(const &this) {
  return State_Manager_GetState(g_rgPlayerStateManagers[this]) > INFECTION_STATE(None);
}

bool:@Player_SetInfected(const &this, bool:bValue, const &pInfector) {
  if (bValue == @Player_IsInfected(this)) return false;

  if (bValue) {
    g_rgpPlayerInfector[this] = pInfector;
    State_Manager_SetState(g_rgPlayerStateManagers[this], INFECTION_STATE(Infected));
  } else {
    State_Manager_SetState(g_rgPlayerStateManagers[this], INFECTION_STATE(None), _, true);
  }

  CustomEvent_Emit(INFECTION_EVENT(Set), this, bValue, pInfector);

  return true;
}

@Player_SendInfectionAttrib(const &this, const &pPlayer) {
  emessage_begin(MSG_ONE, gmsgScoreAttrib, _, this);
  ewrite_byte(pPlayer);

  if (PlayerRole_Player_HasRole(this, PLAYER_ROLE(Zombie))) {
    ewrite_byte(@Player_IsInfected(pPlayer) ? SCORE_STATUS_VIP : 0);
  } else {
    ewrite_byte(0);
  }

  emessage_end();
}

@Player_SetSoundEcho(const &this, const bool:bValue) {
  if (!bValue && g_rgiPlayerRoomType[this] == -1) return;

  emessage_begin(MSG_ONE, SVC_ROOMTYPE, _, this);
  ewrite_short(bValue ? 16 : g_rgiPlayerRoomType[this]);
  emessage_end();

  if (bValue) {
    g_rgiPlayerRoomType[this] = -1;
  }
}

@Player_SetInfectionIcon(const &this, const bool:bValue) {
  message_begin(MSG_ONE, gmsgStatusIcon, _, this);
  write_byte(bValue ? 1 : 0);
  write_string(INFECTION_ICON);
  if (bValue) {
    write_byte(255);
    write_byte(120);
    write_byte(0);
  }
  message_end();
}

@Player_SendScreenShake(const &this) {
  emessage_begin(MSG_ONE, gmsgScreenShake, _, this);
  ewrite_short(floatround(2.5 * (1<<12)));
  ewrite_short(floatround(10.0 * (1<<12)));
  ewrite_short(floatround(1.0 * (1<<12)));
  emessage_end();
}

@Player_SendBlinkEffect(const &this) {
  UTIL_ScreenFade(this, {0, 0, 0}, 0.25, 0.0, 255, FFADE_IN, false, true);
}
