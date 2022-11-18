local addonName, wc = ...

--判断控制
local bossControl = false

local function GetControls(self, event, unit, ...)
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
			if wc.getDebuff(33652, 36449) then
				if not bossControl then
					wc.strongControl = true
					bossControl = true
					if wcAlert then
						SendChatMessage('被BOSS强控了，啥也做不了，大家都一样要忍，所以问题不大', 'EMOTE')
					end
				end
			elseif bossControl then
				wc.strongControl = false
				bossControl = false
				if wcAlert then
					SendChatMessage('被BOSS的强控结束了，你长吁了一口气，并说道问题不大', 'EMOTE')
				end
			end
		end
		return
	end
	wc.strongControl = false
	wc.rooted = false
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

function wc.getLatency()
	return select(4, GetNetStats()) / 1000 + 0.025
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
	return UnitPower('player', 3)
end

--狂暴50334 激怒5229 猛虎9846 50212 50213
function wc.getBuff(...)
	local buffs = {}, i, v
	for i, v in ipairs{...} do
		buffs[v] = true;
	end
	i = 1
	while UnitBuff('player', i) do
		if buffs[select(1, UnitBuff('player', i))] or buffs[select(10, UnitBuff('player', i))] then
			return true
		end
		i = i + 1
	end
	return false
end

--狂暴50334 激怒5229 猛虎9846 50212 50213
function wc.getBuffTime(...)
	local buffs = {}, i, v
	for i, v in ipairs{...} do
		buffs[v] = true;
	end
	i = 1
	while UnitBuff('player', i) do
		if buffs[select(1, UnitBuff('player', i))] or buffs[select(10, UnitBuff('player', i))] then
			local _, _, _, _, duration, expirationTime = UnitBuff("player", i)
     		return expirationTime - GetTime()
		end
		i = i + 1
	end
	return 0
end

function wc.getDebuff(...)
	local debuffs = {}, i, v
	for i, v in ipairs{...} do
		debuffs[v] = true;
	end
	i = 1
	while UnitDebuff('player', i) do
		if debuffs[select(1, UnitDebuff('player', i))] or debuffs[select(10, UnitDebuff('player', i))] then
			return true
		end
		i = i + 1
	end
	return false
end

function wc.enoughMana(cost)
	if cost == nil then
		cost = GetSpellPowerCost(768)[1].cost
	end
	return UnitPower('player', 0) >= cost
end

-- 清晰预兆 16870
-- 猛虎 50213

function wc.enoughEnergy(cost)
	if (wc.getBuff(16870) and wc.getRage() < 25) or wc.getCoolDown(50213) < 2 then
		return true
	end
	return wc.getEnergy() >= cost
end

function wc.needUnroot()
	--打得着并且不是瓦斯琪纠缠
	if IsSpellInRange('爪击', 'target') == 1 and not wc.getDebuff(38316) then
		return false
	--定身或者减速了
	elseif wc.rooted then return true
	elseif select(2, GetUnitSpeed('player')) < 7 and not IsStealthed() then return true
	else return false end
	--todo dazed 眩晕 震荡射击
end

function wc.getComboPoint()
	return GetComboPoints('player','target')
end

function wc.getCoolDown(spellID)
	local cooldown, duration = GetSpellCooldown(spellID)
	if cooldown == 0 then
		return cooldown
	end
	return cooldown + duration - GetTime()
end
