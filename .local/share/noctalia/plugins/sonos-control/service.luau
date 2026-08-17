-- Headless Sonos service: polls all rooms every 5s, tracks per-room
-- transport/title/volume/group-coordinator, and handles commands sent
-- by the bar widget and panel via noctalia.state ("sonos.cmd"). This
-- is the single source of truth so bar.luau and panel.luau never talk
-- to the speakers directly - they just watch state and set commands.
local ROOMS = {
  { name = "Bedroom", ip = "192.168.1.181", rincon = "RINCON_7828CAE285F801400" },
  { name = "Dining",  ip = "192.168.1.194", rincon = "RINCON_7828CAE6B2EA01400" },
  { name = "Kitchen", ip = "192.168.1.204", rincon = "RINCON_347E5C35CDB801400" },
}

local activeRoom = "Dining"
local rooms = {}
local favorites = {}
local togglePending = false

local function findRoom(name)
  for _, r in ipairs(ROOMS) do
    if r.name == name then return r end
  end
  return nil
end

local function findByRincon(id)
  for _, r in ipairs(ROOMS) do
    if r.rincon == id then return r end
  end
  return nil
end

-- Single-pass decode (one scan via a replacement table) instead of five
-- chained full-string gsubs - the favourites <Result> blob is big enough
-- that the chained version blew the plugin sandbox's CPU budget.
local XML_ENTITIES = { ["&lt;"] = "<", ["&gt;"] = ">", ["&quot;"] = '"', ["&apos;"] = "'", ["&amp;"] = "&" }
local function decodeEntities(s)
  return (s:gsub("&%a+;", XML_ENTITIES))
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

local function publish()
  noctalia.state.set("sonos.activeRoom", activeRoom)
  noctalia.state.set("sonos.rooms", rooms)
  noctalia.state.set("sonos.favorites", favorites)
end

local function pollRoom(room, cb)
  soap(room.ip, "/MediaRenderer/AVTransport/Control", "AVTransport", "GetPositionInfo",
    "<InstanceID>0</InstanceID>", function(res)
      local coordRincon = room.rincon
      local title = ""
      if res.ok then
        local uri = res.body:match("<TrackURI>(.-)</TrackURI>")
        local rid = uri and uri:match("^x%-rincon:(.+)$")
        if rid then
          coordRincon = rid
        else
          local meta = res.body:match("<TrackMetaData>(.-)</TrackMetaData>")
          if meta and meta ~= "NOT_IMPLEMENTED" then
            meta = decodeEntities(meta)
            title = meta:match("<dc:title>(.-)</dc:title>") or ""
          end
        end
      end
      soap(room.ip, "/MediaRenderer/AVTransport/Control", "AVTransport", "GetTransportInfo",
        "<InstanceID>0</InstanceID>", function(res2)
          local transport = (res2.ok and res2.body:match("<CurrentTransportState>(.-)</CurrentTransportState>")) or "?"
          soap(room.ip, "/MediaRenderer/RenderingControl/Control", "RenderingControl", "GetVolume",
            "<InstanceID>0</InstanceID><Channel>Master</Channel>", function(res3)
              local volume = res3.ok and tonumber(res3.body:match("<CurrentVolume>(.-)</CurrentVolume>")) or nil
              rooms[room.name] = { transport = transport, title = title, volume = volume, coordRincon = coordRincon }
              cb()
            end)
        end)
    end)
end

local pollIndex = 1
local function pollNext()
  if pollIndex > #ROOMS then
    pollIndex = 1
    publish()
    return
  end
  local room = ROOMS[pollIndex]
  pollIndex = pollIndex + 1
  pollRoom(room, pollNext)
end

local function coordIpFor(name)
  local coordRincon = rooms[name] and rooms[name].coordRincon
  local coordRoom = (coordRincon and findByRincon(coordRincon)) or findRoom(name)
  return coordRoom.ip
end

-- Parsing the favourites <Result> blob (decode + gmatch over ~10KB of
-- DIDL-Lite) reliably blew the plugin sandbox's CPU budget for a single
-- "async http callback" invocation, even with minimal per-item work. So
-- the HTTP callback below only stashes the raw text; actual parsing runs
-- inside update() (a separate callback context) one item at a time,
-- spread across ticks so no single invocation does more than one
-- decode+match.
local favoritesRawDidl = nil
local favoritesParseIndex = nil

local function refreshFavorites()
  soap(ROOMS[1].ip, "/MediaServer/ContentDirectory/Control", "ContentDirectory", "Browse",
    "<ObjectID>FV:2</ObjectID><BrowseFlag>BrowseDirectChildren</BrowseFlag><Filter>*</Filter>" ..
    "<StartingIndex>0</StartingIndex><RequestedCount>100</RequestedCount><SortCriteria></SortCriteria>",
    function(res)
      favoritesRawDidl = res.ok and res.body:match("<Result>(.-)</Result>") or nil
      favoritesParseIndex = 1
      favorites = {}
      publish()
    end)
end

-- Advances the favourites parse by exactly one <item>, called from
-- update() each tick until nothing is left to parse. Scans for the
-- still-entity-escaped item markers (&lt;item ... &lt;/item&gt;) so only
-- the one matched item substring needs decoding per call, not the whole
-- multi-KB blob.
local function stepFavoritesParse()
  if not favoritesRawDidl or not favoritesParseIndex then return end
  local from, to = favoritesRawDidl:find("&lt;item.-&lt;/item&gt;", favoritesParseIndex)
  if not from then
    favoritesRawDidl = nil
    favoritesParseIndex = nil
    return
  end
  favoritesParseIndex = to + 1
  local decodedItem = decodeEntities(favoritesRawDidl:sub(from, to))
  local title = decodedItem:match("<dc:title>(.-)</dc:title>")
  if title then
    table.insert(favorites, { title = title, raw = decodedItem })
    publish()
  end
end

function update()
  noctalia.setUpdateInterval(5000)
  stepFavoritesParse()
  pollIndex = 1
  pollNext()
end

local function toggleActive(room)
  if togglePending then return end
  local ip = coordIpFor(room)
  local st = rooms[room]
  local action = (st and st.transport == "PLAYING") and "Pause" or "Play"
  local body = "<InstanceID>0</InstanceID>"
  if action == "Play" then body = body .. "<Speed>1</Speed>" end
  togglePending = true
  soap(ip, "/MediaRenderer/AVTransport/Control", "AVTransport", action, body, function(res)
    togglePending = false
    update()
  end)
end

local function setVolume(room, delta, absolute)
  local r = findRoom(room)
  if not r then return end
  local current = (rooms[room] and rooms[room].volume) or 20
  local newVol = absolute or math.max(0, math.min(100, current + delta))
  soap(r.ip, "/MediaRenderer/RenderingControl/Control", "RenderingControl", "SetVolume",
    "<InstanceID>0</InstanceID><Channel>Master</Channel><DesiredVolume>" .. newVol .. "</DesiredVolume>",
    function(res)
      if rooms[room] then rooms[room].volume = newVol end
      publish()
    end)
end

local function joinGroup(room, targetRoom)
  local r = findRoom(room)
  local targetCoordRincon = (rooms[targetRoom] and rooms[targetRoom].coordRincon)
    or (findRoom(targetRoom) and findRoom(targetRoom).rincon)
  if not r or not targetCoordRincon then return end
  soap(r.ip, "/MediaRenderer/AVTransport/Control", "AVTransport", "SetAVTransportURI",
    "<InstanceID>0</InstanceID><CurrentURI>x-rincon:" .. targetCoordRincon .. "</CurrentURI><CurrentURIMetaData></CurrentURIMetaData>",
    function(res) update() end)
end

local function leaveGroup(room)
  local r = findRoom(room)
  if not r then return end
  soap(r.ip, "/MediaRenderer/AVTransport/Control", "AVTransport", "BecomeCoordinatorOfStandaloneGroup",
    "<InstanceID>0</InstanceID>", function(res) update() end)
end

local function playFavorite(room, index)
  local fav = favorites[index]
  if not fav then return end
  -- fav.raw was already decoded once (same as resMD below), so it's at
  -- the "safe to re-embed in a new XML element" escaping level already -
  -- escaping it again here corrupted every "&" in stream URLs into
  -- "&amp;amp;", which Sonos rejected outright (HTTP 500).
  local resUri = fav.raw:match("<res[^>]*>(.-)</res>")
  local resMD = fav.raw:match("<r:resMD>(.-)</r:resMD>") or ""
  if not resUri then return end
  local ip = coordIpFor(room)
  soap(ip, "/MediaRenderer/AVTransport/Control", "AVTransport", "SetAVTransportURI",
    "<InstanceID>0</InstanceID><CurrentURI>" .. resUri .. "</CurrentURI><CurrentURIMetaData>" .. resMD .. "</CurrentURIMetaData>",
    function(res)
      soap(ip, "/MediaRenderer/AVTransport/Control", "AVTransport", "Play",
        "<InstanceID>0</InstanceID><Speed>1</Speed>", function(res2) update() end)
    end)
end

noctalia.state.watch("sonos.cmd", function(cmd)
  if not cmd then return end
  if cmd.action == "TOGGLE" then
    toggleActive(cmd.room)
  elseif cmd.action == "VOLUME_DELTA" then
    setVolume(cmd.room, cmd.delta, nil)
  elseif cmd.action == "VOLUME_SET" then
    setVolume(cmd.room, nil, cmd.value)
  elseif cmd.action == "SET_ACTIVE" then
    activeRoom = cmd.room
    publish()
  elseif cmd.action == "JOIN" then
    joinGroup(cmd.room, cmd.target)
  elseif cmd.action == "LEAVE" then
    leaveGroup(cmd.room)
  elseif cmd.action == "REFRESH_FAVORITES" then
    refreshFavorites()
  elseif cmd.action == "PLAY_FAVORITE" then
    playFavorite(cmd.room, cmd.index)
  end
end)

publish()
