local addon, NiftyPlates = ...

local font, fontSize, fontOutline = [[Interface\Addons\kNamePlates\media\Calibri1.ttf]], 9, "OUTLINE"
local barTexture = kNPCustom_barTexture or [[Interface\Addons\kNamePlates\media\Smoothv2]]
local glowTexture = kNPCustom_glowTexture or [[Interface\Addons\kNamePlates\media\Outline]]
local aggroColors = {
  --[0]		= { 1.00, 0.00, 0.00 },	-- "gray" equivalent (translate gray glow to red, the default hostile nameplate color; low aggro)
	[1]		= { 0.00, 1.00, 1.00 },	-- "yellow" equivalent (tranlate glow to a bright cyan; you are at risk of pulling/losing aggro)
	[2]		= { 1.00, 0.00, 1.00 },	-- "orange" equivalent (tranlate glow to a bright magenta; you are really close to pulling/losing aggro)
	[3]		= { 1.00, 0.67, 0.00 },	-- "red" equivalent (tranlate glow to a bright orange; this target is securely yours)
}

--[[ Utility functions ]]--
do
	local f = CreateFrame("Frame")
	
	function NiftyPlates:SetScript(...)
		return f:SetScript(...)
	end
end


local getUnitThreatValue = function (region)
	if not region:IsShown() then
		return 0
	end

	local r, g, b = region:GetVertexColor()
	if r > 0 then
		if g > 0 then
			if b > 0 then 
				return 1 
			end
			
			return 2
		end
		
		return 3
	end
end

local updateThreat = function (frame)
	local threatValue = getUnitThreatValue(frame.oldglow)

	if threatValue == 0 then
		return frame.glow:Hide()
	end
	
	frame.glow:SetVertexColor( unpack(aggroColors[threatValue]) )
	frame.glow:Show()
end

local updateNamePlates = function (frame)
	frame = frame:GetParent()
	
	frame.name:SetText( frame.oldname:GetText() )
	
	frame.highlight:ClearAllPoints()
	frame.highlight:SetAllPoints(frame.hb)
end

local styleNamePlate = function (frame) 
	local hb, cb = frame:GetChildren()
	local nativeGlowRegion, overlayRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()
	local castBarRegion, castBarOverlayRegion, castBarShieldRegion, spellIconRegion = cb:GetRegions()
	
	frame.isStyled = true
	frame.hb = hb
	frame.cb = cb
	
	hb:HookScript("OnShow", updateNamePlates)
	
--	nameTextRegion:Hide()

	local name = hb:CreateFontString()
	name:SetPoint("LEFT", hb, "LEFT", 0, 1)
	name:SetJustifyH("LEFT") 
	name:SetJustifyV("MIDDLE") 
	name:SetWidth(120 * .9)
	name:SetHeight(11)
	name:SetFont(font, fontSize, fontOutline)
	name:SetTextColor(1, 1, 1)
	name:SetShadowOffset(0, 0)
	frame.oldname = nameTextRegion
	frame.name = name
	
	-- @Todo: Health update function
	local health = hb:CreateFontString()
	health:SetPoint("LEFT", hb, "LEFT", 0, 1)
	health:SetFont(font, fontSize, fontOutline)
	health:SetShadowOffset(0, 0)
	health:SetJustifyV("MIDDLE") 
	health:SetHeight(11)
	frame.health = health
	
	frame.oldname:Hide()
	
	local glow = hb:CreateTexture(nil, "BORDER")
	glow:SetPoint("TOPLEFT", hb, "TOPLEFT", -2, 2)
	glow:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", 2, -2)
	glow:SetTexture(glowTexture)
	glow:SetVertexColor(0, 0, 0)
	glow:SetAlpha(1)
	glow:Hide()
	frame.glow = glow
	frame.oldglow = nativeGlowRegion
	
	local bg = hb:CreateTexture(nil, "BORDER")
	bg:SetAllPoints(hb)
	bg:SetTexture(barTexture)
	bg:SetAlpha(0.5)
	bg:SetVertexColor(0.15, 0.15, 0.15)
	frame.bg = bg
	
	
	highlightRegion:SetTexture(barTexture)
	highlightRegion:SetVertexColor(0.25, 0.25, 0.25)
	frame.highlight = highlightRegion	
	
	
	nativeGlowRegion:SetTexture(nil)
	overlayRegion:SetTexture(nil)
	castBarShieldRegion:SetTexture(nil)
	castBarOverlayRegion:SetTexture(nil)
	stateIconRegion:SetTexture(nil)
	bossIconRegion:SetTexture(nil)
	
	updateNamePlates(hb)
end

local isNamePlate = function (frame)
	local o = select(2, frame:GetRegions())
	
	frame.region = o
	if not o or o:GetObjectType() ~= "Texture" or o:GetTexture() ~= "Interface\\Tooltips\\Nameplate-Border" then
		return false 
    end
	
    return true
end

local findNamePlates
do
	local lastUpdate = 0
	
	findNamePlates = function (self, elapsed)
		lastUpdate = lastUpdate + elapsed
		
		if lastUpdate > 0.33 then
			lastUpdate = 0
			
			local num = select("#", WorldFrame:GetChildren())
			for i = 1, num do
				local frame = select(i, WorldFrame:GetChildren())
				
				if isNamePlate(frame) then
					if not frame.isStyled then
						styleNamePlate(frame)
					end
					
					updateThreat(frame)
				end
			end			
		end
	end
end

NiftyPlates:SetScript("OnUpdate", findNamePlates)