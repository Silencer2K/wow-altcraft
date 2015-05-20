local addonName, addon = ...

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

ALTCRAFT_TABS = {}

local frame = AltCraftFrame

function frame:OnInitialize()
    table.insert(UISpecialFrames, self:GetName())

    local i
    for i = 1, #ALTCRAFT_TABS do
        local button = CreateFrame('Button', self:GetName() .. 'Tab' .. i, self, 'CharacterFrameTabButtonTemplate')

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

    PanelTemplates_SetNumTabs(self, #ALTCRAFT_TABS)
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
