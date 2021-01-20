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
  if (ZP_Player_IsZombie(pPlayer) || is_user_bot(pPlayer)) {
    Reset(pPlayer);
  }
}

public OnMessage(iMsgId, iDest, pPlayer) {
  return pPlayer ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public OnEvent(pPlayer) {
  new pTargetPlayer = read_data(1);
  new iScore = read_data(2);
  new iDeaths = read_data(3);
  new iClassId = read_data(4);
  new iTeam = read_data(5);

  for (new pPlayer = 1; pPlayer <= MAX_PLAYERS; ++pPlayer) {
    if (!is_user_connected(pPlayer)) {
      continue;
    }

    new bool:bIsHuman = !ZP_Player_IsZombie(pPlayer);
    new _iDeaths = !bIsHuman || pTargetPlayer == pPlayer ? iDeaths : 0;
    new _iTeam = !bIsHuman || is_user_bot(pPlayer) ? iTeam : get_member(pPlayer, m_iTeam);
    SendMessage(pPlayer, pTargetPlayer, iScore, _iDeaths, iClassId, _iTeam);
  }

  return PLUGIN_HANDLED;
}

Reset(pPlayer) {
  for (new pTargetPlayer = 1; pTargetPlayer <= MAX_PLAYERS; ++pTargetPlayer) {
    if (!is_user_connected(pTargetPlayer)) {
      continue;
    }

    new iScore = get_user_frags(pTargetPlayer);
    new iDeaths = get_user_deaths(pTargetPlayer);
    new iClassId = 0;
    new iTeam = get_member(pTargetPlayer, m_iTeam);

    SendMessage(pPlayer, pTargetPlayer, iScore, iDeaths, iClassId, iTeam);
  }
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
