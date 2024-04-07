MR = {
  state = false,
  frames = {},
  focusedFrame = nil,

  playback = {
    state = false,
    vehicle = Vehicle(411, 0.0, 0.0, 0.0),
    ped = Ped(83, 0.0, 0.0, 0.0),
    startingPoint = 1,
    currentPosition = nil
  },

  preview = {
    isVisible = false,
    vehicle = Vehicle(411, 0.0, 0.0, 0.0)
  },

  metatable = {
    __index = MR
  }
}

function MR:init()
  setmetatable({}, MR.metatable)

  controls:add({
    ["record_movement"]   =   { key = "r",        friendlyName = "Record Movement",     handler = function() self:toggleRecording() end },
    ["playback"]          =   { key="p",          friendlyName = "Playback Recording",  handler = function() self:togglePlayback() end },
    ["preview_vehicle"]   =   { key = "lctrl",    friendlyName = "Preview Vehicle" },
    ["place_vehicle"]     =   { key = "mouse3",   friendlyName = "Place Vehicle",       handler = function() self:doPlaceVehicle() end }
  })

  self:resetPed(self.playback.ped)
  self:resetVehicle(self.playback.vehicle)
  self:resetVehicle(self.preview.vehicle)

  exports.editor_main:registerEditorElements(self.playback.vehicle)
  exports.editor_main:registerEditorElements(self.playback.ped)
  exports.editor_main:registerEditorElements(self.preview.vehicle)
  
  self.playback.ped:warpIntoVehicle(self.playback.vehicle)

  addEventHandler("onClientRender", root, function() self:onClientRender() end)
  return self
end


-------------------------------------
-- Reset things
-------------------------------------
function MR:resetVehicle(vehicle)
  vehicle:setPosition(0.0, 0.0, 0.0)
  vehicle:setAlpha(200)
  vehicle:setFrozen(true)
  vehicle:setDamageProof(true)
  vehicle:setColor(255, 255, 255, 255, 255, 255)
  vehicle:setCollisionsEnabled(false)
  vehicle:setOverrideLights(2)
  vehicle:addUpgrade(1010)
  vehicle:setData("movementrecorder.frame", nil)
  vehicle:setDimension(localPlayer.dimension + 1)
end


function MR:resetPed(ped)
  ped:setPosition(0.0, 0.0, 0.0)
  ped:setDimension(localPlayer.dimension + 1)
end

function MR:onClientRender()
  local cursorPosition = Vector2(getCursorPosition())
  local node = getNodeFromCursorPosition(self.frames, w * cursorPosition.x, h * cursorPosition.y)
  self.focusedFrame = node

  self:renderLines()
  if self.state then
    self:record()
  end
  self:renderVehicle()
  self:renderPlayback()
  self:renderText()
end

-------------------------------------
-- Renders recorded line
-------------------------------------
function MR:renderLines()
  for i, frame in ipairs(self.frames) do
    dxDrawLine3D(frame.position, i == #self.frames and frame.position or self.frames[i + 1].position, frame.isOnGround and tocolor(255, 255, 255, 255) or tocolor(255, 0, 0, 255))
  end
end

-------------------------------------
-- Displays text while hovering over recorded nodes
-------------------------------------
function MR:renderText()
  if not isCursorShowing() or GuiElement.isMTAWindowActive() or GuiElement.isInputEnabled() then return end
  local cursorPosition = Vector2(getCursorPosition())

  if self.preview.isVisible and self.focusedFrame then
    local frame = self.frames[self.focusedFrame]
    drawHighlighterText(("Press %s to place the recorded vehicle"):format(controls:getKey("place_vehicle")), w * cursorPosition.x, h * cursorPosition.y, 32)

    if frame.nitroCount then
      drawHighlighterText(("Nitro Level: %.2f %s"):format(frame.nitroLevel, (frame.isNitroActivated and "#00ff00•" or (frame.isNitroRecharging and "#ffa500•" or "#ff0000•"))), w * cursorPosition.x, h * cursorPosition.y, 48)
    end

  elseif not self.preview.isVisible and self.focusedFrame then
    drawHighlighterText(("Hold %s to view the recorded vehicle"):format(controls:getKey("preview_vehicle")), w * cursorPosition.x, h * cursorPosition.y, 32)
    drawHighlighterText(("Press %s to start playback from here"):format(controls:getKey("playback")), w * cursorPosition.x, h * cursorPosition.y, 48)
  end
end



-------------------------------------
-- Displays vehicle while hovering over recorded nodes
-------------------------------------
function MR:renderVehicle()
  if self.preview.isVisible and (not control:getState("preview_vehicle") or not self.focusedFrame) then
    exports.editor_main:enableMouseOver(true)
    exports.editor_main:setWorldClickEnabled(true)
    self:resetVehicle(self.preview.vehicle)
    self.preview.isVisible = false
    self.focusedFrame = nil
    return
  end

  if not isCursorShowing() or not control:getState("preview_vehicle") or not self.focusedFrame then return end

  exports.editor_main:enableMouseOver(false)
  exports.editor_main:setWorldClickEnabled(false)

  if self.preview.vehicle:getData("movementrecorder.frame") == self.focusedFrame then return end
  local frame = self.frames[self.focusedFrame]

  self.preview.vehicle:setData("movementrecorder.frame", self.focusedFrame)
  self.preview.vehicle:setModel(frame.model)
  self.preview.vehicle:setPosition(frame.position)
  self.preview.vehicle:setRotation(frame.rotation)
  self.preview.vehicle:setDimension(localPlayer.dimension)

  self.preview.isVisible = true
end


-------------------------------------
-- Places selected node as vehicle
-------------------------------------
function MR:doPlaceVehicle()
  if not self.focusedFrame then return end
  triggerServerEvent("mr:createVehicle", localPlayer, {
    model = self.preview.vehicle:getModel(),
    position = {
      self.preview.vehicle.position.x,
      self.preview.vehicle.position.y,
      self.preview.vehicle.position.z
    },
    rotation = {
      self.preview.vehicle.rotation.x,
      self.preview.vehicle.rotation.y,
      self.preview.vehicle.rotation.z
    }
  })
end


-------------------------------------
-- Handles movement recording
-------------------------------------
function MR:toggleRecording(forcedState)
  if not self.state or (type(forcedState) == "boolean" and forcedState == true) then
    if localPlayer:getData("race.spectating") then return outputString("You cannot do this while spectating.") end
    if not localPlayer:isInVehicle() then return outputString("You must be in a vehicle.") end

    if self.playback.state then
      self:togglePlayback(false)
    end
    self.frames = {}
    self.state = true
  elseif self.state or (type(forcedState) == "boolean" and forcedState == false) then
    self.state = false
  end
  triggerEvent("onRecordingStateChange", resourceRoot, self.state)
end


function MR:record()
  local vehicle = localPlayer:getOccupiedVehicle()
  if not vehicle or localPlayer:isDead() then self:toggleRecording(false) return end
  
  table.insert(self.frames, {
    model = vehicle:getModel(),
    position = vehicle.position,
    rotation = vehicle.rotation,
    health = vehicle:getHealth(),
    nitroCount = vehicle:getNitroCount(),
    isNitroActivated = vehicle:isNitroActivated(),
    isNitroRecharging = vehicle:isNitroRecharging(),
    nitroLevel = vehicle:getNitroLevel(),
    isOnGround = vehicle:isOnGround(),
    controlStates = {
      accelerate = localPlayer:getControlState("accelerate"),
      reverse = localPlayer:getControlState("brake_reverse"),
      steer_left = localPlayer:getControlState("vehicle_left"),
      steer_right = localPlayer:getControlState("vehicle_right")
    }
  })
end


-------------------------------------
-- Handles playback
-------------------------------------
function MR:togglePlayback(forcedState)
  if not self.playback.state or (type(forcedState) == "boolean" and forcedState == true) then
    self.playback.startingPoint = self.focusedFrame and self.focusedFrame or 1
    self.playback.currentPosition = self.playback.startingPoint

    self.playback.state = true
    self.playback.ped:setDimension(localPlayer.dimension)
    self.playback.vehicle:setDimension(localPlayer.dimension)
  elseif self.playback.state or (type(forcedState) == "boolean" and forcedState == false) then
    self.playback.state = false
    self:resetPed(self.playback.ped)
    self:resetVehicle(self.playback.vehicle)
  end
  triggerEvent("onPlaybackStateChange", resourceRoot, self.playback.state)
end

function MR:renderPlayback()
  if not self.playback.state then return end

  local frame = self.frames[self.playback.currentPosition]
  self.playback.vehicle:setAlpha(255)
  self.playback.vehicle:setFrozen(false)
  self.playback.vehicle:setModel(frame.model)
  self.playback.vehicle:setPosition(frame.position)
  self.playback.vehicle:setRotation(frame.rotation)

  if frame.isNitroActivated then
    self.playback.vehicle:setNitroCount(frame.nitroCount)
    self.playback.vehicle:setNitroActivated(frame.isNitroActivated)
  end

  self.playback.ped:setControlState("accelerate", frame.controlStates.accelerate)
  self.playback.ped:setControlState("brake_reverse", frame.controlStates.reverse)
  self.playback.ped:setControlState("vehicle_left", frame.controlStates.steer_left)
  self.playback.ped:setControlState("vehicle_right", frame.controlStates.steer_right)

  self.playback.currentPosition = self.playback.currentPosition + 1
  if self.playback.currentPosition > #self.frames then
    self.playback.currentPosition = self.playback.startingPoint
  end
end
recorder = MR:init()