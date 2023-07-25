#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>


#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] ScoreInfo"
#define AUTHOR "Hedgehog Fog"

new gmsgScoreInfo;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgScoreInfo = get_user_msgid("ScoreInfo");

    register_event("ScoreInfo", "Event_ScoreInfo", "a");
    register_message(gmsgScoreInfo, "Message_ScoreInfo");

    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
}

public HamHook_Player_Spawn_Post(pPlayer) {
    for (new pTargetPlayer = 1; pTargetPlayer <= MaxClients; ++pTargetPlayer) {
        if (!is_user_connected(pTargetPlayer)) {
            continue;
        }

        @Player_UpdatePlayerScoreInfo(pPlayer, pTargetPlayer);
    }
}

public Message_ScoreInfo(iMsgId, iDest, pPlayer) {
    return pPlayer ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public Event_ScoreInfo() {
    new pTargetPlayer = read_data(1);

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        @Player_UpdatePlayerScoreInfo(pPlayer, pTargetPlayer);
    }

    return PLUGIN_HANDLED;
}

@Player_UpdatePlayerScoreInfo(this, pPlayer) {
    new iTeam = get_member(pPlayer, m_iTeam);

    new iTargetScore = get_user_frags(pPlayer);
    new iTargetDeaths = get_member(pPlayer, m_iDeaths);
    new iTargetClassId = 0;
    new iTargetTeam = get_member(pPlayer, m_iTeam);

    if (UTIL_IsPlayerSpectator(pPlayer)) {
        @Player_SendPlayerScoreInfo(this, pPlayer, iTargetScore, iTargetDeaths, iTargetClassId, 3);
        return;
    }

    new bool:bShowTeam = (
        pPlayer == this ||
        ZP_Player_IsZombie(this) ||
        UTIL_IsPlayerSpectator(this) ||
        is_user_bot(this) ||
        ZP_GameRules_IsCompetitive()
    );

    @Player_SendPlayerScoreInfo(this, pPlayer, iTargetScore, bShowTeam ? iTargetDeaths : 0, iTargetClassId, bShowTeam ? iTargetTeam : iTeam);
}

@Player_SendPlayerScoreInfo(this, pPlayer, iScore, iDeaths, iClassId, iTeam) {
    emessage_begin(MSG_ONE, gmsgScoreInfo, _, this);
    ewrite_byte(pPlayer);
    ewrite_short(iScore);
    ewrite_short(iDeaths);
    ewrite_short(iClassId);
    ewrite_short(iTeam);
    emessage_end();
}
