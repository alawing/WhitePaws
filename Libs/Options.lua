local addonName, wc = ...

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

local panel = CreateFrame("FRAME")
panel.name = "WhitePaws"
InterfaceOptions_AddCategory(panel)

local alertButton = CreateFrame("Button", "alertButton_GlobalName", panel, "UIPanelButtonTemplate")
alertButton:SetPoint("TOPLEFT", 100, -30)
alertButton:SetSize(120 ,22)
alertButton_GlobalNameText:SetText("开关被控通报")
alertButton.tooltip = "开关被控通报功能"
alertButton:SetScript("OnClick", 
  function()
    --do stuff
    WhitePaws_Command('alert')
  end
)

local bgButton = CreateFrame("Button", "bgButton_GlobalName", panel, "UIPanelButtonTemplate")
bgButton:SetPoint("TOPLEFT", 100, -60)
bgButton:SetSize(120 ,22)
bgButton_GlobalNameText:SetText("副本/战场马鞭")
bgButton.tooltip = "开关副本/战场内自动马鞭"
bgButton:SetScript("OnClick", 
  function()
    --do stuff
    WhitePaws_Command('bg')
  end
)

local speedButton = CreateFrame("Button", "speedButton_GlobalName", panel, "UIPanelButtonTemplate")
speedButton:SetPoint("TOPLEFT", 100, -90)
speedButton:SetSize(120 ,22)
speedButton_GlobalNameText:SetText("移动速度显示")
speedButton.tooltip = "开关小地图右下方移动速度显示框体"
speedButton:SetScript("OnClick", 
  function()
    --do stuff
    WhitePaws_Command('speed')
  end
)