#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_custom_events>
#include <api_custom_entities>
#include <api_custom_weapons>

#include <zombiepanic>
#include <zombiepanic_internal>

/*--------------------------------[ Players State ]--------------------------------*/

new Float:g_rgflPlayerNextLookup[MAX_PLAYERS + 1];
new g_rgpPlayerHoveredItem[MAX_PLAYERS + 1];
new bool:g_rgbPlayerPickup[MAX_PLAYERS + 1];
new g_rgiPlayerHoverBits = 0;

/*--------------------------------[ Plugin State ]--------------------------------*/

new bool:g_bBlockTouch = true;
new g_pTrace;
new Float:g_flGameTime = 0.0;

new bool:g_bEnabled;
new bool:g_bHighlight;
new Float:g_flPickupRange;
new g_rgiHighlightColor[3];

new g_pfwfmAddToFullPack = 0;
new HamHook:g_pfwhamPostThinkPost = HamHook:0;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_pTrace = create_tr2();

  CustomEvent_Register(USEPICKUP_EVENT(Hover), CEP_Cell, CEP_Cell);
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Use Pickup"), ZP_VERSION, "Hedgehog Fog");

  bind_pcvar_num(create_cvar(CVAR("use_pickup"), "1"), g_bEnabled);
  bind_pcvar_num(create_cvar(CVAR("use_pickup_highlight"), "1"), g_bHighlight);
  bind_pcvar_float(create_cvar(CVAR("use_pickup_range"), "64.0"), g_flPickupRange);
  bind_pcvar_num(create_cvar(CVAR("use_pickup_highlight_color_r"), "96"), g_rgiHighlightColor[0]);
  bind_pcvar_num(create_cvar(CVAR("use_pickup_highlight_color_g"), "64"), g_rgiHighlightColor[1]);
  bind_pcvar_num(create_cvar(CVAR("use_pickup_highlight_color_b"), "16"), g_rgiHighlightColor[2]);

  RegisterHamPlayer(Ham_Player_PreThink, "HamHook_Player_PreThink_Post", .Post = 1);
  g_pfwhamPostThinkPost = RegisterHamPlayer(Ham_Player_PostThink, "HamHook_Player_PostThink_Post", .Post = 1);

  CE_RegisterClassNativeMethodHook(ENTITY(WeaponBox), CE_Method_Touch, "CEHook_Item_Touch");
  CE_RegisterClassNativeMethodHook(CE_Class_BaseItem, CE_Method_Touch, "CEHook_Item_Touch");

  UpdateHooks();
}

public plugin_end() {
  free_tr2(g_pTrace);
}

public server_frame() {
  g_flGameTime = get_gametime();
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  g_rgpPlayerHoveredItem[pPlayer] = FM_NULLENT;
  g_rgbPlayerPickup[pPlayer] = false;
  g_rgflPlayerNextLookup[pPlayer] = 0.0;
}

public client_disconnected(pPlayer) {
  @Player_ClearHoveredItem(pPlayer);
}

/*--------------------------------[ Hooks ]--------------------------------*/

public FMHook_AddToFullPack_Post(const pState, const e, const pEntity, const pHost, const iHostFlags, const bool:bPlayer, const pSet) {
  if (!g_bEnabled) return FMRES_IGNORED;
  if (!g_bHighlight) return FMRES_IGNORED;
  if (!is_user_alive(pHost)) return FMRES_IGNORED;
  if (!pev_valid(pEntity)) return FMRES_IGNORED;

  if (pEntity == g_rgpPlayerHoveredItem[pHost]) {
    set_es(pState, ES_RenderMode, kRenderNormal);
    set_es(pState, ES_RenderFx, kRenderFxGlowShell);
    set_es(pState, ES_RenderAmt, 1);
    set_es(pState, ES_RenderColor, g_rgiHighlightColor);
  }

  return FMRES_HANDLED;
}

public CEHook_Item_Touch(const pEntity, const pToucher) {
  if (!IS_PLAYER(pToucher)) return CE_IGNORED;

  return g_bEnabled && g_bBlockTouch && !is_user_bot(pToucher) ? CE_SUPERCEDE : CE_HANDLED;
}

public HamHook_Item_Touch(const pEntity, const pToucher) {
  if (!IS_PLAYER(pToucher)) return HAM_IGNORED;

  return g_bEnabled && g_bBlockTouch && !is_user_bot(pToucher) ? HAM_SUPERCEDE : HAM_HANDLED;
}

public HamHook_Player_PreThink_Post(const pPlayer) {
  if (g_rgflPlayerNextLookup[pPlayer] <= g_flGameTime) {
    @Player_LookupItem(pPlayer);
    g_rgflPlayerNextLookup[pPlayer] = g_flGameTime + 0.125;
  }

  if (g_rgpPlayerHoveredItem[pPlayer] != FM_NULLENT) {
    g_rgbPlayerPickup[pPlayer] = pev(pPlayer, pev_button) & IN_USE && ~pev(pPlayer, pev_oldbuttons) & IN_USE;
  } else {
    g_rgbPlayerPickup[pPlayer] = false;
  }

  return HAM_HANDLED;
}

public HamHook_Player_PostThink_Post(const pPlayer) {
  if (!g_rgbPlayerPickup[pPlayer]) return HAM_IGNORED;
  if (g_rgpPlayerHoveredItem[pPlayer] == FM_NULLENT) return HAM_IGNORED;
  if (!pev_valid(g_rgpPlayerHoveredItem[pPlayer])) return HAM_IGNORED;

  g_bBlockTouch = false;
  ExecuteHamB(Ham_Touch, g_rgpPlayerHoveredItem[pPlayer], pPlayer);
  g_bBlockTouch = true;

  g_rgbPlayerPickup[pPlayer] = false;
  @Player_ClearHoveredItem(pPlayer);

  return HAM_HANDLED;
}

/*--------------------------------[ Player Methods ]--------------------------------*/

@Player_LookupItem(const &this) {
  if (!is_user_alive(this)) return FM_NULLENT;

  static pLastHoveredItem; pLastHoveredItem = g_rgpPlayerHoveredItem[this];

  @Player_ClearHoveredItem(this);

  static Float:vecAngles[3]; pev(this, pev_v_angle, vecAngles);
  static Float:vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
  static Float:vecSrc[3]; ExecuteHam(Ham_Player_GetGunPosition, this, vecSrc);
  static Float:vecEnd[3]; xs_vec_add_scaled(vecSrc, vecForward, g_flPickupRange, vecEnd);

  engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, this, g_pTrace);
  get_tr2(g_pTrace, TR_vecEndPos, vecEnd);

  static pEntity; pEntity = 0;
  while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecEnd, 1.0)) != 0) {
    if (!@Entity_IsUsableItem(pEntity, this)) continue;

    @Player_SetHoveredItem(this, pEntity);

    if (pEntity != pLastHoveredItem) {
      CustomEvent_SetActivator(this);
      CustomEvent_Emit(USEPICKUP_EVENT(Hover), this, pEntity);
    }

    return pEntity;
  }

  return FM_NULLENT;
}

@Player_SetHoveredItem(const &this, const &pEntity) {
  if (g_rgpPlayerHoveredItem[this] == pEntity) return;

  g_rgpPlayerHoveredItem[this] = pEntity;
  g_rgiPlayerHoverBits |= BIT(this);

  UpdateHooks();
}

@Player_ClearHoveredItem(const &this) {
  if (g_rgpPlayerHoveredItem[this] == FM_NULLENT) return;

  g_rgpPlayerHoveredItem[this] = FM_NULLENT;
  g_rgiPlayerHoverBits &= ~BIT(this);

  UpdateHooks();
}

/*--------------------------------[ Entity Methods ]--------------------------------*/

bool:@Entity_IsUsableItem(const &this, const &pPlayer) {
  if (pev(this, pev_solid) == SOLID_NOT) return false;
  if (~pev(this, pev_flags) & FL_ONGROUND) return false;
  if (!ZP_GameRules_CanPickupItem(this, pPlayer)) return false;

  if (CE_IsInstanceOf(this, CE_Class_BaseItem)) {
    return CE_CallNativeMethod(this, CE_Method_CanPickup, pPlayer);
  }

  if (CE_IsInstanceOf(this, ENTITY(SatchelCharge))) {
    static pRemote; pRemote = CW_PlayerFindWeapon(pPlayer, WEAPON(Satchel));
    if (pRemote == FM_NULLENT) return false;

    return CE_GetMember(this, SATCHELCHARGE_MEMBER(pRemote)) == pRemote;
  }

  static szClassname[CE_MAX_NAME_LENGTH]; pev(this, pev_classname, szClassname, charsmax(szClassname));

  if (equal(szClassname, ENTITY(WeaponBox))) return ZP_GameRules_CanPickupItem(this, pPlayer);
  if (equal(szClassname, "item_", 5)) return ZP_GameRules_CanPickupItem(this, pPlayer);

  return false;
}

/*--------------------------------[ Functions ]--------------------------------*/

UpdateHooks() {
  if (g_rgiPlayerHoverBits) {
    if (!g_pfwfmAddToFullPack) {
      g_pfwfmAddToFullPack = register_forward(FM_AddToFullPack, "FMHook_AddToFullPack_Post", 1);
    }

    EnableHamForward(g_pfwhamPostThinkPost);
  } else {
    if (g_pfwfmAddToFullPack) {
      unregister_forward(FM_AddToFullPack, g_pfwfmAddToFullPack, 1);
      g_pfwfmAddToFullPack = 0;
    }

    DisableHamForward(g_pfwhamPostThinkPost);
  }
}
