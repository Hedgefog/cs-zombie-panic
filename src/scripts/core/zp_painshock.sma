#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Pain Shock"
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 1);
}

public HamHook_Player_TakeDamage_Post(pPlayer) {
    set_member(pPlayer, m_flVelocityModifier, 1.0);

    return HAM_HANDLED;
}
