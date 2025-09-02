#pragma semicolon 1

#include <amxmodx>

#include <api_rounds>
#include <api_custom_events>
#include <screenfade_util>

#include <zombiepanic_internal>

public plugin_init() {
  register_plugin(PLUGIN_NAME("Win Messages"), ZP_VERSION, "Hedgehog Fog");

  CustomEvent_Subscribe(GAMERULES_EVENT(GameEnd), "EventSubscriber_GameRules_GameEnd");
}

public EventSubscriber_GameRules_GameEnd(const iWinnerTeam) {
  static Float:flDelay; flDelay = floatmax(Round_GetRestartRoundTime() - get_gametime(), 1.0);

  set_dhudmessage(255, 255, 255, -1.0, -1.0);

  switch (iWinnerTeam) {
    case TEAM(Zombies): show_dhudmessage(0, "Zombies have conquered...");
    case TEAM(Survivors): show_dhudmessage(0, "Humans have survived...");
    case TEAM(Spectators): show_dhudmessage(0, "Both sides have failed...");
  }

  UTIL_ScreenFade(0, {0, 0, 0}, flDelay - 1.0, 1.0, 255, FFADE_OUT, .bExternal = true);
}
