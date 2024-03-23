UI = {
  metatable = {
    __index = UI
  }
}

function UI:init()
  setmetatable({}, UI.metatable)
  return self
end