#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>

#define PLUGIN "[Zombie Panic] Hints HUD"
#define AUTHOR "Hedgehog Fog"

enum MessageType {
    MessageType_Info,
    MessageType_Important,
    MessageType_Warn
}

#define TASKID_RESPAWN_MESSAGE 100

#define HUD_CHAR_WIDTH 0.02083  // 16.0 / 768.0
#define DHUD_CHAR_WIDTH 0.03125  // 24.0 / 768.0

#define MESSAGE_HINT_POS -1.0, 0.10
#define MESSAGE_HINT_HOLD_TIME 5.0
#define MESSAGE_HINT_FADEIN_TIME 1.0
#define MESSAGE_HINT_FADEOUT_TIME 1.0

#define MESSAGE_OBJECTIVE_POS -1.0, 0.20
#define MESSAGE_OBJECTIVE_HOLD_TIME 5.0
#define MESSAGE_OBJECTIVE_FADEIN_TIME 1.0
#define MESSAGE_OBJECTIVE_FADEOUT_TIME 1.0

#define MESSAGE_SPEED_WARN_POS -1.0, 0.10
#define MESSAGE_SPEED_HOLD_TIME 5.0
#define MESSAGE_SPEED_FADEIN_TIME 1.0
#define MESSAGE_SPEED_FADEOUT_TIME 1.0

#define MESSAGE_RESPAWN_POS -1.0, -1.0
#define MESSAGE_RESPAWNHOLD_TIME 5.0
#define MESSAGE_RESPAWNFADEIN_TIME 1.0
#define MESSAGE_RESPAWNFADEOUT_TIME 1.0

#define MESSAGE_PICKUP_POS -1.0, 0.65
#define MESSAGE_PICKUP_HOLD_TIME 0.75
#define MESSAGE_PICKUP_FADEIN_TIME 0.5
#define MESSAGE_PICKUP_FADEOUT_TIME 1.0

#define MESSAGE_INFECTION_POS -1.0, 0.30
#define MESSAGE_INFECTION_HOLD_TIME 1.0
#define MESSAGE_INFECTION_FADEIN_TIME 1.0
#define MESSAGE_INFECTION_FADEOUT_TIME 1.0

#define HINTS_KEY "zp_hints"

enum Message {
    Message_Title[64],
    Message_Text[256]
}

new g_rgMessageColors[MessageType][3] = {
    { 117, 255, 127 },
    { 0, 255, 255 },
    { 255, 160, 0 }
};

new g_message[Message];

new bool:g_bShowObjectiveMessage[MAX_PLAYERS + 1] = { true, ... };
new bool:g_bPlayerShowSpeedWarning[MAX_PLAYERS + 1] = { true, ... };
new Float:g_flPlayerLastPickupHint[MAX_PLAYERS + 1] = { 0.0, ... };

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
            if (ZP_GameRules_GetObjectiveMode()) {
                SetMessageTitle("%L", pPlayer, "ZPO_OBJECTIVE_TITLE");

                if (ZP_Player_IsZombie(pPlayer)) {
                    SetMessageText("%L", pPlayer, "ZPO_OBJECTIVE_ZOMBIE");
                } else {
                    SetMessageText("%L", pPlayer, "ZPO_OBJECTIVE_HUMAN");
                }
            } else {
                SetMessageTitle("%L", pPlayer, "ZP_OBJECTIVE_TITLE");

                if (ZP_Player_IsZombie(pPlayer)) {
                    SetMessageText("%L", pPlayer, "ZP_OBJECTIVE_ZOMBIE");
                } else {
                    SetMessageText("%L", pPlayer, "ZP_OBJECTIVE_HUMAN");
                }
            }

            g_bShowObjectiveMessage[pPlayer] = false;

            ShowMessage(
                pPlayer,
                MessageType_Important,
                MESSAGE_OBJECTIVE_POS,
                MESSAGE_OBJECTIVE_HOLD_TIME,
                MESSAGE_OBJECTIVE_FADEIN_TIME,
                MESSAGE_OBJECTIVE_FADEOUT_TIME
            );
        }
    } else {
        SetMessageTitle("%L", pPlayer, "ZP_HINT_TITLE");

        switch (random(1)) {
            case 0: {
                SetMessageText("%L", pPlayer, "ZP_HINT_PANIC");
            }
            case 1: {
                SetMessageText("%L", pPlayer, "ZP_HINT_DROP_AMMO");
            }
            case 2: {
                SetMessageText("%L", pPlayer, "ZP_HINT_PICKUP");
            }
        }

        ShowMessage(
            pPlayer,
            MessageType_Info,
            MESSAGE_HINT_POS,
            MESSAGE_HINT_HOLD_TIME,
            MESSAGE_HINT_FADEIN_TIME,
            MESSAGE_HINT_FADEOUT_TIME
        );
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

    if (Round_IsRoundEnd()) {
        return HAM_IGNORED;
    }

    set_task(1.0, "Task_RespawnMessage", TASKID_RESPAWN_MESSAGE + pPlayer);

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

    if (ZP_Player_IsZombie(pPlayer)) {
        return PLUGIN_CONTINUE;
    }

    new Float:flMaxSpeed;
    pev(pPlayer, pev_maxspeed, flMaxSpeed);

    if (flMaxSpeed < ZP_ZOMBIE_SPEED) {
        SetMessageTitle("%L", pPlayer, "ZP_WARN_TITLE");
        SetMessageText("%L", pPlayer, "ZP_WARN_SPEED");
        ShowMessage(
            pPlayer,
            MessageType_Warn,
            MESSAGE_SPEED_WARN_POS,
            MESSAGE_SPEED_HOLD_TIME,
            MESSAGE_SPEED_FADEIN_TIME,
            MESSAGE_SPEED_FADEOUT_TIME
        );

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

    SetMessageTitle("%L", pPlayer, "ZP_ITEM_PICKUP_TITLE");
    SetMessageText("%L", pPlayer, "ZP_ITEM_PICKUP");

    ShowMessage(
        pPlayer,
        MessageType_Warn,
        MESSAGE_PICKUP_POS,
        MESSAGE_PICKUP_HOLD_TIME,
        MESSAGE_PICKUP_FADEIN_TIME,
        MESSAGE_PICKUP_FADEOUT_TIME
    );

    g_flPlayerLastPickupHint[pPlayer] = get_gametime();
}

public ZP_Fw_PlayerInfected(pPlayer, pInfector) {
    if (!pInfector) {
        return;
    }

    SetMessageTitle("%L", pInfector, "ZP_WARN_INFECTION_TITLE");
    SetMessageText("%L ^"%n^"", pInfector, "ZP_WARN_INFECTOR", pPlayer);

    ShowMessage(
        pInfector,
        MessageType_Warn,
        MESSAGE_INFECTION_POS,
        MESSAGE_INFECTION_HOLD_TIME,
        MESSAGE_INFECTION_FADEIN_TIME,
        MESSAGE_INFECTION_FADEOUT_TIME
    );
}

SetMessageTitle(const szTitle[], any:...) {
    static szBuffer[64];
    vformat(szBuffer, charsmax(szBuffer), szTitle, 2);

    copy(g_message[Message_Title], charsmax(g_message[Message_Title]), szBuffer);
}

SetMessageText(const szText[], any:...) {
    static szBuffer[256];
    vformat(szBuffer, charsmax(szBuffer), szText, 2);

    copy(g_message[Message_Text], charsmax(g_message[Message_Text]), szBuffer);
}

ShowMessage(pPlayer, MessageType:iType, Float:flPosX = -1.0, Float:flPosY = -1.0, Float:holdTime = 5.0, Float:fadeInTime = 1.0, Float:fadeOutTime = 1.0) {
    new Float:flTitlePosY = flPosY;
    if (flTitlePosY == -1.0) {
        new Float:flTextWidth = HUD_CHAR_WIDTH * UTIL_CalculateHUDLines(g_message[Message_Text]);
        flTitlePosY = 0.5 - DHUD_CHAR_WIDTH - (flTextWidth / 2);
    } else {
        flTitlePosY -= DHUD_CHAR_WIDTH;
    }

    set_dhudmessage(
        g_rgMessageColors[iType][0],
        g_rgMessageColors[iType][1],
        g_rgMessageColors[iType][2],
        flPosX,
        flTitlePosY,
        0,
        0.0,
        holdTime,
        fadeInTime,
        fadeOutTime
    );

    show_dhudmessage(pPlayer, g_message[Message_Title]);

    set_hudmessage(
        255,
        255,
        255,
        flPosX,
        flPosY,
        0,
        0.0,
        holdTime,
        fadeInTime,
        fadeOutTime,
        -1
    );

    show_hudmessage(pPlayer, g_message[Message_Text]);
}

IsPlayerHintsEnabled(pPlayer) {
    static szValue[2];
    get_user_info(pPlayer, HINTS_KEY, szValue, charsmax(szValue));

    return szValue[0] != '0';
}

public Task_RespawnMessage(iTaskId) {
    new pPlayer = iTaskId - TASKID_RESPAWN_MESSAGE;

    if (is_user_alive(pPlayer)) {
        return;
    }

    SetMessageTitle("%L", pPlayer, "ZP_RESPAWN_TITLE");

    if (ZP_Player_IsZombie(pPlayer)) {
        if (ZP_GameRules_GetZombieLives() > 0) {
            SetMessageText("%L", pPlayer, "ZP_RESPAWN_ZOMBIE");
        } else {
            SetMessageText("%L", pPlayer, "ZP_RESPAWN_NOLIVES");
        }
    } else {
        SetMessageText("%L", pPlayer, "ZP_RESPAWN_HUMAN");
    }

    ShowMessage(
        pPlayer,
        MessageType_Info,
        MESSAGE_RESPAWN_POS,
        MESSAGE_RESPAWNHOLD_TIME,
        MESSAGE_RESPAWNFADEIN_TIME,
        MESSAGE_RESPAWNFADEOUT_TIME
    );
}

stock UTIL_CalculateHUDLines(const szText[]) {
    new iLineCount = 1;
    new iLineLength = 0;

    for (new i = 0; i < 256; ++i) {
        if (szText[i] == '^0') {
            break;
        }

        iLineLength++;

        if (szText[i] == '^n' || iLineLength > 68) {
            iLineCount++;
            iLineLength = 0;
        }
    }

    return iLineCount;
}
