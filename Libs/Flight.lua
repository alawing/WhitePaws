local addonName, wc = ...

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
local Shapeshifted, FlightPointButton

function wc.autoUnshiftonTaxi()
    local texture_str = 'Interface\\TARGETINGFRAME\\UI-StatusBar'
    if InCombatLockdown() then return end
    if not wc.autoUnshiftFrame then
        wc.autoUnshiftFrame = CreateFrame('Button', 'unshiftMacroButton', UIParent, 'SecureActionButtonTemplate')
        wc.autoUnshiftFrame:SetAttribute('type1', 'macro')
        wc.autoUnshiftFrame:SetAttribute("macrotext1",'/cancelform\n/script autoCancelShapeshift()\n/script TakeTaxiNode(FlightPoint)')
        wc.autoUnshiftFrame:SetParent(TaxiRouteMap)
        wc.autoUnshiftFrame:SetAllPoints(TaxiRouteMap)
        wc.autoUnshiftFrame:SetSize(16,16)
        wc.autoUnshiftFrame:SetPoint('TOPLEFT',0,0)
        wc.autoUnshiftFrame:EnableMouse(false)
        wc.autoUnshiftFrame:SetFrameLevel(3)
        wc.autoUnshiftFrame:Show()
        wc.autoUnshiftFrame:SetScript("OnUpdate",function(self,motion)
        	autoCancelShapeshiftForm()
        	FlightPoint = FlightPoint or 0
        	if not FlightPointButton then return end
        	if (Shapeshifted or GetShapeshiftFormID()) and MouseIsOver(FlightPointButton) then
            		TaxiNodeOnButtonEnter(FlightPointButton)
			FlightPointButton:LockHighlight()
            		wc.autoUnshiftFrame:EnableMouse(true)
        	end
        	if (not Shapeshifted and not GetShapeshiftFormID()) or (not MouseIsOver(FlightPointButton)) then
            		wc.autoUnshiftFrame:EnableMouse(false)
			FlightPointButton:UnlockHighlight()
        	end
    	end)
    	wc.autoUnshiftFrame:SetScript("OnLeave",function()
        	wc.autoUnshiftFrame:EnableMouse(false)
        	TaxiNodeOnButtonLeave(FlightPointButton)
		FlightPointButton:UnlockHighlight()
    	end)
	end
end

--月光林地德鲁伊免费飞行点自动下马
local function moongladeAutoDismount()
    	if GossipFrameNpcNameText:GetText() == "希尔瓦·菲纳雯斯" or GossipFrameNpcNameText:GetText() == "布瑟恩·草风" then
        	Dismount()
        	SelectGossipOption(1)
	elseif GossipFrameNpcNameText:GetText() == "时间管理者" then
		if not wc.GossipUnshiftFrame then
		    wc.GossipUnshiftFrame = CreateFrame('Button', 'unshiftMacroButton2', UIParent, 'SecureActionButtonTemplate')
		    wc.GossipUnshiftFrame:SetAttribute('type1', 'macro')
		    wc.GossipUnshiftFrame:SetAttribute("macrotext1",'/cancelform\n/script autoCancelShapeshift()\n/script SelectGossipOption(1)')
		    wc.GossipUnshiftFrame:SetParent(GossipGreetingScrollChildFrame)
		    wc.GossipUnshiftFrame:SetAllPoints(GossipGreetingScrollChildFrame)
		    wc.GossipUnshiftFrame:SetSize(16,16)
		    wc.GossipUnshiftFrame:SetPoint('TOPLEFT',0,0)
		    wc.GossipUnshiftFrame:EnableMouse(false)
		    wc.GossipUnshiftFrame:SetFrameLevel(6)
		    wc.GossipUnshiftFrame:Show()
		    wc.GossipUnshiftFrame:SetScript("OnUpdate",function(self,motion)
			autoCancelShapeshiftForm()
			if (Shapeshifted or GetShapeshiftFormID()) and MouseIsOver(GossipTitleButton1) then
				GossipTitleButton1:LockHighlight()
				wc.GossipUnshiftFrame:EnableMouse(true)
			end
			if (not Shapeshifted and not GetShapeshiftFormID()) or (not MouseIsOver(GossipTitleButton1)) then
				wc.GossipUnshiftFrame:EnableMouse(false)
				GossipTitleButton1:UnlockHighlight()
			end
		    end)
		    wc.GossipUnshiftFrame:SetScript("OnLeave",function()
			wc.GossipUnshiftFrame:EnableMouse(false)
			GossipTitleButton1:UnlockHighlight()
		    end)
		end
    	else
        	GossipTitleButton_OnClick(self, button)
    	end
end

GossipTitleButton1:SetScript("OnClick",moongladeAutoDismount)

--解除德鲁伊变形
function autoCancelShapeshiftForm()
    if InCombatLockdown() then return end
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
    if NumTaxiNodes() == 0 then return end
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
function wc.showSpeed()
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
showSpeedFrame:SetScript('OnEvent',wc.showSpeed)
