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

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "OnPlayerSpawnEquip");
}

public OnPlayerSpawnEquip(pPlayer) {
    rg_remove_all_items(pPlayer);

    set_member(pPlayer, m_szAnimExtention, "c4");

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

    return HC_SUPERCEDE;
}
