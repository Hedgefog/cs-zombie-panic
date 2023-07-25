
#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <api_rounds>
#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] trigger_endround"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "trigger_endround"
#define MEMBER_PLAYER_FLAGS "playerflags"
#define SF_FORALL (BIT(0))

public plugin_precache() {
    CE_Register(ENTITY_NAME, .preset = CEPreset_Trigger);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "@Entity_Spawn");
    CE_RegisterHook(CEFunction_Activate, ENTITY_NAME, "@Entity_Activate");
    CE_RegisterHook(CEFunction_Activated, ENTITY_NAME, "@Entity_Activated");
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

@Entity_Spawn(this) {
    ZP_GameRules_SetObjectiveMode(true);
    CE_SetMember(this, MEMBER_PLAYER_FLAGS, 0);
}

@Entity_Activate(this, pActivator) {
    if (!IS_PLAYER(pActivator)) {
        return PLUGIN_CONTINUE;
    }

    if (ZP_Player_IsZombie(pActivator)) {
        return PLUGIN_CONTINUE;
    }

    if (!Round_IsRoundStarted()) {
        return PLUGIN_CONTINUE;
    }

    if (Round_IsRoundEnd()) {
        return PLUGIN_CONTINUE;
    }

    return PLUGIN_HANDLED;
}

@Entity_Activated(this, pActivator) {
    CE_SetMember(this, MEMBER_PLAYER_FLAGS, CE_GetMember(this, MEMBER_PLAYER_FLAGS) | BIT(pActivator & 31));

    if (@Entity_IsActivated(this)) {
        ZP_GameRules_DispatchWin(ZP_HUMAN_TEAM);
    }
}

@Entity_IsActivated(this) {
    new iPlayerFlags = CE_GetMember(this, MEMBER_PLAYER_FLAGS);

    new iTouchersNum = 0;
    new iHumansNum = 0;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_alive(pPlayer)) {
            continue;
        }

        if (ZP_Player_IsZombie(pPlayer)) {
            continue;
        }

        iHumansNum++;

        if (iPlayerFlags & BIT(pPlayer & 31)) {
            iTouchersNum++;
        }
    }

    if (pev(this, pev_spawnflags) & SF_FORALL) {
        return iTouchersNum >= iHumansNum;
    }

    return iTouchersNum > 0;
}
