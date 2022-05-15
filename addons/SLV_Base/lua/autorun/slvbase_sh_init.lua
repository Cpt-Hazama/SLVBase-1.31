if SLVBase then return end
require("datastream")
require("aigraph")
require("nodegraph")
if SERVER then require("tracex") end

local tblAddonsDerived = {}
SLVBase = {
	AddDerivedAddon = function(name, tblInfo)
		tblAddonsDerived[name] = tblInfo
	end,
	AddonInitialized = function(name)
		return !name || tblAddonsDerived[name] != nil
	end,
	GetDerivedAddons = function() return tblAddonsDerived end,
	GetDerivedAddon = function(name) return tblAddonsDerived[name] end,
	InitLua = function(dir)
		local _dir = "../lua/" .. dir .. "/"
		local tblFiles = {client = {}, server = {}}
		for k, v in pairs(file.Find(_dir .. "*")) do
			if string.find(v, ".lua") then table.insert(tblFiles.client, v); table.insert(tblFiles.server, v)
			elseif v == "client" || v == "server" then
				for k, _v in pairs(file.Find(_dir .. v .. "/*")) do
					if string.find(_v, ".lua") then
						table.insert(tblFiles[v], v .. "/" .. _v)
					end
				end
			end
		end
		if CLIENT then
			for k, v in pairs(tblFiles.client) do
				include(dir .. "/" .. v)
			end
		else
			for k, v in pairs(tblFiles.client) do
				AddCSLuaFile(dir .. "/" .. v)
			end
			for k, v in pairs(tblFiles.server) do
				include(dir .. "/" .. v)
			end
		end
	end
}

for _, particle in pairs({
		"svl_explosion",
		"blood_impact_red_01",
		"blood_impact_yellow_01",
		"blood_impact_green_01",
		"blood_impact_blue_01"
	}) do
	PrecacheParticleSystem(particle)
end

HITBOX_GENERIC = 100
HITBOX_HEAD = 101
HITBOX_CHEST = 102
HITBOX_STOMACH = 103
HITBOX_LEFTARM = 104
HITBOX_RIGHTARM = 105
HITBOX_LEFTLEG = 106
HITBOX_RIGHTLEG = 107
HITBOX_GEAR = 108
HITBOX_ADDLIMB = 109
HITBOX_ADDLIMB2 = 110

hook.Add("InitPostEntity", "SLV_PrecacheModels", function()
	local models = {}
	local function AddDir(path)
		for k, v in pairs(file.Find("../" .. path .. "*")) do
			if string.find(v, ".mdl") then
				table.insert(models, path .. v)
			end
		end
	end
	
	local function AddFile(file)
		table.insert(models, file)
	end
	for i = 1, 6 do AddFile("models/gibs/ice_shard0" .. i .. ".mdl") end
	
	for k, v in pairs(models) do
		util.PrecacheModel(v)
	end
	hook.Remove("InitPostEntity", "SLV_PrecacheModels")
end)

if CLIENT then
	if SinglePlayer() then SLVBase_IsInstalledOnServer = true
	else
		SLVBase_IsInstalledOnServer = false
		local addons = GetAddonList()
		for k, sAddon in pairs(addons) do
			local info = file.Read("../addons/" .. sAddon .. "/info.txt")
			if info && string.find(info, "SLVBase") then
				local path = "addons/" .. sAddon
				SLVBase_IsInstalledOnServer = true
				hook.Add("InitPostEntity", "slv_waitforinit", function()
					datastream.StreamToServer("slv_checkvalid",1,nil,function(accepted)
						if accepted then
							SLVBase_IsInstalledOnServer = false
							local tblFilesWeapons = {}
							local tblFilesStools = {}
							local tblFilesEnts = {}
							local iTool
							local listWeapons = weapons.GetList()
							local listNPCs = list.Get("NPC")
							--local listEnts = scripted_ents.GetList()
							local listEntsSpawnable = scripted_ents.GetSpawnable()
							for k, data in pairs(listWeapons) do
								if data.Folder == "weapons/gmod_tool" then iTool = k; break end
							end
							for addon, info in pairs(tblAddonsDerived) do
								local path
								for _, addonName in pairs(addons) do
									if addonName != sAddon then
										local info = file.Read("../addons/" .. addonName .. "/info.txt")
										if info && string.find(info, addon) then
											path = "addons/" .. addonName
											break
										end
									end
								end
								if path then
									table.Add(tblFilesWeapons, file.FindDir("../" .. path .. "/lua/weapons/*"))
									if iTool && listWeapons[iTool].Tool then
										table.Add(tblFilesStools, file.Find("../" .. path .. "/lua/weapons/gmod_tool/stools/*.lua"))
									end
									table.Add(tblFilesEnts, file.FindDir("../" .. path .. "/lua/entities/*"))
									if info.Unload then info:Unload() end
								end
							end
							for k, class in pairs(tblFilesWeapons) do
								tblFilesWeapons[k] = "weapons/" .. class
							end
							for k, data in pairs(listWeapons) do
								if table.HasValue(tblFilesWeapons, data.Folder) then
									listWeapons[k].Spawnable = false
									listWeapons[k].AdminSpawnable = false
								end
							end
							if iTool && listWeapons[iTool].Tool then
								for k, file in pairs(tblFilesStools) do
									tblFilesStools[k] = string.sub(file, 1, string.len(file) -4)
								end
								for stool, data in pairs(listWeapons[iTool].Tool) do
									if table.HasValue(tblFilesStools, stool) then
										listWeapons[iTool]["Tool"][stool] = nil
									end
								end
							end
							for k, class in pairs(tblFilesEnts) do
								class = string.lower(class)
								if listNPCs[class] then list.Set("NPC", class, nil)
								elseif listEntsSpawnable[class] then
									local data = scripted_ents.Get(class)
									local tblData = {Spawnable = false, AdminSpawnable = false, Type = data.Type, Base = data.Base}
									scripted_ents.Register(tblData, class, true)
								end
							end
							RunConsoleCommand("spawnmenu_reload")
						end
					end)
				end)
				break
			end
		end
	end
else
	NPC_STATE_LOST = 8
	if !SinglePlayer() then
		hook.Add("AcceptStream", "SLVBase_CheckValidity", function(pl, handler, ID)
			if handler == "slv_checkvalid" then return false end
		end)
	end
end
SLVBase.InitLua("slvbase_init")
