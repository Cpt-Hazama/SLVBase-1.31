AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')
include('schedules.lua')

if(util.GMIsAftermath()) then
	include('init_aftm.lua');
end

AccessorFunc(ENT, "iClass", "NPCClass", FORCE_NUMBER)
AccessorFunc(ENT, "AIType", "AIType", FORCE_NUMBER)
AccessorFunc(ENT, "m_fMaxYawSpeed", "MaxYawSpeed", FORCE_NUMBER)
AccessorFunc(ENT, "fSoundLevel", "SoundLevel", FORCE_NUMBER)
AccessorFunc(ENT, "fSoundPitch", "SoundPitch", FORCE_NUMBER)
AccessorFunc(ENT, "fSoundVolume", "SoundVolume", FORCE_NUMBER)

ENT.m_fMaxYawSpeed 				= 20 // Max turning speed
ENT.iClass					= CLASS_NONE // NPC Class
ENT.AIType = 2				// 1 = Static NPC (e.g. Sentry), 2 = Ground, 3 = Air, 5 = Water

ENT.bScripted = true
ENT.bWander = true
ENT.iWanderDelay = 10
ENT.fWanderDistance = 100
ENT.fFollowDistance = 380
ENT.nHostileOnDamage = 3

---- Not yet implemented
--ENT.bAgressive = true
--ENT.AggroRadius = 512
--ENT.nConfidence = 3			-- 0 = Cowardly, 1 = Cautious, 2 = Average, 3 = Brave, 4 = Foolhardy
--ENT.nAssistance = 0			-- 0 = Helps Nobody, 1 = Helps Allies, 2 = Helps Friends and Allies
----

ENT.fHearDistance = 450
ENT.fViewDistance = 20000
ENT.fViewAngle = 90

ENT.iBloodType = BLOOD_COLOR_RED
ENT.bInvincible = false
ENT.bPlayIdle = true
ENT.bIgnoreRagdollDamage = true
ENT.bIgnitable = true
ENT.bFreezable = true
ENT.bFlinchOnDamage = true
ENT.tblIgnoreDamageTypes = {}
ENT.tblFlinchActivities = {}
ENT.tblDeathActivities = {}

ENT.bPlayDeathSequence = false
ENT.bFadeOnDeath = false
ENT.bRemoveOnDeath = false
ENT.bExplodeOnDeath = false
ENT.bSpecialDeath = false

ENT.tblSourceSounds = {}
ENT.sSoundDir = ""
ENT.fSoundPitch = 100
ENT.fSoundVolume = 100

ENT.tblAlertAct = {}
ENT.iAlertRandom = 1
ENT.idleChance = 3

ENT.tblCRelationships = {
	[D_NU] = {"monster_gman", "npc_seagull", "npc_antlion_grub", "npc_barnacle", "monster_cockroach", "npc_pigeon", "npc_crow"},
	[D_FR] = {"npc_strider","npc_combinegunship","npc_combinedropship", "npc_helicopter"},
	[D_HT] = {"obj_sentrygun", "npc_clawscanner", "npc_headcrab_poison", "npc_stalker"}
}

ENT.bNeutral = false

local schdWander = ai_schedule.New("Wnd")
schdWander:EngTask("TASK_GET_PATH_TO_RANDOM_NODE", 384)
schdWander:AddTask("TASK_WALK_PATH")
schdWander:EngTask("TASK_WAIT_FOR_MOVEMENT")
schdWander.bForceSelSched = true

function ENT:Task_TASK_WALK_PATH()
end

function ENT:TaskStart_TASK_WALK_PATH()
	self:SetCustomMovementActivity(self:GetWalkActivity())
	local tasks = self.CurrentSchedule.Tasks
	if tasks[#tasks].FunctionName != "Task_TASK_RESET_MOVEMENT" then
		self.CurrentSchedule:AddTask("TASK_RESET_MOVEMENT")
	end
	self.customMoveSched = self.CurrentSchedule
	self:TaskComplete()
end

function ENT:Task_TASK_RUN_PATH()
end

function ENT:TaskStart_TASK_RUN_PATH()
	self:SetCustomMovementActivity(self:GetRunActivity())
	local tasks = self.CurrentSchedule.Tasks
	if tasks[#tasks].FunctionName != "Task_TASK_RESET_MOVEMENT" then
		self.CurrentSchedule:AddTask("TASK_RESET_MOVEMENT")
	end
	self.customMoveSched = self.CurrentSchedule
	self:TaskComplete()
end

function ENT:Task_TASK_CUSTOM_MOVE_PATH()
end

function ENT:TaskStart_TASK_CUSTOM_MOVE_PATH(data)
	self:SetCustomMovementActivity(data)
	local tasks = self.CurrentSchedule.Tasks
	if tasks[#tasks].FunctionName != "Task_TASK_RESET_MOVEMENT" then
		self.CurrentSchedule:AddTask("TASK_RESET_MOVEMENT")
	end
	self.customMoveSched = self.CurrentSchedule
	self:TaskComplete()
end

function ENT:Task_TASK_RESET_MOVEMENT()
end

function ENT:TaskStart_TASK_RESET_MOVEMENT()
	self:SetCustomMovementActivity()
	self:TaskComplete()
end

local schdWanderNoNode = ai_schedule.New("Wnd")
schdWanderNoNode:EngTask("TASK_GET_PATH_TO_LASTPOSITION")
schdWanderNoNode:AddTask("TASK_WALK_PATH")
schdWanderNoNode:EngTask("TASK_WAIT_FOR_MOVEMENT")
schdWanderNoNode:EngTask("TASK_WAIT", 0.2)
schdWanderNoNode:AddTask("TASK_CHECK_PATH_TIME_WND", 0)
schdWanderNoNode.bForceSelSched = true

function ENT:Task_TASK_CHECK_PATH_TIME_WND()
end

function ENT:TaskStart_TASK_CHECK_PATH_TIME_WND()
	self.fWanderDelay = CurTime() +self:GetPathTimeToGoal() +math.Rand(0,6)
	self:TaskComplete()
end

local schdFollow = ai_schedule.New("Flw")
schdFollow:EngTask("TASK_GET_PATH_TO_TARGET", 0)
schdFollow:EngTask("TASK_WAIT", 0.1)
//schdFollow:EngTask("TASK_RUN_PATH_WITHIN_DIST", 125)
//schdFollow:EngTask("TASK_STOP_MOVING")

local schdMoveToLastPosition = ai_schedule.New("MvLP")
schdMoveToLastPosition:EngTask("TASK_GET_PATH_TO_LASTPOSITION")
schdMoveToLastPosition:EngTask("TASK_WAIT_FOR_MOVEMENT")

local schdMoveToLastPositionTimed = ai_schedule.New("MvLPTmd")
schdMoveToLastPositionTimed:EngTask("TASK_GET_PATH_TO_LASTPOSITION")
schdMoveToLastPositionTimed:EngTask("TASK_WAIT", 0.2)

local schdChase = ai_schedule.New("ChsEnmy")
schdChase:EngTask("TASK_GET_CHASE_PATH_TO_ENEMY")
schdChase:EngTask("TASK_WAIT", 0.2)

local schdChaseTarget = ai_schedule.New("ChsTgt")
schdChaseTarget:EngTask("TASK_GET_PATH_TO_TARGET")
schdChaseTarget:EngTask("TASK_WAIT", 0.2)

function ENT:TaskStart_TASK_RUN_PATH_TIMED(data)
	self.pathMoveEnd = CurTime() +data
end

function ENT:Task_TASK_RUN_PATH_TIMED(data)
	local posSelf = self:GetPos()
	local posMove
	local fDist = self:OBBDistance(self.entEnemy)
	if /*fDist <= 500 || */#self.path == 0 || (#self.path == 1 && (posSelf:Distance(self.path[1].pos) <= 120 || posSelf:Distance(self.path[1].pos) > fDist)) then
		if fDist > 260 then fDist = 230 else fDist = fDist -(self.entEnemy:OBBMaxs().x +self:OBBMaxs().x) end
		posMove = posSelf +(self.entEnemy:GetPos() -posSelf):GetNormal() *fDist
	elseif self.path[1] then
		if self:GetPos():Distance(self.path[1].pos) <= 60 || self:GetPathTimeToGoal() < 1 then	// 120
			table.remove(self.path, 1)
		end
		if self.path[1] then
			local flDist = self:GetPos():Distance(self.path[1].pos) //self.path[1].pos:Distance(self:NearestPoint(self.path[1].pos))
			if flDist > 260 then flDist = 230 end// else flDist = flDist -(self.entEnemy:OBBMaxs().x +self:OBBMaxs().x) end
			posMove = posSelf +(self.path[1].pos -posSelf):GetNormal() *flDist //self.path[1].pos
		end
	end
	if !posMove then self:TaskComplete(); return end
	self:SetLastPosition(posMove)
	self:SetMovementActivity(self:GetRunActivity())
	self:StartSchedule(schdMoveToLastPosition)
	if CurTime() < self.pathMoveEnd then return end
	self:TaskComplete()
end

function ENT:Initialize()
	self:SetModel(self.sModel)

	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_STEP)

	self:SetMaxYawSpeed(self.m_fMaxYawSpeed)
	
	self:CapabilitiesAdd(CAP_SQUAD)
	self:SetUpEnemies()
	self.tblSounds = {}
	self:InitSounds()
	self.tblMemory = {}
	self.iMemCount = 0
	self.tblMemBlockedNodeLinks = {}
	self.tblDeleteOnDeathEnts = {}
	self.tblGestureLayers = {}
	self.lastHitGroupDamage = 0
	self.iDmgCount = 0
	self.nextFlinch = 0
	self.nextIdle = 0
	self.schdWait = CurTime() +0.2
	self.nextPathGenSteps = 0
	self.nextAlertToIdle = 0
	self.nextTurnOnDmg = 0
	self.iState = NPC_STATE_IDLE
	self.tblHostilePlayers = {}
	
	if self.bWander then self.fWanderDelay = 0 end
	self:SetBehavior(0)
	self:SetUseType(SIMPLE_USE)
	self:SetSchedule(1)
	
	if table.HasValue(self.tblIgnoreDamageTypes, DMG_DISSOLVE) then
		self:NoCollide("prop_combine_ball")
	end
	self.tblIncomingGrenades = {}
	
	if self.tblKeyValues then
		for k, v in pairs(self.tblKeyValues) do
			self:KeyValueHandle(k, v)
		end
	end
	self:OnInit()
	self:InitLimbs()
end

/*local function GetState(st)
	return st == NPC_STATE_INVALID && "NPC_STATE_INVALID" || st == NPC_STATE_PRONE && "NPC_STATE_PRONE" || st == NPC_STATE_IDLE && "NPC_STATE_IDLE" || st == NPC_STATE_SCRIPT && "NPC_STATE_SCRIPT" || st == NPC_STATE_DEAD && "NPC_STATE_DEAD" || st == NPC_STATE_PLAYDEAD && "NPC_STATE_PLAYDEAD" || st == NPC_STATE_COMBAT && "NPC_STATE_COMBAT" || st == NPC_STATE_ALERT && "NPC_STATE_ALERT" || st == NPC_STATE_NONE && "NPC_STATE_NONE" || st == NPC_STATE_LOST && "NPC_STATE_LOST"
end*/
function ENT:OnStateChanged(old, new)
end

function ENT:SetState(i)
	if i == self.iState then return end
	if i == NPC_STATE_ALERT || i == NPC_STATE_LOST then self.nextAlertToIdle = CurTime() +math.Rand(12,18) end
	local old = self.iState
	self.iState = i
	self:OnStateChanged(old, i)
end

function ENT:GetState()
	return self.iState
end

function ENT:OnInit()
end

function ENT:_PossAttackThink(entPossessor, iInAttack)
	self:TurnDegree(3,entPossessor:GetAimVector():Angle())
end

function ENT:SetWalkActivity(act)
	if self:IsWalking() then self:SetMovementActivity(act) end
	self.actWalk = (act != ACT_WALK && act) || nil
end

function ENT:SetRunActivity(act)
	if self:IsRunning() then self:SetMovementActivity(act) end
	self.actRun = (act != ACT_RUN && act) || nil
end

function ENT:SetCustomMovementActivity(act)
	if self:IsMoving() then self:SetMovementActivity(act) end
	self.actCMove = act
end

function ENT:SetDefaultArrivalActivity(act)
	if self:IsMoving() then self:SetArrivalActivity(act) end
	self.m_actArrival = act
end

function ENT:GetWalkActivity()
	return self.actWalk || ACT_WALK
end

function ENT:GetRunActivity()
	return self.actRun || ACT_RUN
end

function ENT:SetIdleActivity(act)
	self.actIdle = (act != ACT_IDLE && act) || nil
end

function ENT:GetIdleActivity()
	return self.actIdle || ACT_IDLE
end

function ENT:InitSandbox()
	if !self:GetSquad() then self:SetSquad(self:GetClass() .. "_sbsquad") end
end

function ENT:Ignitable()
	return self.bIgnitable
end

function ENT:KeyValueHandle(key, value)
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	//print("Keyvalue: " .. key .. " = " .. value)
	
	self.tblKeyValues = self.tblKeyValues || {}
	if tonumber(value) then value = tonumber(value) end
	self.tblKeyValues[key] = value
end

function ENT:InitSounds()
	self.tblSounds = {}
	self.tblSourceSounds["BaseClass"] = nil
	for name, sounds in pairs(self.tblSourceSounds) do
		local tbl = type(sounds) == "table" && sounds || {sounds}
		for _, sound in pairs(tbl) do
			local br = string.find(sound, "[[]")
			if br then
				local _br = string.find(sound, "[]]", br +1)
				if _br then
					local str = string.sub(sound, br +1, _br -1)
					local sep = string.find(str, "-")
					if sep then
						local Start = string.sub(str, 1, sep -1)
						Start = tonumber(Start)
						local End = string.sub(str, sep +1, string.len(str))
						End = tonumber(End)
						if Start && End then
							if type(sounds) != "table" then self.tblSourceSounds[name] = {}
							else self.tblSourceSounds[name][_] = nil end
							local strStart = string.sub(sound, 1, br -1)
							local strEnd = string.sub(sound, _br +1, string.len(sound))
							for i = Start, End do
								table.insert(self.tblSourceSounds[name], strStart .. i .. strEnd)
							end
						end
					end
				end
			end
		end
		if type(sounds) == "table" then table.refresh(self.tblSourceSounds[name]) end
		self.tblSounds[name] = {}
	end
	self.tblCSPStopOnDeath = {}
end

function ENT:SelectScheduleHandle()
end

function ENT:Flinch(hitgroup)
	local act = self.tblFlinchActivities[hitgroup] || self.tblFlinchActivities[HITGROUP_GENERIC] || self.tblFlinchActivities[HITBOX_GENERIC]
	if !act then return end
	self:PlayActivity(act)
end

local schdChaseNoNode = ai_schedule.New("ChsEnmyDr")
schdChaseNoNode:EngTask("TASK_GET_PATH_TO_LASTPOSITION")
schdChaseNoNode:EngTask("TASK_WAIT", 0.2)

local schdChaseNoNodeClose = ai_schedule.New("ChsEnmyDrCl")
schdChaseNoNodeClose:EngTask("TASK_GET_PATH_TO_TARGET")
schdChaseNoNodeClose:EngTask("TASK_WAIT", 0.1)

function ENT:ChaseDirect(entTarget)
	entTarget = entTarget || self.entEnemy
	self.bDirectChase = true
	local posSelf = self:GetPos()
	local posRun
	local enemyData = self:GetMemory()[entTarget]
	local ent = self:GetTargetEntity(entTarget)
	local posEnemyLast,dirEnemyLast
	if ent == entTarget then
		if enemyData then
			posEnemyLast = enemyData.lastPos
			dirEnemyLast = enemyData.lastDir
		end
	else posEnemyLast = ent:GetPos(); dirEnemyLast = Vector(0,0,0) end
	if posEnemyLast && entTarget == self.entEnemy then
		entTarget = ent
		self.nextNodeMovement = nil
		local fDist = posSelf:Distance(posEnemyLast)
		if fDist < 270 || self.moveEnemyStart then
			if !self.moveEnemyStart then self.moveEnemyStart = CurTime() end
			local flDist = 230
			local posStart = posSelf +Vector(0,0,10)
			local obbMax = self:OBBMaxs()
			local dirEnemyLast = enemyData.visible && (entTarget:GetPos() -self:GetPos()):GetNormal() || dirEnemyLast
			local tr = util.TraceHull({
				start = posStart,
				endpos = posStart +dirEnemyLast *flDist,
				--mask = MASK_NPCWORLDSTATIC,
				filter = self,
				mins = self:OBBMins(),
				maxs = obbMax
			})
			if tr.Hit then
				flDist = posSelf:Distance(tr.HitPos) -self:OBBMaxs().y
				if flDist < 40 then
					self:ClearCondition(COND_TASK_FAILED)
					self:StartSchedule(schdChase)
					if !self:HasCondition(COND_TASK_FAILED) then
						self.nextNodeMovement = nil
						self.moveEnemyStart = nil
						return
					end
					self:RemoveFromMemory(self.entEnemy)
					return
				end
			end
			posRun = posSelf +dirEnemyLast *flDist
		else
			if fDist > 260 then fDist = 230 end
			local normal = (posEnemyLast -posSelf):GetNormal()
			local posStart = posSelf +Vector(0,0,10)
			local posEnd = posStart +normal *fDist
			local tr = self:CreateTrace(posEnd +Vector(0,0,10), nil, posStart)
			if tr.Hit then fDist = posSelf:Distance(tr.HitPos) -(self:OBBMaxs().y +10) end
			posRun = self:GetPos() +normal *fDist
		end
	else
		entTarget = ent
		if self:OBBDistance(entTarget) <= 550 then
			self:SetTarget(entTarget)
			self:StartSchedule(schdChaseNoNodeClose)
			return
		end
		local fDist = entTarget:NearestPoint(posSelf +entTarget:OBBCenter()):Distance(posSelf)
		fDist = fDist -(self:OBBMaxs().x +30)
		fDist = math.min(fDist, 550)
		posRun = posSelf +(entTarget:GetPos() -posSelf):GetNormal() *fDist
	end
	
	local trace = util.TraceLine({start = posRun +Vector(0,0,100), endpos = posRun -Vector(0,0,100), mask = MASK_NPCWORLDSTATIC})
	posRun = trace.HitPos
	
	self:SetLastPosition(posRun)
	self:StartSchedule(schdChaseNoNode)
end

local schdChaseCustomNode = ai_schedule.New("RnLP")
schdChaseCustomNode:EngTask("TASK_GET_PATH_TO_LASTPOSITION")
schdChaseCustomNode:EngTask("TASK_WAIT", 0.2)
schdChaseCustomNode:AddTask("TASK_CHECK_PATH_TIME")

function ENT:Task_TASK_CHECK_PATH_TIME()
end

function ENT:TaskStart_TASK_CHECK_PATH_TIME()
	self:TaskComplete()
	self.currentPathTime = self:GetPathTimeToGoal()
	if !self.currentNodePos || self.currentNodePos != self.currentPath[1].pos || (self.lastPathCheck && CurTime() -self.lastPathCheck >= 0.65) then
		local tm = CurTime() +self.currentPathTime
		if self.pathTargetDistToNode > 0 then tm = tm +(self.currentPathTime /450) *self.pathTargetDistToNode end
		self.estimPathArrival = tm
	elseif self.estimPathArrival -CurTime() <= -1 then
		if #self.currentPath > 1 then
			local IDCur = self.currentPath[1].ID
			local IDNext = self.currentPath[2].ID
			self.tblMemBlockedNodeLinks[IDCur] = self.tblMemBlockedNodeLinks[IDCur] || {}
			table.insert(self.tblMemBlockedNodeLinks[IDCur], IDNext)
			self.currentPath = nil
			self.pathObj = nil
			self.pathObjTgt = nil
			return
		else
			local iAIType = self:GetAIType()
			local nodeClosest = nodegraph.GetClosestNode(self:GetPos(), iAIType)
			local nodeNext = self.currentPath[1]
			local nodes = nodegraph.GetNodes(iAIType)
			for _, data in pairs(nodeClosest.links) do
				if nodes[data.dest].pos == nodeNext.pos then
					local IDCur = nodeClosest.ID
					local IDNext = nodeNext.ID
					self.tblMemBlockedNodeLinks[IDCur] = self.tblMemBlockedNodeLinks[IDCur] || {}
					table.insert(self.tblMemBlockedNodeLinks[IDCur], IDNext)
					self.currentPath = nil
					self.pathObj = nil
					self.pathObjTgt = nil
					return
				end
			end
		end
	end
	self.lastPathCheck = CurTime()
	self.currentNodePos = self.currentPath && self.currentPath[1].pos || nil
end

function ENT:GeneratePath(tTarget)
	local bEnt = type(tTarget) != "Vector"
	local tTargetR = tTarget
	if bEnt then tTarget = self:GetTargetEntity(tTarget) end
	if bEnt && !tTarget:IsValid() then return end
	local pos = bEnt && tTarget:GetPos() || tTarget
	local iAIType = self:GetAIType()
	if self.pathObj then return self.currentPath -- Path hasn't been completely calculated yet, returning last path
	elseif !self.currentPath || #self.currentPath == 0 || (bEnt && nodegraph.GetClosestNode(pos, iAIType).pos != self.currentPath[#self.currentPath].pos) then
		/*
		if self.currentPath && self.estimPathArrival && #self.currentPath == 0 && self.estimPathArrival -CurTime() <= -1 then
			local nodeSelf = nodegraph.GetClosestNode(self:GetPos(), iAIType)
			local nodeTgt = nodegraph.GetClosestNode(pos, iAIType)
			local nodes = nodegraph.GetNodes(iAIType)
			for _, data in pairs(nodeSelf.links) do
				if nodes[data.dest].pos == nodeTgt.pos then
					self.tblMemBlockedNodeLinks[nodeSelf.ID] = self.tblMemBlockedNodeLinks[nodeSelf.ID] || {}
					table.insert(self.tblMemBlockedNodeLinks[nodeSelf.ID], nodeTgt.ID)
					self.estimPathArrival = nil
					break
				end
			end
		end*/
		self.pathObj = nodegraph.CreateAstarObject(self:GetPos(), pos, iAIType, self:GetHullType(), function(nodeCur, nodeNeigh)
			local IDCur = nodeCur.ID
			local IDNext = nodeNeigh.ID
			return (!self.tblMemBlockedNodeLinks[IDCur] || !table.HasValue(self.tblMemBlockedNodeLinks[IDCur], IDNext)) && (!self.tblMemBlockedNodeLinks[IDNext] || !table.HasValue(self.tblMemBlockedNodeLinks[IDNext], IDCur))
		end) -- Creating new astar object
		self.pathObjTgt = tTargetR
		return
	else
		local posSelf = self:GetPos()
		local bPathValid
		if #self.currentPath > 0 then
			local nodeClosest = nodegraph.GetClosestNode(posSelf, iAIType)
			if self.currentPath[1].pos == nodeClosest.pos then bPathValid = true -- Path is valid (Closest node is first node in path)
			else
				local tblNodes = nodegraph.GetNodes(iAIType)
				for k, data in pairs(self.currentPath[1].links) do
					if tblNodes[data.dest].pos == nodeClosest.pos then
						bPathValid = true -- Path is valid(Closest node is linked to first node in path)
						break
					end
				end
			end
		end
		if !bPathValid then -- Path is invalid
			self.pathObj = nodegraph.CreateAstarObject(posSelf, pos, iAIType, self:GetHullType(), function(nodeCur, nodeNeigh)
				local IDCur = nodeCur.ID
				local IDNext = nodeNeigh.ID
				return (!self.tblMemBlockedNodeLinks[IDCur] || !table.HasValue(self.tblMemBlockedNodeLinks[IDCur], IDNext)) && (!self.tblMemBlockedNodeLinks[IDNext] || !table.HasValue(self.tblMemBlockedNodeLinks[IDNext], IDCur))
			end) -- Creating new astar object
			self.pathObjTgt = tTargetR
			return
		end
	end
	local path = self.currentPath
	local numPath = #path
	if self:GetPos():Distance(path[1].pos) <= self:OBBMaxs().x *0.25/*85*/ && self:VisibleVec(path[1].pos +self:OBBCenter()) then
		table.remove(path, 1)
		numPath = numPath -1
	end
	if numPath >= 2 then
		local posSelf = self:GetPos()
		local obbMax = self:OBBMaxs()
		local zCenter = obbMax.z *0.5
		local posEnd = Vector(path[2].pos.x, path[2].pos.y, path[2].pos.z)
		local trA = util.TraceLine({start = posSelf +Vector(obbMax.x, 0, zCenter), endpos = posEnd +Vector(obbMax.x, 0, zCenter), mask = MASK_NPCWORLDSTATIC})
		local trB = util.TraceLine({start = posSelf +Vector(-obbMax.x, 0, zCenter), endpos = posEnd +Vector(-obbMax.x, 0, zCenter), mask = MASK_NPCWORLDSTATIC})
		local trC = util.TraceLine({start = posSelf +Vector(0, obbMax.y, zCenter), endpos = posEnd +Vector(0, obbMax.y, zCenter), mask = MASK_NPCWORLDSTATIC})
		local trD = util.TraceLine({start = posSelf +Vector(0, -obbMax.y, zCenter), endpos = posEnd +Vector(0, -obbMax.y, zCenter), mask = MASK_NPCWORLDSTATIC})
		if !trA.Hit && !trB.Hit && !trC.Hit && !trD.Hit && /*self:VisibleVec(path[2].pos +self:OBBCenter()) &&*/ path[2].pos:Distance(path[1].pos) >= self:NearestPoint(path[2].pos):Distance(path[2].pos) then
			table.remove(path, 1)
			numPath = numPath -1
		end
	end
	if bEnt && numPath == 1 then
		if self:NearestPoint(path[1].pos):Distance(path[1].pos) >= self:OBBDistance(tTarget) then
			table.remove(path, 1)
			numPath = numPath -1
		end
	end
	return path
end

function ENT:GetCurrentPath()
	return self.currentPath || {}
end

function ENT:MoveToPos(pos, bWalk, bTimed)
	local tr = util.TraceLine({start = pos +Vector(0,0,100), endpos = pos -Vector(0,0,100), filter = self})
	pos = tr.HitPos
	local posSelf = self:GetPos()
	local dist = posSelf:Distance(pos)
	tr = util.TraceLine({start = posSelf +Vector(0,0,10), endpos = pos +Vector(0,0,10), filter = self})
	if tr.Hit then dist = posSelf:Distance(tr.HitPos) -self:OBBMaxs().y end
	self:SetLastPosition(posSelf +(pos -posSelf):GetNormal() *dist)
	self:SetMovementActivity(bWalk && self:GetWalkActivity() || self:GetRunActivity())
	self:StartSchedule(!bTimed && schdMoveToLastPosition || schdMoveToLastPositionTimed)
end

function ENT:GetOBBDistanceToTarget(ent)
	return self:OBBDistance(self:GetTargetEntity(ent))
end

function ENT:GetTargetEntity(ent)
	return (ent:IsScriptedNPC() || ent:IsPlayer()) && ent:KnockedDown() && ent:GetRagdollEntity() || ent
end

function ENT:ChaseTarget(ent, bEnemy, bCMove)
	self:SetMovementActivity(self:GetRunActivity())
	if nodegraph.Exists() then--&& !self:HasCondition(COND_TASK_FAILED) then
		if nodegraph.IsEdited() && GetConVarNumber("sv_customnodegraph_enabled") == 1 then
			local mem = self:GetMemory()
			local bVisible
			if !bEnemy then bVisible = self:Visible(ent)
			else bVisible = mem[ent].visible end
			local posLast
			if bEnemy && !bVisible then
				self:UpdateLastEnemyPositions()
				posLast = self:GetLastEnemyPosition()
			end
			local dist = posLast && self:NearestPoint(posLast):Distance(posLast) || self:GetOBBDistanceToTarget(ent)
			if posLast && dist <= 50 then
				posLast = nil
				local dir = self:GetLastEnemyMovement()
				if !mem[ent].lost && dir then
					local center = self:OBBCenter()
					local posStart = self:GetPos() +center
					local posEnemyLast = mem[ent].lastPos
					mem[ent].lost = true
					mem[ent].lastPos = nodegraph.GetClosestNode(posStart +dir *800, self:GetAIType()).pos
					posLast = mem[ent].lastPos
					self.currentPath = nil
					self.pathObj = nil
				elseif !bVisible then
					self.currentPath = nil
					self:RemoveFromMemory(ent)
					self:SetState(NPC_STATE_LOST)
					return
				end
			end
			if posLast then bVisible = self:VisibleVec(posLast) end
			if !bVisible || dist > 80 then	-- && > 550 && !self:HasCondition(COND_TASK_FAILED) then???
				local path = self:GeneratePath(posLast || ent)
				if path then
					local numPath = #path
					if numPath > 0 && (numPath != 1 || (posLast && dist > posLast:Distance(path[1].pos)) || (!posLast && dist > ent:NearestPoint(path[1].pos):Distance(path[1].pos))) then
						if self.currentNodePos && self.currentPathTime then
							local estTime
							if numPath > 1 then
								local yawA = (path[1].pos -self:GetPos()):GetNormal():Angle().y
								local yawB = (path[1].pos -path[2].pos):GetNormal():Angle().y
								local yaw = (360 +yawA) -yawB
								local sin = math.abs(math.cos(math.Deg2Rad(yaw)))
								estTime = 0.8 *sin
							else estTime = 0.8 end
							if (self.currentNodePos == path[1].pos && self.currentPathTime > 0 && self.currentPathTime <= estTime) then --|| self:NearestPoint(path[1].pos):Distance(path[1].pos) <= 85 then
								table.remove(self.currentPath, 1)
								numPath = numPath -1
								path = self.currentPath
							end
						end
						if numPath > 0 then
							local pos = path[1].pos
							if bVisible && self:NearestPoint(pos):Distance(pos) > dist then
								self:ChaseDirect(ent)
								return
							end
							local posSelf = self:GetPos()
							local dist = posSelf:Distance(pos)
							if dist > 600 then
								pos = posSelf +(pos -posSelf):GetNormal() *600
								self.pathTargetDistToNode = dist -600
							else self.pathTargetDistToNode = 0 end
							local tr = util.TraceLine({start = pos +Vector(0,0,100), endpos = pos -Vector(0,0,100), mask = MASK_NPCWORLDSTATIC})
							self:SetLastPosition(tr.HitPos)--path[1].pos)
							if !bCMove then self:StartSchedule(schdChaseCustomNode)
							else
								self.m_MoveCPos = tr.HitPos
								self.m_tMoveCTimeOut = CurTime() +0.2
							end
							self.bDirectChase = false
						else self:ChaseDirect(ent) end
					elseif bVisible then self:ChaseDirect(ent) end
				end
			else self:ChaseDirect(ent) end
		else
			if bEnemy then self:StartSchedule(schdChase)
			else
				self:SetTarget(ent)
				self:StartSchedule(schdChaseTarget)
			end
			self.bDirectChase = true
		end
	else
		--if nodegraph.Exists() then
			if !self.nextNodeMovement then self.nextNodeMovement = CurTime() +3
			elseif CurTime() >= self.nextNodeMovement then
				self.nextNodeMovement = CurTime() +3
				self.bDirectChase = true
				self:ClearCondition(COND_TASK_FAILED)
				if bEnemy then self:StartSchedule(schdChase)
				else
					self:SetTarget(ent)
					self:StartSchedule(schdChaseTarget)
				end
				self.bDirectChase = false
				if !self:HasCondition(COND_TASK_FAILED) then
					self.nextNodeMovement = nil
					self.moveEnemyStart = nil
					return
				end
			end
		--end
		self:ChaseDirect(ent)
	end
end

function ENT:ChaseEnemy()
	self:ChaseTarget(self.entEnemy, true)
end

local schdHide = ai_schedule.New("Hid") 
schdHide:EngTask("TASK_FIND_COVER_FROM_ENEMY", 0) 
schdHide:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)

local schdHideCustomNode = ai_schedule.New("HidNG") 
schdHideCustomNode:EngTask("TASK_GET_PATH_TO_LASTPOSITION")
schdHideCustomNode:EngTask("TASK_WAIT", 0.2)
schdHideCustomNode:AddTask("TASK_CHECK_PATH_TIME_HIDE")

function ENT:Task_TASK_CHECK_PATH_TIME_HIDE()
end

function ENT:TaskStart_TASK_CHECK_PATH_TIME_HIDE()
	self:TaskComplete()
	self.currentPathTime = self:GetPathTimeToGoal()
	if !self.currentNodePos || self.currentNodePos != self.currentPath[1].pos || (self.lastPathCheck && CurTime() -self.lastPathCheck >= 0.65) then
		local tm = CurTime() +self.currentPathTime
		if self.pathTargetDistToNode > 0 then tm = tm +(self.currentPathTime /600) *self.pathTargetDistToNode end
		self.estimPathArrival = tm
	elseif self.estimPathArrival -CurTime() <= -1 then
		if #self.currentPath > 1 then
			local IDCur = self.currentPath[1].ID
			local IDNext = self.currentPath[2].ID
			self.tblMemBlockedNodeLinks[IDCur] = self.tblMemBlockedNodeLinks[IDCur] || {}
			table.insert(self.tblMemBlockedNodeLinks[IDCur], IDNext)
			self.currentPath = nil
			self.pathObj = nil
			self.pathObjTgt = nil
			return
		else
			local iAIType = self:GetAIType()
			local nodeClosest = nodegraph.GetClosestNode(self:GetPos(), iAIType)
			local nodeNext = self.currentPath[1]
			local nodes = nodegraph.GetNodes(iAIType)
			for _, data in pairs(nodeClosest.links) do
				if nodes[data.dest].pos == nodeNext.pos then
					local IDCur = nodeClosest.ID
					local IDNext = nodeNext.ID
					self.tblMemBlockedNodeLinks[IDCur] = self.tblMemBlockedNodeLinks[IDCur] || {}
					table.insert(self.tblMemBlockedNodeLinks[IDCur], IDNext)
					self.currentPath = nil
					self.pathObj = nil
					self.pathObjTgt = nil
					return
				end
			end
		end
	end
	self.lastPathCheck = CurTime()
	self.currentNodePos = self.currentPath[1].pos
end

function ENT:Hide()
	self:SetMovementActivity(self:GetRunActivity())
	if nodegraph.IsEdited() && GetConVarNumber("sv_customnodegraph_enabled") == 1 then
		if !self.nodeHide then
			local pos = self:GetPos()
			local nodes = nodegraph.FindNodesInSphere(pos,2000,self:GetAIType())
			local nodeHide
			local dist = 2000
			local i = 0
			for _, node in pairs(nodes) do
				i = i +1
				if !self.entEnemy:VisibleVec(node.pos +Vector(0,0,20)) then
					local _dist = node.pos:Distance(pos)
					if _dist < dist then
						nodeHide = node
						dist = _dist
					end
				end
				if i >= 50 then break end
			end
			self.nodeHide = nodeHide
		end
		if self.nodeHide then
			local posSelf = self:GetPos()
			local dist = posSelf:Distance(self.nodeHide.pos)
			local bVisible = self:Visible(self.entEnemy)
			if bVisible then
				local path = self:GeneratePath(self.nodeHide.pos)
				if path then
					local numPath = #path
					if numPath > 0 then
						if self.currentNodePos && self.currentPathTime then
							local estTime
							if numPath > 1 then
								local yawA = (path[1].pos -self:GetPos()):GetNormal():Angle().y
								local yawB = (path[1].pos -path[2].pos):GetNormal():Angle().y
								local yaw = (360 +yawA) -yawB
								local sin = math.abs(math.cos(math.Deg2Rad(yaw)))
								estTime = 0.8 *sin
							else estTime = 0.8 end
							if (self.currentNodePos == path[1].pos && self.currentPathTime > 0 && self.currentPathTime <= estTime) then --|| self:NearestPoint(path[1].pos):Distance(path[1].pos) <= 85 then
								table.remove(self.currentPath, 1)
								numPath = numPath -1
								path = self.currentPath
							end
						end
						if numPath > 0 then
							local pos = path[1].pos
							local dist = posSelf:Distance(pos)
							if dist > 600 then
								pos = posSelf +(pos -posSelf):GetNormal() *600
								self.pathTargetDistToNode = dist -600
							else self.pathTargetDistToNode = 0 end
							local tr = util.TraceLine({start = pos +Vector(0,0,100), endpos = pos -Vector(0,0,100), mask = MASK_NPCWORLDSTATIC})
							self:SetLastPosition(tr.HitPos)--path[1].pos)
							self:StartSchedule(schdHideCustomNode)
							self.bDirectChase = false
						else self.nodeHide = nil end
					else self.nodeHide = nil end
				end
			end
		end
	else self:StartSchedule(schdHide) end
end

function ENT:Wander()
	self:SetMovementActivity(self:GetWalkActivity())
	if self.OnWander then self:OnWander() end
	local bNodegraphExists = nodegraph.Exists()
	if bNodegraphExists && (!nodegraph.IsEdited() || GetConVarNumber("sv_customnodegraph_enabled") == 0) then
		self:StartSchedule(schdWander)
	else
		local posWander
		if bNodegraphExists then
			local posSelf = self:GetPos()
			local iAIType = self:GetAIType()
			local nodes = nodegraph.GetNodes(iAIType)
			local nodesSphere = nodegraph.FindNodesInSphere(posSelf, 600, iAIType)
			local nodeClosest = nodegraph.GetClosestNode(posSelf, iAIType)
			local nodeTgt = {}
			for _, node in pairs(nodesSphere) do
				if node != nodeClosest && node.pos:Distance(posSelf) >= 200 then
					for _, link in pairs(nodeClosest.links) do
						if nodes[link.dest].pos == node.pos then
							table.insert(nodeTgt, node)
							break
						end
					end
				end
			end
			if #nodeTgt > 1 then
				local node = nodeTgt[math.random(1,#nodeTgt)]
				posWander = node && node.pos
			end
		end
		if !posWander then
			local vecRand = VectorRand()
			vecRand.z = 0
			posWander = self:GetPos() +vecRand *600
			local tr = util.TraceLine({start = self:GetPos() +Vector(0,0,20), endpos = posWander +Vector(0,0,20), filter = self})
			posWander = tr.HitPos -tr.Normal *(self:OBBMaxs().x +10)
			tr = util.TraceLine({start = posWander +Vector(0,0,80), endpos = posWander -Vector(0,0,100), filter = self})
			posWander = tr.HitPos
		end
		self:SetLastPosition(posWander)
		self:StartSchedule(schdWanderNoNode)
	end
	self.fWanderDelay = CurTime() +12
end

function ENT:OnScheduleSelection()
end

function ENT:OnDanger(vecPos, iType)
end

function ENT:GetLastEnemyPosition(ent)
	ent = ent || self.entEnemy
	local mem = self:GetMemory()
	return mem[ent] && mem[ent].lastPos
end

function ENT:GetLastEnemyMovement(ent)
	ent = ent || self.entEnemy
	local mem = self:GetMemory()
	return mem[ent] && mem[ent].lastDir
end

function ENT:UpdateLastEnemyPositions()
	local mem = self:GetMemory()
	for ent, data in pairs(mem) do
		if ValidEntity(ent) then
			local bVisible = self:Visible(ent)
			if bVisible then -- && self:EntInViewCone(ent, self.fViewAngle) - too slow if there are a lot of enemies
				if ent == self.entEnemy then self.moveEnemyStart = nil end
				mem[ent].lost = false
				local vel = ent:GetVelocity()
				local pos = ent:GetPos()
				mem[ent].lastDir = (vel:Length() > 0 || !mem[ent].lastPos || mem[ent].lastPos:Length() == 0) && vel:GetNormal() || (pos -mem[ent].lastPos):GetNormal()
				mem[ent].lastPos = pos
			end
			mem[ent].visible = bVisible
		end
	end
end

function ENT:RunFollowBehavior()
	self:ChaseTarget(self.entFollow)
end

function ENT:KnockDown(delay)
	if !self.m_bKnockDownable || self:KnockedDown() then return end
	self.m_tGetUp = CurTime() +(delay || 6)
	local ragdoll = self:CreateRagdoll()
	if !ragdoll then return end
	self:DeleteOnRemove(ragdoll)
	ragdoll:DeleteOnRemove(self)
	local index = self:EntIndex()
	hook.Add("EntityTakeDamage", "knockdown_rgdolldmg" .. index, function(ent,inflictor,attacker,am,dmginfo)
		if ent == ragdoll && !attacker:IsWorld() then
			local dmg = DamageInfo()
			dmg:SetAttacker(dmginfo:GetAttacker())
			dmg:SetDamage(dmginfo:GetDamage())
			dmg:SetDamageForce(dmginfo:GetDamageForce())
			dmg:SetDamagePosition(dmginfo:GetDamagePosition())
			dmg:SetDamageType(dmginfo:GetDamageType())
			dmg:SetInflictor(dmginfo:GetInflictor())
			dmg:SetMaxDamage(dmginfo:GetMaxDamage())
			self.m_bRagdollDamage = true
			self:TakeDamageInfo(dmg)
			self.m_bRagdollDamage = nil
		end
	end)
	self:CallOnRemove("ClrKnckDn",function()
		hook.Remove("EntityTakeDamage", "knockdown_rgdolldmg" .. index)
	end)
	self:Interrupt()
	self.ragdoll = ragdoll
	self.m_bKnockedDown = true
	self.m_iKDMovetype = self:GetMoveType()
	self:SetNoDraw(true)
	self:SetParent(self.ragdoll)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:SetMoveType(MOVETYPE_NONE)
end

function ENT:KnockedDown()
	return self.m_bKnockedDown || false
end

function ENT:StandUp()
	if !self:KnockedDown() then return end
	self.m_tGetUp = nil
	self:SetParent()
	self.m_bKnockedDown = false
	local _, angMain = self.ragdoll:GetBonePosition(self:GetMainRagdollBone())
	local ang = self:GetAngles()
	if self.ragdoll:IsValid() then
		local ang = ang
		ang.y = angMain.y
		self:SetPos(self.ragdoll:GetPos())
		self:SetAngles(ang)
	end
	self:PlayActivity(self:SelectGetUpActivity())
end

function ENT:PlayActivity(TAct, bFaceEnemy, fcDone, bDontResetAct, bDontStopMoving)
	local schdAct = ai_schedule.New("Act" .. TAct)
	local task = "TASK_PLAY_SEQUENCE"
	if bFaceEnemy then
		/*if type(bFaceEnemy) == "Vector" then
			self:SetLastPosition(bFaceEnemy)
			schdAct:EngTask("TASK_FACE_LASTPOSITION", 0)
		else task = task .. "_FACE_ENEMY" end*/
		task = task .. "_FACE_ENEMY"
	end
	if !bDontStopMoving && (self:IsMoving() || (!self.bInSchedule && self.CurrentSchedule)) then
		--schdAct:EngTask("TASK_STOP_MOVING", 0)
		--schdAct:EngTask("TASK_STOP_MOVING", 0)
		self:StopMoving()
		self:StopMoving()
	elseif !bDontResetAct then self:StartEngineTask(GetTaskID("TASK_RESET_ACTIVITY"), 0) end
	schdAct:EngTask(task, TAct)
	if fcDone then
		self.TaskStart_TASK_ACTIVITY_END = fcDone
		schdAct:AddTask("TASK_ACTIVITY_END")
	end
	//if !bDontForceIdle then schdAct:EngTask("TASK_SET_ACTIVITY", self:GetIdleActivity()) end
	self:StartSchedule(schdAct)
	--self.CurrentSchedule.Name = "PlayActivity" .. TAct
end

function ENT:PreIdle() end

function ENT:OnIdle() end

function ENT:SelectSchedule(iNPCState)
	if GetConVarNumber("ai_disabled") == 1 || self:IsPossessed() || self:PercentageFrozen() == 100 || self:GetState() == NPC_STATE_DEAD || CurTime() < self.schdWait then return end
	if self.m_iCustomIdle && !self.CurrentSchedule && !self:IsMoving() && (!self.bInSchedule || self:GetActivity() == ACT_IDLE) then
		if !self:PreIdle() then
			local schdAct = ai_schedule.New("ActIdle")
			schdAct:EngTask("TASK_PLAY_SEQUENCE", self.m_iCustomIdle)
			schdAct.bForceSelSched = true
			self:StartEngineTask(GetTaskID("TASK_RESET_ACTIVITY"), 0)
			self:StartSchedule(schdAct)
			self:OnIdle()
		end
	end
	local bSkip = self:OnScheduleSelection()
	if bSkip then return end
	for ent, v in pairs(self.tblIncomingGrenades) do
		if !ValidEntity(ent) then self.tblIncomingGrenades[ent] = nil
		else
			local flDist = self:OBBDistance(ent)
			if flDist <= 200 then
				self.tblIncomingGrenades[ent] = nil
				local bSkip = self:OnDanger(ent:GetPos(), v)
				if bSkip then return end
			end
		end
	end
	
	local iState = self:GetState()
	local iBehavior = self:GetBehavior()
	if iBehavior == 1 then
		local entFollow = self.entFollow
		if !ValidEntity(entFollow) || entFollow:Health() <= 0 then self:SetBehavior(0)
		else
			local fDist = entFollow:OBBDistance(self)
			if fDist > self:GetFollowDistance() then
				if self.bInSchedule then self:OnBehaviorInterrupt(1)
				else
					--self:SetTarget(entFollow)
					--self:StartSchedule(schdFollow)
					--if self:HasCondition(COND_TASK_FAILED) then
					--	self:OnBehaviorFailed(1)
					--	self:ClearCondition(COND_TASK_FAILED)
					--end
					self:RunFollowBehavior()
				end
				return
			else
				if self.DoFollowBehavior then self:DoFollowBehavior(entFollow)
				else
					if !ValidEntity(self.entEnemy) then
						local schd = self:GetScheduleName()
						if schd != "MvLP" && schd != "MvLPTmd" then self:StopMoving() end
					end
					if entFollow:IsPlayer() && self:OBBDistance(entFollow) <= 10 && self:EntityIsPushing(entFollow) then
						if self.bInSchedule then self:OnBehaviorInterrupt(1)
						else
							self:SetLastPosition(self:GetPos() +(self:GetPos() -entFollow:GetPos()):GetNormal() *50)
							self:SetMovementActivity(self:GetWalkActivity())
							self:StartSchedule(schdMoveToLastPosition)
						end
					end
				end
			end
		end
	elseif iBehavior == 2 then
		local posPatrol = self.posPatrol
		local fDist = self:GetPos():Distance(posPatrol)
		if fDist > self.distPatrol then
			self:SetLastPosition(posPatrol)
			self:SetMovementActivity(self:GetRunActivity())
			self:StartSchedule(schdMoveToLastPosition)
			return
		end
	end
	
	if (iState != NPC_STATE_COMBAT && (self.iBehavior != 1 || self.iMemCount == 0) && !self:HearEnemy()) || self.bInSchedule then
		local AIType = self:GetAIType()
		if self.bWander && AIType == 2 && (iState == NPC_STATE_ALERT || iState == NPC_STATE_LOST) && iBehavior != 1 && CurTime() >= self.fWanderDelay then
			if CurTime() < self.nextAlertToIdle then
				if self:GetScheduleName() != "Wnd" then self:Wander() end
			else self:SetState(NPC_STATE_IDLE) end
		elseif !self.m_iCustomIdle && (AIType == 2 || AIType == 3) && self.bPlayIdle && !self.bInSchedule && !self:IsMoving() then
			local actIdle = self:GetIdleActivity()
			if self:GetActivity() != actIdle then self:StartEngineTask(GetTaskID("TASK_SET_ACTIVITY"), actIdle)
			elseif CurTime() >= self.nextIdle && self:GetCycle() < 0.1 then
				if math.random(1,self.idleChance) <= 2 then
					self:PlaySound((!self.tblSourceSounds["IdleAlert"] || self:GetState() == NPC_STATE_IDLE) && "Idle" || "IdleAlert")
				end
				self.nextIdle = CurTime() +self:SequenceDuration() *1.5
			end
		end
		return
	end
	local tblEnemies = self:UpdateEnemies()
	if !ValidEntity(self.entEnemy) then return end
	local iDisposition = self:Disposition(self.entEnemy)
	
	local posEnemy = self.entEnemy:NearestPoint(self:GetPos() +self.entEnemy:OBBCenter())
	local posSelf = self:NearestPoint(self.entEnemy:GetPos() +self:OBBCenter())
	posEnemy.z = self.entEnemy:GetPos().z
	posSelf.z = self:GetPos().z
	
	local posEnemyPredicted = posEnemy +self.entEnemy:GetVelocity() *0.9
	local fDistPredicted = posEnemyPredicted:Distance(posSelf)
	local fDist = posEnemy:Distance(posSelf)
	
	if iDisposition == 2 then
		self:SetTarget(self.entEnemy)
		self:UpdateEnemyMemory(self.entEnemy, self.entEnemy:GetPos())
		self:SelectScheduleHandle(fDist,fDistPredicted,iDisposition)
		return
	end
	if fDist <= 20 && self:GetAIType() != 1 then
		self:FaceEnemy()
	end
	self:UpdateEnemyMemory(self.entEnemy, self.entEnemy:GetPos())
	self:SelectScheduleHandle(fDist,fDistPredicted,iDisposition)
end

function ENT:OnBehaviorInterrupt(iBehavior)
end

function ENT:Interrupt()		-- Called on flinch, possession start or ai disabled
	if self.actReset then self:SetMovementActivity(self.actReset); self.actReset = nil end
	if self:IsPossessed() then self:_PossScheduleDone() end
	self.bInSchedule = false
end

cvars.AddChangeCallback("ai_disabled", function(cvar, prevValue, newValue)
	if tobool(newValue) then
		for k, ent in pairs(ents.GetAll()) do
			if ent:IsNPC() && ent.bScripted then
				ent:Interrupt()
			end
		end
	end
end)

function ENT:_PossStart(entPossessor)
	self:Interrupt()
end

function ENT:EntityIsPushing(ent)
	local angEnt = Angle(0,0,0)
	if ent:KeyDown(IN_FORWARD) then
		angEnt = angEnt +ent:GetForward():Angle()
	end
	if ent:KeyDown(IN_BACK) then
		angEnt = angEnt +(ent:GetForward() *-1):Angle()
	end
	if ent:KeyDown(IN_MOVERIGHT) then
		angEnt = angEnt +ent:GetRight():Angle()
	end
	if ent:KeyDown(IN_MOVELEFT) then
		angEnt = angEnt +(ent:GetRight() *-1):Angle()
	end
	local angEntSelf = (self:GetPos() -ent:GetPos()):GetNormal():Angle()
	local angDiff = angEnt.y -angEntSelf.y
	if angDiff < 0 then angDiff = angDiff +360 end
	if angDiff > 360 then angDiff = angDiff -360 end
	if angDiff >= 310 || angDiff <= 50 then
		return true
	end
	return false
end

function ENT:OnBehaviorFailed(iBehavior)
end

function ENT:OnFoundEnemy(iEnemies)
	--self:SelectSchedule()
end

function ENT:OnLostEnemy(entEnemy)
end

function ENT:OnAreaCleared()
	self:PlaySound("AreaClear")
end

function ENT:SetBehavior(iBehavior,tArg,tArgb)
	if self:GetAIType() == 3 then return end
	if iBehavior != self.iBehavior then
		if self.iBehavior == 1 then
			if self.iEntFollowDisposition then
				if ValidEntity(self.entFollow) then
					self:AddEntityRelationship(self.entFollow,self.iEntFollowDisposition,10)
				end
				self.iEntFollowDisposition = nil
			end
			self.entFollow = nil
		elseif self.iBehavior == 2 then
			self.posPatrol = nil
			self.distPatrol = nil
		end
	end
	if iBehavior > 2 || iBehavior < 0 then iBehavior = 0 end
	self.iBehavior = iBehavior	// 0 = No Behavior, 1 = Follow Behavior, 2 = Patrol Behavior, --[3 == Lead Behavior]--
	if iBehavior == 1 then
		self.entFollow = tArg
		if !ValidEntity(tArg) then return end
		if !tArgb then
			self.iEntFollowDisposition = self:Disposition(tArg)
			self:AddEntityRelationship(tArg,D_LI,10)
		end
		if ValidEntity(self.entEnemy) && self.entEnemy == tArg then self.entEnemy = nil; self:SetEnemy(NULL) end
	elseif iBehavior == 2 then
		if !tArg then self.iBehavior = 0; return end
		self.posPatrol = tArg
		self.distPatrol = fDist || 420
		self:SetLastPosition(self.posPatrol)
		self:SetMovementActivity(self:GetRunActivity())
		self:StartSchedule(schdMoveToLastPosition)
	end
end

function ENT:GetViewDistance()
	return (self.iBehavior == 1 || self.iBehavior == 2) && (self.fFollowAttackDistance || self:GetFollowDistance() -50) || self.fViewDistance
end

function ENT:GetFollowDistance()
	return self.fFollowDistance
end

function ENT:GetBehavior()
	return self.iBehavior
end

function ENT:DoSchedule(schedule)
	if self:TaskFinished() then
		self:NextTask(schedule)
	end
	if self.CurrentTask then
		self:RunTask(self.CurrentTask)
	end
end

function ENT:OnTaskComplete()
	self.bTaskComplete = true
	//self:DoSchedule(self.CurrentSchedule)
end

function ENT:OnPlayAlert() end

function ENT:OnCondition(iCondition)
	if self.bDead then return end
	--Msg(self, " Condition: ", iCondition, " - ", self:ConditionName(iCondition), "\n")
	local iNPCState = self:GetState()
	if iNPCState == NPC_STATE_DEAD then return end
	if iNPCState != NPC_STATE_COMBAT && (iCondition == COND_SEE_HATE || iCondition == COND_SEE_FEAR) then --|| #self.tblMemory > 0) then TODO: CHEATING BEHAVIOR?
		if iNPCState != NPC_STATE_LOST then
			self:PlaySound("Alert")
			if !self:IsPossessed() && #self.tblAlertAct > 0 then
				if math.random(1,self.iAlertRandom) < 3 then
					self:PlayActivity(self.tblAlertAct[math.random(1,#self.tblAlertAct)], true)
					self:OnPlayAlert()
				end
			end
		end
		self:SetState(NPC_STATE_COMBAT)
		return
	end
	--if iNPCState == NPC_STATE_COMBAT && !self:HasCondition(COND_SEE_HATE) && !self:HasCondition(COND_SEE_FEAR) && self.iMemCount && (self:HasCondition(COND_ENEMY_UNREACHABLE) || self:HasCondition(COND_ENEMY_DEAD) || self:HasCondition(COND_ENEMY_OCCLUDED) || self:HasCondition(COND_ENEMY_WENT_NULL)) then
		--self:SetState(NPC_STATE_ALERT)
	--end
end

function ENT:HearEnemy()
	for k, v in pairs(ents.FindInSphere(self:GetPos(), self.fHearDistance)) do
		if self:IsEnemy(v) then
			return true
		end
	end
	return false
end

function ENT:FaceEnemy()
	self:SetAngles(Angle(0,(self.entEnemy:GetPos() -self:GetPos()):Angle().y,0))
end

function ENT:GetEnemies()
	local tblPotentialEnemies = {}
	local bIgnorePlayers = tobool(GetConVarNumber("ai_ignoreplayers")) || self.bIgnorePlayers
	if !bIgnorePlayers then table.Add(tblPotentialEnemies,player.GetAll()) end
	if !self.bIgnoreNPCs then
		table.Add(tblPotentialEnemies,ents.FindByClass("npc_*"))
		table.Add(tblPotentialEnemies,ents.FindByClass("monster_*"))
		table.Add(tblPotentialEnemies,ents.FindByClass("obj_sentrygun"))
	end
	local tblEnemies = {}
	local posSelf = self:GetPos()
	local viewDist = self:GetViewDistance()
	for k, ent in pairs(tblPotentialEnemies) do
		local bNPC = ent:IsNPC()
		local bPlayer = ent:IsPlayer()
		if (bNPC || bPlayer) && !ent:GetNoTarget() then
			local posEnemy = ent:GetPos()
			local fDist = posSelf:Distance(posEnemy)
			local bIsPlayer = bPlayer && !ent:IsPossessing()
			local bIsNPC = bNPC
			local bValid = (bIsNPC && ent != self && ent:Health() > 0) || (bIsPlayer && ent:Alive())
			if bValid && fDist <= viewDist && !ent.bSelfDestruct then
				local bCanSee = self:InSight(ent) || ((bIsPlayer && fDist < self.fHearDistance) || (((bIsPlayer && ent:KeyDown(8) && !ent:Crouching()) || bIsNPC) && fDist <= 100))
				local iDisposition = self:Disposition(ent)
				if bCanSee && self:Visible(ent) && (iDisposition == 1 || iDisposition == 2) && (self:GetAIType() != 5 || ent:WaterLevel() > 1) then
					table.insert(tblEnemies,ent)
				end
			end
		end
	end
	self:AddToMemory(tblEnemies)
	return tblEnemies
end

function ENT:InSight(ent)
	return self:CanSee(ent)
end

function ENT:IsVisible(ent)
	local posCenter = ent:GetPos() +ent:OBBCenter()
	local posStart = self:NearestPoint(posCenter)
	local posEnd = posCenter
	local tr = util.TraceLine({start = posStart, endpos = posEnd, filter = self})
	return tr.Entity == ent
end

function ENT:InMemory(ent)
	return self:GetMemory()[ent] && true || false
end

function ENT:IsEnemy(ent)
	return ValidEntity(ent) && (ent:IsNPC() || ent:IsPlayer()) && !ent:GetNoTarget() && self:Disposition(ent) <= 2 && (!ent:IsPlayer() || (!tobool(GetConVarNumber("ai_ignoreplayers")) && !ent:IsPossessing())) && ent != self && ent:Health() > 0
end

function ENT:MergeMemory(memTgt)
	local num = self.iMemCount
	local mem = self:GetMemory()
	for ent, data in pairs(memTgt) do
		if !mem[ent] then self.iMemCount = self.iMemCount +1 end
		mem[ent] = data
	end
	if num == 0 && self.iMemCount > 0 then self:OnCondition(COND_SEE_HATE); self:OnFoundEnemy(self.iMemCount); return
	elseif num > 0 && self.iMemCount == 0 then self:SetState(NPC_STATE_IDLE); self:OnAreaCleared(); self.tblMemBlockedNodeLinks = {} end
end

function ENT:AddToMemory(TEnts)
	local mem = self:GetMemory()
	local sType = type(TEnts)
	if sType == "NPC" || sType == "Player" then
		if !mem[TEnts] && self:IsEnemy(TEnts) then
			mem[TEnts] = {}
			self.iMemCount = self.iMemCount +1
		end
		return true
	elseif sType == "table" then
		for _, ent in pairs(TEnts) do
			if !mem[ent] && self:IsEnemy(ent) then
				mem[ent] = {}
				self.iMemCount = self.iMemCount +1
			end
		end
		return true
	end
	return false
end

function ENT:GetMemory()
	return self.tblMemory
end

function ENT:GetEnemyCount()
	return self.iMemCount;
end

function ENT:RemoveFromMemory(ent)
	local mem = self:GetMemory()
	if !mem[ent] then return false end
	if self.iMemCount == 0 then return false end
	mem[ent] = nil
	self.iMemCount = self.iMemCount -1
	if ent == self.entEnemy then self.entEnemy = nil; self:SetEnemy(NULL) end
	if self.iMemCount == 0 then self:OnAreaCleared(); self.tblMemBlockedNodeLinks = {} end
	return true
end

function ENT:ClearMemory()
	self.tblMemory = {}
end

function ENT:CreateTrace(posEnd, iMask, posStart)
	return util.TraceLine({start = posStart || self:GetPos(), endpos = posEnd, mask = iMask, filter = self}) 
end

function ENT:TurnToTarget(ent)
	self:TurnDegree(2,(ent:GetPos() -self:GetPos()):Angle())
end

function ENT:CancelCurrentSchedule()
	self:StartEngineTask(GetTaskID("TASK_SET_ACTIVITY"), ACT_IDLE)
	self.CurrentSchedule = nil
	self.CurrentTask = nil
	self.CurrentTaskID = nil
end

function ENT:PlayActivity(TAct, bFaceEnemy, fcDone, bDontResetAct, bDontStopMoving)
	local schdAct = ai_schedule.New("Act" .. TAct)
	local task = "TASK_PLAY_SEQUENCE"
	if bFaceEnemy then
		/*if type(bFaceEnemy) == "Vector" then
			self:SetLastPosition(bFaceEnemy)
			schdAct:EngTask("TASK_FACE_LASTPOSITION", 0)
		else task = task .. "_FACE_ENEMY" end*/
		task = task .. "_FACE_ENEMY"
	end
	if !bDontStopMoving && (self:IsMoving() || (!self.bInSchedule && self.CurrentSchedule)) then
		--schdAct:EngTask("TASK_STOP_MOVING", 0)
		--schdAct:EngTask("TASK_STOP_MOVING", 0)
		self:StopMoving()
		self:StopMoving()
	elseif !bDontResetAct then self:StartEngineTask(GetTaskID("TASK_RESET_ACTIVITY"), 0) end
	schdAct:EngTask(task, TAct)
	if fcDone then
		self.TaskStart_TASK_ACTIVITY_END = fcDone
		schdAct:AddTask("TASK_ACTIVITY_END")
	end
	//if !bDontForceIdle then schdAct:EngTask("TASK_SET_ACTIVITY", self:GetIdleActivity()) end
	self:StartSchedule(schdAct)
	--self.CurrentSchedule.Name = "PlayActivity" .. TAct
end

function ENT:Task_TASK_ACTIVITY_END()
end

function ENT:UpdateMemory()
	local mem = self:GetMemory()
	local viewDist = self:GetViewDistance()
	for ent, data in pairs(mem) do
		local bValid = ValidEntity(ent)
		local iDisposition = bValid && self:Disposition(ent)
		if !bValid || ent:Health() <= 0 || self:OBBDistance(ent) > viewDist || ent:GetNoTarget() || (ent:IsPlayer() && (!ent:Alive() || tobool(GetConVarNumber("ai_ignoreplayers")))) || (iDisposition != 1 && iDisposition != 2) || (self:GetAIType() == 5 && ent:WaterLevel() < 2) || ent.bSelfDestruct then
			self:RemoveFromMemory(ent)
		end
	end
end

function ENT:OnPrimaryTargetChanged(ent)
end

function ENT:UpdateEnemies()
	local num = self.iMemCount
	if self.entEnemy && (!ValidEntity(self.entEnemy) || self.entEnemy:Health() <= 0 || self.entEnemy:GetNoTarget() || (self:GetAIType() == 5 && self.entEnemy:WaterLevel() < 2) || (self.entEnemy:IsPlayer() && (tobool(GetConVarNumber("ai_ignoreplayers")) || self.entEnemy:IsPossessing())) || self.entEnemy.bSelfDestruct) then self:RemoveFromMemory(self.entEnemy) end
	self:UpdateMemory()
	self:GetEnemies()
	local fDistClosest = self:GetViewDistance()
	local posSelf = self:GetPos()
	local enemyLast = self.entEnemy
	local mem = self:GetMemory()
	for ent, data in pairs(mem) do
		local posEnemy = ent:GetPos()
		local fDist = posSelf:Distance(posEnemy)
		if fDist < fDistClosest then
			self.entEnemy = ent
			fDistClosest = fDist
		end
	end
	if self.entEnemy != enemyLast then self:SetEnemy(self.entEnemy); self:OnPrimaryTargetChanged(self.entEnemy) end
	
	if self.sSquad && self.tblSquadMembers && self.iMemCount > 0 then
		for _, ent in pairs(self.tblSquadMembers) do
			if !ValidEntity(ent) then self.tblSquadMembers[_] = nil
			else ent:MergeMemory(mem) end
		end
		table.refresh(self.tblSquadMembers)
	end
	if num == 0 && self.iMemCount > 0 then self:OnFoundEnemy(self.iMemCount); return
	elseif num > 0 && self.iMemCount == 0 then self:SetState(NPC_STATE_IDLE); self:OnAreaCleared(); self.tblMemBlockedNodeLinks = {} end
	return mem
end

function ENT:GetMeleePos()
	local yaw = self:GetAngles().y
	yaw = yaw < 0 && yaw *-1 || yaw
	while yaw > 90 do
		yaw = yaw -90
	end
	while yaw > 45 do
		yaw = 45 -(yaw -45)
	end
	local a = self:OBBMaxs().y
	local beta = yaw
	local alpha = math.Deg2Rad(90 -beta)
	local c = a /math.sin(alpha) +8
	return self:GetPos() +(self:GetForward() *c)
end

--------
	-- OBSOLETE, USE ENT.DealMeleeDamage INSTEAD!
	-- LEFT FOR BACKWARDS COMPATIBILITY
--------
function ENT:DoMeleeDamage(fDist,iDmg,angViewPunch,iAttachment,funcAdd,bIgnoreAngle,sHitSound,attacker)
	local posDmg
	if !iAttachment then posDmg = self:GetMeleePos()
	else posDmg = self:GetAttachment(iAttachment).Pos end
	local posSelf = self:GetPos()
	local posSelfCenter = posSelf +self:OBBCenter()
	local bHit
	for _, ent in pairs(ents.FindInSphere(posDmg,fDist)) do
		if ValidEntity(ent) && (self:IsEnemy(ent) || ent:IsPhysicsEntity()) && self:Visible(ent) && ent:Health() > 0 then
			local tgt = self:GetTargetEntity(ent)
			local posEnemy = tgt:GetPos()
			local angToEnemy = self:GetAngleToPos(posEnemy).y
			if bIgnoreAngle || ((angToEnemy <= 70 && angToEnemy >= 0) || (angToEnemy <= 360 && angToEnemy >= 290)) then
				bHit = true
				if funcAdd then funcAdd(ent) end
				local posDmg = tgt:NearestPoint(posSelfCenter)
				local dmgInfo = DamageInfo()
				dmgInfo:SetDamage(iDmg)
				dmgInfo:SetAttacker(attacker || self)
				dmgInfo:SetInflictor(self)
				dmgInfo:SetDamageType(DMG_SLASH)
				dmgInfo:SetDamagePosition(posDmg)
				tgt:TakeDamageInfo(dmgInfo)
				if ent:IsPlayer() then
					ent:ViewPunch(angViewPunch)
					ParticleEffect("blood_impact_red_01", posDmg, Angle(0,0,0), ent)
				end
				if tgt:GetClass() == "npc_turret_floor" && !tgt.bSelfDestruct then
					tgt:Fire("selfdestruct", "", 0)
					tgt:GetPhysicsObject():ApplyForceCenter(self:GetForward() *10000) 
					tgt.bSelfDestruct = true
				end
			end
		end
	end
	if sHitSound == false then return end
	local sSound = sHitSound || "npc/zombie/claw_strike" ..math.random(1,3).. ".wav"
	if bHit then
		self:EmitSound(sSound, 75, 100)
	else
		self:EmitSound("npc/zombie/claw_miss" ..math.random(1,2).. ".wav", 75, 100)
	end
end

function ENT:DealMeleeDamage(dist,dmg,viewPunch,force,dmgType,fcFilter,bDontPlayDefSounds,bFullRot)
	local pos = self:GetMeleePos()
	local posSelf = self:GetPos()
	local center = posSelf +self:OBBCenter()
	local bHit
	if force then
		local forward,right,up = self:GetForward(),self:GetRight(),self:GetUp()
		force = forward *force.x +right *force.y +up *force.z
	end
	for _, ent in ipairs(ents.FindInSphere(pos,dist)) do
		if ent:IsValid() && (self:IsEnemy(ent) || ent:IsPhysicsEntity()) && self:Visible(ent) && ent:Health() > 0 && (!fcFilter || fcFilter(ent)) then
			local posTgt = ent:GetPos()
			local yaw = !bFullRot && self:GetAngleToPos(posTgt).y
			if bFullRot || ((yaw <= 70 && yaw >= 0) || (yaw <= 360 && yaw >= 290)) then
				bHit = true
				local posDmg = ent:NearestPoint(center)
				local dmgInfo = DamageInfo()
				dmgInfo:SetDamage(dmg)
				dmgInfo:SetAttacker(self)
				dmgInfo:SetInflictor(self)
				dmgInfo:SetDamageType(dmgType || DMG_SLASH)
				dmgInfo:SetDamagePosition(posDmg)
				if force then dmgInfo:SetDamageForce(force) end
				ent:TakeDamageInfo(dmgInfo)
				if ent:IsPlayer() then
					ent:ViewPunch(viewPunch)
					ParticleEffect("blood_impact_red_01",posDmg,Angle(0,0,0),ent)
				elseif ent:GetClass() == "npc_turret_floor" && !ent.bSelfDestruct then
					ent:Fire("selfdestruct", "", 0)
					ent:GetPhysicsObject():ApplyForceCenter(self:GetForward() *10000) 
					ent.bSelfDestruct = true
				end
			end
		end
	end
	if bDontPlayDefSounds then return end
	self:EmitSound(bHit && ("npc/zombie/claw_strike" .. math.random(1,3) .. ".wav") || ("npc/zombie/claw_miss" .. math.random(1,2) .. ".wav"),75,100)
end

function ENT:CallOnDeath(fc)
	if self.bDead then fc(); return end
	self.m_tbOnDeath = self.m_tbOnDeath || {}
	table.insert(self.m_tbOnDeath,fc)
end

function ENT:CallOnInitialized(fc)
	if self.m_bAIInitialized then fc(); return end
	self.m_tbOnAIInit = self.m_tbOnAIInit || {}
	table.insert(self.m_tbOnAIInit,fc)
end

function ENT:StopSoundOnDeath(csp)
	table.insert(self.tblCSPStopOnDeath, csp)
end

function ENT:StopSounds()
	for k, v in pairs(self.tblSounds) do
		if k != "Death" then
			for _k, _v in pairs(v) do
				_v:Stop()
			end
		end
		self.tblSounds[k] = {}
	end
end

function ENT:StopSoundPatch(sSound)
	if !self.tblSounds[sSound] then return end
	for k, v in pairs(self.tblSounds[sSound]) do
		v:Stop()
	end
	self.tblSounds[sSound] = {}
end

function ENT:PlaySound(sSound, bOver, bDontStop)
	if !self.tblSourceSounds[sSound] || (self.nextSoundPlay && CurTime() < self.nextSoundPlay) then return end
	if !bOver then self:StopSounds() end
	local sType = type(self.tblSourceSounds[sSound])
	local _sSound
	if sType == "string" then _sSound = self.tblSourceSounds[sSound]
	else _sSound = self.tblSourceSounds[sSound][math.random(1,table.Count(self.tblSourceSounds[sSound]))] end
	local cspSound = CreateSound(self, self.sSoundDir .. _sSound)
	if self.fSoundLevel then cspSound:SetSoundLevel(self.fSoundLevel) end
	cspSound:Play()
	if self.fSoundPitch != 100 then cspSound:ChangePitch(self.fSoundPitch) end
	if self.fSoundVolume != 100 then cspSound:ChangeVolume(self.fSoundVolume) end
	if !bDontStop then table.insert(self.tblSounds[sSound], cspSound) end
	return self.sSoundDir .. _sSound
end

function ENT:SetUpEnemies()
	for i = 0, 4 do
		if self.tblCRelationships[i] && self.tblCRelationships[i]["BaseClass"] then self.tblCRelationships[i]["BaseClass"] = nil end
	end
	
	local tblRelationships = {
		[D_NU] = self.tblCRelationships[D_NU] && table.Copy(self.tblCRelationships[D_NU]) || {},
		[D_HT] = self.tblCRelationships[D_HT] && table.Copy(self.tblCRelationships[D_HT]) || {},
		[D_LI] = self.tblCRelationships[D_LI] && table.Copy(self.tblCRelationships[D_LI]) || {},
		[D_FR] = self.tblCRelationships[D_FR] && table.Copy(self.tblCRelationships[D_FR]) || {}
	}
	for _, class in pairs(self:GetAlliedNPCClasses()) do if !table.HasValue(tblRelationships[D_LI], class) then table.insert(tblRelationships[D_LI], class) end end
	
	local tblList = list.Get("NPC")
	for class, data in pairs(list.Get("NPC")) do
		if class != self:GetClass() then
			local bExists
			for disp, classes in pairs(tblRelationships) do
				if table.HasValue(classes, class) then bExists = true; break end
			end
			if !bExists then table.insert(tblRelationships[D_HT],class); if class == "player" then bPlayerRel = true end end
		end
	end
	local bPlayerRel
	for disp, classes in pairs(tblRelationships) do
		if table.HasValue(classes, "player") then bPlayerRel = true; break end
	end
	if !bPlayerRel then table.insert(tblRelationships[D_HT],"player") end
	local iDispPly
	for disp, classes in pairs(tblRelationships) do
		if table.HasValue(classes, "player") then iDispPly = disp; break end
	end
	
	for _, pl in pairs(player.GetAll()) do self:AddEntityRelationship(pl, iDispPly || D_LI, 10) end
	hook.Add("PlayerSpawn", "PlayerSpawn_AddRelationship" .. self:EntIndex(), function(ply)
		if ValidEntity(ply) then
			self:AddEntityRelationship(ply, iDispPly, 10)
		end
	end)
	
	for _, ent in pairs(ents.GetAll()) do
		if ent:IsNPC() then
			local class = ent:GetClass()
			for disp, classes in pairs(tblRelationships) do
				if table.HasValue(classes, class) then
					self:AddEntityRelationship(ent, disp, 10)
					ent:AddEntityRelationship(self, disp, 10)
					break
				end
			end
		end
	end
	if self.bNeutral then return end
	hook.Add("OnEntityCreated", "OnEntityCreated_AddRelationship" .. self:EntIndex(), function(ent)
		timer.Simple(0, function()
			if ValidEntity(ent) then
				local class = ent:GetClass()
				if ent:IsNPC() then
					if !self.SetCRelationship || !self:SetCRelationship(ent, class) then
						for disp, classes in pairs(tblRelationships) do
							if table.HasValue(classes, class) then
								self:AddEntityRelationship(ent, disp, 10)
								ent:AddEntityRelationship(self, disp, 10)
								break
							end
						end
					end
				else
					local iType
					if class == "npc_grenade_frag" || class == "obj_handgrenade" || (class == "obj_spore" && ent.bGrenade) then iType = 0
					elseif class == "obj_portal" || class == "obj_grenade_flechette" || class == "hunter_flechette" then iType = -1 end
					if iType then
						self.tblIncomingGrenades[ent] = iType
					end
				end
			end
		end)
	end)
end

function ENT:OnRemove()
	hook.Remove("PlayerSpawn", "PlayerSpawn_AddRelationship" .. self:EntIndex())
	hook.Remove("OnEntityCreated", "OnEntityCreated_AddRelationship" .. self:EntIndex())
	self:StopSounds()
	for k, v in pairs(self.tblCSPStopOnDeath) do
		v:Stop()
	end
	if self.m_tbOnDeath then
		for _, fc in ipairs(self.m_tbOnDeath) do
			fc()
		end
		self.m_tbOnDeath = nil
	end
end

function ENT:BloodDecal(dmginfo)
	if !dmginfo:IsBulletDamage() && !dmginfo:IsExplosionDamage() && !dmginfo:IsDamageType(DMG_CLUB) then return end
	local force = dmginfo:GetDamageForce()
	local length = math.Clamp(force:Length() *0.25, 0, 180)
	local bPaint = tobool(math.random(0, math.Round(length *0.125)) <= 10)
	if !bPaint then return end
	local posStart = dmginfo:GetDamagePosition()
	local posEnd = posStart +force:GetNormal() *length
	local tr = util.TraceLine({start = posStart, endpos = posEnd, filter = self})
	if !tr.HitWorld then return end
	local iBloodCol = self.iBloodType
	local sDecal
	if iBloodCol == BLOOD_COLOR_RED then sDecal = "Blood"
	elseif iBloodCol == BLOOD_COLOR_GREEN || iBloodCol == BLOOD_COLOR_YELLOW || iBloodCol == BLOOD_COLOR_ANTLION || iBloodCol == BLOOD_COLOR_ANTLION_WORKER || iBloodCol == BLOOD_COLOR_ZOMBIE then sDecal = "YellowBlood"
	else return end
	util.Decal(sDecal,tr.HitPos +tr.HitNormal,tr.HitPos -tr.HitNormal)
end

function ENT:GetBloodParticle()
	local iBloodCol = self.iBloodType
	return iBloodCol == BLOOD_COLOR_RED && "blood_impact_red_01"
		|| (iBloodCol == BLOOD_COLOR_YELLOW || iBloodCol == BLOOD_COLOR_ANTLION || iBloodCol == BLOOD_COLOR_ANTLION_WORKER) && "blood_impact_yellow_01"
		|| (iBloodCol == BLOOD_COLOR_GREEN || iBloodCol == BLOOD_COLOR_ZOMBIE) && "blood_impact_green_01"
		|| iBloodCol == BLOOD_COLOR_BLUE && "blood_impact_blue_01"
		|| iBloodCol == BLOOD_COLOR_MECH && "impact_metal" || nil
end

function ENT:BloodSplash(vecPos)
	if vecPos == Vector(0,0,0) || !self.iBloodType then return false end
	local particle = self:GetBloodParticle()
	if !particle then return false end
	util.ParticleEffect(particle, vecPos, self:GetAngles(), self)
	return true
end

function ENT:CreateRagdoll()
	local mdl = self:GetModel()
	if !util.IsValidRagdoll(mdl) then return end
	local ragdoll = ents.Create("prop_ragdoll")
	ragdoll:SetModel(self:GetModel())
	for i = 1, 3 do ragdoll:SetBodygroup(i,self:GetBodygroup(i)) end
	ragdoll:SetPos(self:GetPos())
	ragdoll:SetAngles(self:GetAngles())
	ragdoll:Spawn()
	
	if !ragdoll:IsValid() then return end
	local entPhys = self:GetPhysicsObject()
	local entVel = entPhys:IsValid() && entPhys:GetVelocity() || self:GetVelocity()

	for i=0,ragdoll:GetPhysicsObjectCount() -1 do
		local bone = ragdoll:GetPhysicsObjectNum(i)
		if ValidEntity(bone) then
			local bonepos, boneang = self:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
			
			bone:SetPos(bonepos)
			bone:SetAngle(boneang)// +Angle(0,90,0))
			
			--bone:ApplyForceOffset(dmgForce /3, forcepos)
			bone:AddVelocity(entVel)
		end
	end
	ragdoll:SetSkin(self:GetSkin())
	ragdoll:SetColor(self:GetColor())
	ragdoll:SetMaterial(self:GetMaterial())
	if self:IsOnFire() then ragdoll:Ignite(math.Rand(8,10),0) end
	return ragdoll
end

local tblRagdolls = {}
function ENT:DoRagdollDeath(dmginfo)
	local ragdoll
	if ValidEntity(self.ragdoll) then
		ragdoll = self.ragdoll
		self:DontDeleteOnDeath(ragdoll)
	else
		local iKeepRagdolls = GetConVarNumber("ai_keepragdolls")
		if !self.BodyCaps && iKeepRagdolls != 2 then
			local bKeepRagdoll = tobool(iKeepRagdolls)
			if !bKeepRagdoll then
				self:SetSchedule(SCHED_DIE_RAGDOLL)
				timer.Simple(0.1, function()
					if !ValidEntity(self) then return end
					self:SetSchedule(SCHED_DIE_RAGDOLL)
					timer.Simple(0.1, function()
						if !ValidEntity(self) then return end
						self:FadeOut()
					end)
				end)
				return
			end
		end
		ragdoll = self:CreateRagdoll()
		if !ragdoll then self:Remove(); return end
		self.ragdoll = ragdoll
	end
	undo.ReplaceEntity(self, ragdoll)
	cleanup.ReplaceEntity(self, ragdoll)
	gamemode.Call("CreateEntityRagdoll", self, ragdoll)
	if self.BodyCaps then
		ragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		local bodyCaps = table.Copy(self.BodyCaps)
		for model, data in pairs(self.BodyCaps) do
			for _, bone in pairs(data.bones) do
				bodyCaps[model].bones[_] = ragdoll:LookupBone(bone)
			end
			bodyCaps[model].numAtt = ragdoll:LookupAttachment(data.att)
			bodyCaps[model].health = 45
		end
		local index = ragdoll:EntIndex()
		table.insert(tblRagdolls, ragdoll)
		for _, ragdoll in ipairs(tblRagdolls) do
			if !ragdoll:IsValid() then tblRagdolls[_] = nil end
		end
		table.MakeSequential(tblRagdolls)
		local numRag = #tblRagdolls
		if numRag > 8 then
			for i = 1, numRag -8 do
				tblRagdolls[i]:FadeOut()
				if tblRagdolls[i].BodyParts then
					for _, ent in pairs(tblRagdolls[i].BodyParts) do
						if ValidEntity(ent) then
							ent:FadeOut()
						end
					end
				end
				tblRagdolls[i] = nil
			end
		end
		local tblBodyParts = {}
		ragdoll.BodyParts = {}
		ragdoll:CallOnRemove("FLT_ClearRagdollHook", function()
			hook.Remove("EntityTakeDamage", "FT_RagdollDamage_ent" .. index)
			for _, ent in pairs(tblBodyParts) do
				if ValidEntity(ent) then ent:Remove() end
			end
		end)
		local part = self:GetBloodParticle()
		hook.Add("EntityTakeDamage", "FT_RagdollDamage_ent" .. index, function(ent,inflictor,attacker,am,dmginfo)
			if ent == ragdoll then
				local posDmg = dmginfo:GetDamagePosition()
				ent:EmitSound("fx/bullet/impact/newflesh/fx_bullet_impact_flesh0" .. math.random(6,9) .. ".wav",75,100)
				local pos = dmginfo:GetDamagePosition()
				local bone
				local distClosest = math.huge
				for i = 0, ent:GetBoneCount() -1 do
					local _pos, _ang = ent:GetBonePosition(i)
					local dist = _pos:Distance(pos)
					if dist < distClosest then bone = i; distClosest = dist end
				end
				if bone then
					local ang = ent:GetAngles()
					for model, data in pairs(bodyCaps) do
						if table.HasValue(data.bones, bone) then
							if data.health > 0 then
								bodyCaps[model].health = math.max(data.health -dmginfo:GetDamage(), 0)
								if bodyCaps[model].health == 0 then
									ent:SetBodygroup(data.bodygroup,1)
									local bone = ent:LookupBone(data.boneCap)
									if bone then
										local pos = ent:GetBonePosition(bone)
										local cap = ents.Create("prop_physics")--ragdoll")
										cap:SetModel(model)
										cap:SetPos(pos)
										cap:SetAngles(ang)
										cap:SetSkin(ent:GetSkin())
										cap:SetColor(ent:GetColor())
										cap:SetMaterial(ent:GetMaterial())
										cap:Spawn()
										cap:Activate()
										cap:TakeDamageInfo(dmginfo)
										cap:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
										cap.parent = ent
										cap:SetNetworkedEntity("ragdoll",ent)
										table.insert(tblBodyParts,cap)
										table.insert(ent.BodyParts,cap)
										cap:EmitSound("fx/fx_flinder_body_bloodspout0" .. math.random(1,6) .. ".wav",75,100)
										local phys = cap:GetPhysicsObject()
										if phys:IsValid() then
											phys:SetVelocity(dmginfo:GetDamageForce() *0.5)
										end
										local numAtt = cap:LookupAttachment(data.att)
										local indexCap = cap:EntIndex()
										if numAtt then
											timer.Create("tm_bloodspout_" .. indexCap,0.1,math.random(10,30),function()
												if cap:IsValid() then ParticleEffectAttach(part,PATTACH_POINT_FOLLOW,cap,numAtt) end
											end)
										end
										if data.numAtt then
											timer.Create("tm_bloodspout_" .. index .. "_" .. indexCap,0.1,math.random(10,30),function()
												if ent:IsValid() then ParticleEffectAttach(part,PATTACH_POINT_FOLLOW,ent,data.numAtt) end
											end)
										end
									else print("Invalid bone '" .. data.boneCap .. "' on " .. tostring(ent) .. ". Unable to create bodycap!") end
								end
							end
							break
						end
					end
				end
			end
		end)
	else ragdoll:SetCollisionGroup(iKeepRagdolls != 2 && COLLISION_GROUP_INTERACTIVE_DEBRIS || COLLISION_GROUP_DEBRIS) end
	if dmginfo then ragdoll:TakeDamageInfo(dmginfo) end
	self:Remove()
end

function ENT:GetRagdollEntity()
	return self.ragdoll
end

function ENT:DeleteOnDeath(ent)
	if table.HasValue(self.tblDeleteOnDeathEnts, ent) then return end
	table.insert(self.tblDeleteOnDeathEnts, ent)
	self:DeleteOnRemove(ent)
end

function ENT:DontDeleteOnDeath(ent)
	for k, v in pairs(self.tblDeleteOnDeathEnts) do
		if v == ent then
			table.remove(self.tblDeleteOnDeathEnts,k)
			break
		end
	end
	self:DontDeleteOnRemove(ent)
end

function ENT:OnDeath(dmginfo)
end

function ENT:SetSquad(sSquad)
	if self.sSquad then
		if self.sSquad == sSquad then return end
		for k, v in pairs(self.tblSquadMembers) do
			if ValidEntity(v) then
				for k, v in pairs(v.tblSquadMembers) do
					if v == self then
						table.remove(v.tblSquadMembers,k)
						break
					end
				end
			end
		end
		self.sSquad = nil
		self.tblSqadMembers = nil
	end
	
	if !sSquad || string.len(sSquad) == 0 then self.sSquad = nil; return end
	self.sSquad = sSquad
	self.tblSquadMembers = {}
	local tblEnts = ents.FindByClass("monster_*")
	table.Add(tblEnts,ents.FindByClass("npc_*"))
	for _, ent in pairs(tblEnts) do
		if ent.bScripted then
			local sSquadEnt = ent:GetSquad()
			if sSquadEnt && sSquadEnt == sSquad && ent != self then
				table.insert(self.tblSquadMembers,ent)
				table.insert(ent.tblSquadMembers,self)
				self:MergeMemory(ent:GetMemory())
				ent:MergeMemory(self:GetMemory())
			end
		end
	end
end

function ENT:GetSquad()
	return self.sSquad
end

function ENT:GetSquadMembers()
	return self.tblSquadMembers || {}
end

function ENT:DoDeleteOnDeath()
	for k, v in pairs(self.tblDeleteOnDeathEnts) do
		if ValidEntity(v) then
			v:Remove()
		end
	end
end

local tblDamageTypes = {DMG_ACID, DMG_AIRBOAT, DMG_ALWAYSGIB, DMG_BLAST, DMG_BLAST_SURFACE, DMG_BUCKSHOT,
DMG_BULLET, DMG_BURN, DMG_CLUB, DMG_CRUSH, DMG_DIRECT, DMG_DISSOLVE, DMG_DROWN, DMG_DROWNRECOVER, 
DMG_ENERGYBEAM, DMG_FALL, DMG_GENERIC, DMG_NERVEGAS, DMG_NEVERGIB, DMG_PARALYZE, DMG_PHYSGUN,
DMG_PLASMA, DMG_POISON, DMG_PREVENT_PHYSICS_FORCE, DMG_RADIATION, DMG_REMOVENORAGDOLL, DMG_SHOCK, 
DMG_SLASH, DMG_SLOWBURN, DMG_SONIC, DMG_VEHICLE}
function ENT:GetDamageTypes(dmginfo)
	local _tblDamageTypes = {}
	for k, v in pairs(tblDamageTypes) do
		if dmginfo:IsDamageType(v) then table.insert(_tblDamageTypes,v) end
	end
	return _tblDamageTypes
end
/*
local _tblDamageTypes = {}
_tblDamageTypes[DMG_ACID] = "DMG_ACID"
_tblDamageTypes[DMG_AIRBOAT] = "DMG_AIRBOAT"
_tblDamageTypes[DMG_ALWAYSGIB] = "DMG_ALWAYSGIB"
_tblDamageTypes[DMG_BLAST] = "DMG_BLAST"
_tblDamageTypes[DMG_BLAST_SURFACE] = "DMG_BLAST_SURFACE"
_tblDamageTypes[DMG_BUCKSHOT] = "DMG_BUCKSHOT"
_tblDamageTypes[DMG_BULLET] = "DMG_BULLET"
_tblDamageTypes[DMG_BURN] = "DMG_BURN"
_tblDamageTypes[DMG_CLUB] = "DMG_CLUB"
_tblDamageTypes[DMG_CRUSH] = "DMG_CRUSH"
_tblDamageTypes[DMG_DIRECT] = "DMG_DIRECT"
_tblDamageTypes[DMG_DISSOLVE] = "DMG_DISSOLVE"
_tblDamageTypes[DMG_DROWN] = "DMG_DROWN"
_tblDamageTypes[DMG_DROWNRECOVER] = "DMG_DROWNRECOVER"
_tblDamageTypes[DMG_ENERGYBEAM] = "DMG_ENERGYBEAM"
_tblDamageTypes[DMG_FALL] = "DMG_FALL"
_tblDamageTypes[DMG_GENERIC] = "DMG_GENERIC"
_tblDamageTypes[DMG_NERVEGAS] = "DMG_NERVEGAS"
_tblDamageTypes[DMG_NEVERGIB] = "DMG_NEVERGIB"
_tblDamageTypes[DMG_PARALYZE] = "DMG_PARALYZE"
_tblDamageTypes[DMG_PHYSGUN] = "DMG_PHYSGUN"
_tblDamageTypes[DMG_PLASMA] = "DMG_PLASMA"
_tblDamageTypes[DMG_POISON] = "DMG_POISON"
_tblDamageTypes[DMG_PREVENT_PHYSICS_FORCE] = "DMG_PREVENT_PHYSICS_FORCE"
_tblDamageTypes[DMG_RADIATION] = "DMG_RADIATION"
_tblDamageTypes[DMG_REMOVENORAGDOLL] = "DMG_REMOVENORAGDOLL"
_tblDamageTypes[DMG_SHOCK] = "DMG_SHOCK"
_tblDamageTypes[DMG_SLASH] = "DMG_SLASH"
_tblDamageTypes[DMG_SLOWBURN] = "DMG_SLOWBURN"
_tblDamageTypes[DMG_SONIC] = "DMG_SONIC"
_tblDamageTypes[DMG_VEHICLE] = "DMG_VEHICLE"
function ENT:GetDamageTypeName(iType)
	return _tblDamageTypes[iType] || "DMG_INVALID"
end*/

function ENT:SetInvincible(bInvincible)
	self.bInvincible = bInvincible == nil || bInvincible
	if self.bInvincible then self:NoCollide("prop_combine_ball")
	elseif !table.HasValue(self.tblIgnoreDamageTypes, DMG_DISSOLVE) then self:Collide("prop_combine_ball") end
end

function ENT:IsInvincible()
	return self.bInvincible
end

function ENT:SetInvincibleToTarget(tgt)
	self.m_tbInvincible = self.m_tbInvincible || {}
	self.m_tbInvincible[tgt] = true
end

function ENT:SetVincibleToTarget(tgt)
	if !self.m_tbInvincible then return end
	self.m_tbInvincible[tgt] = nil
end

function ENT:OnFlinch()
	self:Interrupt()
end

function ENT:DamageHandle(dmginfo)
end

local schdFaceLastPos = ai_schedule.New("FceLP")
schdFaceLastPos:EngTask("TASK_FACE_LASTPOSITION")
function ENT:FacePosition(pos)
	self:Interrupt()
	self:SetLastPosition(pos)
	self:StartSchedule(schdFaceLastPos)
end

function ENT:ScaleDamage(dmginfo, hitgroup)
	--gamemode.Call("ScaleNPCDamage", self, 1, dmginfo)
	if hitgroup == HITBOX_HEAD then
		dmginfo:ScaleDamage(2)
	elseif hitgroup == HITBOX_GEAR then dmginfo:SetDamage(0)
	elseif hitgroup == HITBOX_LEFTARM || hitgroup == HITBOX_RIGHTARM || hitgroup == HITBOX_LEFTLEG || hitgroup == HITBOX_RIGHTLEG || hitgroup == HITBOX_ADDLIMB then
		dmginfo:ScaleDamage(0.25)
	end
end

ENT.Limbs = {
	[HITBOX_RIGHTARM] = "Right Arm",
	[HITBOX_LEFTLEG] = "Left Leg",
	[HITBOX_HEAD] = "Head",
	[HITBOX_RIGHTLEG] = "Right Leg",
	[HITBOX_LEFTARM] = "Left Arm",
	[HITBOX_STOMACH] = HITBOX_CHEST,
	[HITBOX_CHEST] = "Torso"
}

function ENT:InitLimbs()
	local limbs = self.Limbs
	self.Limbs = {}
	local hpMax = self:Health()
	local health = hpMax *math.Clamp((((2500 -hpMax) /2500) *0.25), 0.1, 0.25)
	for hitbox, limbName in pairs(limbs) do
		if type(limbName) == "number" then self.Limbs[hitbox] = {parent = limbName}
		else
			self.Limbs[hitbox] = {
				name = limbName,
				health = health
			}
		end
	end
end

function ENT:LimbCrippled(hitbox)
	return self.Limbs[hitbox] && self.Limbs[hitbox].health == 0 && true || false
end

function ENT:OnLimbCrippled(hitbox, attacker)
end

local schdFlinch = ai_schedule.New("Hrt")
schdFlinch:EngTask("TASK_SMALL_FLINCH")
function ENT:OnTakeDamage(dmginfo)
	if self.bDead || (self:KnockedDown() && !self.m_bRagdollDamage) then return end
	local entAttacker = dmginfo:GetAttacker()
	if self:GetAIType() != 1 && !self:IsPossessed() && self:GetState() != NPC_STATE_COMBAT && self.iMemCount == 0 && !self.bInSchedule && ValidEntity(entAttacker) && self:Disposition(entAttacker) == D_HT then
		if self:GetState() == NPC_STATE_IDLE then
			self:SetState(NPC_STATE_ALERT)
			self:FacePosition(dmginfo:GetDamagePosition())
			self.nextTurnOnDmg = CurTime() +math.Rand(2,4)
		elseif CurTime() >= self.nextTurnOnDmg then
			self:FacePosition(dmginfo:GetDamagePosition())
			self.nextTurnOnDmg = CurTime() +math.Rand(2,4)
		end
	end
	local bAttackerValid = ValidEntity(entAttacker)
	local sAttackerClass = entAttacker:GetClass()
	
	local entInflictor = dmginfo:GetInflictor()
	local bInflictorValid = ValidEntity(entInflictor)
	
	local hitgroup = entAttacker:IsPlayer() && self.lastHitGroupDamage
	local fDmg = dmginfo:GetDamage()
	if self.iBloodType && (!hitgroup || hitgroup != HITBOX_GEAR) then
		self:BloodSplash(dmginfo:GetDamagePosition())
		self:BloodDecal(dmginfo)
	end
	
	local bIgnoreDamage
	
	if self.bInvincible || (self.m_tbInvincible && (self.m_tbInvincible[entAttacker] || self.m_tbInvincible[sAttackerClass])) || (bAttackerValid && ((entAttacker:IsNPC() && entAttacker:Disposition(self) >= 3) || (self.bIgnoreRagdollDamage && sAttackerClass == "prop_ragdoll"))) then bIgnoreDamage = true
	else
		for k, v in pairs(self.tblIgnoreDamageTypes) do
			if dmginfo:IsDamageType(v) then bIgnoreDamage = true; break end
		end
	end
	if bIgnoreDamage then
		dmginfo:SetDamage(0)
		dmginfo:SetDamageForce(vector_origin)
	end
	self:SetGroundEntity(NULL)
	if(GAMEMODE.NPCDamageForce) then self:SetVelocity(dmginfo:GetDamageForce() *10) end;
	
	if !self:DamageHandle(dmginfo) && hitgroup then self:ScaleDamage(dmginfo, hitgroup) end
	--if self.fDamageScale != 1 then dmginfo:ScaleDamage(self.fDamageScale); gamemode.Call("ScaleNPCDamage", self, 1, dmginfo) end
	local health = self:Health()
	self:SetHealth(health -dmginfo:GetDamage())
	if self.OnHalfHealth then
		local healthHalf = self:GetMaxHealth() *0.5
		if self:Health() <= healthHalf && health > healthHalf then self:OnHalfHealth() end
	end
	--self:SetNetworkedInt("health", self:Health())
	
	if self:Health() <= 0 then
		self:OnDeath(dmginfo)
		self:DoDeleteOnDeath()
		for k, v in pairs(self.tblCSPStopOnDeath) do
			v:Stop()
		end
		self.bDead = true
		self:StopParticles()
		gamemode.Call("OnNPCKilled", self, entAttacker, entInflictor)
		self:PlaySound("Death")

		if entAttacker:IsPlayer() then
			entAttacker:AddFrags(1)
		end
		self:DoDeath(dmginfo)
		if self.m_tbOnDeath then
			for _, fc in ipairs(self.m_tbOnDeath) do
				fc()
			end
			self.m_tbOnDeath = nil
		end
	elseif dmginfo:GetDamage() > 0 then
		local hitGroup = self.lastHitGroupDamage
		local bCrippled
		if entAttacker:IsPlayer() then --&& self.Limbs[hitGroup] && self.Limbs[hitGroup].health > 0 then
			bCrippled = self:TakeLimbDamage(hitGroup, dmginfo:GetDamage(), dmginfo:GetAttacker())
			if self.nHostileOnDamage then
				local disp = self:Disposition(entAttacker)
				if disp == D_LI || disp == D_NU then
					self.tblHostilePlayers[entAttacker] = (self.tblHostilePlayers[entAttacker] && self.tblHostilePlayers[entAttacker] != self.nHostileOnDamage && self.tblHostilePlayers[entAttacker] || 0) +1
					local numDmg = self.tblHostilePlayers[entAttacker]
					if numDmg == self.nHostileOnDamage then
						if self:GetBehavior() == 1 && self.entFollow == entAttacker then
							self:SetBehavior(0)
						end
						self:AddEntityRelationship(entAttacker,1,10)
					end
					self:OnDamagedByAlliedPlayer(entAttacker,dmginfo,numDmg)
				end
			end
		end
		self.iDmgCount = self.iDmgCount +math.random(0,2)
		local bTorsoCrippled = self:LimbCrippled(HITBOX_CHEST) || self:LimbCrippled(HITBOX_STOMACH) || self:LimbCrippled(HITGROUP_CHEST) || self:LimbCrippled(HITGROUP_STOMACH)
		if self.bFlinchOnDamage && (self.iDmgCount >= (bTorsoCrippled && 3 || 6) || dmginfo:IsDamageType(DMG_BLAST) || bCrippled) then
			self.iDmgCount = 0
			if CurTime() >= self.nextFlinch && math.random(1,3) < 3 || bCrippled then
				if self.CustomFlinch then self:CustomFlinch(dmginfo,entAttacker:IsPlayer() && self.lastHitGroupDamage || HITBOX_GENERIC)
				else
					self:StopMoving()
					if self.tblFlinchActivities && table.Count(self.tblFlinchActivities) > 0 then
						local hitgroup = entAttacker:IsPlayer() && self.lastHitGroupDamage || HITBOX_GENERIC
						self:Flinch(hitgroup)
					else self:StartSchedule(schdFlinch) end
					self:PlaySound("Pain")
					self:OnFlinch(entAttacker)
				end
			end
			self.nextFlinch = CurTime() +(bTorsoCrippled && math.Rand(1,6) || math.Rand(3,12))
		end
	end
end

function ENT:TakeLimbDamage(hitgroup, dmg, attacker)
	local bCrippled
	local limb = self.Limbs[hitgroup]
	if limb then
		local hg = hitgroup
		if limb.parent then hg = limb.parent; limb = self.Limbs[limb.parent] end
		if limb.health > 0 then
			local health = math.max(limb.health -dmg, 0)
			self.Limbs[hg].health = health
			if health == 0 then
				if GAMEMODE.OnEntityLimbCrippled then
					GAMEMODE:OnEntityLimbCrippled(self, hg, attacker)
				end
				bCrippled = true
				self:OnLimbCrippled(hitgroup, entAttacker)
			end
		end
	end
	return bCrippled || false
end

function ENT:GetLimbName(hitgroup)
	return self.Limbs[hitgroup].name
end

function ENT:OnDamagedByAlliedPlayer(pl,dmginfo,nTimesShot)
end

function ENT:DoDeath(dmginfo)
	if self:KnockedDown() then self:DoRagdollDeath(dmginfo); return end
	local attacker = dmginfo:GetAttacker()
	if (!ValidEntity(attacker) || attacker:GetClass() != "npc_barnacle") && !dmginfo:IsDamageType(DMG_DISSOLVE) then
		if self.bExplodeOnDeath then self:DoExplode(); return end
		self:SetNPCState(NPC_STATE_DEAD)
		self:SetState(NPC_STATE_DEAD)
		if self.bFadeOnDeath then self:FadeOut(4) end
		local bRagdoll = util.IsValidRagdoll(self:GetModel())
		if self.bPlayDeathSequence then
			if bRagdoll && tobool(GetConVarNumber("ai_keepragdolls")) then self:DoRagdollDeath(dmginfo)
			else
				//self:SetSchedule(SCHED_DIE)
				local bMoving = self:IsMoving()
				if bMoving && !self.m_bForceDeathAnim && (!self.DeathActChance || math.random(1,100) > self.DeathActChance) then
					if bRagdoll then self:SetSchedule(SCHED_DIE_RAGDOLL)
					else
						self:SetSchedule(SCHED_DIE)
						if !self.bSpecialDeath then
							timer.Simple(0.1,function()
								if !ValidEntity(self) then return end
								self:FadeOut(self:SequenceDuration() -0.1)
							end)
						end
					end
				else
					if bMoving then self:StopMoving(); self:StopMoving() end
					if !ValidEntity(attacker) || !attacker:IsPlayer() || !self.lastHitGroupDamage || (!self.tblDeathActivities[self.lastHitGroupDamage] && !self.tblDeathActivities[HITGROUP_GENERIC] && !self.tblDeathActivities[HITBOX_GENERIC]) then self:SetSchedule(SCHED_DIE)
					else
						local act = self.tblDeathActivities[self.lastHitGroupDamage] || self.tblDeathActivities[HITGROUP_GENERIC] || self.tblDeathActivities[HITBOX_GENERIC]
						if type(act) == "table" then act = table.Random(act) end
						local SCHED_DIE = ai_schedule.New("Die")
						SCHED_DIE:EngTask("TASK_PLAY_SEQUENCE", act)
						self:StartSchedule(SCHED_DIE)
					end
					if !self.bSpecialDeath then
						timer.Simple(0.1,function()
							if !ValidEntity(self) then return end
							if bRagdoll then
								timer.Simple(self:SequenceDuration() -0.1, function()
									if !ValidEntity(self) then return end; self:DoRagdollDeath(dmginfo)
								end)
							elseif !self.bSpecialDeath then
								self:FadeOut(self:SequenceDuration() -0.1)
							end
						end)
					end
				end
			end
		elseif bRagdoll then self:DoRagdollDeath(dmginfo) end
		if self.bRemoveOnDeath then self:Remove() end
	elseif dmginfo:IsDamageType(DMG_DISSOLVE) then
		if self:Disposition(attacker) == D_LI then self:Dissolve(nil, nil, 0) end
		if self.bRemoveOnDeath then self:Remove(); return end
		self:SetNPCState(NPC_STATE_DEAD)
		self:SetState(NPC_STATE_DEAD)
		self:SetSchedule(SCHED_DIE_RAGDOLL)
	end
end

function ENT:Event(sEvent)
	if self:KnockedDown() then return end
	/*local iEvent
	local tblArgs = {}
	local _sEvent = sEvent
	local iSpace = string.find(_sEvent,"%s")
	if iSpace then
		sEvent = string.sub(sEvent,1,iSpace -1)
	end
	while iSpace do
		local _iArgEnd = string.find(_sEvent,",",iSpace +1) || string.find(_sEvent,"$")
		local sArg = string.Trim(string.sub(_sEvent,iSpace +1,_iArgEnd -1))
		local iArg = tonumber(sArg)
		if iArg then table.insert(tblArgs,iArg) else table.insert(tblArgs,sArg) end
		iSpace = string.find(_sEvent,",",iSpace +1)
	end*/
	
	//print("Handling event " .. sEvent .. "...")
	/*if #tblArgs > 0 then
		print("Event Arguments:")
		PrintTable(tblArgs)
	end*/
	
	local iSoundEvent = string.find(sEvent,"play")
	if iSoundEvent then
		local sSoundEvent = string.sub(sEvent,string.find(sEvent,"%s") +1,string.len(sEvent))
		if !string.find(sSoundEvent,"[.]wav") then
			self:PlaySound(sSoundEvent)// ,true, true
		else
			local sSound = self.sSoundDir .. sSoundEvent
			WorldSound(sSound, self:GetPos(), 75, self.fSoundPitch)
		end
		return
	end
	local iEmitEvent = string.find(sEvent,"emit")
	if iEmitEvent then
		local sSoundEvent = string.sub(sEvent,string.find(sEvent,"%s") +1,string.len(sEvent))
		local dat = string.Explode(" ",sSoundEvent)
		sSoundEvent = dat[1]
		local vol = tonumber(dat[2])
		local pitch = tonumber(dat[3])
		if !string.find(sSoundEvent,"[.]wav") then
			if !self.tblSourceSounds[sSoundEvent] then return end
			local sType = type(self.tblSourceSounds[sSoundEvent])
			if sType == "string" then
				self:EmitSound(self.sSoundDir .. self.tblSourceSounds[sSoundEvent], 75, self.fSoundPitch)
			else
				self:EmitSound(self.sSoundDir .. self.tblSourceSounds[sSoundEvent][math.random(1,table.Count(self.tblSourceSounds[sSoundEvent]))], vol || 75, pitch || self.fSoundPitch)
			end
		else
			local sSound = self.sSoundDir .. sSoundEvent
			self:EmitSound(sSound, vol || 75, pitch || 100)
		end
		return
	end
	local bDropDead = tobool(string.find(sEvent,"dropdead"))
	if bDropDead then
		self:DoRagdollDeath()
		return
	end
	local iSkin = string.find(sEvent,"skin")
	if iSkin then
		local sSkin = string.Trim(string.sub(sEvent,string.find(sEvent,"%d"),string.len(sEvent)))
		local iSkin = tonumber(sSkin)
		self:SetSkin(iSkin)
		return
	end
	local iBodyGroup = string.find(sEvent,"bodygroup")
	if iBodyGroup then
		local sBodygroup = string.Trim(string.sub(sEvent,string.find(sEvent,"%d"),string.len(sEvent)))
		local bodygroup = string.Explode(" ",sBodygroup)
		self:SetBodygroup(tonumber(bodygroup[1]),tonumber(bodygroup[2]))
		return
	end
	local bRun = sEvent == "run"
	if bRun then
		self:SetMovementActivity(ACT_RUN)
		return
	end
	local bActivity = tobool(string.find(sEvent,"activity"))
	if bActivity then
		local iActivity = string.Trim(string.sub(sEvent,9,string.len(sEvent)))
		iActivity = tonumber(iActivity)
		if iActivity then self:PlayActivity(iActivity) end
		return
	end
	local bStopParticles = tobool(string.find(sEvent,"stopparticles"))
	if bStopParticles then
		self:StopParticles()
		return
	end
	if string.find(sEvent,"getup") then
		if self.ragdoll:IsValid() then
			self.ragdoll:DontDeleteOnRemove(self)
			self.ragdoll:Remove()
		end
		self.ragdoll = nil
		self:SetNoDraw(false)
		self:SetCollisionGroup(COLLISION_GROUP_NPC)
		self:SetMoveType(self.m_iKDMovetype)
		self.m_iKDMovetype = nil
		return
	end
	self:EventHandle(sEvent,tblArgs)
end

function ENT:EventHandle(sEvent,tblArgs)
end

function ENT:GetSentenceLength(sSentence)
	sSentence = string.Replace(sSentence,"!","")
	local content = file.Read("../scripts/sentences.txt")
	local iSenStart = string.find(content,sSentence)
	if !iSenStart then return 0 end
	local iLenStart = string.find(content,"Len ",iSenStart) +4
	local iLenEnd = string.find(content,"}",iLenStart) -1
	local iLenEndB = string.find(content,"%s",iLenStart)
	if iLenEndB && iLenEndB < iLenEnd then
		iLenEnd = iLenEndB -1
	end
	local fLength = string.sub(content,iLenStart,iLenEnd)
	fLength = tonumber(fLength)
	return fLength
end

function ENT:SpeakSentence(sSentence, entListener, fcDone, entSpeaker, iRadius, iVolume, iAttenuation, bRepeat, bInterrupt, bConcurrent, bToActivator)
	entSpeaker = entSpeaker || self
	entListener = entListener || self
	
	local entSentenceScript = ents.Create("scripted_sentence")
	entSentenceScript:SetPos(self:GetPos())
	entSentenceScript:SetKeyValue("sentence", sSentence)
	local sSpeaker
	if entSpeaker:GetName() == "" then sSpeaker = entSpeaker:GetClass()
	else sSpeaker = entSpeaker:GetName() end
	entSentenceScript:SetKeyValue("entity", sSpeaker)

	local sListener
	if entListener:GetName() != "" and !entListener:IsPlayer() then sListener = entListener:GetName()
	else sListener = entListener:GetClass() end
	entSentenceScript:SetKeyValue("listener", sListener)
	entSentenceScript:SetKeyValue("radius", iRadius || 2)
	entSentenceScript:SetKeyValue("volume", iVolume || 10)
	entSentenceScript:SetKeyValue("attenuation", iAttenuation || 1)
	
	local iSpawnflags = 0
	if !bRepeat then iSpawnflags = iSpawnflags +1 end
	if bInterrupt then iSpawnflags = iSpawnflags +4 end
	if bConcurrent then iSpawnflags = iSpawnflags +8 end
	if bToActivator then iSpawnflags = iSpawnflags +16 end
	entSentenceScript:SetKeyValue("spawnflags", iSpawnflags)
	
	if fcDone then
		timer.Simple(self:GetSentenceLength(sSentence), function() if ValidEntity(self) then fcDone() end end)
	end
	
	entSentenceScript:Spawn()
	entSentenceScript:Activate()
	entSentenceScript:Fire("BeginSentence", "", 0)
	entSentenceScript:Fire("kill", "", 0.1)
end

function ENT:AcceptInput(sCvar, entActivator, entCaller, data)
	local iEvent = string.find(sCvar,"event_")
	if iEvent && entActivator == self then
		local sEvent = string.sub(sCvar,iEvent +6,string.len(sCvar))
		self:Event(sEvent)
		return
	end
	sCvar = string.lower(sCvar)
	local bSetSquad = tobool(sCvar == "setsquad")
	if bSetSquad then
		self:SetSquad(data)
		return
	end
	local bUse = tobool(sCvar == "use")
	if bUse then
		self:Use(entActivator,entCaller,SIMPLE_USE)
		return
	end
	self:InputHandle(cvar,activator,caller,data)
end

function ENT:InputHandle(cvar,activator,caller,data)
end

function ENT:Use(entActivator, entCaller, iType, value)
end

function ENT:StartTouch(ent)
end

function ENT:EndTouch(ent)
end

function ENT:Touch(ent)
end

function ENT:GetRelationship(ent)
	//return self:Disposition(ent)
end

function ENT:ExpressionFinished(strExp)
end

function ENT:UpdateNPCState()
	local state = self:GetNPCState(true)
	if state != NPC_STATE_COMBAT && state != NPC_STATE_DEAD then self:SetNPCState(NPC_STATE_COMBAT) end
end

function ENT:UpdatePath()
	if self.pathObj then--&& CurTime() -self.nextPathGenSteps >= 0 then
		--self.nextPathGenSteps = CurTime() +0.1
		local path, bFailed
		for i = 1, 5 do
			local bFinished, bWorked, _path, nStatus = astar.Step(self.pathObj)
			if bFinished then
				path = _path
				bFailed = !bWorked
				break
			end
		end
		if path then
			self.pathObj = nil
			local tTarget = self.pathObjTgt
			self.pathObjTgt = nil
			local _path = {}
			for i = #path, 1, -1 do
				_path[(#path +1) -i] = path[i]
			end
			--local nodeCur = nodegraph.GetClosestNode(self:GetPos(), iAIType)
			if self.currentNodePos && self.currentPath && #self.currentPath > 0 then --self.currentNodePos
				local b = false
				for k, node in pairs(_path) do
					if node.pos == self.currentNodePos then
						for i = 1, k -1 do
							table.remove(_path, 1) -- Improving path in case NPC has moved since astar object was created
						end
						b = true
						break
					end
				end
				if b then self.currentPath = _path -- Path is valid. Setting current path to new path
				else self:GeneratePath(tTarget); self.currentNodePos = nil; return end -- Path is invalid (Current node doesn't exist in path?), regenerating
			else
				self.currentPath = _path -- Path is valid. Setting current path to new path
				self.currentNodePos = nil
				self.currentPathTime = nil
				self.estimPathArrival = nil
			end
			if bFailed then
				if tTarget && type(tTarget) != "Vector" then
					self:RemoveFromMemory(tTarget)
					self:SetState(NPC_STATE_LOST)
					self.currentPath = nil
				end -- Failed to generate path, removing enemy from memory
				return
			end
		end
	end
end

function ENT:SetActivitySchedule(act)
	self.bInSchedule = act
end

function ENT:AttackMove(act, duration)
	self.actReset = self:GetMovementActivity()
	self:SetMovementActivity(act)
	self.bInSchedule = true
	timer.Simple(duration, function()
		if ValidEntity(self) then
			if self.actReset then
				self:SetMovementActivity(self.actReset)
				self.actReset = nil
			end
			self.bInSchedule = false
		end
	end)
end

function ENT:Think()
	if self.m_tGetUp && CurTime() >= self.m_tGetUp then self:StandUp(); self.m_tGetUp = nil end
	if self.m_MoveCPos then
		self:SetLastPosition(self.m_MoveCPos)
		local schdChase = ai_schedule.New("Chase")
		schdChase:EngTask("TASK_PLAY_SEQUENCE", self:GetMovementActivity())
		schdChase.bForceSelSched = true
		self:StartSchedule(schdChase)
		
		util.CreateSpriteTrace(self.m_MoveCPos, self.m_MoveCPos +Vector(0,0,100), 0.4, 60, Color(255,0,0,255))
		local angTgt = (self.m_MoveCPos -self:GetPos()):Angle()
		local ang = self:GetAngles()
		self:SetAngles(Angle(0,math.ApproachAngle(ang.y,angTgt.y,40),0))
		
		if CurTime() >= self.m_tMoveCTimeOut then
			self.m_tMoveCTimeOut = nil
			self.m_MoveCPos = nil
		end
	end
	--if self.bInSchedule && self:GetActivity() != self.bInSchedule then self:Interrupt() end
	self:UpdatePath()
	self:UpdateNPCState()
	return self:OnThink()
end

function ENT:OnThink()
	self:UpdateLastEnemyPositions()
end

/*---------------------------------------------------------
   Name: GetAttackSpread
		How good is the NPC with this weapon? Return the number
		of degrees of inaccuracy for the NPC to use.
---------------------------------------------------------*/
function ENT:GetAttackSpread(Weapon, Target)
	return 0.1
end
