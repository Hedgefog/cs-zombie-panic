#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Weapon Crowbar"
#define AUTHOR "Hedgehog Fog"

#define PRIMARY_AMMO_ID 13

new CW:g_iCwHandler;
new gmsgAmmoX;

public plugin_precache() {
    precache_generic(ZP_WEAPON_SWIPE_HUD_TXT);

    for (new i = 0; i < sizeof(ZP_WEAPON_SWIPE_MISS_SOUNDS); ++i) {
        precache_sound(ZP_WEAPON_SWIPE_MISS_SOUNDS[i]);
    }

    for (new i = 0; i < sizeof(ZP_WEAPON_SWIPE_HIT_SOUNDS); ++i) {
        precache_sound(ZP_WEAPON_SWIPE_HIT_SOUNDS[i]);
    }

    g_iCwHandler = CW_Register(ZP_WEAPON_SWIPE, CSW_KNIFE, WEAPON_NOCLIP, PRIMARY_AMMO_ID, _, _, _, 2, 1, _, "swipe", CWF_NoBulletDecal | CWF_NotRefillable);
    CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
    CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
    CW_Bind(g_iCwHandler, CWB_SecondaryAttack, "@Weapon_SecondaryAttack");
    CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
    CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
    CW_Bind(g_iCwHandler, CWB_CanDrop, "@Weapon_CanDrop");

    ZP_Weapons_Register(g_iCwHandler, 0.0);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgAmmoX = get_user_msgid("AmmoX");

    RegisterHamPlayer(Ham_TraceAttack, "HamHook_Player_TraceAttack", .Post = 0);
    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
}

public ZP_Fw_ZombieLivesChanged() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (!is_user_alive(pPlayer)) {
            continue;
        }

        if (!ZP_Player_IsZombie(pPlayer)) {
            continue;
        }

        @Player_UpdateZombieLivesHud(pPlayer);
    }
}

public HamHook_Player_Spawn_Post(pPlayer) {
    @Player_UpdateZombieLivesHud(pPlayer);
    return HAM_HANDLED;
}

public HamHook_Player_TraceAttack(this, pAttacker, Float:flDamage, Float:vecDir[3], pTr, iDamageBits) {
    if (!IS_PLAYER(pAttacker)) {
        return HAM_IGNORED;
    }

    new pItem = get_member(pAttacker, m_pActiveItem);
    if (CW_GetHandlerByEntity(pItem) != g_iCwHandler) {
        return HAM_IGNORED;
    }

    set_tr2(pTr, TR_iHitgroup, get_tr2(pTr, TR_iHitgroup) & ~HIT_HEAD);

    return HAM_HANDLED;
}

@Weapon_PrimaryAttack(this) {
    @Weapon_Swing(this);
    set_member(this, m_Weapon_flNextSecondaryAttack, 0.5);
}

@Weapon_SecondaryAttack(this) {
    new pPlayer = CW_GetPlayer(this);
    if (is_user_bot(pPlayer)) {
        @Weapon_Swing(this);
        set_member(this, m_Weapon_flNextSecondaryAttack, 0.5);
    }
}

@Weapon_Deploy(this) {
    CW_DefaultDeploy(this, NULL_STRING, NULL_STRING, 1, "dualpistols");
}

@Weapon_Idle(this) {
    new pPlayer = CW_GetPlayer(this);
    set_member(pPlayer, m_szAnimExtention, "dualpistols");

    switch (random(3)) {
        case 0: {
            CW_PlayAnimation(this, 0, 36.0 / 13.0);
        }
        case 1: {
            CW_PlayAnimation(this, 9, 61.0 / 15.0);
        }
        case 2: {
            CW_PlayAnimation(this, 10, 61.0 / 15.0);
        }
    }
}

Float:@Weapon_GetMaxSpeed(this) {
    return ZP_ZOMBIE_SPEED;
}

@Weapon_CanDrop(this) {
    return PLUGIN_HANDLED;
}

@Weapon_Swing(this) {
    new pPlayer = CW_GetPlayer(this);

    if (random(2) == 0) {
        set_member(pPlayer, m_szAnimExtention, "grenade");
    } else {
        set_member(pPlayer, m_szAnimExtention, "shieldgren");
    }

    new pHit = CW_DefaultSwing(this, 25.0, 0.5, 36.0);

    if (pHit < 0) {
        switch (random(3)) {
            case 0: CW_PlayAnimation(this, 4, 11.0 / 22.0);
            case 1: CW_PlayAnimation(this, 5, 14.0 / 22.0);
            case 2: CW_PlayAnimation(this, 7, 19.0 / 24.0);
        }

        emit_sound(pPlayer, CHAN_ITEM, ZP_WEAPON_SWIPE_MISS_SOUNDS[random(sizeof(ZP_WEAPON_SWIPE_MISS_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    } else {
        switch (random(3)) {
            case 0: CW_PlayAnimation(this, 3, 11.0 / 22.0);
            case 1: CW_PlayAnimation(this, 6, 14.0 / 22.0);
            case 2: CW_PlayAnimation(this, 8, 19.0 / 24.0);
        }

        emit_sound(pPlayer, CHAN_ITEM, ZP_WEAPON_SWIPE_HIT_SOUNDS[random(sizeof(ZP_WEAPON_SWIPE_HIT_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }
}

@Player_UpdateZombieLivesHud(this) {
    message_begin(MSG_ONE, gmsgAmmoX, _, this);
    write_byte(PRIMARY_AMMO_ID);
    write_byte(ZP_GameRules_GetZombieLives());
    message_end();
}
