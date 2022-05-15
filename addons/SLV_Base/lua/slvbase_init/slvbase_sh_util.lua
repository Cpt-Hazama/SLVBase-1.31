function util.GMIsAftermath()
	return GAMEMODE.Name == "Aftermath"
end

function math.SplitByPowerOfTwo(value)
	local tbl = {}
	while value > 0 do
		local i = 1
		while value >= i *2 do i = i *2 end
		table.insert(tbl, i)
		value = value -i
	end
	return tbl
end

function math.RoundForPos(num, pos, bKeepZeros)
	local inc = 10 ^pos
	local numRound = math.Round(num *inc) /inc
	if !bKeepZeros || pos <= 0 then return numRound end
	local decStart = string.find(numRound, "[.]")
	if !decStart then return numRound .. "." .. string.rep("0", pos) end
	return numRound .. string.rep("0", pos -(string.len(num) -(decStart)))
end

function ents.GetNPCs()
	local tblNPCs = {}
	for k, ent in pairs(ents.GetAll()) do
		if ent:IsNPC() then table.insert(tblNPCs, ent) end
	end
	return tblNPCs
end

function table.IsEmpty(tbl)
	for _, v in pairs(tbl) do return false end
	return true
end

local tblCustomAmmo = {}
function util.RegisterCustomAmmoType(ammo, ammoName)
	tblCustomAmmo[ammo] = ammoName
end

function util.GetCustomAmmoTypes()
	return tblCustomAmmo
end

function util.GetAmmoName(ammo)
	if tblCustomAmmo[ammo] then return tblCustomAmmo[ammo] end
	if ammo == "Buckshot" then return "Shotgun Ammo"
	elseif ammo == "RPG_Round" then return "RPG Round"
	elseif ammo == "XBowBolt" then return "Crossbow Bolts"
	elseif ammo == "SniperRound" || ammo == "SniperPenetratedRound" then return "Sniper Round"
	elseif ammo == "GaussEnergy" then return "Gauss Energy"
	elseif ammo == "Grenade" then return "Grenades"
	elseif ammo == "SMG1_Grenade" then return "SMG Grenades"
	elseif ammo == "AR2AltFire" then return "Combine's Balls"
	elseif ammo == "slam" then return "SLAM Ammo"
	else return ammo .. " Ammo" end
end

local tblAmmoDefault = {
	"ar2", 
	"alyxgun", 
	"pistol", 
	"smg1", 
	"357", 
	"xbowbolt", 
	"buckshot", 
	"rpg_round", 
	"smg1_grenade", 
	"sniperround", 
	"sniperpenetratedround", 
	"grenade", 
	"thumper", 
	"gravity", 
	"battery", 
	"gaussenergy", 
	"combinecannon", 
	"airboatgun", 
	"striderminigun", 
	"helicoptergun", 
	"ar2altfire", 
	"slam"
}
function util.IsDefaultAmmoType(ammo)
	return table.HasValue(tblAmmoDefault, string.lower(ammo))
end

function table.refresh(tbl) -- obsolete; kept for backward-compatibilty
	table.MakeSequential(tbl)
end

function table.MakeSequential(tbl)
	local i = 1
	for ind, _ in pairs(tbl) do
		if ind > i then tbl[i] = tbl[ind]; tbl[ind] = nil end
		i = i +1
	end
end

function util.IsInWater(vecPos)
	return util.TraceLine({start = vecPos +Vector(0,0,32768), endpos = vecPos, mask = MASK_WATER}).Hit
end

function util.HLR_MinMaxVector(vecA, vecB)
	local vecMin, vecMax = Vector(), Vector()
	if vecA.x < vecB.x then vecMin.x = vecA.x; vecMax.x = vecB.x else vecMin.x = vecB.x; vecMax.x = vecA.x end
	if vecA.y < vecB.y then vecMin.y = vecA.y; vecMax.y = vecB.y else vecMin.y = vecB.y; vecMax.y = vecA.y end
	if vecA.z < vecB.z then vecMin.z = vecA.z; vecMax.z = vecB.z else vecMin.z = vecB.z; vecMax.z = vecA.z end
	return vecMin, vecMax
end
