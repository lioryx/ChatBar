--------------------------------------------------
-- DropDown Menu
--------------------------------------------------

function ChatBar_DropDownOnLoad()
	ChatBar_InitializeDropDown(this);
end

function ChatBar_LoadDropDownMenu()
	if (not UIDROPDOWNMENU_MENU_VALUE) then
		return;
	end

	if (UIDROPDOWNMENU_MENU_VALUE == "ChatBarMenu") then
		ChatBar_CreateFrameMenu();
	elseif (UIDROPDOWNMENU_MENU_VALUE == "HiddenButtonsMenu") then
		ChatBar_CreateHiddenButtonsMenu();
	elseif (UIDROPDOWNMENU_MENU_VALUE == "AltArtMenu") then
		ChatBar_CreateAltArtMenu();
	else
		ChatBar_CreateButtonMenu();
	end
end

function ChatBar_CreateFrameMenu()
	local info = {};
	info.text = CHATBAR_MENU_MAIN_TITLE;
	info.notClickable = 1;
	info.isTitle = 1;
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info = {};
	info.text = CHATBAR_MENU_MAIN_VERTICAL;
	info.func = ChatBar_Toggle_VerticalButtonOrientationSlide;
	if (ChatBar_VerticalDisplay) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info = {};
	info.text = CHATBAR_MENU_MAIN_REVERSE;
	info.func = ChatBar_Toggle_AlternateButtonOrientationSlide;
	if (ChatBar_AlternateOrientation) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info = {};
	info.text = CHATBAR_MENU_MAIN_ALTART;
	info.hasArrow = 1;
	info.value = "AltArtMenu";
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info = {};
	info.text = CHATBAR_MENU_MAIN_TEXTONBUTTONS;
	info.func = ChatBar_Toggle_TextOrientation;
	info.keepShownOnClick = 1;
	if (ChatBar_TextOnButtonDisplay) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info = {};
	info.text = CHATBAR_MENU_MAIN_SHOWTEXT;
	info.func = ChatBar_Toggle_ButtonText;
	info.keepShownOnClick = 1;
	if (ChatBar_ButtonText) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info = {};
	info.text = CHATBAR_MENU_MAIN_CHANNELID;
	info.func = ChatBar_Toggle_TextChannelNumbers;
	info.keepShownOnClick = 1;
	if (ChatBar_TextChannelNumbers) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info = {};
	info.text = CHATBAR_MENU_MAIN_BUTTONFLASHING;
	info.func = ChatBar_Toggle_ButtonFlashing;
	info.keepShownOnClick = 1;
	if (ChatBar_ButtonFlashing) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info = {};
	info.text = CHATBAR_MENU_MAIN_BARBORDER;
	info.func = ChatBar_Toggle_BarBorder;
	info.keepShownOnClick = 1;
	if (ChatBar_BarBorder) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	local size = 0;
	for _, v in pairs(ChatBar_HiddenButtons) do
		if (v) then
			size = size + 1;
		end
	end
	if (size > 0) then
		info = {};
		info.text = CHATBAR_MENU_MAIN_HIDDENBUTTONS;
		info.hasArrow = 1;
		info.func = nil;
		info.value = "HiddenButtonsMenu";
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end

	info = {};
	info.text = CHATBAR_MENU_MAIN_RESET;
	info.func = ChatBar_Reset;
	if (not ChatBarFrame:IsUserPlaced()) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
end

function ChatBar_CreateHiddenButtonsMenu()
	for k, v in ChatBar_HiddenButtons do
		local info = {};
		local ctype = k;
		info.text = format(CHATBAR_MENU_SHOW_BUTTON, k);
		info.func = function()
			ChatBar_HiddenButtons[ctype] = nil;
			ChatBarFrame.count = 0;
		end;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end
end

function ChatBar_CreateAltArtMenu()
	for k, v in pairs(ChatBar_AltArtDirs) do
		local info = {};
		local skinIndex = k;
		info.text = getglobal("CHATBAR_SKIN" .. k);
		info.func = function()
			ChatBar_AltArt = skinIndex;
			ChatBar_UpdateArt();
		end;
		if (ChatBar_AltArt == k) then
			info.checked = 1;
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end
end

function ChatBar_CreateButtonMenu()
	local buttonInfo = ChatBar_ChatTypes[UIDROPDOWNMENU_MENU_VALUE];
	local buttonHeader = buttonInfo.type;
	local info = {};
	local chatType, channelIndex;

	info.text = buttonInfo.text();
	info.notClickable = 1;
	info.isTitle = 1;
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	chatType, channelIndex = string.gfind(buttonHeader, "([^%d]*)([%d]+)$")();
	if (channelIndex) then
		local channelNum, channelName = GetChannelName(tonumber(channelIndex));

		info = {};
		info.text = CHATBAR_MENU_CHANNEL_LEAVE;
		info.func = function() LeaveChannelByName(channelNum); end;
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

		info = {};
		info.text = CHATBAR_MENU_CHANNEL_LIST;
		info.func = function() ListChannelByName(channelNum); end;
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

		local channelShortName = ChatBar_GetFirstWord(channelName);
		info = {};
		info.text = format(CHATBAR_MENU_HIDE_BUTTON, channelShortName);
		info.func = function()
			ChatBar_HiddenButtons[channelShortName] = true;
			ChatBarFrame.count = 0;
		end;
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	else
		local localizedChatType = buttonInfo.text();
		info = {};
		info.text = format(CHATBAR_MENU_HIDE_BUTTON, localizedChatType);
		info.func = function()
			ChatBar_HiddenButtons[localizedChatType] = true;
			ChatBarFrame.count = 0;
		end;
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end

	if (buttonHeader == "WHISPER") then
		local chatFrame = SELECTED_DOCK_FRAME;
		if (not chatFrame) then
			chatFrame = DEFAULT_CHAT_FRAME;
		end

		info = {};
		info.text = CHATBAR_MENU_WHISPER_REPLY;
		info.func = function()
			ChatFrame_ReplyTell(chatFrame);
		end;
		if (ChatEdit_GetLastTellTarget(ChatFrameEditBox) == "") then
			info.disabled = 1;
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

		info = {};
		info.text = CHATBAR_MENU_WHISPER_RETELL;
		info.func = function()
			ChatFrame_SendTell(ChatBar_LastTell, chatFrame);
		end;
		if (not ChatBar_LastTell) then
			info.disabled = 1;
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end

	if (chatType or ChatTypeInfo[buttonHeader]) then
		info = {};
		if (chatType) then
			info.text = CHATBAR_MENU_CHANNEL_STICKY;
		else
			info.text = CHATBAR_MENU_STICKY;
			chatType = buttonHeader;
		end
		info.func = function()
			if (ChatTypeInfo[chatType].sticky == 1) then
				ChatTypeInfo[chatType].sticky = 0;
				ChatBar_StoredStickies[chatType] = 0;
			else
				ChatTypeInfo[chatType].sticky = 1;
				ChatBar_StoredStickies[chatType] = 1;
			end
		end;
		if (ChatTypeInfo[chatType].sticky == 1) then
			info.checked = 1;
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end
end