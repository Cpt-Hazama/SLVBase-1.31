require("a_star_pathfinding")
if CLIENT && !SinglePlayer() then return end
local nodegraph_default, links = ParseGraphFile("garrysmod/maps/graphs/" .. game.GetMap() .. ".ain") || {}, {}
local nodes = {}
local tblNodePositions = {}
for k, v in pairs(nodegraph_default) do
	if table.HasValue(tblNodePositions, v.pos) then
		nodegraph_default[k] = nil
	else
		tblNodePositions[k] = v.pos
	end
end
local nodesGround = {}
local nodesAir = {}
local nodesClimb = {}
local nodesWater = {}

local HULL_HUMAN = HULL_HUMAN
local HULL_SMALL_CENTERED = HULL_SMALL_CENTERED
local HULL_WIDE_HUMAN = HULL_WIDE_HUMAN
local HULL_TINY = HULL_TINY
local HULL_WIDE_SHORT = HULL_WIDE_SHORT
local HULL_MEDIUM = HULL_MEDIUM
local HULL_TINY_CENTERED = HULL_TINY_CENTERED
local HULL_LARGE = HULL_LARGE
local HULL_LARGE_CENTERED = HULL_LARGE_CENTERED
local HULL_MEDIUM_TALL = HULL_MEDIUM_TALL

local bEdited = false
local function InitCustomNodeSystem()
	local content = file.Read("nodegraph/" .. game.GetMap() .. ".txt")
	if content then
		bEdited = true
		local function GetSubContent(str)
			local name_start = 1
			local name_end = string.find(str,"{") -1
			local name = string.Trim(string.sub(str,name_start,name_end))
			local c_start = name_end +2
			local c_end = c_start
			local x = 1
			while x != 0 do
				local a = string.find(str, "{", c_end)
				local b = string.find(str, "}", c_end)
				if a && b && a < b then
					c_end = a +1
					x = x+1
				elseif b && (!a or b < a) then
					c_end = b +1
					x = x-1
				end
			end
			c_end = c_end -2
			local subcontent = string.Trim(string.sub(str,c_start,c_end))
			return subcontent,c_end
		end
		
		local contentNodes, nodesEnd = GetSubContent(content)
		local tblNodes = {}
		debug.sethook()
		while string.len(contentNodes) > 0 do
			local subContentStart = string.find(contentNodes, "{")
			local subContentEnd = string.find(contentNodes, "}", subContentStart)
			local indexStart = 1
			local indexEnd = subContentStart -1
			local index = string.Trim(string.sub(contentNodes, indexStart, indexEnd))
			index = tonumber(index)
			local subContent = string.Trim(string.sub(contentNodes, subContentStart +1, subContentEnd -1))
			tblNodes[index] = {ID = index, links = {}}
			while string.len(subContent) > 0 do
				local keyStart = 1
				local keyEnd = string.find(subContent, "=")
				local key = string.Trim(string.sub(subContent, keyStart, keyEnd -1))
				local valueStart = keyEnd
				local valueEnd = string.find(subContent,"\n") || string.find(subContent,"$")
				local value = string.Trim(string.sub(subContent, valueStart +1, valueEnd -1))
				if key == "pos" then
					value = string.Explode(" ", value)
					value = Vector(value[1], value[2], value[3])
				else value = tonumber(value) end
				tblNodes[index][key] = value
				subContent = string.Trim(string.sub(subContent, valueEnd +1, string.len(subContent)))
			end
			contentNodes = string.Trim(string.sub(contentNodes, subContentEnd +1, string.len(contentNodes)))
		end
		
		content = string.Trim(string.sub(content,nodesEnd +2,string.len(content)))
		content = GetSubContent(content)
		while string.len(content) > 0 do
			local linkStart = 1
			local linkEnd = string.find(content,"=")
			local link = string.Trim(string.sub(content,linkStart,linkEnd -1))
			link = string.Explode(",", link)
			local hullStart = linkEnd +1
			local hullEnd = string.find(content,"\n") || string.find(content,"$")
			local hull = string.Trim(string.sub(content,hullStart,hullEnd -1))
			hull = string.Explode(",", hull)
			local linkType = tonumber(hull[2])
			hull = tonumber(hull[1])
			local nodeID = tonumber(link[1])
			local nodeIDDest = tonumber(link[2])
			---tblNodes[nodeID].links = tblNodes[nodeID].links || {}
			table.insert(tblNodes[nodeID].links, {dest = nodeIDDest, move = hull, type = linkType})
			if !nodes[nodeIDDest] then
				tblNodes[nodeIDDest].links = tblNodes[nodeIDDest].links || {}
				table.insert(tblNodes[nodeIDDest].links, {dest = nodeID, move = hull, type = linkType})
			else
				table.insert(nodes[nodeIDDest].links, {dest = nodeID, move = hull, type = linkType})
			end
			content = string.Trim(string.sub(content,hullEnd,string.len(content)))
		end
		nodes = nodes || {}
		table.Merge(nodes, tblNodes)
		for k, v in pairs(tblNodes) do
			if v.type == 2 then nodesGround[k] = v
			elseif v.type == 3 then nodesAir[k] = v
			elseif v.type == 4 then nodesClimb[k] = v
			elseif v.type == 5 then nodesWater[k] = v end
		end
	end
end
local function GetHullID(iHull)
	if iHull == HULL_HUMAN then return 1
	elseif iHull == HULL_SMALL_CENTERED then return 2
	elseif iHull == HULL_WIDE_HUMAN then return 4
	elseif iHull == HULL_TINY then return 8
	elseif iHull == HULL_WIDE_SHORT then return 16
	elseif iHull == HULL_MEDIUM then return 32
	elseif iHull == HULL_TINY_CENTERED then return 64
	elseif iHull == HULL_LARGE then return 128
	elseif iHull == HULL_LARGE_CENTERED then return 256
	elseif iHull == HULL_MEDIUM_TALL then return 512 end
	return 0
end
debug.sethook()
for ID, node in pairs(nodegraph_default) do
	nodes[ID] = {ID = ID, persistent = true}
	for k, v in pairs(node) do
		if k == "link" then
			nodes[ID].links = {}
			local links = {}
			for k, v in pairs(v) do
				local nodeDest
				if v.dest.pos != node.pos then nodeDest = v.dest
				elseif v.src.pos != node.pos then nodeDest = v.src end
				if nodeDest then
					local IDDest
					for k, v in pairs(tblNodePositions) do
						if v == nodeDest.pos then
							IDDest = k
							break
						end
					end
					if IDDest && !table.HasValue(links, IDDest) then
						local move = 0
						for k, v in pairs(v.move) do
							if v > 0 then
								move = move +GetHullID(k -1)
							end
						end
						local link = {dest = IDDest, type = 0, move = move}
						table.insert(nodes[ID].links, link)
						table.insert(links, IDDest)
					end
				end
			end
		/*elseif k == "offset" then
			local iHull = 0
			local iHullCur = 1
			local i = 1
			while iHullCur <= 512 do
				if v[i] > 0 then iHull = iHull +iHullCur end
				i = i +1
				iHullCur = iHullCur *2
			end
			nodes[ID]["move"] = iHull*/
		elseif k == "pos" || k == "info" || k == "yaw" || k == "zone" || k == "type" then
			nodes[ID][k] = v
		end
	end
end
for k, v in pairs(nodes) do
	if v.type == 2 then nodesGround[k] = v
	elseif v.type == 3 then nodesAir[k] = v
	elseif v.type == 4 then nodesClimb[k] = v end
end
InitCustomNodeSystem()

local ipairs = ipairs
local pairs = pairs
local table = table
local math = math
local util = util
local Vector = Vector
local astar = astar
local file = file
local game = game
local tostring = tostring
local timer = timer
local debug = debug

module("nodegraph")

function GetNodes(iType)
	return !iType && nodes || iType == 2 && nodesGround || iType == 3 && nodesAir || iType == 4 && nodesClimb || iType == 5 && nodesWater
end

function Reload()
	InitCustomNodeSystem()
end

function GetGroundNodes()
	return nodesGround
end

function GetAirNodes()
	return nodesAir
end

function GetClimbNodes()
	return nodesClimb
end

function GetWaterNodes()
	return nodesWater
end

function IsEdited()
	return bEdited
end

function FindNodesInSphere(pos, dist, iType)
	local nodes = {}
	for _, node in pairs(GetNodes(iType)) do
		if node.pos:Distance(pos) <= dist then
			table.insert(nodes, node)
		end
	end
	return nodes
end

function GetNodeLinks(node, iType)
	if !node then return links || {} end
	iType = iType || 2
	for k, v in pairs(GetNodes(iType)) do
		if v.pos == node.pos then
			return v.link
		end
	end
	return {}
end

function GetClosestNode(pos, iType)
	iType = iType || 2
	local flDist = 99999
	local node
	for k, v in pairs(GetNodes(iType)) do
		local _flDist = pos:Distance(v.pos)
		if _flDist < flDist /*&& !util.TraceLine({start = pos +Vector(0,0,3), v.pos +Vector(0,0,3)}).Hit*/ then	-- Visible?
			flDist = _flDist
			node = v
		end
	end
	return node
end

function Exists()
	return table.Count(nodes) > 0 || false
end

local function HullCanUsePath(iMove, iHull)
	return table.HasValue(math.SplitByPowerOfTwo(iMove), GetHullID(iHull))
end

function GeneratePath(posStart, posEnd, iType, iHull, fcLinkFilter)
	if !Exists() || table.IsEmpty(GetNodes(iType)) then return {} end
	local nodeStart = GetClosestNode(posStart, iType)
	local nodeEnd = GetClosestNode(posEnd, iType)
	local b, _path, nStatus = astar.CalculatePath(nodeStart, nodeEnd, function(node)
		local tblNeigh = {}
		for k, v in pairs(node.links) do
			table.insert(tblNeigh, nodes[v.dest])
		end
		return pairs(tblNeigh)
	end, function(nodeCur, nodeNeigh, nodeStart, nodeTarget, heuristic, ...)
		for k, v in pairs(nodeCur.links) do
			if nodes[v.dest].pos == nodeNeigh.pos then
				if (v.type == 2 && nodeCur.pos.z < nodeNeigh.pos.z) || (iHull && !HullCanUsePath(v.move, iHull)) then
					return false
				end
			end
		end
		return !fcLinkFilter || fcLinkFilter(nodeCur, nodeNeigh)
	end, function(nodeA, nodeB)
		return nodeA.pos:Distance(nodeB.pos)
	end, function(nodeCur, nodeNeigh, nodeStart, nodeTarget, heuristic, ...)
		return 1
	end)
	local path = {}
	for i = #_path, 1, -1 do
		path[(#_path +1) -i] = _path[i]
	end
	return path, nodeStart, nodeEnd
end

function CreateAstarObject(posStart, posEnd, iType, iHull, fcLinkFilter)
	if !Exists() || table.IsEmpty(GetNodes(iType)) then return nil end
	local nodeStart = GetClosestNode(posStart, iType)
	local nodeEnd = GetClosestNode(posEnd, iType)
	local objAstar = astar.Create(nodeStart, nodeEnd, function(node)
		local tblNeigh = {}
		for k, v in pairs(node.links) do
			table.insert(tblNeigh, nodes[v.dest])
		end
		return pairs(tblNeigh)
	end, function(nodeCur, nodeNeigh, nodeStart, nodeTarget, heuristic, ...)
		for k, v in pairs(nodeCur.links) do
			if nodes[v.dest].pos == nodeNeigh.pos then
				if (v.type == 2 && nodeCur.pos.z < nodeNeigh.pos.z) || (iHull && !HullCanUsePath(v.move, iHull)) then
					return false
				end
			end
		end
		return !fcLinkFilter || fcLinkFilter(nodeCur, nodeNeigh)
	end, function(nodeA, nodeB)
		return nodeA.pos:Distance(nodeB.pos)
	end, function(nodeCur, nodeNeigh, nodeStart, nodeTarget, heuristic, ...)
		return 1
	end)
	return objAstar
end

local function HullAccessable(posStart, posEnd, hull)
	local tblTraces = {}
	local tblTrPos = {
		{start = Vector(0,0,(hull.max.z +hull.min.z) *0.5), endpos = Vector(0,0,(hull.max.z +hull.min.z) *0.5)},
		{start = Vector(0,0,hull.max.z), endpos = Vector(0,0,hull.max.z)},
		{start = Vector(0,0,hull.min.z), endpos = Vector(0,0,hull.min.z)},
		{start = Vector(hull.max.x,hull.max.y,(hull.max.z +hull.min.z) *0.5), endpos = Vector(hull.max.x,hull.max.y,(hull.max.z +hull.min.z) *0.5)},
		{start = Vector(hull.min.x,hull.min.y,(hull.max.z +hull.min.z) *0.5), endpos = Vector(hull.min.x,hull.min.y,(hull.max.z +hull.min.z) *0.5)},
		{start = Vector(hull.min.x,hull.min.y,hull.max.z), endpos = Vector(hull.max.x,hull.max.y,hull.max.z)},
		{start = Vector(hull.max.x,hull.max.y,hull.max.z), endpos = Vector(hull.min.x,hull.min.y,hull.max.z)},
		{start = Vector(hull.min.x,hull.min.y,hull.min.z), endpos = Vector(hull.max.x,hull.max.y,hull.min.z)},
		{start = Vector(hull.max.x,hull.max.y,hull.min.z), endpos = Vector(hull.min.x,hull.min.y,hull.min.z)},
		{start = Vector(hull.min.x,hull.min.y,hull.max.z), endpos = Vector(hull.min.x,hull.min.y,hull.min.z)},
		{start = Vector(hull.min.x,hull.min.y,hull.min.z), endpos = Vector(hull.min.x,hull.min.y,hull.max.z)},
		{start = Vector(hull.max.x,hull.max.y,hull.max.z), endpos = Vector(hull.max.x,hull.max.y,hull.min.z)},
		{start = Vector(hull.max.x,hull.max.y,hull.min.z), endpos = Vector(hull.max.x,hull.max.y,hull.max.z)}
	}

	for k, v in pairs(tblTrPos) do
		table.insert(tblTraces, util.TraceLine({start = posStart +v.start, endpos = posEnd +v.endpos, mask = MASK_NPCWORLDSTATIC}))
	end

	local tblTrPos = {hull.max, hull.min, Vector(hull.max.x, hull.max.y, hull.min.z), Vector(hull.min.x, hull.min.y, hull.max.z)}
	for k, v in pairs(tblTrPos) do
		table.insert(tblTraces, util.TraceLine({start = posStart +v, endpos = posEnd +v, mask = MASK_NPCWORLDSTATIC}))
		if k == 1 || k == 3 then
			table.insert(tblTraces, util.TraceLine({start = posStart +v, endpos = posEnd +tblTrPos[k +1], mask = MASK_NPCWORLDSTATIC}))
		else
			table.insert(tblTraces, util.TraceLine({start = posStart +v, endpos = posEnd +tblTrPos[k -1], mask = MASK_NPCWORLDSTATIC}))
		end
	end

	for k, v in pairs(tblTraces) do
		if v.Hit then return false end
	end
	return true
end

function AddLink(nodeIDStart, nodeIDEnd, iType, iForceHulls)
	local tblHulls = {
		HULL_HUMAN = {max = Vector(13, 13, 72), min = Vector(-13, -13, 0)},
		HULL_SMALL_CENTERED = {max = Vector(20, 20, 40), min = Vector(-20, -20, 0)},
		HULL_WIDE_HUMAN = {max = Vector(15, 15, 72), min = Vector(-15, -15, 0)},
		HULL_TINY = {max = Vector(12, 12, 24), min = Vector(-12, -12, 0)},
		HULL_WIDE_SHORT = {max = Vector(35, 35, 32), min = Vector(-35, -35, 0)},
		HULL_MEDIUM = {max = Vector(16, 16, 64), min = Vector(-16, -16, 0)},
		HULL_TINY_CENTERED = {max = Vector(8, 8, 8), min = Vector(-8, -8, 0)},
		HULL_LARGE = {max = Vector(40, 40, 100), min = Vector(-40, -40, 0)},
		HULL_LARGE_CENTERED = {max = Vector(38, 38, 76), min = Vector(-38, -38, 0)},
		HULL_MEDIUM_TALL = {max = Vector(18, 18, 100), min = Vector(-18, -18, 0)}
	}
	
	local nodeType = nodes[nodeIDStart].type
	if nodeType == 3 then
		for k, v in pairs(tblHulls) do
			v.max.z = v.max.z *0.5
			v.min.z = -v.max.z
		end
	end
	
	local tblHullIDs = {
		HULL_HUMAN = 1,
		HULL_SMALL_CENTERED = 2,
		HULL_WIDE_HUMAN = 4,
		HULL_TINY = 8,
		HULL_WIDE_SHORT = 16,
		HULL_MEDIUM = 32,
		HULL_TINY_CENTERED = 64,
		HULL_LARGE = 128,
		HULL_LARGE_CENTERED = 256,
		HULL_MEDIUM_TALL = 512
	}
	
	local nodeEnd = GetNodes(nodeType)[nodeIDEnd]
	local posEnd = nodeEnd.pos +Vector(0,0,3)
	local posStart = nodeEnd.pos +Vector(0,0,3)
	local iHullsAccessable = 0
	local tblForceHulls = iForceHulls && math.SplitByPowerOfTwo(iForceHulls) || {}
	for k, v in pairs(tblHulls) do
		if table.HasValue(tblForceHulls, tblHullIDs[k]) || HullAccessable(posStart, posEnd, v) then
			iHullsAccessable = iHullsAccessable +tblHullIDs[k]
		end
	end
	
	local tbl = nodeType == 2 && nodesGround || nodeType == 3 && nodesAir || nodeType == 4 && nodesClimb || nodesWater
	table.insert(tbl[nodeIDStart].links, {dest = nodeIDEnd, move = iHullsAccessable, type = iType})
	table.insert(tbl[nodeIDEnd].links, {dest = nodeIDStart, move = iHullsAccessable, type = iType})
end

function AddNode(pos, iType, iForceHulls)
	local iNodeID = 0
	for k, v in pairs(nodes) do
		if k > iNodeID then iNodeID = k end
	end
	iNodeID = iNodeID +1
	local links = {}
	
	local tblHulls = {
		HULL_HUMAN = {max = Vector(13, 13, 72), min = Vector(-13, -13, 0)},
		HULL_SMALL_CENTERED = {max = Vector(20, 20, 40), min = Vector(-20, -20, 0)},
		HULL_WIDE_HUMAN = {max = Vector(15, 15, 72), min = Vector(-15, -15, 0)},
		HULL_TINY = {max = Vector(12, 12, 24), min = Vector(-12, -12, 0)},
		HULL_WIDE_SHORT = {max = Vector(35, 35, 32), min = Vector(-35, -35, 0)},
		HULL_MEDIUM = {max = Vector(16, 16, 64), min = Vector(-16, -16, 0)},
		HULL_TINY_CENTERED = {max = Vector(8, 8, 8), min = Vector(-8, -8, 0)},
		HULL_LARGE = {max = Vector(40, 40, 100), min = Vector(-40, -40, 0)},
		HULL_LARGE_CENTERED = {max = Vector(38, 38, 76), min = Vector(-38, -38, 0)},
		HULL_MEDIUM_TALL = {max = Vector(18, 18, 100), min = Vector(-18, -18, 0)}
	}
	
	if iType == 3 then
		for k, v in pairs(tblHulls) do
			v.max.z = v.max.z *0.5
			v.min.z = -v.max.z
		end
	end
	
	local tblHullIDs = {
		HULL_HUMAN = 1,
		HULL_SMALL_CENTERED = 2,
		HULL_WIDE_HUMAN = 4,
		HULL_TINY = 8,
		HULL_WIDE_SHORT = 16,
		HULL_MEDIUM = 32,
		HULL_TINY_CENTERED = 64,
		HULL_LARGE = 128,
		HULL_LARGE_CENTERED = 256,
		HULL_MEDIUM_TALL = 512
	}
	
	local tblForceHulls = iForceHulls && math.SplitByPowerOfTwo(iForceHulls) || {}
	for k, v in pairs(GetNodes(iType)) do
		if v.pos != pos && v.pos:Distance(pos) <= 320 then
			local tr = util.TraceLine({start = v.pos +Vector(0,0,3), endpos = pos +Vector(0,0,3), mask = MASK_NPCWORLDSTATIC})
			if !tr.Hit then
				local posStart = pos +Vector(0,0,3)
				local posEnd = v.pos +Vector(0,0,3)
				local iHullsAccessable = 0
				for k, v in pairs(tblHulls) do
					if table.HasValue(tblForceHulls, tblHullIDs[k]) || HullAccessable(posStart, posEnd, v) then
						iHullsAccessable = iHullsAccessable +tblHullIDs[k]
					end
				end
				table.insert(links, {dest = k, move = iHullsAccessable, type = 0})
				table.insert(v.links, {dest = iNodeID, move = iHullsAccessable, type = 0})
			end
		end
	end
	local node = {pos = pos, type = iType, zone = 0, yaw = 0, info = 0, links = links}
	if iType == 2 then nodesGround[iNodeID] = node
	elseif iType == 3 then nodesAir[iNodeID] = node
	elseif iType == 4 then nodesClimb[iNodeID] = node
	elseif iType == 5 then nodesWater[iNodeID] = node end
	nodes[iNodeID] = node
	return iNodeID
end

function RemoveNode(iNodeID)
	local iType = nodes[iNodeID].type
	nodes[iNodeID] = nil
	for k, v in pairs(nodes) do
		for _, link in pairs(v.links) do
			if link.dest == iNodeID then
				nodes[k].links[_] = nil
			end
		end
	end
	local tbl = iType == 2 && nodesGround || iType == 3 && nodesAir || iType == 4 && nodesClimb || nodesWater
	tbl[iNodeID] = nil
	for k, v in pairs(tbl) do
		for _, link in pairs(v.links) do
			if link.dest == iNodeID then
				tbl[k].links[_] = nil
			end
		end
	end
end

function RemoveLink(iNodeIDStart, iNodeIDEnd, iHullOnly)
	local iType = nodes[iNodeIDStart].type
	if !iHullOnly then
		if !iNodeIDEnd || iNodeIDStart == iNodeIDEnd then
			for k, v in pairs(nodes[iNodeIDStart].links) do
				for k, link in pairs(nodes[v.dest].links) do
					if link.dest == iNodeIDStart then
						table.remove(nodes[v.dest].links, k)
					end
				end
			end
			nodes[iNodeIDStart].links = {}
			return
		end
		for k, v in pairs(nodes[iNodeIDStart].links) do
			if v.dest == iNodeIDEnd then
				table.remove(nodes[iNodeIDStart].links, k)
				break
			end
		end
		for k, v in pairs(nodes[iNodeIDEnd].links) do
			if v.dest == iNodeIDStart then
				table.remove(nodes[iNodeIDEnd].links, k)
				break
			end
		end
		return
	end
	
	if !iNodeIDEnd || iNodeIDStart == iNodeIDEnd then
		for k, v in pairs(nodes[iNodeIDStart].links) do
			for k, link in pairs(nodes[v.dest].links) do
				if link.dest == iNodeIDStart then
					if table.HasValue(math.SplitByPowerOfTwo(v.move), iHullOnly) then
						nodes[v.dest].links[k].move = v.move -iHullOnly
					end
				end
			end
		end
		for k, v in pairs(nodes[iNodeIDStart].links) do
			if table.HasValue(math.SplitByPowerOfTwo(v.move), iHullOnly) then
				nodes[iNodeIDStart].links[k].move = v.move -iHullOnly
			end
		end
		return
	end
	for k, v in pairs(nodes[iNodeIDStart].links) do
		if v.dest == iNodeIDEnd then
			if table.HasValue(math.SplitByPowerOfTwo(v.move), iHullOnly) then
				nodes[iNodeIDStart].links[k].move = v.move -iHullOnly
			end
			break
		end
	end
	for k, v in pairs(nodes[iNodeIDEnd].links) do
		if v.dest == iNodeIDStart then
			if table.HasValue(math.SplitByPowerOfTwo(v.move), iHullOnly) then
				nodes[iNodeIDEnd].links[k].move = v.move -iHullOnly
			end
			break
		end
	end
end

local function _Save(i,content_links,content,tblNodeLinksIgnore)
	local _i = 0
	local bWorking = false
	debug.sethook()
	for k, v in pairs(nodes) do
		_i = _i +1
		if _i > i then
			if !v.persistent then
				content = content .. "\n	" .. k .. "	\n	{\n		pos = " .. tostring(v.pos) .. "\n		type = " .. v.type .. "\n		yaw = " .. v.yaw .. "\n		info = " .. v.info .. "\n	}"
				for _k, _v in pairs(v.links) do
					if !table.HasValue(tblNodeLinksIgnore, _v.dest) then
						table.insert(tblNodeLinksIgnore, k)
						content_links = content_links .. "\n	" .. k .. ", " .. _v.dest .. " = " .. _v.move .. ", " .. _v.type
					end
				end
			end
			i = i +1
			if i == 250 then
				timer.Simple(0,_Save,i,content_links,content,tblNodeLinksIgnore)
				bWorking = true
				break
			end
		end
	end
	if !bWorking then
		content_links = content_links .. "\n}"
		content = content .. "\n}\n\n" .. content_links
		file.Write("nodegraph/" .. game.GetMap() .. ".txt", content)
	end
end
function Save()
	local content_links = "links\n{"
	local content = "nodes\n{"
	local tblNodeLinksIgnore = {}
	_Save(0,content_links,content,tblNodeLinksIgnore)
end