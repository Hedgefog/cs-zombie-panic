#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Player Equipment"
#define AUTHOR "Hedgehog Fog"

#define PLAYER_IDLE_ANIMEXT "c4"

new g_pFwPlayerEquiped;
new g_iFwResult;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "HC_Player_SpawnEquip");

    g_pFwPlayerEquiped = CreateMultiForward("ZP_Fw_PlayerEquiped", ET_IGNORE, FP_CELL);
}

public HC_Player_SpawnEquip(pPlayer) {
    rg_remove_all_items(pPlayer);

    set_member(pPlayer, m_szAnimExtention, PLAYER_IDLE_ANIMEXT);

    new Float:flMaxHealth = ZP_Player_IsZombie(pPlayer) ? ZP_ZOMBIE_HEALTH : 100.0;
    set_pev(pPlayer, pev_max_health, flMaxHealth);
    set_pev(pPlayer, pev_health, flMaxHealth);
    set_pev(pPlayer, pev_armorvalue, 0.0);
    set_member(pPlayer, m_iKevlar, 0);

    if (Round_IsRoundStarted()) {
        strip_user_weapons(pPlayer);

        if (ZP_Player_IsZombie(pPlayer)) {
            CW_GiveWeapon(pPlayer, ZP_WEAPON_SWIPE);
        } else {
            CW_GiveWeapon(pPlayer, ZP_WEAPON_CROWBAR);
            CW_GiveWeapon(pPlayer, ZP_WEAPON_PISTOL);
        }
    }

    ExecuteForward(g_pFwPlayerEquiped, g_iFwResult, pPlayer);

    return HC_SUPERCEDE;
}
