#pragma semicolon 1

#include "amxmodx"

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Music"
#define AUTHOR "Hedgehog Fog"

public plugin_precache() {
  precache_generic(ZP_STARTUP_SOUND);
}

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public client_connect(id) {
  static szCommand[64];
  format(szCommand, charsmax(szCommand), "mp3 loop ^"%s^"", ZP_STARTUP_SOUND);
  client_cmd(id, szCommand);
}
