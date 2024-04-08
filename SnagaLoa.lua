--[[

verify if buttons are doing something
	give feedback on actions being performed on both ends
	
check if someone is the master before becoming the master
	if someone else is master, feedback message that x person is the master
create commande master -force
	if you are L or A and person with master isn't L or A, then revoke his master, force your master on

create a check for if people have the addon or not
create a check for if people are heal spec or not


if press X in master edit mode, the names stay there
	it should turn the addon off, maybe add a popup? Do you wanna turn off the addon...
]]--ToDo

--MFX is the master edit frame

local SnagaLoa_Names = {}
local SnagaLoa_NamesSave = {}
local SnagaLoa_RaidIds = {}
local SnagaLoa_TempList = {}

local windowheight = nil
local runningtime = 0
local counter = 0
local generated = nil
local frameIsShown = nil
local isMaster = nil
local currentmaster = ""
local firstGen = true

function SnagaLoa_OnLoad()
   this:RegisterEvent("VARIABLES_LOADED")
   this:RegisterEvent("CHAT_MSG_ADDON")
end

function SnagaLoa_OnEvent()
	if event == "VARIABLES_LOADED" then
		if frameIsShown then
			SnagaLoaFrame:Show()
		elseif not frameIsShown then
			SnagaLoaFrame:Hide()
		end
		
		SLASH_SnagaLoa1 = "/loatheb"
		SlashCmdList["SnagaLoa"] = SnagaLoa_SlashHandler
		DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f[SnagaLoatheb]|r Loatheb-Addon Loaded. Type '/loatheb' for more info.")
		
		current1:SetText("List by:")
		current1:SetTextColor(0.93,0.77,0,1)
		current1:Show()
		current2:SetText("")
		current2:SetTextColor(0.93,0.77,0,1)
		current2:Show()
		pending1:SetText("list pending..")
		pending1:Hide()
		SnagaLoa_HideMasterFrames()
		
		if isMaster then
			SendAddonMessage("loamnew", UnitName("Player"), "Raid")
			currentmaster = UnitName("Player")
			Edit:Show()
			Broadcast:Show()
			Reload:Hide()
			current2:SetText(currentmaster)
			current2:SetTextColor(SnagaLoa_SetMasterColorM())
			firstGen = nil
			SnagaLoa_EditStart()
			generated = nil
		else 
			isMaster = nil
			SnagaLoa_ClearAllLists()
			SnagaLoa_Names = {}
			SnagaLoa_RaidIds = {}
			SnagaLoa_Request()
		end
	
	
	elseif event == "CHAT_MSG_ADDON" then
		local a1 = arg1
		local a2 = arg2
		local a3 = arg3
		local a4 = arg4
		if a1 == "loamnew" then
			if a4 ~= UnitName("Player") then
				currentmaster = a4
				current2:SetText(currentmaster)
				current2:SetTextColor(SnagaLoa_SetMasterColorCL())
				generated = nil
			end
		elseif a1 == "loamoff" then
			if a4 ~= UnitName("Player") then
				currentmaster = ""
				current2:SetText(currentmaster)
				SnagaLoa_ClearAllLists()
				SnagaLoa_Names = {}
				SnagaLoa_RaidIds = {}
				SnagaLoa_SetWindowHeight()
				generated = nil
			end
		elseif a1 == "loacreq" then
			if isMaster then
				if generated then
					SnagaLoa_BroadCast()
				end
			end
		elseif a1 == "loalistoff" then
			if not isMaster then
				SnagaLoa_ClearAllLists()
				pending1:Show()
				SnagaLoa_Names = {}
				SnagaLoa_RaidIds = {}
				SnagaLoa_SetWindowHeight("pending")
				generated = nil
			end
		elseif a1 == "loaliston" then
			if not isMaster then
				pending1:Hide()
			end
		elseif a1 == "loabroad" then
			if not isMaster then
				if currentmaster == "" then
					currentmaster = a4
					current2:SetText(currentmaster)
					current2:SetTextColor(SnagaLoa_SetMasterColorCL())
				end
				SnagaLoa_ClientList(a2)
			end
		end
	end
end

function SnagaLoa_ClientList(arg)
	local namestring = arg
	SnagaLoa_Names = {}
	SnagaLoa_RaidIds = {}

	for word in string.gfind(namestring, "%a+") do 
		table.insert(SnagaLoa_Names, word)
	end

	for p,q in ipairs(SnagaLoa_Names) do
		for i=1, GetNumRaidMembers() do
			local name, realm = UnitName("Raid"..i)
			if name == q then
				table.insert(SnagaLoa_RaidIds, "Raid"..i)
			end
		end
	end

	SnagaLoa_DoText()
	SnagaLoa_SetWindowHeight()
	generated = true
end

function SnagaLoa_RenewIds()
	SnagaLoa_RaidIds = {}
	for p,q in ipairs(SnagaLoa_Names) do
		local namepureq = string.gsub(q, "!!%s", "")
		if SnagaLoa_IsInRaid(namepureq) then
			for i=1,GetNumRaidMembers() do
				local name, realm = UnitName("Raid"..i)
				if name == namepureq then
					table.insert(SnagaLoa_RaidIds, "Raid"..i)
				end
			end
			if string.find(SnagaLoa_Names[p], "!!") then
				SnagaLoa_Names[p] = string.gsub(SnagaLoa_Names[p], "!!%s", "")
			end
		else
			if not string.find(SnagaLoa_Names[p], "!!") then
				SnagaLoa_Names[p] = string.format("%s %s", "!!", SnagaLoa_Names[p])
			end
			
			table.insert(SnagaLoa_RaidIds, "raid1")
		end	
	end	
	SnagaLoa_DoText()
end

--called by the BC button
function SnagaLoa_BroadCast()
	local bcstring = ""
	for f,g in ipairs(SnagaLoa_Names) do
		if bcstring == "" then
			bcstring = string.format("%s", g)
		else
			bcstring = string.format("%s %s", bcstring, g)
		end
	end
	SendAddonMessage("loabroad", bcstring, "Raid")
end

function SnagaLoa_Add(currentname)
	for i=1,GetNumRaidMembers() do
		local name, realm = UnitName("Raid"..i)
		if name == currentname then
			table.insert(SnagaLoa_RaidIds, "Raid"..i)
		end
	end
	table.insert(SnagaLoa_Names, currentname)
	SnagaLoa_DoText()
	SnagaLoa_SetWindowHeight()
	SnagaLoa_SetWindowWidth()
end

function SnagaLoa_Reload(argument)
	if argument == "LeftButton" then
		SnagaLoa_Request()
	end
end
	
function SnagaLoa_SaveButton()
	SnagaLoa_HideMasterFrames()
	SnagaLoa_BCon()
	SnagaLoa_BroadCast()
	generated = true
	if firstGen then
		firstGen = nil
	end
	SnagaLoa_DoText()
	SnagaLoa_SetWindowHeight()
	SnagaLoa_SetWindowWidth()
end

function SnagaLoa_NewButton()
	if firstGen then
		SnagaLoa_GenerateFirstBox()
	else
		SnagaLoa_GenerateBox("new")
	end
end
	
function SnagaLoa_BCon()
	SendAddonMessage("loaliston", UnitName("Player"), "Raid")
end

function SnagaLoa_BCoff()
	SendAddonMessage("loalistoff", UnitName("Player"), "Raid")
end

function SnagaLoa_ToggleMasterMode()
	if not isMaster then
		SendAddonMessage("loamnew", UnitName("Player"), "Raid")
		isMaster = true
		currentmaster = UnitName("Player")
		Edit:Show()
		Broadcast:Show()
		Reload:Hide()
		current2:SetText(currentmaster)
		current2:SetTextColor(SnagaLoa_SetMasterColorM())
		SnagaLoa_GenerateFirstBox()
		SnagaLoa_BCoff()
		generated = nil
		DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [SnagaLoatheb]|r Master-mode Enabled.")
		
	elseif isMaster then
		SendAddonMessage("loamoff", UnitName("Player"), "Raid")
		isMaster = nil
		currentmaster = ""
		SnagaLoa_HideMasterFrames()
		current2:SetText(currentmaster)
		Edit:Hide()
		Broadcast:Hide()
		Reload:Show()
		SnagaLoa_ClearAllLists()
		SnagaLoa_Names = {}
		SnagaLoa_RaidIds = {}
		SnagaLoa_SetWindowHeight()
		DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [SnagaLoatheb]|r Master-mode Disabled.")
	end
end

function SnagaLoa_GenerateFirstList()
	SnagaLoa_TempList = {}
	local insertatpos = 1
	
	for i=1,GetNumRaidMembers() do
		local name, realm = UnitName("Raid"..i)
		if UnitClass("Raid"..i) == "Priest" or UnitClass("Raid"..i) == "Druid" or UnitClass("Raid"..i) == "Paladin" or UnitClass("Raid"..i) == "Shaman" then
			tinsert(SnagaLoa_TempList, insertatpos, name)
			insertatpos = insertatpos + 1
		end
	end
end

--called by the Request button
function SnagaLoa_Request()
	SendAddonMessage("loacreq", UnitName("Player"), "Raid")
end

--called by the Edit button
function SnagaLoa_EditStart()
	SnagaLoa_GenerateBox("edit")
	SnagaLoa_BCoff()
	SnagaLoa_ClearAllLists()
	current2:SetText(UnitName("Player"))
end

function SnagaLoa_SetMasterColorM()
	if UnitClass("Player") == "Priest" then
		return 1,1,1,1
	elseif UnitClass("Player") == "Druid" then
		return 1,0.59,0.14,1
	elseif UnitClass("Player") == "Paladin" then
		return 1,0.62,0.78,1
	elseif UnitClass("Player") == "Hunter" then
		return 0.55,0.71,0.42,1	
	elseif UnitClass("Player") == "Mage" then
		return 0.41,0.8,0.94,1
	elseif UnitClass("Player") == "Warlock" then
		return 0.48,0.43,0.66,1
	elseif UnitClass("Player") == "Rogue" then
		return 1,0.96,0.41,1
	elseif UnitClass("Player") == "Warrior" then
		return 0.78,0.61,0.43,1
	elseif UnitClass("Player") == "Shaman" then
		return 0,0.54,0.87,1
	end	
end

function SnagaLoa_SetMasterColorCL()
	for i=1, GetNumRaidMembers() do
		local name, realm = UnitName("Raid"..i)
		if name == currentmaster then
			if UnitClass("Raid"..i) == "Priest" then
				return 1,1,1,1
			elseif UnitClass("Raid"..i) == "Druid" then
				return 1,0.59,0.14,1
			elseif UnitClass("Raid"..i) == "Paladin" then
				return 1,0.62,0.78,1
			elseif UnitClass("Raid"..i) == "Hunter" then
				return 0.55,0.71,0.42,1	
			elseif UnitClass("Raid"..i) == "Mage" then
				return 0.41,0.8,0.94,1
			elseif UnitClass("Raid"..i) == "Warlock" then
				return 0.48,0.43,0.66,1
			elseif UnitClass("Raid"..i) == "Rogue" then
				return 1,0.96,0.41,1
			elseif UnitClass("Raid"..i) == "Warrior" then
				return 0.78,0.61,0.43,1
			elseif UnitClass("Raid"..i) == "Shaman" then
				return 0,0.54,0.87,1
			end
		end
	end
end

function SnagaLoa_SlashHandler(msg)
	local command = string.lower(msg)

	if string.lower(msg) == "on" then
		if frameIsShown then
			DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [SnagaLoatheb]|r Addon already enabled.")
		elseif GetNumRaidMembers() == 0 then
			DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [SnagaLoatheb]|r Addon enabled. Will only work in raids.")
			SnagaLoaFrame:Show()
			frameIsShown = true
		else
			SnagaLoaFrame:Show()
			frameIsShown = true
			DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [SnagaLoatheb]|r Addon enabled.")
		end
	elseif string.lower(msg) == "off" then
		if not frameIsShown then
			DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [SnagaLoatheb]|r Addon already disabled.")
		else
			if isMaster then
				SnagaLoa_ToggleMasterMode()
			end
			SnagaLoaFrame:Hide()
			frameIsShown = nil
			DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [SnagaLoatheb]|r Addon disabled.")
		end
	elseif string.lower(msg) == "master" then
		if frameIsShown then
			SnagaLoa_ToggleMasterMode()
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [SnagaLoatheb]|r Enable the Addon first: '/loatheb on'")
		end
	else
		SnagaLoa_ShowHelp()
	end
end

--called by the X button
function SnagaLoa_ManualDisable()
	if not frameIsShown then
		DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [SnagaLoatheb]|r Addon already disabled.")
	else
		if isMaster then
			SnagaLoa_ToggleMasterMode()
		end
		
		frameIsShown = nil
		SnagaLoaFrame:Hide()
		DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [SnagaLoatheb]|r Addon disabled.")
	end
end

function SnagaLoa_ClearAllLists()
	for i=1,20 do
		getglobal("SnagaLoaText"..i):SetText("")
	end
end

function SnagaLoa_ShowMasterFrames()
	MFX:Show()
	
	for i=1,20 do
		getglobal("MF"..i):Show()
	end
end

function SnagaLoa_HideMasterFrames()
	MFX:Hide()
	
	for i=1,20 do
		getglobal("MF"..i):Hide()
	end
end

function SnagaLoa_ShowHelp()
	DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f[SnagaLoatheb]|r")
	DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [Commands]|r '/loatheb on' and '/loatheb off'")
	DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [To move the window]|r hold SHIFT and Drag")
	DEFAULT_CHAT_FRAME:AddMessage("|cffFF8080   [Red]: Healers with the Debuff |r |cff889D9D [Grey]: Dead Players |r")
	DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [Generate the List]|r '/loatheb master'")
	DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [Master mode issues]|r If you go offline or leave the raid, use the command again to sign off. Dont go mastermode if someone else already is.")
end

function SnagaLoa_SetWindowHeight(arg)
--TODO
	local numberofppl = table.getn(SnagaLoa_Names)
	if numberofppl == 0 then
		if arg ~= "pending" then
			windowheight = 46 --to be tested
		else
			windowheight = 69 --to be tested
		end
	else
		windowheight = 59 + (10 * numberofppl) --this is the List frame
	end
	SnagaLoaFrame:SetHeight(windowheight)
end

function SnagaLoa_SetWindowWidth()
	SnagaLoaFrame:SetWidth(118)
end

function SnagaLoa_OnUpdate(elapsed)
	runningtime = runningtime + elapsed 	
	if runningtime > 0.5 then
		SnagaLoa_UpdateIds()
		SnagaLoa_UpdateStatus()
		runningtime = 0
	end
end

function SnagaLoa_UpdateIds()
	if not UnitAffectingCombat("Player") then
		if counter == 5 then
			if generated then
				SnagaLoa_RenewIds()
				counter = 0
			end
		else
			counter = counter + 1
		end
	end
end

function SnagaLoa_CheckDebuff(IDToCheck)
	for a=1,21 do
		local t = UnitDebuff(IDToCheck,a)
		if t == nil then 
			break
		end    
		if t == "Interface\\Icons\\Spell_Shadow_AuraOfDarkness" then
			return true
		end
	end
end

function SnagaLoa_GenerateFirstBox()
	SnagaLoa_GenerateFirstList()
	SnagaLoa_ClearAllLists()
	MFX:Show()
	
	for i=1,20 do
		if SnagaLoa_TempList[i] then
			getglobal("MF"..i):Show()
			getglobal("M"..i):SetText(SnagaLoa_TempList[i])
			getglobal("M"..i):SetTextColor(SnagaLoa_DecodeColor(SnagaLoa_TempList[i]))
		else
			getglobal("M"..i):SetText("")
			getglobal("MF"..i):Hide()
		end
	end
	
	local amount = table.getn(SnagaLoa_TempList)
	if amount == 0 then
		MFX:SetHeight(30)
	else
		local newheight = 30 + (amount * 20)
		MFX:SetHeight(newheight)
	end
end

function SnagaLoa_IsInRaid(thename)
	for i=1,GetNumRaidMembers() do
		local name, realm = UnitName("Raid"..i)
		if name == thename then
			return true
		end
	end
	return false
end

function SnagaLoa_IsInList(thename)
	for c,d in ipairs(SnagaLoa_NamesSave) do
		if d == thename then
			return true
		end
	end
	return false
end

function SnagaLoa_RedoSaveList()
	local pos = 1
	while (pos <= table.getn(SnagaLoa_NamesSave)) do
		if not SnagaLoa_IsInRaid(SnagaLoa_NamesSave[pos]) then
			table.remove(SnagaLoa_NamesSave, pos)
		else 
			pos = pos + 1
		end
	end
	
	for i=1,GetNumRaidMembers() do
		local name, realm = UnitName("Raid"..i)
		if UnitClass("Raid"..i) == "Priest" or UnitClass("Raid"..i) == "Druid" or UnitClass("Raid"..i) == "Paladin" or UnitClass("Raid"..i) == "Shaman" then
			if not SnagaLoa_IsInList(name) then
				table.insert(SnagaLoa_NamesSave, pos, name)
				pos = pos + 1
			end
		end
	end
end

function SnagaLoa_GenerateBox(typeok)
	if typeok == "edit" then
		SnagaLoa_NamesSave = SnagaLoa_Names
	end
	SnagaLoa_Names = {}
	SnagaLoa_RaidIds = {}
	SnagaLoa_ClearAllLists()
	SnagaLoa_SetWindowHeight()
	SnagaLoa_RedoSaveList()
	MFX:Show()
	
	for i=1,20 do
		if SnagaLoa_NamesSave[i] then
			getglobal("MF"..i):Show()
			getglobal("M"..i):SetText(SnagaLoa_NamesSave[i])
			getglobal("M"..i):SetTextColor(SnagaLoa_DecodeColor(SnagaLoa_NamesSave[i]))
		else
			getglobal("M"..i):SetText("")
			getglobal("MF"..i):Hide()
		end
	end
	
	local amount = table.getn(SnagaLoa_NamesSave)
	if amount == 0 then
		MFX:SetHeight(30)
	else
		local newheight = 30 + (amount * 20) --This is when you press the EDIT button
		MFX:SetHeight(newheight)
	end
end

function SnagaLoa_UpdateStatus()
	for i=1,20 do
		if SnagaLoa_Names[i] then
			if UnitIsDeadOrGhost(SnagaLoa_RaidIds[i]) then
				getglobal("SnagaLoaText"..i):SetTextColor(0.4,0.4,0.4,1)
			elseif SnagaLoa_CheckDebuff(SnagaLoa_RaidIds[i]) then
				getglobal("SnagaLoaText"..i):SetTextColor(0.7,0,0,1)
			else 
				if UnitClass(SnagaLoa_RaidIds[i]) == "Priest" then
					getglobal("SnagaLoaText"..i):SetTextColor(1,1,1,1)
				elseif UnitClass(SnagaLoa_RaidIds[i]) == "Druid" then
					getglobal("SnagaLoaText"..i):SetTextColor(1,0.59,0.14,1)
				elseif UnitClass(SnagaLoa_RaidIds[i]) == "Paladin" then
					getglobal("SnagaLoaText"..i):SetTextColor(1,0.62,0.78,1)
				else --Shaman
					getglobal("SnagaLoaText"..i):SetTextColor(0,0.54,0.87,1)
				end
			end
		end
	end
end

function SnagaLoa_DoText()
	for i=1,20 do
		if SnagaLoa_Names[i] then
			getglobal("SnagaLoaText"..i):SetText(SnagaLoa_Names[i])
			if UnitClass(SnagaLoa_RaidIds[i]) == "Priest" then
				getglobal("SnagaLoaText"..i):SetTextColor(1,1,1,1)
			elseif UnitClass(SnagaLoa_RaidIds[i]) == "Druid" then
				getglobal("SnagaLoaText"..i):SetTextColor(1,0.59,0.14,1)
			elseif UnitClass(SnagaLoa_RaidIds[i]) == "Paladin" then
				getglobal("SnagaLoaText"..i):SetTextColor(1,0.62,0.78,1)
			else 
				getglobal("SnagaLoaText"..i):SetTextColor(0,0.54,0.87,1)
			end
		else
			getglobal("SnagaLoaText"..i):SetText("")
		end
	end
end

function SnagaLoa_DecodeColor(ar)
	for i=1, GetNumRaidMembers() do
		local name, realm = UnitName("Raid"..i)
		if name == ar then
			if UnitClass("Raid"..i) == "Priest" then
				return 1,1,1,1
			elseif UnitClass("Raid"..i) == "Druid" then
				return 1,0.59,0.14,1
			elseif UnitClass("Raid"..i) == "Paladin" then
				return 1,0.62,0.78,1
			elseif UnitClass("Raid"..i) == "Shaman" then
				return 0,0.54,0.87,1
			else
				return 1,0,0,1
			end	
		end
	end
end
