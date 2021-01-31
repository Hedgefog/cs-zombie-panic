#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] TeamInfo"
#define AUTHOR "Hedgehog Fog"

#define FAKE_TEAM_NAME "CT"

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

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
}

public OnPlayerSpawn_Post(pPlayer) {
    if (ZP_Player_IsZombie(pPlayer) || is_user_bot(pPlayer)) {
        Reset(pPlayer);
    }
}

public OnMessage(iMsgId, iDest, pPlayer) {
    return pPlayer ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public OnEvent() {
    new iTargetPlayer = read_data(1);

    static szTeam[16];
    read_data(2, szTeam, charsmax(szTeam));

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        SendMessage(pPlayer, iTargetPlayer, ZP_Player_IsZombie(pPlayer) || is_user_bot(pPlayer) ? szTeam : g_rgszTeams[iTeam]);
    }
}

Reset(pPlayer) {
    for (new iTargetPlayer = 1; iTargetPlayer <= MaxClients; ++iTargetPlayer) {
        if (!is_user_connected(iTargetPlayer)) {
            continue;
        }

        static szTeam[16];
        get_user_team(iTargetPlayer, szTeam, charsmax(szTeam));
        SendMessage(pPlayer, iTargetPlayer, szTeam);
    }
}

SendMessage(pPlayer, iTargetPlayer, const szTeam[]) {
    emessage_begin(MSG_ONE, gmsgTeamInfo, _, pPlayer);
    ewrite_byte(iTargetPlayer);
    ewrite_string(szTeam);
    emessage_end();
}
