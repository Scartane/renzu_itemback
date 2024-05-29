ESX = nil
local currentWeapon = nil
local currentWeaponInventory = nil
local loaded = false
local compodata = {}
local itemsdb = {}
local PlayerData = {}
local hasPlayerSpawned = false

local function initClientData(hasPlayerLoad)
    ESX.TriggerServerCallback('renzu:server:getItems', function(data)
        itemsdb = data

        ESX.PlayerData = ESX.GetPlayerData()
        PlayerData = ESX.PlayerData

        local componentitems = {}
        for item, v in pairs(itemsdb) do
            if v.category and string.find(v.category, 'component_') then
                componentitems[item] = v.componentHash
            end
        end
        for k, v in pairs(components_data) do
            local compo = GetHashKey(v.name)
            v.model = GetHashKey(v.model)
            v.name = GetHashKey(v.name)
            for item, v2 in pairs(componentitems) do
                if GetHashKey(v2) == v.name then
                    v.item = item
                end
            end
            compodata[compo] = v
        end
        CleanupOnRestart()
        CleanupProps()
        if PlayerData then 
            hasPlayerSpawned = true
            Loop()
            GetInventory()    
        end
    end)
end

CreateThread(function()
    Wait(1)

    while ESX == nil do
        if Config.NewESX then
            ESX = exports['es_extended']:getSharedObject()
        else
            TriggerEvent('esx:getSharedObject', function(obj)
                ESX = obj
            end)
        end
        Citizen.Wait(50)
    end

    initClientData()
end)

local onback = {}
local items = {}
local inv = {}


RegisterNetEvent('renzu_itemback:startLoop', function()
    Wait(2500)
    Loop()
    GetInventory()
end)

function Loop()
    CreateThread(function()
        while true do
            local callbackEnd = false
            local added = {}

            local weaponEquiped = exports['core_inventory']:getWeaponEquiped()

            if weaponEquiped then
                inv['primary-weaponEquiped'] = weaponEquiped.primary
                inv['secondry-weaponEquiped'] = weaponEquiped.secondry
                if not weaponEquiped.active and currentWeapon then
                    currentWeapon = nil
                end
            else
                currentWeapon = nil
            end

            for k, v in pairs(inv) do
                if v.name and v.name ~= nil then
                    ItemBack(v.name, v.metadata)
                    added[v.name] = true
                end
            end

            for k, v in pairs(onback) do
                if v and not added[k] then
                    DeleteAttachments(onback[k])
                    ReqAndDelete(onback[k].entity)
                    onback[k] = nil
                end
            end
            Wait(10)
        end
    end)
end

function GetInventory()
    ESX.TriggerServerCallback('core_inventory:server:getInventory', function(data)
        inv = data
        if hasPlayerSpawned then
            SetTimeout(5000, GetInventory) -- Keep the loop running with updated inventory
        else
            Wait(5000)
            GetInventory()
        end
    end)
end

RegisterNetEvent('esx:playerLoaded', function(playerData)
    hasPlayerSpawned = true
    CleanupOnRestart()
    CleanupProps()
    initClientData(hasPlayerSpawned)
end)

startingup = true

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
    for k, v in pairs(onback) do
        if DoesEntityExist(v.entity) then
            DeleteAttachments(v)
            ReqAndDelete(v.entity)
        end
    end
    onback = {}
    hasPlayerSpawned = false
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

GetWeaponComponents = function(weapon, metadata)
    local components = {}
    local hascomponents = false
    if metadata and metadata.attachments then
        for k, v in pairs(metadata.attachments) do
            for kk, v4 in pairs(compodata) do
                if v4.item then
                    if v4.item == v.name then
                        components[GetHashKey(v.componentHash)] = v4
                        hascomponents = true
                    end
                end
            end
        end
    end
    return hascomponents, components
end

ItemBack = function(name, data)
    if not name or name == nil or name == 'nil' then
        return
    end

    local itemname = name
    local metadata = data

    local data = Config[itemname] or Config[string.upper(itemname)]
    local save = false
    if data and not onback[itemname] and ((currentWeapon and itemname ~= currentWeapon.name) or not currentWeapon) then
        local model = data["model"]
        local ped = cache.ped
        local bone = GetPedBoneIndex(ped, data["back_bone"])
        lib.requestModel(model)
        SetModelAsNoLongerNeeded(model)
        local ent = CreateObject(GetHashKey(model), GetEntityCoords(cache.ped) - vec3(0.0, 0.0, 5.0), true, true, false)
        while not DoesEntityExist(ent) do
            Wait(1)
        end
        while not NetworkGetEntityIsNetworked(ent) do
            Wait(1)
            NetworkRegisterEntityAsNetworked(ent)
        end
        if not onback[itemname] then
            onback[itemname] = {}
        end
        onback[itemname] = {
            net = NetworkGetNetworkIdFromEntity(ent),
            entity = ent
        }
        save = true
        local y = data["y"]
        AttachEntityToEntity(ent, ped, bone, data["x"], y, data["z"], data["x_rotation"], data["y_rotation"],
            data["z_rotation"], 0, 1, 0, 1, 0, 1)
        SetEntityCompletelyDisableCollision(ent, false, true)
        if string.find(itemname:upper(), "WEAPON_") then
            local hascompo, components = GetWeaponComponents(itemname, metadata)
            if hascompo then
                for k, v in pairs(components) do
                    if IsModelInCdimage(v.model) then
                        local bone = GetEntityBoneIndexByName(ent, v.bone)
                        lib.requestModel(v.model)
                        local componentEntity = CreateObjectNoOffset(v.model,
                            GetEntityCoords(cache.ped) - vec3(0.0, 0.0, 5.0), true, true)
                        while not DoesEntityExist(componentEntity) do
                            Wait(1)
                        end
                        NetworkRegisterEntityAsNetworked(componentEntity)
                        while not NetworkGetEntityIsNetworked(componentEntity) do
                            Wait(1)
                            NetworkRegisterEntityAsNetworked(componentEntity)
                        end
                        if onback[itemname]['components'] == nil then
                            onback[itemname]['components'] = {}
                        end
                        table.insert(onback[itemname]['components'], NetworkGetNetworkIdFromEntity(componentEntity))
                        SetEntityCollision(componentEntity, false, false)
                        AttachEntityToEntity(componentEntity, ent, bone, 0.0, 0.0, 0.00, 0.0, 0.0, 0.0, true, true,
                            false, false, 1, true)
                    end
                end
            end
        end
    end
end

lastweapon = nil

DeleteAttachments = function(data)
    if data and data.components then
        for k, v in pairs(data.components) do
            if DoesEntityExist(NetworkGetEntityFromNetworkId(v)) then
                DeleteEntity(NetworkGetEntityFromNetworkId(v))
            end
        end
    end
end

AddEventHandler('core_inventory:custom:handleWeapon', function(cwn, cw, cwi)
    if cwn == nil and currentWeapon ~= nil then
        ItemBack(currentWeapon.name, currentWeapon.metadata)
        currentWeapon = nil
    else
        if currentWeapon ~= nil then
            ItemBack(currentWeapon.name, currentWeapon.metadata)
            currentWeapon = nil
        end
        currentWeapon = cw
        if onback[cwn] then
            DeleteAttachments(onback[cwn])
            ReqAndDelete(onback[cwn].entity)
            onback[cwn] = nil
        end
    end
    currentWeaponInventory = cwi
end)

ToggleItemBack = function(bool)
    for k, v in pairs(onback) do
        SetEntityVisible(v.entity, bool)
    end
end

-- used for clothing shops or if you dont want to show the objects
RegisterNetEvent('toggleprops', ToggleItemBack)
exports('ToggleItemBack', ToggleItemBack)

ToggleItemBackSingle = function(name, bool)
    for k, v in pairs(onback) do
        if k == name then
            SetEntityVisible(v.entity, bool)
        end
    end
end

-- same with above but to toggle single object only
RegisterNetEvent('togglesingle', ToggleItemBackSingle)
exports('ToggleItemBackSingle', ToggleItemBackSingle)

local bool = true
RegisterCommand('toggleprops', function(source, args)
    ToggleItemBack(not bool)
    bool = not bool
end)

function ReqAndDelete(object, detach)
    if detach then
        DetachEntity(object, true, true)
    end

    if DoesEntityExist(object) then
        if NetworkGetEntityIsNetworked(object) then
            NetworkRequestControlOfEntity(object)
            local timeout = 2000
            while timeout > 0 and not NetworkHasControlOfEntity(object) do
                Wait(100)
                timeout = timeout - 100
            end

            TriggerServerEvent('deleteentity', NetworkGetNetworkIdFromEntity(object))
        else
            SetEntityAsNoLongerNeeded(object)
            DeleteEntity(object)
        end
    else
        DeleteEntity(object)
        SetEntityCoords(object, 0.0, 0.0, 0.0)
    end
end

----
function CleanupOnRestart()
    if onback then
        for itemName, itemData in pairs(onback) do
            if itemData.entity and DoesEntityExist(itemData.entity) then
                DeleteEntity(itemData.entity)
            end
        end
    end
    onback = {} -- Initialize the onback table if it doesn't exist
    -- Clear the inventory cache
    inv = {}
    -- Clear the current weapon variable
    currentWeapon = nil
    currentWeaponInventory = nil
end
------------
function CleanupProps()
    for _, prop in pairs(onback) do
        -- Delete the main weapon object
        if DoesEntityExist(prop.entity) then
            DeleteEntity(prop.entity)
        end

        -- Delete any associated components
        if prop.components then
            for _, compNetId in pairs(prop.components) do
                local compEnt = NetworkGetEntityFromNetworkId(compNetId)
                if DoesEntityExist(compEnt) then
                    DeleteEntity(compEnt)
                end
            end
        end
    end
end
-- Call CleanupOnRestart when the script is restarted
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupOnRestart()
        CleanupProps()
    end
end)
