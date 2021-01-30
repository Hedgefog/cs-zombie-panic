#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] ScoreInfo"
#define AUTHOR "Hedgehog Fog"

new gmsgScoreInfo;

public plugin_init()
{
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  gmsgScoreInfo = get_user_msgid("ScoreInfo");
  register_event("ScoreInfo", "OnEvent", "a");
  register_message(gmsgScoreInfo, "OnMessage");

  RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
}

public OnPlayerSpawn_Post(pPlayer) {
  for (new pTargetPlayer = 1; pTargetPlayer <= MaxClients; ++pTargetPlayer) {
    if (!is_user_connected(pTargetPlayer)) {
      continue;
    }

    Update(pPlayer, pTargetPlayer);
  }
}

public OnMessage(iMsgId, iDest, pPlayer) {
  return pPlayer ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public OnEvent(pPlayer) {
  new pTargetPlayer = read_data(1);

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) {
      continue;
    }

    Update(pPlayer, pTargetPlayer);
  }

  return PLUGIN_HANDLED;
}

Update(pPlayer, pTargetPlayer) {
    new iScore = get_user_frags(pTargetPlayer);
    new iDeaths = ZP_Player_IsZombie(pPlayer) || pTargetPlayer == pPlayer ? get_member(pTargetPlayer, m_iDeaths) : 0;
    new iClassId = 0;
    new iTeam = ZP_Player_IsZombie(pPlayer) || is_user_bot(pPlayer) ? get_member(pTargetPlayer, m_iTeam) : get_member(pPlayer, m_iTeam);

    SendMessage(pPlayer, pTargetPlayer, iScore, iDeaths, iClassId, iTeam);
}

SendMessage(pPlayer, pTargetPlayer, iScore, iDeaths, iClassId, iTeam) {
  emessage_begin(MSG_ONE, gmsgScoreInfo, _, pPlayer);
  ewrite_byte(pTargetPlayer);
  ewrite_short(iScore);
  ewrite_short(iDeaths);
  ewrite_short(iClassId);
  ewrite_short(iTeam);
  emessage_end();
}
