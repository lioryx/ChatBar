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
	row:SetWidth(288);
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

local function ChatBar_GetChannelSortID()
	if (ChatBar_ChannelSort == "name") then
		return 2;
	elseif (ChatBar_ChannelSort == "name_desc") then
		return 3;
	end
	return 1;
end

local function ChatBar_GetChannelSortText()
	if (ChatBar_ChannelSort == "name") then
		return CHATBAR_CHANNELSORT_NAME or "By Name (A-Z)";
	elseif (ChatBar_ChannelSort == "name_desc") then
		return CHATBAR_CHANNELSORT_NAME_DESC or "By Name (Z-A)";
	end
	return CHATBAR_CHANNELSORT_NUMBER or "By Channel Number";
end

local function ChatBar_ChannelSortDropDown_OnClick()
	if (this.value == 2) then
		ChatBar_ChannelSort = "name";
	elseif (this.value == 3) then
		ChatBar_ChannelSort = "name_desc";
	else
		ChatBar_ChannelSort = "number";
	end
	ChatBar_ApplyChannelSortToManualOrder();
	ChatBar_UpdateButtons();
	ChatBar_UpdateOptionsPanel();
end

local function ChatBar_InitializeChannelSortDropDown()
	local info;

	info = {};
	info.text = CHATBAR_CHANNELSORT_NUMBER or "By Channel Number";
	info.value = 1;
	info.func = ChatBar_ChannelSortDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = CHATBAR_CHANNELSORT_NAME or "By Name (A-Z)";
	info.value = 2;
	info.func = ChatBar_ChannelSortDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = CHATBAR_CHANNELSORT_NAME_DESC or "By Name (Z-A)";
	info.value = 3;
	info.func = ChatBar_ChannelSortDropDown_OnClick;
	UIDropDownMenu_AddButton(info);
end

local function ChatBar_GetVisibilityEntries()
	local entries = {};
	local chatTypeInfo;
	local label;
	local key;
	local _, _, channelIndex;
	local channelNum, channelName;
	local displayOrder = ChatBar_GetDisplayOrder();
	local i;

	for i = 1, table.getn(displayOrder) do
		chatTypeInfo = ChatBar_ChatTypes[displayOrder[i]];
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

		if (not chatTypeInfo.alwaysShow) and (label) and (label ~= "") and (key) and (key ~= "") then
			table.insert(entries, {
				label = label,
				key = key,
			});
		end
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

local function ChatBar_AdjustButtonWidth(delta)
	local newValue;
	local squareMin;
	local squareMax;
	ChatBar_InitializeSizeSettings();
	if (ChatBar_IsColorBarArt()) then
		newValue = ChatBar_NormalizeSizeSetting(ChatBar_ButtonWidth + delta, CHAT_BAR_BUTTON_WIDTH,
			CHAT_BAR_BUTTON_WIDTH_MIN, CHAT_BAR_BUTTON_WIDTH_MAX, CHAT_BAR_BUTTON_WIDTH_STEP);
		if (newValue ~= ChatBar_ButtonWidth) then
			ChatBar_ButtonWidth = newValue;
			ChatBar_RefreshButtonLayout();
		end
		return;
	end

	if (CHAT_BAR_BUTTON_WIDTH_MIN > CHAT_BAR_BUTTON_HEIGHT_MIN) then
		squareMin = CHAT_BAR_BUTTON_WIDTH_MIN;
	else
		squareMin = CHAT_BAR_BUTTON_HEIGHT_MIN;
	end
	if (CHAT_BAR_BUTTON_WIDTH_MAX < CHAT_BAR_BUTTON_HEIGHT_MAX) then
		squareMax = CHAT_BAR_BUTTON_WIDTH_MAX;
	else
		squareMax = CHAT_BAR_BUTTON_HEIGHT_MAX;
	end
	newValue = ChatBar_NormalizeSizeSetting(ChatBar_ButtonWidth + delta, CHAT_BAR_BUTTON_WIDTH,
		squareMin, squareMax, CHAT_BAR_BUTTON_WIDTH_STEP);
	if (newValue ~= ChatBar_ButtonWidth) then
		ChatBar_ButtonWidth = newValue;
		ChatBar_ButtonHeight = newValue;
		ChatBar_RefreshButtonLayout();
	end
end

local function ChatBar_AdjustButtonHeight(delta)
	local newValue;
	if (not ChatBar_IsColorBarArt()) then
		return;
	end
	ChatBar_InitializeSizeSettings();
	newValue = ChatBar_NormalizeSizeSetting(ChatBar_ButtonHeight + delta, CHAT_BAR_BUTTON_HEIGHT,
		CHAT_BAR_BUTTON_HEIGHT_MIN, CHAT_BAR_BUTTON_HEIGHT_MAX, CHAT_BAR_BUTTON_HEIGHT_STEP);
	if (newValue ~= ChatBar_ButtonHeight) then
		ChatBar_ButtonHeight = newValue;
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

local function ChatBar_AdjustColorBarBorderSize(delta)
	local newValue;
	if (not ChatBar_IsColorBarArt()) then
		return;
	end
	ChatBar_InitializeSizeSettings();
	newValue = ChatBar_NormalizeSizeSetting(ChatBar_ColorBarBorderSize + delta, CHAT_BAR_COLORBAR_BORDER,
		CHAT_BAR_COLORBAR_BORDER_MIN, CHAT_BAR_COLORBAR_BORDER_MAX, CHAT_BAR_COLORBAR_BORDER_STEP);
	if (newValue ~= ChatBar_ColorBarBorderSize) then
		ChatBar_ColorBarBorderSize = newValue;
		-- 边框大小变化会影响间距（间距含 2 倍边框），需要重排整个布局
		ChatBar_RefreshButtonLayout();
	end
end

function ChatBar_DecreaseButtonWidth()
	ChatBar_AdjustButtonWidth(-CHAT_BAR_BUTTON_WIDTH_STEP);
end

function ChatBar_IncreaseButtonWidth()
	ChatBar_AdjustButtonWidth(CHAT_BAR_BUTTON_WIDTH_STEP);
end

function ChatBar_DecreaseButtonHeight()
	ChatBar_AdjustButtonHeight(-CHAT_BAR_BUTTON_HEIGHT_STEP);
end

function ChatBar_IncreaseButtonHeight()
	ChatBar_AdjustButtonHeight(CHAT_BAR_BUTTON_HEIGHT_STEP);
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

function ChatBar_DecreaseColorBarBorderSize()
	ChatBar_AdjustColorBarBorderSize(-CHAT_BAR_COLORBAR_BORDER_STEP);
end

function ChatBar_IncreaseColorBarBorderSize()
	ChatBar_AdjustColorBarBorderSize(CHAT_BAR_COLORBAR_BORDER_STEP);
end

function ChatBar_UpdateOptionsPanel()
	if (not ChatBarOptionsPanel) then
		return;
	end

	local panel = ChatBarOptionsPanel;
	local i;
	local currentTab;
	local colorBars = ChatBar_IsColorBarArt();
	local squareMin;
	local squareMax;
	local widthMin;
	local widthMax;
	ChatBar_InitializeSizeSettings();
	currentTab = panel.currentTab or "appearance";
	panel.currentTab = currentTab;

	panel.AppearancePage:Hide();
	panel.TextPage:Hide();
	panel.BehaviorPage:Hide();
	panel.ChannelsPage:Hide();
	panel.AppearanceTab:Enable();
	panel.TextTab:Enable();
	panel.BehaviorTab:Enable();
	panel.ChannelsTab:Enable();

	if (currentTab == "appearance") then
		panel.AppearancePage:Show();
		panel.AppearanceTab:Disable();
	elseif (currentTab == "text") then
		panel.TextPage:Show();
		panel.TextTab:Disable();
	elseif (currentTab == "behavior") then
		panel.BehaviorPage:Show();
		panel.BehaviorTab:Disable();
	else
		panel.ChannelsPage:Show();
		panel.ChannelsTab:Disable();
		currentTab = "channels";
		panel.currentTab = currentTab;
	end

	if (colorBars) then
		panel.ButtonHeightRow:Show();
		panel.ColorBarBorderRow:Show();
		panel.ButtonPaddingRow:ClearAllPoints();
		panel.ButtonPaddingRow:SetPoint("TOPLEFT", panel.ButtonHeightRow, "BOTTOMLEFT", 0, -4);
		panel.ColorBarBorderRow:ClearAllPoints();
		panel.ColorBarBorderRow:SetPoint("TOPLEFT", panel.ButtonPaddingRow, "BOTTOMLEFT", 0, -4);
		panel.BarBorder:ClearAllPoints();
		panel.BarBorder:SetPoint("TOPLEFT", panel.ColorBarBorderRow, "BOTTOMLEFT", -4, -2);
	else
		panel.ButtonHeightRow:Hide();
		panel.ColorBarBorderRow:Hide();
		panel.ButtonPaddingRow:ClearAllPoints();
		panel.ButtonPaddingRow:SetPoint("TOPLEFT", panel.ButtonWidthRow, "BOTTOMLEFT", 0, -4);
		panel.BarBorder:ClearAllPoints();
		panel.BarBorder:SetPoint("TOPLEFT", panel.ButtonPaddingRow, "BOTTOMLEFT", -4, -2);
	end

	panel.ButtonWidthRow.Value:SetText(ChatBar_ButtonWidth);
	panel.ButtonHeightRow.Value:SetText(ChatBar_ButtonHeight);
	panel.ButtonTextSizeRow.Value:SetText(ChatBar_ButtonTextSize);
	panel.ButtonPaddingRow.Value:SetText(ChatBar_ButtonPadding);
	panel.ColorBarBorderRow.Value:SetText(ChatBar_ColorBarBorderSize);

	if (colorBars) then
		widthMin = CHAT_BAR_BUTTON_WIDTH_MIN;
		widthMax = CHAT_BAR_BUTTON_WIDTH_MAX;
	else
		if (CHAT_BAR_BUTTON_WIDTH_MIN > CHAT_BAR_BUTTON_HEIGHT_MIN) then
			squareMin = CHAT_BAR_BUTTON_WIDTH_MIN;
		else
			squareMin = CHAT_BAR_BUTTON_HEIGHT_MIN;
		end
		if (CHAT_BAR_BUTTON_WIDTH_MAX < CHAT_BAR_BUTTON_HEIGHT_MAX) then
			squareMax = CHAT_BAR_BUTTON_WIDTH_MAX;
		else
			squareMax = CHAT_BAR_BUTTON_HEIGHT_MAX;
		end
		widthMin = squareMin;
		widthMax = squareMax;
	end

	if (ChatBar_ButtonWidth <= widthMin) then
		panel.ButtonWidthRow.Minus:Disable();
	else
		panel.ButtonWidthRow.Minus:Enable();
	end
	if (ChatBar_ButtonWidth >= widthMax) then
		panel.ButtonWidthRow.Plus:Disable();
	else
		panel.ButtonWidthRow.Plus:Enable();
	end
	if (ChatBar_ButtonHeight <= CHAT_BAR_BUTTON_HEIGHT_MIN) then
		panel.ButtonHeightRow.Minus:Disable();
	else
		panel.ButtonHeightRow.Minus:Enable();
	end
	if (ChatBar_ButtonHeight >= CHAT_BAR_BUTTON_HEIGHT_MAX) then
		panel.ButtonHeightRow.Plus:Disable();
	else
		panel.ButtonHeightRow.Plus:Enable();
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
	if (ChatBar_ColorBarBorderSize <= CHAT_BAR_COLORBAR_BORDER_MIN) then
		panel.ColorBarBorderRow.Minus:Disable();
	else
		panel.ColorBarBorderRow.Minus:Enable();
	end
	if (ChatBar_ColorBarBorderSize >= CHAT_BAR_COLORBAR_BORDER_MAX) then
		panel.ColorBarBorderRow.Plus:Disable();
	else
		panel.ColorBarBorderRow.Plus:Enable();
	end
	local verticalChecked = ChatBar_VerticalDisplay;
	local reverseChecked = ChatBar_AlternateOrientation;
	-- 滑动动画结束前实际标志尚未翻转，勾选框显示即将生效的目标状态
	if (ChatBar_VerticalDisplay_Sliding) then
		verticalChecked = not ChatBar_VerticalDisplay;
	end
	if (ChatBar_AlternateDisplay_Sliding) then
		reverseChecked = not ChatBar_AlternateOrientation;
	end
	panel.VerticalButtons:SetChecked(verticalChecked);
	panel.ReverseButtons:SetChecked(reverseChecked);
	if (ChatBar_VerticalDisplay_Sliding or ChatBar_AlternateDisplay_Sliding) then
		panel.VerticalButtons:Disable();
		panel.ReverseButtons:Disable();
	else
		panel.VerticalButtons:Enable();
		panel.ReverseButtons:Enable();
	end
	panel.TextOnButtons:SetChecked(ChatBar_TextOnButtonDisplay);
	panel.ShowButtonText:SetChecked(ChatBar_ButtonText);
	panel.ReverseTextPosition:SetChecked(ChatBar_ReverseTextPosition);
	panel.HoverText:SetChecked(ChatBar_HoverTextEnabled);
	panel.ChannelNumbers:SetChecked(ChatBar_TextChannelNumbers);
	panel.ButtonFlashing:SetChecked(ChatBar_ButtonFlashing);
	panel.BarBorder:SetChecked(ChatBar_BarBorder);
	panel.FadeEffect:SetChecked(ChatBar_FadeEnabled);
	if (type(ChatBar_AltArt) ~= "number") or (not ChatBar_AltArtDirs[ChatBar_AltArt]) then
		ChatBar_AltArt = 1;
	end
	UIDropDownMenu_SetSelectedID(panel.AltArtDropDown, ChatBar_AltArt);
	UIDropDownMenu_SetText(getglobal("CHATBAR_SKIN" .. ChatBar_AltArt) or ChatBar_AltArtDirs[ChatBar_AltArt], panel.AltArtDropDown);

	if (ChatBar_ChannelSort ~= "name") and (ChatBar_ChannelSort ~= "name_desc") then
		ChatBar_ChannelSort = "number";
	end
	UIDropDownMenu_SetSelectedID(panel.ChannelSortDropDown, ChatBar_GetChannelSortID());
	UIDropDownMenu_SetText(ChatBar_GetChannelSortText(), panel.ChannelSortDropDown);
	panel.ChannelSortLabel:SetText(CHATBAR_OPTIONS_CHANNELS_SORT or "Channel Sort");

	panel.ResetButton:SetText(CHATBAR_MENU_MAIN_RESET);
	panel.AppearanceTab:SetText(CHATBAR_OPTIONS_TAB_APPEARANCE or "Skin");
	panel.TextTab:SetText(CHATBAR_OPTIONS_TAB_TEXT or "Text");
	panel.BehaviorTab:SetText(CHATBAR_OPTIONS_TAB_BEHAVIOR or "Behavior");
	panel.ChannelsTab:SetText(CHATBAR_OPTIONS_TAB_CHANNELS or "Channels");
	panel.ChannelHelpText:SetText(CHATBAR_OPTIONS_CHANNELS_HELP or "Checked buttons are shown on ChatBar.");
	panel.ChannelEmptyText:SetText(CHATBAR_OPTIONS_CHANNELS_EMPTY or "No chat channels are currently available.");
	panel.ChannelSelectAllButton:SetText(CHATBAR_OPTIONS_CHANNELS_SELECTALL or "Select All");
	panel.ChannelClearAllButton:SetText(CHATBAR_OPTIONS_CHANNELS_CLEARALL or "Clear All");
	panel.ChannelResetSortButton:SetText(CHATBAR_OPTIONS_CHANNELS_RESETSORT or "Reset Sort");

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
	panel:SetWidth(320);
	panel:SetHeight(540);
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

	panel.AppearanceTab = ChatBar_CreateOptionsActionButton(panel, panel:GetName() .. "AppearanceTab", 72,
		CHATBAR_OPTIONS_TAB_APPEARANCE or "Skin");
	panel.AppearanceTab:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -38);
	panel.AppearanceTab.tabKey = "appearance";
	panel.AppearanceTab:SetScript("OnClick", ChatBar_OptionsTab_OnClick);

	panel.TextTab = ChatBar_CreateOptionsActionButton(panel, panel:GetName() .. "TextTab", 72,
		CHATBAR_OPTIONS_TAB_TEXT or "Text");
	panel.TextTab:SetPoint("LEFT", panel.AppearanceTab, "RIGHT", 4, 0);
	panel.TextTab.tabKey = "text";
	panel.TextTab:SetScript("OnClick", ChatBar_OptionsTab_OnClick);

	panel.BehaviorTab = ChatBar_CreateOptionsActionButton(panel, panel:GetName() .. "BehaviorTab", 72,
		CHATBAR_OPTIONS_TAB_BEHAVIOR or "Behavior");
	panel.BehaviorTab:SetPoint("LEFT", panel.TextTab, "RIGHT", 4, 0);
	panel.BehaviorTab.tabKey = "behavior";
	panel.BehaviorTab:SetScript("OnClick", ChatBar_OptionsTab_OnClick);

	panel.ChannelsTab = ChatBar_CreateOptionsActionButton(panel, panel:GetName() .. "ChannelsTab", 72,
		CHATBAR_OPTIONS_TAB_CHANNELS or "Channels");
	panel.ChannelsTab:SetPoint("LEFT", panel.BehaviorTab, "RIGHT", 4, 0);
	panel.ChannelsTab.tabKey = "channels";
	panel.ChannelsTab:SetScript("OnClick", ChatBar_OptionsTab_OnClick);

	panel.AppearancePage = CreateFrame("Frame", panel:GetName() .. "AppearancePage", panel);
	panel.AppearancePage:SetWidth(288);
	panel.AppearancePage:SetHeight(390);
	panel.AppearancePage:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -68);

	panel.TextPage = CreateFrame("Frame", panel:GetName() .. "TextPage", panel);
	panel.TextPage:SetWidth(288);
	panel.TextPage:SetHeight(390);
	panel.TextPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -68);
	panel.TextPage:Hide();

	panel.BehaviorPage = CreateFrame("Frame", panel:GetName() .. "BehaviorPage", panel);
	panel.BehaviorPage:SetWidth(288);
	panel.BehaviorPage:SetHeight(390);
	panel.BehaviorPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -68);
	panel.BehaviorPage:Hide();

	panel.ChannelsPage = CreateFrame("Frame", panel:GetName() .. "ChannelsPage", panel);
	panel.ChannelsPage:SetWidth(288);
	panel.ChannelsPage:SetHeight(390);
	panel.ChannelsPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -68);
	panel.ChannelsPage:Hide();

	panel.AltArtLabel = panel.AppearancePage:CreateFontString(panel:GetName() .. "AltArtLabel", "OVERLAY", "GameFontNormalSmall");
	panel.AltArtLabel:SetPoint("TOPLEFT", panel.AppearancePage, "TOPLEFT", 12, 0);
	panel.AltArtLabel:SetText(CHATBAR_MENU_MAIN_ALTART);

	panel.AltArtDropDown = CreateFrame("Frame", panel:GetName() .. "AltArtDropDown", panel.AppearancePage, "UIDropDownMenuTemplate");
	panel.AltArtDropDown:SetPoint("TOPLEFT", panel.AltArtLabel, "BOTTOMLEFT", -16, -2);
	UIDropDownMenu_SetWidth(180, panel.AltArtDropDown);
	UIDropDownMenu_Initialize(panel.AltArtDropDown, ChatBar_InitializeAltArtDropDown);

	panel.ButtonWidthRow = ChatBar_CreateOptionsValueRow(panel.AppearancePage, panel:GetName() .. "ButtonWidthRow", CHATBAR_MENU_MAIN_BUTTONWIDTH);
	panel.ButtonWidthRow:SetPoint("TOPLEFT", panel.AltArtDropDown, "BOTTOMLEFT", 16, -8);
	panel.ButtonWidthRow.Minus.actionFunc = ChatBar_DecreaseButtonWidth;
	panel.ButtonWidthRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonWidthRow.Plus.actionFunc = ChatBar_IncreaseButtonWidth;
	panel.ButtonWidthRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ButtonHeightRow = ChatBar_CreateOptionsValueRow(panel.AppearancePage, panel:GetName() .. "ButtonHeightRow", CHATBAR_MENU_MAIN_BUTTONHEIGHT);
	panel.ButtonHeightRow:SetPoint("TOPLEFT", panel.ButtonWidthRow, "BOTTOMLEFT", 0, -4);
	panel.ButtonHeightRow.Minus.actionFunc = ChatBar_DecreaseButtonHeight;
	panel.ButtonHeightRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonHeightRow.Plus.actionFunc = ChatBar_IncreaseButtonHeight;
	panel.ButtonHeightRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ButtonPaddingRow = ChatBar_CreateOptionsValueRow(panel.AppearancePage, panel:GetName() .. "ButtonPaddingRow", CHATBAR_MENU_MAIN_BUTTONPADDING);
	panel.ButtonPaddingRow:SetPoint("TOPLEFT", panel.ButtonWidthRow, "BOTTOMLEFT", 0, -4);
	panel.ButtonPaddingRow.Minus.actionFunc = ChatBar_DecreaseButtonPadding;
	panel.ButtonPaddingRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonPaddingRow.Plus.actionFunc = ChatBar_IncreaseButtonPadding;
	panel.ButtonPaddingRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ColorBarBorderRow = ChatBar_CreateOptionsValueRow(panel.AppearancePage, panel:GetName() .. "ColorBarBorderRow",
		CHATBAR_MENU_MAIN_COLORBARBORDER or "Color Bar Border");
	panel.ColorBarBorderRow:SetPoint("TOPLEFT", panel.ButtonPaddingRow, "BOTTOMLEFT", 0, -4);
	panel.ColorBarBorderRow.Minus.actionFunc = ChatBar_DecreaseColorBarBorderSize;
	panel.ColorBarBorderRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ColorBarBorderRow.Plus.actionFunc = ChatBar_IncreaseColorBarBorderSize;
	panel.ColorBarBorderRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.BarBorder = ChatBar_CreateOptionsCheckButton(panel.AppearancePage, panel:GetName() .. "BarBorder", CHATBAR_MENU_MAIN_BARBORDER);
	panel.BarBorder:SetPoint("TOPLEFT", panel.ButtonPaddingRow, "BOTTOMLEFT", -4, -2);
	panel.BarBorder.optionFunc = ChatBar_Toggle_BarBorder;
	panel.BarBorder:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ButtonTextSizeRow = ChatBar_CreateOptionsValueRow(panel.TextPage, panel:GetName() .. "ButtonTextSizeRow", CHATBAR_MENU_MAIN_TEXTSIZE);
	panel.ButtonTextSizeRow:SetPoint("TOPLEFT", panel.TextPage, "TOPLEFT", 0, -4);
	panel.ButtonTextSizeRow.Minus.actionFunc = ChatBar_DecreaseButtonTextSize;
	panel.ButtonTextSizeRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonTextSizeRow.Plus.actionFunc = ChatBar_IncreaseButtonTextSize;
	panel.ButtonTextSizeRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ShowButtonText = ChatBar_CreateOptionsCheckButton(panel.TextPage, panel:GetName() .. "ShowButtonText", CHATBAR_MENU_MAIN_SHOWTEXT);
	panel.ShowButtonText:SetPoint("TOPLEFT", panel.ButtonTextSizeRow, "BOTTOMLEFT", -4, -2);
	panel.ShowButtonText.optionFunc = ChatBar_Toggle_ButtonText;
	panel.ShowButtonText:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.TextOnButtons = ChatBar_CreateOptionsCheckButton(panel.TextPage, panel:GetName() .. "TextOnButtons", CHATBAR_MENU_MAIN_TEXTONBUTTONS);
	panel.TextOnButtons:SetPoint("TOPLEFT", panel.ShowButtonText, "BOTTOMLEFT", 0, -2);
	panel.TextOnButtons.optionFunc = ChatBar_Toggle_TextOrientation;
	panel.TextOnButtons:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ReverseTextPosition = ChatBar_CreateOptionsCheckButton(panel.TextPage, panel:GetName() .. "ReverseTextPosition", CHATBAR_MENU_MAIN_REVERSETEXT);
	panel.ReverseTextPosition:SetPoint("TOPLEFT", panel.TextOnButtons, "BOTTOMLEFT", 0, -2);
	panel.ReverseTextPosition.optionFunc = ChatBar_Toggle_ReverseTextPosition;
	panel.ReverseTextPosition:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.HoverText = ChatBar_CreateOptionsCheckButton(panel.TextPage, panel:GetName() .. "HoverText", CHATBAR_MENU_MAIN_HOVERTEXT);
	panel.HoverText:SetPoint("TOPLEFT", panel.ReverseTextPosition, "BOTTOMLEFT", 0, -2);
	panel.HoverText.optionFunc = ChatBar_Toggle_HoverText;
	panel.HoverText:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ChannelNumbers = ChatBar_CreateOptionsCheckButton(panel.TextPage, panel:GetName() .. "ChannelNumbers", CHATBAR_MENU_MAIN_CHANNELID);
	panel.ChannelNumbers:SetPoint("TOPLEFT", panel.HoverText, "BOTTOMLEFT", 0, -2);
	panel.ChannelNumbers.optionFunc = ChatBar_Toggle_TextChannelNumbers;
	panel.ChannelNumbers:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.VerticalButtons = ChatBar_CreateOptionsCheckButton(panel.BehaviorPage, panel:GetName() .. "VerticalButtons", CHATBAR_MENU_MAIN_VERTICAL);
	panel.VerticalButtons:SetPoint("TOPLEFT", panel.BehaviorPage, "TOPLEFT", 0, -4);
	panel.VerticalButtons.optionFunc = ChatBar_Toggle_VerticalButtonOrientationSlide;
	panel.VerticalButtons:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ReverseButtons = ChatBar_CreateOptionsCheckButton(panel.BehaviorPage, panel:GetName() .. "ReverseButtons", CHATBAR_MENU_MAIN_REVERSE);
	panel.ReverseButtons:SetPoint("TOPLEFT", panel.VerticalButtons, "BOTTOMLEFT", 0, -2);
	panel.ReverseButtons.optionFunc = ChatBar_Toggle_AlternateButtonOrientationSlide;
	panel.ReverseButtons:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ButtonFlashing = ChatBar_CreateOptionsCheckButton(panel.BehaviorPage, panel:GetName() .. "ButtonFlashing", CHATBAR_MENU_MAIN_BUTTONFLASHING);
	panel.ButtonFlashing:SetPoint("TOPLEFT", panel.ReverseButtons, "BOTTOMLEFT", 0, -2);
	panel.ButtonFlashing.optionFunc = ChatBar_Toggle_ButtonFlashing;
	panel.ButtonFlashing:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.FadeEffect = ChatBar_CreateOptionsCheckButton(panel.BehaviorPage, panel:GetName() .. "FadeEffect", CHATBAR_MENU_MAIN_FADE);
	panel.FadeEffect:SetPoint("TOPLEFT", panel.ButtonFlashing, "BOTTOMLEFT", 0, -2);
	panel.FadeEffect.optionFunc = ChatBar_Toggle_FadeEffect;
	panel.FadeEffect:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ResetButton = ChatBar_CreateOptionsActionButton(panel.BehaviorPage, panel:GetName() .. "ResetButton", 130, CHATBAR_MENU_MAIN_RESET);
	panel.ResetButton:SetPoint("TOPLEFT", panel.FadeEffect, "BOTTOMLEFT", 16, -16);
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

	panel.ChannelSortLabel = panel.ChannelsPage:CreateFontString(panel:GetName() .. "ChannelSortLabel", "OVERLAY",
		"GameFontNormalSmall");
	panel.ChannelSortLabel:SetPoint("TOPLEFT", panel.ChannelSelectAllButton, "BOTTOMLEFT", 12, -6);

	panel.ChannelSortDropDown = CreateFrame("Frame", panel:GetName() .. "ChannelSortDropDown", panel.ChannelsPage,
		"UIDropDownMenuTemplate");
	panel.ChannelSortDropDown:SetPoint("TOPLEFT", panel.ChannelSortLabel, "BOTTOMLEFT", -16, -2);
	UIDropDownMenu_SetWidth(180, panel.ChannelSortDropDown);
	UIDropDownMenu_Initialize(panel.ChannelSortDropDown, ChatBar_InitializeChannelSortDropDown);

	panel.ChannelResetSortButton = ChatBar_CreateOptionsActionButton(panel.ChannelsPage,
		panel:GetName() .. "ChannelResetSortButton", 116, CHATBAR_OPTIONS_CHANNELS_RESETSORT or "Reset Sort");
	panel.ChannelResetSortButton:SetPoint("TOPLEFT", panel.ChannelSortDropDown, "BOTTOMLEFT", 16, -8);
	panel.ChannelResetSortButton.actionFunc = ChatBar_ResetButtonOrder;
	panel.ChannelResetSortButton:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ChannelScrollFrame = CreateFrame("ScrollFrame", panel:GetName() .. "ChannelScrollFrame", panel.ChannelsPage,
		"UIPanelScrollFrameTemplate");
	panel.ChannelScrollFrame:SetPoint("TOPLEFT", panel.ChannelResetSortButton, "BOTTOMLEFT", 0, -8);
	panel.ChannelScrollFrame:SetWidth(244);
	panel.ChannelScrollFrame:SetHeight(230);

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

	panel.currentTab = "appearance";
end