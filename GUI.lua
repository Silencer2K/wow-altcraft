local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local FRAME_TABS = 2
local CHAR_SCROLL_ITEM_HEIGHT = 20

local frame = AltCraftFrame

local charsFrame = frame.Tab1Frame
local charsPane = charsFrame.CharsPane

local reagentsFrame = frame.Tab2Frame

function frame:OnInitialize()
    tinsert(UISpecialFrames, self:GetName())

    -- Chars Tab
    self.Tab1:SetText(L.tab_chars)
    charsFrame:OnInitialize()

    -- Reagents Tab
    self.Tab2:SetText(L.tab_reagents)
    reagentsFrame:OnInitialize()

    PanelTemplates_SetNumTabs(self, FRAME_TABS)
    self:OnSelectTab(1)
end

function frame:OnSelectTab(index)
    PanelTemplates_SetTab(self, index)

    if index == 1 then
        self.TopLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\tl3')
        self.Top:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\t3')
        self.TopRight:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\tr3')

        self.BottomLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\bl')

        SetPortraitTexture(self.Portrait, 'player')
    else
        self.TopLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\tl2')
        self.Top:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\t')
        self.TopRight:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\tr')

        self.BottomLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\bl2')

        self.Portrait:SetTexture('Interface\\MailFrame\\Mail-Icon')
    end

    local i
    for i = 1, FRAME_TABS do
        if index == i then
            self['Tab' .. i .. 'Frame']:Show()
            self['Tab' .. i .. 'Frame']:Update()
        else
            self['Tab' .. i .. 'Frame']:Hide()
        end
    end
end

function charsFrame:OnInitialize()
    self.Title:SetText(L.tab_chars_title)

    self.NameSort:SetText(L.sort_char_name)
    self.LevelSort:SetText(L.sort_char_level)
    self.ILevelSort:SetText(L.sort_char_ilevel)
    self.MoneySort:SetText(L.sort_char_money)
    self.Prof1Sort:SetText(L.sort_char_prof)
    self.Prof2Sort:SetText(L.sort_char_prof)

    self.CharsPane:OnInitialize()
end

function charsFrame:Update()
    self.CharsPane:Update()
end

function charsFrame:GetSortedChars()
    local list = {}

    local name, data
    for name, data in pairs(addon:GetChars()) do
        tinsert(list, { name = name, data = data })
    end

    return list
end

function charsPane:OnInitialize()
    self.scrollBar.doNotHide = 1

    HybridScrollFrame_OnLoad(self)
    self.update = function() self:Update() end

    HybridScrollFrame_CreateButtons(self, "AltCraftCharsButtonTemplate", 0, 0)
    self:Update()
end

function charsPane:Update()
    local chars = self:GetParent():GetSortedChars()
    local numRows = #chars

    HybridScrollFrame_Update(self, numRows * CHAR_SCROLL_ITEM_HEIGHT, self:GetHeight())

    local scrollOffset = HybridScrollFrame_GetOffset(self)

    local i
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        local char = chars[i + scrollOffset]

        if scrollOffset + i <= numRows then
            button:Show()

            button.ClassIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            button.ClassIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[char.data.class]))

            button.Name:SetText(char.name)
            button.Name:SetTextColor(RAID_CLASS_COLORS[char.data.class].r,
                RAID_CLASS_COLORS[char.data.class].g, RAID_CLASS_COLORS[char.data.class].b)

            button.Level:SetText(char.data.level)
            button.ILevel:SetText(math.floor(char.data.ilevel or 0))

            button.Money:SetText(GetCoinTextureString(char.data.money, 10))
        else
            button:Hide()
        end
    end
end

function reagentsFrame:OnInitialize()
    self.Title:SetText(L.tab_reagents_title)
end

function reagentsFrame:Update()
end
