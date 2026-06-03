Enum = _G.Enum or {}

_G.Enum = Enum

Enum.ItemClass = {
	Weapon = 2,
	Armor = 4,
	Miscellaneous = 15,
}

Enum.ItemWeaponSubclass = {
	Axe1H = 0,
	Axe2H = 1,
	Bows = 2,
	Guns = 3,
	Mace1H = 4,
	Mace2H = 5,
	Polearm = 6,
	Sword1H = 7,
	Sword2H = 8,
	Warglaive = 9,
	Staff = 10,
	Bearclaw = 11,
	Catclaw = 12,
	Unarmed = 13,
	Generic = 14,
	Dagger = 15,
	Thrown = 16,
	Crossbow = 18,
	Wand = 19,
}

Enum.ItemArmorSubclass = {
	Generic = 0,
	Cloth = 1,
	Leather = 2,
	Mail = 3,
	Plate = 4,
	Cosmetic = 5,
	Shield = 6,
	Libram = 7,
	Idol = 8,
	Totem = 9,
	Sigil = 10,
	Relic = 11,
}

Enum.ItemMiscellaneousSubclass = {
	Junk = 0,
}

Enum.ItemBind = {
	None = 0,
	OnAcquire = 1,
	OnEquip = 2,
	OnUse = 3,
	Quest = 4,
}

loadfile('Test/API/LootConstants.lua')()
