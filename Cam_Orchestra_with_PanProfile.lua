local r = reaper
-- [PanProfile] Integrated: uses per-leaf values from Cam_Orchestra_PanProfile.lua when APPLY_SEATING_PANS is enabled.

-- ========= USER CONFIG =========
local PLUGIN_CANDIDATES = {
  "VST3i: Kontakt 7 (Native Instruments GmbH)",
  "VST3i: Kontakt (Native Instruments GmbH)",
  "VSTi: Kontakt 7",
  "Kontakt 7",
}

-- Preset naming rules:
local PRESET_JOIN = " — "
local FAMILY_DEFAULT_SUFFIX = " — Default"

-- Grouping behavior
local GROUPS_AS_FOLDERS = true
local FLATTEN_SINGLE_ITEM_GROUPS = true

-- Whether to add Kontakt instances by default (UI can override)
local ADD_KONTAKT_DEFAULT = true

-- Mono input index for audio-only tracks (0 = first mono input)
local AUDIO_MONO_INPUT_INDEX = 0

-- Top-level category order and base hues
local CATEGORY_ORDER = { "STRINGS", "WOODWINDS", "BRASS", "PERC", "KEYS", "CHOIRS" }
local CATEGORY_BASE_HUE = {
  STRINGS   = 220,
  WOODWINDS = 180,
  BRASS     = 45,
  PERC      = 0,
  KEYS      = 300,
  CHOIRS    = 260,
}

-- Subcategory order inside each category
local SUBCAT_ORDER = { "Sections", "Solo", "Blends" }

-- ========= REVERB (ROUTING-ONLY) OPTIONS =========
-- Mode: 0 = Off, 1 = Global, 2 = Per-Category
local REVERB_MODE_DEFAULT = 0
-- Default send level to the reverb bus(es) in dB
local REVERB_DEFAULT_SEND_DB = -12.0
-- Create a small Reverbs folder under the root (used for Global mode)
local REVERB_FOLDER_NAME = "FX — Reverbs"
-- Prefix for reverb return tracks
local REVERB_PREFIX = "REV — "
-- Color for the Reverb folder/returns (teal-ish)
local REVERB_COLOR = {120, 170, 210}
-- If true, apply PanProfile-based pans on the created leaf tracks (not on sends)
local APPLY_SEATING_PANS_DEFAULT = false
-- Pan intensity multiplier (0..1), only used if seating pans are enabled
local PAN_INTENSITY_DEFAULT = 1.0

-- ========= FAMILIES =========
-- { category, subcat, engine="kontakt"|"audio", name, groups={...} }
local FAMILIES = {
  -- ====== BHCT (existing, kept) ======
  { category="STRINGS", subcat="Sections", engine="kontakt", name = "High strings", groups = {
      "Long","Long CS","Long CS Blend","Long Sul Pont","Long CS Sul Pont","Long Sul Tasto","Long Harmonics","Long Flautando",
      "Marcato Attack","Tremolo","Tremolo CS","Tremolo Sul Pont","Tremolo CS Sul Pont",
      "Trill (Major 2nd)","Trill (Major 3rd)","Trill (Minor 2nd)","Trill (Minor 3rd)","Trill (Perfect 4th)",
      "Short Spiccato","Short Brushed","Short Brushed CS","Short 0'5","Short 1'0","Short Spiccato CS",
      "Brushed Spiccato","Brushed Spiccato CS","Short Pizzicato","Short Harmonics","Short Pizzicato Bartok","Short Col Legno",
  }},
  { category="STRINGS", subcat="Sections", engine="kontakt", name = "High strings octaves", groups = {
      "Long","Long CS","Tremolo","Trill (Minor 2nd)","Trill (Major 2nd)","Short Spiccato","Legato fingered","Legato portamento",
  }},
  { category="STRINGS", subcat="Sections", engine="kontakt", name = "High strings, half section", groups = {
      "Legato","Legato Portamento","Long","Long CS","Long Flautando","Tremolo","Tremolo Sul Pont",
      "FX Cluster Slides","FX Cluster Stabs","FX Chatter","FX Cluster Swells","FX Cluster Swipes",
  }},
  { category="STRINGS", subcat="Sections", engine="kontakt", name = "Low strings", groups = {
      "Legato fingered","Long","Long CS","Long Sul Pont","Long CS Sul Pont","Long Flautando","Long Harmonics","Marcato Attack",
      "Tremolo","Tremolo CS","Tremolo Sul Pont","Tremolo CS Sul Pont","Short Spiccato","Short Pizzicato","Short Bartok","Short Col Legno",
      "FX 1 (Cluster Slides)","FX 2 (Chatter)","FX 3 (Cluster Swells)","FX 4 (Cluster Runs)",
  }},
  { category="STRINGS", subcat="Blends", engine="kontakt", name = "Low strings and horns", groups = {
      "Long","Long CS","Short","Short Pizzicato","Col Legno/Stopped",
  }},
  { category="STRINGS", subcat="Blends", engine="kontakt", name = "Low strings and trombones", groups = {
      "Legato","Long","Long CS","Long CS Sul Pont","Long Tremolo","Short","Short CS Sul Pont",
  }},
  { category="WOODWINDS", subcat="Sections", engine="kontakt", name = "Piccolo and flutes", groups = {
      "Legato","Long","Short",
  }},
  { category="WOODWINDS", subcat="Sections", engine="kontakt", name = "Concert flutes", groups = {
      "Legato","Long","Short","Trill (Minor 2nd)","Trill (Major 2nd)","Long Flutter","FX 1 (Rips)","FX 2 (Upper Mordent Major)","FX 3 (Upper Mordent Minor)",
  }},
  { category="WOODWINDS", subcat="Sections", engine="kontakt", name = "Mixed flutes", groups = {
      "Legato","Long","Short","Trill (Minor 2nd)","Trill (Major 2nd)","Long Flutter","FX 1","FX 2",
  }},
  { category="WOODWINDS", subcat="Blends", engine="kontakt", name = "Flutes and clarinets", groups = {
      { name = "Long", names = { "Long", "Long" } },
      "Long (Octave)","Short","Short (Octave)","Trill (Minor 2nd)","Trill (Major 2nd)",
  }},
  { category="WOODWINDS", subcat="Sections", engine="kontakt", name = "Low winds", groups = {
      "Legato","Long","Long (Octave)","Short","Short (Octave)",
  }},
  { category="WOODWINDS", subcat="Blends", engine="kontakt", name = "Cor anglais, clarinet and trumpet", groups = {
      "Long","Short","Trill (Minor 2nd)","Trill (Major 2nd)","FX (Chatter)",
  }},
  { category="WOODWINDS", subcat="Blends", engine="kontakt", name = "Oboes, bassoons and horns", groups = {
      "Long","Short","FX",
  }},
  { category="BRASS", subcat="Blends", engine="kontakt", name = "Trumpet and xylophone", groups = {
      "Long","Short","Short Muted","Long (Octave)","Short (Octave)","Short Muted (Octave)",
  }},
  { category="BRASS", subcat="Sections", engine="kontakt", name = "Horns", groups = { "Long","Short" }},
  { category="BRASS", subcat="Sections", engine="kontakt", name = "Mid brass", groups = {
      "Long","Short","FX 1 (Chatter)","FX 2 (Falls)",
  }},
  { category="BRASS", subcat="Sections", engine="kontakt", name = "Trombones", groups = {
      "Long","Long Muted","Short","Short Muted",
  }},
  { category="BRASS", subcat="Blends", engine="kontakt", name = "Trombones and timpani", groups = { "Long","Short" }},
  { category="KEYS", subcat="Blends", engine="kontakt", name = "Harp and celeste", groups = { "Long","Short" }},
  { category="KEYS", subcat="Blends", engine="kontakt", name = "Harp and vibraphone", groups = {
      "Long","Long Bowed","Short (Vibes On)","Short (Vibes Off)","Short Hotrods (Vibes Off)",
  }},
  { category="PERC", subcat="Sections", engine="kontakt", name = "Percussion", groups = {
      "Anvil","Bass Drum","Bongos","Bowed Cymbals","Brake Disks","Claves","Congas","Cymbals","Exhaust Pipe","Lion Roar","Ogororo","Quica",
      "Snare Drum (brushes)","Snare Drum (snares off)","Snare Drum (snares on)","Steel Plate","Temple Block","Timbales","Trash Can","Woodblock",
  }},
  { category="PERC", subcat="Sections", engine="kontakt", name = "Timpani", groups = {
      "Hard Stick Hit Damped","Hard Stick Hit Super Damped","Hard Stick Hit","Hard Stick Roll",
      "Hot Rod Hit Damped","Hot Rod Hit","Soft Stick Hit Damped","Soft Stick Hit","Soft Stick Roll",
  }},

  -- ====== KEPLER ORCHESTRA ======
  { category="STRINGS", subcat="Sections", engine="kontakt", name="High strings kepler", groups={
      "KEPLER grid","KEPLER muted grid","KEPLER sul pont grid","KEPLER muted tremolo grid","KEPLER momentum grid",
      "KEPLER pulsing momentum grid","KEPLER accelerating momentum grid","KEPLER shards grid",
  }},
  { category="STRINGS", subcat="Sections", engine="kontakt", name="Celli kepler", groups={
      "KEPLER grid","KEPLER muted grid","KEPLER sul pont grid","KEPLER muted tremolo grid","KEPLER momentum grid",
      "KEPLER pulsing momentum grid","KEPLER accelerating momentum grid","KEPLER shards grid","KEPLER dopplers grid","KEPLER non pulsing dopplers grid",
  }},
  { category="BRASS", subcat="Sections", engine="kontakt", name="High brass kepler", groups={
      "KEPLER grid","KEPLER momentum grid","KEPLER pulsing momentum grid","KEPLER accelerating momentum grid","KEPLER shards grid",
  }},
  { category="BRASS", subcat="Sections", engine="kontakt", name="Low brass kepler", groups={
      "KEPLER grid","KEPLER momentum grid","KEPLER pulsing momentum grid","KEPLER accelerating momentum grid","KEPLER shards grid",
      "KEPLER dopplers grid","KEPLER non pulsing dopplers grid",
  }},
  { category="STRINGS", subcat="Sections", engine="kontakt", name="Basses kepler", groups={
      "KEPLER grid","KEPLER pizzicato grid","KEPLER col legno grid","KEPLER tremolo grid","KEPLER momentum grid","KEPLER harmonics grid",
      "KEPLER tremolo harmonics grid","KEPLER shards grid","KEPLER dopplers grid",
  }},
  { category="WOODWINDS", subcat="Sections", engine="kontakt", name="Woodwinds kepler", groups={
      "KEPLER grid","KEPLER momentum grid","KEPLER accelerating momentum grid","KEPLER shards grid",
  }},

  -- ====== RINASCIMENTO (solo medieval instruments) ======
  { category="BRASS", subcat="Solo", engine="kontakt", name="Renaissance trombone", groups={ "Legato","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Soprano Cornett", groups={ "Sustain","Vibrato","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Recorder", groups={ "Legato","Vibrato","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Bass recorder", groups={ "Vibrato","Sustain" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Sopranino recorder", groups={ "Vibrato","Sustain","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Soprano recorder", groups={ "Vibrato","Sustain","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Tabor pipe", groups={ "Vibrato","Sustain" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Tenor recorder", groups={ "Sustain","Vibrato","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Traversiere", groups={ "Sustain","Vibrato","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Alto crumhorn", groups={ "Sustain","Vibrato","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Bass crumhorn", groups={ "Sustain","Vibrato","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Tenor crumhorn", groups={ "Sustain","Vibrato","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Bombarde", groups={ "Sustain","Staccato","Polyphonic" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Ciaramello soprano", groups={ "Sustain","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Dulciana", groups={ "Staccato","Legato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Rauschpfeife", groups={ "Sustain","Staccato" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Zampogna", groups={ "Legato","Alt Legato" }},
  { category="STRINGS", subcat="Solo", engine="kontakt", name="Hurdy gurdy", groups={ "Legato","Alt Legato" }},
  { category="STRINGS", subcat="Solo", engine="kontakt", name="Vielle", groups={ "Legato","Poly Legato" }},
  { category="STRINGS", subcat="Solo", engine="kontakt", name="Viola da gamba", groups={ "Legato","Poly Legato","Staccato" }},
  { category="KEYS", subcat="Sections", engine="kontakt", name="Medieval keys", groups={
      "Harpsichord Main","Harpsichord Second","Positive Organ","Virginal",
  }},
  { category="KEYS", subcat="Sections", engine="kontakt", name="Medieval organ", groups={
      "Main","Cornetto","Octave","Trumpet","8842","Vox Humana","Mezzo Ripieno","Flute","Bass 8","cl/vc/fl","Double Bass",
  }},
  { category="PERC", subcat="Sections", engine="kontakt", name="Medieval percussion", groups={
      "Egyptian Darbuka","Raqs Sharqi Shakers","Natural Seashells","Crotales (Finger Cymbals)","Wide Bass Drum","Renaissance Bass Drum",
      "Renaissance Snare","Frame Drum","Long Shell Drum","Wood Hit","Handclap",
  }},

  -- ====== APERTURE STRINGS ======
  { category="STRINGS", subcat="Sections", engine="kontakt", name="Aperture ensemble", groups={
      "Long","Long CS","Long Flautando","Long Harmonics","Short Col Legno","Short Col Pizzicato","Short Spiccato","Tremolo",
  }},
  { category="STRINGS", subcat="Sections", engine="kontakt", name="Pinhole ensemble", groups={
      "Long","Long CS","Long Flautando","Long Harmonics","Short Col Legno","Short Col Pizzicato","Short Spiccato","Tremolo",
  }},
  { category="STRINGS", subcat="Sections", engine="kontakt", name="Refractions", groups={
      "Tremolo","Normale","Harmonics","Flautando","Con Sordino",
  }},

  -- ====== BRITISH DRAMA TOOLKIT ======
  { category="WOODWINDS", subcat="Sections", engine="kontakt", name="Flutes and piccolo", groups={
      "Long","Long Soft","Long Soft Alt","Long Chiffs","Long Alt",
  }},
  { category="STRINGS", subcat="Sections", engine="kontakt", name="String ensemble", groups={
      "Long","Long Accented","Long Soft","Long Loud Accented",
  }},
  { category="WOODWINDS", subcat="Sections", engine="kontakt", name="Woodwind ensemble", groups={
      "Long","Long Soft",
  }},
  { category="STRINGS", subcat="Blends", engine="kontakt", name="Strings and woodwinds", groups={
      "Long Soft Accented Texture","Long Loud Accented Texture","Soft Alt",
      "Loud Texture Strings Dominant","Soft Texture Strings Dominant","Soft Texture Woodwinds Dominant",
      "Loud Texture Woodwinds Dominant","Long Loud Strings Dominant","Long Loud Woodwinds Dominant","Long Soft",
  }},
  { category="STRINGS", subcat="Solo", engine="kontakt", name="Violin", groups={ "Long","Long Accented","Long Soft","Long Loud","Long Harmonics" }},
  { category="STRINGS", subcat="Solo", engine="kontakt", name="Viola", groups={ "Long","Long Accented","Long Soft","Long Loud","Long Harmonics" }},
  { category="STRINGS", subcat="Solo", engine="kontakt", name="Cello", groups={ "Long","Long Accented","Long Soft","Long Loud","Long Harmonics" }},
  { category="STRINGS", subcat="Solo", engine="kontakt", name="Double bass", groups={
      "Long Accented Alt","Long Accented","Long Alt","Long Harmonics","Long Loud","Long Soft Alt","Long Soft","Long",
  }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Flute", groups={ "Long","Long Soft","Long Alt","Long Loud","Long Chiffs","Long Soft Alt" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Piccolo", groups={ "Long","Long Soft","Long Alt","Long Loud","Long Chiffs","Long Soft Alt" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Clarinet", groups={ "Long","Long Soft","Long Loud","Long Chatter" }},
  { category="WOODWINDS", subcat="Solo", engine="kontakt", name="Bass clarinet", groups={ "Long","Long Soft","Long Loud","Long Chatter" }},

  -- ====== THE ORCHESTRA COMPLETE 3 ======
  { category="CHOIRS", subcat="Sections", engine="kontakt", name="Choir", groups={
      "Elven Sustain Vowels","Female Shouts","Female Staccato","Female Sustain","Female Whispers","Male Shouts","Male Staccato","Male Sustain",
  }},
  { category="KEYS", subcat="Sections", engine="kontakt", name="Organ manual", groups={
      "Toccata","Mixture","Flute","Bourdon","Chorus","Tutti","Principal","Plenum","Diaposon","Octave",
  }},
  { category="KEYS", subcat="Sections", engine="kontakt", name="Organ pedal", groups={
      "Tutti","Plenum","Mixture","Subbass","Reed",
  }},

  -- ====== SWAM (audio tracks) ======
  { category="STRINGS", subcat="Solo", engine="audio", name="Swam strings (Solo)", groups={
      "Swam violin solo","Swam cello solo","Swam viola solo","Swam double bass solo",
  }},
  { category="STRINGS", subcat="Sections", engine="audio", name="Swam strings (Section)", groups={
      "Swam violin section","Swam cello section","Swam viola section","Swam double bass section",
  }},
  { category="WOODWINDS", subcat="Solo", engine="audio", name="Swam woodwinds", groups={
      "Swam flute","Swam oboe","Swam tenor sax","Swam bass flute","Swam clarinet",
  }},
  { category="BRASS", subcat="Solo", engine="audio", name="Swam horns", groups={ "Swam bass trombone" }},

  -- ====== NAADA (audio tracks) ======
  { category="WOODWINDS", subcat="Solo", engine="audio", name="Naada winds", groups={
      "Naada bansuri","Naada duduk","Naada pan flute","Naada nadaswaram","Naada dizi","Naada shehnai","Naada guan","Naada suona","Naada bass clarinet",
  }},
  { category="STRINGS", subcat="Solo", engine="audio", name="Naada strings", groups={
      "Naada carnatic violin","Naada sitar","Naada sarangi","Naada saraswati veena","Naada sarod","Naada cello","Naada viola","Naada pipa",
      "Naada erhu","Naada gaohu","Naada zhonghu","Naada double bass",
  }},

  -- ====== CAM-BASED AUDIO ======
  { category="CHOIRS", subcat="Sections", engine="audio", name="Cam Choir", groups={
      "Soprano (Cam)","Alto (Cam)","Tenor (Cam)","Bass (Cam)",
  }},
}

-- ========= HELPERS =========
local HAS_JS  = r.APIExists and r.APIExists("JS_Window_Find")
local HAS_SWS = r.APIExists and r.APIExists("BR_Win32_GetWindowRect")
local HAS_IMGUI = (reaper and reaper.ImGui_CreateContext) and true or false

local function toNativeColor(r_, g_, b_) return r.ColorToNative(r_, g_, b_) | 0x1000000 end
local function clamp(x, a, b) if x < a then return a elseif x > b then return b else return x end end

-- HSL -> RGB
local function hslToRgb(h, s, l)
  h = (h % 360) / 360
  s = clamp(s,0,1); l = clamp(l,0,1)
  local function hue2rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1/6 then return p + (q - p) * 6 * t end
    if t < 1/2 then return q end
    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
    return p
  end
  local r_, g_, b_
  if s == 0 then
    r_, g_, b_ = l, l, l
  else
    local q = l < 0.5 and l * (1 + s) or (l + s - l * s)
    local p = 2 * l - q
    r_ = hue2rgb(p, q, h + 1/3)
    g_ = hue2rgb(p, q, h)
    b_ = hue2rgb(p, q, h - 1/3)
  end
  return math.floor(r_ * 255 + 0.5), math.floor(g_ * 255 + 0.5), math.floor(b_ * 255 + 0.5)
end

local function colorFromHue(baseHue, itemIndex, itemCount)
  local sat = 0.45
  local lightBase = 0.62
  local lightStep = 0.9 * (itemIndex-1) / math.max(1,(itemCount-1)) * 0.22
  local l = clamp(lightBase - lightStep, 0.35, 0.8)
  local r_,g_,b_ = hslToRgb(baseHue, sat, l)
  return {r_, g_, b_}
end

local function colorFromCategory(cat, itemIndex, itemCount)
  local hue = CATEGORY_BASE_HUE[cat] or 200
  return colorFromHue(hue, itemIndex, itemCount)
end

local function colorTrack(tr, rgb) if rgb then r.SetTrackColor(tr, toNativeColor(rgb[1], rgb[2], rgb[3])) end end

local function insertTrack(idx, name, folderDepth, rgb, opts)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  if folderDepth then r.SetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH", folderDepth) end
  colorTrack(tr, rgb)
  if (folderDepth or 0) == 0 then
    r.SetMediaTrackInfo_Value(tr, "I_RECARM", 0)
    r.SetMediaTrackInfo_Value(tr, "I_RECMON", 1)
    r.SetMediaTrackInfo_Value(tr, "I_RECMODE", 0)
    local inputMode = opts and opts.input or "midi"
    if inputMode == "midi" then
      r.SetMediaTrackInfo_Value(tr, "I_RECINPUT", 4096) -- MIDI: All
    elseif inputMode == "audio_mono" then
      r.SetMediaTrackInfo_Value(tr, "I_RECINPUT", AUDIO_MONO_INPUT_INDEX or 0) -- mono audio input index
    end
    r.SetMediaTrackInfo_Value(tr, "I_RECMONITEMS", 1)
    r.SetMediaTrackInfo_Value(tr, "B_FREEMODE", 1)    -- FIPM
  end
  return tr
end

local function addFolderDelta(tr, delta)
  local cur = r.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH") or 0
  r.SetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH", cur + delta)
end

local function closeFXUI(tr, fx)
  if r.TrackFX_SetOpen then r.TrackFX_SetOpen(tr, fx, false) end
  if r.TrackFX_Show then r.TrackFX_Show(tr, fx, 0) end
end

local function placeFXTopRight(hwnd)
  if not hwnd then return end
  local margin = 20
  if HAS_JS then
    local _, ml, mt, mr, mb = r.JS_Window_GetRect(r.GetMainHwnd())
    local _, l, t, rgt, btm = r.JS_Window_GetRect(hwnd)
    local w, h = (rgt - l), (btm - t)
    local x = (mr - ml) - w - margin + ml
    local y = mt + margin
    r.JS_Window_Move(hwnd, x, y)
  elseif HAS_SWS then
    local ml, mt, mr, mb = r.BR_Win32_GetWindowRect(r.GetMainHwnd())
    local l, t, rgt, btm = r.BR_Win32_GetWindowRect(hwnd)
    local w, h = (rgt - l), (btm - t)
    local x = (mr - ml) - w - margin + ml
    private_y = mt + margin
    r.BR_Win32_SetWindowPos(hwnd, x, private_y, w, h, true)
  end
end

local function addKontaktFX(tr)
  for _, name in ipairs(PLUGIN_CANDIDATES) do
    local fx = r.TrackFX_AddByName(tr, name, false, 1)
    if fx and fx >= 0 then closeFXUI(tr, fx); return fx end
  end
  for _, name in ipairs(PLUGIN_CANDIDATES) do
    local fx = r.TrackFX_AddByName(tr, name, false, -1)
    if fx and fx >= 0 then closeFXUI(tr, fx); return fx end
  end
  return -1
end

local function tryPreset(tr, fx, name)
  if not name or name=="" or fx < 0 then return false end
  return r.TrackFX_SetPreset(tr, fx, name)
end

local function loadPreset(tr, fx, familyName, articulationName)
  local famTrack = familyName .. PRESET_JOIN .. articulationName
  if tryPreset(tr, fx, famTrack) then return "family+art" end
  if tryPreset(tr, fx, articulationName) then return "art" end
  local famDefault = familyName .. FAMILY_DEFAULT_SUFFIX
  if tryPreset(tr, fx, famDefault) then return "family" end
  return "none"
end

local function setKontaktDefaultPos(tr, fx)
  if fx < 0 then return end
  r.TrackFX_Show(tr, fx, 2)
  local hwnd = r.TrackFX_GetFloatingWindow(tr, fx)
  if hwnd then placeFXTopRight(hwnd) end
  closeFXUI(tr, fx)
end

local function normalize_group(grp)
  if type(grp) == "string" then
    return grp, { grp }
  elseif type(grp) == "table" then
    local label = grp.name or (grp.names and grp.names[1]) or "Group"
    local names = grp.names or {}
    return label, names
  else
    return "Group", {}
  end
end

-- db -> amplitude
local function dbToAmp(db)
  return 10 ^ (db / 20)
end
-- ========= PAN PROFILE (External) =========
-- Looks for 'Cam_Orchestra_PanProfile.lua' next to this script, falls back gracefully.
local function _get_script_dir()
  if reaper and reaper.get_action_context then
    local ok, script_file = pcall(function()
      local _, fp = reaper.get_action_context()
      return fp
    end)
    if ok and type(script_file) == "string" then
      return (script_file:match("^(.*[\\/])") or "")
    end
  end
  -- Fallback using debug info
  local src = debug and debug.getinfo and debug.getinfo(1, 'S')
  local p = src and src.source or ""
  p = p:gsub("^@", "")
  return (p:match("^(.*[\\/])") or "")
end

local function _load_pan_profile()
  local dir = _get_script_dir()
  local candidates = {
    dir .. "Cam_Orchestra_PanProfile.lua",
    dir .. "PanProfile.lua",
  }
  for _,path in ipairs(candidates) do
    local ok, tbl = pcall(dofile, path)
    if ok and type(tbl) == "table" and type(tbl.leaf) == "table" then
      return tbl
    end
  end
  return { family_default_pan = {}, leaf = {} }
end

local _PANPROFILE = _load_pan_profile()

local function get_profile_pan(familyName, artName)
  if not familyName or not artName then return nil end
  local key = (tostring(familyName) or "") .. "|" .. (tostring(artName) or "")
  local v = _PANPROFILE.leaf[key]
  if v == nil then v = _PANPROFILE.family_default_pan[familyName] end
  return v
end





-- ========= BUILD CORE =========
-- per_pan_modes is a table keyed by original family index: 0=inherit, 1=force on, 2=force off
local function build_selected(selected_indices, add_kontakt, rev_mode, rev_send_db, apply_pans, pan_intensity, per_pan_modes)
  r.Undo_BeginBlock()
  add_kontakt = (add_kontakt ~= false)
  rev_mode = rev_mode or 0
  rev_send_db = rev_send_db or REVERB_DEFAULT_SEND_DB
  apply_pans = apply_pans or false
  pan_intensity = pan_intensity or 1.0
  per_pan_modes = per_pan_modes or {}

  local base = r.GetNumTracks()
  local rootColor = {92,105,180}
  insertTrack(base, "Cam Orchestra", 1, rootColor)
  local idx = base + 1

  -- Group selection by category/subcat
  local chosen = {}
  for _,i in ipairs(selected_indices) do
    local f = FAMILIES[i]
    -- remember original index for per-family pan override lookup
    f._index = i
    chosen[f.category] = chosen[f.category] or {}
    chosen[f.category][f.subcat] = chosen[f.category][f.subcat] or {}
    table.insert(chosen[f.category][f.subcat], f)
  end

  -- Keep track of created leaf tracks per category for reverb sends/pans
  local leaves_by_cat = {}
  local function remember_leaf(cat, tr, famName)
    leaves_by_cat[cat] = leaves_by_cat[cat] or {}
    table.insert(leaves_by_cat[cat], { tr = tr, fam = famName })
  end

  local last_of_root = nil

  for _,cat in ipairs(CATEGORY_ORDER) do
    local subcats = chosen[cat]
    if subcats then
      local catColor = colorFromCategory(cat, 1, 1)
      insertTrack(idx, cat, 1, catColor); idx = idx + 1
      local last_of_cat = nil

      for _,sub in ipairs(SUBCAT_ORDER) do
        local fams = subcats[sub]
        if fams and #fams > 0 then
          local subColor = colorFromCategory(cat, 2, 3)
          insertTrack(idx, cat .. " — " .. sub, 1, subColor); idx = idx + 1
          local last_of_sub = nil

          table.sort(fams, function(a,b) return a.name:lower() < b.name:lower() end)

          local totalLeaves = 0
          for _, family in ipairs(fams) do
            for _, grp in ipairs(family.groups) do
              local _, names = normalize_group(grp)
              totalLeaves = totalLeaves + #names
            end
          end
          local leafIdx = 1

          for fi, family in ipairs(fams) do
            local famColor = colorFromCategory(cat, fi, #fams)
            insertTrack(idx, family.name, 1, famColor); idx = idx + 1
            local last_of_family = nil

            -- Decide panning for this family (inherit from global unless overridden)
            local pan_mode = per_pan_modes[family._index] or 0 -- 0 inherit, 1 on, 2 off
            local pan_for_family = (pan_mode == 1) or (pan_mode == 0 and apply_pans)

            for _, grp in ipairs(family.groups) do
              local gLabel, names = normalize_group(grp)
              local makeGroupFolder = GROUPS_AS_FOLDERS and (not FLATTEN_SINGLE_ITEM_GROUPS or #names > 1)
              local last_of_group = nil

              if makeGroupFolder then
                insertTrack(idx, family.name .. PRESET_JOIN .. gLabel, 1, famColor); idx = idx + 1
              end

              for _, art in ipairs(names) do
                local trColor = colorFromHue((CATEGORY_BASE_HUE[cat] or 200), leafIdx, math.max(1,totalLeaves))
                local opts = { input = (family.engine == "audio") and "audio_mono" or "midi" }
                local tr = insertTrack(idx, art, 0, trColor, opts); idx = idx + 1

                -- optional seating pan on the track itself (not on sends)
                if pan_for_family then
                  local prof = get_profile_pan(family.name, art); local p = (prof or 0.0) * pan_intensity
                  r.SetMediaTrackInfo_Value(tr, "D_PAN", p)
                end

                if family.engine ~= "audio" and add_kontakt then
                  local fx = addKontaktFX(tr)
                  if fx >= 0 then
                    loadPreset(tr, fx, family.name, art)
                    setKontaktDefaultPos(tr, fx)
                  end
                end

                remember_leaf(cat, tr, family.name)

                last_of_group  = tr
                last_of_family = tr
                last_of_sub    = tr
                last_of_cat    = tr
                last_of_root   = tr
                leafIdx = leafIdx + 1
              end

              if makeGroupFolder and last_of_group then addFolderDelta(last_of_group, -1) end
            end

            if last_of_family then addFolderDelta(last_of_family, -1) end
          end

          if last_of_sub then addFolderDelta(last_of_sub, -1) end
        end
      end

      -- If per-category reverb is enabled, add a reverb return under the category and wire sends now
      if rev_mode == 2 and leaves_by_cat[cat] and #leaves_by_cat[cat] > 0 then
        local revName = REVERB_PREFIX .. cat
        local revTr = insertTrack(idx, revName, 0, REVERB_COLOR); idx = idx + 1
        -- create sends (post-fader, post-pan) at default level
        local sendVol = dbToAmp(rev_send_db)
        for _, leaf in ipairs(leaves_by_cat[cat]) do
          local sendIdx = r.CreateTrackSend(leaf.tr, revTr)
          -- 0 = post-fader (post-pan)
          r.SetTrackSendInfo_Value(leaf.tr, 0, sendIdx, "I_SENDMODE", 0)
          r.SetTrackSendInfo_Value(leaf.tr, 0, sendIdx, "D_VOL", sendVol)
          -- keep send pan centered; panning lives on source track
          r.SetTrackSendInfo_Value(leaf.tr, 0, sendIdx, "D_PAN", 0.0)
        end
        -- ensure the category folder closes after the reverb track
        last_of_cat = revTr
        last_of_root = revTr
      end

      if last_of_cat then addFolderDelta(last_of_cat, -1) end
    end
  end

  -- If Global reverb is enabled, add a small Reverbs folder with one return and wire every leaf
  if rev_mode == 1 then
    local revFolder = insertTrack(idx, REVERB_FOLDER_NAME, 1, REVERB_COLOR); idx = idx + 1
    local revTr = insertTrack(idx, REVERB_PREFIX .. "Global", 0, REVERB_COLOR); idx = idx + 1

    local sendVol = dbToAmp(rev_send_db)
    for cat, arr in pairs(leaves_by_cat) do
      for _, leaf in ipairs(arr) do
        local sendIdx = r.CreateTrackSend(leaf.tr, revTr)
        r.SetTrackSendInfo_Value(leaf.tr, 0, sendIdx, "I_SENDMODE", 0) -- post-fader (post-pan)
        r.SetTrackSendInfo_Value(leaf.tr, 0, sendIdx, "D_VOL", sendVol)
        r.SetTrackSendInfo_Value(leaf.tr, 0, sendIdx, "D_PAN", 0.0) -- pan on the track, not the send
      end
    end

    -- close Reverbs folder
    addFolderDelta(revTr, -1)
    last_of_root = revTr
  end

  if last_of_root then addFolderDelta(last_of_root, -1) end

  r.TrackList_AdjustWindows(false)
  local mode = add_kontakt and "Kontakt ON" or "Kontakt OFF"
  r.Undo_EndBlock("Build Cam Orchestra — Modular by Category: "..mode.." + Colors + FIPM + Inputs + Reverb routing + Modular Pans", -1)
end

-- ========= UI (ReaImGui) =========
if HAS_IMGUI then
  local ctx = r.ImGui_CreateContext('Cam Orchestra — Select families')
  local FONT = r.ImGui_CreateFont('sans-serif', 16)
  r.ImGui_Attach(ctx, FONT)

  local DestroyContext = r.ImGui_DestroyContext or function(_) end
  local W_NoCollapse = (r.ImGui_WindowFlags_NoCollapse and r.ImGui_WindowFlags_NoCollapse()) or 0
  local W_None       = (r.ImGui_WindowFlags_None and r.ImGui_WindowFlags_None()) or 0

  local function BeginChildCompat(id, w, h, wantBorder, flags)
    wantBorder = (wantBorder ~= false)
    flags = flags or W_None
    local ok, ret = pcall(r.ImGui_BeginChild, ctx, id, w, h, wantBorder, flags)
    if ok then return ret end
    return r.ImGui_BeginChild(ctx, id, w, h, flags)
  end

  -- Compatibility wrappers for float/double widgets across ReaImGui versions
  local DragNumber = r.ImGui_DragDouble or r.ImGui_DragDouble
  local SliderNumber = r.ImGui_SliderDouble or r.ImGui_SliderDouble
  local InputNumber = r.ImGui_InputDouble or r.ImGui_InputFloat
  local function DragNumberCompat(label, value, speed, vmin, vmax, fmt)
    if DragNumber then
      return DragNumber(ctx, label, value, speed or 0.1, vmin, vmax, fmt)
    end
    if InputNumber then
      r.ImGui_SetNextItemWidth(ctx, 160)
      local changed
      changed, value = InputNumber(ctx, label, value, 0, 0, fmt or '%.3f')
      return changed, value
    end
    return false, value
  end
  local function SliderNumberCompat(label, value, vmin, vmax, fmt)
    if SliderNumber then
      return SliderNumber(ctx, label, value, vmin, vmax, fmt)
    end
    return DragNumberCompat(label, value, 0.01, vmin, vmax, fmt)
  end

  local open = true
  local filter = ''
  local states = {}
  for i=1,#FAMILIES do states[i] = false end
  local ui_add_kontakt = ADD_KONTAKT_DEFAULT

  -- Reverb UI state
  local ui_rev_mode = REVERB_MODE_DEFAULT -- 0 Off, 1 Global, 2 Per-Category
  local ui_rev_send_db = REVERB_DEFAULT_SEND_DB

  -- Global pan default + per-family overrides
  local ui_apply_pans = APPLY_SEATING_PANS_DEFAULT
  local ui_pan_intensity = PAN_INTENSITY_DEFAULT
  -- 0 = inherit, 1 = on, 2 = off
  local pan_modes = {}
  for i=1,#FAMILIES do pan_modes[i] = 0 end

  local cat_rank = {}
  for i,cat in ipairs(CATEGORY_ORDER) do cat_rank[cat] = i end
  local sub_rank = {}
  for i,sub in ipairs(SUBCAT_ORDER) do sub_rank[sub] = i end

  local function pass_filter(cat, sub, name)
    if filter == '' then return true end
    local hay = (cat .. " " .. sub .. " " .. name):lower()
    return hay:find(filter:lower(), 1, true) ~= nil
  end

  local function run_ui()
    if not open then return end

    r.ImGui_SetNextWindowSize(ctx, 820, 760, r.ImGui_Cond_Appearing and r.ImGui_Cond_Appearing() or 0)
    local visible, show = r.ImGui_Begin(ctx, 'Cam Orchestra — Select families', true, W_NoCollapse)

    if visible then
      r.ImGui_Text(ctx, 'Pick families to add (filter by category/name):')
      r.ImGui_SameLine(ctx)
      if r.ImGui_Button(ctx, 'All') then for i=1,#FAMILIES do states[i] = true end end
      r.ImGui_SameLine(ctx)
      if r.ImGui_Button(ctx, 'None') then for i=1,#FAMILIES do states[i] = false end end

      r.ImGui_SameLine(ctx)
      r.ImGui_SetNextItemWidth(ctx, 260)
      local changed; changed, filter = r.ImGui_InputText(ctx, ' Filter', filter)

      r.ImGui_Separator(ctx)

      do
        local clicked; clicked, ui_add_kontakt = r.ImGui_Checkbox(ctx, "Add Kontakt instances", ui_add_kontakt)
        r.ImGui_SameLine(ctx)
        r.ImGui_TextDisabled(ctx, "(audio families ignore this)")
      end

      r.ImGui_Separator(ctx)

      -- Reverb routing controls
      r.ImGui_Text(ctx, 'Reverb routing (no FX added):')
      r.ImGui_SameLine(ctx)
      r.ImGui_TextDisabled(ctx, 'sends are post-fader/post-pan; pans live on tracks')

      r.ImGui_SetNextItemWidth(ctx, 260)
      local items = 'Off\0Global (one return)\0Per Category (STRINGS/WW/BRASS/etc.)\0\0'
      local selChanged; selChanged, ui_rev_mode = r.ImGui_Combo(ctx, ' Mode', ui_rev_mode, items)

      r.ImGui_SameLine(ctx)
      r.ImGui_SetNextItemWidth(ctx, 200)
      local lvChanged; lvChanged, ui_rev_send_db = DragNumberCompat( ' Default send (dB)', ui_rev_send_db, 0.1, -48.0, 6.0, '%.1f dB')

      r.ImGui_Separator(ctx)

      -- Global pan defaults
      local pansChanged; pansChanged, ui_apply_pans = r.ImGui_Checkbox(ctx, 'Apply seating pans on tracks (default)', ui_apply_pans)
      r.ImGui_SameLine(ctx)
      r.ImGui_SetNextItemWidth(ctx, 180)
      local piChanged; piChanged, ui_pan_intensity = SliderNumberCompat( ' Pan intensity', ui_pan_intensity, 0.0, 1.0, '%.2f')

      r.ImGui_Separator(ctx)

      BeginChildCompat('list', 0, -120, true, W_None)
      -- Build sorted view: Category > Subcategory > Name
      local view = {}
      for i, fam in ipairs(FAMILIES) do
        if pass_filter(fam.category, fam.subcat, fam.name) then
          view[#view+1] = { i=i, fam=fam }
        end
      end
      table.sort(view, function(a,b)
        local ac = cat_rank[a.fam.category] or 999
        local bc = cat_rank[b.fam.category] or 999
        if ac ~= bc then return ac < bc end
        local as = sub_rank[a.fam.subcat] or 999
        local bs = sub_rank[b.fam.subcat] or 999
        if as ~= bs then return as < bs end
        return a.fam.name:lower() < b.fam.name:lower()
      end)

      for _, item in ipairs(view) do
        local fam = item.fam
        local idxv = item.i
        local c = states[idxv]
        local label = string.format("%s › %s — %s##%d", fam.category, fam.subcat, fam.name, idxv)
        local clicked; clicked, c = r.ImGui_Checkbox(ctx, label, c)
        if clicked then states[idxv] = c end

        r.ImGui_SameLine(ctx)
        r.ImGui_TextDisabled(ctx, "Pan:")
        r.ImGui_SameLine(ctx)
        r.ImGui_SetNextItemWidth(ctx, 140)
        local comboItems = 'Inherit\0On\0Off\0\0'
        local pmChanged; pmChanged, pan_modes[idxv] = r.ImGui_Combo(ctx, ('##pan_%d'):format(idxv), pan_modes[idxv], comboItems)
      end
      r.ImGui_EndChild(ctx)

      r.ImGui_Separator(ctx)

      if r.ImGui_Button(ctx, 'Build', 160, 30) then
        local sel = {}
        local per_pan = {}
        for i,v in ipairs(states) do if v then sel[#sel+1]=i end end
        if #sel == 0 then
          r.MB("Pick at least one family.", "Cam Orchestra", 0)
        else
          for _,i in ipairs(sel) do per_pan[i] = pan_modes[i] or 0 end
          open = false
          r.ImGui_End(ctx)
          DestroyContext(ctx)
          build_selected(sel, ui_add_kontakt, ui_rev_mode, ui_rev_send_db, ui_apply_pans, ui_pan_intensity, per_pan)
          return
        end
      end

      r.ImGui_SameLine(ctx)
      if r.ImGui_Button(ctx, 'Cancel', 140, 30) then
        open = false
      end
    end

    if visible then r.ImGui_End(ctx) end
    if show == false or open == false then
      DestroyContext(ctx)
      return
    end

    r.defer(run_ui)
  end

  r.defer(run_ui)

else
  -- Fallback: build everything with defaults
  -- local all = {}
  -- for i=1,#FAMILIES do all[#all+1] = i end
  -- build_selected(all, ADD_KONTAKT_DEFAULT, REVERB_MODE_DEFAULT, REVERB_DEFAULT_SEND_DB, APPLY_SEATING_PANS_DEFAULT, PAN_INTENSITY_DEFAULT, {})
end
