local addonName, addon = ...

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

local CHAR_SCROLL_ITEM_HEIGHT = 20

local frame = AltCraftFrameCharsTabFrame

table.insert(ALTCRAFT_TABS, { frame = frame, label = L.tab_chars })

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
    self.selectedChar = button.data.name
    self:Update()
end

function frame:Update()
    self:UpdateSelectRealm()
    self:UpdateSelectFaction()
    self:UpdateSort()
    self.CharsScroll:Update()
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

        local selectedRealm = self.selectedRealm or addon.realm

        local realm
        for realm in valuesIterator(addon:GetRealms()) do
            info.value = realm
            info.text = string.format(
                '%s (%d)',
                realm,
                tableLength(addon:GetChars(realm, 'alliance')) + tableLength(addon:GetChars(realm, 'horde'))
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

        local selectedFaction = self.selectedFaction or addon.faction

        local faction
        for faction in valuesIterator({ 'alliance', 'horde' }) do
            info.value = faction
            info.text = string.format(
                '|c%s%s (%d)|r',
                addon:GetFactionColor(faction),
                _G['FACTION_' .. faction:upper()],
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
                _G[button:GetName() .. 'Arrow']:SetTexCoord(0, 0.5625, 1, 0);
            else
                _G[button:GetName() .. 'Arrow']:SetTexCoord(0, 0.5625, 0, 1);
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

            button.ClassIcon:SetTexture('Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes')
            button.ClassIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[char.data.class]))

            button.Name:SetText(char.name)
            button.Name:SetTextColor(RAID_CLASS_COLORS[char.data.class].r,
                RAID_CLASS_COLORS[char.data.class].g, RAID_CLASS_COLORS[char.data.class].b)

            button.Level:SetText(char.data.level)
            button.ILevel:SetText(math.floor(char.data.ilevel))

            button.Money:SetText(GetCoinTextureString(char.data.money, 10))

            local profIndex
            for profIndex = 1, 2 do
                if char.data.profs[profIndex - 1] then
                    button['Prof' .. profIndex]:SetText(char.data.profs[profIndex - 1].name)
                    button['Prof' .. profIndex .. 'Level']:SetText(char.data.profs[profIndex - 1].level)
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
