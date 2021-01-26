#pragma semicolon 1

#include <amxmodx>

#include <zombiepanic>

#define MOTD_STYLES "<style type=^"text/css^"> body { background: #000; margin: 8px; color: #FFB000; font: normal 16px/20px Verdana, Tahoma, sans-serif; } </style>"

#define PLUGIN "[Zombie Panic] Map Info"
#define AUTHOR "Hedgehog Fog"

new g_szMotdTitle[32];
new g_szMotdData[2048];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    BuildMotd();
}

public plugin_natives() {
    register_native("ZP_ShowMapInfo", "Native_Show");
}

public Native_Show(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  ShowMotd(pPlayer);
}

ShowMotd(pPlayer) {
  show_motd(pPlayer, g_szMotdData, g_szMotdTitle);
}

BuildMotd() {
  static szMap[32];
  get_mapname(szMap, charsmax(szMap));

  static szFile[48];
  format(szFile, charsmax(szMap), "maps/%s.txt", szMap);

  copy(g_szMotdData, charsmax(g_szMotdData), MOTD_STYLES);

  new iLine = 0;
  static szLine[128];
  while (read_file(szFile, iLine++, szLine, charsmax(szLine)) != 0) {
      format(g_szMotdData, charsmax(g_szMotdData), "%s<br>%s", g_szMotdData, szLine);
  }

  copy(g_szMotdTitle, charsmax(g_szMotdTitle), szMap);
}
