-- Sonos control panel: pick the active room, see/toggle grouping between
-- rooms, control play/pause + volume for the active room, and play a
-- Sonos Favourite. All state comes from service.luau; this file only
-- ever sends commands via noctalia.state.set("sonos.cmd", ...).
local ROOM_ORDER = { "Bedroom", "Dining", "Kitchen" }
local activeRoom = "Dining"
local rooms = {}
local favorites = {}

local function coordRinconOf(name)
  local r = rooms[name]
  return r and r.coordRincon
end

local function isGrouped(name)
  if name == activeRoom then return true end
  local a, b = coordRinconOf(activeRoom), coordRinconOf(name)
  return a ~= nil and a == b
end

local function statusText(name)
  local st = rooms[name] or {}
  if st.title and st.title ~= "" then return st.title end
  if st.transport == "PLAYING" then return "Playing" end
  if st.transport == "PAUSED_PLAYBACK" then return "Paused" end
  if not st.transport then return "..." end
  return "Idle"
end

local function render()
  local roomRows = {}
  for _, name in ipairs(ROOM_ORDER) do
    local isActive = (name == activeRoom)
    local rowChildren = {
      ui.button({
        key = "active_" .. name,
        text = name,
        variant = isActive and "primary" or "outline",
        flexGrow = 1,
        onClick = function()
          noctalia.state.set("sonos.cmd", { action = "SET_ACTIVE", room = name })
        end,
      }),
      ui.label({ text = statusText(name), maxLines = 1 }),
    }
    if not isActive then
      table.insert(rowChildren, ui.toggle({
        key = "group_" .. name,
        checked = isGrouped(name),
        onChange = function(v)
          if v then
            noctalia.state.set("sonos.cmd", { action = "JOIN", room = name, target = activeRoom })
          else
            noctalia.state.set("sonos.cmd", { action = "LEAVE", room = name })
          end
        end,
      }))
    end
    table.insert(roomRows, ui.row({ gap = 8, align = "center" }, rowChildren))
  end

  local st = rooms[activeRoom] or {}
  local transportRow = ui.row({ gap = 10, align = "center" }, {
    ui.button({
      key = "playpause",
      text = (st.transport == "PLAYING") and "Pause" or "Play",
      variant = "primary",
      onClick = function()
        noctalia.state.set("sonos.cmd", { action = "TOGGLE", room = activeRoom })
      end,
    }),
    ui.slider({
      key = "volume",
      value = st.volume or 0,
      min = 0,
      max = 100,
      flexGrow = 1,
      onChange = function(v)
        noctalia.state.set("sonos.cmd", { action = "VOLUME_SET", room = activeRoom, value = math.floor(v) })
      end,
    }),
    ui.label({ text = (st.volume or 0) .. "%" }),
  })

  local favRows = {}
  for i, fav in ipairs(favorites) do
    table.insert(favRows, ui.button({
      key = "fav_" .. i,
      text = fav.title,
      variant = "ghost",
      flexGrow = 1,
      onClick = function()
        noctalia.state.set("sonos.cmd", { action = "PLAY_FAVORITE", room = activeRoom, index = i })
      end,
    }))
  end
  if #favRows == 0 then
    table.insert(favRows, ui.label({ text = "Loading favourites...", color = "secondary" }))
  end

  panel.render(ui.column({ gap = 12, padding = 12 }, {
    ui.label({ text = "Rooms", fontWeight = "bold" }),
    ui.column({ gap = 6 }, roomRows),
    ui.separator({}),
    ui.label({ text = "Now playing - " .. activeRoom, fontWeight = "bold" }),
    transportRow,
    ui.separator({}),
    ui.label({ text = "Favourites", fontWeight = "bold" }),
    ui.scroll({ flexGrow = 1 }, {
      ui.column({ gap = 4 }, favRows),
    }),
  }))
end

noctalia.state.watch("sonos.activeRoom", function(v)
  activeRoom = v or activeRoom
  render()
end)

noctalia.state.watch("sonos.rooms", function(v)
  rooms = v or {}
  render()
end)

noctalia.state.watch("sonos.favorites", function(v)
  favorites = v or {}
  render()
end)

function onOpen(_context)
  noctalia.state.set("sonos.cmd", { action = "REFRESH_FAVORITES" })
  render()
end

function onClose()
end
