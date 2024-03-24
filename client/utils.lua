function getNodeFromCursorPosition(frames, cX, cY)
  if not isCursorShowing() then return nil end
  local node = nil
  for i = 1, #frames do
    local nsX, nsY = getScreenFromWorldPosition(frames[i].position, 50.0, false)
    if nsX then
      local distance = getDistanceBetweenPoints2D(cX, cY, nsX, nsY)
      if distance < 40 then
        node = i
        break
      end
    end
  end
  return node
end

function drawHighlighterText(text, posX, posY, offsetY)
  if exports.editor_gui:guiGetMouseOverElement() then return end
  local fontHeight = dxGetFontHeight(1, "default")
  local textWidth = dxGetTextWidth(text, 1, "default")
  local posX = posX - (textWidth / 2)
  local posY = posY + offsetY
  dxDrawText(text, posX, posY , posX + textWidth, posY + fontHeight, -3618561, 1, "default", "center", "center", false, false, false, true)
end