#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_custom_weapons>
#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] weapon_9mmhandgun"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "weapon_9mmhandgun"
#define WEAPON_NAME ZP_WEAPON_PISTOL

new CW:g_iCwHandler;
new CE:g_iCeHandler;

public plugin_precache() {
    g_iCwHandler = CW_GetHandler(WEAPON_NAME);
    if (g_iCwHandler == CW_INVALID_HANDLER) return;

    g_iCeHandler = CE_Register(ENTITY_NAME);
    CE_RegisterHook(CEFunction_Init, ENTITY_NAME, "@Entity_Init");
    CE_RegisterHook(CEFunction_Spawned, ENTITY_NAME, "@Entity_Spawned");
    CE_RegisterHook(CEFunction_Think, ENTITY_NAME, "@Entity_Think");
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
