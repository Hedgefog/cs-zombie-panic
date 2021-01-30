#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>

#define PLUGIN "[Zombie Panic] Info HUD"
#define AUTHOR "Hedgehog Fog"

#define MESSAGE_COLOR 0, 72, 128
#define MESSAGE_TIME 5.0
#define MESSAGE_POS_INFO -1.0, 0.10
#define MESSAGE_POS_WARN -1.0, 0.75
#define MESSAGE_POS_AMMO_WARN MESSAGE_POS_WARN
#define MESSAGE_POS_HINT MESSAGE_POS_INFO
#define MESSAGE_POS_OBJECTIVE MESSAGE_POS_WARN
#define MESSAGE_POS_RESPAWN MESSAGE_POS_WARN
#define MESSAGE_FADEIN_TIME 1.0
#define MESSAGE_FADEOUT_TIME 1.0

new bool:g_bShowObjectiveMessage[MAX_PLAYERS + 1] = { true, ... };
new bool:g_bPlayerShowSpeedWarning[MAX_PLAYERS + 1] = { true, ... };

new g_pCvarEnabled;

public plugin_init() {
        register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
        register_dictionary("zombiepanic.txt");

        RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
        RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);

        register_event("AmmoPickup", "OnItemPickup", "be");
        register_event("WeapPickup", "OnItemPickup", "be");

        g_pCvarEnabled = register_cvar("zp_hints", "1");
}

public OnPlayerSpawn_Post(pPlayer) {
    if (!get_pcvar_num(g_pCvarEnabled)) {
        return HAM_IGNORED;
    }

    if (Round_IsRoundStarted()) {
        if (g_bShowObjectiveMessage[pPlayer]) {
            SetHudMessage(MESSAGE_POS_OBJECTIVE);

            if (ZP_Player_IsZombie(pPlayer)) {
                if (ZP_GameRules_GetObjectiveMode()) {
                    show_dhudmessage(pPlayer, "%L", pPlayer, "ZPO_ZOMBIE_OBJECTIVE");
                } else {
                    show_dhudmessage(pPlayer, "%L", pPlayer, "ZP_ZOMBIE_OBJECTIVE");
                }
            } else {
                if (ZP_GameRules_GetObjectiveMode()) {
                    show_dhudmessage(pPlayer, "%L", pPlayer, "ZPO_HUMAN_OBJECTIVE");
                } else {
                    show_dhudmessage(pPlayer, "%L", pPlayer, "ZP_HUMAN_OBJECTIVE");
                }
            }

            g_bShowObjectiveMessage[pPlayer] = false;
        }
    } else {
        SetHudMessage(MESSAGE_POS_HINT);

        switch (random(2)) {
            case 0: {
                show_dhudmessage(pPlayer, "%L", pPlayer, "ZP_PANIC_HINT");
            }
            case 1: {
                show_dhudmessage(pPlayer, "%L", pPlayer, "ZP_DROP_AMMO_HINT");
            }
            case 2: {
                show_dhudmessage(pPlayer, "%L", pPlayer, "ZP_PICKUP_HINT");
            }
        }
    }

    return HAM_IGNORED;
}

public OnPlayerKilled_Post(pPlayer) {
    if (!get_pcvar_num(g_pCvarEnabled)) {
        return HAM_IGNORED;
    }

    SetHudMessage(MESSAGE_POS_RESPAWN);

    if (ZP_Player_IsZombie(pPlayer)) {
        if (ZP_GameRules_GetZombieLives() > 0) {
            show_dhudmessage(pPlayer, "%L", pPlayer, "ZP_ZOMBIE_RESPAWN");
        } else {
            show_dhudmessage(pPlayer, "%L", pPlayer, "ZP_ZOMBIE_NO_LIVES");
        }
    } else {
        show_dhudmessage(pPlayer, "%L", pPlayer, "ZP_HUMAN_RESPAWN");
    }

    return HAM_IGNORED;
}

public Round_Fw_NewRound() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        g_bShowObjectiveMessage[pPlayer] = true;
        g_bPlayerShowSpeedWarning[pPlayer] = true;
    }
}

public OnItemPickup(pPlayer) {
    if (!get_pcvar_num(g_pCvarEnabled)) {
        return PLUGIN_CONTINUE;
    }

    if (!g_bPlayerShowSpeedWarning[pPlayer]) {
        return PLUGIN_CONTINUE;
    }

    if (get_member_game(m_bFreezePeriod)) {
        return PLUGIN_CONTINUE;
    }

    new Float:flMaxSpeed;
    pev(pPlayer, pev_maxspeed, flMaxSpeed);

    if (flMaxSpeed < ZP_ZOMBIE_SPEED) {
        SetHudMessage(MESSAGE_POS_AMMO_WARN);
        show_dhudmessage(pPlayer, "%L", pPlayer, "ZP_SPEED_WARN");
        g_bPlayerShowSpeedWarning[pPlayer] = false;
    }

    return PLUGIN_CONTINUE;
}

SetHudMessage(Float:flPosX, Float:flPosY) {
    set_dhudmessage(MESSAGE_COLOR, flPosX, flPosY, 0, 0.0, MESSAGE_TIME, MESSAGE_FADEIN_TIME, MESSAGE_FADEOUT_TIME);
}
