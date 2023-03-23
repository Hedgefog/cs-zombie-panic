#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] TeamInfo"
#define AUTHOR "Hedgehog Fog"

new gmsgTeamInfo;

new g_rgszTeams[][] = {
    "UNASSIGNED",
    "TERRORIST",
    "CT",
    "SPECTATOR"
};

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgTeamInfo = get_user_msgid("TeamInfo");

    register_event("TeamInfo", "OnEvent", "a");
    register_message(gmsgTeamInfo, "OnMessage");

    RegisterHamPlayer(Ham_Spawn, "OnPlayerSpawn_Post", .Post = 1);
    RegisterHamPlayer(Ham_Killed, "OnPlayerKilled_Post", .Post = 1);
}

public OnPlayerSpawn_Post(pPlayer) {
    if (ZP_Player_IsZombie(pPlayer) || UTIL_IsPlayerSpectator(pPlayer) || is_user_bot(pPlayer)) {
        Reset(pPlayer);
    }
}

public OnPlayerKilled_Post(pPlayer) {
    if (ZP_Player_IsZombie(pPlayer) || UTIL_IsPlayerSpectator(pPlayer) || is_user_bot(pPlayer)) {
        Reset(pPlayer);
    }
}

public OnMessage(iMsgId, iDest, pPlayer) {
    return pPlayer ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public OnEvent() {
    new pTargetPlayer = read_data(1);

    static szTeam[16];
    read_data(2, szTeam, charsmax(szTeam));

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        new bool:bShowTeam = ZP_Player_IsZombie(pPlayer)
            || UTIL_IsPlayerSpectator(pPlayer)
            || UTIL_IsPlayerSpectator(pTargetPlayer)
            || is_user_bot(pPlayer)
            || ZP_GameRules_IsCompetitive();

        SendMessage(pPlayer, pTargetPlayer, bShowTeam ? szTeam : g_rgszTeams[iTeam]);
    }
}

Reset(pPlayer) {
    for (new pTargetPlayer = 1; pTargetPlayer <= MaxClients; ++pTargetPlayer) {
        if (!is_user_connected(pTargetPlayer)) {
            continue;
        }

        static szTeam[16];
        get_user_team(pTargetPlayer, szTeam, charsmax(szTeam));
        SendMessage(pPlayer, pTargetPlayer, szTeam);
    }
}

SendMessage(pPlayer, pTargetPlayer, const szTeam[]) {
    emessage_begin(MSG_ONE, gmsgTeamInfo, _, pPlayer);
    ewrite_byte(pTargetPlayer);
    ewrite_string(szTeam);
    emessage_end();
}
