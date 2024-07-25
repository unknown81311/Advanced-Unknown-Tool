lock = class()

function lock.client_onCreate( self )
end

function lock.client_onAction( self, action, state )
	if sm.EditorTool then
		sm.event.sendToTool(sm.EditorTool, "cl_onAction", {action = action, state = state})
	end
	print(action)
	if action == 0 then return false end
	if sm.EditorToolData.requireKey then
		if action == sm.EditorToolData.requireKey then
			return false
		end
	end
	return true
end