#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fun>
#include <reapi>

#include <api_rounds>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Gamerules"
#define AUTHOR "Hedgehog Fog"

#define CHOOSE_TEAM_VGUI_MENU_ID 2
#define CHOOSE_TEAM1_CLASS_VGUI_MENU_ID 26
#define CHOOSE_TEAM2_CLASS_VGUI_MENU_ID 27

new g_iMaxPlayers;
new bool:g_bObjectiveMode = false;

new g_bPlayerPreferZombies[MAX_PLAYERS + 1];

new g_fwPlayerJoined;
new g_fwResult;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    Round_HookCheckWinConditions("OnCheckWinConditions");
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", .Post = 0);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);

    register_clcmd("chooseteam", "OnPlayerChangeTeam");
    register_clcmd("jointeam", "OnPlayerChangeTeam");
    register_clcmd("joinclass", "OnPlayerChangeTeam");

    register_message(get_user_msgid("ShowMenu"), "OnMessage_ShowMenu");
    register_message(get_user_msgid("VGUIMenu"), "OnMessage_VGUIMenu");

    g_iMaxPlayers = get_maxplayers();
    g_fwPlayerJoined = CreateMultiForward("Zp_Fw_PlayerJoined", ET_IGNORE, FP_CELL);
}

public plugin_natives() {
    register_native("ZP_GameRules_DispatchWin", "Native_DispatchWin");
    register_native("ZP_GameRules_GetObjectiveMode", "Native_GetObjectiveMode");
    register_native("ZP_GameRules_SetObjectiveMode", "Native_SetObjectiveMode");
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

/*--------------------------------[ Forwards ]--------------------------------*/

public client_disconnected(pPlayer) {
    CheckWinConditions(pPlayer);
}

public Round_Fw_NewRound() {
    for (new pPlayer = 1; pPlayer <= MAX_PLAYERS; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        if (iTeam != ZP_HUMAN_TEAM && iTeam != ZP_ZOMBIE_TEAM) {
            continue;
        }

        g_bPlayerPreferZombies[pPlayer] = false;
        set_member(pPlayer, m_iTeam, ZP_HUMAN_TEAM);
    }

    return PLUGIN_CONTINUE;
}

/*--------------------------------[ Hooks ]--------------------------------*/

public OnMessage_ShowMenu(iMsgId, iDest, pPlayer) {
    static szBuffer[32];
    get_msg_arg_string(4, szBuffer, charsmax(szBuffer));

    if (equali(szBuffer, "#Team_Select", 12)) {
        set_task(0.1, "TaskJoin", pPlayer);
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
        set_task(0.1, "TaskJoin", pPlayer);
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
    return PLUGIN_HANDLED;
}

public OnClCmd_ChooseTeam(pPlayer) {
    return PLUGIN_HANDLED;
}

public OnPlayerSpawn(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    if (!Round_IsRoundStarted()) {
        OpenTeamMenu(pPlayer);
    } else {
        CheckWinConditions();
    }

    return HAM_HANDLED;
}

public OnPlayerKilled_Post(pPlayer) {
    CheckWinConditions();

    return HAM_HANDLED;
}

public OpenTeamMenu(pPlayer) {
    new iMenu = menu_create("What's your plan?", "TeamMenuHandler");
    menu_additem(iMenu, "I wanna shit my pants");
    menu_additem(iMenu, "Join Zombies");
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
    menu_display(pPlayer, iMenu, 0);
}

public OnCheckWinConditions() {
    return PLUGIN_HANDLED;
}

public Round_Fw_RoundStart() {
    DistributeTeams();

    log_amx("New round started");
}

public Round_Fw_RoundExpired() {
    if (!g_bObjectiveMode) {
        DispatchWin(ZP_HUMAN_TEAM);

        log_amx("Round expired, survivors win!");
    }
}

DistributeTeams() {
    new pPlayerCount = CalculatePlayerCount();
    new iZombieCount = ProcessZombiePlayers(pPlayerCount / 2);

    if (iZombieCount) {
        log_amx("Respawned %d zombies", iZombieCount);
    }

    if (!iZombieCount) {
        if (pPlayerCount > 1) {
            log_amx("No one has chosen play zombie, a random player will be moved to the zombie team...");
            ChooseRandomZombie();
        } else {
            log_amx("Not enough players to start");
        }
    }
}

ProcessZombiePlayers(iMaxZombies) {
    new iZombieCount = 0;

    for (new pPlayer = 1; pPlayer <= g_iMaxPlayers; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        if (iTeam != ZP_ZOMBIE_TEAM && iTeam != ZP_HUMAN_TEAM) {
            continue;
        }

        if (is_user_alive(pPlayer) && !g_bPlayerPreferZombies[pPlayer]) {
            continue;
        }

        if (iZombieCount < iMaxZombies || !is_user_alive(pPlayer)) {
            if (g_bPlayerPreferZombies[pPlayer]) {
                log_amx("Player ^"%n^" has chosen a zombie team", pPlayer);
            }

            RespawnPlayerAsZombie(pPlayer);
            iZombieCount++;
        }
    }

    return iZombieCount;
}

ChooseRandomZombie() {
    static rgpPlayers[MAX_PLAYERS + 1];
    new pPlayerCount = 0;

    for (new pPlayer = 1; pPlayer <= g_iMaxPlayers; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        if (iTeam != ZP_ZOMBIE_TEAM && iTeam != ZP_HUMAN_TEAM) {
            continue;
        }

        if (ZP_Player_IsZombie(pPlayer)) {
            continue;
        }

        rgpPlayers[pPlayerCount] = pPlayer;
        pPlayerCount++;
    }

    new pPlayer = rgpPlayers[random(pPlayerCount)];
    RespawnPlayerAsZombie(pPlayer);
}

RespawnPlayerAsZombie(pPlayer) {
    strip_user_weapons(pPlayer);
    set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
    ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);

    log_amx("Player ^"%n^" was moved to the zombie team", pPlayer);
}

CalculatePlayerCount() {
    new pPlayerCount = 0;

    for (new pPlayer = 1; pPlayer <= g_iMaxPlayers; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        if (iTeam != ZP_ZOMBIE_TEAM && iTeam != ZP_HUMAN_TEAM) {
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

    for (new pPlayer = 1; pPlayer <= g_iMaxPlayers; ++pPlayer) {
        if (pPlayer == pIgnorePlayer) {
            continue;
        }

        if (!is_user_connected(pPlayer)) {
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
    }

    if (Round_IsRoundStarted()) {
        if (!iAliveHumanCount) {
            DispatchWin(ZP_ZOMBIE_TEAM);
        } else if (!iZombieCount || (!iAliveZombieCount && !ZP_GameRules_GetZombieLives())) {
            DispatchWin(ZP_HUMAN_TEAM);
        }
    }
}

DispatchWin(iTeam) {
    Round_DispatchWin(iTeam, ZP_NEW_ROUND_DELAY);
}

public TaskJoin(pPlayer) {
    set_member(pPlayer, m_bTeamChanged, get_member(pPlayer, m_bTeamChanged) & ~BIT(8));
    set_member(pPlayer, m_iTeam, 2);
    set_member(pPlayer, m_iJoiningState, 5);

    ExecuteForward(g_fwPlayerJoined, g_fwResult, pPlayer);
}

public TeamMenuHandler(pPlayer, iMenu, iItem) {
    if (iItem == 1) {
        if (Round_IsRoundStarted()) {
            if (!ZP_Player_IsZombie(pPlayer)) {
                ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
            }
        } else {
            g_bPlayerPreferZombies[pPlayer] = true;
        }
    }

    menu_destroy(iMenu);

    return PLUGIN_HANDLED;
}
