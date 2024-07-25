dofile( "$SURVIVAL_DATA/Scripts/game/survival_constants.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )
dofile( "$CONTENT_DATA/Scripts/api.lua" )

builder = class()

function builder.client_onCreate( self )if not self.tool:isLocal() then return end
	self.cl = {
		gui = class(),
		hudGui = sm.gui.createGuiFromLayout( "$CONTENT_DATA/Gui/Layouts/fake invintory.layout", false, {
		    isHud = true,
		    isInteractive = false,
		    needsCursor = false,
		    hidesHotbar = true,
		    isOverlapped = false,
		    backgroundAlpha = 0.0
		}),
		interactiveGui = sm.gui.createGuiFromLayout( "$CONTENT_DATA/Gui/Layouts/fake invintory.layout", false, {
		    isHud = false,
		    isInteractive = true,
		    needsCursor = true,
		    hidesHotbar = true,
		    isOverlapped = false,
		    backgroundAlpha = 0.0
		}),
		actions = {},
		activeItem = 10,
		paintTool = {
			guiActive = false,
			colorType = 1,
			color = sm.color.new(0xeeeeee)
		},
		gravTool = {
			target = nil,
			distance = 5,
			effect = sm.effect.createEffect( "ShapeRenderable" ) -- to be replaced with custom effect
		},
		liftTool = {
			bodies = {}
		},
		toggleCounter = 0
	}

	self.cl.gravTool.effect:setParameter("visualization", true)
	self.cl.gravTool.effect:setParameter("uuid", sm.uuid.new("628b2d61-5ceb-43e9-8334-a4135566df7a")) -- plastic

	sm.EditorTool = self.tool
	sm.EditorToolData = {requireKey=nil}
	
	self.cl.gui = class()

	self.cl.gui.close = function ()
		self.cl.hudGui:close()
		self.cl.interactiveGui:close()
	end

	self.cl.gui.setButtonState = function ( name, state )
		self.cl.hudGui:setButtonState(name, state)
		self.cl.interactiveGui:setButtonState(name, state)
	end
	self.cl.gui.setIconImage = function ( name, uuid )
		self.cl.hudGui:setIconImage(name, uuid)
		self.cl.interactiveGui:setIconImage(name, uuid)
	end


	self.cl.gui.setButtonState("MainPanel10", true)

	self.cl.gui.setIconImage( "ItemIcon1", sm.uuid.new("fdb8b8be-96e7-4de0-85c7-d2f42e4f33ce") ) -- idk its a weld tool tho
	self.cl.gui.setIconImage( "ItemIcon2", sm.uuid.new("c60b9627-fc2b-4319-97c5-05921cb976c6") ) -- paint tool
	self.cl.gui.setIconImage( "ItemIcon3", sm.uuid.new("8c7efc37-cd7c-4262-976e-39585f8527bf") ) -- connect tool
	self.cl.gui.setIconImage( "ItemIcon4", sm.uuid.new("b1dd7967-da2a-4ff5-a90f-bbd7e9bae4d7") ) -- gravity (pointer lol)
	self.cl.gui.setIconImage( "ItemIcon5", sm.uuid.new("c5ea0c2f-185b-48d6-b4df-45c386a575cc") ) -- spud gun
	self.cl.gui.setIconImage( "ItemIcon6", sm.uuid.new("5cc12f03-275e-4c8e-b013-79fc0f913e1b") ) -- Lift

	self.cl.interactiveGui:setVisible("panel_color", true)

	self.cl.gui.setIconImage( "ItemIcon10", sm.uuid.new("dc0790e3-4599-4057-b80f-27681caaa579") ) -- close


	-- self.cl.interactiveGui
	self.cl.interactiveGui:createHorizontalSlider("Slider1", 256, 0, "client_onSlider1Callback")
	self.cl.interactiveGui:createHorizontalSlider("Slider2", 256, 0, "client_onSlider2Callback")
	self.cl.interactiveGui:createHorizontalSlider("Slider3", 256, 0, "client_onSlider3Callback")
	self.cl.interactiveGui:setTextChangedCallback("Input1", "cl_editHex")


	self.cl.interactiveGui:createDropDown( "color_type", "cl_changeColorType", {"color single","color all","color same type","color same color"} )
	self.cl.interactiveGui:createDropDown( "slider_type", "cl_changeSliderType", {"R G B", "H S L", "H W B"} )
	self.cl.interactiveGui:setButtonCallback( "applyColorTool", "cl_applyColorTool" )

    self.cl.interactiveGui:setColor( "previewColor_icon", sm.color.new("000000") )
    self.cl.interactiveGui:setButtonCallback( "previewColor", "cl_doNth" )
    self.cl.interactiveGui:setButtonState("previewColor", true)

	for button_id, color in pairs( PAINT_COLORS ) do
        local base = "ColorBtn_"..button_id
        self.cl.interactiveGui:setButtonCallback( base, "cl_pickColor" )
        self.cl.interactiveGui:setColor( base.."_icon", sm.color.new(color) )
    end
end
builder.client_onReload = client_onCreate
function builder:cl_doNth()self.cl.interactiveGui:setButtonState("previewColor", true)end

function builder.cl_changeColorType( self, option )
	if option == "color all" then
		self.cl.paintTool.colorType = 1
	elseif option == "color same type" then
		self.cl.paintTool.colorType = 2
	elseif option == "color same color" then
		self.cl.paintTool.colorType = 3
	else
		self.cl.paintTool.colorType = 4
	end
end

function builder.cl_changeSliderType( self, option )
	if option == "R G B" then
		self.cl.sldierType = 1
	elseif option == "H S L" then
		self.cl.sldierType = 2
	else
		self.cl.sldierType = 3
	end
	self:setPaintToolColor(self.cl.paintTool.color,true)
end

local color_id = 0
function builder.cl_pickColor( self, btn )
	self.cl.interactiveGui:setButtonState("ColorBtn_"..color_id, false)
	color_id = tonumber(btn:sub(10, 11))
	self.cl.interactiveGui:setButtonState("ColorBtn_"..color_id, true)
	self.cl.interactiveGui:setButtonState("previewColor", true)

	self:setPaintToolColor(sm.color.new(PAINT_COLORS[color_id]))
end

function builder.client_onSlider1Callback( self, value )
	local color = self.cl.paintTool.color
	if self.cl.sldierType == 1 then -- red
		color.r = value/255
		self:setPaintToolColor(color,true)
	elseif self.cl.sldierType == 2 then -- H S L
		local hsl = rgb_to_hsl(color)
		hsl.h=value/255
		local rgb = hsl_to_rgb(hsl)
		self:setPaintToolColor(sm.color.new(rgb.r,rgb.g,rgb.b),true)
	else -- hwb
		local hwb = rgb_to_hwb(color)
		hwb.h=value/255
		local rgb = hwb_to_rgb(hwb)
		self:setPaintToolColor(sm.color.new(rgb.r,rgb.g,rgb.b),true)
	end
end
function builder.client_onSlider2Callback( self, value )
	local color = self.cl.paintTool.color
	if self.cl.sldierType == 1 then
		color.g = value/255
		self:setPaintToolColor(color,true)
	elseif self.cl.sldierType == 2 then
		local hsl = rgb_to_hsl(color)
		hsl.s=value/255
		local rgb = hsl_to_rgb(hsl)
		self:setPaintToolColor(sm.color.new(rgb.r,rgb.g,rgb.b),true)
	else
		local hwb = rgb_to_hwb(color)
		hwb.w=value/255
		local rgb = hwb_to_rgb(hwb)
		self:setPaintToolColor(sm.color.new(rgb.r,rgb.g,rgb.b),true)
	end
end
function builder.client_onSlider3Callback( self, value )
	local color = self.cl.paintTool.color
	if self.cl.sldierType == 1 then
		color.b = value/255
		self:setPaintToolColor(color,true)
	elseif self.cl.sldierType == 2 then
		local hsl = rgb_to_hsl(color)
		hsl.l=value/255
		local rgb = hsl_to_rgb(hsl)
		self:setPaintToolColor(sm.color.new(rgb.r,rgb.g,rgb.b),true)
	else
		local hwb = rgb_to_hwb(color)
		hwb.b=value/255
		local rgb = hwb_to_rgb(hwb)
		self:setPaintToolColor(sm.color.new(rgb.r,rgb.g,rgb.b),true)
	end
end

function builder.setPaintToolColor( self, color, slider )
	self.cl.paintTool.color = color

	self.cl.interactiveGui:setText("Input1", tostring(self.cl.paintTool.color):sub(1,6):upper())
    self.cl.interactiveGui:setColor( "previewColor_icon", self.cl.paintTool.color )

	if self.cl.sldierType == 1 then
		local r = self.cl.paintTool.color.r*255
		local g = self.cl.paintTool.color.g*255
		local b = self.cl.paintTool.color.b*255

		if slider then
			self.cl.interactiveGui:setSliderPosition("Slider1", r)
			self.cl.interactiveGui:setSliderPosition("Slider2", g)
			self.cl.interactiveGui:setSliderPosition("Slider3", b)
		end

		self.cl.interactiveGui:setText("Value1", ("#ff0000R#ffffff: #ffff00%s#ffffff"):format(math.ceil(r)))
		self.cl.interactiveGui:setText("Value2", ("#00ff00G#ffffff: #ffff00%s#ffffff"):format(math.ceil(g)))
		self.cl.interactiveGui:setText("Value3", ("#0000ffB#ffffff: #ffff00%s#ffffff"):format(math.ceil(b)))
	elseif self.cl.sldierType == 2 then
		local hsl = rgb_to_hsl(self.cl.paintTool.color)

		if slider then
			self.cl.interactiveGui:setSliderPosition("Slider1", hsl.h)
			self.cl.interactiveGui:setSliderPosition("Slider2", hsl.s)
			self.cl.interactiveGui:setSliderPosition("Slider3", hsl.l)
		end

		self.cl.interactiveGui:setText("Value1", ("#ff0000H#ffffff: #ffff00%s#ffffff"):format(math.ceil(hsl.h*360)))
		self.cl.interactiveGui:setText("Value2", ("#00ff00S#ffffff: #ffff00%s#ffffff"):format(math.ceil(hsl.s*100)))
		self.cl.interactiveGui:setText("Value3", ("#0000ffL#ffffff: #ffff00%s#ffffff"):format(math.ceil(hsl.l*100)))
	else
		local hwb = rgb_to_hwb(self.cl.paintTool.color)
		if slider then
			self.cl.interactiveGui:setSliderPosition("Slider1", hwb.h*255)
			self.cl.interactiveGui:setSliderPosition("Slider2", hwb.w*255)
			self.cl.interactiveGui:setSliderPosition("Slider3", hwb.b*255)
		end

		self.cl.interactiveGui:setText("Value1", ("#ff0000H#ffffff: #ffff00%s#ffffff"):format(math.ceil(hwb.h*360)))
		self.cl.interactiveGui:setText("Value2", ("#00ff00W#ffffff: #ffff00%s#ffffff"):format(math.ceil(hwb.w*100)))
		self.cl.interactiveGui:setText("Value3", ("#0000ffB#ffffff: #ffff00%s#ffffff"):format(math.ceil(hwb.b*100)))
	end
end

function builder.server_onCreate( self )
	self.sv = {
		host = sm.shape.createPart(sm.uuid.new("dc0790e3-4599-4057-b80f-27681caaa579"), sm.vec3.new(0,0,-9999999), nil, false, true),
		destroyUnits = {}
	}

	self.network:sendToClient(self.tool:getOwner(), "cl_getHost", self.sv.host)
end

function builder.cl_getHost( self, host )
	self.cl.host = host
end

function builder.client_onToggle( self )
	self.cl.toggleCounter= self.cl.toggleCounter + 1
	return false
end

function builder.client_onEquippedUpdate( self, lmb, rmb )if not self.tool:isLocal() then return end
	sm.camera.setDirection(sm.localPlayer.getPlayer().character.direction)

	if lmb == 3 then
		lmbActive = true
		self.cl.actions = {}
		self.cl.hudGui:open()
		sm.camera.setCameraState( sm.camera.state.cutsceneTP )
		sm.camera.setFov( sm.camera.getDefaultFov() )
		sm.localPlayer.getPlayer().character:setLockingInteractable( self.cl.host.interactable )
		self.tool:getOwner().character:setNameTag( self.tool:getOwner().name, sm.color.new(0xe2db13ff), false, 99999999999, 99999999999 )
	end

	return true, true
end

function builder.client_onFixedUpdate( self )
	if self.cl.setActive then
	end
end

function builder.cl_onAction( self, data )
	local state = data.state
	local action = data.action
	for i,v in pairs(sm.interactable.actions) do
		if v == action then
			self.cl.actions[i] = state
			return
		end
	end
end

local sm_vec3_lerp = sm.vec3.lerp

local useAction = false


function builder.client_onUpdate( self )if not self.tool:isLocal() then return end
	local actions = self.cl.actions

	local owner = self.tool:getOwner()

	local character = owner.character
	local sprinting = character:isSprinting()
	
	local direction = character.direction
	local position = character.worldPosition
	local cameraPos = sm.camera.getPosition()

	if actions.forward then
		if sprinting then
			cameraPos = cameraPos + direction
		else
			cameraPos = cameraPos + direction/5
		end
	elseif actions.backward then
		if sprinting then
			cameraPos = cameraPos - direction
		else
			cameraPos = cameraPos - direction/5
		end
	end

	if actions.left then
		cameraPos = cameraPos - sm.camera.getRight()/5
	elseif actions.right then
		cameraPos = cameraPos + sm.camera.getRight()/5
	end

	if actions.jump then
		cameraPos = cameraPos + sm.vec3.new(0,0,.2)
	end

	if character:isCrouching() then
		cameraPos = cameraPos - sm.vec3.new(0,0,.2)
	end


	sm.camera.setPosition(cameraPos)

	function filter(tbl, predicate)
	    local result = {}
	    for key, value in pairs(tbl) do
	        if predicate(value, key, tbl) then
	            result[key] = value
	        end
	    end
	    return result
	end

	if self.cl.activeItem == 1 then
		if actions.create then
			self.cl.actions.create = false
			sm.gui.chatMessage("unimplemented")
		end
	elseif self.cl.activeItem == 2 then -- [[ PAINT TOOL ]]
		if actions.create then
			self.cl.actions.create = false
			local active, raycast = sm.physics.raycast(cameraPos, cameraPos + direction * 999, character, 4099+4)
			if active then
				if raycast.type == "character" then
					self.network:sendToServer("sv_colorObject", {
						color = self.cl.paintTool.color,
						object = raycast:getCharacter(),
						type = 1,
						colorType = self.cl.paintTool.colorType
					})
				elseif raycast.type == "body" then
					self.network:sendToServer("sv_colorObject", {
						color = self.cl.paintTool.color,
						object = raycast:getShape(),
						type = 2, colorType = self.cl.paintTool.colorType
					})
				elseif raycast.type == "joint" then
					self.network:sendToServer("sv_colorObject", {
						color = self.cl.paintTool.color,
						object = raycast:getJoint(),
						type = 3,
						colorType = self.cl.paintTool.colorType
					})
				end
			end
		end
		if actions.attack then
			self.cl.actions.attack = false
			local active, raycast = sm.physics.raycast(cameraPos, cameraPos + direction * 999, character, 4099+4)
			if active then
				if raycast.type == "character" then
					self.network:sendToServer("sv_deColorObject", {
						object = raycast:getCharacter(),
						type = 1,
						colorType = self.cl.paintTool.colorType
					})
				elseif raycast.type == "body" then
					self.network:sendToServer("sv_deColorObject", {
						object = raycast:getShape(),
						type = 2,
						colorType = self.cl.paintTool.colorType
					})
				elseif raycast.type == "joint" then
					self.network:sendToServer("sv_deColorObject", {
						object = raycast:getJoint(),
						type = 3,
						colorType = self.cl.paintTool.colorType
					})
				end
			end
		end
		if actions.use then
			self.cl.interactiveGui:open()
		end
	elseif self.cl.activeItem == 3 then
		if actions.create then
			self.cl.actions.create = false
			sm.gui.chatMessage("unimplemented")
		end
	elseif self.cl.activeItem == 4 then -- [[ GAVITY GUN ]]
		if actions.create then
			if not self.cl.gravTool.target then
				local active, raycast = sm.physics.spherecast(cameraPos, cameraPos + direction * 999, 0.1)
				if active then
					if raycast.type == "character" then
						self.cl.gravTool.target = raycast:getCharacter()
						self.cl.gravTool.targetType = raycast.type
						self.cl.gravTool.distance = raycast.fraction*999
					elseif raycast.type == "body" and not raycast:getBody():isStatic() then
						self.cl.gravTool.target = raycast:getBody()
						self.cl.gravTool.targetType = raycast.type
						self.cl.gravTool.distance = raycast.fraction*999
					end
				end
			end
			if actions.zoomOut then
				self.cl.actions.zoomOut = false
				self.cl.gravTool.distance = self.cl.gravTool.distance - 1
			elseif actions.zoomIn then
				self.cl.actions.zoomIn = false
				self.cl.gravTool.distance = self.cl.gravTool.distance + 1
			end

			if self.cl.gravTool.target then
			if not sm.exists(self.cl.gravTool.target) then self.cl.gravTool.effect:stop() return end
				self.network:sendToServer("sv_gravTool", {
					type = 4,
					data = {
						target = self.cl.gravTool.target,
						distance = self.cl.gravTool.distance,
						targetType = self.cl.gravTool.targetType
					},
					cameraPos = cameraPos
				})
				
				if not self.cl.gravTool.effect:isPlaying() then
					self.cl.gravTool.effect:start()
				end
				self.cl.gravTool.effect:setVelocity( self.tool:getMovementVelocity() )
				if self.cl.gravTool.targetType == "character" then
					lineTo(cameraPos-sm.vec3.new(0,0,1), self.cl.gravTool.target.worldPosition, self.cl.gravTool.effect)
					-- self.cl.gravTool.effect:setPosition( cameraPos-sm.vec3.new(0,0,1) )
				else
					local pos = cameraPos + sm.vec3.new( 0, 0, 0.8 ) + ( direction * self.cl.gravTool.distance )

					lineTo(cameraPos-sm.vec3.new(0,0,1), self.cl.gravTool.target:getCenterOfMassPosition(), self.cl.gravTool.effect)
					-- self.cl.gravTool.effect:setPosition( cameraPos-sm.vec3.new(0,0,1) )
				end
			elseif self.cl.gravTool.effect:isPlaying() then
				self.cl.gravTool.effect:stop()
			end
		else
			self.cl.gravTool.target = nil
			self.cl.gravTool.distance = 5
			if self.cl.gravTool.effect:isPlaying() then
				self.cl.gravTool.effect:stop()
			end
		end
	elseif self.cl.activeItem == 5 then
		if actions.create then
			self.cl.actions.create = false

			sm.projectile.projectileAttack( projectile_potato, 7.5, cameraPos, direction * 130, self.tool:getOwner() )
		end
		if actions.attack then
			sm.camera.setFov( 20 )
		else
			sm.camera.setFov( sm.camera.getDefaultFov() )
		end
	elseif self.cl.activeItem == 6 then -- [[ LIFT ]]
		local active, raycast = sm.physics.spherecast(cameraPos, cameraPos + direction * 999, 0.1)

		local __liftPos = raycast.pointWorld * 4
		local liftPos = sm.vec3.new( math.floor( __liftPos.x + 0.5 ), math.floor( __liftPos.y + 0.5 ), math.floor( __liftPos.z + 0.5 ) )/4
		sm.visualization.setLiftPosition( liftPos )
		
		local okPosition, liftLevel = sm.tool.checkLiftCollision( self.cl.liftTool.bodies, liftPos, self.cl.toggleCounter%4 )


		if #self.cl.liftTool.bodies==0 and raycast.type=="body" then
			local body = raycast:getBody()
			if not body:isOnLift() and not body:isStatic() then
				sm.visualization.setCreationBodies( body:getCreationBodies() )
				sm.visualization.setCreationFreePlacement( false )		
				sm.visualization.setCreationValid( true, true )
				sm.visualization.setLiftValid( true )
				sm.visualization.setCreationVisible( true )
				sm.visualization.setLiftVisible( false )
			end
		elseif #self.cl.liftTool.bodies==0 and raycast.type=="joint" then
			local body = raycast:getJoint().shapeA.body
			if not body:isOnLift() and not body:isStatic() then
				sm.visualization.setCreationBodies( body:getCreationBodies() )
				sm.visualization.setCreationFreePlacement( false )		
				sm.visualization.setCreationValid( true, true )
				sm.visualization.setLiftValid( true )
				sm.visualization.setCreationVisible( true )
				sm.visualization.setLiftVisible( false )
			end
		else
			if #self.cl.liftTool.bodies~=0 then
				print(liftLevel)
				sm.visualization.setCreationBodies( self.cl.liftTool.bodies )
				sm.visualization.setCreationFreePlacement( true )
				sm.visualization.setCreationFreePlacementPosition( liftPos + sm.vec3.new(0,0,0.5) + sm.vec3.new(0,0,0.25)*liftLevel )
				sm.visualization.setCreationFreePlacementRotation( self.cl.toggleCounter%4 )
				sm.visualization.setCreationVisible( true )
				sm.visualization.setLiftLevel( liftLevel )
				sm.visualization.setLiftVisible( true )
			else
				sm.visualization.setCreationValid( true, false )
				sm.visualization.setLiftLevel( 0 )
				sm.visualization.setLiftVisible( true )
			end
		end

		if actions.create then
			if sm.EditorToolData.requireKey == 15 then
				sm.EditorToolData.requireKey = nil
			end
			self.cl.actions.create = false
			if active then 
				if #self.cl.liftTool.bodies~= 0 then
					self.network:sendToServer("sv_placeLift", {creation=self.cl.liftTool.bodies, position= liftPos, level=liftLevel, rotation = self.cl.toggleCounter%4})
					self.cl.liftTool.bodies = {}
				else
					local fitlerBodies = function(value, key, tbl)
						return not value:isOnLift() and not value:isStatic()
					end
					if raycast.type=="body" then
						local body = raycast:getBody()
						if not body:isOnLift() and not body:isStatic() then
							self.cl.liftTool.bodies = filter(body:getCreationBodies(), fitlerBodies)
						else
							self.network:sendToServer("sv_placeLift", {creation={}, position = liftPos })
						end
					elseif raycast.type=="joint" then
						local body = raycast:getJoint().shapeA.body
						if not body:isOnLift() then
							self.cl.liftTool.bodies = filter(body:getCreationBodies(), fitlerBodies)
						else
							self.network:sendToServer("sv_placeLift", {creation={}, position = liftPos })
						end
					else
						self.network:sendToServer("sv_placeLift", {creation={}, position = liftPos })
					end
				end
			end
		end
		if raycast.type=="lift" then
			sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use", true ), "#{INTERACTION_USE}" )
		end
		if sm.EditorToolData.requireKey ~= 15 then
			if actions.use and not useAction then
				useAction = true
				sm.EditorToolData.requireKey = 15
				-- local pos = position*4
				local a,shit =  sm.localPlayer.getRaycast(10000000)


				
				self.network:sendToServer("sv_placeLift", {creation={}, position = sm.localPlayer.getRaycastStart()+sm.localPlayer.getDirection()*2})
			elseif not actions.use then
				useAction = false
			end
		elseif sm.EditorToolData.requireKey == 15 then
			if actions.use and not useAction then
				useAction = true
				sm.EditorToolData.requireKey = nil
				self.network:sendToServer("sv_placeLift", {creation={}, position = liftPos })
			elseif not actions.use then
				useAction = false
			end

		end
		if actions.attack then
			self.cl.actions.attack = false
			if active then --  and raycast.type=="lift"
				if #self.cl.liftTool.bodies == 0 then
					self.network:sendToServer("sv_deleteLift")
				else
					self.cl.liftTool.bodies = {}
				end
			end
		end
	elseif self.cl.activeItem == 10 then
		if actions.create then
			self.cl.gui:close()
			sm.camera.setCameraState( 0 )
			character:setLockingInteractable( nil )
			character:setNameTag( "" )
		end
	else
		if actions.create then
			self.cl.actions.create = false
			sm.gui.chatMessage("unimplemented")
		end
	end

	if self.cl.activeItem ~= 6 then
		sm.visualization.setCreationVisible( false )
		sm.visualization.setLiftVisible( false )
	end

	local function changeSlotState(idx, state)

	    local cl_gui = self.cl.gui
	    cl_gui.setButtonState("MainPanel" .. idx, state)
	    cl_gui.setButtonState("Binding" .. idx, state)
	end

	local function scrollItem(idx)
	    --switch the old state off
	    changeSlotState(self.cl.activeItem, false)
	    --update the state for the new slot
	    changeSlotState(idx, true)

	    --update the state
	    self.cl.activeItem = idx
	    self.cl.actions["item" .. idx] = false
	end

	if not actions.create then
		if actions.item0 then
		    scrollItem(1)
		elseif actions.item1 then
		    scrollItem(2)
		elseif actions.item2 then
		    scrollItem(3)
		elseif actions.item3 then
		    scrollItem(4)
		elseif actions.item4 then
		    scrollItem(5)
		elseif actions.item5 then
		    scrollItem(6)
		elseif actions.item6 then
		    scrollItem(7)
		elseif actions.item7 then
		    scrollItem(8)
		elseif actions.item8 then
		    scrollItem(9)
		elseif actions.item9 then
			print("10")
		    scrollItem(10)
		end

		if actions.zoomOut then
			print("a")
			self.cl.actions.zoomOut = false
			scrollItem(math.min(self.cl.activeItem+1,10))
		elseif actions.zoomIn then
			self.cl.actions.zoomIn = false
			print("b")
			scrollItem(math.max(self.cl.activeItem-1,1))
		end
	end
end

local oldLift = sm.player.placeLift

sm.player.placeLift = function(a,b,c,d,e)
print("liftHook",a,b,c,d,e)
oldLift(a,b,c,d,e)
end

function builder.sv_placeLift( self, data, caller )
	print(data)
	caller:placeLift(data.creation, data.position*4, data.level or 0, data.rotation or 0 )
end
function builder.sv_deleteLift( self, _, caller )
	print(caller)
	caller:removeLift()
end

function builder.sv_gravTool( self, info, caller )
	local character = caller.character
	data = info.data
	if info.type == 4 then
		local dir = character:getDirection()
		local pos = info.cameraPos + sm.vec3.new( 0, 0, 0.8 ) + ( dir * data.distance )
		if data.targetType == "character" then
			if not sm.exists(data.target) then return end
			local GrabbedCharacterPos = (data.target:isTumbling() and data.target:getTumblingWorldPosition()) or data.target.worldPosition
			local GrabbedCharacterMass = (data.target:isTumbling() and 75) or data.target:getMass()

			print(GrabbedCharacterMass)

			local force = pos - GrabbedCharacterPos
			local vel = data.target:getVelocity()

			force = force * GrabbedCharacterMass * 2
			force = force - (vel * GrabbedCharacterMass * 0.3)

			if data.target:isTumbling() then
			    data.target:applyTumblingImpulse(force)
			else
			    sm.physics.applyImpulse(data.target, force, true)
			end
		else
			local bodyShape = data.target:getShapes()[1]
			local force = pos - data.target:getCenterOfMassPosition()
			local velocity = data.target.velocity

			force = force * data.target.mass * 2
			force = force - (velocity * data.target.mass * 0.3)
			sm.physics.applyImpulse(data.target, force, true)

			local angularVelocity = -data.target:getAngularVelocity() / 5
			local angularForce = angularVelocity * data.target:getMass()

			if sm.vec3.length(angularForce) > 0.001 then
			    sm.physics.applyTorque(data.target, angularForce * 1 / 40, true)
			end
		end
	end
end

function builder.sv_deColorObject( self, data, caller )
	local object = data.object
	local color = data.color
	local objType = data.type
	local colorType = data.colorType
	if objType == 1 then
		table.insert(self.sv.destroyUnits, {unit = sm.unit.createUnit( object:getCharacterType(), sm.vec3.new(0,0,-9999999) ), baseChar = object})
		return	
	end
	print(object, colorType)
	if colorType == 4 then
		object.color = sm.item.getShapeDefaultColor(object.uuid)
	elseif colorType == 1 then -- ALL
		if objType == 2 then -- shape
			local shapes = object.body:getCreationShapes()
			for i,v in pairs(shapes) do
				v.color = sm.item.getShapeDefaultColor(v.uuid)
			end
		elseif objType == 3 then -- joint
			local joints = object.shapeA.body:getCreationJoints()
			for i,v in pairs(joints) do
				v.color = sm.item.getShapeDefaultColor(v.uuid)
			end
		end
	elseif colorType == 2 then -- TYPE
		if objType == 2 then -- shape
			local shapes = object.body:getCreationShapes()
			for i,v in pairs(shapes) do
				if v.uuid == object.uuid then
					v.color = sm.item.getShapeDefaultColor(v.uuid)
				end
			end
		elseif objType == 3 then -- joint
			local joints = object.shapeA.body:getCreationJoints()
			for i,v in pairs(joints) do
				if v.uuid == object.uuid then
					v.color = sm.item.getShapeDefaultColor(v.uuid)
				end
			end
		end
	elseif colorType == 3 then -- COLOR
		if objType == 2 then -- shape
			local shapes = object.body:getCreationShapes()
			for i,v in pairs(shapes) do
				if v.color == object.color then
					v.color = sm.item.getShapeDefaultColor(v.uuid)
				end
			end
		elseif objType == 3 then -- joint
			local joints = object.shapeA.body:getCreationJoints()
			for i,v in pairs(joints) do
				if v.color == object.color then
					v.color = sm.item.getShapeDefaultColor(v.uuid)
				end
			end
		end
	end
end

function builder.server_onFixedUpdate( self )
	for i,v in pairs(self.sv.destroyUnits) do
		if v and sm.exists(v.unit) and sm.exists(v.unit:getCharacter()) then 
			v.baseChar.color = v.unit:getCharacter().color
			v.unit:destroy()
			self.sv.destroyUnits[i]=nil
		end
	end
	local character = self.tool:getOwner().character
	local pos = character.worldPosition

	if pos.z<-90 or (pos + character.velocity).z<-90 then
		local newPos = pos
		newPos.z = 3

		sm.physics.applyImpulse( character, (character.velocity*-50), true )
		character:setWorldPosition( newPos )
	end
end

function builder.sv_colorObject( self, data, caller )
	local object = data.object
	local color = data.color
	local objType = data.type
	local colorType = data.colorType

	if objType == 1 or colorType == 4 then -- characters or single
		object.color = color
		return
	end

	if colorType == 1 then -- ALL
		if objType == 2 then -- shape
			local shapes = object.body:getCreationShapes()
			for i,v in pairs(shapes) do
				v.color = color
			end
		elseif objType == 3 then -- joint
			local joints = object.shapeA.body:getCreationJoints()
			for i,v in pairs(joints) do
				v.color = color
			end
		end
	elseif colorType == 2 then -- TYPE
		if objType == 2 then -- shape
			local shapes = object.body:getCreationShapes()
			for i,v in pairs(shapes) do
				if v.uuid == object.uuid then
					v.color = color
				end
			end
		elseif objType == 3 then -- joint
			local joints = object.shapeA.body:getCreationJoints()
			for i,v in pairs(joints) do
				if v.uuid == object.uuid then
					v.color = color
				end
			end
		end
	elseif colorType == 3 then -- COLOR
		if objType == 2 then -- shape
			local shapes = object.body:getCreationShapes()
			for i,v in pairs(shapes) do
				if v.color == object.color then
					v.color = color
				end
			end
		elseif objType == 3 then -- joint
			local joints = object.shapeA.body:getCreationJoints()
			for i,v in pairs(joints) do
				if v.color == object.color then
					v.color = color
				end
			end
		end
	end
end