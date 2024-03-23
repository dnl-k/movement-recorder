w, h = guiGetScreenSize()
addEvent('onRecordingStateChange')

function outputString(text)
  return outputChatBox(string.format("[MR] %s", text), 255, 255, 255, true)
end

addEventHandler('onClientResourceStart', resourceRoot, function()
  movementRecorder = MR:init()
  interface = UI:init()
end)

addEventHandler('onRecordingStateChange', resourceRoot, function(state)

end)