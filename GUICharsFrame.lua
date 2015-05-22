local addonName, addon = ...

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)
local LBI = LibStub('LibBabble-Inventory-3.0'):GetUnstrictLookupTable()

local DEFAULT_COLOR = { 1.0, 1.0, 1.0 }

local RACE_ICON_TCOORDS = {
    HUMAN_MALE       = { 0    , 0.125, 0, 0.25 },
    DWARF_MALE       = { 0.125, 0.25 , 0, 0.25 },
    GNOME_MALE       = { 0.25 , 0.375, 0, 0.25 },
    NIGHTELF_MALE    = { 0.375, 0.5  , 0, 0.25 },
    DRAENEI_MALE     = { 0.5  , 0.625, 0, 0.25 },
    WORGEN_MALE      = { 0.625, 0.75 , 0, 0.25 },
    PANDAREN_MALE    = { 0.75 , 0.875, 0, 0.25 },

    TAUREN_MALE      = { 0    , 0.125, 0.25, 0.5 },
    SCOURGE_MALE     = { 0.125, 0.25 , 0.25, 0.5 },
    TROLL_MALE       = { 0.25 , 0.375, 0.25, 0.5 },
    ORC_MALE         = { 0.375, 0.5  , 0.25, 0.5 },
    BLOODELF_MALE    = { 0.5  , 0.625, 0.25, 0.5 },
    GOBLIN_MALE      = { 0.625, 0.75 , 0.25, 0.5 },
    PANDAREN2_MALE   = { 0.75 , 0.875, 0.25, 0.5 },

    HUMAN_FEMALE     = { 0    , 0.125, 0.5, 0.75 },
    DWARF_FEMALE     = { 0.125, 0.25 , 0.5, 0.75 },
    GNOME_FEMALE     = { 0.25 , 0.375, 0.5, 0.75 },
    NIGHTELF_FEMALE  = { 0.375, 0.5  , 0.5, 0.75 },
    DRAENEI_FEMALE   = { 0.5  , 0.625, 0.5, 0.75 },
    WORGEN_FEMALE    = { 0.625, 0.75 , 0.5, 0.75 },
    PANDAREN_FEMALE  = { 0.75 , 0.875, 0.5, 0.75 },

    TAUREN_FEMALE    = { 0    , 0.125, 0.75, 1 },
    SCOURGE_FEMALE   = { 0.125, 0.25 , 0.75, 1 },
    TROLL_FEMALE     = { 0.25 , 0.375, 0.75, 1 },
    ORC_FEMALE       = { 0.375, 0.5  , 0.75, 1 },
    BLOODELF_FEMALE  = { 0.5  , 0.625, 0.75, 1 },
    GOBLIN_FEMALE    = { 0.625, 0.75 , 0.75, 1 },
    PANDAREN2_FEMALE = { 0.75 , 0.875, 0.75, 1 },
}

local CHAR_SCROLL_ITEM_HEIGHT = 20

local frame = AltCraftFrameCharsTabFrame

AltCraftFrame:AddTab(frame, L.tab_chars)

function frame:OnInitialize()
    self.Title:SetText(L.tab_chars_title)

    self.SelectFaction.Label:SetText(string.format('%s:', L.sel_faction))
    self.SelectRealm.Label:SetText(string.format('%s:', L.sel_realm))

    self.NameSort:SetText(L.sort_char_name)
    self.LevelSort:SetText(L.sort_char_level)
    self.ILevelSort:SetText(L.sort_char_ilevel)
    self.MoneySort:SetText(L.sort_char_money)
    self.Prof1Sort:SetText(L.sort_char_prof)
    self.Prof1LevelSort:SetText(L.sort_char_level)
    self.Prof2Sort:SetText(L.sort_char_prof)
    self.Prof2LevelSort:SetText(L.sort_char_level)

    self.CharsScroll:OnInitialize()

    self:OnSelectSort(addon.db.profile.chars_tab.sort_column, addon.db.profile.chars_tab.sort_reverse)
end

function frame:OnShow()
    local parent = self:GetParent()

    parent.TopLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\tl3')
    parent.Top:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\t3')
    parent.TopRight:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\tr3')

    parent.BottomLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\bl')

    SetPortraitTexture(parent.Portrait, 'player')

    self:Update()
end

function frame:OnSelectSort(column, reverse)
    if reverse == nil and self.sortColumn == column then
        self.sortReverse = not self.sortReverse
    else
        self.sortColumn = column
        self.sortReverse = false
    end

    addon.db.profile.chars_tab.sort_column = self.sortColumn
    addon.db.profile.chars_tab.sort_reverse = self.sortReverse

    self:Update()
end

function frame:OnSelectChar(button)
    if self.selectedChar and self.selectedChar == button.data.name then
        self.selectedChar = nil
    else
        self.selectedChar = button.data.name
    end
    self:Update()
end

function frame:OnDeleteClick()
    if addon:CanDeleteChar(self.selectedChar, self.selectedRealm) then
        addon:DeleteChar(self.selectedChar, self.selectedRealm)

        self.selectedChar = nil
        self:Update()
    end
end

function frame:Update()
    self:UpdateSelectRealm()
    self:UpdateSelectFaction()
    self:UpdateSort()
    self.CharsScroll:Update()

    if addon:CanDeleteChar(self.selectedChar, self.selectedRealm) then
        self.DeleteButton:Enable()
    else
        self.DeleteButton:Disable()
    end
end

function frame:UpdateSelectRealm()
    UIDropDownMenu_Initialize(self.SelectRealm, function()
        local info = UIDropDownMenu_CreateInfo()

        info.func = function(button)
            UIDropDownMenu_SetSelectedValue(self.SelectRealm, button.value)

            if self.selectedRealm ~= button.value then
                self.selectedChar = nil
            end

            self.selectedRealm = button.value
            self:Update()
        end

        local selectedRealm = GetRealmName()

        local realm
        for realm in valuesIterator(addon:GetRealms()) do
            info.value = realm
            info.text = string.format(
                '%s (%d)',
                realm,
                tableLength(addon:GetChars(realm, 'ALLIANCE')) + tableLength(addon:GetChars(realm, 'HORDE'))
            )

            UIDropDownMenu_AddButton(info)

            selectedRealm = realm == self.selectedRealm and realm or selectedRealm
        end

        UIDropDownMenu_SetSelectedValue(self.SelectRealm, selectedRealm)

        self.selectedRealm = selectedRealm
    end)
end

function frame:UpdateSelectFaction()
    UIDropDownMenu_Initialize(self.SelectFaction, function()
        local info = UIDropDownMenu_CreateInfo()

        info.func = function(button)
            UIDropDownMenu_SetSelectedValue(self.SelectFaction, button.value)

            if self.selectedRealm ~= button.value then
                self.selectedChar = nil
            end

            self.selectedFaction = button.value
            self:Update()
        end

        local selectedFaction = string.upper(UnitFactionGroup('player'))

        local faction
        for faction in valuesIterator({ 'ALLIANCE', 'HORDE' }) do
            info.value = faction
            info.text = string.format(
                '|c%s%s (%d)|r',
                addon:GetFactionColor(faction),
                _G['FACTION_' .. faction],
                tableLength(addon:GetChars(self.selectedRealm, faction))
            )

            UIDropDownMenu_AddButton(info)

            selectedFaction = faction == self.selectedFaction and faction or selectedFaction
        end

        UIDropDownMenu_SetSelectedValue(self.SelectFaction, selectedFaction)

        self.selectedFaction = selectedFaction
    end)
end

function frame:GetSortedChars()
    local list = {}

    local name, data
    for name, data in pairs(addon:GetChars(self.selectedRealm, self.selectedFaction)) do
        table.insert(list, { name = name, data = data })
    end

    local column = self.sortColumn or 'name'
    local reverse = self.sortReverse or false

    if column == 'name' then
        table.sort(list, function(a, b)
            if reverse then
                return a.name > b.name
            end
            return a.name < b.name
        end)
    elseif column == 'level' or column == 'ilevel' or column == 'money' then
        table.sort(list, function(a, b)
            if reverse then
                return (a.data[column] or 0) < (b.data[column] or 0)
            end
            return (a.data[column] or 0) > (b.data[column] or 0)
        end)
    elseif column == 'prof1' or column == 'prof2' then
        table.sort(list, function(a, b)
            local index = column:match('%d+') - 1

            av = a.data.profs[index] and a.data.profs[index].name or ''
            bv = b.data.profs[index] and b.data.profs[index].name or ''

            if reverse then
                return av > bv
            end
            return av < bv
        end)
    elseif column == 'prof1level' or column == 'prof2level' then
        table.sort(list, function(a, b)
            local index = column:match('%d+') - 1

            av = a.data.profs[index] and a.data.profs[index].level or 0
            bv = b.data.profs[index] and b.data.profs[index].level or 0

            if reverse then
                return av < bv
            end
            return av > bv
        end)
    else
        table.sort(list, function(a, b)
            if reverse then
                return (a.data[column] or '') > (b.data[column] or '')
            end
            return (a.data[column] or '') < (b.data[column] or '')
        end)
    end

    return list
end

function frame:UpdateSort()
    local column
    for column in valuesIterator({ 'Name', 'Level', 'ILevel', 'Money', 'Prof1', 'Prof1Level', 'Prof2', 'Prof2Level' }) do
        local button = self[column .. 'Sort']

        if self.sortColumn == column:lower() then
            _G[button:GetName() .. 'Arrow']:Show()

            if self.sortReverse then
                _G[button:GetName() .. 'Arrow']:SetTexCoord(0, 0.5625, 1, 0)
            else
                _G[button:GetName() .. 'Arrow']:SetTexCoord(0, 0.5625, 0, 1)
            end
        else
            _G[button:GetName() .. 'Arrow']:Hide()
        end
    end
end

function frame.CharsScroll:OnInitialize()
    self.scrollBar.doNotHide = 1

    HybridScrollFrame_OnLoad(self)
    self.update = function() self:Update() end

    HybridScrollFrame_CreateButtons(self, 'AltCraftCharsButtonTemplate', 0, 0)
    self:Update()
end

function frame.CharsScroll:Update()
    local chars = self:GetParent():GetSortedChars()
    local numRows = #chars

    HybridScrollFrame_Update(self, numRows * CHAR_SCROLL_ITEM_HEIGHT, self:GetHeight())

    local scrollOffset = HybridScrollFrame_GetOffset(self)

    local i
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        local char = chars[i + scrollOffset]

        if scrollOffset + i <= numRows then
            button.data = char

            button:Show()

            button.ClassIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[char.data.class]))
            button.RaceIcon:SetTexCoord(unpack(RACE_ICON_TCOORDS[char.data.race .. (char.data.race == 'PANDAREN' and char.data.faction == 'HORDE' and '2' or '') .. '_' .. char.data.gender]))

            button.Name:SetText(char.name)
            button.Name:SetTextColor(RAID_CLASS_COLORS[char.data.class].r,
                RAID_CLASS_COLORS[char.data.class].g, RAID_CLASS_COLORS[char.data.class].b)

            local color = addon:GetLevelColor(char.data.level)

            button.Level:SetText(char.data.level)
            button.Level:SetTextColor(unpack(color or DEFAULT_COLOR))

            color = addon:GetILevelColor(char.data.level, char.data.ilevel)

            button.ILevel:SetText(math.floor(char.data.ilevel))
            button.ILevel:SetTextColor(unpack(color or DEFAULT_COLOR))

            button.Money:SetText(GetCoinTextureString(char.data.money, 10))

            local profIndex
            for profIndex = 1, 2 do
                if char.data.profs[profIndex - 1] then
                    color = addon:GetProfColor(char.data.level, char.data.profs[profIndex - 1].name, char.data.profs[profIndex - 1].level)

                    button['Prof' .. profIndex]:SetText(LBI[char.data.profs[profIndex - 1].name])
                    button['Prof' .. profIndex .. 'Level']:SetText(char.data.profs[profIndex - 1].level)

                    button['Prof' .. profIndex]:SetTextColor(unpack(color or DEFAULT_COLOR))
                    button['Prof' .. profIndex .. 'Level']:SetTextColor(unpack(color or DEFAULT_COLOR))
                else
                    button['Prof' .. profIndex]:SetText('')
                    button['Prof' .. profIndex .. 'Level']:SetText('')
                end
            end

            if self:GetParent().selectedChar == char.name then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
        else
            button:Hide()
        end
    end
end
