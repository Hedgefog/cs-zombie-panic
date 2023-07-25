#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <xs>

#include <api_rounds>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] item_healthkit"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "item_healthkit"

new g_iModel;

new g_pCvarCureChance;
new g_pCvarSuspendInfection;

public plugin_precache() {
    precache_sound("items/smallmedkit1.wav");
    g_iModel = precache_model(ZP_ITEM_MEDKIT_MODEL);

    RegisterHam(Ham_Spawn, ENTITY_NAME, "HamHook_HealthKit_Spawn_Post", .Post = 1);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Touch, ENTITY_NAME, "HamHook_HealthKit_Touch", .Post = 0);

    g_pCvarCureChance = register_cvar("zp_healthkit_cure_chance", "25");
    g_pCvarSuspendInfection = register_cvar("zp_healthkit_suspend_infection", "1");
}

public HamHook_HealthKit_Spawn_Post(pEntity) {
    set_pev(pEntity, pev_modelindex, g_iModel);
    set_pev(pEntity, pev_solid, SOLID_TRIGGER);
    set_pev(pEntity, pev_effects, pev(pEntity, pev_effects) & ~EF_NODRAW);

    SetThink(pEntity, "");

    if (!ZP_GameRules_CanItemRespawn(pEntity)) {
        Kill(pEntity);
    }

    return HAM_HANDLED;
}

public HamHook_HealthKit_Touch(pEntity, pToucher) {
    if (!IS_PLAYER(pToucher)) {
        return HAM_IGNORED;
    }

    if (ZP_Player_IsZombie(pToucher)) {
        return HAM_SUPERCEDE;
    }

    if (GetHamReturnStatus() < HAM_SUPERCEDE) {
        if (!get_member_game(m_bFreezePeriod)) {
            new Float:flMaxHealth;
            pev(pToucher, pev_max_health, flMaxHealth);
            
            new Float:flHealth;
            pev(pToucher, pev_health, flHealth);
            
            if (flHealth < flMaxHealth) {
                flHealth = floatmin(flMaxHealth, flHealth + 25.0);
                set_pev(pToucher, pev_health, flHealth);
            } else {
                if (!ZP_Player_IsInfected(pToucher) || !ZP_Player_IsPartialZombie(pToucher) || ZP_Player_IsTransforming(pToucher)) {
                    return HAM_SUPERCEDE;
                }
            }

            if (ZP_Player_IsInfected(pToucher) && !ZP_Player_IsTransforming(pToucher)) {
                if (random(100) < get_pcvar_num(g_pCvarCureChance)) {
                    ZP_Player_SetInfected(pToucher, false);
                } else if (get_pcvar_num(g_pCvarSuspendInfection)) {
                    new pInfector = ZP_Player_GetInfector(pToucher);
                    ZP_Player_SetInfected(pToucher, false);
                    ZP_Player_SetInfected(pToucher, true, pInfector);
                }
            }

            emit_sound(pToucher, CHAN_ITEM, "items/smallmedkit1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
            Kill(pEntity);
        }
    }

    return HAM_SUPERCEDE;
}

public RespawnThink(pEntity) {
    dllfunc(DLLFunc_Spawn, pEntity);
    SetThink(pEntity, "");
}

public Round_Fw_NewRound() {
    new pEntity;
    while ((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", ENTITY_NAME)) != 0) {
        ExecuteHamB(Ham_Spawn, pEntity);
    }
}

Kill(pEntity) {
    set_pev(pEntity, pev_effects, pev(pEntity, pev_effects) | EF_NODRAW);
    set_pev(pEntity, pev_solid, SOLID_NOT);
    SetThink(pEntity, "RespawnThink");
    set_pev(pEntity, pev_nextthink, get_gametime() + ZP_ITEMS_RESPAWN_TIME);
}
