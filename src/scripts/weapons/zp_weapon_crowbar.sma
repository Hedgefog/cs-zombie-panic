#pragma semicolon 1

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <api_custom_weapons>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Weapon Crowbar"
#define AUTHOR "Hedgehog Fog"

new CW:g_iCwHandler;

public plugin_precache() {
    precache_generic(ZP_WEAPON_CROWBAR_HUD_TXT);

    precache_model(ZP_WEAPON_CROWBAR_V_MODEL);
    precache_model(ZP_WEAPON_CROWBAR_P_MODEL);
    precache_model(ZP_WEAPON_CROWBAR_W_MODEL);

    precache_sound(ZP_WEAPON_CROWBAR_MISS_SOUND);

    for (new i = 0; i < sizeof(ZP_WEAPON_CROWBAR_HIT_SOUNDS); ++i) {
        precache_sound(ZP_WEAPON_CROWBAR_HIT_SOUNDS[i]);
    }

    for (new i = 0; i < sizeof(ZP_WEAPON_CROWBAR_HITBODY_SOUNDS); ++i) {
        precache_sound(ZP_WEAPON_CROWBAR_HITBODY_SOUNDS[i]);
    }

    g_iCwHandler = CW_Register(ZP_WEAPON_CROWBAR, CSW_KNIFE, WEAPON_NOCLIP, _, _, _, _, 2, 1, _, _, CWF_NoBulletSmoke);
    CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
    CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
    CW_Bind(g_iCwHandler, CWB_SecondaryAttack, "@Weapon_SecondaryAttack");
    CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
    CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
    CW_Bind(g_iCwHandler, CWB_Spawn, "@Weapon_Spawn");
    CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");
    CW_Bind(g_iCwHandler, CWB_CanDrop, "@Weapon_CanDrop");

    ZP_Weapons_Register(g_iCwHandler, ZP_WEIGHT_MELEE);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public @Weapon_Idle(this) {
    switch (random(3)) {
        case 0: {
            CW_PlayAnimation(this, 0, 36.0 / 13.0);
        }
        case 1: {
            CW_PlayAnimation(this, 9, 81.0 / 15.0);
        }
        case 2: {
            CW_PlayAnimation(this, 10, 81.0 / 15.0);
        }
    }
}

public @Weapon_PrimaryAttack(this) {
    new pPlayer = CW_GetPlayer(this);
    new pHit = CW_DefaultSwing(this, 35.0, 0.5, 36.0);
    CW_PlayAnimation(this, 4, 0.25);

    if (pHit < 0) {
        switch (random(3)) {
            case 0: CW_PlayAnimation(this, 4, 11.0 / 22.0);
            case 1: CW_PlayAnimation(this, 5, 14.0 / 22.0);
            case 2: CW_PlayAnimation(this, 7, 19.0 / 24.0);
        }

        emit_sound(pPlayer, CHAN_ITEM, ZP_WEAPON_CROWBAR_MISS_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    } else {
        switch (random(3)) {
            case 0: CW_PlayAnimation(this, 3, 11.0 / 22.0);
            case 1: CW_PlayAnimation(this, 6, 14.0 / 22.0);
            case 2: CW_PlayAnimation(this, 8, 19.0 / 24.0);
        }

        if (UTIL_IsPlayer(pHit)) {
            emit_sound(pPlayer, CHAN_ITEM, ZP_WEAPON_CROWBAR_HITBODY_SOUNDS[random(sizeof(ZP_WEAPON_CROWBAR_HITBODY_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        } else {
            emit_sound(pPlayer, CHAN_ITEM, ZP_WEAPON_CROWBAR_HIT_SOUNDS[random(sizeof(ZP_WEAPON_CROWBAR_HIT_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        }
    }

    set_member(this, m_Weapon_flNextSecondaryAttack, 0.5);
}

public @Weapon_SecondaryAttack(this) {
    new pPlayer = CW_GetPlayer(this);
    if (is_user_bot(pPlayer)) {
        CW_PrimaryAttack(this);
    }
}

public @Weapon_Deploy(this) {
    CW_DefaultDeploy(this, ZP_WEAPON_CROWBAR_V_MODEL, ZP_WEAPON_CROWBAR_P_MODEL, 1, "grenade");
}

public Float:@Weapon_GetMaxSpeed(this) {
    return ZP_HUMAN_SPEED;
}

public @Weapon_Spawn(this) {
    engfunc(EngFunc_SetModel, this, ZP_WEAPON_CROWBAR_W_MODEL);
}

public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
    engfunc(EngFunc_SetModel, pWeaponBox, ZP_WEAPON_CROWBAR_W_MODEL);
}

public @Weapon_CanDrop(this) {
    return PLUGIN_HANDLED;
}
