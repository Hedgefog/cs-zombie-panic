
#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <api_custom_entities>

#include <zombiepanic>

#define PLUGIN "[Entity] Player Spawn Point"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME_1 "info_player_team1"
#define ENTITY_NAME_2 "info_player_team2"

#define CT_SPAWN_ENTITY_NAME "info_player_start"
#define T_SPAWN_ENTITY_NAME "info_player_deathmatch"

new g_iszInfoPlayerStart;
new g_iszInfoPlayerDeathmatch;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public plugin_precache() {
    CE_Register(ENTITY_NAME_1);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME_1, "OnInfoPlayerTeamSpawn");

    CE_Register(ENTITY_NAME_2);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME_2, "OnInfoPlayerTeamSpawn");

    g_iszInfoPlayerStart = engfunc(EngFunc_AllocString, "info_player_start");
    g_iszInfoPlayerDeathmatch = engfunc(EngFunc_AllocString, "info_player_deathmatch");
}

public OnInfoPlayerTeamSpawn(pEntity) {
    new szClassname[32];
    pev(pEntity, pev_classname, szClassname, charsmax(szClassname));

    new Float:vecOrigin[3];
    pev(pEntity, pev_origin, vecOrigin);

    new Float:vecAngles[3];
    pev(pEntity, pev_angles, vecAngles);

    CE_Remove(pEntity);

    new iszClassname = szClassname[16] == '1' ? g_iszInfoPlayerStart : g_iszInfoPlayerDeathmatch;

    new pEntity = engfunc(EngFunc_CreateNamedEntity, iszClassname);
    engfunc(EngFunc_SetOrigin, pEntity, vecOrigin);
    set_pev(pEntity, pev_angles, vecAngles);
}
