#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>

#include <zombiepanic>

#define PLUGIN "Zombie Panic"
#define AUTHOR "Hedgehog Fog"

new g_fwConfigLoaded;
new g_fwResult;

public plugin_precache() {
    for (new i = 0; i < sizeof(ZP_HUD_SPRITES); ++i) {
        precache_generic(ZP_HUD_SPRITES[i]);
    }
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
    register_cvar("mp_flashlight", "1");
    register_cvar("mp_freezetime", "10");
    register_cvar("mp_scoreboard_showmoney", "0");
    register_cvar("mp_scoreboard_showhealth", "0");
    register_cvar("mp_scoreboard_showdefkit", "0");

    g_fwConfigLoaded = CreateMultiForward("Zp_Fw_ConfigLoaded", ET_IGNORE);
}

public plugin_natives() {
    register_library("zombiepanic");
}

public plugin_cfg() {
    LoadConfig();
}

LoadConfig() {
    new szConfigDir[32];
    get_configsdir(szConfigDir, charsmax(szConfigDir));

    server_cmd("exec %s/zombiepanic.cfg", szConfigDir);
    server_exec();
    
    ExecuteForward(g_fwConfigLoaded, g_fwResult);
}
