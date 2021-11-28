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

local myCheckButton = CreateFrame("CheckButton", "myCheckButton_GlobalName", panel, "ChatConfigCheckButtonTemplate")
myCheckButton:SetPoint("TOPLEFT", 200, -65)
myCheckButton_GlobalNameText:SetText("CheckBox Name")
myCheckButton.tooltip = "This is where you place MouseOver Text."
myCheckButton:SetScript("OnClick", 
  function()
    --do stuff
    WhitePaws_Command('alert')
  end
)