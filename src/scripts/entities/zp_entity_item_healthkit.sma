#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <api_rounds>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] item_healthkit"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "item_healthkit"

new g_iModel;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Touch, ENTITY_NAME, "OnTouch", .Post = 0);
}

public plugin_precache() {
    precache_sound("items/smallmedkit1.wav");
    g_iModel = precache_model(ZP_ITEM_MEDKIT_MODEL);

    RegisterHam(Ham_Spawn, ENTITY_NAME, "OnSpawn_Post", .Post = 1);
}

public OnSpawn_Post(pEntity) {
    set_pev(pEntity, pev_modelindex, g_iModel);
    set_pev(pEntity, pev_solid, SOLID_TRIGGER);
    set_pev(pEntity, pev_effects, pev(pEntity, pev_effects) & ~EF_NODRAW);

    return HAM_HANDLED;
}

public OnTouch(pEntity, pToucher) {
    if (!UTIL_IsPlayer(pToucher)) {
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

                set_pev(pEntity, pev_effects, pev(pEntity, pev_effects) | EF_NODRAW);
                set_pev(pEntity, pev_solid, SOLID_NOT);

                emit_sound(pToucher, CHAN_ITEM, "items/smallmedkit1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
            }
        }
    }

    return HAM_SUPERCEDE;
}

public Round_Fw_NewRound() {
    new pEntity;
    while ((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", ENTITY_NAME)) != 0) {
        ExecuteHamB(Ham_Spawn, pEntity);
    }
}
