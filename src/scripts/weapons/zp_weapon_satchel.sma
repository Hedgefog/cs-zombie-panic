#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <xs>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>
#include <api_rounds>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Weapon Crowbar"
#define AUTHOR "Hedgehog Fog"

new const g_rgszBounceSounds[][] = {
    "weapons/g_bounce1.wav",
    "weapons/g_bounce2.wav",
    "weapons/g_bounce3.wav"
};

new gmsgAmmoPickup;

new bool:g_bPlayerChargeReady[MAX_PLAYERS + 1];
new bool:g_bPlayerRedeploy[MAX_PLAYERS + 1];
new g_pPlayerPickupCharge[MAX_PLAYERS + 1] = { -1, ... };
new g_iPlayerChargeCount[MAX_PLAYERS + 1] = { 0, ... };
new g_iAmmoId;

new CW:g_iCwHandler;

public plugin_precache() {
    precache_generic(ZP_WEAPON_SATCHEL_HUD_TXT);

    precache_model(ZP_WEAPON_SATCHEL_V_MODEL);
    precache_model(ZP_WEAPON_SATCHEL_P_MODEL);
    precache_model(ZP_WEAPON_SATCHEL_W_MODEL);
    precache_model(ZP_WEAPON_SATCHELRADIO_V_MODEL);
    precache_model(ZP_WEAPON_SATCHELRADIO_P_MODEL);

    for (new i = 0; i < sizeof(g_rgszBounceSounds); ++i) {
        precache_sound(g_rgszBounceSounds[i]);
    }

    g_iAmmoId = ZP_Ammo_GetId(ZP_Ammo_GetHandler("satchel"));

    g_iCwHandler = CW_Register(ZP_WEAPON_SATCHEL, CSW_C4, WEAPON_NOCLIP, g_iAmmoId, -1, 0, -1, 4, 5, _, "satchel");
    CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
    CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
    CW_Bind(g_iCwHandler, CWB_SecondaryAttack, "@Weapon_SecondaryAttack");
    CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
    CW_Bind(g_iCwHandler, CWB_Holster, "@Weapon_Holster");
    CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
    CW_Bind(g_iCwHandler, CWB_Spawn, "@Weapon_Spawn");
    CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");
    CW_Bind(g_iCwHandler, CWB_CanDrop, "@Weapon_CanDrop");

    ZP_Weapons_Register(g_iCwHandler, 0.0);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgAmmoPickup = get_user_msgid("AmmoPickup");

    RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);
    RegisterHamPlayer(Ham_Player_PreThink, "HamHook_Player_PreThink_Post", .Post = 1);
    RegisterHamPlayer(Ham_Player_PostThink, "HamHook_Player_PostThink_Post", .Post = 1);
}

@Weapon_PrimaryAttack(this) {
    new pPlayer = CW_GetPlayer(this);

    if (g_bPlayerChargeReady[pPlayer]) {
            Detonate(this);
    } else {
            if (get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0) {
                return;
            }

            Throw(this);
    }

    CW_PlayAnimation(this, 3, 0.5);
    g_bPlayerRedeploy[pPlayer] = true;
}

@Weapon_SecondaryAttack(this) {
    new pPlayer = CW_GetPlayer(this);

    if (!g_bPlayerChargeReady[pPlayer]) {
        return;
    }

    if (get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0) {
        return;
    }

    Throw(this);
    set_member(this, m_Weapon_flNextPrimaryAttack, 0.53);
    set_member(this, m_Weapon_flNextSecondaryAttack, 0.53);
}

@Weapon_Deploy(this) {
    new pPlayer = CW_GetPlayer(this);

    if (g_bPlayerChargeReady[pPlayer] || get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0) {
        CW_DefaultDeploy(this, ZP_WEAPON_SATCHELRADIO_V_MODEL, ZP_WEAPON_SATCHELRADIO_P_MODEL, 2, "grenade");
    } else {
        CW_DefaultDeploy(this, ZP_WEAPON_SATCHEL_V_MODEL, ZP_WEAPON_SATCHEL_P_MODEL, 2, "grenade");
    }
}

@Weapon_Holster(this) {
    new pPlayer = CW_GetPlayer(this);
    if (get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0 && !g_bPlayerChargeReady[pPlayer]) {
        SetThink(this, "RemovePlayerItem");
        set_pev(this, pev_nextthink, get_gametime() + 0.1);
    }
}

public RemovePlayerItem(this) {
    CW_RemovePlayerItem(this);
}

Float:@Weapon_GetMaxSpeed(this) {
    return ZP_HUMAN_SPEED;
}

@Weapon_Idle(this) {
    new pPlayer = CW_GetPlayer(this);
    if (g_bPlayerRedeploy[pPlayer]) {
        ExecuteHamB(Ham_Item_Deploy, this);
        g_bPlayerRedeploy[pPlayer] = false;
    } else {
        CW_PlayAnimation(this, 0, 5.5);
    }

    if (get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0 && !g_bPlayerChargeReady[pPlayer]) {
        RemovePlayerItem(this);
    }
}

@Weapon_Spawn(this) {
    set_member(this, m_Weapon_iDefaultAmmo, 1);
    engfunc(EngFunc_SetModel, this, ZP_WEAPON_SATCHEL_W_MODEL);
}

@Weapon_WeaponBoxSpawn(this, pWeaponBox) {
    engfunc(EngFunc_SetModel, pWeaponBox, ZP_WEAPON_SATCHEL_W_MODEL);
}

@Weapon_CanDrop(this) {
    new pPlayer = CW_GetPlayer(this);
    if (pPlayer == -1) {
        return PLUGIN_CONTINUE;
    }

    return get_member(pPlayer, m_rgAmmo, g_iAmmoId) > 0 && !g_bPlayerChargeReady[pPlayer] ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

Throw(this) {
    new pPlayer = CW_GetPlayer(this);
    new iAmmoAmount = get_member(pPlayer, m_rgAmmo, g_iAmmoId);

    if (iAmmoAmount <= 0) {
        return;
    }

    static Float:vecOrigin[3];
    pev(pPlayer, pev_origin, vecOrigin);

    static Float:vecAngles[3];
    pev(pPlayer, pev_v_angle, vecAngles);

    static Float:vecForward[3];
    angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

    static Float:vecVelocity[3];
    pev(pPlayer, pev_velocity, vecVelocity);
    for (new i = 0; i < 3; ++i) {
        vecVelocity[i] = (vecForward[i] * 274.0) + vecVelocity[i];
    }

    new pSatchelCharge = SpawnSatchelCharge();
    engfunc(EngFunc_SetOrigin, pSatchelCharge, vecOrigin);
    set_pev(pSatchelCharge, pev_velocity, vecVelocity);
    set_pev(pSatchelCharge, pev_avelocity, Float:{0.0, 100.0, 0.0});
    set_pev(pSatchelCharge, pev_owner, pPlayer);
    set_pev(pSatchelCharge, pev_team, get_member(pPlayer, m_iTeam));
    g_iPlayerChargeCount[pPlayer]++;

    set_member(pPlayer, m_rgAmmo, iAmmoAmount - 1, g_iAmmoId);
    rg_set_animation(pPlayer, PLAYER_ATTACK1);

    g_bPlayerChargeReady[pPlayer] = true;

    set_member(this, m_Weapon_flNextPrimaryAttack, 1.0);
    set_member(this, m_Weapon_flNextSecondaryAttack, 0.5);

    ZP_Player_UpdateSpeed(pPlayer);
}

Detonate(this) {
    new pPlayer = CW_GetPlayer(this);

    new pEntity;
    while ((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "zp_satchel_charge")) != 0) {
        if (pev(pEntity, pev_owner) == pPlayer) {
            ExecuteHamB(Ham_Use, pEntity, pPlayer, pPlayer, USE_ON, 0.0);
        }
    }

    g_bPlayerChargeReady[pPlayer] = false;

    set_member(this, m_Weapon_flNextPrimaryAttack, 0.5);
    set_member(this, m_Weapon_flNextSecondaryAttack, 0.5);
}

SpawnSatchelCharge() {
    new pEntity = rg_create_entity("info_target");
    dllfunc(DLLFunc_Spawn, pEntity);
    
    set_pev(pEntity, pev_classname, "zp_satchel_charge");

    set_pev(pEntity, pev_movetype, MOVETYPE_BOUNCE);
    set_pev(pEntity, pev_solid, SOLID_BBOX);

    engfunc(EngFunc_SetModel, pEntity, ZP_WEAPON_SATCHEL_W_MODEL);
    // engfunc(EngFunc_SetSize, pEntity, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 16.0});

    SetTouch(pEntity, "SatchelChargeSlide");
    SetUse(pEntity, "GrenadeDetonateUse");
    SetThink(pEntity, "SatchelChargeThink");

    set_pev(pEntity, pev_nextthink, get_gametime() + 0.1);

    set_pev(pEntity, pev_gravity, 0.5);
    set_pev(pEntity, pev_friction, 0.8);

    set_pev(pEntity, pev_dmg, 500.0);
    set_pev(pEntity, pev_sequence, 1);
    set_pev(pEntity, pev_spawnflags, SF_DETONATE);

    return pEntity;
}

Deactivate(this) {
    set_pev(this, pev_solid, SOLID_NOT);
    set_pev(this, pev_flags, pev(this, pev_flags) | FL_KILLME);

    new pOwner = pev(this, pev_owner);
    if (IS_PLAYER(pOwner)) {
        g_iPlayerChargeCount[pOwner]--;
    }
}

DeactivateSatchels(pOwner) {
    new pEntity;
    while ((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "zp_satchel_charge")) != 0) {
        if (pev(pEntity, pev_owner) == pOwner) {
            Deactivate(pEntity);
        }
    }

    g_bPlayerChargeReady[pOwner] = false;
}

public SatchelChargeSlide(pEntity) {
    set_pev(pEntity, pev_gravity, 1.0);

    static Float:vecOrigin[3];
    pev(pEntity, pev_origin, vecOrigin);

    static Float:vecVelocity[3];
    pev(pEntity, pev_velocity, vecVelocity);

    static Float:vecDown[3];
    xs_vec_copy(vecOrigin, vecDown);
    vecDown[2] -= 10.0;

    new pTr = create_tr2();
    engfunc(EngFunc_TraceLine, vecOrigin, vecDown, IGNORE_MONSTERS, pEntity, pTr);

    static Float:flFraction;
    get_tr2(pTr, TR_flFraction, flFraction);

    free_tr2(pTr);

    if (flFraction < 1.0) {
        xs_vec_mul_scalar(vecVelocity, 0.95, vecVelocity);
        set_pev(pEntity, pev_velocity, vecVelocity);

        // static Float:vecAVelocity[3];
        // pev(pEntity, pev_velocity, vecAVelocity);
        // xs_vec_mul_scalar(vecAVelocity, 0.9, vecAVelocity);
        // set_pev(pEntity, pev_avelocity, vecAVelocity);
    }

    if ((~pev(pEntity, pev_flags) & FL_ONGROUND) && xs_vec_len(vecVelocity) > 10.0) {
        emit_sound(pEntity, CHAN_VOICE, g_rgszBounceSounds[random(sizeof(g_rgszBounceSounds))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }
}

public SatchelChargeThink(pEntity) {
    if (!ExecuteHam(Ham_IsInWorld, pEntity)) {
        engfunc(EngFunc_RemoveEntity, pEntity);
        return;
    }

    static Float:vecVelocity[3];
    pev(pEntity, pev_velocity, vecVelocity);

    new iWaterLevel = pev(pEntity, pev_waterlevel);
    if (iWaterLevel == 3) {
        set_pev(pEntity, pev_movetype, MOVETYPE_FLY);

        xs_vec_mul_scalar(vecVelocity, 0.8, vecVelocity);
        vecVelocity[2] += 8.0;
        set_pev(pEntity, pev_velocity, vecVelocity);

        static Float:vecAVelocity[3];
        pev(pEntity, pev_avelocity, vecAVelocity);
        xs_vec_mul_scalar(vecAVelocity, 0.9, vecAVelocity);
        set_pev(pEntity, pev_avelocity, vecAVelocity);
    } else if (iWaterLevel == 0) {
        set_pev(pEntity, pev_movetype, MOVETYPE_BOUNCE);
    } else {
        vecVelocity[2] -= 8.0;
        set_pev(pEntity, pev_velocity, vecVelocity);
    }

    // if (!xs_vec_len_2d(vecVelocity) && (iWaterLevel || pev(pEntity, pev_flags) & FL_ONGROUND)) {
    //     set_pev(pEntity, pev_solid, SOLID_NOT);
    // }

    set_pev(pEntity, pev_nextthink, get_gametime() + 0.1);
}

public GrenadeDetonateUse(const pEntity) {
    SetThink(pEntity, "GrenadeDetonate");
    set_pev(pEntity, pev_nextthink, get_gametime());
}

public GrenadeDetonate(this) {
    new pOwner = pev(this, pev_owner);

    new Float:flDamage;
    pev(this, pev_dmg, flDamage);

    CW_GrenadeDetonate(this, flDamage * 0.75, flDamage * 0.125);
    SetThink(this, "GrenadeSmoke");
    set_pev(this, pev_nextthink, get_gametime() + 0.1);

    if (IS_PLAYER(pOwner)) {
        g_iPlayerChargeCount[pOwner]--;
    }
}

public GrenadeSmoke(this) {
    CW_GrenadeSmoke(this);
    engfunc(EngFunc_RemoveEntity, this);
}

public Round_Fw_NewRound() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        DeactivateSatchels(pPlayer);
    }
}

public HamHook_Player_Killed_Post(pPlayer) {
    DeactivateSatchels(pPlayer);
}


public HamHook_Player_PreThink_Post(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    g_pPlayerPickupCharge[pPlayer] = -1;
    
    if (~pev(pPlayer, pev_button) & IN_USE || pev(pPlayer, pev_oldbuttons) & IN_USE) {
        return HAM_IGNORED;
    }
    if (ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    static Float:vecSrc[3];
    ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);

    static Float:vecEnd[3];
    pev(pPlayer, pev_v_angle, vecEnd);
    engfunc(EngFunc_MakeVectors, vecEnd);
    get_global_vector(GL_v_forward, vecEnd);

    for (new i = 0; i < 3; ++i) {
        vecEnd[i] = vecSrc[i] + (vecEnd[i] * 64.0);
    }

    new pTr = create_tr2();
    engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTr);
    get_tr2(pTr, TR_vecEndPos, vecEnd);
    free_tr2(pTr);

    new pEntity;
    while ((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "zp_satchel_charge")) != 0) {
        if (~pev(pEntity, pev_flags) & FL_ONGROUND) {
            continue;
        }
        
        if (pev(pEntity, pev_owner) != pPlayer) {
            continue;
        }

        static Float:vecOrigin[3];
        pev(pEntity, pev_origin, vecOrigin);

        if (xs_vec_distance(vecOrigin, vecEnd) < 16.0) {
            g_pPlayerPickupCharge[pPlayer] = pEntity;
            break;
        }
    }

    return HAM_HANDLED;
}

public HamHook_Player_PostThink_Post(pPlayer) {
    if (g_pPlayerPickupCharge[pPlayer] != -1) {
        if (ZP_Player_AddAmmo(pPlayer, ZP_AMMO_SATCHEL, 1)) {
            Deactivate(g_pPlayerPickupCharge[pPlayer]);

            if (!g_iPlayerChargeCount[pPlayer]) {
                new pActiveItem = get_member(pPlayer, m_pActiveItem);

                if (pActiveItem != 1 && CW_GetHandlerByEntity(pActiveItem) == g_iCwHandler) {
                    g_bPlayerRedeploy[pPlayer] = true;
                    set_member(pActiveItem, m_Weapon_flTimeWeaponIdle, 0.0);
                }

                g_bPlayerChargeReady[pPlayer] = false;
            }

            emessage_begin(MSG_ONE, gmsgAmmoPickup, _, pPlayer);
            ewrite_byte(ZP_Ammo_GetId(ZP_Ammo_GetHandler(ZP_AMMO_SATCHEL)));
            ewrite_byte(1);
            emessage_end();

            emit_sound(pPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        }

        g_pPlayerPickupCharge[pPlayer] = -1;
    }

    return HAM_HANDLED;
}
