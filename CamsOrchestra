-- Cam Orchestra builder (Kontakt 7). Section folders + logical orchestral order.
-- KEPLER items are merged in-place in their appropriate sections.
-- Root renamed to "Cam Orchestra" (made unique if needed).
-- Adds a global "Reverb" track as last child of root and auto-creates post-fader sends from leaf tracks.
-- v3.3a: Same as v3.3 but **no ImGui_Columns** (compat for older ReaImGui). Uses two side-by-side Child panes.

local r = reaper

-- ========= VERSION / NAMESPACE =========
local VERSION = "3.3a"
local EXT_NS  = "CamOrchestra"
r.SetExtState(EXT_NS, "version", VERSION, true)

-- ========= OPTIONS =========
local ADD_FX_WHEN_BUILDING = true   -- toggle to insert Kontakt on leaves
local DEFAULT_MIDI_INPUT   = 4096   -- All MIDI (Omni)
local DEFAULT_MONITOR      = 1      -- Monitor on
local DEFAULT_RECARM       = 0      -- Not armed
local DEFAULT_RECMODE      = 0      -- 0: Record: input, 16: MIDI overdub, 7: Record: output
local DEFAULT_SEND_LEVEL   = -12    -- dB for sends to "Reverb"
local AUTO_SCALE_REVERB    = false  -- gently adjust reverb send based on leaf count
local COLLAPSE_AFTER_BUILD = true   -- minimize folders after build
local POSITION_FX_WINDOWS  = true   -- float Kontakt briefly at top-right, then close

-- Optional per-family overrides (leave empty or nil for defaults)
local FAMILY_MIDI_INPUT    = {}     -- [familyName] = reaper MIDI input int (e.g., 4096 for Omni)
local FAMILY_SEND_OFFSET_DB= {}     -- [familyName] = additional dB offset to reverb send (e.g., -3)

-- ========= USER CONFIG =========
local PLUGIN_CANDIDATES = {
  -- VST3 / VST
  "VST3i: Kontakt 7 (Native Instruments GmbH)",
  "VST3i: Kontakt (Native Instruments GmbH)",
  "VSTi: Kontakt 7",
  "VSTi: Kontakt 6",
  -- Wrappers
  "VST3i: Komplete Kontrol (Native Instruments GmbH)",
  "Komplete Kontrol",
  -- AU (macOS)
  "AU: Kontakt 7 (Native Instruments)",
  "AU: Kontakt (Native Instruments)",
  -- Loose fallbacks
  "Kontakt 7",
  "Kontakt",
}

local PRESET_JOIN = " — "
local ALT_PRESET_JOINS = { " - ", " – ", " — " }
local FAMILY_DEFAULT_SUFFIX = " — Default"

-- Optional base hue per top-level family (0..360). If nil, auto-distributes using stable hash.
local FAMILY_BASE_HUE = {
  -- Strings-ish
  ["High strings"]                     = 225,
  ["High strings octaves"]             = 220,
  ["High Strings — Half Section"]      = 210,
  ["Celli"]                            = 205,
  ["Low strings"]                      = 200,
  ["Basses"]                           = 195,

  -- Winds
  ["Piccolo and flutes"]               = 190,
  ["Concert flutes"]                   = 185,
  ["Mixed flutes"]                     = 180,
  ["Flutes and clarinets"]             = 170,
  ["Low winds"]                        = 160,
  ["Woodwinds"]                        = 155,

  -- Brass
  ["High brass"]                       = 40,
  ["Trumpet and xylophone"]            = 35,
  ["Horns"]                            = 30,
  ["Mid brass"]                        = 25,
  ["Low brass"]                        = 22,
  ["Trombones"]                        = 20,
  ["Trombones and timpani"]            = 15,

  -- Mixed families (parked in closest section)
  ["Low strings and horns"]            = 45,
  ["Low strings and trombones"]        = 30,
  ["Cor anglais, clarinet and trumpet"]= 150,
  ["Oboes, bassoons and horns"]        = 140,

  -- Keys / Perc
  ["Harp and celeste"]                 = 300,
  ["Harp and vibraphone"]              = 305,
  ["Percussion"]                       = 0,
  ["Timpani"]                          = 10,
}

-- ========= BIG SECTION COLORS =========
local SECTION_COLOR = {
  ["Strings"]   = {170, 190, 255},
  ["Woodwinds"] = {170, 240, 210},
  ["Brass"]     = {255, 225, 160},
  ["Percussion"]= {255, 180, 180},
  ["Keys"]      = {235, 200, 255},
}

-- ========= DATA (FLAT SOURCE) =========
local FAMILIES = {
  -- STRINGS (core BHCT)
  { name = "High strings", items = {
      "Long","Long CS Blend","Long CS Sul Pont","Long CS","Long Flautando","Long Harmonics","Long Sul Pont",
      "Marcato Attack","Short 0'5","Short 1'0","Short Brushed CS","Short Brushed","Short Col Legno",
      "Short Harmonics","Short Pizzicato Bartok","Short Pizzicato","Short Spiccato CS","Short Spiccato",
      "Tremolo CS Sul Pont","Tremolo CS","Tremolo Sul Pont","Tremolo",
      "Trill (Major 2nd)","Trill (Major 3rd)","Trill (Minor 2nd)","Trill (Minor 3rd)","Trill (Perfect 4th)",
  }},
  { name = "High strings octaves", items = {
      "Legato fingered","Legato portamento","Long","Long CS","Tremolo",
      "Trill (Minor 2nd)","Trill (Major 2nd)","Short Spiccato",
  }},
  { name = "High Strings — Half Section", items = {
      "Legato","Legato Portamento","Long","Long CS","Long Flautando",
      "Tremolo","Tremolo Sul Pont",
      "FX Cluster Slides","FX Cluster Stabs","FX Chatter","FX Cluster Swells","FX Cluster Swipes",
  }},
  { name = "Low strings", items = {
      "Legato fingered",
      "Long","Long CS",
      "Long Sul Pont","Long CS Sul Pont","Long Flautando","Long Harmonics","Long Marcato Attack",
      "Tremolo","Tremolo CS","Tremolo Sul Pont","Tremolo CS Sul Pont",
      "Short Spiccato","Pizzicato","Short Bartok",
      "FX 1 (Cluster Slides)","FX 2 (Chatter)","FX 3 (Cluster Swells)","FX 4 (Cluster Run)",
  }},

  -- STRINGS/BRASS mixed (kept under Strings for convenience)
  { name = "Low strings and horns", items = { "Long","Long CS","Short","Col Legno/Stopped", "Short Pizzicato" }},
  { name = "Low strings and trombones", items = { "Legato","Long","Long CS","Long CS Sul Pont","Tremolo","Short","Short CS Sul Pont" }},

  -- WOODWINDS (BHCT)
  { name = "Piccolo and flutes", items = { "Legato","Long","Short" }},
  { name = "Concert flutes", items = {
      "Legato","Long","Short","Trill (Minor 2nd)","Trill (Major 2nd)",
      "Long Flutter","FX 1 (Rips)","FX 2 (Upper Mordent Major)","FX 3 (Upper Mordent Minor)",
  }},
  { name = "Mixed flutes", items = { "Legato","Long","Short","Trill (Minor 2nd)","Trill (Major 2nd)","Long Flutter","FX 1","FX 2" }},
  { name = "Flutes and clarinets", items = { "Legato","Long","Long (Octave)","Short","Short (Octave)","Trill (Minor 2nd)","Trill (Major 2nd)" }},
  { name = "Low winds", items = { "Legato","Long","Long (Octave)","Short","Short (Octave)" }},

  -- WOODWINDS/BRASS mixed (kept under Woodwinds)
  { name = "Cor anglais, clarinet and trumpet", items = { "Long","Short","Trill (Minor 2nd)","Trill (Major 2nd)","FX (Chatter)" }},
  { name = "Oboes, bassoons and horns", items = { "Long","Short","FX" }},

  -- BRASS (BHCT)
  { name = "Trumpet and xylophone", items = { "Long","Short","Short Muted","Long (Octave)","Short (Octave)","Short Muted (Octave)" }},
  { name = "Horns", items = { "Long mf","Long ff","Short mf","Short ff" }},
  { name = "Mid brass", items = { "Long","Short","FX 1 (Chatter)","FX 2 (Falls)" }},
  { name = "Trombones", items = { "Long","Long Muted","Short","Short Muted" }},
  { name = "Trombones and timpani", items = { "Long","Short" }},

  -- KEYS
  { name = "Harp and celeste", items = { "Long","Short" }},
  { name = "Harp and vibraphone", items = { "Long","Long Bowed","Short (Vibes On)","Short (Vibes Off)","Short Hotrods (Vibes Off)" }},

  -- PERC
  { name = "Percussion", items = {
      "Anvil","Bass Drum","Bongos","Bowed Cymbals","Brake Disks","Claves","Congas","Cymbals","Exhaust Pipe",
      "Lion Roar","Ogororo","Quica","Snare Drum (brushes)","Snare Drum (snares off)","Snare Drum (snares on)",
      "Steel Plate","Temple Block","Timbales","Trash Can","Woodblock",
  }},
  { name = "Timpani", items = {
      "Hits Sustained","Hits Damped","Hits Super Damped","Rolls",
      "Soft Stick - Hits Sustained","Soft Stick - Hits Damped","Soft Stick - Rolls",
      "Hot Rods - Hits Sustained","Hot Rods - Hits Damped",
  }},
}

-- KEPLER payloads (added on merge, deduped)
local KEPLER_FAMILIES = {
  ["High strings"] = {
    "KEPLER grid","KEPLER muted grid","KEPLER sul pont grid","KEPLER muted tremolo grid",
    "KEPLER momentum grid","KEPLER pulsing momentum grid","KEPLER accelerating momentum grid","KEPLER shards grid",
  },
  ["Celli"] = {
    "KEPLER grid","KEPLER muted grid","KEPLER sul pont grid","KEPLER muted tremolo grid",
    "KEPLER momentum grid","KEPLER pulsing momentum grid","KEPLER accelerating momentum grid","KEPLER shards grid",
    "KEPLER dopplers grid","KEPLER non pulsing dopplers grid",
  },
  ["High brass"] = {
    "KEPLER grid","KEPLER momentum grid","KEPLER pulsing momentum grid","KEPLER accelerating momentum grid","KEPLER shards grid",
  },
  ["Low brass"] = {
    "KEPLER grid","KEPLER momentum grid","KEPLER pulsing momentum grid","KEPLER accelerating momentum grid","KEPLER shards grid",
    "KEPLER dopplers grid","KEPLER non pulsing dopplers grid",
  },
  ["Basses"] = {
    "KEPLER grid","KEPLER pizzicato grid","KEPLER col legno grid","KEPLER tremolo grid",
    "KEPLER momentum grid","KEPLER harmonics grid","KEPLER tremolo harmonics grid","KEPLER shards grid","KEPLER dopplers grid",
  },
  ["Woodwinds"] = {
    "KEPLER grid","KEPLER momentum grid","KEPLER accelerating momentum grid","KEPLER shards grid","KEPLER shards grid time machine",
  },
}

-- ========= SECTION ORDER / FAMILY ORDER =========
local SECTION_ORDER = { "Strings", "Woodwinds", "Brass", "Percussion", "Keys" }

local ORDER_BY_SECTION = {
  ["Strings"] = {
    "High strings",
    "High strings octaves",
    "High Strings — Half Section",
    "Celli",
    "Low strings",
    "Basses",
    "Low strings and horns",
    "Low strings and trombones",
  },
  ["Woodwinds"] = {
    "Piccolo and flutes",
    "Concert flutes",
    "Mixed flutes",
    "Flutes and clarinets",
    "Low winds",
    "Cor anglais, clarinet and trumpet",
    "Oboes, bassoons and horns",
    "Woodwinds",
  },
  ["Brass"] = {
    "High brass",
    "Trumpet and xylophone",
    "Horns",
    "Mid brass",
    "Low brass",
    "Trombones",
    "Trombones and timpani",
  },
  ["Percussion"] = {
    "Percussion",
    "Timpani",
  },
  ["Keys"] = {
    "Harp and celeste",
    "Harp and vibraphone",
  },
}

-- ========= OPTIONAL EXTERNAL LIBRARY OVERRIDES =========
local function safe_require(path)
  local ok, mod = pcall(dofile, path)
  if ok and type(mod)=="table" then return mod end
end

local ext_path = r.GetResourcePath().."/Scripts/Cam_Orchestra_families.lua"
local external = safe_require(ext_path)
if external then
  FAMILIES          = external.FAMILIES          or FAMILIES
  KEPLER_FAMILIES   = external.KEPLER_FAMILIES   or KEPLER_FAMILIES
  ORDER_BY_SECTION  = external.ORDER_BY_SECTION  or ORDER_BY_SECTION
  SECTION_ORDER     = external.SECTION_ORDER     or SECTION_ORDER
  FAMILY_BASE_HUE   = external.FAMILY_BASE_HUE   or FAMILY_BASE_HUE
end

-- Map families to sections
local FAMILY_SECTION = {}
for sec, list in pairs(ORDER_BY_SECTION) do
  for _, name in ipairs(list) do FAMILY_SECTION[name] = sec end
end

-- ========== MERGE KEPLER + META (with de-duplication) ==========
local ORIGINAL_BHCT = {}; for _, f in ipairs(FAMILIES) do ORIGINAL_BHCT[f.name] = true end
local FAMILY_META = {} -- [name] = { has_kepler, kepler_only, is_bhct_original }

local function index_families()
  local idx = {}
  for i, f in ipairs(FAMILIES) do
    idx[f.name] = i
    FAMILY_META[f.name] = FAMILY_META[f.name] or {
      has_kepler=false, kepler_only=false, is_bhct_original = ORIGINAL_BHCT[f.name] or false
    }
  end
  return idx
end

local function merge_kepler_in_place()
  local idx = index_families()
  for famName, items in pairs(KEPLER_FAMILIES) do
    if idx[famName] then
      local list = FAMILIES[idx[famName]].items
      local seen = {}; for _, it in ipairs(list) do seen[it] = true end
      for _, it in ipairs(items) do
        if not seen[it] then list[#list+1] = it; seen[it] = true end
      end
      FAMILY_META[famName].has_kepler = true
    else
      table.insert(FAMILIES, { name=famName, items = { table.unpack(items) } })
      FAMILY_META[famName] = { has_kepler=true, kepler_only=true, is_bhct_original=false }
      idx = index_families()
    end
  end
end
merge_kepler_in_place()

-- ========= HELPERS =========
local HAS_JS  = r.APIExists and r.APIExists("JS_Window_Find")
local HAS_SWS = r.APIExists and (r.APIExists("BR_Win32_GetWindowRect") or r.APIExists("SNM_SetIntConfigVar"))
local HAS_IMGUI = (reaper and reaper.ImGui_CreateContext) and true or false

local function toNativeColor(r_, g_, b_) return r.ColorToNative(r_, g_, b_) | 0x1000000 end
local function clamp(x, a, b) if x < a then return a elseif x > b then return b else return x end end

-- memoize r,g,b -> native
local COLOR_CACHE = {}
local function rgb_key(rgb) return (rgb and (rgb[1]..","..rgb[2]..","..rgb[3])) or "" end
local function cached_native(rgb)
  local k = rgb_key(rgb)
  if not COLOR_CACHE[k] then COLOR_CACHE[k] = toNativeColor(rgb[1], rgb[2], rgb[3]) end
  return COLOR_CACHE[k]
end

-- FNV-1a hash for stable auto hue
local function hash32(s)
  local h = 2166136261
  for i=1,#s do h = (h ~ s:byte(i)) * 16777619 & 0xffffffff end
  return h
end

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
  if s == 0 then r_, g_, b_ = l, l, l else
    local q = l < 0.5 and l * (1 + s) or (l + s - l * s)
    local p = 2 * l - q
    r_ = hue2rgb(p, q, h + 1/3)
    g_ = hue2rgb(p, q, h)
    b_ = hue2rgb(p, q, h - 1/3)
  end
  return math.floor(r_*255+0.5), math.floor(g_*255+0.5), math.floor(b_*255+0.5)
end

local function colorFromFamily(familyName, fi, fc, ii, ic)
  local baseHue = FAMILY_BASE_HUE[familyName]
  if not baseHue then baseHue = hash32(familyName) % 360 end
  local sat = (ii==1 and 0.45 or 0.55)
  local lightBase = 0.62
  local lightStep = 0.9 * (ii-1) / math.max(1,(ic-1)) * 0.22
  local l = math.max(0.35, math.min(0.8, lightBase - lightStep))
  local r_,g_,b_ = hslToRgb(baseHue, sat, l)
  return {r_,g_,b_}
end

-- Pack RGBA float(0..1) to U32 for TextColored
local function RGBA(rf, gf, bf, af)
  if r.ImGui_ColorConvertDouble4ToU32 then
    return r.ImGui_ColorConvertDouble4ToU32(rf, gf, bf, af)
  else
    local r8 = math.floor((rf or 0)*255+0.5)
    local g8 = math.floor((gf or 0)*255+0.5)
    local b8 = math.floor((bf or 0)*255+0.5)
    local a8 = math.floor((af or 1)*255+0.5)
    return (a8<<24) | (b8<<16) | (g8<<8) | r8
  end
end

local function insertTrack(idx, name, folderDepth, rgb)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  if folderDepth then r.SetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH", folderDepth) end
  if rgb then r.SetTrackColor(tr, cached_native(rgb)) end
  return tr
end

local function closeFXUI(tr, fx)
  if r.TrackFX_SetOpen then r.TrackFX_SetOpen(tr, fx, false) end
  if r.TrackFX_Show then r.TrackFX_Show(tr, fx, 0) end
end

local function placeFXTopRight(hwnd)
  if not hwnd then return end
  local margin = 20
  if HAS_JS then
    local _, ml, mt, mr = r.JS_Window_GetRect(r.GetMainHwnd())
    local _, l, t, rgt, btm = r.JS_Window_GetRect(hwnd)
    local w, h = (rgt - l), (btm - t)
    local x = (mr - ml) - w - margin + ml
    local y = mt + margin
    r.JS_Window_Move(hwnd, x, y)
  elseif r.BR_Win32_GetWindowRect then
    local ml, mt, mr = r.BR_Win32_GetWindowRect(r.GetMainHwnd())
    local l, t, rgt, btm = r.BR_Win32_GetWindowRect(hwnd)
    local w, h = (rgt - l), (btm - t)
    local x = (mr - ml) - w - margin + ml
    local y = mt + margin
    r.BR_Win32_SetWindowPos(hwnd, x, y, w, h, true)
  end
end

-- Unique root naming if "Cam Orchestra" already exists
local function unique_name(base)
  local name = base; local n = 2
  while true do
    local exists = false
    for i=0, r.GetNumTracks()-1 do
      local tr = r.GetTrack(0,i)
      local ok, nm = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
      if ok and nm == name then exists = true; break end
    end
    if not exists then return name end
    name = base .. " ("..n..")"; n = n + 1
  end
end

-- Find an immediate child by name under a given parent index (folder-scope search)
local function find_child_by_name(parent_idx, name)
  local depth = 1
  local i = parent_idx + 1
  while i < r.GetNumTracks() do
    local tr = r.GetTrack(0, i)
    local _, nm = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if nm == name then return tr, i end
    local d = r.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH") or 0
    depth = depth + d
    if depth <= 0 then break end
    i = i + 1
  end
  return nil
end

-- dB to linear
local function db_to_lin(db) return 10^(db/20) end

-- Create a post-fader send
local function create_postfader_send(src, dest, vol_db)
  local send = r.CreateTrackSend(src, dest)
  r.SetTrackSendInfo_Value(src, 0, send, "I_SENDMODE", 0)       -- 0=post-fader
  r.SetTrackSendInfo_Value(src, 0, send, "D_VOL", db_to_lin(vol_db or 0))
end

local function has_send_to(src, dest)
  local cnt = r.GetTrackNumSends(src, 0)
  for i=0,cnt-1 do
    if r.GetTrackSendInfo_Value(src, 0, i, "P_DESTTRACK") == dest then return true end
  end
  return false
end

-- Optional: scale send level vs number of leaves (gentle)
local function scaled_send_db(n, base_db)
  if not AUTO_SCALE_REVERB then return base_db end
  local ref = 12
  local k = math.max(1, n) / ref
  local adjust = 20 * math.log(k, 10) * 0.5
  return base_db - adjust
end

-- Plugin detection (warn once)
local NO_PLUGIN = false
local function addKontaktFX(tr)
  if NO_PLUGIN or not ADD_FX_WHEN_BUILDING then return -1 end
  for _, name in ipairs(PLUGIN_CANDIDATES) do
    local fx = r.TrackFX_AddByName(tr, name, false, 1)
    if fx and fx >= 0 then closeFXUI(tr, fx); return fx end
  end
  for _, name in ipairs(PLUGIN_CANDIDATES) do
    local fx = r.TrackFX_AddByName(tr, name, false, -1)
    if fx and fx >= 0 then closeFXUI(tr, fx); return fx end
  end
  NO_PLUGIN = true
  r.ShowMessageBox("Kontakt/Komplete Kontrol not found. Tracks will be created without FX.", "Cam Orchestra", 0)
  return -1
end

-- articulation aliasing for preset matching
local function alt_art_names(art)
  local alts = { art }
  if art == "Long" then alts[#alts+1] = "Long v" end
  if art == "Short Brushed" then alts[#alts+1] = "Brushed Spiccato" end
  if art == "Short Brushed CS" then alts[#alts+1] = "Brushed Spiccato CS" end
  if art == "Short Col Legno" then alts[#alts+1] = "Col Legno" end
  if art == "Short Pizzicato Bartok" then alts[#alts+1] = "Pizzicato Bartok" end
  if art == "Marcato Attack" then alts[#alts+1] = "Long Marcato Attack" end
  if art == "Legato Portamento" then alts[#alts+1] = "Legato portamento" end
  if art == "Legato portamento" then alts[#alts+1] = "Legato Portamento" end
  if art == "Short 0'5" then alts[#alts+1] = "Short 0.5" end
  if art == "Short 1'0" then alts[#alts+1] = "Short 1.0" end
  local trill_map = {
    ["Trill (Major 2nd)"] = "Trill Maj2",
    ["Trill (Minor 2nd)"] = "Trill Min2",
    ["Trill (Major 3rd)"] = "Trill Maj3",
    ["Trill (Minor 3rd)"] = "Trill Min3",
    ["Trill (Perfect 4th)"] = "Trill Perf4",
  }
  if trill_map[art] then alts[#alts+1] = trill_map[art] end
  return alts
end

-- normalize preset names (dash variants + whitespace + numeric apostrophes)
local function norm(s)
  s = (s or ""):gsub("[–—%-]+"," — "):gsub("%s+"," ")
  s = s:gsub("^%s+",""):gsub("%s+$","")
  s = s:gsub("0'?5","0.5"):gsub("1'?0","1.0")
  return s
end

local function tryPreset(tr, fx, name)
  if not name or name=="" or fx < 0 then return false end
  return r.TrackFX_SetPreset(tr, fx, norm(name))
end

-- preset loader with caching: Family+Art (joins+aliases) -> Art -> Family Default
local PRESET_CACHE = {} -- [family|art] = resolved preset name or ""

local function loadPreset(tr, fx, familyName, art)
  local key = familyName.."|"..art
  local hit = PRESET_CACHE[key]
  if hit ~= nil then
    if hit ~= "" then r.TrackFX_SetPreset(tr, fx, hit) end
    return hit ~= "" and "cached" or "none"
  end
  for _, a in ipairs(alt_art_names(art)) do
    if tryPreset(tr, fx, familyName .. PRESET_JOIN .. a) then
      local _, nm = r.TrackFX_GetPreset(tr, fx, "")
      PRESET_CACHE[key] = nm or ""; return "family+art"
    end
    for _, j in ipairs(ALT_PRESET_JOINS) do
      if tryPreset(tr, fx, familyName .. j .. a) then
        local _, nm = r.TrackFX_GetPreset(tr, fx, "")
        PRESET_CACHE[key] = nm or ""; return "family+art"
      end
    end
  end
  for _, a in ipairs(alt_art_names(art)) do
    if tryPreset(tr, fx, a) then
      local _, nm = r.TrackFX_GetPreset(tr, fx, "")
      PRESET_CACHE[key] = nm or ""; return "art"
    end
  end
  if tryPreset(tr, fx, familyName .. FAMILY_DEFAULT_SUFFIX) then
    local _, nm = r.TrackFX_GetPreset(tr, fx, "")
    PRESET_CACHE[key] = nm or ""; return "family"
  end
  PRESET_CACHE[key] = ""
  return "none"
end

local function setKontaktDefaultPos(tr, fx)
  if fx < 0 or not POSITION_FX_WINDOWS then return end
  r.TrackFX_Show(tr, fx, 2)
  local hwnd = r.TrackFX_GetFloatingWindow(tr, fx)
  if hwnd then placeFXTopRight(hwnd) end
  closeFXUI(tr, fx)
end

-- ========= BUILD =========
local function count_selection(sel)
  local fams, leaves = 0, 0
  local sections_present = {}
  for _, f in ipairs(FAMILIES) do
    if sel[f.name] then
      fams = fams + 1
      leaves = leaves + #f.items
      sections_present[FAMILY_SECTION[f.name] or ""] = true
    end
  end
  local sec_count = 0; for _ in pairs(sections_present) do sec_count = sec_count + 1 end
  local total = 1 + sec_count + fams + leaves + 1
  return total, sec_count, fams, leaves
end

local function build_selected(selected_set)
  local tcp_old
  if r.SNM_SetIntConfigVar then tcp_old = r.SNM_SetIntConfigVar("tcp_vuavail", 0) end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local base = r.GetNumTracks()
  r.InsertTrackAtIndex(base, true)
  local root = r.GetTrack(0, base)
  r.GetSetMediaTrackInfo_String(root, "P_NAME", unique_name("Cam Orchestra"), true)
  r.SetMediaTrackInfo_Value(root, "I_FOLDERDEPTH", 1)
  r.SetTrackColor(root, toNativeColor(92,105,180))
  local idx = base + 1

  local section_last_leaf = nil
  local family_last_leaf  = nil
  local leafs = {}

  for _, section in ipairs(SECTION_ORDER) do
    local secFamilies = {}
    for _, famName in ipairs(ORDER_BY_SECTION[section]) do
      if selected_set[famName] then secFamilies[#secFamilies+1] = famName end
    end
    if #secFamilies > 0 then
      local secTr = insertTrack(idx, section, 1, SECTION_COLOR[section]); idx = idx + 1
      section_last_leaf = secTr
      for fi, famName in ipairs(secFamilies) do
        local fam
        for _, F in ipairs(FAMILIES) do if F.name == famName then fam = F; break end end
        if fam then
          local famColor = colorFromFamily(fam.name, fi, #secFamilies, 1, 1)
          local famTr = insertTrack(idx, fam.name, 1, famColor); idx = idx + 1
          family_last_leaf = famTr

          local leafCount = #fam.items
          for li, art in ipairs(fam.items) do
            local artColor = colorFromFamily(fam.name, fi, #secFamilies, li, leafCount)
            local tr = insertTrack(idx, art, 0, artColor); idx = idx + 1
            r.SetMediaTrackInfo_Value(tr, "I_RECARM", DEFAULT_RECARM)
            r.SetMediaTrackInfo_Value(tr, "I_RECMON", DEFAULT_MONITOR)
            r.SetMediaTrackInfo_Value(tr, "I_RECMODE", DEFAULT_RECMODE)
            local midi_in = FAMILY_MIDI_INPUT[fam.name] or DEFAULT_MIDI_INPUT
            r.SetMediaTrackInfo_Value(tr, "I_RECINPUT", midi_in)
            r.SetMediaTrackInfo_Value(tr, "I_RECMONITEMS", 1)
            r.SetMediaTrackInfo_Value(tr, "B_FREEMODE", 1)

            local fx = addKontaktFX(tr)
            if fx >= 0 then loadPreset(tr, fx, fam.name, art); setKontaktDefaultPos(tr, fx) end

            leafs[#leafs+1] = tr
            family_last_leaf = tr
            section_last_leaf = tr
          end
          if family_last_leaf then
            local cur = r.GetMediaTrackInfo_Value(family_last_leaf, "I_FOLDERDEPTH") or 0
            r.SetMediaTrackInfo_Value(family_last_leaf, "I_FOLDERDEPTH", cur - 1)
          end
        end
      end
      if section_last_leaf then
        local cur = r.GetMediaTrackInfo_Value(section_last_leaf, "I_FOLDERDEPTH") or 0
        r.SetMediaTrackInfo_Value(section_last_leaf, "I_FOLDERDEPTH", cur - 1)
      end
    end
  end

  local reverbTr = find_child_by_name(base, "Reverb")
  if not reverbTr then
    reverbTr = insertTrack(idx, "Reverb", 0, {200,200,200}); idx = idx + 1
  end
  r.SetMediaTrackInfo_Value(reverbTr, "I_RECARM", 0)
  r.SetMediaTrackInfo_Value(reverbTr, "I_RECMON", 0)
  r.SetMediaTrackInfo_Value(reverbTr, "I_RECMODE", 0)
  r.SetMediaTrackInfo_Value(reverbTr, "B_FREEMODE", 0)
  section_last_leaf = reverbTr

  local send_db = scaled_send_db(#leafs, DEFAULT_SEND_LEVEL)
  for _, lt in ipairs(leafs) do
    if not has_send_to(lt, reverbTr) then
      local _, fam_name = r.GetSetMediaTrackInfo_String(r.GetParentTrack(lt) or lt, "P_NAME", "", false)
      local add = FAMILY_SEND_OFFSET_DB[fam_name or ""] or 0
      create_postfader_send(lt, reverbTr, send_db + add)
    end
  end

  if section_last_leaf then
    local cur = r.GetMediaTrackInfo_Value(section_last_leaf, "I_FOLDERDEPTH") or 0
    r.SetMediaTrackInfo_Value(section_last_leaf, "I_FOLDERDEPTH", cur - 1)
  end

  r.TrackList_AdjustWindows(false)
  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("Build Cam Orchestra (Sections, KEPLER in-order, Kontakt + Auto Presets + Reverb + Sends)", -1)

  if COLLAPSE_AFTER_BUILD then
    r.Main_OnCommand(40297,0)
    if r.SetOnlyTrackSelected then r.SetOnlyTrackSelected(root, true) end
    r.Main_OnCommand(40854,0)
  end

  if r.SNM_SetIntConfigVar and tcp_old then r.SNM_SetIntConfigVar("tcp_vuavail", tcp_old) end
end

-- ========= PERSISTENCE =========
local function save_state(STATES, SHOW_MODE, selset_names)
  local t = {
    tostring(SHOW_MODE or 1),
    ADD_FX_WHEN_BUILDING and "1" or "0",
    tostring(DEFAULT_SEND_LEVEL),
    AUTO_SCALE_REVERB and "1" or "0",
    tostring(DEFAULT_RECARM),
    tostring(DEFAULT_MONITOR),
    tostring(DEFAULT_MIDI_INPUT),
    tostring(DEFAULT_RECMODE),
    COLLAPSE_AFTER_BUILD and "1" or "0",
    POSITION_FX_WINDOWS and "1" or "0",
  }
  for k,v in pairs(STATES) do if v then t[#t+1]=k end end
  r.SetExtState(EXT_NS, "state", table.concat(t, "|"), true)
  if selset_names and #selset_names>0 then
    r.SetExtState(EXT_NS, "selsets", table.concat(selset_names, ","), true)
  end
end

local function load_state(STATES)
  local s = r.GetExtState(EXT_NS, "state")
  if s=="" then return 1 end
  local parts = {}
  for p in s:gmatch("[^|]+") do parts[#parts+1]=p end
  local mode = tonumber(parts[1]) or 1
  ADD_FX_WHEN_BUILDING = (parts[2] ~= "0")
  DEFAULT_SEND_LEVEL   = tonumber(parts[3]) or DEFAULT_SEND_LEVEL
  AUTO_SCALE_REVERB    = (parts[4] ~= "0")
  DEFAULT_RECARM       = tonumber(parts[5]) or DEFAULT_RECARM
  DEFAULT_MONITOR      = tonumber(parts[6]) or DEFAULT_MONITOR
  DEFAULT_MIDI_INPUT   = tonumber(parts[7]) or DEFAULT_MIDI_INPUT
  DEFAULT_RECMODE      = tonumber(parts[8]) or DEFAULT_RECMODE
  COLLAPSE_AFTER_BUILD = (parts[9] ~= "0")
  POSITION_FX_WINDOWS  = (parts[10] ~= "0")
  for i=11,#parts do if STATES[parts[i]] ~= nil then STATES[parts[i]] = true end end
  return mode
end

-- Selection set helpers
local function get_selset_names()
  local s = r.GetExtState(EXT_NS, "selsets")
  if s=="" then return {} end
  local t = {}
  for name in s:gmatch("[^,]+") do t[#t+1]=name end
  return t
end

local function save_selection_set(name, STATES)
  if not name or name=="" then return end
  local on = {}
  for k,v in pairs(STATES) do if v then on[#on+1]=k end end
  r.SetExtState(EXT_NS, "selset:"..name, table.concat(on, "|"), true)
  local list = get_selset_names()
  local seen = {}; for _,n in ipairs(list) do seen[n]=true end
  if not seen[name] then list[#list+1]=name end
  r.SetExtState(EXT_NS, "selsets", table.concat(list, ","), true)
end

local function load_selection_set(name, STATES)
  if not name or name=="" then return end
  local s = r.GetExtState(EXT_NS, "selset:"..name)
  if s=="" then return end
  for k in pairs(STATES) do STATES[k]=false end
  for fam in s:gmatch("[^|]+") do if STATES[fam] ~= nil then STATES[fam] = true end end
end

-- ========= UI =========
if HAS_IMGUI then
  local ctx = r.ImGui_CreateContext('Cam Orchestra — Select families')
  local FONT = r.ImGui_CreateFont('sans-serif', 16); r.ImGui_Attach(ctx, FONT)
  local DestroyContext = r.ImGui_DestroyContext or function(_) end
  local W_NoCollapse = (r.ImGui_WindowFlags_NoCollapse and r.ImGui_WindowFlags_NoCollapse()) or 0
  local W_None       = (r.ImGui_WindowFlags_None and r.ImGui_WindowFlags_None()) or 0
  local function BeginChildCompat(id, w, h, wantBorder, flags)
    wantBorder = (wantBorder ~= false); flags = flags or W_None
    local ok, ret = pcall(r.ImGui_BeginChild, ctx, id, w, h, wantBorder, flags)
    if ok then return ret end
    return r.ImGui_BeginChild(ctx, id, w, h, flags)
  end

  local open, filter = true, ''
  local STATES = {}  -- [familyName] = bool
  for _, f in ipairs(FAMILIES) do STATES[f.name] = false end

  -- Show: 1=All, 2=BHCT-only, 3=KEPLER-containing, 4=Selected
  local SHOW_MODE = load_state(STATES)

  local function family_meta(name) return FAMILY_META[name] end

  local function pass_filter(name, text)
    if text ~= '' then
      local lname = name:lower()
      for token in text:lower():gmatch("%S+") do
        if not lname:find(token, 1, true) then return false end
      end
    end
    local m = family_meta(name)
    if SHOW_MODE==2 then return m and m.is_bhct_original
    elseif SHOW_MODE==3 then return m and m.has_kepler
    elseif SHOW_MODE==4 then return STATES[name]
    end
    return true
  end

  local function kepler_badge(name)
    local m = family_meta(name); if not m then return end
    if m.kepler_only then r.ImGui_SameLine(ctx); r.ImGui_Text(ctx, " [KEPLER]")
    elseif m.has_kepler then r.ImGui_SameLine(ctx); r.ImGui_Text(ctx, " [+KEPLER]") end
  end

  local function section_state(section, STATES_)
    local totals, on = 0, 0
    for _, fam in ipairs(ORDER_BY_SECTION[section]) do
      if STATES_[fam] ~= nil then totals = totals + 1; if STATES_[fam] then on = on + 1 end end
    end
    return totals==on and 1 or (on>0 and 0 or -1)
  end

  local function run_ui()
    if not open then return end
    local COND_FIRST = (r.ImGui_Cond_Appearing and r.ImGui_Cond_Appearing()) or 0
    r.ImGui_SetNextWindowSize(ctx, 1000, 760, COND_FIRST)
    if r.ImGui_SetNextWindowSizeConstraints then
      r.ImGui_SetNextWindowSizeConstraints(ctx, 840, 600, 4096, 4096)
    end

    local visible, show = r.ImGui_Begin(ctx, 'Cam Orchestra — Select families', true, W_NoCollapse)
    if visible then
      r.ImGui_Text(ctx, 'Pick families to add (BHCT + KEPLER, ordered by section):')
      r.ImGui_SameLine(ctx); if r.ImGui_Button(ctx, 'All') then for _, f in ipairs(FAMILIES) do STATES[f.name]=true end end
      r.ImGui_SameLine(ctx); if r.ImGui_Button(ctx, 'None') then for _, f in ipairs(FAMILIES) do STATES[f.name]=false end end
      r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx, 260); local _; _, filter = r.ImGui_InputText(ctx, ' Filter', filter)
      r.ImGui_SameLine(ctx); r.ImGui_Text(ctx, "Show:")
      r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx, 160)
      local label = (SHOW_MODE==1 and "All") or (SHOW_MODE==2 and "BHCT") or (SHOW_MODE==3 and "KEPLER") or "Selected"
      if r.ImGui_BeginCombo(ctx, "##showmode", label) then
        local c
        c = r.ImGui_Selectable(ctx, "All",      SHOW_MODE==1); if c then SHOW_MODE = 1 end
        c = r.ImGui_Selectable(ctx, "BHCT",     SHOW_MODE==2); if c then SHOW_MODE = 2 end
        c = r.ImGui_Selectable(ctx, "KEPLER",   SHOW_MODE==3); if c then SHOW_MODE = 3 end
        c = r.ImGui_Selectable(ctx, "Selected", SHOW_MODE==4); if c then SHOW_MODE = 4 end
        r.ImGui_EndCombo(ctx)
      end

      r.ImGui_NewLine(ctx)

      local ch; ch, ADD_FX_WHEN_BUILDING = r.ImGui_Checkbox(ctx, "Add Kontakt on build", ADD_FX_WHEN_BUILDING)
      r.ImGui_SameLine(ctx)
      r.ImGui_SetNextItemWidth(ctx, 120)
      local ch_send; ch_send, DEFAULT_SEND_LEVEL = r.ImGui_InputDouble(ctx, "Reverb send (dB)", DEFAULT_SEND_LEVEL, 0.5, 1.0, "%.1f")
      if ch_send then DEFAULT_SEND_LEVEL = tonumber(tostring(DEFAULT_SEND_LEVEL):gsub(",", ".")) or DEFAULT_SEND_LEVEL end
      r.ImGui_SameLine(ctx)
      local ch_auto; ch_auto, AUTO_SCALE_REVERB = r.ImGui_Checkbox(ctx, "Auto-scale reverb", AUTO_SCALE_REVERB)

      r.ImGui_NewLine(ctx)
      r.ImGui_TextColored(ctx, RGBA(0.9,0.9,1,1), "Recording defaults:")
      r.ImGui_SameLine(ctx)
      local arm_chk = (DEFAULT_RECARM or 0) ~= 0
      ch, arm_chk = r.ImGui_Checkbox(ctx, "Arm new tracks", arm_chk)
      if ch then DEFAULT_RECARM = arm_chk and 1 or 0 end

      r.ImGui_SameLine(ctx)
      local mon_chk = (DEFAULT_MONITOR or 0) ~= 0
      ch, mon_chk = r.ImGui_Checkbox(ctx, "Monitor on", mon_chk)
      if ch then DEFAULT_MONITOR = mon_chk and 1 or 0 end

      r.ImGui_SameLine(ctx)
      local midi_all = (DEFAULT_MIDI_INPUT == 4096)
      ch, midi_all = r.ImGui_Checkbox(ctx, "MIDI: All inputs (Omni)", midi_all)
      if ch then DEFAULT_MIDI_INPUT = midi_all and 4096 or 0 end
      if r.ImGui_IsItemHovered(ctx) then
        r.ImGui_BeginTooltip(ctx)
        r.ImGui_Text(ctx, "When OFF, tracks start with no input selected.\n(You can set specific devices/channels on tracks later.)")
        r.ImGui_EndTooltip(ctx)
      end

      r.ImGui_SameLine(ctx)
      r.ImGui_SetNextItemWidth(ctx, 200)
      local recmode_label = (DEFAULT_RECMODE==0 and "Record: input") or (DEFAULT_RECMODE==16 and "MIDI overdub") or (DEFAULT_RECMODE==7 and "Record: output") or ("Mode "..tostring(DEFAULT_RECMODE))
      if r.ImGui_BeginCombo(ctx, "##recmode", recmode_label) then
        if r.ImGui_Selectable(ctx, "Record: input", DEFAULT_RECMODE==0) then DEFAULT_RECMODE = 0 end
        if r.ImGui_Selectable(ctx, "MIDI overdub", DEFAULT_RECMODE==16) then DEFAULT_RECMODE = 16 end
        if r.ImGui_Selectable(ctx, "Record: output", DEFAULT_RECMODE==7) then DEFAULT_RECMODE = 7 end
        r.ImGui_EndCombo(ctx)
      end

      r.ImGui_SameLine(ctx)
      ch, COLLAPSE_AFTER_BUILD = r.ImGui_Checkbox(ctx, "Collapse folders after build", COLLAPSE_AFTER_BUILD)

      r.ImGui_SameLine(ctx)
      ch, POSITION_FX_WINDOWS = r.ImGui_Checkbox(ctx, "Place Kontakt top-right", POSITION_FX_WINDOWS)

      r.ImGui_Separator(ctx)

      -- Two side-by-side panes (no Columns API)
      local avail_w = 960
      if r.ImGui_GetContentRegionAvail then
        local w, _ = r.ImGui_GetContentRegionAvail(ctx)
        if w and w > 0 then avail_w = w end
      end
      local left_w = math.floor(avail_w * 0.58)
      local right_w = math.max(100, avail_w - left_w - 8)
      local list_h = -120

      -- Left pane: Family list
      BeginChildCompat('list', left_w, list_h, true, W_None)
        for _, section in ipairs(SECTION_ORDER) do
          local hasAny = false
          for _, famName in ipairs(ORDER_BY_SECTION[section]) do
            if pass_filter(famName, filter) then hasAny = true break end
          end
          if hasAny then
            local st = section_state(section, STATES)
            local lbl = (st==1 and "☑ ") or (st==0 and "◪ ") or "☐ "
            if r.ImGui_Button(ctx, lbl .. section .. "  (toggle)") then
              local new = st~=1
              for _, fam in ipairs(ORDER_BY_SECTION[section]) do
                if STATES[fam] ~= nil then STATES[fam] = new end
              end
            end
            r.ImGui_SameLine(ctx); r.ImGui_TextColored(ctx, RGBA(0.85, 0.87, 1.0, 1.0), " ")
            r.ImGui_Separator(ctx)

            for _, famName in ipairs(ORDER_BY_SECTION[section]) do
              if pass_filter(famName, filter) then
                local clicked, val = r.ImGui_Checkbox(ctx, "  "..famName, STATES[famName])
                if clicked then STATES[famName] = val end
                kepler_badge(famName)
              end
            end
            r.ImGui_Separator(ctx)
          end
        end
      r.ImGui_EndChild(ctx)

      r.ImGui_SameLine(ctx)
      -- Right pane: Preview & Selection sets
      BeginChildCompat('preview', right_w, list_h, true, W_None)
        r.ImGui_TextColored(ctx, RGBA(0.9,0.95,1,1), "Preview:")
        BeginChildCompat('previewtree', 0, 160, true, W_None)
          for _, section in ipairs(SECTION_ORDER) do
            local anyInSection = false
            for _, famName in ipairs(ORDER_BY_SECTION[section]) do
              if STATES[famName] then anyInSection = true break end
            end
            if anyInSection then
              r.ImGui_Text(ctx, section)
              for _, famName in ipairs(ORDER_BY_SECTION[section]) do
                if STATES[famName] then r.ImGui_Text(ctx, "  • "..famName) end
              end
            end
          end
        r.ImGui_EndChild(ctx)

        r.ImGui_Separator(ctx)
        r.ImGui_TextColored(ctx, RGBA(0.9,0.95,1,1), "Selection sets:")
        local selset_names = get_selset_names()
        local current = "(none)"
        if #selset_names > 0 then current = selset_names[1] end
        -- simple combo replacement: show first and buttons
        if #selset_names > 0 then
          r.ImGui_Text(ctx, "Current: "..current)
          if r.ImGui_Button(ctx, "Load first") then load_selection_set(current, STATES) end
          r.ImGui_SameLine(ctx)
          if r.ImGui_Button(ctx, "Delete first") then
            r.SetExtState(EXT_NS, "selset:"..current, "", true)
            table.remove(selset_names, 1)
            r.SetExtState(EXT_NS, "selsets", table.concat(selset_names, ","), true)
          end
        else
          r.ImGui_Text(ctx, "(no saved sets)")
        end
        local _, newname = r.ImGui_InputText(ctx, " Save as", "")
        if r.ImGui_IsItemDeactivatedAfterEdit(ctx) and newname ~= "" then
          save_selection_set(newname, STATES)
        end
      r.ImGui_EndChild(ctx)

      -- Footer
      local sel = {}
      for name, on in pairs(STATES) do if on then sel[name] = true end end
      local total, sec_count, fams, leaves = count_selection(sel)
      r.ImGui_Text(ctx, string.format("Will create: %d tracks  (%d sections, %d families, %d leaves + Reverb)", total, sec_count, fams, leaves))

      r.ImGui_Separator(ctx)
      if r.ImGui_Button(ctx, 'Build', 160, 30) then
        local any=false; for _,v in pairs(sel) do if v then any=true break end end
        if not any then r.MB("Pick at least one family.", "Cam Orchestra", 0)
        else
          save_state(STATES, SHOW_MODE, get_selset_names())
          open=false; r.ImGui_End(ctx); DestroyContext(ctx); build_selected(sel); return
        end
      end
      r.ImGui_SameLine(ctx); if r.ImGui_Button(ctx, 'Cancel', 160, 30) then save_state(STATES, SHOW_MODE, get_selset_names()); open=false end
    end
    if visible then r.ImGui_End(ctx) end
    if show==false or open==false then DestroyContext(ctx); return end
    r.defer(run_ui)
  end
  r.defer(run_ui)
else
  r.ShowMessageBox("This script requires ReaImGui (Extensions > ReaImGui) enabled.", "Cam Orchestra", 0)
end
