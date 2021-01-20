#pragma semicolon 1

#include <amxmodx>
#include <engine>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Controls"
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  register_clcmd("changeammotype", "OnClCmd_NextAmmo");
  register_clcmd("dropammo", "OnClCmd_DropAmmo");
  register_clcmd("panic", "OnClCmd_Panic");

  register_clcmd("radio1", "OnClCmd_NextAmmo");
  register_clcmd("radio2", "OnClCmd_DropAmmo");
  register_clcmd("buyequip", "OnClCmd_Panic");

  register_impulse(100, "OnImpulse_100");
}

public OnImpulse_100(pPlayer) {
  if (!is_user_alive(pPlayer)) {
    return PLUGIN_HANDLED;
  }

  if (ZP_Player_IsZombie(pPlayer)) {
    ZP_Player_ToggleZombieVision(pPlayer);
  } else {
    ZP_Player_ToggleFlashlight(pPlayer);
  }

  return PLUGIN_HANDLED;
}

public OnClCmd_NextAmmo(pPlayer) {
  if (ZP_Player_IsZombie(pPlayer)) {
    return PLUGIN_HANDLED;
  }

  ZP_Player_NextAmmo(pPlayer);
  return PLUGIN_HANDLED;
}

public OnClCmd_DropAmmo(pPlayer) {
  if (ZP_Player_IsZombie(pPlayer)) {
    return PLUGIN_HANDLED;
  }

  ZP_Player_DropAmmo(pPlayer);
  return PLUGIN_HANDLED;
}

public OnClCmd_Panic(pPlayer) {
  if (ZP_Player_IsZombie(pPlayer)) {
    return PLUGIN_HANDLED;
  }

  ZP_Player_Panic(pPlayer);
  return PLUGIN_HANDLED;
}
