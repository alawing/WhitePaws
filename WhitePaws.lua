local function WhitePaws_Command(arg1)
	arg1 = strlower(arg1)
	if arg1 == "alert" then
		wcAlert = not wcAlert
		print('当前被控通告为:'..(wcAlert and '开' or '关'))
		print('输入/wcalert或/wp alert来进行开关')
		print('输入/wp help查看命令帮助')
	elseif arg1 == "bg" then
		wpIsInInstance = not wpIsInInstance
		print('当前副本/战场内自动换马鞭功能为:'..(wpIsInInstance and '开' or '关'))
		print('输入/wp bg来进行开关')
		print('输入/wp help查看命令帮助')
	elseif arg1 == "show" then
		print('当前被控通告为:'..(wcAlert and '开' or '关'))
		print('当前副本/战场内自动换马鞭功能为:'..(wpIsInInstance and '开' or '关'))
		print('输入/wp help查看命令帮助')
	elseif arg1 == "help" then
		print('/wcalert    开关被控通告功能')
		print('/wp alert   开关被控通告功能')
		print('/wp bg      开关副本/战场内自动马鞭功能')
		print('/wp show    显示当前被控通告和自动马鞭功能的开关状态')
		print('/wp help    查看命令帮助')
	end
end

SlashCmdList["WHITEPAWS"] = WhitePaws_Command
SLASH_WHITEPAWS1 = '/whitepaws'
SLASH_WHITEPAWS2 = '/wp'

SLASH_WCALERT1 = '/wcalert'

function SlashCmdList.WCALERT(msg, editBox)
	wcAlert = not wcAlert
	print('当前被控通告为:'..(wcAlert and '开' or '关'))
	print('输入/wcalert来进行开关')
	print('输入/wp help查看命令帮助')
end

local function wcInit()
	wcAlert = wcAlert or false
	wpIsInInstance = wpIsInInstance or false
	local title = select(2, GetAddOnInfo('whitepaws'))
	print('欢迎使用'..title)
	print('当前被控通告为:'..(wcAlert and '开' or '关'))
	print('输入/wcalert来进行开关')
	print('输入/wp help查看命令帮助')
end

local initFrame = CreateFrame('Frame')

initFrame:RegisterEvent('PLAYER_LOGIN')
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
			locType == 'FEAR' then
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
--马鞭: 25653 迅捷飞行符咒: 32481
local function changeBoostTrinket(self, event, ...)
	if InCombatLockdown() then return end
	if IsInInstance() and not wpIsInInstance then return end
	if IsMounted() and not UnitOnTaxi("player") then
		if GetInventoryItemID('player', 13) ~= 25653 and GetInventoryItemID('player', 14) ~= 25653 then
        	if GetInventoryItemID('player', 14) ~= 32481 then
				originTrinket = GetInventoryItemID('player', 14)
			end
			EquipItemByName(25653, 14)
		end
	elseif (GetShapeshiftFormID() == 27 or GetShapeshiftFormID() == 29) then
		if GetInventoryItemID('player', 13) ~= 32481 and GetInventoryItemID('player', 14) ~= 32481 then
        	if GetInventoryItemID('player', 14) ~= 25653 then
				originTrinket = GetInventoryItemID('player', 14)
			end
			EquipItemByName(32481, 14)
		end
	elseif GetInventoryItemID('player', 14) == 25653 or GetInventoryItemID('player' ,14) == 32481 then
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
local function autoUnshift()
    local texture_str = "Interface\\TARGETINGFRAME\\UI-StatusBar"
    if InCombatLockdown() then return end
    if not autoUnshiftFrame then
        autoUnshiftFrame = CreateFrame("Button", "unshiftMacroButton", UIParent, "SecureActionButtonTemplate")
        autoUnshiftFrame:SetAttribute("type1", "macro")
        autoUnshiftFrame:SetAttribute("macrotext1",'/cancelform\n/script autoUnshiftFrame:Hide()')
        autoUnshiftFrame.bg = autoUnshiftFrame:CreateTexture(nil,"BACKGROUND", nil, -5)
        autoUnshiftFrame.bg:SetTexture(texture_str)
        autoUnshiftFrame.bg:SetVertexColor(0.2,0.1,0,0.0)
        autoUnshiftFrame.bg:SetAllPoints(autoUnshiftFrame)
        autoUnshiftFrame:SetParent(TaxiRouteMap)
        autoUnshiftFrame:SetAllPoints(TaxiRouteMap)
        autoUnshiftFrame:SetSize(320,350)
        autoUnshiftFrame:SetPoint("TOPLEFT",0,0)
        autoUnshiftFrame:EnableMouse(true)
        autoUnshiftFrame:SetFrameLevel(3)
        autoUnshiftFrame.tip = CreateFrame("GameTooltip","autoUnshiftTooltip",nil,"GameTooltipTemplate")
        autoUnshiftFrame.tip:SetAllPoints(autoUnshiftFrame)
        autoUnshiftFrame:SetScript("OnEnter",function(self)
            autoUnshiftFrame.tip:SetOwner(self,"ANCHOR_CURSOR")
            autoUnshiftFrame.tip:AddLine("点击飞行点地图可以解除变形")
            autoUnshiftFrame.tip:Show()
        end)
        autoUnshiftFrame:SetScript("OnLeave",function(self)
            autoUnshiftFrame.tip:Hide()
        end)
        return
    elseif GetShapeshiftFormID() then
        autoUnshiftFrame:Show()
        autoUnshiftFrame.tip:Show()
        return
    end
    autoUnshiftFrame:Hide()
    autoUnshiftFrame.tip:Hide()
end

--打开飞行点地图时自动下马
local function autoDismount()
    if InCombatLockdown() then return end
    if NumTaxiNodes() == 0 then return end
    if GetShapeshiftFormID() then
        autoUnshift()
    elseif not GetShapeshiftFormID() then
        autoUnshiftFrame:Hide()
        autoUnshiftFrame.tip:Hide()
    end
end

local autoflightmasterFrame = CreateFrame('frame')
autoflightmasterFrame:RegisterEvent('TAXIMAP_OPENED')
autoflightmasterFrame:RegisterEvent('UPDATE_SHAPESHIFT_FORM')
autoflightmasterFrame:SetScript('OnEvent', autoDismount)

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
	if not strongControl and enoughMana(m) and not getShiftGCD() and (rooted and (IsSpellInRange('爪击', 'target') ~= 1 or UnitLevel('target') == -1) or not enoughRage(r) and not enoughEnergy(e)) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--吃蓝，考虑延迟
function manapot(cost, name)
	if UnitLevel('target') ~= -1 or not ableShift() or enoughEnergywithNextTick(cost) or strongControl or (UnitPowerMax('player', 0) - getMana()) < 3000 or GetItemCooldown(GetItemInfoInstant(name)) > 0 then
		SetCVar('autoUnshift', 0)
	else
		SetCVar('autoUnshift', 1)
	end
end

--老款吃蓝，不考虑延迟
function manapotx(cost, name)
	if UnitLevel('target') ~= -1 or getShiftGCD() or enoughEnergywithNextTick(cost) or strongControl or (UnitPowerMax('player', 0) - getMana()) < 3000 or GetItemCooldown(GetItemInfoInstant(name)) > 0 then
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
