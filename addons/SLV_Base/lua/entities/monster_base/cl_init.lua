include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Draw()
	self.Entity:DrawModel()
end

function ENT:DrawTranslucent()
end

function ENT:BuildBonePositions(NumBones, NumPhysBones)
end

function ENT:SetRagdollBones(bIn)
	self.m_bRagdollSetup = bIn
end

function ENT:DoRagdollBone(PhysBoneNum, BoneNum)
end 

hook.Add("OnEntityCreated", "SLV_ClientInitFix", function(ent)
	if ValidEntity(ent) && ent:IsNPC() then
		timer.Simple(0, function()
			if ValidEntity(ent) && ent:IsNPC() then
				local class = ent.ClassName || ent:GetClass()
				local filename = "entities/" .. class .. "/cl_init.lua"
				if file.Exists("../lua/" .. filename) || file.Exists("../gamemodes/" .. GAMEMODE.Name .. "/entities/" .. filename) then
					ENT = ent
					include(filename)
					ENT = nil
				end
			end
		end)
	end
end)