detector = class()

function detector.client_onCreate( self )
    detector.tool = self.tool
    self.cl = {
        validCapturedBodies = {},
        capturedBodies = {},
        lastBody = {id = nil, tick = sm.game.getCurrentTick()}
    }
end

-- detector.client_onRefresh = detector.client_onCreate

function minVec3(vec)
    return math.min( vec.x, vec.y, vec.z )
end

function detector.cl_receaveBodies( self, bodies )
    for i,body in pairs(bodies) do
        if sm.exists(body) then
            local exist = false
            for i,v in pairs(self.cl.validCapturedBodies) do
                exist = i == body.id
                if exist then break end
            end
            if not exist then
                self:createBodyEffects(body)
                table.insert(self.cl.capturedBodies, body)
            end
        end
    end
end

function detector.createBodyEffects( self, body )
    self.cl.validCapturedBodies[body.id] = true
end

function detector.client_onFixedUpdate( self )
	if true then return end
    for i,body in pairs(self.cl.capturedBodies) do
    	if not sm.exists(body) then
    		self.cl.capturedBodies[i] = nil
    	else
    		local joints = body:getJoints()
    		for i,joint in pairs(joints) do
				-- print(i,joint)
				local shapeA = joint.shapeA
				local size = shapeA:getBoundingBox()*4
				local aa, bb = shapeA:getSticky()
				local validA = true
				if aa.x ~= 0 then
					print(shapeA.localPosition.x+size.x,joint.localPosition.x)
					if shapeA.localPosition+sm.vec3.new(size.x,0,0)>=joint.localPosition then
						print("1")
					else
						print("~1")
					end
				end
				if aa.y ~= 0 then
					print(shapeA.localPosition.y+size.y,joint.localPosition.y)
					if shapeA.localPosition+sm.vec3.new(0,size.y,0)>=joint.localPosition then
						print("2")
					else
						print("~2")
					end
				end
				if aa.z ~= 0 then
					print(shapeA.localPosition.z+size.z,joint.localPosition.z)
					if shapeA.localPosition+sm.vec3.new(0,size.z,1)>=joint.localPosition then
						print("3")
					else
						print("~3")
					end
				end
			end
    	end
    end


    -- print(self.cl.capturedBodies)
end


function detector.client_onUpdate( self, dt )
end

function detector.server_onCreate( self )
    self.sv = {
        bodiesLen = 0,
        lastHighestBodyID = 0
    }
end
-- detector.server_onRefresh = server_onCreate

function detector.server_onFixedUpdate( self, dt )
    --idk if this will happen for ever server side tool or not
    -- ik that the tools have their own client but idk about server (im assuming not)
    local bodies = sm.body.getAllBodies()
    local bodiesLen = #bodies
    -- print(bodiesLen, self.sv.bodiesLen)
    if bodiesLen == 0 then self.sv.bodiesLen = 0 return end
    if bodiesLen == self.sv.bodiesLen then return end
    if not (bodies[bodiesLen].id > self.sv.lastHighestBodyID) then return end
    self.sv.bodiesLen = bodiesLen
    self.sv.lastHighestBodyID = bodies[bodiesLen].id
    
    local players = sm.player.getAllPlayers()
    for i,player in pairs(players) do
        self.network:sendToClient(player, "cl_receaveBodies", bodies)
    end
end