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

    register_event("TeamInfo", "Event_TeamInfo", "a");
    register_message(gmsgTeamInfo, "Message_TeamInfo");

    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
    RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);
}

public HamHook_Player_Spawn_Post(pPlayer) {
    if (ZP_Player_IsZombie(pPlayer) || UTIL_IsPlayerSpectator(pPlayer) || is_user_bot(pPlayer)) {
        @Player_ResetPlayerTeams(pPlayer);
    }
}

public HamHook_Player_Killed_Post(pPlayer) {
    if (ZP_Player_IsZombie(pPlayer) || UTIL_IsPlayerSpectator(pPlayer) || is_user_bot(pPlayer)) {
        @Player_ResetPlayerTeams(pPlayer);
    }
}

public Message_TeamInfo(iMsgId, iDest, pPlayer) {
    return pPlayer ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public Event_TeamInfo() {
    new pTargetPlayer = read_data(1);
    new iTargetTeam = get_member(pTargetPlayer, m_iTeam);

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (is_user_bot(pPlayer)) {
            continue;
        }

        if (UTIL_IsPlayerSpectator(pTargetPlayer)) {
            @Player_SendPlayerTeam(pPlayer, pTargetPlayer, g_rgszTeams[3]);
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);

        new bool:bShowTeam = (
            pPlayer == pTargetPlayer ||
            ZP_Player_IsZombie(pPlayer) ||
            UTIL_IsPlayerSpectator(pPlayer) ||
            is_user_bot(pPlayer) ||
            ZP_GameRules_IsCompetitive()
        );

        @Player_SendPlayerTeam(pPlayer, pTargetPlayer, bShowTeam ? g_rgszTeams[iTargetTeam] : g_rgszTeams[iTeam]);
    }
}

@Player_ResetPlayerTeams(this) {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        @Player_SendPlayerTeam(this, pPlayer, g_rgszTeams[iTeam]);
    }
}

@Player_SendPlayerTeam(this, pPlayer, const szTeam[]) {
    emessage_begin(MSG_ONE, gmsgTeamInfo, _, this);
    ewrite_byte(pPlayer);
    ewrite_string(szTeam);
    emessage_end();
}
