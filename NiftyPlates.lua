local addon, NiftyPlates = ...

local font, fontSize, fontOutline = [=[Interface\Addons\NiftyPlates\media\Calibri1.ttf]=], 9, "OUTLINE"
local barTexture = [=[Interface\Addons\NiftyPlates\media\Smoothv2]=]
local glowTexture = [=[Interface\Addons\NiftyPlates\media\Outline]=]
local aggroColors = {
  --[0]		= { 1.00, 0.00, 0.00 },	-- "gray" equivalent (translate gray glow to red, the default hostile nameplate color; low aggro)
	[1]		= { 0.00, 1.00, 1.00 },	-- "yellow" equivalent (tranlate glow to a bright cyan; you are at risk of pulling/losing aggro)
	[2]		= { 1.00, 0.00, 1.00 },	-- "orange" equivalent (tranlate glow to a bright magenta; you are really close to pulling/losing aggro)
	[3]		= { 1.00, 0.67, 0.00 },	-- "red" equivalent (tranlate glow to a bright orange; this target is securely yours)
}

local namePlates = {}

--[[ Utility functions ]]--
do
	local f = CreateFrame("Frame")
	
	function NiftyPlates:SetScript(...)
		return f:SetScript(...)
	end
end

local shortenValue = function (val)
	if val < 1000 then
		return num
	elseif val > 1000000 then
		return string.format("%.1fm", val / 1000000)
	else
		return string.format("%.1fk", val / 1000)
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

local updateHealth = function (frame, value)
	frame:GetParent().health:SetText( shortenValue(value) )
end

local updateNamePlates = function (frame)
	frame = frame:GetParent()
	
	frame.name:SetText( frame.oldname:GetText() )
	
	frame.highlight:ClearAllPoints()
	frame.highlight:SetAllPoints(frame.hb)
	
	frame.level:Hide()
	frame.oldname:Hide()
end

local styleNamePlate = function (frame) 
	local hb, cb = frame:GetChildren()
	local nativeGlowRegion, overlayRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()
	local castBarRegion, castBarOverlayRegion, castBarShieldRegion, spellIconRegion = cb:GetRegions()
	
	namePlates[ frame ] = true
	frame.isStyled = true
	frame.hb = hb
	frame.cb = cb
	frame.level = levelTextRegion
		
	local name = hb:CreateFontString()
	name:SetPoint("LEFT", hb, "LEFT", 1, 0)
	name:SetJustifyH("LEFT") 
	name:SetJustifyV("MIDDLE") 
	name:SetWidth(120 * .9)
	name:SetFont(font, fontSize, fontOutline)
	name:SetTextColor(1, 1, 1)
	name:SetShadowOffset(0, 0)
	frame.oldname = nameTextRegion
	frame.name = name
	
	local health = hb:CreateFontString()
	health:SetPoint("RIGHT", hb, "RIGHT", 1, 0)
	health:SetFont(font, fontSize, fontOutline)
	health:SetShadowOffset(0, 0)
	health:SetJustifyV("MIDDLE") 
	health:SetJustifyH("RIGHT")
	frame.health = health
	
	local glow = hb:CreateTexture(nil, "BORDER")
	glow:SetPoint("TOPLEFT", hb, "TOPLEFT", -1.5, 1.5)
	glow:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", 1.5, -1.5)
	glow:SetTexture(glowTexture)
	glow:SetVertexColor(0, 0, 0)
	glow:SetAlpha(.75)
	glow:SetBlendMode("ADD")
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
	
	hb:HookScript("OnShow", updateNamePlates)
	hb:SetScript("OnValueChanged", updateHealth)
	
	updateHealth(hb, hb:GetValue())
	updateNamePlates(hb)
end

local isNamePlate = function (frame)
	local o = select(2, frame:GetRegions())

	if not o or o:GetObjectType() ~= "Texture" or o:GetTexture() ~= "Interface\\Tooltips\\Nameplate-Border" then
		return false 
    end
	
    return true
end

local findNamePlates, hookFrames
do
	local lastUpdate = 0
	local numChildren = -1
	
	hookFrames = function (frames)
		for i = 1, numChildren do
			local frame = select(i, WorldFrame:GetChildren())
			
			if isNamePlate(frame) and not frame.isStyled then
				styleNamePlate(frame)
			end
		end	
	end
	
	findNamePlates = function (self, elapsed)
		lastUpdate = lastUpdate + elapsed
		
		if lastUpdate > 0.33 then
			lastUpdate = 0
			
			if numChildren ~= WorldFrame:GetNumChildren() then
				numChildren = WorldFrame:GetNumChildren()
				hookFrames( WorldFrame:GetChildren() )
			end
			
			for frame in pairs(namePlates) do
				updateThreat(frame)
			end
		end
	end
end

NiftyPlates:SetScript("OnUpdate", findNamePlates)