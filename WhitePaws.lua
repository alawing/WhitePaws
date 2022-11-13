local addonName, wc = ...

--公共函数

--输出，自动解定身减速，考虑延迟和能量延迟，tbc有用，wlk弃用
function dps(cost, mana)
	if not wc.strongControl and wc.enoughMana(mana) and (wc.needUnroot() or wc.ableShift() and not wc.enoughEnergywithNextTickwithDelay(cost)) then
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

--吃红，tbc有用，wlk弃用
--9634巨熊形态
function hppot()
	local u,n = IsUsableSpell(9634)
	if wc.getShiftGCD() or wc.strongControl or not u
		then SetCVar('autoUnshift', 0)
	else
		SetCVar('autoUnshift', 1)
	end
end

--变形金刚-变熊
function bxjgx(e)
	if not wc.strongControl and wc.enoughMana() and not wc.getShiftGCD() and not wc.enoughEnergy(e) and not wc.getBuff(50334) and wc.getBuffTime(52610) > 5 and wc.getComboPoint() < 4 then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--变形金刚-激怒变熊
-- 52610 野蛮咆哮
-- 50213 猛虎之怒
-- 5229 激怒
-- 50334 狂暴
function jnbxjgx(e)
	if not wc.strongControl and wc.enoughMana() and not wc.getShiftGCD() and not wc.enoughEnergy(e) and not wc.getBuff(50334) and GetSpellCooldown(5229) == 0 then
		SetCVar('autoUnshift', 1)
	else
		SetCVar('autoUnshift', 0)
	end
end

--变形金刚-变猫
function bxjgm(e)
	if not wc.strongControl and wc.enoughMana() and (wc.needUnroot() or (wc.enoughEnergy(e) and wc.getRage() < 20)) then
		if not wc.getShiftGCD() then
			SetCVar('autoUnshift', 1)
		else
			cancelQueue = 1
			SetCVar('autoUnshift', 0)
		end
	else
		SetCVar('autoUnshift', 0)
	end
end

--结束
function wcEnd()
	if cancelQueue == 1 then
		SpellCancelQueuedSpell()
		cancelQueue = 0
	end
	SetCVar('autoUnshift', 1)
	UIErrorsFrame:Clear()
end
