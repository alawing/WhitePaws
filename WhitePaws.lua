local addonName, wc = ...

--公共函数

--输出，自动解定身减速，考虑延迟
function dps(cost, mana)
	if not wc.strongControl and wc.enoughMana(mana) and (wc.needUnroot() or wc.ableShift() and not wc.enoughEnergywithNextTick(cost)) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--输出，自动解定身减速，考虑延迟和能量延迟
function dpsp(cost, mana)
	if not wc.strongControl and wc.enoughMana(mana) and (wc.needUnroot() or wc.ableShift() and not wc.enoughEnergywithNextTickwithDelay(cost)) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--输出，自动解定身减速，不考虑延迟
function dpsx(cost, mana)
	if not wc.strongControl and wc.enoughMana(mana) and (wc.needUnroot() or not wc.getShiftGCD() and not wc.enoughEnergywithNextTick(cost)) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--输出，自动解定身减速，考虑延迟，省蓝
function dpsl(cost, mana)
	if not wc.strongControl and wc.enoughMana(mana) and (wc.needUnroot() or wc.ableShift() and not wc.enoughEnergy(cost-20)) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--变身
function shift(r, e, m)
	r = r or 200
	e = e or 200
	if not wc.strongControl and wc.enoughMana(m) and not wc.getShiftGCD() and (wc.needUnroot() or wc.getRage() < r and wc.getEnergy() < e) then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--吃蓝，考虑延迟
function manapot(cost, name)
	if not wc.ableShift() or wc.enoughEnergywithNextTick(cost) or wc.strongControl or (UnitPowerMax('player', 0) - UnitPower('player', 0)) < 3000 or GetItemCooldown(GetItemInfoInstant(name)) > 0 or GetItemCount(name) == 0 then
		SetCVar('autoUnshift', 0)
	else
		SELECTED_CHAT_FRAME:AddMessage('吃蓝啦！')
		SetCVar('autoUnshift', 1)
	end
end

--老款吃蓝，不考虑延迟
function manapotx(cost, name)
	if wc.getShiftGCD() or wc.enoughEnergywithNextTick(cost) or wc.strongControl or (UnitPowerMax('player', 0) - UnitPower('player', 0)) < 3000 or GetItemCooldown(GetItemInfoInstant(name)) > 0 or GetItemCount(name) == 0 then
		SetCVar('autoUnshift', 0)
	else
		SetCVar('autoUnshift', 1)
	end
end

--吃红
--9634巨熊形态
function hppot()
	local u,n = IsUsableSpell(9634)
	if wc.getShiftGCD() or wc.strongControl or not u
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
