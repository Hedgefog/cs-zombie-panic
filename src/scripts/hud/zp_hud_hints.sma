#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>

#define PLUGIN "[Zombie Panic] Hints HUD"
#define AUTHOR "Hedgehog Fog"

#define MESSAGE_COLOR 0, 144, 255
#define MESSAGE_COLOR_WARN 255, 160, 0
#define MESSAGE_POS_HINT -1.0, 0.10
#define MESSAGE_POS_OBJECTIVE -1.0, 0.20
#define MESSAGE_POS_AMMO_WARN -1.0, 0.35
#define MESSAGE_AMMO_WARN_HOLD_TIME 0.75
#define MESSAGE_AMMO_WARN_FADEIN_TIME 0.5
#define MESSAGE_AMMO_WARN_FADEOUT_TIME 1.0
#define MESSAGE_POS_PICKUP -1.0, 0.65
#define MESSAGE_POS_RESPAWN -1.0, 0.40
#define MESSAGE_HOLD_TIME 5.0
#define MESSAGE_FADEIN_TIME 1.0
#define MESSAGE_FADEOUT_TIME 1.0
#define MESSAGE_OFFSET 0.03625

#define HINTS_KEY "zp_hints"

enum Message {
    Message_Color[3],
    Float:Message_Pos[2],
    Float:Message_HoldTime,
    Float:Message_FadeInTime,
    Float:Message_FadeOutTime
}

new bool:g_bShowObjectiveMessage[MAX_PLAYERS + 1] = { true, ... };
new bool:g_bPlayerShowSpeedWarning[MAX_PLAYERS + 1] = { true, ... };
new Float:g_flPlayerLastPickupHint[MAX_PLAYERS + 1] = { 0.0, ... };

new g_message[Message];

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

    if (!IsPlayerHintsEnabled(pPlayer)) {
        return HAM_IGNORED;
    }

    if (Round_IsRoundStarted()) {
        if (g_bShowObjectiveMessage[pPlayer]) {
            SetupMessage(MESSAGE_COLOR, MESSAGE_POS_OBJECTIVE, MESSAGE_HOLD_TIME, MESSAGE_FADEIN_TIME, MESSAGE_FADEOUT_TIME);

            if (ZP_GameRules_GetObjectiveMode()) {
                ShowMessageTitle(pPlayer, "%L", pPlayer, "ZPO_GAMEMODE_TITLE");

                if (ZP_Player_IsZombie(pPlayer)) {
                    ShowMessage(pPlayer, "%L", pPlayer, "ZPO_ZOMBIE_OBJECTIVE");
                } else {
                    ShowMessage(pPlayer, "%L", pPlayer, "ZPO_HUMAN_OBJECTIVE");
                }
            } else {
                ShowMessageTitle(pPlayer, "%L", pPlayer, "ZP_GAMEMODE_TITLE");

                if (ZP_Player_IsZombie(pPlayer)) {
                    ShowMessage(pPlayer, "%L", pPlayer, "ZP_ZOMBIE_OBJECTIVE");
                } else {
                    ShowMessage(pPlayer, "%L", pPlayer, "ZP_HUMAN_OBJECTIVE");
                }
            }

            g_bShowObjectiveMessage[pPlayer] = false;
        }
    } else {
        SetupMessage(MESSAGE_COLOR, MESSAGE_POS_HINT, MESSAGE_HOLD_TIME, MESSAGE_FADEIN_TIME, MESSAGE_FADEOUT_TIME);
        ShowMessageTitle(pPlayer, "%L", pPlayer, "ZP_HINT_TITLE");

        switch (random(2)) {
            case 0: {
                ShowMessage(pPlayer, "%L", pPlayer, "ZP_PANIC_HINT");
            }
            case 1: {
                ShowMessage(pPlayer, "%L", pPlayer, "ZP_DROP_AMMO_HINT");
            }
            case 2: {
                ShowMessage(pPlayer, "%L", pPlayer, "ZP_PICKUP_HINT");
            }
        }
    }

    return HAM_IGNORED;
}

public OnPlayerKilled_Post(pPlayer) {
    if (!get_pcvar_num(g_pCvarEnabled)) {
        return HAM_IGNORED;
    }

    if (!IsPlayerHintsEnabled(pPlayer)) {
        return HAM_IGNORED;
    }

    SetupMessage(MESSAGE_COLOR, MESSAGE_POS_RESPAWN, MESSAGE_HOLD_TIME, MESSAGE_FADEIN_TIME, MESSAGE_FADEOUT_TIME);
    ShowMessageTitle(pPlayer, "%L", pPlayer, "ZP_RESPAWN_TITLE");

    if (ZP_Player_IsZombie(pPlayer)) {
        if (ZP_GameRules_GetZombieLives() > 0) {
            ShowMessage(pPlayer, "%L", pPlayer, "ZP_ZOMBIE_RESPAWN");
        } else {
            ShowMessage(pPlayer, "%L", pPlayer, "ZP_ZOMBIE_NO_LIVES");
        }
    } else {
        ShowMessage(pPlayer, "%L", pPlayer, "ZP_HUMAN_RESPAWN");
    }

    return HAM_IGNORED;
}

public Round_Fw_NewRound() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        g_bShowObjectiveMessage[pPlayer] = true;
        g_bPlayerShowSpeedWarning[pPlayer] = true;
        g_flPlayerLastPickupHint[pPlayer] = 0.0;
    }
}

public OnItemPickup(pPlayer) {
    if (!get_pcvar_num(g_pCvarEnabled)) {
        return PLUGIN_CONTINUE;
    }

    if (!IsPlayerHintsEnabled(pPlayer)) {
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
        SetupMessage(MESSAGE_COLOR_WARN, MESSAGE_POS_AMMO_WARN, MESSAGE_HOLD_TIME, MESSAGE_FADEIN_TIME, MESSAGE_FADEOUT_TIME);
        ShowMessageTitle(pPlayer, "%L", pPlayer, "ZP_WARN_TITLE");
        ShowMessage(pPlayer, "%L", pPlayer, "ZP_SPEED_WARN");
        g_bPlayerShowSpeedWarning[pPlayer] = false;
    }

    return PLUGIN_CONTINUE;
}

public ZP_Fw_Player_AimItem(pPlayer) {
    if (!get_pcvar_num(g_pCvarEnabled)) {
        return;
    }

    if (!IsPlayerHintsEnabled(pPlayer)) {
        return;
    }

    if (get_gametime() - g_flPlayerLastPickupHint[pPlayer] < 1.0) {
        return;
    }

    SetupMessage(MESSAGE_COLOR_WARN, MESSAGE_POS_PICKUP, MESSAGE_AMMO_WARN_HOLD_TIME, MESSAGE_AMMO_WARN_FADEIN_TIME, MESSAGE_AMMO_WARN_FADEOUT_TIME);
    ShowMessageTitle(pPlayer, "%L", pPlayer, "ZP_ITEM_PICKUP_TITLE");
    ShowMessage(pPlayer, "%L", pPlayer, "ZP_ITEM_PICKUP");

    g_flPlayerLastPickupHint[pPlayer] = get_gametime();
}

SetupMessage(r, g, b, Float:x, Float:y, Float:holdTime, Float:fadeInTime, Float:fadeOutTime) {
    g_message[Message_Color][0] = r;
    g_message[Message_Color][1] = g;
    g_message[Message_Color][2] = b;

    g_message[Message_Pos][0] = x;
    g_message[Message_Pos][1] = y;

    g_message[Message_HoldTime] = holdTime;
    g_message[Message_FadeInTime] = fadeInTime;
    g_message[Message_FadeOutTime] = fadeOutTime;
}

ShowMessageTitle(pPlayer,const szText[], any:...) {
    static szBuffer[256];
    vformat(szBuffer, charsmax(szBuffer), szText, 3);
    set_dhudmessage(
        g_message[Message_Color][0],
        g_message[Message_Color][1],
        g_message[Message_Color][2],
        g_message[Message_Pos][0],
        g_message[Message_Pos][1],
        0,
        0.0,
        g_message[Message_HoldTime],
        g_message[Message_FadeInTime],
        g_message[Message_FadeOutTime]
    );
    show_dhudmessage(pPlayer, szBuffer);
}

ShowMessage(pPlayer, const szText[], any:...) {
    static szBuffer[256];
    vformat(szBuffer, charsmax(szBuffer), szText, 3);
    set_dhudmessage(
        255,
        255,
        255,
        g_message[Message_Pos][0],
        g_message[Message_Pos][1] + MESSAGE_OFFSET,
        0,
        0.0,
        g_message[Message_HoldTime],
        g_message[Message_FadeInTime],
        g_message[Message_FadeOutTime]
    );
    show_hudmessage(pPlayer, szBuffer);
}

IsPlayerHintsEnabled(pPlayer) {
    static szValue[2];
    get_user_info(pPlayer, HINTS_KEY, szValue, charsmax(szValue));

    return szValue[0] != '0';
}
