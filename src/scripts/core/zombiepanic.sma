#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#include <zombiepanic>

#define PLUGIN "Zombie Panic"
#define AUTHOR "Hedgehog Fog"

new g_pFwConfigLoaded;
new g_iFwResult;

new g_pCvarVersion;

public plugin_precache() {
    g_pCvarVersion = register_cvar("zombiepanic_version", ZP_VERSION, FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_SPONLY);
    hook_cvar_change(g_pCvarVersion, "OnVersionCvarChange");

    for (new i = 0; i < sizeof(ZP_HUD_SPRITES); ++i) {
        precache_generic(ZP_HUD_SPRITES[i]);
    }
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    register_forward(FM_GetGameDescription, "OnGetGameDescription");
    
    register_cvar("mp_flashlight", "1");
    register_cvar("mp_freezetime", "10");
    register_cvar("mp_scoreboard_showmoney", "0");
    register_cvar("mp_scoreboard_showhealth", "0");
    register_cvar("mp_scoreboard_showdefkit", "0");
    register_cvar("mp_autoteambalance", "0");
    register_cvar("mp_forcecamera", "1");

    g_pFwConfigLoaded = CreateMultiForward("Zp_Fw_ConfigLoaded", ET_IGNORE);
}

public plugin_natives() {
    register_library("zombiepanic");
}

public plugin_cfg() {
    new szConfigDir[32];
    get_configsdir(szConfigDir, charsmax(szConfigDir));

    server_cmd("exec %s/zombiepanic.cfg", szConfigDir);
    server_exec();
    
    ExecuteForward(g_pFwConfigLoaded, g_iFwResult);
}

public OnVersionCvarChange() {
    set_pcvar_string(g_pCvarVersion, ZP_VERSION);
}

public OnGetGameDescription() {
    static szGameName[32];
    format(szGameName, charsmax(szGameName), "%s %s", ZP_TITLE, ZP_VERSION);
    forward_return(FMV_STRING, szGameName);

    return FMRES_SUPERCEDE;
}
