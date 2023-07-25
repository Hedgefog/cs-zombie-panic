#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Knockback"
#define AUTHOR "Hedgehog Fog"

new Float:g_rgflPlayerVelocity[MAX_PLAYERS + 1][3];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage", .Post = 0);
    RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 1);
}

public HamHook_Player_TakeDamage(pPlayer) {
    pev(pPlayer, pev_velocity, g_rgflPlayerVelocity[pPlayer]);
}

public HamHook_Player_TakeDamage_Post(pPlayer) {
    set_pev(pPlayer, pev_velocity, g_rgflPlayerVelocity[pPlayer]); // reset knockback
}
