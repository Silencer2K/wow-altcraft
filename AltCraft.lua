local addonName, addon = ...

LibStub('AceAddon-3.0'):NewAddon(addon, addonName, 'AceEvent-3.0')

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

local COLOR_TOOLTIP_2L      = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 }

local COLOR_TOOLTIP_SOURCE  = 'ffffffff'
local COLOR_TOOLTIP_COUNT   = 'ffffff00'

function addon:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New(addonName .. 'DB', {
        profile = {
            minimap = {
                hide = false,
            },
        },
        global = {
            alliance = {},
            horde = {},
        },
    }, true)

    self.ldb = LibStub('LibDataBroker-1.1'):NewDataObject(addonName, {
        type = 'launcher',
        icon = 'Interface\\ICONS\\INV_Misc_Gem_Crystal_01',
        label = "AltCraft",
        OnTooltipShow = function(tooltip)
        end,
        OnClick = function()
            AltCraftFrame:Show()
        end,
    })

    self.icon = LibStub('LibDBIcon-1.0')
    self.icon:Register(addonName, self.ldb, self.db.profile.minimap)

    self:RegisterEvent('PLAYER_LOGIN', function(...)
        self:OnLogin()
    end)

    self:RegisterEvent('PLAYER_LEVEL_UP', function(event, level, ...)
        selc.charDb.level = 0 + level
    end)

    self:RegisterEvent('PLAYER_MONEY', function(...)
        self.charDb.money = GetMoney()
    end)

    self:RegisterEvent('BANKFRAME_OPENED', function(...)
        self:ScanBank()
    end)

    self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', function(...)
        self:ScanEquip()
    end)

    self:RegisterEvent('BAG_UPDATE', function(event, bagIndex, ...)
        if self.charDb then
            if bagIndex >= BACKPACK_CONTAINER and bagIndex <= NUM_BAG_SLOTS then
                self:ScanBags()
            elseif bagIndex == NUM_BAG_SLOTS + 1 and bagIndex <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS then
                self:ScanBank()
            end
        end
    end)

    self:RegisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED', function(...)
        self:ScanReagents()
    end)

    self:RegisterEvent('PLAYERBANKSLOTS_CHANGED', function(...)
        self:ScanBank()
    end)

    GameTooltip:HookScript('OnTooltipCleared', function(self)
        addon:OnGameTooltipCleared(self)
    end)

    GameTooltip:HookScript('OnTooltipSetItem', function(self)
        addon:OnGameTooltipSetItem(self)
    end)
end

function addon:OnLogin()
    self.char, self.realm = UnitFullName('player')
    self.faction = string.lower(UnitFactionGroup('player'))

    self.realmDb = self.db.global[self.faction][self.realm]
    if not self.realmDb then
        self.realmDb = {
            chars = {},
        }
        self.db.global[self.faction][self.realm] = self.realmDb
    end

    local _, class = UnitClass('player')

    self.charDb = self.realmDb.chars[self.char]
    if not self.charDb then
        self.charDb = {
            class = class,
            level = 0,
            money = 0,
            equip = {},
            bags = {},
            reagents = {},
            bank = {},
        }
        self.realmDb.chars[self.char] = self.charDb
    end

    self.charDb.level = UnitLevel('player')
    self.charDb.money = GetMoney()

    self:ScanEquip()
    self:ScanBags()
    self:ScanReagents()
end

function addon:ScanEquip()
    items = {}
    local slotIndex

    for slotIndex = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemId = GetInventoryItemID("player", slotIndex)
        local count = 1

        if itemId then
            if not items[itemId] then
                items[itemId] = {
                    count = count,
                }
            else
                items[itemId].count = items[itemId].count + count
            end
        end
    end

    self.charDb.equip = items
end

function addon:ScanContainers(fromIndex, toIndex, items)
    items = items or {}

    local bagIndex
    for bagIndex = fromIndex, toIndex do
        local itemIndex
        for itemIndex = 1, GetContainerNumSlots(bagIndex) do
            local itemId = GetContainerItemID(bagIndex, itemIndex)
            local _, count = GetContainerItemInfo(bagIndex, itemIndex)

            if itemId then
                if not items[itemId] then
                    items[itemId] = {
                        count = count,
                    }
                else
                    items[itemId].count = items[itemId].count + count
                end
            end
        end
    end

    return items
end

function addon:ScanBags()
    self.charDb.bags = self:ScanContainers(BACKPACK_CONTAINER, NUM_BAG_SLOTS)
end

function addon:ScanReagents()
    self.charDb.reagents = self:ScanContainers(REAGENTBANK_CONTAINER, REAGENTBANK_CONTAINER)
end

function addon:ScanBank()
    self.charDb.bank = self:ScanContainers(NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS,
        self:ScanContainers(BANK_CONTAINER, BANK_CONTAINER)
    )
end

function addon:OnGameTooltipCleared(tooltip)
end

function addon:OnGameTooltipSetItem(tooltip)
    local _, link = tooltip:GetItem()

    if link then
        local itemId = link:match('|Hitem:(%d+):')

        if itemId then
            itemId = 0 + itemId

            tooltip:AddLine(' ')

            local char, charDb
            for char, charDb in pairs(self.realmDb.chars) do
                local count, desc = 0

                local source, sourceDb
                for source, sourceDb in pairs({ equip = charDb.equip, bags = charDb.bags, reagents = charDb.reagents, bank = charDb.bank }) do
                    if sourceDb[itemId] then
                        count = count + sourceDb[itemId].count
                        desc = (desc and (desc .. ', ') or '') .. string.format(
                            '|c%s%s:|r |c%s%d|r',
                            COLOR_TOOLTIP_SOURCE,
                            L['in_' .. source],
                            COLOR_TOOLTIP_COUNT,
                            sourceDb[itemId].count
                        )
                    end
                end

                if count > 0 then
                    tooltip:AddDoubleLine(string.format(
                        '|c%s%s|r',
                        RAID_CLASS_COLORS[charDb.class].colorStr,
                        char
                    ), string.format(
                        '|c%s%d|r (%s)',
                        COLOR_TOOLTIP_COUNT,
                        count,
                        desc
                    ),
                    unpack(COLOR_TOOLTIP_2L))
                end
            end
        end
    end
end
