--------------------------------------------------
-- Options Panel
--------------------------------------------------

local function ChatBar_CreateOptionsCheckButton(parent, name, labelText)
	local button = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate");
	button:SetWidth(24);
	button:SetHeight(24);
	getglobal(name .. "Text"):SetText(labelText);
	return button;
end

local function ChatBar_CreateOptionsActionButton(parent, name, width, labelText)
	local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate");
	button:SetWidth(width);
	button:SetHeight(22);
	button:SetText(labelText);
	return button;
end

local function ChatBar_CreateOptionsValueRow(parent, name, labelText)
	local row = CreateFrame("Frame", name, parent);
	row:SetWidth(268);
	row:SetHeight(22);

	row.Label = row:CreateFontString(name .. "Label", "OVERLAY", "GameFontNormalSmall");
	row.Label:SetPoint("LEFT", row, "LEFT", 0, 0);
	row.Label:SetText(labelText);

	row.Plus = ChatBar_CreateOptionsActionButton(row, name .. "Plus", 24, "+");
	row.Plus:SetPoint("RIGHT", row, "RIGHT", 0, 0);

	row.Value = row:CreateFontString(name .. "Value", "OVERLAY", "GameFontHighlightSmall");
	row.Value:SetWidth(28);
	row.Value:SetHeight(16);
	row.Value:SetJustifyH("CENTER");
	row.Value:SetPoint("RIGHT", row.Plus, "LEFT", -8, 0);

	row.Minus = ChatBar_CreateOptionsActionButton(row, name .. "Minus", 24, "-");
	row.Minus:SetPoint("RIGHT", row.Value, "LEFT", -8, 0);

	return row;
end

function ChatBar_OptionsCheckButton_OnClick()
	if (this.optionFunc) then
		this.optionFunc();
	end
	ChatBar_UpdateOptionsPanel();
end

function ChatBar_OptionsActionButton_OnClick()
	if (this.actionFunc) then
		this.actionFunc();
	end
	ChatBar_UpdateOptionsPanel();
end

function ChatBar_OptionsTab_OnClick()
	if (this.tabKey) then
		ChatBarOptionsPanel.currentTab = this.tabKey;
		ChatBar_UpdateOptionsPanel();
	end
end

local function ChatBar_AltArtDropDown_OnClick()
	ChatBar_AltArt = this.value;
	ChatBar_UpdateArt();
	ChatBar_UpdateOptionsPanel();
end

local function ChatBar_InitializeAltArtDropDown()
	local info;
	local i;

	for i = 1, table.getn(ChatBar_AltArtDirs) do
		info = {};
		info.text = getglobal("CHATBAR_SKIN" .. i) or ChatBar_AltArtDirs[i];
		info.value = i;
		info.func = ChatBar_AltArtDropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

local function ChatBar_GetVisibilityEntries()
	local entries = {};
	local chatTypeInfo;
	local label;
	local key;
	local i = 1;
	local _, _, channelIndex;
	local channelNum, channelName;

	while (ChatBar_ChatTypes[i]) do
		chatTypeInfo = ChatBar_ChatTypes[i];
		_, _, channelIndex = string.find(chatTypeInfo.type, "^CHANNEL(%d+)$");
		label = nil;
		key = nil;

		if (channelIndex) then
			channelNum, channelName = GetChannelName(tonumber(channelIndex));
			if (channelNum ~= 0) and (channelName) and (channelName ~= "") then
				label = chatTypeInfo.text();
				key = ChatBar_GetFirstWord(channelName);
			end
		else
			label = chatTypeInfo.text();
			key = label;
		end

		if (label) and (label ~= "") and (key) and (key ~= "") then
			table.insert(entries, {
				label = label,
				key = key,
			});
		end

		i = i + 1;
	end

	return entries;
end

function ChatBar_ChannelVisibilityCheck_OnClick()
	if (not this.visibilityKey) then
		return;
	end

	if (this:GetChecked()) then
		ChatBar_HiddenButtons[this.visibilityKey] = nil;
	else
		ChatBar_HiddenButtons[this.visibilityKey] = true;
	end

	ChatBar_UpdateButtons();
	ChatBar_UpdateOptionsPanel();
end

local function ChatBar_SetAllChannelVisibility(showButtons)
	local entries = ChatBar_GetVisibilityEntries();
	local i;

	for i = 1, table.getn(entries) do
		if (showButtons) then
			ChatBar_HiddenButtons[entries[i].key] = nil;
		else
			ChatBar_HiddenButtons[entries[i].key] = true;
		end
	end

	ChatBar_UpdateButtons();
	ChatBar_UpdateOptionsPanel();
end

function ChatBar_SelectAllChannels()
	ChatBar_SetAllChannelVisibility(true);
end

function ChatBar_ClearAllChannels()
	ChatBar_SetAllChannelVisibility(false);
end

local function ChatBar_UpdateChannelsPage(panel)
	local entries = ChatBar_GetVisibilityEntries();
	local entryCount = table.getn(entries);
	local contentHeight = 8;
	local maxScroll;
	local currentScroll;
	local i;

	for i = 1, CHAT_BAR_MAX_BUTTONS do
		local checkButton = panel.ChannelEntries[i];
		local entry = entries[i];
		local textRegion = getglobal(checkButton:GetName() .. "Text");

		if (entry) then
			checkButton.visibilityKey = entry.key;
			textRegion:SetText(entry.label);
			checkButton:SetChecked(not ChatBar_HiddenButtons[entry.key]);
			checkButton:Show();
			contentHeight = 8 + (i * 26);
		else
			checkButton.visibilityKey = nil;
			checkButton:Hide();
		end
	end

	if (entryCount == 0) then
		panel.ChannelEmptyText:Show();
		contentHeight = panel.ChannelScrollFrame:GetHeight();
	else
		panel.ChannelEmptyText:Hide();
	end

	if (contentHeight < panel.ChannelScrollFrame:GetHeight()) then
		contentHeight = panel.ChannelScrollFrame:GetHeight();
	end
	panel.ChannelScrollChild:SetHeight(contentHeight);

	currentScroll = panel.ChannelScrollFrame:GetVerticalScroll();
	maxScroll = contentHeight - panel.ChannelScrollFrame:GetHeight();
	if (maxScroll < 0) then
		maxScroll = 0;
	end
	if (currentScroll > maxScroll) then
		panel.ChannelScrollFrame:SetVerticalScroll(maxScroll);
	end
end

local function ChatBar_RefreshButtonLayout()
	ChatBar_InitializeSizeSettings();
	ChatBar_UpdateButtonSizes();
	ChatBar_UpdateButtonOrientation();
	ChatBar_UpdateButtons();
end

local function ChatBar_AdjustButtonSize(delta)
	local newValue;
	ChatBar_InitializeSizeSettings();
	newValue = ChatBar_NormalizeSizeSetting(ChatBar_ButtonSize + delta, CHAT_BAR_BUTTON_SIZE,
		CHAT_BAR_BUTTON_SIZE_MIN, CHAT_BAR_BUTTON_SIZE_MAX, CHAT_BAR_BUTTON_SIZE_STEP);
	if (newValue ~= ChatBar_ButtonSize) then
		ChatBar_ButtonSize = newValue;
		ChatBar_RefreshButtonLayout();
	end
end

local function ChatBar_AdjustButtonTextSize(delta)
	local newValue;
	ChatBar_InitializeSizeSettings();
	newValue = ChatBar_NormalizeSizeSetting(ChatBar_ButtonTextSize + delta, CHAT_BAR_BUTTON_TEXT_SIZE,
		CHAT_BAR_BUTTON_TEXT_SIZE_MIN, CHAT_BAR_BUTTON_TEXT_SIZE_MAX, CHAT_BAR_BUTTON_TEXT_SIZE_STEP);
	if (newValue ~= ChatBar_ButtonTextSize) then
		ChatBar_ButtonTextSize = newValue;
		ChatBar_RefreshButtonLayout();
	end
end

local function ChatBar_AdjustButtonPadding(delta)
	local newValue;
	ChatBar_InitializeSizeSettings();
	newValue = ChatBar_NormalizeSizeSetting(ChatBar_ButtonPadding + delta, CHAT_BAR_BUTTON_PADDING,
		CHAT_BAR_BUTTON_PADDING_MIN, CHAT_BAR_BUTTON_PADDING_MAX, CHAT_BAR_BUTTON_PADDING_STEP);
	if (newValue ~= ChatBar_ButtonPadding) then
		ChatBar_ButtonPadding = newValue;
		ChatBar_RefreshButtonLayout();
	end
end

function ChatBar_DecreaseButtonSize()
	ChatBar_AdjustButtonSize(-CHAT_BAR_BUTTON_SIZE_STEP);
end

function ChatBar_IncreaseButtonSize()
	ChatBar_AdjustButtonSize(CHAT_BAR_BUTTON_SIZE_STEP);
end

function ChatBar_DecreaseButtonTextSize()
	ChatBar_AdjustButtonTextSize(-CHAT_BAR_BUTTON_TEXT_SIZE_STEP);
end

function ChatBar_IncreaseButtonTextSize()
	ChatBar_AdjustButtonTextSize(CHAT_BAR_BUTTON_TEXT_SIZE_STEP);
end

function ChatBar_DecreaseButtonPadding()
	ChatBar_AdjustButtonPadding(-CHAT_BAR_BUTTON_PADDING_STEP);
end

function ChatBar_IncreaseButtonPadding()
	ChatBar_AdjustButtonPadding(CHAT_BAR_BUTTON_PADDING_STEP);
end

function ChatBar_UpdateOptionsPanel()
	if (not ChatBarOptionsPanel) then
		return;
	end

	local panel = ChatBarOptionsPanel;
	local i;
	local currentTab;

	ChatBar_InitializeSizeSettings();
	currentTab = panel.currentTab or "general";
	panel.currentTab = currentTab;

	if (currentTab == "channels") then
		panel.GeneralPage:Hide();
		panel.ChannelsPage:Show();
		panel.GeneralTab:Enable();
		panel.ChannelsTab:Disable();
	else
		panel.GeneralPage:Show();
		panel.ChannelsPage:Hide();
		panel.GeneralTab:Disable();
		panel.ChannelsTab:Enable();
	end

	panel.ButtonSizeRow.Value:SetText(ChatBar_ButtonSize);
	panel.ButtonTextSizeRow.Value:SetText(ChatBar_ButtonTextSize);
	panel.ButtonPaddingRow.Value:SetText(ChatBar_ButtonPadding);
	if (ChatBar_ButtonSize <= CHAT_BAR_BUTTON_SIZE_MIN) then
		panel.ButtonSizeRow.Minus:Disable();
	else
		panel.ButtonSizeRow.Minus:Enable();
	end
	if (ChatBar_ButtonSize >= CHAT_BAR_BUTTON_SIZE_MAX) then
		panel.ButtonSizeRow.Plus:Disable();
	else
		panel.ButtonSizeRow.Plus:Enable();
	end
	if (ChatBar_ButtonTextSize <= CHAT_BAR_BUTTON_TEXT_SIZE_MIN) then
		panel.ButtonTextSizeRow.Minus:Disable();
	else
		panel.ButtonTextSizeRow.Minus:Enable();
	end
	if (ChatBar_ButtonTextSize >= CHAT_BAR_BUTTON_TEXT_SIZE_MAX) then
		panel.ButtonTextSizeRow.Plus:Disable();
	else
		panel.ButtonTextSizeRow.Plus:Enable();
	end
	if (ChatBar_ButtonPadding <= CHAT_BAR_BUTTON_PADDING_MIN) then
		panel.ButtonPaddingRow.Minus:Disable();
	else
		panel.ButtonPaddingRow.Minus:Enable();
	end
	if (ChatBar_ButtonPadding >= CHAT_BAR_BUTTON_PADDING_MAX) then
		panel.ButtonPaddingRow.Plus:Disable();
	else
		panel.ButtonPaddingRow.Plus:Enable();
	end
	panel.VerticalButtons:SetChecked(ChatBar_VerticalDisplay);
	panel.ReverseButtons:SetChecked(ChatBar_AlternateOrientation);
	panel.TextOnButtons:SetChecked(ChatBar_TextOnButtonDisplay);
	panel.ShowButtonText:SetChecked(ChatBar_ButtonText);
	panel.ChannelNumbers:SetChecked(ChatBar_TextChannelNumbers);
	panel.ButtonFlashing:SetChecked(ChatBar_ButtonFlashing);
	panel.BarBorder:SetChecked(ChatBar_BarBorder);
	if (type(ChatBar_AltArt) ~= "number") or (not ChatBar_AltArtDirs[ChatBar_AltArt]) then
		ChatBar_AltArt = 1;
	end
	UIDropDownMenu_SetSelectedID(panel.AltArtDropDown, ChatBar_AltArt);
	UIDropDownMenu_SetText(getglobal("CHATBAR_SKIN" .. ChatBar_AltArt) or ChatBar_AltArtDirs[ChatBar_AltArt], panel.AltArtDropDown);

	panel.ResetButton:SetText(CHATBAR_MENU_MAIN_RESET);
	panel.GeneralTab:SetText(CHATBAR_OPTIONS_TAB_GENERAL or "General");
	panel.ChannelsTab:SetText(CHATBAR_OPTIONS_TAB_CHANNELS or "Channels");
	panel.ChannelHelpText:SetText(CHATBAR_OPTIONS_CHANNELS_HELP or "Checked buttons are shown on ChatBar.");
	panel.ChannelEmptyText:SetText(CHATBAR_OPTIONS_CHANNELS_EMPTY or "No chat channels are currently available.");
	panel.ChannelSelectAllButton:SetText(CHATBAR_OPTIONS_CHANNELS_SELECTALL or "Select All");
	panel.ChannelClearAllButton:SetText(CHATBAR_OPTIONS_CHANNELS_CLEARALL or "Clear All");

	ChatBar_UpdateChannelsPage(panel);

	for i = 1, CHAT_BAR_MAX_BUTTONS do
		local textRegion = getglobal(panel.ChannelEntries[i]:GetName() .. "Text");
		textRegion:SetWidth(188);
	end
end

function ChatBar_ShowOptionsPanel(anchor)
	if (not ChatBarOptionsPanel) then
		return;
	end

	if (CloseDropDownMenus) then
		CloseDropDownMenus();
	end

	ChatBar_UpdateOptionsPanel();
	if (ChatBarOptionsPanel.Raise) then
		ChatBarOptionsPanel:Raise();
	end
	ChatBarOptionsPanel:Show();
end

function ChatBar_ToggleOptionsPanel(anchor)
	if (not ChatBarOptionsPanel) then
		return;
	end

	if (ChatBarOptionsPanel:IsVisible()) then
		ChatBarOptionsPanel:Hide();
	else
		ChatBar_ShowOptionsPanel(anchor);
	end
end

function ChatBar_CreateOptionsPanel()
	if (ChatBarOptionsPanel) then
		return;
	end

	local panel = CreateFrame("Frame", "ChatBarOptionsPanel", UIParent);
	panel:SetWidth(300);
	panel:SetHeight(432);
	panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	panel:SetFrameStrata("DIALOG");
	panel:SetMovable(true);
	panel:EnableMouse(true);
	panel:SetClampedToScreen(true);
	panel:RegisterForDrag("LeftButton");
	panel:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	});
	panel:SetBackdropColor(0, 0, 0, 1);
	panel:SetBackdropBorderColor(1, .82, 0, 1);
	panel:SetScript("OnDragStart", function()
		this:StartMoving();
	end);
	panel:SetScript("OnDragStop", function()
		this:StopMovingOrSizing();
	end);
	panel:Hide();

	local title = panel:CreateFontString(panel:GetName() .. "Title", "OVERLAY", "GameFontNormal");
	title:SetPoint("TOP", panel, "TOP", 0, -14);
	title:SetText(CHATBAR_MENU_MAIN_TITLE);

	local closeButton = CreateFrame("Button", panel:GetName() .. "Close", panel, "UIPanelCloseButton");
	closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4);

	panel.GeneralTab = ChatBar_CreateOptionsActionButton(panel, panel:GetName() .. "GeneralTab", 110,
		CHATBAR_OPTIONS_TAB_GENERAL or "General");
	panel.GeneralTab:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -38);
	panel.GeneralTab.tabKey = "general";
	panel.GeneralTab:SetScript("OnClick", ChatBar_OptionsTab_OnClick);

	panel.ChannelsTab = ChatBar_CreateOptionsActionButton(panel, panel:GetName() .. "ChannelsTab", 110,
		CHATBAR_OPTIONS_TAB_CHANNELS or "Channels");
	panel.ChannelsTab:SetPoint("LEFT", panel.GeneralTab, "RIGHT", 8, 0);
	panel.ChannelsTab.tabKey = "channels";
	panel.ChannelsTab:SetScript("OnClick", ChatBar_OptionsTab_OnClick);

	panel.GeneralPage = CreateFrame("Frame", panel:GetName() .. "GeneralPage", panel);
	panel.GeneralPage:SetWidth(268);
	panel.GeneralPage:SetHeight(344);
	panel.GeneralPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -68);

	panel.ChannelsPage = CreateFrame("Frame", panel:GetName() .. "ChannelsPage", panel);
	panel.ChannelsPage:SetWidth(268);
	panel.ChannelsPage:SetHeight(344);
	panel.ChannelsPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -68);
	panel.ChannelsPage:Hide();

	panel.AltArtLabel = panel.GeneralPage:CreateFontString(panel:GetName() .. "AltArtLabel", "OVERLAY", "GameFontNormalSmall");
	panel.AltArtLabel:SetPoint("TOPLEFT", panel.GeneralPage, "TOPLEFT", 12, 0);
	panel.AltArtLabel:SetText(CHATBAR_MENU_MAIN_ALTART);

	panel.AltArtDropDown = CreateFrame("Frame", panel:GetName() .. "AltArtDropDown", panel.GeneralPage, "UIDropDownMenuTemplate");
	panel.AltArtDropDown:SetPoint("TOPLEFT", panel.AltArtLabel, "BOTTOMLEFT", -16, -2);
	UIDropDownMenu_SetWidth(180, panel.AltArtDropDown);
	UIDropDownMenu_Initialize(panel.AltArtDropDown, ChatBar_InitializeAltArtDropDown);

	panel.ButtonSizeRow = ChatBar_CreateOptionsValueRow(panel.GeneralPage, panel:GetName() .. "ButtonSizeRow", CHATBAR_MENU_MAIN_BUTTONSIZE);
	panel.ButtonSizeRow:SetPoint("TOPLEFT", panel.AltArtDropDown, "BOTTOMLEFT", 16, -8);
	panel.ButtonSizeRow.Minus.actionFunc = ChatBar_DecreaseButtonSize;
	panel.ButtonSizeRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonSizeRow.Plus.actionFunc = ChatBar_IncreaseButtonSize;
	panel.ButtonSizeRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ButtonTextSizeRow = ChatBar_CreateOptionsValueRow(panel.GeneralPage, panel:GetName() .. "ButtonTextSizeRow", CHATBAR_MENU_MAIN_TEXTSIZE);
	panel.ButtonTextSizeRow:SetPoint("TOPLEFT", panel.ButtonSizeRow, "BOTTOMLEFT", 0, -4);
	panel.ButtonTextSizeRow.Minus.actionFunc = ChatBar_DecreaseButtonTextSize;
	panel.ButtonTextSizeRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonTextSizeRow.Plus.actionFunc = ChatBar_IncreaseButtonTextSize;
	panel.ButtonTextSizeRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ButtonPaddingRow = ChatBar_CreateOptionsValueRow(panel.GeneralPage, panel:GetName() .. "ButtonPaddingRow", CHATBAR_MENU_MAIN_BUTTONPADDING);
	panel.ButtonPaddingRow:SetPoint("TOPLEFT", panel.ButtonTextSizeRow, "BOTTOMLEFT", 0, -4);
	panel.ButtonPaddingRow.Minus.actionFunc = ChatBar_DecreaseButtonPadding;
	panel.ButtonPaddingRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonPaddingRow.Plus.actionFunc = ChatBar_IncreaseButtonPadding;
	panel.ButtonPaddingRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.VerticalButtons = ChatBar_CreateOptionsCheckButton(panel.GeneralPage, panel:GetName() .. "VerticalButtons", CHATBAR_MENU_MAIN_VERTICAL);
	panel.VerticalButtons:SetPoint("TOPLEFT", panel.ButtonPaddingRow, "BOTTOMLEFT", -4, -2);
	panel.VerticalButtons.optionFunc = ChatBar_Toggle_VerticalButtonOrientationSlide;
	panel.VerticalButtons:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ReverseButtons = ChatBar_CreateOptionsCheckButton(panel.GeneralPage, panel:GetName() .. "ReverseButtons", CHATBAR_MENU_MAIN_REVERSE);
	panel.ReverseButtons:SetPoint("TOPLEFT", panel.VerticalButtons, "BOTTOMLEFT", 0, -2);
	panel.ReverseButtons.optionFunc = ChatBar_Toggle_AlternateButtonOrientationSlide;
	panel.ReverseButtons:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.TextOnButtons = ChatBar_CreateOptionsCheckButton(panel.GeneralPage, panel:GetName() .. "TextOnButtons", CHATBAR_MENU_MAIN_TEXTONBUTTONS);
	panel.TextOnButtons:SetPoint("TOPLEFT", panel.ReverseButtons, "BOTTOMLEFT", 0, -2);
	panel.TextOnButtons.optionFunc = ChatBar_Toggle_TextOrientation;
	panel.TextOnButtons:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ShowButtonText = ChatBar_CreateOptionsCheckButton(panel.GeneralPage, panel:GetName() .. "ShowButtonText", CHATBAR_MENU_MAIN_SHOWTEXT);
	panel.ShowButtonText:SetPoint("TOPLEFT", panel.TextOnButtons, "BOTTOMLEFT", 0, -2);
	panel.ShowButtonText.optionFunc = ChatBar_Toggle_ButtonText;
	panel.ShowButtonText:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ChannelNumbers = ChatBar_CreateOptionsCheckButton(panel.GeneralPage, panel:GetName() .. "ChannelNumbers", CHATBAR_MENU_MAIN_CHANNELID);
	panel.ChannelNumbers:SetPoint("TOPLEFT", panel.ShowButtonText, "BOTTOMLEFT", 0, -2);
	panel.ChannelNumbers.optionFunc = ChatBar_Toggle_TextChannelNumbers;
	panel.ChannelNumbers:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ButtonFlashing = ChatBar_CreateOptionsCheckButton(panel.GeneralPage, panel:GetName() .. "ButtonFlashing", CHATBAR_MENU_MAIN_BUTTONFLASHING);
	panel.ButtonFlashing:SetPoint("TOPLEFT", panel.ChannelNumbers, "BOTTOMLEFT", 0, -2);
	panel.ButtonFlashing.optionFunc = ChatBar_Toggle_ButtonFlashing;
	panel.ButtonFlashing:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.BarBorder = ChatBar_CreateOptionsCheckButton(panel.GeneralPage, panel:GetName() .. "BarBorder", CHATBAR_MENU_MAIN_BARBORDER);
	panel.BarBorder:SetPoint("TOPLEFT", panel.ButtonFlashing, "BOTTOMLEFT", 0, -2);
	panel.BarBorder.optionFunc = ChatBar_Toggle_BarBorder;
	panel.BarBorder:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ResetButton = ChatBar_CreateOptionsActionButton(panel.GeneralPage, panel:GetName() .. "ResetButton", 130, CHATBAR_MENU_MAIN_RESET);
	panel.ResetButton:SetPoint("TOPLEFT", panel.BarBorder, "BOTTOMLEFT", 16, -16);
	panel.ResetButton.actionFunc = ChatBar_Reset;
	panel.ResetButton:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ChannelHelpText = panel.ChannelsPage:CreateFontString(panel:GetName() .. "ChannelHelpText", "OVERLAY", "GameFontNormalSmall");
	panel.ChannelHelpText:SetWidth(240);
	panel.ChannelHelpText:SetJustifyH("LEFT");
	panel.ChannelHelpText:SetPoint("TOPLEFT", panel.ChannelsPage, "TOPLEFT", 0, 0);

	panel.ChannelSelectAllButton = ChatBar_CreateOptionsActionButton(panel.ChannelsPage,
		panel:GetName() .. "ChannelSelectAllButton", 116, CHATBAR_OPTIONS_CHANNELS_SELECTALL or "Select All");
	panel.ChannelSelectAllButton:SetPoint("TOPLEFT", panel.ChannelHelpText, "BOTTOMLEFT", 0, -8);
	panel.ChannelSelectAllButton.actionFunc = ChatBar_SelectAllChannels;
	panel.ChannelSelectAllButton:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ChannelClearAllButton = ChatBar_CreateOptionsActionButton(panel.ChannelsPage,
		panel:GetName() .. "ChannelClearAllButton", 116, CHATBAR_OPTIONS_CHANNELS_CLEARALL or "Clear All");
	panel.ChannelClearAllButton:SetPoint("LEFT", panel.ChannelSelectAllButton, "RIGHT", 8, 0);
	panel.ChannelClearAllButton.actionFunc = ChatBar_ClearAllChannels;
	panel.ChannelClearAllButton:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ChannelScrollFrame = CreateFrame("ScrollFrame", panel:GetName() .. "ChannelScrollFrame", panel.ChannelsPage,
		"UIPanelScrollFrameTemplate");
	panel.ChannelScrollFrame:SetPoint("TOPLEFT", panel.ChannelSelectAllButton, "BOTTOMLEFT", 0, -8);
	panel.ChannelScrollFrame:SetWidth(244);
	panel.ChannelScrollFrame:SetHeight(266);

	panel.ChannelScrollChild = CreateFrame("Frame", panel:GetName() .. "ChannelScrollChild", panel.ChannelScrollFrame);
	panel.ChannelScrollChild:SetWidth(214);
	panel.ChannelScrollChild:SetHeight(300);
	panel.ChannelScrollFrame:SetScrollChild(panel.ChannelScrollChild);

	panel.ChannelEmptyText = panel.ChannelScrollChild:CreateFontString(panel:GetName() .. "ChannelEmptyText", "OVERLAY",
		"GameFontHighlightSmall");
	panel.ChannelEmptyText:SetWidth(200);
	panel.ChannelEmptyText:SetJustifyH("LEFT");
	panel.ChannelEmptyText:SetPoint("TOPLEFT", panel.ChannelScrollChild, "TOPLEFT", 4, -8);

	panel.ChannelEntries = {};
	for i = 1, CHAT_BAR_MAX_BUTTONS do
		local channelCheck = ChatBar_CreateOptionsCheckButton(panel.ChannelScrollChild, panel:GetName() .. "ChannelEntry" .. i, "");
		local channelText = getglobal(channelCheck:GetName() .. "Text");
		if (i == 1) then
			channelCheck:SetPoint("TOPLEFT", panel.ChannelScrollChild, "TOPLEFT", 0, -4);
		else
			channelCheck:SetPoint("TOPLEFT", panel.ChannelEntries[i - 1], "BOTTOMLEFT", 0, -2);
		end
		channelText:SetWidth(188);
		channelText:SetJustifyH("LEFT");
		channelCheck:SetScript("OnClick", ChatBar_ChannelVisibilityCheck_OnClick);
		channelCheck:Hide();
		panel.ChannelEntries[i] = channelCheck;
	end

	panel.currentTab = "general";
end