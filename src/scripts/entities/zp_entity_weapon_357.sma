#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_custom_weapons>
#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] weapon_357"
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "weapon_357"
#define WEAPON_NAME ZP_WEAPON_MAGNUM

new CW:g_iCwHandler;
new g_iCeHandler;

public plugin_precache() {
    g_iCwHandler = CW_GetHandler(ZP_WEAPON_MAGNUM);
    if (g_iCwHandler == CW_INVALID_HANDLER) {
        return;
    }

    g_iCeHandler = CE_Register(ENTITY_NAME, _, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 8.0}, _, ZP_WEAPONS_RESPAWN_TIME);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "@Entity_Spawn");
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Touch, "weaponbox", "HamHook_WeaponBox_Touch_Post", .Post = 1);
    RegisterHam(Ham_Think, CE_BASE_CLASSNAME, "HamHook_Base_Think_Post", .Post = 1);
}

public HamHook_WeaponBox_Touch_Post(pEntity) {
    UTIL_HandleSpawnerItemTouch(pEntity, g_iCeHandler);

    return HAM_HANDLED;
}

public HamHook_Base_Think_Post(pEntity) {
    if (CE_GetHandlerByEntity(pEntity) == g_iCeHandler) {
        @Entity_Think(pEntity);
    }

    return HAM_HANDLED;
}

@Entity_Spawn(this) {
    set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_Think(this) {
    if (ZP_GameRules_CanItemRespawn(this)) {
        new pWeaponBox = CW_SpawnWeaponBox(g_iCwHandler);
        UTIL_InitWithSpawner(pWeaponBox, this);
    } else {
        CE_Kill(this);
    }
}

