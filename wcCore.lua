local addonName, wc = ...

--判断控制
local bossControl = false

local function GetControls(self, event, unit, ...)
	wc.strongControl = false
	wc.rooted = false

	if event == 'PLAYER_CONTROL_LOST' then
		if wcAlert then
			SELECTED_CHAT_FRAME:AddMessage('哟失去控制了')
		end
		return
	end
	if event == 'PLAYER_CONTROL_GAINED' then
		if wcAlert then
			SELECTED_CHAT_FRAME:AddMessage('哟又能控制了')
		end
		return
	end
	if event == 'UNIT_AURA' then
		if unit == 'player' then
			if wc.getAura(33652, 36449) then
				print(bossControl)
				print(wc.strongControl)
				if not bossControl then
					wc.strongControl = true
					bossControl = true
					if wcAlert then
						SendChatMessage('BOSS强控，啥也做不了，大家都一样要忍，所以问题不大', 'EMOTE')
					end
				end
			elseif bossControl then
				wc.strongControl = false
				bossControl = false
				if wcAlert then
					SendChatMessage('BOSS强控结束了，你长吁了一口气，并说道问题不大', 'EMOTE')
				end
			end
		end
		return
	end
	local eventIndex = C_LossOfControl.GetActiveLossOfControlDataCount()
	while (eventIndex > 0) do
		local locType = C_LossOfControl.GetActiveLossOfControlData(eventIndex).locType
		if locType == 'ROOT' or locType == 'CONFUSE' and C_LossOfControl.GetActiveLossOfControlData(eventIndex).displayText == '变形' then
			wc.rooted = true
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
			wc.strongControl = true
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
controlFrame:RegisterEvent('UNIT_AURA') -- the player current target recently gained or lost an control
controlFrame:SetScript('OnEvent', GetControls)

local function WhitePaws_Command(arg1)
	if arg1 then arg1 = strlower(arg1) end
	if arg1 == 'alert' then
		wcAlert = not wcAlert
	elseif arg1 == 'bg' then
		wcIsInInstance = not wcIsInInstance
	elseif arg1 == 'speed' then
		wcSpeed = not wcSpeed
		wc.showSpeed()
	end
	SELECTED_CHAT_FRAME:AddMessage((wcAlert and '[|cff00ff00开|r]' or '[|cffff0000关|r]')..'/wc alert 开关被控通告功能',255,255,0)
	SELECTED_CHAT_FRAME:AddMessage((wcIsInInstance and '[|cff00ff00开|r]' or '[|cffff0000关|r]')..'/wc bg 开关副本/战场内自动马鞭功能',255,255,0)
	SELECTED_CHAT_FRAME:AddMessage((wcSpeed and '[|cff00ff00开|r]' or '[|cffff0000关|r]')..'/wc speed 开关小地图右下方移动速度显示框体',255,255,0)
	SELECTED_CHAT_FRAME:AddMessage('/wc 查看命令帮助',255,255,0)
end

SlashCmdList['WHITEPAWS'] = WhitePaws_Command
SLASH_WHITEPAWS1 = '/whitepaws'
SLASH_WHITEPAWS2 = '/wc'

local function wcInit()
	wcAlert = wcAlert or false
	wcIsInInstance = wcIsInInstance or false
	wcSpeed = wcSpeed or false
	local title = select(2, GetAddOnInfo('whitepaws'))
	SELECTED_CHAT_FRAME:AddMessage('---------------------')
	SELECTED_CHAT_FRAME:AddMessage('欢迎使用'..title,255,255,0)
	SELECTED_CHAT_FRAME:AddMessage('---------------------')
	WhitePaws_Command()
	wc.autoUnshiftonTaxi()
	wc.autoUnshiftFrame:Show()
	wc.autoUnshiftFrame:EnableMouse(false)
end

local initFrame = CreateFrame('Frame')

initFrame:RegisterEvent('PLAYER_LOGIN')
initFrame:SetScript('OnEvent', wcInit)

function wc.getLatency()
	return select(4, GetNetStats()) / 1000
end

--变形条件
function wc.getShiftGCD()
	return GetSpellCooldown(768) ~= 0
end

function wc.ableShift()
	local cd = 0
	if wc.getShiftGCD() then
		cd = select(2, GetSpellCooldown(768)) + GetSpellCooldown(768) - GetTime()
	end
	return cd <= wc.getLatency()
end

function wc.getRage()
	if GetShapeshiftFormID() ~= 5 and GetShapeshiftFormID() ~= 8  then
		return 0
	end
	return UnitPower('player', 1)
end

function wc.getEnergy()
	if GetShapeshiftFormID() ~= 1 then
		return 0
	end
	return UnitPower('player', 3)
end

--格鲁尔石化33652 玛瑟里顿碎片36449 瓦斯琪纠缠38316
function wc.getAura(...)
	local auras = {}, i, v
	for i, v in ipairs{...} do
		auras[v] = true;
	end
	i = 1
	while UnitAura('player', i) do
		if auras[select(1, UnitAura('player', i))] or auras[select(10, UnitAura('player', i))] then
			return true
		end
		i = i + 1
	end
	return false
end

local lastPower = UnitPower('player', 3)
local notNormalTick = GetTime()
--回能
local function calcTick(self, event, unit, type)
	if (event == 'COMBAT_LOG_EVENT_UNFILTERED') then
		local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
		if subevent == 'SPELL_ENERGIZE' and sourceName ==  GetUnitName('player') then
			notNormalTick = GetTime()
			lastPower = UnitPower('player', 3)
		end
	elseif (unit == 'player' and type == 'ENERGY') then
		if UnitPower('player', 3) > lastPower and notNormalTick ~= GetTime() then
			LastTick = GetTime()
		end
		lastPower = UnitPower('player', 3)
	end
end

tickframe = CreateFrame("Frame", nil)
tickframe:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
tickframe:RegisterEvent('UNIT_POWER_FREQUENT')
tickframe:SetScript('OnEvent', calcTick)

function wc.enoughMana(cost)
	if cost == nil then
		cost = GetSpellPowerCost(768)[1].cost
	end
	return UnitPower('player', 0) >= cost
end

function wc.enoughEnergy(cost)
	if wc.clearcasting then
		return true
	end
	return wc.getEnergy() >= cost
end

function wc.enoughEnergywithNextTickwithDelay(cost)
	local nextTick = 2 - mod(GetTime() - LastTick, 2)
	if wc.clearcasting then
		return true
	end
	local e = wc.getEnergy()
	if nextTick - wc.getLatency() <= 0 then e = e + 20 end
	if e >= cost then return true end
	if e + 20 >= cost and nextTick - wc.getLatency() <= 1.5 then return true end
	return false
end

function wc.enoughEnergywithNextTick(cost)
	local nextTick = 2 - mod(GetTime() - LastTick, 2)
	if wc.enoughEnergy(cost) then return true end
	local e = wc.getEnergy()
	if e + 20 >= cost and nextTick <= 1.5 then return true end
	return false
end

function wc.needUnroot()
	--打得着并且不是瓦斯琪纠缠
	if IsSpellInRange('爪击', 'target') == 1 and not wc.getAura(38316) then
		return false
	--定身或者减速了
	elseif wc.rooted then return true
	elseif select(2, GetUnitSpeed('player')) < 7 and not IsStealthed() then return true
	else return false end
end
