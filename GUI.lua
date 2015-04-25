local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local frame = AltCraftFrame

function frame:OnInitialize()
    self.TabChars:SetText(L.tab_chars)
    self.TabReagents:SetText(L.tab_reagents)
end
