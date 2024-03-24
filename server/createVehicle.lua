addEvent("mr:createVehicle", true)
addEventHandler("mr:createVehicle", root, function(parameters)
  local id = "MR:Vehicle (" .. countVehicles() .. ")"

  local element = exports.edf:edfCreateElement("vehicle", client, getResourceFromName("editor_main"), {
    model = parameters.model,
    position = parameters.position,
    rotation = parameters.rotation,
    dimension = exports.editor_main:getWorkingDimension(),
    id = id
  }, true)

  element:setColor(255, 255, 255, 255, 255, 255)
  element:setOverrideLights(2)

  element:setID(id)
  element:setFrozen(true)
  element:setDamageProof(true)
  element:setCollisionsEnabled(false)

  triggerEvent("onElementCreate_undoredo", element)
  triggerEvent("onElementCreate", element)
	triggerClientEvent(root, "onClientElementCreate", element)
end)

function countVehicles()
	local counter = 0
	for key, element in pairs(getElementsByType("vehicle")) do
    if string.find(element:getID(), "MR:Vehicle") then counter = counter + 1 end
	end
	return counter
end