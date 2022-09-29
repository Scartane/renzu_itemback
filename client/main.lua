ESX						= nil
local currentWeapon = nil
viewer = false
local loaded = false
Citizen.CreateThread(function()
	ESX = exports['es_extended']:getSharedObject()
	ESX.PlayerData = ESX.GetPlayerData()
	PlayerData = ESX.PlayerData
	player = LocalPlayer.state
	Wait(2000)
	loaded = ESX.PlayerLoaded
end)

local onback = {}
active = false
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	for k,v in pairs(onback) do
		if DoesEntityExist(v.entity) then
			ReqAndDelete(v.entity)
		end
	end
	onback = {}
	print("Playerloaded")
	Wait(5000)
	active = true
	loaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
	loaded = false
	active = false
	for k,v in pairs(onback) do
		if DoesEntityExist(v.entity) then
			ReqAndDelete(v.entity)
		end
	end
	onback = {}
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	loaded = true
end)

local items = {}
RegisterNetEvent("itemsonback")
AddEventHandler('itemsonback', function(data)
	items = data
end)

RegisterCommand('itemsonback', function(source,args)
	Wait(1000)
	active = true
end)

function StartThread() -- temporary logic, to be reworked to non looped, later im lazy,  but it doesnt matter this dont consume much cpu. 0.0 or 0.01 most of the time
	Citizen.CreateThread(function()
		while true do
			while not active or not loaded do Wait(1000) end
			local ped = PlayerPedId()
			local save = false
			for k,v in pairs(items) do
				local name = k
				local data = Config[v.name]
				if data and not onback[v.name] and currentWeapon and v.name ~= currentWeapon.name 
				or currentWeapon == nil and data and not onback[v.name] then
					local model = data["model"]
					local ped = PlayerPedId()
					local bone = GetPedBoneIndex(ped, data["back_bone"])
					RequestModel(model)
					while not HasModelLoaded(model) do
						--print(model)
						Wait(10)
					end
					SetModelAsNoLongerNeeded(model)
					local ent = CreateObject(GetHashKey(model), 1.0, 1.0, 1.0, true, true, false)
					while not DoesEntityExist(ent) do Wait(1) end
					if not onback[v.name] then onback[v.name] = {} end
					onback[v.name] = {net = NetworkGetNetworkIdFromEntity(ent), entity = ent}
					save = true
					--print(data , not onback[v.name] , currentWeapon and v.name ~= currentWeapon.name,currentWeapon)
					local y = data["y"]  
					AttachEntityToEntity(ent, ped, bone, data["x"], y, data["z"], data["x_rotation"], data["y_rotation"], data["z_rotation"], 0, 1, 0, 1, 0, 1)
					SetEntityCompletelyDisableCollision(ent, false, true)	
				end
				if data and onback[v.name] then
					if onback[v.name].entity and not DoesEntityExist(onback[v.name].entity) then
						onback[v.name] = nil
					end
				end
			end
			if save then
				TriggerServerEvent('saveprop',onback) -- save net ids so we can properly removed objects
			end
			Wait(1000)
		end
	end)
end

RegisterNetEvent("ox_inventory:setPlayerInventory")
AddEventHandler('ox_inventory:setPlayerInventory', function(currentDrops, inventory, weight, esxItem, player, source)
	items = inventory
end)

StartThread()

lastweapon = nil
AddEventHandler('ox_inventory:currentWeapon', function(cw)
	if currentWeapon and lastweapon and lastweapon ~= currentWeapon.name then
		currentWeapon = nil
	end
	currentWeapon = cw
	if currentWeapon ~= nil and GetHashKey(currentWeapon.name) ~= GetHashKey('WEAPON_UNARMED') then
		local ped = PlayerPedId()
		for k,v in pairs(items) do
			if onback[v.name] and v.name == currentWeapon.name then
				ReqAndDelete(onback[v.name].entity)
				onback[v.name] = nil
			end
			lastweapon = v.name
		end
	elseif currentWeapon and GetHashKey(currentWeapon.name) == GetHashKey('WEAPON_UNARMED') then
		currentWeapon = nil
	end
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(name,count)
	local item = exports.ox_inventory:Search('slots', name)
	local count = 0
	for _, v in pairs(item) do
		print(v.slot..' contains '..v.count..' '..name..'')
		count = count + v.count
	end
	if count <= 0 then
		ReqAndDelete(onback[name].entity)
		onback[name] = nil
		for k,v in pairs(items) do
			if name == v.name then
				items[k] = nil
			end
		end
	end
	print("REMOVED ITEM INV"..name,count)
end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(name,count)
	local exist = false
	for k,v in pairs(items) do
		if name == v.name then
			exist = true
		end
	end
	if not exist then
		table.insert(items, {name = name, count = count})
	else
		for k,v in pairs(items) do
			if name == v.name then
				items[k].count = items[k].count + count
			end
		end
	end
end)

RegisterNetEvent('toggleprops') -- used for clothing shops or if you dont want to show the objects
AddEventHandler('toggleprops', function(bool)
	for k,v in pairs(onback) do
		SetEntityVisible(v.entity,bool)
	end
end)

RegisterNetEvent('togglesingle') -- same with above but to toggle single object only
AddEventHandler('togglesingle', function(name,bool)
	for k,v in pairs(onback) do
		if k == name then
			SetEntityVisible(v.entity,bool)
		end
	end
end)

function ReqAndDelete(object, detach)
    if NetworkGetEntityIsNetworked(object) then
        if DoesEntityExist(object) and NetworkGetEntityOwner(object) == PlayerId() then
            TriggerServerEvent('deleteentity', NetworkGetNetworkIdFromEntity(object))
            --print("sending server request delete")
        end
    else
        DeleteEntity(object)
		SetEntityCoords(object,0.0,0.0,0.0)
        --print("deleting Object locally")
    end
end