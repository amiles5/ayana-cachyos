-- Thin bar widget: no direct speaker calls, just reflects service.luau's
-- state. Click = play/pause the active room, scroll = volume, right-click
-- opens the panel (room switch / grouping / favourites).
local activeRoom = "Dining"
local rooms = {}

local function render()
  local st = rooms[activeRoom] or {}
  local text = activeRoom
  if st.title and st.title ~= "" then
    text = text .. ": " .. st.title
  elseif st.transport == "PLAYING" then
    text = text .. ": Playing"
  elseif st.transport == "PAUSED_PLAYBACK" then
    text = text .. ": Paused"
  elseif not st.transport then
    text = text .. ": ..."
  else
    text = text .. ": Idle"
  end
  if st.volume then
    text = text .. "  " .. st.volume .. "%"
  end

  local icon = "\xE2\x96\xB6" -- ▶
  if st.transport == "PLAYING" then
    icon = "\xE2\x8F\xB8" -- ⏸
  end

  barWidget.render(ui.row({ gap = 6, align = "center" }, {
    ui.label({ text = icon }),
    ui.label({ text = text }),
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

function onClick()
  noctalia.state.set("sonos.cmd", { action = "TOGGLE", room = activeRoom })
end

function onScroll(axis, steps)
  if axis ~= "vertical" then return end
  noctalia.state.set("sonos.cmd", { action = "VOLUME_DELTA", room = activeRoom, delta = steps * 2 })
end

function onRightClick()
  noctalia.togglePanel("milesj/sonos-control:panel")
end

render()
