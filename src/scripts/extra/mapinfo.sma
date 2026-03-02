#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>

#include <api_rounds>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define MOTD_STYLES "<style type=^"text/css^"> body { background: #000; margin: 8px; color: #FFB000; font: normal 16px/20px Verdana, Tahoma, sans-serif; } </style>"

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_szMotdTitle[32];
new g_szMotdData[MAX_MOTD_LENGTH];

new bool:g_bEnabled = false;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  BuildMotd();
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Map Info"), ZP_VERSION, "Hedgehog Fog");

  bind_pcvar_num(create_cvar(CVAR("mapinfo"), "0"), g_bEnabled);

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
}

/*--------------------------------[ Hooks ]--------------------------------*/

public HamHook_Player_Spawn_Post(const pPlayer) {
  if (!is_user_alive(pPlayer)) return HAM_IGNORED;

  if (g_bEnabled) {
    if (!Round_IsStarted()) {
      @Player_ShowMotd(pPlayer);
    }
  }

  return HAM_HANDLED;
}

/*--------------------------------[ Player Methods ]--------------------------------*/

@Player_ShowMotd(const &pPlayer) {
  if (equal(g_szMotdData, NULL_STRING)) return;

  show_motd(pPlayer, g_szMotdData, g_szMotdTitle);
}

/*--------------------------------[ Functions ]--------------------------------*/

BuildMotd() {
  new szMap[64]; get_mapname(szMap, charsmax(szMap));
  new szFile[MAX_RESOURCE_PATH_LENGTH]; format(szFile, charsmax(szFile), "maps/%s.txt", szMap);

  if (!file_exists(szFile)) return;

  copy(g_szMotdData, charsmax(g_szMotdData), MOTD_STYLES);

  new iLine = 0;
  new szLine[128];
  while (read_file(szFile, iLine++, szLine, charsmax(szLine)) != 0) {
    format(g_szMotdData, charsmax(g_szMotdData), "%s<br>%s", g_szMotdData, szLine);
  }

  copy(g_szMotdTitle, charsmax(g_szMotdTitle), szMap);
}
