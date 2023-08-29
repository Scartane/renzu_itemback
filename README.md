# renzu_itemback [CORE INVENTORY COMPATIBLE]

In **core_inventory resource folder**, locate `/client/main.lua` and add this event at the end of the file :
```lua 
exports('getWeaponEquiped', function()
    return { 
        primary = Holders['primary-'.. cid],
        secondry = Holders['secondry-'.. cid],
        active = currentWeaponData,
        activeInventory = currentWeaponInventory
    }
end)
```

Then, in the same file, locate the `function useWeapon(weapon, inventory)` and at the end of the function, before the last end that close it, add :
```lua
TriggerEvent('core_inventory:custom:handleWeapon', currentWeapon, currentWeaponData, currentWeaponInventory)
```

This script need to be start **after** core_inventory

- Show any item to your Character
- Multiple Weapons are included in default config, and some custom items example.
- Supports Weapon Attachedments
- DEPENDENCY : OX INVENTORY
- FRAMEWORK ESX ONLY!

![image](https://user-images.githubusercontent.com/82306584/197387181-ab0957b4-b432-4461-8cf1-ece436538472.png)

![image](https://user-images.githubusercontent.com/82306584/192984062-9d57d413-0d32-4bbc-ab5a-3e17c584cebd.png)
![image](https://user-images.githubusercontent.com/82306584/192984202-bdcc96bd-f764-4d7b-a8ea-9444cc8bc354.png)
![image](https://user-images.githubusercontent.com/82306584/192984478-f248d17d-7f96-4d4f-af65-a6cba585ee9c.png)


# here is the tool
- if you want to edit the position of object
- https://forum.cfx.re/t/devtool-attach-object-to-ped-with-preview/4758930
