#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>

#include <api_states>
#include <api_player_roles>
#include <api_custom_events>

#include <zombiepanic>
#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define PANIC_DURATION 5.0
#define PANIC_DELAY 10.0

/*--------------------------------[ Global Variables ]--------------------------------*/

new gmsgScreenShake;

/*--------------------------------[ Players State ]--------------------------------*/

new StateManager:g_rgPlayerStateManagers[MAX_PLAYERS + 1];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  State_Context_Register(STATE_CONTEXT(Panic));
  State_Context_RegisterChangeGuard(STATE_CONTEXT(Panic), "@State_ChangeGuard");
  State_Context_RegisterEnterHook(STATE_CONTEXT(Panic), PANIC_STATE(Panic), "@State_Panic");
  State_Context_RegisterEnterHook(STATE_CONTEXT(Panic), PANIC_STATE(Rest), "@State_Rest");

  CustomEvent_Register(PANIC_EVENT(Start), CEP_Cell);
  CustomEvent_Register(PANIC_EVENT(End), CEP_Cell);
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Panic"), ZP_VERSION, "Hedgehog Fog");

  gmsgScreenShake = get_user_msgid("ScreenShake");

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);

  register_clcmd("panic", "Command_Panic");
}

/*--------------------------------[ Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  g_rgPlayerStateManagers[pPlayer] = State_Manager_Create(STATE_CONTEXT(Panic), pPlayer);
}

public client_disconnected(pPlayer) {
  State_Manager_Destroy(g_rgPlayerStateManagers[pPlayer]);
}

/*--------------------------------[ Commands ]--------------------------------*/

public Command_Panic(const pPlayer) {
  if (!PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Survivor))) return PLUGIN_HANDLED;

  State_Manager_SetState(g_rgPlayerStateManagers[pPlayer], PANIC_STATE(Panic), _, true);

  return PLUGIN_HANDLED;
}

/*--------------------------------[ Hooks ]--------------------------------*/

public HamHook_Player_Spawn_Post(const pPlayer) {
  State_Manager_SetState(g_rgPlayerStateManagers[pPlayer], PANIC_STATE(None), _, true);

  return HAM_HANDLED;
}

/*--------------------------------[ State Hooks ]--------------------------------*/

@State_Panic(const StateManager:this) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_METHOD(DropInactiveItems));

  emessage_begin(MSG_ONE, gmsgScreenShake, _, pPlayer);
  ewrite_short(floatround(1.5 * (1<<12)));
  ewrite_short(floatround(1.0 * (1<<12)));
  ewrite_short(floatround(1.0 * (1<<12)));
  emessage_end();

  State_Manager_SetState(this, PANIC_STATE(Rest), PANIC_DURATION);

  PlayerRole_Player_CallMethod(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_METHOD(PlaySound), BASE_ROLE_SOUND(Scream));
  PlayerRole_Player_SetMember(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_MEMBER(flNextItemPickup), get_gametime() + PANIC_DURATION);

  CustomEvent_Emit(PANIC_EVENT(Start), pPlayer);

  PlayerRole_Player_SetMember(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_MEMBER(flSpeedMultiplier), 1.25);
}

@State_Rest(const StateManager:this) {
  static pPlayer; pPlayer = State_Manager_GetUserToken(this);

  State_Manager_SetState(this, PANIC_STATE(None), PANIC_DELAY);

  PlayerRole_Player_SetMember(pPlayer, PLAYER_ROLE(Base), BASE_ROLE_MEMBER(flSpeedMultiplier), 1.0);

  CustomEvent_Emit(PANIC_EVENT(End), pPlayer);
}

@State_ChangeGuard(const StateManager:this, ZP_State_Panic:iFromState, ZP_State_Panic:iToState) {
  if (iFromState == PANIC_STATE(None)) {
    if (!ZP_GameRules_IsGameInProgress()) return STATE_GUARD_BLOCK;
  }

  if (iFromState == PANIC_STATE(Rest) && iToState == PANIC_STATE(Panic)) return STATE_GUARD_BLOCK;

  return STATE_GUARD_CONTINUE;
}
