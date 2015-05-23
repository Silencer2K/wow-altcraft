local addonName, addon = ...

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

ALTCRAFT_TABS = {}

local frame = AltCraftFrame

function frame:AddTab(tabFrame, label)
    table.insert(ALTCRAFT_TABS, { frame = tabFrame, label = label })

    tabFrame:SetParent(self)

    tabFrame:ClearAllPoints()
    tabFrame:SetPoint('TOPLEFT')

    if _G[self:GetName() .. 'Tab1'] then
        self:UpdateTabs()
    end

    return #ALTCRAFT_TABS
end

function frame:OnInitialize()
    table.insert(UISpecialFrames, self:GetName())

    self.Portrait:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")

    self:UpdateTabs()
    self:OnSelectTab(1)
end

function frame:OnSelectTab(index)
    PanelTemplates_SetTab(self, index)

    local i
    for i = 1, #ALTCRAFT_TABS do
        if index == i then
            ALTCRAFT_TABS[i].frame:Show()
        else
            ALTCRAFT_TABS[i].frame:Hide()
        end
    end
end

function frame:OnShow()
end

function frame:UpdateTabs()
    local i
    for i = 1, #ALTCRAFT_TABS do
        local button = _G[self:GetName() .. 'Tab' .. i]
        if not button then
            button = CreateFrame('Button', self:GetName() .. 'Tab' .. i, self, 'CharacterFrameTabButtonTemplate')

            if i == 1 then
                button:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 27, 13)
            else
                button:SetPoint('TOPLEFT', _G[self:GetName() .. 'Tab' .. (i - 1)], 'TOPRIGHT', -15, 0)
            end

            button:SetID(i)
            button:SetText(ALTCRAFT_TABS[i].label)

            button:SetScript('OnClick', function()
                self:OnSelectTab(i)
            end)

            ALTCRAFT_TABS[i].frame:OnInitialize()
        end
    end

    PanelTemplates_SetNumTabs(self, #ALTCRAFT_TABS)
end
