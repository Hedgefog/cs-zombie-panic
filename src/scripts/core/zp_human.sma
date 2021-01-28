#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Human"
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}
