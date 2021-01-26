#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
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

new g_pCvarLives;

new g_fwPlayerJoined;
new g_fwResult;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    Round_HookCheckWinConditions("OnCheckWinConditions");
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", .Post = 0);
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);

    register_clcmd("chooseteam", "OnPlayerChangeTeam");
    register_clcmd("jointeam", "OnPlayerChangeTeam");
    register_clcmd("joinclass", "OnPlayerChangeTeam");
    register_clcmd("drop", "OnClCmd_Drop");

    register_message(get_user_msgid("ShowMenu"), "OnMessage_ShowMenu");
    register_message(get_user_msgid("VGUIMenu"), "OnMessage_VGUIMenu");

    g_iMaxPlayers = get_maxplayers();
    g_fwPlayerJoined = CreateMultiForward("Zp_Fw_PlayerJoined", ET_IGNORE, FP_CELL);

    g_pCvarLives = register_cvar("zp_zombie_lives", "20");
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
        if (iTeam != ZP_ZOMBIE_TEAM) {
            continue;
        }

        g_bPlayerPreferZombies[pPlayer] = false;
    }

    ShuffleTeams();

    return PLUGIN_CONTINUE;
}

public Round_Fw_RoundStart() {
    ZP_GameRules_SetZombieLives(ZP_GameRules_GetObjectiveMode() ? 255 : get_pcvar_num(g_pCvarLives));
    DistributeTeams();
    CheckWinConditions();
    log_amx("New round started");
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

public OnClCmd_Drop(pPlayer) {
    return get_member_game(m_bFreezePeriod) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public OnPlayerSpawn(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    if (!Round_IsRoundStarted()) {
        OpenTeamMenu(pPlayer);
    }

    return HAM_HANDLED;
}

public OnPlayerSpawn_Post(pPlayer) {
    if (!Round_IsRoundStarted()) {
        set_member(pPlayer, m_iTeam, ZP_HUMAN_TEAM);
        set_pev(pPlayer, pev_takedamage, DAMAGE_NO);
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

public OpenTeamMenu(pPlayer) {
    new pMenu = menu_create("What's your plan?", "TeamMenuHandler");
    menu_additem(pMenu, "I wanna shit my pants");
    menu_additem(pMenu, "Join Zombies");
    menu_setprop(pMenu, MPROP_EXIT, MEXIT_NEVER);
    menu_display(pPlayer, pMenu, 0);
}

public OnCheckWinConditions() {
    return PLUGIN_HANDLED;
}

/*--------------------------------[ Methods ]--------------------------------*/

DistributeTeams() {
    for (new pPlayer = 1; pPlayer <= MAX_PLAYERS; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        if (iTeam == ZP_ZOMBIE_TEAM) {
            set_member(pPlayer, m_iTeam, ZP_HUMAN_TEAM);
        }
    }

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
    
    for (new pPlayer = 1; pPlayer <= MAX_PLAYERS; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        if (iTeam != ZP_ZOMBIE_TEAM && iTeam != ZP_HUMAN_TEAM) {
            continue;
        }

        ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);
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

            MovePlayerToZombieTeam(pPlayer);
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
    MovePlayerToZombieTeam(pPlayer);
}

MovePlayerToZombieTeam(pPlayer) {
    set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
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

ShuffleTeams() {
    new Array:irgPlayers = ArrayCreate();

    for (new pPlayer = 1; pPlayer <= g_iMaxPlayers; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iTeam = get_member(pPlayer, m_iTeam);
        if (iTeam != ZP_ZOMBIE_TEAM && iTeam != ZP_HUMAN_TEAM) {
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

DispatchWin(iTeam) {
    Round_DispatchWin(iTeam, ZP_NEW_ROUND_DELAY);
}

/*--------------------------------[ Tasks ]--------------------------------*/

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
