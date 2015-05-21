local addonName, addon = ...

LibStub('AceAddon-3.0'):NewAddon(addon, addonName, 'AceEvent-3.0', 'AceTimer-3.0')

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

local VERSION = 4

local COLOR_TOOLTIP         = { 1.0, 1.0, 1.0 }
local COLOR_TOOLTIP_2L      = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 }
local COLOR_ICON_TOOLTIP    = { 0.8, 0.8, 0.8 }

local COLOR_TOOLTIP_SOURCE  = 'ffffffff'
local COLOR_TOOLTIP_COUNT   = 'ffffff00'

local PROF_SKILLS = {
    [164] = 'Blacksmithing',
    [165] = 'Leatherworking',
    [171] = 'Alchemy',
    [182] = 'Herbalism',
    [186] = 'Mining',
    [197] = 'Tailoring',
    [202] = 'Engineering',
    [333] = 'Enchanting',
    [393] = 'Skinning',
    [755] = 'Jewelcrafting',
    [773] = 'Inscription',
}

local PROF_LEVELS = {
    Blacksmithing = {
        {  5,   0,   0,  75 },
        { 10,  50,  75, 150 },
        { 20, 125, 150, 225 },
        { 35, 200, 225, 300 },
        { 50, 275, 300, 375 },
        { 65, 350, 375, 450 },
        { 75, 425, 450, 525 },
        { 85, 500, 525, 600 },
        { 90,   0, 600, 700 },
    },
    Herbalism = {
        {  0,   0,   0,  75 },
        {  0,  50,  75, 150 },
        { 10, 125, 150, 225 },
        { 25, 200, 225, 300 },
        { 40, 275, 300, 375 },
        { 55, 350, 375, 450 },
        { 75, 425, 450, 525 },
        { 85, 500, 525, 600 },
        { 90,   0, 600, 700 },
    },
}

PROF_SKILLS.Leatherworking = PROF_SKILLS.Blacksmithing
PROF_SKILLS.Alchemy        = PROF_SKILLS.Blacksmithing
PROF_SKILLS.Tailoring      = PROF_SKILLS.Blacksmithing
PROF_SKILLS.Engineering    = PROF_SKILLS.Blacksmithing
PROF_SKILLS.Enchanting     = PROF_SKILLS.Blacksmithing
PROF_SKILLS.Jewelcrafting  = PROF_SKILLS.Blacksmithing
PROF_SKILLS.Inscription    = PROF_SKILLS.Blacksmithing

PROF_SKILLS.Mining   = PROF_SKILLS.Herbalism
PROF_SKILLS.Skinning = PROF_SKILLS.Herbalism

function addon:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New(addonName .. 'DB', self:GetDefaults(), true)

    if self.db.global.version ~= VERSION then
        self.db.global.version = VERSION
        self.db.global.realms = {}
    end

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
                if AltCraftFrame:IsShown() and AltCraftFrame.CharsTabFrame:IsShown() then
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
        self:UpdateFrames('level')
    end)

    self:RegisterEvent('PLAYER_MONEY', function(...)
        self.charDb.money = GetMoney()
        self:UpdateFrames('money')
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
        self:UpdateFrames('ilevel')

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

    self:RegisterEvent('SKILL_LINES_CHANGED', function(...)
        if self.charDb then
            self:ScanProfs()
        end
    end)

    hooksecurefunc('SendMail', function(...)
        self:ScanOutbox(...)
    end)

    self:RegisterEvent('MAIL_SEND_SUCCESS', function(...)
        self:ProcessOutbox()
    end)

    self:RegisterEvent('MAIL_INBOX_UPDATE', function(...)
        self:ScanInbox(true)
    end)

    self:RegisterEvent('MAIL_CLOSED', function(...)
        self:ScanInbox()
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

function addon:UpdateFrames(what)
    if AltCraftFrame:IsShown() and AltCraftFrame.CharsTabFrame:IsShown() then
        if what == 'level' or what == 'ilevel' or what == 'money' or what == 'profs' then
            AltCraftFrame.CharsTabFrame:Update()
        end
    end
end

function addon:OnLogin()
    self.realm = GetRealmName()
    self.faction = string.upper(UnitFactionGroup('player'))
    self.char = UnitName('player')

    self.realmDb = self.db.global.realms[self.realm]
    if not self.realmDb then
        self.realmDb = {
            chars = {},
        }

        self.db.global.realms[self.realm] = self.realmDb
    end

    local class = select(2, UnitClass('player'))
    class = class:upper()

    local race = select(2, UnitRace('player'))
    race = race:upper()

    local gender = UnitSex('player') == 2 and 'MALE' or 'FEMALE'
    local level  = UnitLevel('player')

    self.charDb = self.realmDb.chars[self.char]
    if not self.charDb or class ~= self.charDb.class or level < self.charDb.level then
        self.charDb = {
            faction = self.faction,
            class   = class,
            race    = race,
            gender  = gender,

            items = {
                equip    = {},
                bags     = {},
                reagents = {},
                bank     = {},
                mail     = {},
            },

            profs = {},
        }

        self.realmDb.chars[self.char] = self.charDb
    end

    self.charDb.level = level
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
        local itemId = GetInventoryItemID('player', slotIndex)
        local count = 1

        if itemId then
            if not items[itemId] then
                items[itemId] = { count = count }
            else
                items[itemId].count = items[itemId].count + count
            end
        end
    end

    self.charDb.items.equip = items

    self:UpdateFrames('equip')
end

function addon:ScanContainers(fromIndex, toIndex, items)
    items = items or {}

    local bagIndex
    for bagIndex = fromIndex, toIndex do
        local itemIndex
        for itemIndex = 1, GetContainerNumSlots(bagIndex) do
            local itemId = GetContainerItemID(bagIndex, itemIndex)
            local count = select(2, GetContainerItemInfo(bagIndex, itemIndex))

            if itemId then
                if not items[itemId] then
                    items[itemId] = { count = count }
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

    self.charDb.items.bags = self:ScanContainers(BACKPACK_CONTAINER, NUM_BAG_SLOTS)

    self:UpdateFrames('bags')
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

    self.charDb.items.reagents = self:ScanContainers(REAGENTBANK_CONTAINER, REAGENTBANK_CONTAINER)

    self:UpdateFrames('reagents')
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

    self.charDb.items.bank = self:ScanContainers(NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS,
        self:ScanContainers(BANK_CONTAINER, BANK_CONTAINER)
    )

    self:UpdateFrames('bank')
end

function addon:ScanProfs()
    local profs = { GetProfessions() }

    local profIndex
    for profIndex = 1, 2 do
        self.charDb.profs[profIndex - 1] = nil
        if profs[profIndex] then
            local skill, level = unpackByIndex({ GetProfessionInfo(profs[profIndex]) }, 7, 3)
            if PROF_SKILLS[skill] then
                self.charDb.profs[profIndex - 1] = { name = PROF_SKILLS[skill], level = level }
            end
        end
    end

    self:UpdateFrames('profs')
end

function addon:ScanOutbox(rcpt, subject, body)
    self.outbox = {
        rcpt    = rcpt,
        subject = subject,
        body    = body,

        money   = GetSendMailMoney(),
        cod     = GetSendMailCOD(),
    }

    local items = {}

    local itemIndex
    for itemIndex = 1, ATTACHMENTS_MAX_SEND do
        local link = GetSendMailItemLink(itemIndex)
        if link then
            local itemId = 0 + link:match('|Hitem:(%d+):')
            local count = select(3, GetSendMailItem(itemIndex))

            if not items[itemId] then
                items[itemId] = { count = count }
            else
                items[itemId].count = items[itemId].count + count
            end
        end
    end

    self.outbox.items = items
end

function addon:ProcessOutbox()
    local char, realm = strsplit('-', self.outbox.rcpt, 2)
    local charDb = self:GetCharDb(char, realm)

    if charDb then
        local items = charDb.items.mail

        local itemId, itemData
        for itemId, itemData in pairs(self.outbox.items) do
            if not items[itemId] then
                items[itemId] = { count = itemData.count }
            else
                items[itemId].count = items[itemId].count + itemData.count
            end
        end
    end

    self.outbox = nil

    self:UpdateFrames('mail')
end

function addon:ScanInbox(deffered)
    if self.scanInboxTimer then
        self:CancelTimer(self.scanInboxTimer)
        self.scanInboxTimer = nil
    end

    if deffered then
        self.scanInboxTimer = self:ScheduleTimer(function()
            self:ScanInbox()
        end, 0.2)
        return
    end

    local items = {}

    local mailIndex
    for mailIndex = 1, GetInboxNumItems() do
        local itemIndex
        for itemIndex = 1, ATTACHMENTS_MAX_RECEIVE do
            local link = GetInboxItemLink(mailIndex, itemIndex)
            if link then
                local itemId = 0 + link:match('|Hitem:(%d+):')
                local count = select(3, GetInboxItem(mailIndex, itemIndex))

                if not items[itemId] then
                    items[itemId] = { count = count }
                else
                    items[itemId].count = items[itemId].count + count
                end
            end
        end
    end

    self.charDb.items.mail = items

    self:UpdateFrames('mail')
end

function addon:GetRealms()
    local list = {}

    for realm in pairs(self.db.global.realms) do
        if not tableIsEmpty(self.db.global.realms[realm]) then
            table.insert(list, realm)
        end
    end

    table.sort(list)

    return list
end

function addon:GetChars(realm, faction)
    realm = realm or self.realm
    faction = faction and faction:upper() or self.faction

    local list = {}

    if self.db.global.realms[realm] then
        local char, charDb
        for char, charDb in pairs(self.db.global.realms[realm].chars) do
            if faction == charDb.faction then
                list[char] = charDb
            end
        end
    end

    return list
end

function addon:GetCharDb(char, realm)
    char = char:lower()

    realm = realm or self.realm
    realm = realm:gsub('[- ]', ''):lower()

    local tryRealm, realmDb
    for tryRealm, realmDb in pairs(self.db.global.realms) do
        if realm == tryRealm:gsub('[- ]', ''):lower() then
            local tryChar, charDb

            for tryChar, charDb in pairs(realmDb.chars) do
                if char == tryChar:lower() then
                    return charDb, tryChar, tryRealm
                end
            end
        end
    end
end

function addon:GetFactionColor(faction)
    faction = faction and faction:upper() or self.faction

    local ids = { HORDE = 0, ALLIANCE = 1 }
    local color = PLAYER_FACTION_COLORS[ids[faction]]

    return string.format("ff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
end

function addon:OnGameTooltipCleared(tooltip)
end

function addon:OnGameTooltipSetItem(tooltip)
    local disabled = false;--_G['Altoholic'] or false

    if not disabled then
        local link = select(2, tooltip:GetItem())

        if link then
            local itemId = 0 + link:match('|Hitem:(%d+):')
            local total = 0

            tooltip:AddLine(' ')

            local char, charDb
            for char, charDb in pairs(self:GetChars()) do
                local count, desc = 0

                local source
                for source in valuesIterator({ 'equip', 'bags', 'reagents', 'bank', 'mail' }) do
                    local sourceDb = charDb.items[source]
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
