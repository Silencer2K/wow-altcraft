local addonName, addon = ...

LibStub('AceAddon-3.0'):NewAddon(addon, addonName, 'AceEvent-3.0', 'AceTimer-3.0')

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

local COLOR_TOOLTIP         = { 1.0, 1.0, 1.0 }
local COLOR_TOOLTIP_2L      = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 }
local COLOR_ICON_TOOLTIP    = { 0.8, 0.8, 0.8 }

local COLOR_TOOLTIP_SOURCE  = 'ffffffff'
local COLOR_TOOLTIP_COUNT   = 'ffffff00'

function addon:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New(addonName .. 'DB', self:GetDefaults(), true)

    self.ldb = LibStub('LibDataBroker-1.1'):NewDataObject(addonName, {
        type = 'launcher',
        icon = 'Interface\\ICONS\\INV_Gizmo_KhoriumPowerCore',
        label = "AltCraft",
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(addonName)
            tooltip:AddLine(L.icon_tooltip, unpack(COLOR_ICON_TOOLTIP))
        end,
        OnClick = function(obj, button)
            if button == 'RightButton' then
                InterfaceOptionsFrame_OpenToCategory(addonName)
            else
                if AltCraftFrame:IsShown() then
                    AltCraftFrame:Hide()
                else
                    AltCraftFrame:Show()
                    AltCraftFrame:OnSelectTab(1)
                end
            end
        end,
    })

    self.icon = LibStub('LibDBIcon-1.0')
    self.icon:Register(addonName, self.ldb, self.db.profile.minimap)

    self:RegisterEvent('PLAYER_LOGIN', function(...)
        self:OnLogin()
    end)

    self:RegisterEvent('PLAYER_LEVEL_UP', function(event, level, ...)
        self.charDb.level = 0 + level
    end)

    self:RegisterEvent('PLAYER_MONEY', function(...)
        self.charDb.money = GetMoney()
    end)

    self:RegisterEvent('BANKFRAME_OPENED', function(...)
        self:ScanBank()
    end)

    self:RegisterEvent('BANKFRAME_CLOSED', function(...)
        if self.scanBankTimer then
            self:ScanBank()
        end
    end)

    self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', function(...)
        self.charDb.ilevel = select(2, GetAverageItemLevel())
        self:ScanEquip(true)
    end)

    self:RegisterEvent('BAG_UPDATE', function(event, bagIndex, ...)
        if self.charDb then
            if bagIndex >= BACKPACK_CONTAINER and bagIndex <= NUM_BAG_SLOTS then
                self:ScanBags(true)
            elseif bagIndex >= NUM_BAG_SLOTS + 1 and bagIndex <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS then
                self:ScanBank(true)
            end
        end
    end)

    self:RegisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED', function(...)
        self:ScanReagents(true)
    end)

    self:RegisterEvent('PLAYERBANKSLOTS_CHANGED', function(...)
        self:ScanBank(true)
    end)

    GameTooltip:HookScript('OnTooltipCleared', function(self)
        addon:OnGameTooltipCleared(self)
    end)

    GameTooltip:HookScript('OnTooltipSetItem', function(self)
        addon:OnGameTooltipSetItem(self)
    end)

    AltCraftFrame:OnInitialize()

    LibStub('AceConfig-3.0'):RegisterOptionsTable(addonName, self:GetOptions())
    LibStub('AceConfigDialog-3.0'):AddToBlizOptions(addonName, addonName, nil)
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

            equip = {},
            bags = {},
            reagents = {},
            bank = {},
        }
        self.realmDb.chars[self.char] = self.charDb
    end

    self.charDb.level = UnitLevel('player')
    self.charDb.ilevel = select(2, GetAverageItemLevel())
    self.charDb.money = GetMoney()

    self:ScanEquip()
    self:ScanBags()
    self:ScanReagents()

    self:ScanProfs()
end

function addon:ScanEquip(deffered)
    if self.scanEquipTimer then
        self:CancelTimer(self.scanEquipTimer)
        self.scanEquipTimer = nil
    end

    if deffered then
        self.scanEquipTimer = self:ScheduleTimer(function()
            self:ScanEquip()
        end, 0.2)
        return
    end

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

function addon:ScanBags(deffered)
    if self.scanBagsTimer then
        self:CancelTimer(self.scanBagsTimer)
        self.scanBagsTimer = nil
    end

    if deffered then
        self.scanBagsTimer = self:ScheduleTimer(function()
            self:ScanBags()
        end, 0.2)
        return
    end

    self.charDb.bags = self:ScanContainers(BACKPACK_CONTAINER, NUM_BAG_SLOTS)
end

function addon:ScanReagents(deffered)
    if self.scanReagentsTimer then
        self:CancelTimer(self.scanReagentsTimer)
        self.scanReagentsTimer = nil
    end

    if deffered then
        self.scanReagentsTimer = self:ScheduleTimer(function()
            self:ScanReagents()
        end, 0.2)
        return
    end

    self.charDb.reagents = self:ScanContainers(REAGENTBANK_CONTAINER, REAGENTBANK_CONTAINER)
end

function addon:ScanBank(deffered)
    if self.scanBankTimer then
        self:CancelTimer(self.scanBankTimer)
        self.scanBankTimer = nil
    end

    if deffered then
        self.scanBankTimer = self:ScheduleTimer(function()
            self:ScanBank()
        end, 0.2)
        return
    end

    self.charDb.bank = self:ScanContainers(NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS,
        self:ScanContainers(BANK_CONTAINER, BANK_CONTAINER)
    )
end

function addon:ScanProfs()
    local profs = { GetProfessions() }

    local index
    for index = 1, 2 do
        if not profs[index] then
            self.charDb['prof' .. index], self.charDb['prof' .. index .. 'level'] = nil, nil
        else
            self.charDb['prof' .. index], self.charDb['prof' .. index .. 'level'] = unpackByIndex({ GetProfessionInfo(profs[index]) }, 1, 3)
        end
    end
end

function addon:GetChars(faction, realm)
    faction = faction and string.lower(faction) or self.faction
    realm = realm or self.realm

    if not self.db.global[faction] or not self.db.global[faction][realm] then
        return {}
    end

    return self.db.global[faction][realm].chars
end

function addon:OnGameTooltipCleared(tooltip)
end

function addon:OnGameTooltipSetItem(tooltip)
    local disabled = false;--_G['Altoholic'] or false

    if not disabled then
        local _, link = tooltip:GetItem()

        if link then
            local itemId = link:match('|Hitem:(%d+):')

            if itemId then
                itemId = 0 + itemId

                tooltip:AddLine(' ')

                local total = 0

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
                                L['tooltip_' .. source],
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
                        ), unpack(COLOR_TOOLTIP_2L))
                    end

                    total = total + count
                end

                tooltip:AddLine(string.format(
                    '%s: |c%s%d|r',
                    L.tooltip_total,
                    COLOR_TOOLTIP_COUNT,
                    total
                ), unpack(COLOR_TOOLTIP))
            end
        end
    end
end
