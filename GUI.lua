local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local FRAME_TABS = 2

local frame = AltCraftFrame

function frame:OnInitialize()
    tinsert(UISpecialFrames, self:GetName())

    self.Tab1:SetText(L.tab_chars)
    self.Tab1Frame.Title:SetText(L.tab_chars_title)

    self.Tab1Frame.CharNameSort:SetText(L.sort_char_name)
    self.Tab1Frame.CharLevelSort:SetText(L.sort_char_level)
    self.Tab1Frame.CharILevelSort:SetText(L.sort_char_ilevel)
    self.Tab1Frame.CharMoneySort:SetText(L.sort_char_money)
    self.Tab1Frame.CharProf1Sort:SetText(L.sort_char_prof)
    self.Tab1Frame.CharProf2Sort:SetText(L.sort_char_prof)

    self.Tab2:SetText(L.tab_reagents)
    self.Tab2Frame.Title:SetText(L.tab_reagents_title)

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
        else
            self['Tab' .. i .. 'Frame']:Hide()
        end
    end
end
