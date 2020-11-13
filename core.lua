local L = LibStub("AceLocale-3.0"):GetLocale("AutoMacro")

local frames = {}
local pressed = false
local addonname = "|c002FC5D0AutoMacro: |r"

local function MakeMovable(frame)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

-- Config frame
local config = {}
config.main = CreateFrame("Frame", "AutoMacroConfigFrame", UIPanel)
config.main:SetFrameStrata("DIALOG")
config.main:SetSize(300,250)
config.main:SetPoint("CENTER")
config.main.texture = config.main:CreateTexture(nil, "BACKGROUND")
config.main.texture:SetAllPoints(config.main)
config.main.texture:SetColorTexture(0,0,0,0.5)
MakeMovable(config.main)
tinsert(UISpecialFrames, config.main:GetName())
config.main:Hide()

config.title = config.main:CreateFontString("AutoMacroConfigTitle", "OVERLAY", "GameFontNormal")
config.title:SetPoint("TOP")
config.title:SetText(L["AutoMacro configuration"])

config.desc = config.main:CreateFontString("AutoMacroConfigDesc", "OVERLAY", "GameFontWhiteSmall")
config.desc:SetPoint("TOPLEFT", config.main, "TOPLEFT", 10, -20)
config.desc:SetWidth(config.main:GetWidth() - 20)
config.desc:SetJustifyH("LEFT")
config.desc:SetText(format(L["Type below the macro you want to create with AutoMacro. Use %s where the name of the spell clicked should be replaced."],"|c00FFFF00<spell>|r"))

config.mreplace = CreateFrame("CheckButton", "AutoMacroOverwriteMacro", config.main, "UICheckButtonTemplate")
config.mreplace.text = _G[config.mreplace:GetName() .. "Text"]
config.mreplace:SetPoint("TOPLEFT", config.desc, "BOTTOMLEFT", -5, -5)
config.mreplace:SetSize(20,20)
config.mreplace.text:SetText(L["Overwrite existing macro"])
config.mreplace.text:SetFontObject(GameFontNormalSmall)
config.mreplace.tooltip = L["Replace the existing macro with the one you just created."]
config.mreplace:SetScript("OnClick", function(self)
	AutoMacroDB.mreplace = self:GetChecked()
end)

config.general = CreateFrame("CheckButton", "AutoMacroGeneral", config.main, "UICheckButtonTemplate")
config.general.text = _G[config.general:GetName() .. "Text"]
config.general:SetPoint("TOPLEFT", config.mreplace, "BOTTOMLEFT")
config.general:SetSize(20,20)
config.general.text:SetText(L["Save macro in the General tab"])
config.general.text:SetFontObject(GameFontNormalSmall)
config.general.tooltip = L["Save the macro in the General tab, making it available to other characters."]
config.general:SetScript("OnClick", function(self)
	AutoMacroDB.general = self:GetChecked()
end)

config.box = CreateFrame("ScrollFrame", "AutoMacroConfigEditBox", config.main, "InputScrollFrameTemplate")
config.box:SetPoint("TOPLEFT", config.general, "BOTTOMLEFT", 5, -5)
config.box:SetSize(config.main:GetWidth() - 20, config.main:GetHeight() - 140)
config.box.EditBox:SetMaxLetters(255)
config.box.EditBox:SetSize(config.box:GetSize())
config.box.EditBox:SetAllPoints()
config.box.EditBox:SetScript("OnTextChanged", function(self)
	AutoMacroDB.macro = self:GetText()
end)

config.exit = CreateFrame("Button", "AutoMacroConfigClose", config.main, "UIPanelCloseButton")
config.exit:SetPoint("TOPRIGHT")
config.exit:SetSize(20,20)

config.ok = CreateFrame("Button", "AutoMacroConfigOkay", config.main, "UIPanelButtonTemplate")
config.ok:SetSize(100,20)
config.ok:SetPoint("BOTTOM", config.main, "BOTTOM", 0, 10)
config.ok:SetText(_G["OKAY"])  
config.ok:SetScript("OnClick", function()
	local text = config.box.EditBox:GetText()
	local checkdata = strfind(text, "<spell>")
	if (checkdata ~= nil) then
		config.main:Hide() 
	else
		StaticPopupDialogs["AUTOMACRO_ERROR"] = {
		text = format(L["The %s tag is missing or incorrectly typed."],"|c00FFFF00<spell>|r"),
		button1 = _G["OKAY"],
		whileDead = true,
		hideOnEscape = true,
		showAlert = true,}
		StaticPopup_Show("AUTOMACRO_ERROR")
	end
end)

-- Load the saved variables.
config.main:RegisterEvent("ADDON_LOADED")
config.main:SetScript("OnEvent", function(self, event, ...)
	if (event == "ADDON_LOADED") and (... == "AutoMacro") then
		-- Defaults
			AutoMacroDB = AutoMacroDB or {}
			AutoMacroDB.default = {}
			AutoMacroDB.default.macro = [[#showtooltip
/use [@mouseover,exists][] <spell>]]
			AutoMacroDB.default.mreplace = false
			AutoMacroDB.default.general = false
		-- End defaults
		AutoMacroDB.macro = AutoMacroDB.macro or AutoMacroDB.default.macro
		AutoMacroDB.mreplace = AutoMacroDB.mreplace or AutoMacroDB.default.mreplace
		AutoMacroDB.general = AutoMacroDB.general or AutoMacroDB.default.general
		config.box.EditBox:SetText(AutoMacroDB.macro)
		config.mreplace:SetChecked(AutoMacroDB.mreplace)
		config.general:SetChecked(AutoMacroDB.general)
	end
end)

-- Frames over the spells.
for i = 1, 12 do
	local spell = _G["SpellButton" .. i]
	frames[i] = CreateFrame("Frame", "AutoMacroFrame" .. i, SpellBookFrame)
	frames[i]:SetFrameStrata("HIGH")
	frames[i]:SetSize(spell:GetSize())
	frames[i]:SetAllPoints(spell)
	frames[i]:Hide()
	frames[i]:SetScript("OnMouseDown", function()
		if (not InCombatLockdown()) then
			local slot = SpellBook_GetSpellBookSlot(spell)
			local _, id = GetSpellBookItemInfo(slot, "spell")
			local sname, _, icon = GetSpellInfo(id)
			local macro = gsub(AutoMacroDB.macro, "<spell>", sname)
			local name = strsub(sname, 1, 11) .. " [AM]"
			local exists = GetMacroIndexByName(name)
			local index = nil
			if (exists ~= 0) and (config.mreplace:GetChecked() == false) then
				print(addonname .. string.format(L["There is already a macro named %s."], name))
			else
				local saveWhere = nil
				if (not config.general:GetChecked()) then
					saveWhere = 1
				end
				DeleteMacro(name)
				index = CreateMacro(name, icon, macro, saveWhere, 1)
			end
			if (index) then 
				print(addonname .. L["Macro created successfully!"])
				if (_G["MacroFrame"] ~= nil) and (MacroFrame:IsShown()) then
					MacroFrame:Hide()
					MacroFrame:Show()
				end
				PickupMacro(index)
			end
		else
			print(addonname .. L["Cannot create macros while in combat."])
		end
	end)
	-- The frames should not be displayed if it's an empty slot.
	frames[i]:SetScript("OnShow", function()
		local slot = SpellBook_GetSpellBookSlot(spell)
		if not slot then
			frames[i]:Hide()
		else
			local _, id = GetSpellBookItemInfo(slot, "spell")
			-- Hide frame if spell is passive or unknown. 
			if not IsSpellKnown(id) or IsPassiveSpell(id) then
				frames[i]:Hide()
			else
				-- Tooltips on the frames.
				frames[i]:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetSpellByID(id)
					GameTooltip:Show()
				end)
				frames[i]:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)
			end
		end
	end)
end

-- Forces a refresh to check whether it's an empty slot or not. If it is, hide the frame.
local function ReopenFrames()
	for i = 1, 12 do
		if (pressed) then
			frames[i]:Hide()
			frames[i]:Show()
		end
	end
end
SpellBookPrevPageButton:HookScript("OnClick", ReopenFrames)
SpellBookNextPageButton:HookScript("OnClick", ReopenFrames)
-- If you change tabs, refresh.
SpellBookSkillLineTab1:HookScript("OnClick", ReopenFrames)
SpellBookSkillLineTab2:HookScript("OnClick", ReopenFrames)
SpellBookSkillLineTab3:HookScript("OnClick", ReopenFrames)
SpellBookSkillLineTab4:HookScript("OnClick", ReopenFrames)
SpellBookSkillLineTab5:HookScript("OnClick", ReopenFrames)
SpellBookSkillLineTab6:HookScript("OnClick", ReopenFrames)


-- ON/OFF Button
local button = CreateFrame("Button", "AutoMacroButton", SpellBookFrame, "UIPanelButtonTemplate")
button:RegisterForClicks("AnyUp")
button:SetText("AutoMacro")
button:SetSize(120,18)
button:SetPoint("TOPRIGHT", SpellBookFrameCloseButton, "TOPLEFT", 4 , -6)
button:SetScript("OnClick", function(self, but)
	if (but == "LeftButton") then
		if (not pressed) then
			pressed = true
			button:LockHighlight()
			button:SetText("AutoMacro ON")
			for i = 1, 12 do 
				frames[i]:Show()
				ActionButton_ShowOverlayGlow(frames[i])
			end
			else
			pressed = false
			button:UnlockHighlight()
			button:SetText("AutoMacro")
			for i = 1, 12 do
				ActionButton_HideOverlayGlow(frames[i])
				frames[i]:Hide() 
			end
		end
	elseif (but == "RightButton") then
		config.main:Show()
	end
end)
button:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:SetText(L["Right click for options"], _, _, _, _, true)
	GameTooltip:Show()
end)
button:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)

-- Prevents stuff being displayed on the professions frame.
SpellBookProfessionFrame:HookScript("OnShow", function()
	button:Hide()
	for i = 1, 12 do
		frames[i]:SetFrameStrata("BACKGROUND")
	end
end)
SpellBookProfessionFrame:HookScript("OnHide", function()
	button:Show()
	for i = 1, 12 do
		frames[i]:SetFrameStrata("HIGH")
	end
end)