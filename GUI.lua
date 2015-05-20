local addonName, addon = ...

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

local FRAME_TABS = 2

local frame = AltCraftFrame

function frame:OnInitialize()
    tinsert(UISpecialFrames, self:GetName())

    -- Chars Tab
    self.Tab1:SetText(L.tab_chars)
    self.Tab1Frame:OnInitialize()

    -- Reagents Tab
    self.Tab2:SetText(L.tab_reagents)
    self.Tab2Frame:OnInitialize()

    PanelTemplates_SetNumTabs(self, FRAME_TABS)
    self:OnSelectTab(1)
end

function frame:OnSelectTab(index)
    PanelTemplates_SetTab(self, index)

    local i
    for i = 1, FRAME_TABS do
        if index == i then
            self['Tab' .. i .. 'Frame']:Show()
        else
            self['Tab' .. i .. 'Frame']:Hide()
        end
    end
end
