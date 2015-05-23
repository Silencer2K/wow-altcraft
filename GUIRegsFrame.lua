local addonName, addon = ...

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

local frame = AltCraftFrameReagentsTabFrame

AltCraftFrame:AddTab(frame, L.tab_reagents)

function frame:OnInitialize()
    self.Title:SetText(L.tab_reagents_title)
end

function frame:OnShow()
    local parent = self:GetParent()

    parent.TopLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\tl2')
    parent.Top:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\t')
    parent.TopRight:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\tr')

    parent.BottomLeft:SetTexture('Interface\\Addons\\AltCraft\\assets\\frame\\bl2')

    parent.Portrait:SetTexture('Interface\\ICONS\\INV_Gizmo_KhoriumPowerCore')

    self:Update()
end

function frame:Update()
end
