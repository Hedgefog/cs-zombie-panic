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

    RegisterHam(Ham_TakeDamage, "player", "OnPlayerTraceAttack", .Post = 0);
    RegisterHam(Ham_TakeDamage, "player", "OnPlayerTraceAttack_Post", .Post = 1);
}

public OnPlayerTraceAttack(pPlayer) {
    pev(pPlayer, pev_velocity, g_rgflPlayerVelocity[pPlayer]);
}

public OnPlayerTraceAttack_Post(pPlayer) {
    set_pev(pPlayer, pev_velocity, g_rgflPlayerVelocity[pPlayer]); // reset knockback
}
