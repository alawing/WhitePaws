local function WhitePaws_Command(arg1)
	if arg1 then arg1 = strlower(arg1) end
	if arg1 == 'alert' then
		wcAlert = not wcAlert
	elseif arg1 == 'bg' then
		wcIsInInstance = not wcIsInInstance
	elseif arg1 == 'fly' then
		wcFlightMaster = not wcFlightMaster
	elseif arg1 == 'speed' then
		wcSpeed = not wcSpeed
		showSpeed()
	end
	SELECTED_CHAT_FRAME:AddMessage((wcAlert and '[|cff00ff00开|r]' or '[|cffff0000关|r]')..'/wc alert 开关被控通告功能',255,255,0)
	SELECTED_CHAT_FRAME:AddMessage((wcIsInInstance and '[|cff00ff00开|r]' or '[|cffff0000关|r]')..'/wc bg 开关副本/战场内自动马鞭功能',255,255,0)
	SELECTED_CHAT_FRAME:AddMessage((wcSpeed and '[|cff00ff00开|r]' or '[|cffff0000关|r]')..'/wc speed 开关小地图右下方移动速度显示框体',255,255,0)
	SELECTED_CHAT_FRAME:AddMessage((wcFlightMaster and '[|cff00ff00开|r]' or '[|cffff0000关|r]')..'/wc fly 开关点击飞行点地图自动取消变形功能',255,255,0)
	SELECTED_CHAT_FRAME:AddMessage('/wc 查看命令帮助',255,255,0)
end

SlashCmdList['WHITEPAWS'] = WhitePaws_Command
SLASH_WHITEPAWS1 = '/whitepaws'
SLASH_WHITEPAWS2 = '/wc'

local function wcInit()
	wcAlert = wcAlert or false
	wcIsInInstance = wcIsInInstance or false
	wcFlightMaster = wcFlightMaster or true
	wcSpeed = wcSpeed or false
	local title = select(2, GetAddOnInfo('whitepaws'))
	SELECTED_CHAT_FRAME:AddMessage('---------------------')
	SELECTED_CHAT_FRAME:AddMessage('欢迎使用'..title,255,255,0)
	SELECTED_CHAT_FRAME:AddMessage('---------------------')
	WhitePaws_Command()
	autoUnshift()
end

local initFrame = CreateFrame('Frame')

initFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
initFrame:SetScript('OnEvent', wcInit)

local function getLatency()
	return select(4, GetNetStats()) / 1000
end

local clearcasting = false
local flying = false
local nextTick = 2

--PowerSpark
local class = select(2, UnitClass('player'))
local frame = CreateFrame('Frame')
for _, item in pairs({
	'PLAYER_ENTERING_WORLD',
	'UNIT_AURA',
	'UPDATE_SHAPESHIFT_FORM',
	'UNIT_SPELLCAST_SUCCEEDED',
	'UNIT_POWER_FREQUENT',
}) do
	frame:RegisterEvent(item, 'player')
end
frame:SetScript('OnEvent', function(self, event, ...)
	if event == 'PLAYER_ENTERING_WORLD' then
		function self.cure(key)
			local type = UnitPowerType('player')
			if key == 'druid' then type = 0 end
			return UnitPower('player', type), type
		end
		function self.rest(key, event, unit, powerType)
			local cure, type = self.cure(key)
			if event == 'UPDATE_SHAPESHIFT_FORM' and class == 'DRUID' then --小德变身
				self[key].cure = cure
				self[key].timer = GetTime()
			elseif event == 'UNIT_POWER_FREQUENT' and unit == 'player' then -- 能量/法力更新
				if cure > self[key].cure then
					self[key].cure = cure
					self[key].timer = GetTime()
					PowerSparkDB[key].timer = self[key].timer
				end
			elseif event == 'UNIT_SPELLCAST_SUCCEEDED' and unit == 'player' then -- 施法成功
				if cure < self[key].cure and type == 0 then self[key].wait = GetTime() + 5 end -- 5秒回蓝
				self[key].cure = cure
			end
		end
		function self.init(parent, key) --初始化
			if not parent or self[key] then return end
			if not PowerSparkDB then PowerSparkDB = {} end
			if not PowerSparkDB[key] then PowerSparkDB[key] = {} end
			local power = CreateFrame('StatusBar', nil, parent)
			power:SetWidth(parent.width or parent:GetWidth())
			power:SetHeight(parent.height or parent:GetHeight())
			power:SetPoint('CENTER')
			power.spark = power:CreateTexture(nil, 'OVERLAY')
			power.spark:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
			power.spark:SetWidth(32)
			power.spark:SetHeight(32)
			power.spark:SetBlendMode('ADD')
			power.spark:SetAlpha(0)
			power.cure = self.cure(key)
			power.rate = GetTime()
			power.timer = PowerSparkDB[key].timer or GetTime()
			power.interval = 2
			power.key = key
			power.parent = parent
			function power.hide(key)
				local cure, type = self.cure(key)
				return UnitIsDeadOrGhost('player') or key == 'default' and type == 1 or type == 0 and cure >= UnitPowerMax('player', 0) or type == 3 and cure >= UnitPowerMax('player') and not IsStealthed() and (not UnitCanAttack('player', 'target') or UnitIsDeadOrGhost('target')) --角色死亡/怒气/满蓝/满能量且不潜行且目标不可攻击
			end
			power:HookScript('OnUpdate', function(self)
				local now = GetTime()
				nextTick = 2 - mod(now - self.timer, 2)
				if now < self.rate then return end
				self.rate = now + 0.02 --刷新率
				if self.hide(self.key) then
					self.spark:SetAlpha(0)
				elseif self.wait and self.wait > now and (UnitPowerType('player') == 0 or self.key == 'druid') then --5秒等待回蓝
					self.spark:SetAlpha(1)
					self.spark:SetPoint('CENTER', self, 'LEFT', self:GetWidth() * (self.wait - now) / 5, 0)
				elseif self.timer then
					self.spark:SetAlpha(1)
					self.spark:SetPoint('CENTER', self, 'LEFT', self:GetWidth() * (mod(now - self.timer, self.interval) / self.interval), 0)
				end
			end)
			self[key] = power
		end
		if SUFUnitplayer and SUFUnitplayer.powerBar then -- 兼容 SUF
			self.init(SUFUnitplayer.powerBar, 'default')
			if class == 'DRUID' and SUFUnitplayer.druidBar then self.init(SUFUnitplayer.druidBar, 'druid') end
		elseif ElvUF_Player and ElvUF_Player.Power then	-- 兼容 ElvUI
			self.init(ElvUF_Player.Power, 'default')
		elseif StatusBars2_playerPowerBar then	-- 兼容 Statusbars2
			self.init(StatusBars2_playerPowerBar, 'default')
		else
			self.init(PlayerFrameManaBar, 'default')
		end
		if class == 'DRUID' and DruidBarFrame then
			DruidBarFrame.width = DruidBarKey.width - 4
			DruidBarFrame.health = DruidBarKey.height - 4
			self.init(DruidBarFrame, 'druid')
		end
		if class == 'DRUID' and BC_DruidBar then
			BC_DruidBar.width = BC_DruidBar.Mana:GetWidth() - 4
			BC_DruidBar.health = BC_DruidBar.Mana:GetHeight() - 4
			self.init(BC_DruidBar, 'druid')
		end
	elseif event == 'UNIT_AURA' and class == 'ROGUE' then
		self.interval = 2
		local i = 1
		while UnitBuff('player', i) do
			if select(10, UnitBuff('player', i)) == 13750 then --开了冲动
				self.interval = 1
				break
			end
			i = i + 1
		end
	elseif event == 'UNIT_AURA' and class == 'DRUID' then
		local i = 1
		clearcasting = false
		while UnitBuff('player', i) do
			if select(10, UnitBuff('player', i)) == 16870 then --节能施法
				clearcasting = true
				break
			end
			i = i + 1
		end
	elseif self.rest then
		self.rest('default', event, ...)
		if self.druid then self.rest('druid', event, ...) end
	end
end)
--End of PowerSpark

--判断控制
local strongControl, rooted

local function GetControls(self, event, ...)
	strongControl = false
	rooted = false

	local eventIndex = C_LossOfControl.GetActiveLossOfControlDataCount()
	while (eventIndex > 0) do
		local locType = C_LossOfControl.GetActiveLossOfControlData(eventIndex).locType
		if locType == 'ROOT' or locType == 'CONFUSE' and C_LossOfControl.GetActiveLossOfControlData(eventIndex).displayText == '变形' then
			rooted = true
			if wcAlert then
				SendChatMessage('['..C_LossOfControl.GetActiveLossOfControlData(eventIndex).displayText..'],还剩'..(math.floor(C_LossOfControl.GetActiveLossOfControlData(eventIndex).timeRemaining  * 10 + 0.5) / 10)..'秒,类型是'..C_LossOfControl.GetActiveLossOfControlData(eventIndex).locType..',能解吗？能解，所以问题不大', 'EMOTE')
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
				SendChatMessage('['..C_LossOfControl.GetActiveLossOfControlData(eventIndex).displayText..'],还剩'..(math.floor(C_LossOfControl.GetActiveLossOfControlData(eventIndex).timeRemaining  * 10 + 0.5) / 10)..'秒,类型是'..C_LossOfControl.GetActiveLossOfControlData(eventIndex).locType..',能解吗？不能解,但是可以忍过去,所以问题不大', 'EMOTE')
			end
		elseif locType == 'SCHOOL_INTERRUPT' or
			locType == 'SILENCE' or
			locType == 'DISARM' then
				if wcAlert then
					SendChatMessage('['..C_LossOfControl.GetActiveLossOfControlData(eventIndex).displayText..'],还剩'..(math.floor(C_LossOfControl.GetActiveLossOfControlData(eventIndex).timeRemaining  * 10 + 0.5) / 10)..'秒,类型是'..C_LossOfControl.GetActiveLossOfControlData(eventIndex).locType..',能解吗？不能解,但是不是硬控,所以问题不大', 'EMOTE')
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
function autoUnshift()
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
        autoUnshiftFrame:EnableMouse(true)
        autoUnshiftFrame:SetFrameLevel(3)
        autoUnshiftFrame:Hide()
        autoUnshiftFrame:SetScript("OnUpdate",function(self,motion)
        	autoCancelShapeshiftForm()
        	FlightPoint = FlightPoint or 1
        	if MouseIsOver(FlightPointButton) then
            		TaxiNodeOnButtonEnter(FlightPointButton)
            		autoUnshiftFrame:EnableMouse(true)
        	end
        	if not MouseIsOver(FlightPointButton) then
            		autoUnshiftFrame:EnableMouse(false)
            		TaxiNodeOnButtonLeave(FlightPointButton)
        	end
    	end)
    	autoUnshiftFrame:SetScript("OnLeave",function()
        	autoUnshiftFrame:EnableMouse(false)
        	TaxiNodeOnButtonLeave(FlightPointButton)
    	end)
end

--侦测'你不能在变形状态下使用空中运输服务！'红字错误，然后打开自动解除变形
--ERR_TAXIPLAYERMOVING = '你正在移动。'
--ERR_TAXIPLAYERSHAPESHIFTED = '你不能在变形状态下使用空中运输服务！'
--ERR_TAXISAMENODE = '你已经在那里了！'
--诺格弗格药剂（骷髅）:16591  熊怪形态:6405
dummy = UIErrorsFrame.AddMessage
UIErrorsFrame.AddMessage = function(self, msg, ...)
    if InCombatLockdown() or NumTaxiNodes() == 0 or (not wcFlightMaster) then
    elseif (msg == ERR_TAXIPLAYERMOVING or msg == ERR_TAXIPLAYERSHAPESHIFTED or msg == ERR_TAXISAMENODE) and GetShapeshiftFormID() then
        autoCancelShapeshiftForm()
        autoUnshift()
    end
    if (msg == ERR_TAXIPLAYERMOVING or msg == ERR_TAXIPLAYERSHAPESHIFTED or msg == ERR_TAXISAMENODE) then
        autoCancelShapeshift()
    end
    dummy(UIErrorsFrame, msg, ...)
end

--解除德鲁伊变形
function autoCancelShapeshiftForm()
    if InCombatLockdown() or NumTaxiNodes() == 0 or (not dsfFlightMaster) then
    elseif GetShapeshiftFormID() then
        autoUnshiftFrame:Show()
        local num = NumTaxiNodes() or 17
        for i = 1, num, 1 do
            FlightPoint = 0
            local name = TaxiNodeName(i)
            if name == GameTooltipTextLeft1:GetText() then
                FlightPoint = i
                FlightPointButton = _G["TaxiButton"..i]
                break
            end
        end
    elseif autoUnshiftFrame then
        autoUnshiftFrame:Hide()
    end
end

local autoCancelShapeshiftFormFrame = CreateFrame("frame")
autoCancelShapeshiftFormFrame:RegisterEvent("TAXIMAP_OPENED")
autoCancelShapeshiftFormFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
autoCancelShapeshiftFormFrame:SetScript("OnEvent",autoCancelShapeshiftForm)

--解除诺格弗格药剂（骷髅）和熊怪形态的变形
--诺格弗格药剂（骷髅）:16591  熊怪形态:6405
function autoCancelShapeshift()
    if InCombatLockdown() or NumTaxiNodes() == 0 or (not dsfFlightMaster) then
    else
        local i = 1
        while i <= 32 do
            local name, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
            if spellId == 16591 or spellId == 6405 then
                CancelUnitBuff("player", i)
            elseif spellId == nil then
                break
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
	return UnitPower('player', 1)
end

local function getEnergy()
	if GetShapeshiftForm() ~= 3 then
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
	if clearcasting then
		return true
	end
	return getEnergy() >= cost
end

local function enoughEnergywithNextTick(cost)
	if clearcasting then
		return true
	end
	local e = getEnergy()
	if nextTick + getLatency() / 2 >= 2 or nextTick - getLatency() / 2 <= 0 then e = e + 20 end
	if e >= cost then return true end
	if e + 20 >= cost and nextTick - getLatency() / 2 <= 1.5 then return true end
	return false
end

local function enoughRage(cost)
	if clearcasting then
		return true
	end
	return getRage() >= cost
end

--公共函数

--输出，考虑延迟
function dps(cost)
	if not strongControl and enoughMana() and (rooted and (IsSpellInRange('爪击', 'target') ~= 1 or UnitLevel('target') == -1)  or ableShift() and not enoughEnergywithNextTick(cost)) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--老款输出，不考虑延迟
function dpsx(cost)
	if not strongControl and enoughMana() and (rooted and (IsSpellInRange('爪击', 'target') ~= 1 or UnitLevel('target') == -1) or not getShiftGCD() and not enoughEnergywithNextTick(cost)) then
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
