CM = {
  controls = {},
  metatable = {
    __index = CM
  }
}

function CM:init()
  setmetatable({}, CM.metatable)
  return self
end

function CM:add(controls)
  for i, control in pairs(controls) do
    if self.controls[i] == nil then
      addCommandHandler(control.friendlyName, control.handler and control.handler or function() end)
      bindKey(control.key, "down", control.friendlyName)
      self.controls[i] = control
    else
      outputDebugString(("Duplicate control '%s'"):format(i), 1)
    end
  end
end

function CM:getKey(control)
  if self.controls[control] == nil then return false end
  return getKeyBoundToCommand(self.controls[control].friendlyName)
end

function CM:getState(control)
  if self.controls[control] == nil then return false end
  local key = self:getKey(control)
  local keyState = getKeyState(key)
  return keyState
end
controls = CM:init()