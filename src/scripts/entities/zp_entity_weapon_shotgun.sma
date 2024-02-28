#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_custom_weapons>
#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] weapon_shotgun"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "weapon_shotgun"
#define WEAPON_NAME ZP_WEAPON_SHOTGUN

new CW:g_iCwHandler;
new CE:g_iCeHandler;

public plugin_precache() {
    g_iCwHandler = CW_GetHandler(WEAPON_NAME);
    if (g_iCwHandler == CW_INVALID_HANDLER) return;

    g_iCeHandler = CE_Register(ENTITY_NAME);
    CE_RegisterHook(ENTITY_NAME, CEFunction_Init, "@Entity_Init");
    CE_RegisterHook(ENTITY_NAME, CEFunction_Spawned, "@Entity_Spawned");
    CE_RegisterHook(ENTITY_NAME, CEFunction_Think, "@Entity_Think");
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Touch, "weaponbox", "HamHook_WeaponBox_Touch_Post", .Post = 1);
}

public HamHook_WeaponBox_Touch_Post(pEntity) {
    UTIL_HandleSpawnerItemTouch(pEntity, g_iCeHandler);

    return HAM_HANDLED;
}

@Entity_Init(this) {
    UTIL_InitWeaponEntity(this);
}

@Entity_Spawned(this) {
    set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_Think(this) {
    UTIL_WeaponEntityThink(this, g_iCwHandler);
}
