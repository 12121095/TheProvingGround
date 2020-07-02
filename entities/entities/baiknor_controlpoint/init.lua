AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")


function ENT:Initialize()

	self:SetModel( "models/props_gameplay/cap_point_base.mdl" )
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetUseType(SIMPLE_USE);
	self:SetSolid(SOLID_VPHYSICS);
	local phys = self:GetPhysicsObject()
	phys:SetMass(500000)

	self.phys = phys
	self.LastTime = CurTime()
--	if ( IsValid( phys ) ) then phys:Wake() end
	self.TimerVar = 0 --Variable that counts up, the entity does the major part of its thinking every 5 iterations

	self.pos = self:GetPos()

	self.CapInProgress = 0 --Used for scoreboard to display if a point is being captured
	self.capProgress = 0 --Variable used to track cap ownership
	self.capAt = 10 --Number point is considered captured at in seconds for a neutral point
	self.capMax = 15 --Max time to capture a point that is fully captured
	self.CapOwnership = 0 --who owns the point, 1 for freedom, -1 for duty, 0 for neutral

	self.CapLastState = 0 --Used for playing sounds, tells the last capture state of the point
	self.IsBeingCaptured = 0 --Used for playing the cap alarm noise

	self.PointID = -1 --Adjusted by the spawn command, this adjusts the output signal.
	self.PointName = self.PointName or "Unnamed Point"

	local physObj = self:GetPhysicsObject()

	if physObj:IsValid( ) then physObj:EnableMotion( false ) end


end


function ENT:Think()
	self.TimerVar = self.TimerVar + 1

	if self.TimerVar >= 5 then
	self.TimerVar = 0

	local curtime = CurTime()
	local DelTime = curtime-self.LastTime
	self.LastTime = CurTime()

	local FreedomOnPoint = 0
	local DutyOnPoint = 0

	--Player in range check
	for i, v in ipairs( player.GetAll() ) do
		--self.pos
		local pos = v:GetPos()
		local dist = math.floor(pos:Distance(self.pos)/39.37) --Distance to point in meters

			if dist < 15 then
		local team = v:Team()
--		print( "PlayerName: "..v:Nick() )
--		print( "Distance: "..dist.."m" )
--		print( "Team: "..team )

			if v:Alive() and not v:InVehicle() then

					if team == 1 then
						FreedomOnPoint = FreedomOnPoint + 1
					elseif team == 2 then
						DutyOnPoint = DutyOnPoint	 + 1			
					end
					
			end


			end



	end

	local balance = math.Clamp(FreedomOnPoint - DutyOnPoint,-3,3) --3 capping at once max still allow everyone to override.
	
	if balance != 0 then
	
	self.capProgress = self.capProgress + balance

	if self.capProgress > self.capAt then --Freedom Cap
		self.capProgress = math.min(self.capProgress,self.capMax)

	self.CapOwnership = 1	



	elseif self.capProgress < -self.capAt then --Duty Cap
	
	self.capProgress = math.max(self.capProgress,-self.capMax)

	self.CapOwnership = -1



	else --Neutralized

	self.CapOwnership = 0


		
	end

	else --If nobody is on the point

		if self.CapOwnership == 1 then
		self.capProgress = math.min(self.capProgress+0.5,self.capMax)
		elseif self.CapOwnership == -1 then
		self.capProgress = math.Max(self.capProgress-0.5,-self.capMax) 
		else
		self.capProgress = self.capProgress * 0.5
		end

	end



	--Fin

	if self.CapOwnership == 1 then

	self:SetColor( Color(0, 255*self.capProgress/self.capMax, 0, 255) )

	elseif self.CapOwnership == -1 then

	self:SetColor( Color(255*math.abs(self.capProgress/self.capMax), 0, 0, 255) )

	else

		self:SetColor( Color(255*(1-math.abs(self.capProgress/self.capMax)), 255*(1-math.abs(self.capProgress/self.capMax)), 0, 255) )

	end

	--Sound bits
	local testval = math.ceil(math.abs(balance/3))

	if self.IsBeingCaptured ~= testval and testval > 0 then
		self:EmitSound(Sound("ambient/alarms/doomsday_lift_alarm.wav"), 100, 100, 1, CHAN_VOICE )	
	end

	self.IsBeingCaptured = testval

	testval = self.CapOwnership

	if self.CapOwnership == 1 then
	capOwner = "Freedom"
	elseif self.CapOwnership == -1 then
	capOwner = "Duty"
	end

	if self.CapLastState ~= testval then
		if testval != 0 then
			self:EmitSound(Sound("ambient/alarms/warningbell1.wav"), 100, 100, 1, CHAN_VOICE )	
			PrintMessage(HUD_PRINTTALK, "Point ["..self.PointName.."] Has been captured by "..capOwner.."!")
		else
			self:EmitSound(Sound("ambient/energy/whiteflash.wav"), 100, 100, 1, CHAN_VOICE )	
			PrintMessage(HUD_PRINTTALK, "Point ["..self.PointName.."] Has been neutralized!")
		end
	end

	self.CapLastState = self.CapOwnership

	--print(self.capProgress)


	end


end


function ENT:OnRemove()
end


