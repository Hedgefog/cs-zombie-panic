#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <xs>

#include <zombiepanic>
#include <zombiepanic_utils>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Weapon 357 Magnum"
#define AUTHOR "Hedgehog Fog"

new CW:g_iCwHandler;

public plugin_precache() {
    precache_generic(ZP_WEAPON_MAGNUM_HUD_TXT);

    precache_model(ZP_WEAPON_MAGNUM_V_MODEL);
    precache_model(ZP_WEAPON_MAGNUM_P_MODEL);
    precache_model(ZP_WEAPON_MAGNUM_W_MODEL);
    precache_model("models/shell.mdl");

    for (new i = 0; i < sizeof(ZP_WEAPON_MAGNUM_SHOT_SOUNDS); ++i) {
        precache_sound(ZP_WEAPON_MAGNUM_SHOT_SOUNDS[i]);
    }

    g_iCwHandler = CW_Register(ZP_WEAPON_MAGNUM, CSW_DEAGLE, 6, ZP_Ammo_GetId(ZP_Ammo_GetHandler(ZP_AMMO_MAGNUM)), 24, _, _, 1, 6, _, "fiveseven", CWF_NoBulletSmoke);
    CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
    CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
    CW_Bind(g_iCwHandler, CWB_Reload, "@Weapon_Reload");
    CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
    CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
    CW_Bind(g_iCwHandler, CWB_Spawn, "@Weapon_Spawn");
    CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");

    ZP_Weapons_Register(g_iCwHandler, ZP_WEIGHT_MAGNUM);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public @Weapon_Idle(this) {
    new Float:flRand = random_float(0.0, 1.0);
    
    if (flRand < 0.5) {
        CW_PlayAnimation(this, 0, 71.0 / 30.0);
    } else if (flRand < 0.7) {
        CW_PlayAnimation(this, 6, 71.0 / 30.0);
    } else if (flRand < 0.9) {
        CW_PlayAnimation(this, 7, 89.0 / 30.0);
    } else {
        CW_PlayAnimation(this, 1, 171.0 / 30.0);
    }
}

public @Weapon_PrimaryAttack(this) {
    if (get_member(this, m_Weapon_iShotsFired) > 0) {
        return;
    }

    static Float:vecSpread[3];
    UTIL_CalculateWeaponSpread(this, Float:VECTOR_CONE_1DEGREES, 5.0, 1.0, 0.95, 7.5, vecSpread);

    if (CW_DefaultShot(this, 70.0, 0.5, vecSpread)) {
        CW_PlayAnimation(this, 2, 1.03);
        new pPlayer = CW_GetPlayer(this);
        emit_sound(pPlayer, CHAN_WEAPON, ZP_WEAPON_MAGNUM_SHOT_SOUNDS[random(sizeof(ZP_WEAPON_MAGNUM_SHOT_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        set_pev(pPlayer, pev_punchangle, Float:{-10.0, 0.0, 0.0});

        CW_EjectWeaponBrass(this, engfunc(EngFunc_ModelIndex, "models/shell.mdl"), 1);
    }
}

public @Weapon_Reload(this) {
    CW_DefaultReload(this, 3, 2.5);
}

public @Weapon_Deploy(this) {
    CW_DefaultDeploy(this, ZP_WEAPON_MAGNUM_V_MODEL, ZP_WEAPON_MAGNUM_P_MODEL, 5, "onehanded");
}

public Float:@Weapon_GetMaxSpeed(this) {
    return ZP_HUMAN_SPEED;
}

public @Weapon_Spawn(this) {
    engfunc(EngFunc_SetModel, this, ZP_WEAPON_MAGNUM_W_MODEL);
}

public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
    engfunc(EngFunc_SetModel, pWeaponBox, ZP_WEAPON_MAGNUM_W_MODEL);
}
