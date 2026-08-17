-- Sonos bar widget: click to play/pause, scroll to change volume,
-- right-click to cycle between rooms. Talks directly to each speaker's
-- local UPnP/SOAP control endpoint on port 1400 - no cloud account,
-- no bridge process. RINCON ids let us resolve a grouped/follower
-- speaker's TrackURI (x-rincon:<id>) back to whichever room is
-- actually the group coordinator, since that's the only one with real
-- transport state and track metadata.
local ROOMS = {
  { name = "Bedroom", ip = "192.168.1.181", rincon = "RINCON_7828CAE285F801400" },
  { name = "Dining",  ip = "192.168.1.194", rincon = "RINCON_7828CAE6B2EA01400" },
  { name = "Kitchen", ip = "192.168.1.204", rincon = "RINCON_347E5C35CDB801400" },
}

local roomIndex = 1
local state = { transport = "?", title = "", volume = nil, coordIp = nil, pending = false }

local function currentRoom()
  return ROOMS[roomIndex]
end

local function findRincon(id)
  for _, r in ipairs(ROOMS) do
    if r.rincon == id then return r end
  end
  return nil
end

local function decodeEntities(s)
  return (s:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&amp;", "&"))
end

local function soap(ip, path, service, action, body, cb)
  local envelope = '<?xml version="1.0" encoding="utf-8"?>' ..
    '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">' ..
    '<s:Body><u:' .. action .. ' xmlns:u="urn:schemas-upnp-org:service:' .. service .. ':1">' ..
    body ..
    '</u:' .. action .. '></s:Body></s:Envelope>'
  noctalia.http({
    url = "http://" .. ip .. ":1400" .. path,
    method = "POST",
    headers = {
      'Content-Type: text/xml; charset="utf-8"',
      'SOAPAction: "urn:schemas-upnp-org:service:' .. service .. ':1#' .. action .. '"',
    },
    body = envelope,
  }, cb)
end

local function render()
  local room = currentRoom()
  local text = room.name
  if state.title and state.title ~= "" then
    text = text .. ": " .. state.title
  elseif state.transport == "PLAYING" then
    text = text .. ": Playing"
  elseif state.transport == "PAUSED_PLAYBACK" then
    text = text .. ": Paused"
  elseif state.transport == "?" then
    text = text .. ": ..."
  else
    text = text .. ": Idle"
  end
  if state.volume then
    text = text .. "  " .. state.volume .. "%"
  end

  local icon = "\xE2\x96\xB6" -- ▶
  if state.transport == "PLAYING" then
    icon = "\xE2\x8F\xB8" -- ⏸
  end

  barWidget.render(ui.row({ gap = 6, align = "center" }, {
    ui.label({ text = icon }),
    ui.label({ text = text }),
  }))
end

local function resolveCoordinatorIp(room, cb)
  soap(room.ip, "/MediaRenderer/AVTransport/Control", "AVTransport", "GetPositionInfo",
    "<InstanceID>0</InstanceID>", function(res)
      if not res.ok then cb(room.ip); return end
      local uri = res.body:match("<TrackURI>(.-)</TrackURI>")
      if uri then
        local rinconId = uri:match("^x%-rincon:(.+)$")
        if rinconId then
          local coord = findRincon(rinconId)
          cb(coord and coord.ip or room.ip)
          return
        end
      end
      cb(room.ip)
    end)
end

function update()
  noctalia.setUpdateInterval(5000)
  local room = currentRoom()
  resolveCoordinatorIp(room, function(coordIp)
    state.coordIp = coordIp
    soap(coordIp, "/MediaRenderer/AVTransport/Control", "AVTransport", "GetTransportInfo",
      "<InstanceID>0</InstanceID>", function(res)
        state.transport = res.ok and (res.body:match("<CurrentTransportState>(.-)</CurrentTransportState>") or "?") or "?"
        soap(coordIp, "/MediaRenderer/AVTransport/Control", "AVTransport", "GetPositionInfo",
          "<InstanceID>0</InstanceID>", function(res2)
            state.title = ""
            if res2.ok then
              local meta = res2.body:match("<TrackMetaData>(.-)</TrackMetaData>")
              if meta and meta ~= "NOT_IMPLEMENTED" then
                meta = decodeEntities(meta)
                state.title = meta:match("<dc:title>(.-)</dc:title>") or ""
              end
            end
            soap(room.ip, "/MediaRenderer/RenderingControl/Control", "RenderingControl", "GetVolume",
              "<InstanceID>0</InstanceID><Channel>Master</Channel>", function(res3)
                if res3.ok then
                  state.volume = tonumber(res3.body:match("<CurrentVolume>(.-)</CurrentVolume>"))
                end
                render()
              end)
          end)
      end)
  end)
end

function onClick()
  if state.pending then return end
  local ip = state.coordIp or currentRoom().ip
  local action = (state.transport == "PLAYING") and "Pause" or "Play"
  local body = "<InstanceID>0</InstanceID>"
  if action == "Play" then body = body .. "<Speed>1</Speed>" end
  state.pending = true
  soap(ip, "/MediaRenderer/AVTransport/Control", "AVTransport", action, body, function(res)
    state.pending = false
    update()
  end)
end

function onScroll(axis, steps)
  if axis ~= "vertical" then return end
  local room = currentRoom()
  local newVol = math.max(0, math.min(100, (state.volume or 20) + steps * 2))
  soap(room.ip, "/MediaRenderer/RenderingControl/Control", "RenderingControl", "SetVolume",
    "<InstanceID>0</InstanceID><Channel>Master</Channel><DesiredVolume>" .. newVol .. "</DesiredVolume>",
    function(res)
      state.volume = newVol
      render()
    end)
end

function onRightClick()
  roomIndex = (roomIndex % #ROOMS) + 1
  state.transport = "?"
  state.title = ""
  state.volume = nil
  render()
  update()
end
