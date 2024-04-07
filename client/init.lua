w, h = guiGetScreenSize()
addEvent("onRecordingStateChange")

function outputString(text)
  return outputChatBox(("[MR] %s"):format(text), 255, 255, 255, true)
end

addEventHandler("onClientResourceStart", resourceRoot, function()

end)

addEventHandler("onRecordingStateChange", resourceRoot, function(state)

end)