local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local frame = AltCraftFrame

function frame:OnInitialize()
    tinsert(UISpecialFrames, self:GetName())

    self.TabChars:SetText(L.tab_chars)
    self.TabReagents:SetText(L.tab_reagents)

    PanelTemplates_SetNumTabs(self, 2)

    self:OnSelectTab(1)
end

function frame:OnSelectTab(index)
    PanelTemplates_SetTab(self, index)

    if index == 2 then
        self.Portrait:SetTexture('Interface\\MailFrame\\Mail-Icon')
    else
        SetPortraitTexture(self.Portrait, 'player')
    end

    if index == 2 then
        self.TopLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\tl2')
        self.BottomLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\bl2')
    else
        self.TopLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\tl')
        self.BottomLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\bl')
    end
end
