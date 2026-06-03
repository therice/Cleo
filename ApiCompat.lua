-- Dependency-free API compatibility shims that must load before libraries.

local Enum = _G.Enum or {}
_G.Enum = Enum

local function EnumTable(name)
    local t = Enum[name] or {}
    Enum[name] = t
    return t
end

local function Define(enumTable, enumKey, globalName, fallback)
    if enumTable[enumKey] == nil then
        enumTable[enumKey] = _G[globalName] ~= nil and _G[globalName] or fallback
    end

    if _G[globalName] == nil then
        _G[globalName] = enumTable[enumKey]
    end
end

local ItemClass = EnumTable("ItemClass")
Define(ItemClass, "Weapon", "LE_ITEM_CLASS_WEAPON", 2)
Define(ItemClass, "Armor", "LE_ITEM_CLASS_ARMOR", 4)
Define(ItemClass, "Miscellaneous", "LE_ITEM_CLASS_MISCELLANEOUS", 15)

local ItemWeaponSubclass = EnumTable("ItemWeaponSubclass")
Define(ItemWeaponSubclass, "Axe1H", "LE_ITEM_WEAPON_AXE1H", 0)
Define(ItemWeaponSubclass, "Axe2H", "LE_ITEM_WEAPON_AXE2H", 1)
Define(ItemWeaponSubclass, "Bows", "LE_ITEM_WEAPON_BOWS", 2)
Define(ItemWeaponSubclass, "Guns", "LE_ITEM_WEAPON_GUNS", 3)
Define(ItemWeaponSubclass, "Mace1H", "LE_ITEM_WEAPON_MACE1H", 4)
Define(ItemWeaponSubclass, "Mace2H", "LE_ITEM_WEAPON_MACE2H", 5)
Define(ItemWeaponSubclass, "Polearm", "LE_ITEM_WEAPON_POLEARM", 6)
Define(ItemWeaponSubclass, "Sword1H", "LE_ITEM_WEAPON_SWORD1H", 7)
Define(ItemWeaponSubclass, "Sword2H", "LE_ITEM_WEAPON_SWORD2H", 8)
Define(ItemWeaponSubclass, "Warglaive", "LE_ITEM_WEAPON_WARGLAIVE", 9)
Define(ItemWeaponSubclass, "Staff", "LE_ITEM_WEAPON_STAFF", 10)
Define(ItemWeaponSubclass, "Bearclaw", "LE_ITEM_WEAPON_BEARCLAW", 11)
Define(ItemWeaponSubclass, "Catclaw", "LE_ITEM_WEAPON_CATCLAW", 12)
Define(ItemWeaponSubclass, "Unarmed", "LE_ITEM_WEAPON_UNARMED", 13)
Define(ItemWeaponSubclass, "Generic", "LE_ITEM_WEAPON_GENERIC", 14)
Define(ItemWeaponSubclass, "Dagger", "LE_ITEM_WEAPON_DAGGER", 15)
Define(ItemWeaponSubclass, "Thrown", "LE_ITEM_WEAPON_THROWN", 16)
Define(ItemWeaponSubclass, "Crossbow", "LE_ITEM_WEAPON_CROSSBOW", 18)
Define(ItemWeaponSubclass, "Wand", "LE_ITEM_WEAPON_WAND", 19)

local ItemArmorSubclass = EnumTable("ItemArmorSubclass")
Define(ItemArmorSubclass, "Generic", "LE_ITEM_ARMOR_GENERIC", 0)
Define(ItemArmorSubclass, "Cloth", "LE_ITEM_ARMOR_CLOTH", 1)
Define(ItemArmorSubclass, "Leather", "LE_ITEM_ARMOR_LEATHER", 2)
Define(ItemArmorSubclass, "Mail", "LE_ITEM_ARMOR_MAIL", 3)
Define(ItemArmorSubclass, "Plate", "LE_ITEM_ARMOR_PLATE", 4)
Define(ItemArmorSubclass, "Cosmetic", "LE_ITEM_ARMOR_COSMETIC", 5)
Define(ItemArmorSubclass, "Shield", "LE_ITEM_ARMOR_SHIELD", 6)
Define(ItemArmorSubclass, "Libram", "LE_ITEM_ARMOR_LIBRAM", 7)
Define(ItemArmorSubclass, "Idol", "LE_ITEM_ARMOR_IDOL", 8)
Define(ItemArmorSubclass, "Totem", "LE_ITEM_ARMOR_TOTEM", 9)
Define(ItemArmorSubclass, "Sigil", "LE_ITEM_ARMOR_SIGIL", 10)
Define(ItemArmorSubclass, "Relic", "LE_ITEM_ARMOR_RELIC", 11)

local ItemMiscellaneousSubclass = EnumTable("ItemMiscellaneousSubclass")
Define(ItemMiscellaneousSubclass, "Junk", "LE_ITEM_MISCELLANEOUS_JUNK", 0)

local ItemBind = EnumTable("ItemBind")
Define(ItemBind, "None", "LE_ITEM_BIND_NONE", 0)
Define(ItemBind, "OnAcquire", "LE_ITEM_BIND_ON_ACQUIRE", 1)
Define(ItemBind, "OnEquip", "LE_ITEM_BIND_ON_EQUIP", 2)
Define(ItemBind, "OnUse", "LE_ITEM_BIND_ON_USE", 3)
Define(ItemBind, "Quest", "LE_ITEM_BIND_QUEST", 4)
