
#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <api_rounds>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] item_battery"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "item_battery"

new g_iModel;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Touch, ENTITY_NAME, "OnTouch", .Post = 0);
}

public plugin_precache() {
    precache_sound("items/tr_kevlar.wav");
    g_iModel = precache_model(ZP_ITEM_BATTERY_MODEL);

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
            new Float:flArmorValue;
            pev(pToucher, pev_armorvalue, flArmorValue);

            if (flArmorValue < 100.0) {
                flArmorValue = floatmin(100.0, flArmorValue + 20.0);
                set_member(pToucher, m_iKevlar, 1);
                set_pev(pToucher, pev_armorvalue, flArmorValue);

                set_pev(pEntity, pev_effects, pev(pEntity, pev_effects) | EF_NODRAW);
                set_pev(pEntity, pev_solid, SOLID_NOT);

                emit_sound(pEntity, CHAN_ITEM, "items/tr_kevlar.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
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
