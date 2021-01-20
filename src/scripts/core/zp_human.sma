#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Human"
#define AUTHOR "Hedgehog Fog"

public plugin_precache() {
    for (new i = 0; i < sizeof(ZP_HUMAN_DEATH_SOUNDS); ++i) {
      precache_sound(ZP_HUMAN_DEATH_SOUNDS[i]);
    }
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);
}

public OnPlayerKilled_Post(pPlayer) {
    if (ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    emit_sound(pPlayer, CHAN_VOICE, ZP_HUMAN_DEATH_SOUNDS[random(sizeof(ZP_HUMAN_DEATH_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return HAM_HANDLED;
}
