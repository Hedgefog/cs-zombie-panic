#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <reapi>
#include <xs>

#include <api_rounds>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Gamerules"
#define AUTHOR "Hedgehog Fog"

#define CHOOSE_TEAM_VGUI_MENU_ID 2
#define CHOOSE_TEAM1_CLASS_VGUI_MENU_ID 26
#define CHOOSE_TEAM2_CLASS_VGUI_MENU_ID 27
#define PLAYERS_PER_ZOMBIE 6

enum TeamPreference {
    TeamPreference_Human,
    TeamPreference_Zombie,
    TeamPreference_Spectator
}

new g_pCvarLives;
new g_pCvarLivesPerPlayer;
new g_pCvarCompetitive;

new g_pFwPlayerJoined;
new g_pFwNewRound;
new g_pFwRoundStarted;
new g_pFwRoundEnd;
new g_iFwResult;

new g_iTeamMenu;
new bool:g_bObjectiveMode = false;
new TeamPreference:g_iPlayerTeamPreference[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    Round_HookCheckWinConditions("OnCheckWinConditions");

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", .Post = 0);
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);
    RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage", .Post = 0);

    register_forward(FM_ClientKill, "OnClientKill");

    register_message(get_user_msgid("ShowMenu"), "OnMessage_ShowMenu");
    register_message(get_user_msgid("VGUIMenu"), "OnMessage_VGUIMenu");

    register_clcmd("chooseteam", "OnPlayerChangeTeam");
    register_clcmd("jointeam", "OnPlayerChangeTeam");
    register_clcmd("joinclass", "OnPlayerChangeTeam");
    register_clcmd("drop", "OnClCmd_Drop");

    g_pCvarLives = register_cvar("zp_zombie_lives", "0");
    g_pCvarLivesPerPlayer = register_cvar("zp_zombie_lives_per_player", "2");
    g_pCvarCompetitive = register_cvar("zp_competitive", "0");

    g_pFwPlayerJoined = CreateMultiForward("ZP_Fw_PlayerJoined", ET_IGNORE, FP_CELL);
    g_pFwNewRound = CreateMultiForward("ZP_Fw_NewRound", ET_IGNORE);
    g_pFwRoundStarted = CreateMultiForward("ZP_Fw_RoundStarted", ET_IGNORE);
    g_pFwRoundEnd = CreateMultiForward("ZP_Fw_RoundEnd", ET_IGNORE, FP_CELL);

    g_iTeamMenu = CreateTeamMenu();
}

public plugin_natives() {
    register_native("ZP_GameRules_DispatchWin", "Native_DispatchWin");
    register_native("ZP_GameRules_GetObjectiveMode", "Native_GetObjectiveMode");
    register_native("ZP_GameRules_SetObjectiveMode", "Native_SetObjectiveMode");
    register_native("ZP_GameRules_CanItemRespawn", "Native_CanItemRespawn");
    register_native("ZP_GameRules_IsCompetitive", "Native_IsCompetitive");
}

/*--------------------------------[ Natives ]--------------------------------*/

public Native_DispatchWin(iPluginId, iArgc) {
    new iTeam = get_param(1);
    DispatchWin(iTeam);
}

public Native_SetObjectiveMode(iPluginId, iArgc) {
    g_bObjectiveMode = bool:get_param(1);
}

public bool:Native_GetObjectiveMode(iPluginId, iArgc) {
    return g_bObjectiveMode;
}

public bool:Native_IsCompetitive(iPluginId, iArgc) {
    return !!get_pcvar_num(g_pCvarCompetitive);
}

public bool:Native_CanItemRespawn(iPluginId, iArgc) {
    new pItem = get_param(1);

    if (get_gametime() - Float:get_member_game(m_fRoundStartTime) <= 1.0) {
        return true;
    }

    new Float:vecOrigin[3];
    pev(pItem, pev_origin, vecOrigin);

    new pTr = create_tr2();

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (!is_user_alive(pPlayer)) {
            continue;
        }

        if (is_user_bot(pPlayer)) {
            continue;
        }

        new Float:flMinRange = ZP_Player_IsZombie(pPlayer) ? 256.0 :  512.0;

        static Float:vecPlayerOrigin[3];
        pev(pPlayer, pev_origin, vecPlayerOrigin);

        engfunc(EngFunc_TraceLine, vecOrigin, vecPlayerOrigin, IGNORE_MONSTERS | IGNORE_GLASS, pPlayer, pTr);
        static Float:flFraction;
        get_tr2(pTr, TR_flFraction, flFraction);

        if (flFraction < 1.0) {
            flMinRange /= 2;
        }

        if (xs_vec_distance(vecOrigin, vecPlayerOrigin) <= flMinRange) {
            return false;
        }
    }

    free_tr2(pTr);

    return true;
}

/*--------------------------------[ Forwards ]--------------------------------*/

public client_disconnected(pPlayer) {
    CheckWinConditions(pPlayer);
}

public Round_Fw_NewRound() {
    ResetPlayerTeamPreferences();
    ShuffleTeams();

    ExecuteForward(g_pFwNewRound, g_iFwResult);

    return PLUGIN_CONTINUE;
}

public Round_Fw_RoundStart() {
    DistributeTeams();

    new iHumanCount = CalculatePlayerCount(ZP_HUMAN_TEAM);
    new iLives = ZP_GameRules_GetObjectiveMode()
        ? 255
        : get_pcvar_num(g_pCvarLives) + (iHumanCount * get_pcvar_num(g_pCvarLivesPerPlayer));

    ZP_GameRules_SetZombieLives(iLives);

    RespawnPlayers();
    CheckWinConditions();
    
    log_amx("New round started");

    ExecuteForward(g_pFwRoundStarted, g_iFwResult);
}

public Round_Fw_RoundExpired() {
    if (!g_bObjectiveMode) {
        DispatchWin(ZP_HUMAN_TEAM);
        log_amx("Round expired, survivors win!");
    }
}

/*--------------------------------[ Hooks ]--------------------------------*/

public OnMessage_ShowMenu(iMsgId, iDest, pPlayer) {
    static szBuffer[32];
    get_msg_arg_string(4, szBuffer, charsmax(szBuffer));

    if (equali(szBuffer, "#Team_Select", 12)) {
        set_task(0.1, "Task_Join", pPlayer);
        return PLUGIN_HANDLED;
    }

    get_msg_arg_string(4, szBuffer, charsmax(szBuffer));
    if (equali(szBuffer, "#Terrorist_Select", 17) || equali(szBuffer, "#CT_Select", 10)) {
        return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}

public OnMessage_VGUIMenu(iMsgId, iDest, pPlayer) {
    new iMenuId = get_msg_arg_int(1);

    if (iMenuId == CHOOSE_TEAM_VGUI_MENU_ID) {
        set_task(0.1, "Task_Join", pPlayer);
        return PLUGIN_HANDLED;
    }

    if (iMenuId == CHOOSE_TEAM1_CLASS_VGUI_MENU_ID) {
        return PLUGIN_HANDLED;
    }

    if (iMenuId == CHOOSE_TEAM2_CLASS_VGUI_MENU_ID) {
        return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}


public OnPlayerChangeTeam(pPlayer, iKey) {
    if (get_member(pPlayer, m_iTeam) == 3) {
        OpenTeamMenu(pPlayer);
    }

    return PLUGIN_HANDLED;
}

public OnClCmd_Drop(pPlayer) {
    return get_member_game(m_bFreezePeriod) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public OnClientKill(pPlayer) {
    return get_member_game(m_bFreezePeriod) ? FMRES_SUPERCEDE : FMRES_IGNORED;
}

public OnPlayerSpawn(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    return HAM_HANDLED;
}

public OnPlayerSpawn_Post(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    if (!Round_IsRoundStarted()) {
        set_member(pPlayer, m_iTeam, ZP_HUMAN_TEAM);
        set_pev(pPlayer, pev_takedamage, DAMAGE_NO);
        OpenTeamMenu(pPlayer);
        ZP_ShowMapInfo(pPlayer);
        // ZP_Player_UpdateSpeed(pPlayer);
    } else {
        CheckWinConditions();
    }

    return HAM_HANDLED;
}

public OnPlayerKilled_Post(pPlayer) {
    CheckWinConditions();

    return HAM_HANDLED;
}

public OnPlayerTakeDamage(pPlayer) {
    return Round_IsRoundEnd() ? HAM_SUPERCEDE : HAM_IGNORED;
}

public OnCheckWinConditions() {
    return PLUGIN_HANDLED;
}

/*--------------------------------[ Methods ]--------------------------------*/

DistributeTeams() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer) || is_user_hltv(pPlayer)) {
            continue;
        }

        if (g_iPlayerTeamPreference[pPlayer] != TeamPreference_Spectator) {
            set_member(pPlayer, m_iTeam, ZP_HUMAN_TEAM);
        }
    }

    new pPlayerCount = CalculatePlayerCount();
    new iZombieCount = ProcessZombiePlayers(pPlayerCount / 2);

    if (iZombieCount) {
        log_amx("Respawned %d zombies", iZombieCount);
    }

    new iPlayersPerZombie = get_pcvar_num(g_pCvarCompetitive) ? 2 : PLAYERS_PER_ZOMBIE;
    new iRequiredZombieCount = floatround(float(pPlayerCount) / iPlayersPerZombie, floatround_ceil);
    if (iZombieCount < iRequiredZombieCount) {
        if (pPlayerCount > 1) {
            log_amx("Not enough zombies, a random players will be moved to the zombie team...");
            
            new iCount = iRequiredZombieCount - iZombieCount;
            for (new i = 0; i < iCount; ++i) {
                ChooseRandomZombie();
            }
        } else {
            log_amx("Not enough players to start");
        }
    }

}

ProcessZombiePlayers(iMaxZombies) {
    new iZombieCount = 0;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (UTIL_IsPlayerSpectator(pPlayer)) {
            continue;
        }

        if (g_iPlayerTeamPreference[pPlayer] != TeamPreference_Zombie) {
            continue;
        }

        if (iMaxZombies && iZombieCount >= iMaxZombies) {
            break;
        }

        log_amx("Player ^"%n^" has chosen a zombie team", pPlayer);
        set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
        iZombieCount++;
    }

    return iZombieCount;
}

ChooseRandomZombie() {
    static rgpPlayers[MAX_PLAYERS + 1];
    new pPlayerCount = 0;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (UTIL_IsPlayerSpectator(pPlayer)) {
            continue;
        }

        if (ZP_Player_IsZombie(pPlayer)) {
            continue;
        }

        rgpPlayers[pPlayerCount] = pPlayer;
        pPlayerCount++;
    }

    new pPlayer = rgpPlayers[random(pPlayerCount)];
    set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
    log_amx("Player ^"%n^" was randomly moved to the zombie team", pPlayer);
}

CalculatePlayerCount(iTeam = -1) {
    new pPlayerCount = 0;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (UTIL_IsPlayerSpectator(pPlayer)) {
            continue;
        }

        if (iTeam != -1 && iTeam != get_member(pPlayer, m_iTeam)) {
            continue;
        }

        pPlayerCount++;
    }

    return pPlayerCount;
}

CheckWinConditions(pIgnorePlayer = 0) {
    new iAliveHumanCount = 0;
    new iAliveZombieCount = 0;
    new iZombieCount = 0;
    new iPlayerCount = 0;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (pPlayer == pIgnorePlayer) {
            continue;
        }

        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        if (iTeam != ZP_HUMAN_TEAM && iTeam != ZP_ZOMBIE_TEAM) {
            continue;
        }

        if (ZP_Player_IsZombie(pPlayer)) {
            iZombieCount++;

            if (is_user_alive(pPlayer)) {
                iAliveZombieCount++;
            }
        } else {
            if (is_user_alive(pPlayer)) {
                iAliveHumanCount++;
            }
        }

        iPlayerCount++;
    }

    if (iPlayerCount <= 1) {
        return;
    }

    if (Round_IsRoundStarted()) {
        if (!iAliveHumanCount) {
            DispatchWin(ZP_ZOMBIE_TEAM);
        } else if (!iZombieCount || (!iAliveZombieCount && !ZP_GameRules_GetZombieLives())) {
            DispatchWin(ZP_HUMAN_TEAM);
        }
    }
}

ShuffleTeams() {
    new Array:irgPlayers = ArrayCreate();

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (UTIL_IsPlayerSpectator(pPlayer)) {
            continue;
        }

        ArrayPushCell(irgPlayers, pPlayer);
    }

    new iPlayerCount = ArraySize(irgPlayers);
    for (new i = 0; i < iPlayerCount; ++i) {
        ArraySwap(irgPlayers, i, random(iPlayerCount));
    }

    for (new i = 0; i < iPlayerCount; ++i) {
        new pPlayer = ArrayGetCell(irgPlayers, i);
        new iTeam = i % 2 ? ZP_HUMAN_TEAM : ZP_ZOMBIE_TEAM;
        set_member(pPlayer, m_iTeam, iTeam);
    }

    ArrayDestroy(irgPlayers);
}

ResetPlayerTeamPreferences() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer) || is_user_hltv(pPlayer)) {
            continue;
        }

        g_iPlayerTeamPreference[pPlayer] = get_member(pPlayer, m_iTeam) == 3 ? TeamPreference_Spectator : TeamPreference_Human;
    }
}

RespawnPlayers() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (UTIL_IsPlayerSpectator(pPlayer)) {
            continue;
        }

        ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);
    }
}

DispatchWin(iTeam) {
    Round_DispatchWin(iTeam, ZP_NEW_ROUND_DELAY);
    ExecuteForward(g_pFwRoundEnd, g_iFwResult, iTeam);
}

/*--------------------------------[ Tasks ]--------------------------------*/

public Task_Join(pPlayer) {
    if (!is_user_connected(pPlayer) || is_user_hltv(pPlayer)) {
        return;
    }

    set_member(pPlayer, m_bTeamChanged, get_member(pPlayer, m_bTeamChanged) & ~BIT(8));
    set_member(pPlayer, m_iTeam, ZP_HUMAN_TEAM);
    set_member(pPlayer, m_iJoiningState, 5);

    ExecuteForward(g_pFwPlayerJoined, g_iFwResult, pPlayer);
}

/*--------------------------------[ Team Menu ]--------------------------------*/

CreateTeamMenu() {
    new iMenu = menu_create("What's your plan?", "TeamMenuHandler");
    menu_additem(iMenu, "I wanna shit my pants");
    menu_additem(iMenu, "Join Zombies");
    menu_addblank2(iMenu);
    menu_addblank2(iMenu);
    menu_addblank2(iMenu);
    menu_additem(iMenu, "Spectate");
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);

    return iMenu;
}

OpenTeamMenu(pPlayer) {
    menu_display(pPlayer, g_iTeamMenu, 0);
}

public TeamMenuHandler(pPlayer, iMenu, iItem) {
    switch (iItem) {
        case 0: {
            g_iPlayerTeamPreference[pPlayer] = TeamPreference_Human;

            if (get_member(pPlayer, m_iTeam) == 3) {
                set_member(pPlayer, m_iTeam, ZP_HUMAN_TEAM);
            }
        }
        case 1: {
            g_iPlayerTeamPreference[pPlayer] = TeamPreference_Zombie;

            if (get_member(pPlayer, m_iTeam) == 3) {
                set_member(pPlayer, m_iTeam, ZP_HUMAN_TEAM);
            }
        }
        case 5: {
            g_iPlayerTeamPreference[pPlayer] = TeamPreference_Spectator;
            set_member(pPlayer, m_iTeam, 3);

            if (is_user_alive(pPlayer)) {
                ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
            }
        }
    }

    if (Round_IsRoundStarted()) {
        switch (iItem) {
            case 0: {
                if (get_member(pPlayer, m_iTeam) == 3) {
                    ZP_GameRules_RespawnAsZombie(pPlayer);
                }
            }
            case 1: {
                if (!ZP_Player_IsZombie(pPlayer)) {
                    if (get_member(pPlayer, m_iTeam) == 3) {
                        ZP_GameRules_RespawnAsZombie(pPlayer);
                    } else {
                        ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
                    }
                }
            }
            case 5: {
                CheckWinConditions();
            }
        }
    }

    return PLUGIN_HANDLED;
}
