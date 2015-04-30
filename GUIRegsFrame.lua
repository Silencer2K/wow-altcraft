local addonName, addon = ...

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

local frame = AltCraftFrameTab2Frame

function frame:OnInitialize()
    self.Title:SetText(L.tab_reagents_title)
end

function frame:Update()
end
