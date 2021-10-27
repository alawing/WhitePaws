local addonName, wc = ...

local function WhitePaws_Command(arg1)
	if arg1 then arg1 = strlower(arg1) end
	if arg1 == 'alert' then
		wcAlert = not wcAlert
	elseif arg1 == 'bg' then
		wcIsInInstance = not wcIsInInstance
	elseif arg1 == 'speed' then
		wcSpeed = not wcSpeed
		showSpeed()
	end
	SELECTED_CHAT_FRAME:AddMessage((wcAlert and '[|cff00ff00开|r]' or '[|cffff0000关|r]')..'/wc alert 开关被控通告功能',255,255,0)
	SELECTED_CHAT_FRAME:AddMessage((wcIsInInstance and '[|cff00ff00开|r]' or '[|cffff0000关|r]')..'/wc bg 开关副本/战场内自动马鞭功能',255,255,0)
	SELECTED_CHAT_FRAME:AddMessage((wcSpeed and '[|cff00ff00开|r]' or '[|cffff0000关|r]')..'/wc speed 开关小地图右下方移动速度显示框体',255,255,0)
	SELECTED_CHAT_FRAME:AddMessage('/wc 查看命令帮助',255,255,0)
end

SlashCmdList['WHITEPAWS'] = WhitePaws_Command
SLASH_WHITEPAWS1 = '/whitepaws'
SLASH_WHITEPAWS2 = '/wc'

local function getLatency()
	return select(4, GetNetStats()) / 1000
end

wc.clearcasting = false
local flying = false
wc.nextTick = 2

--判断控制
local strongControl, rooted

local function GetControls(self, event, ...)
	strongControl = false
	rooted = false

	if event == 'PLAYER_CONTROL_LOST' and wcAlert then
		SELECTED_CHAT_FRAME:AddMessage('哟失去控制了')
		return
	end
	if event == 'PLAYER_CONTROL_GAINED' and wcAlert then
		SELECTED_CHAT_FRAME:AddMessage('哟又能控制了')
		return
	end
	local eventIndex = C_LossOfControl.GetActiveLossOfControlDataCount()
	while (eventIndex > 0) do
		local locType = C_LossOfControl.GetActiveLossOfControlData(eventIndex).locType
		if locType == 'ROOT' or locType == 'CONFUSE' and C_LossOfControl.GetActiveLossOfControlData(eventIndex).displayText == '变形' then
			rooted = true
			if wcAlert then
				SendChatMessage('['..C_LossOfControl.GetActiveLossOfControlData(eventIndex).displayText..'],还剩'..(math.floor(C_LossOfControl.GetActiveLossOfControlData(eventIndex).timeRemaining  * 10 + 0.5) / 10)..'秒,类型是'..C_LossOfControl.GetActiveLossOfControlData(eventIndex).locType..',能用变形解，所以问题不大', 'EMOTE')
			end
		elseif locType == 'STUN_MECHANIC' or
			locType == 'STUN' or
			locType == 'POSSESS' or
			locType == 'FEAR_MECHANIC' or
			locType == 'CONFUSE' or
			locType == 'FEAR' or
			locType == 'CHARM' then
			strongControl = true
			if wcAlert then
				SendChatMessage('['..C_LossOfControl.GetActiveLossOfControlData(eventIndex).displayText..'],还剩'..(math.floor(C_LossOfControl.GetActiveLossOfControlData(eventIndex).timeRemaining  * 10 + 0.5) / 10)..'秒,类型是'..C_LossOfControl.GetActiveLossOfControlData(eventIndex).locType..',不能用变形解,但是可以忍过去,所以问题不大', 'EMOTE')
			end
		elseif locType == 'SCHOOL_INTERRUPT' or
			locType == 'SILENCE' or
			locType == 'DISARM' or
			locType == 'PACIFY' then
				if wcAlert then
					SendChatMessage('['..C_LossOfControl.GetActiveLossOfControlData(eventIndex).displayText..'],还剩'..(math.floor(C_LossOfControl.GetActiveLossOfControlData(eventIndex).timeRemaining  * 10 + 0.5) / 10)..'秒,类型是'..C_LossOfControl.GetActiveLossOfControlData(eventIndex).locType..',不能用变形解,但是不是硬控,所以问题不大', 'EMOTE')
				end
		else
			if wcAlert then
				SendChatMessage('['..C_LossOfControl.GetActiveLossOfControlData(eventIndex).displayText..'],还剩'..(math.floor(C_LossOfControl.GetActiveLossOfControlData(eventIndex).timeRemaining  * 10 + 0.5) / 10)..'秒,类型是'..C_LossOfControl.GetActiveLossOfControlData(eventIndex).locType..',新的控制技能？', 'EMOTE')
			end
		end
		eventIndex = eventIndex - 1
	end
end

local controlFrame = CreateFrame('Frame')

controlFrame:RegisterEvent('LOSS_OF_CONTROL_UPDATE') -- the player current target recently gained or lost an control
controlFrame:RegisterEvent('PLAYER_CONTROL_LOST') -- the player current target recently gained or lost an control
controlFrame:RegisterEvent('PLAYER_CONTROL_GAINED') -- the player current target recently gained or lost an control
controlFrame:SetScript('OnEvent', GetControls)

--触发：变形,移动,BUFF,换过装备,变形,脱战
--上坐骑或飞行自动换饰品
--马鞭: 25653 迅捷飞行符咒: 32481 碎天者之鞭: 32863 棍子上的胡萝卜: 37312
local function changeBoostTrinket(self, event, ...)
	if InCombatLockdown() then return end
	local mountedTrinket = nil
    	if GetItemCount(32863) > 0 then
        	mountedTrinket = 32863
    	elseif GetItemCount(25653) > 0 then
        	mountedTrinket = 25653
    	elseif GetItemCount(37312) > 0 then
        	mountedTrinket = 37312
    	end
	if (not IsInInstance() or wcIsInInstance) and IsMounted() and not UnitOnTaxi('player') then
		if GetInventoryItemID('player', 13) ~= mountedTrinket and GetInventoryItemID('player', 14) ~= mountedTrinket then
        	if GetInventoryItemID('player', 14) ~= 32481 then
				originTrinket = GetInventoryItemID('player', 14)
			end
			EquipItemByName(mountedTrinket, 14)
		end
	elseif (not IsInInstance() or wcIsInInstance) and (GetShapeshiftFormID() == 27 or GetShapeshiftFormID() == 29) then
		if GetInventoryItemID('player', 13) ~= 32481 and GetInventoryItemID('player', 14) ~= 32481 then
        	if GetInventoryItemID('player', 14) ~= mountedTrinket then
				originTrinket = GetInventoryItemID('player', 14)
			end
			EquipItemByName(32481, 14)
		end
	elseif GetInventoryItemID('player', 14) == mountedTrinket or GetInventoryItemID('player' ,14) == 32481 then
        if originTrinket ~= nil then
			EquipItemByName(originTrinket, 14)
		end
	end
end

local boostFrame = CreateFrame('Frame')
boostFrame:RegisterEvent('PLAYER_MOUNT_DISPLAY_CHANGED')
boostFrame:RegisterEvent('UPDATE_SHAPESHIFT_FORM')
boostFrame:RegisterEvent('PLAYER_STARTED_MOVING')
boostFrame:RegisterEvent('PLAYER_STOPPED_MOVING')
boostFrame:RegisterEvent('UNIT_AURA')
boostFrame:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
boostFrame:RegisterEvent('PLAYER_REGEN_ENABLED') --比PLAYER_LEAVE_COMBAT更精确的脱战
boostFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
boostFrame:SetScript('OnEvent', changeBoostTrinket)

--点击飞行点地图时自动取消变形
local Shapeshifted, FlightPointButton, autoUnshiftFrame

local function autoUnshift()
    local texture_str = 'Interface\\TARGETINGFRAME\\UI-StatusBar'
    if InCombatLockdown() then return end
    if not autoUnshiftFrame then
        autoUnshiftFrame = CreateFrame('Button', 'unshiftMacroButton', UIParent, 'SecureActionButtonTemplate')
        autoUnshiftFrame:SetAttribute('type1', 'macro')
        autoUnshiftFrame:SetAttribute("macrotext1",'/cancelform\n/script autoCancelShapeshift()\n/script TakeTaxiNode(FlightPoint)')
        autoUnshiftFrame:SetParent(TaxiRouteMap)
        autoUnshiftFrame:SetAllPoints(TaxiRouteMap)
        autoUnshiftFrame:SetSize(16,16)
        autoUnshiftFrame:SetPoint('TOPLEFT',0,0)
        autoUnshiftFrame:EnableMouse(false)
        autoUnshiftFrame:SetFrameLevel(3)
        autoUnshiftFrame:Show()
        autoUnshiftFrame:SetScript("OnUpdate",function(self,motion)
        	autoCancelShapeshiftForm()
        	FlightPoint = FlightPoint or 0
        	if not FlightPointButton then return end
        	if (Shapeshifted or GetShapeshiftFormID()) and MouseIsOver(FlightPointButton) then
            		TaxiNodeOnButtonEnter(FlightPointButton)
            		autoUnshiftFrame:EnableMouse(true)
        	end
        	if (not Shapeshifted and not GetShapeshiftFormID()) or (not MouseIsOver(FlightPointButton)) then
            		autoUnshiftFrame:EnableMouse(false)
        	end
    	end)
    	autoUnshiftFrame:SetScript("OnLeave",function()
        	autoUnshiftFrame:EnableMouse(false)
        	TaxiNodeOnButtonLeave(FlightPointButton)
    	end)
	end
end

--解除德鲁伊变形
function autoCancelShapeshiftForm()
    if InCombatLockdown() or NumTaxiNodes() == 0 then return end
	local i = 1
	Shapeshifted = false
	while UnitBuff('player', i) do
		local spellId = select(10, UnitBuff('player', i))
    	if spellId == 16591 or spellId == 6405 then
    		Shapeshifted = true
    		break
    	end
		i = i + 1
	end

    if Shapeshifted or GetShapeshiftFormID() then
        local num = NumTaxiNodes() or 17
        for i = 1, num, 1 do
            FlightPoint = 0
            local name = TaxiNodeName(i) or "暴风城，艾尔文森林"
            if name == GameTooltipTextLeft1:GetText() then
                FlightPoint = i
                FlightPointButton = _G["TaxiButton"..i]
                break
            end
        end
    end
end

--解除诺格弗格药剂（骷髅）和熊怪形态的变形
--诺格弗格药剂（骷髅）:16591  熊怪形态:6405
function autoCancelShapeshift()
    if InCombatLockdown() or NumTaxiNodes() == 0 then
    else
        local i = 1
		while UnitBuff('player', i) do
			local spellId = select(10, UnitBuff('player', i))
			if spellId == 16591 or spellId == 6405 then
                CancelUnitBuff("player", i)
			end
			i = i + 1
		end
    end
end

--移动速度小框体
function showSpeed()
    if not speedFrame then
        speedFrame = CreateFrame('Frame','MiniMapSpeedFrame', nil, 'ThinGoldEdgeTemplate')
        speedFrame:SetParent(MiniMap)
        speedFrame:SetPoint('TOPRIGHT', 0, -150)
        speedFrame:SetFrameStrata('HIGH')
        speedFrame:SetFrameLevel(9)
        speedFrame:SetMovable(true)
        speedFrame.fs = speedFrame:CreateFontString('MinimapLayerFrameFS', 'ARTWORK')
        speedFrame.fs:SetPoint('CENTER', 0, 0)
        speedFrame.fs:SetFont('Fonts\\ARHei.ttf', 10)
        speedFrame:SetWidth(46)
        speedFrame:SetHeight(17)
        speedFrame:SetScript('OnUpdate',function()
            local playerCurrentSpeed = string.format('%d%%', GetUnitSpeed('player') / 7 * 100)
            speedFrame.fs:SetText(playerCurrentSpeed)
        end)
    end
    if wcSpeed == true then
        speedFrame:Show()
    else
        speedFrame:Hide()
    end
end

local showSpeedFrame = CreateFrame('frame')
showSpeedFrame:RegisterEvent('PLAYER_LOGIN')
showSpeedFrame:RegisterEvent('ADDON_LOADED')
showSpeedFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
showSpeedFrame:SetScript('OnEvent',showSpeed)

--变形条件
local function getShiftGCD()
	return GetSpellCooldown(768) > 0
end

local function getShiftLeftTime()
	local cd = 0
	if GetSpellCooldown(768) ~= 0 then
		cd = select(2, GetSpellCooldown(768)) + GetSpellCooldown(768) - GetTime()
	end
	return cd
end

local function ableShift()
	return getShiftLeftTime() <= getLatency() / 2
end

local function getMana()
	return UnitPower('player', 0)
end

local function getRage()
	if GetShapeshiftFormID() ~= 5 and GetShapeshiftFormID() ~= 8  then
		return 0
	end
	return UnitPower('player', 1)
end

local function getEnergy()
	if GetShapeshiftFormID() ~= 1 then
		return 0
	end
	return UnitPower('player', 3)
end

local function getBuff(name)
	local i = 1
	while UnitBuff('player', i) do
		if select(1, UnitBuff('player', i)) == name then
			return true
		end
		i = i + 1
	end
	return false
end

local function enoughMana(cost)
	if cost == nil then
		cost = GetSpellPowerCost(768)[1].cost
	end
	return getMana() >= cost
end

local function enoughEnergy(cost)
	if wc.clearcasting then
		return true
	end
	return getEnergy() >= cost
end

local function enoughEnergywithNextTick(cost)
	if wc.clearcasting then
		return true
	end
	local e = getEnergy()
	if wc.nextTick + getLatency() / 2 >= 2 or wc.nextTick - getLatency() / 2 <= 0 then e = e + 20 end
	if e >= cost then return true end
	if e + 20 >= cost and wc.nextTick - getLatency() / 2 <= 1.5 then return true end
	return false
end

local function enoughRage(cost)
	if wc.clearcasting then
		return true
	end
	return getRage() >= cost
end

--公共函数

--输出，自动解定身，考虑延迟
function dps(cost)
	if not strongControl and enoughMana() and (rooted and (IsSpellInRange('爪击', 'target') ~= 1 or UnitLevel('target') == -1)  or ableShift() and not enoughEnergywithNextTick(cost)) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--PvP输出，自动解定身减速，考虑延迟，一键打法师
function dpsp(cost)
	if not strongControl and enoughMana() and (((rooted or select(2, GetUnitSpeed('player')) < 7) and not IsStealthed()) and (IsSpellInRange('爪击', 'target') ~= 1 or UnitLevel('target') == -1)  or ableShift() and not enoughEnergywithNextTick(cost)) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--老款输出，自动解定身，不考虑延迟
function dpsx(cost)
	if not strongControl and enoughMana() and (rooted and (IsSpellInRange('爪击', 'target') ~= 1 or UnitLevel('target') == -1) or not getShiftGCD() and not enoughEnergywithNextTick(cost)) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--输出，自动解定身，考虑延迟，省蓝
function dpsl(cost)
	if not strongControl and enoughMana() and (rooted and (IsSpellInRange('爪击', 'target') ~= 1 or UnitLevel('target') == -1)  or ableShift() and not enoughEnergy(cost-20)) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--变身
function shift(r, e, m)
	r = r or 200
	e = e or 200
	if not strongControl and enoughMana(m) and not getShiftGCD() and (rooted and (IsSpellInRange('爪击', 'target') ~= 1 or UnitLevel('target') == -1) or getRage() < r and getEnergy() < e) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--吃蓝，考虑延迟
function manapot(cost, name)
	if UnitLevel('target') ~= -1 or not ableShift() or enoughEnergywithNextTick(cost) or strongControl or (UnitPowerMax('player', 0) - getMana()) < 3000 or GetItemCooldown(GetItemInfoInstant(name)) > 0 or GetItemCount(name) == 0 then
		SetCVar('autoUnshift', 0)
	else
		SELECTED_CHAT_FRAME:AddMessage('吃药啦！')
		SetCVar('autoUnshift', 1)
	end
end

--老款吃蓝，不考虑延迟
function manapotx(cost, name)
	if UnitLevel('target') ~= -1 or getShiftGCD() or enoughEnergywithNextTick(cost) or strongControl or (UnitPowerMax('player', 0) - getMana()) < 3000 or GetItemCooldown(GetItemInfoInstant(name)) > 0 or GetItemCount(name) == 0 then
		SetCVar('autoUnshift', 0)
	else
		SetCVar('autoUnshift', 1)
	end
end

--吃红
--9634巨熊形态
function hppot()
	local u,n = IsUsableSpell(9634)
	if getShiftGCD() or strongControl or not u
		then SetCVar('autoUnshift', 0)
	else
		SetCVar('autoUnshift', 1)
	end
end

--结束
function wcEnd()
	SetCVar('autoUnshift', 1)
	UIErrorsFrame:Clear()
end

local function wcInit()
	wcAlert = wcAlert or false
	wcIsInInstance = wcIsInInstance or false
	wcSpeed = wcSpeed or false
	local title = select(2, GetAddOnInfo('whitepaws'))
	SELECTED_CHAT_FRAME:AddMessage('---------------------')
	SELECTED_CHAT_FRAME:AddMessage('欢迎使用'..title,255,255,0)
	SELECTED_CHAT_FRAME:AddMessage('---------------------')
	WhitePaws_Command()
	autoUnshift()
	autoUnshiftFrame:Show()
	autoUnshiftFrame:EnableMouse(false)
end

local initFrame = CreateFrame('Frame')

initFrame:RegisterEvent('PLAYER_LOGIN')
initFrame:SetScript('OnEvent', wcInit)
