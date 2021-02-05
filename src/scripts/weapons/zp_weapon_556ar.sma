#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <xs>

#include <zombiepanic>
#include <zombiepanic_utils>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Weapon 556ar"
#define AUTHOR "Hedgehog Fog"

new CW:g_iCwHandler;

public plugin_precache() {
    precache_generic(ZP_WEAPON_RIFLE_HUD_TXT);

    precache_model(ZP_WEAPON_RIFLE_V_MODEL);
    precache_model(ZP_WEAPON_RIFLE_P_MODEL);
    precache_model(ZP_WEAPON_RIFLE_W_MODEL);
    precache_model("models/shell.mdl");

    for (new i = 0; i < sizeof(ZP_WEAPON_RIFLE_SHOT_SOUNDS); ++i) {
        precache_sound(ZP_WEAPON_RIFLE_SHOT_SOUNDS[i]);
    }

    precache_sound(ZP_WEAPON_RIFLE_RELOAD_START_SOUND);
    precache_sound(ZP_WEAPON_RIFLE_RELOAD_END_SOUND);

    g_iCwHandler = CW_Register(ZP_WEAPON_RIFLE, CSW_MP5NAVY, 30, ZP_Ammo_GetId(ZP_Ammo_GetHandler(ZP_AMMO_RIFLE)), 90, _, _, 0, 1, _, "m4a1");
    CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
    CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
    CW_Bind(g_iCwHandler, CWB_Reload, "@Weapon_Reload");
    CW_Bind(g_iCwHandler, CWB_DefaultReloadEnd, "@Weapon_DefaultReloadEnd");
    CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
    CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
    CW_Bind(g_iCwHandler, CWB_Spawn, "@Weapon_Spawn");
    CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");

    ZP_Weapons_Register(g_iCwHandler, ZP_WEIGHT_RIFLE);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public @Weapon_Idle(this) {
    switch (random(2)) {
        case 0: {
            CW_PlayAnimation(this, 0, 41.0 / 8.0);
        }
        case 1: {
            CW_PlayAnimation(this, 1, 111.0 / 35.0);
        }
    }
}

public @Weapon_PrimaryAttack(this) {
    static Float:vecSpread[3];
    UTIL_CalculateWeaponSpread(this, Float:VECTOR_CONE_6DEGREES, 3.0, 0.5, 0.95, 3.5, vecSpread);

    if (CW_DefaultShot(this, 26.0, 0.095, Float:vecSpread)) {
        CW_PlayAnimation(this, 5 + random(3), 0.7);
        new pPlayer = CW_GetPlayer(this);
        emit_sound(pPlayer, CHAN_WEAPON, ZP_WEAPON_RIFLE_SHOT_SOUNDS[random(sizeof(ZP_WEAPON_RIFLE_SHOT_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

        set_pev(pPlayer, pev_punchangle, Float:{-2.0, 0.0, 0.0});

        CW_EjectWeaponBrass(this, engfunc(EngFunc_ModelIndex, "models/shell.mdl"), 1);
    }
}

public @Weapon_Reload(this) {
    // new pPlayer = CW_GetPlayer(this);
    if (CW_DefaultReload(this, 3, 1.57)) {
        // emit_sound(pPlayer, CHAN_WEAPON, ZP_WEAPON_RIFLE_RELOAD_START_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }
}

public @Weapon_DefaultReloadEnd(this) {
    // new pPlayer = CW_GetPlayer(this);
    // emit_sound(pPlayer, CHAN_WEAPON, ZP_WEAPON_RIFLE_RELOAD_END_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public @Weapon_Deploy(this) {
    CW_DefaultDeploy(this, ZP_WEAPON_RIFLE_V_MODEL, ZP_WEAPON_RIFLE_P_MODEL, 4, "rifle");
}

public Float:@Weapon_GetMaxSpeed(this) {
    return ZP_HUMAN_SPEED;
}

public @Weapon_Spawn(this) {
    engfunc(EngFunc_SetModel, this, ZP_WEAPON_RIFLE_W_MODEL);
}

public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
    engfunc(EngFunc_SetModel, pWeaponBox, ZP_WEAPON_RIFLE_W_MODEL);
}
