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

local function ChatBar_CreateOptionsSectionHeader(parent, name, labelText)
	local header = CreateFrame("Frame", name, parent);
	header:SetWidth(288);
	header:SetHeight(16);
	header.Label = header:CreateFontString(name .. "Label", "OVERLAY", "GameFontNormal");
	header.Label:SetAllPoints(header);
	header.Label:SetJustifyH("LEFT");
	header.Label:SetText(labelText);
	return header;
end

-- entries: { { frame = Frame, x = number, gap = number }, ... }
-- hidden frames are skipped; x/gap are optional
local function ChatBar_LayoutOptionStack(parent, entries, startX, startY, defaultGap)
	local lastFrame = nil;
	local lastX = startX;
	local i;
	local entry;
	local frame;
	local x;
	local gap;

	for i = 1, table.getn(entries) do
		entry = entries[i];
		frame = entry.frame;
		if (frame) and (frame:IsShown()) then
			x = entry.x;
			if (x == nil) then
				x = startX;
			end
			gap = entry.gap;
			if (gap == nil) then
				gap = defaultGap;
			end
			frame:ClearAllPoints();
			if (lastFrame) then
				frame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", x - lastX, -gap);
			else
				frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, startY);
			end
			lastFrame = frame;
			lastX = x;
		end
	end
end

local function ChatBar_SetCheckButtonEnabled(button, enabled)
	if (enabled) then
		button:Enable();
	else
		button:Disable();
	end
end

local function ChatBar_UpdateValueRowButtons(row, value, minValue, maxValue, enabled)
	local r;
	local g;
	local b;
	if (not enabled) then
		row.Minus:Disable();
		row.Plus:Disable();
		if (row.Label) then
			if (GRAY_FONT_COLOR) then
				row.Label:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
			else
				row.Label:SetTextColor(0.5, 0.5, 0.5);
			end
		end
		return;
	end
	if (row.Label) then
		if (NORMAL_FONT_COLOR) then
			r = NORMAL_FONT_COLOR.r;
			g = NORMAL_FONT_COLOR.g;
			b = NORMAL_FONT_COLOR.b;
		else
			r = 1;
			g = .82;
			b = 0;
		end
		row.Label:SetTextColor(r, g, b);
	end
	if (value <= minValue) then
		row.Minus:Disable();
	else
		row.Minus:Enable();
	end
	if (value >= maxValue) then
		row.Plus:Disable();
	else
		row.Plus:Enable();
	end
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

local function ChatBar_AdjustTextGap(delta)
	local newValue;
	ChatBar_InitializeSizeSettings();
	newValue = ChatBar_NormalizeSizeSetting(ChatBar_TextGap + delta, CHAT_BAR_TEXT_GAP,
		CHAT_BAR_TEXT_GAP_MIN, CHAT_BAR_TEXT_GAP_MAX, CHAT_BAR_TEXT_GAP_STEP);
	if (newValue ~= ChatBar_TextGap) then
		ChatBar_TextGap = newValue;
		ChatBar_RefreshButtonLayout();
	end
end

function ChatBar_DecreaseTextGap()
	ChatBar_AdjustTextGap(-CHAT_BAR_TEXT_GAP_STEP);
end

function ChatBar_IncreaseTextGap()
	ChatBar_AdjustTextGap(CHAT_BAR_TEXT_GAP_STEP);
end

function ChatBar_UpdateOptionsPanel()
	if (not ChatBarOptionsPanel) then
		return;
	end

	local panel = ChatBarOptionsPanel;
	local i;
	local currentTab;
	local colorBars = ChatBar_IsColorBarArt();
	local textOnly = ChatBar_IsTextOnlyArt();
	local octagon = ChatBar_IsOctagonArt();
	local showText;
	local centerText;
	local forcedText;
	local barBorderEnabled;
	local textSizeEnabled;
	local channelIdEnabled;
	local textOnButtonsEnabled;
	local reverseTextEnabled;
	local textGapEnabled;
	local hoverTextEnabled;
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
		panel.ButtonWidthRow.Label:SetText(CHATBAR_MENU_MAIN_BUTTONWIDTH);
	else
		panel.ButtonHeightRow:Hide();
		panel.ColorBarBorderRow:Hide();
		panel.ButtonWidthRow.Label:SetText(CHATBAR_MENU_MAIN_BUTTONSIZE);
	end

	panel.SkinHeader.Label:SetText(CHATBAR_OPTIONS_SECTION_SKIN or "Skin");
	panel.SizeHeader.Label:SetText(CHATBAR_OPTIONS_SECTION_SIZE or "Size");
	panel.SpacingHeader.Label:SetText(CHATBAR_OPTIONS_SECTION_SPACING or "Spacing and Border");
	panel.LayoutHeader.Label:SetText(CHATBAR_OPTIONS_SECTION_LAYOUT or "Layout");
	panel.FeedbackHeader.Label:SetText(CHATBAR_OPTIONS_SECTION_FEEDBACK or "Feedback");
	panel.TextGapRow.Label:SetText(CHATBAR_MENU_MAIN_TEXTGAP or "Text Spacing");

	ChatBar_LayoutOptionStack(panel.AppearancePage, {
		{ frame = panel.SkinHeader, x = 0, gap = 8 },
		{ frame = panel.AltArtDropDownHolder, x = 0, gap = 4 },
		{ frame = panel.SizeHeader, x = 0, gap = 10 },
		{ frame = panel.ButtonWidthRow, x = 0, gap = 6 },
		{ frame = panel.ButtonHeightRow, x = 0, gap = 4 },
		{ frame = panel.SpacingHeader, x = 0, gap = 10 },
		{ frame = panel.ButtonPaddingRow, x = 0, gap = 6 },
		{ frame = panel.ColorBarBorderRow, x = 0, gap = 4 },
		{ frame = panel.BarBorder, x = -4, gap = 4 },
	}, 0, 0, 4);

	ChatBar_LayoutOptionStack(panel.TextPage, {
		{ frame = panel.ShowButtonText, x = -4, gap = 4 },
		{ frame = panel.ButtonTextSizeRow, x = 0, gap = 4 },
		{ frame = panel.ChannelNumbers, x = -4, gap = 4 },
		{ frame = panel.TextOnButtons, x = -4, gap = 10 },
		{ frame = panel.ReverseTextPosition, x = -4, gap = 2 },
		{ frame = panel.TextGapRow, x = 0, gap = 4 },
		{ frame = panel.HoverText, x = -4, gap = 10 },
	}, 0, -4, 4);

	ChatBar_LayoutOptionStack(panel.BehaviorPage, {
		{ frame = panel.LayoutHeader, x = 0, gap = 8 },
		{ frame = panel.VerticalButtons, x = -4, gap = 4 },
		{ frame = panel.ReverseButtons, x = -4, gap = 2 },
		{ frame = panel.ResetButton, x = 12, gap = 8 },
		{ frame = panel.FeedbackHeader, x = 0, gap = 14 },
		{ frame = panel.ButtonFlashing, x = -4, gap = 4 },
		{ frame = panel.FadeEffect, x = -4, gap = 2 },
	}, 0, 0, 4);

	panel.ButtonWidthRow.Value:SetText(ChatBar_ButtonWidth);
	panel.ButtonHeightRow.Value:SetText(ChatBar_ButtonHeight);
	panel.ButtonTextSizeRow.Value:SetText(ChatBar_ButtonTextSize);
	panel.ButtonPaddingRow.Value:SetText(ChatBar_ButtonPadding);
	panel.ColorBarBorderRow.Value:SetText(ChatBar_ColorBarBorderSize);
	panel.TextGapRow.Value:SetText(ChatBar_TextGap);

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

	showText = ChatBar_ShouldShowButtonText();
	centerText = ChatBar_ShouldCenterButtonText();
	forcedText = textOnly or octagon;
	barBorderEnabled = (not textOnly) and (not octagon) and (not colorBars);
	textSizeEnabled = showText;
	channelIdEnabled = showText;
	textOnButtonsEnabled = showText and (not forcedText);
	reverseTextEnabled = showText and (not centerText);
	textGapEnabled = showText and (not centerText);
	hoverTextEnabled = showText and (not textOnly);

	ChatBar_UpdateValueRowButtons(panel.ButtonWidthRow, ChatBar_ButtonWidth, widthMin, widthMax, true);
	ChatBar_UpdateValueRowButtons(panel.ButtonHeightRow, ChatBar_ButtonHeight, CHAT_BAR_BUTTON_HEIGHT_MIN, CHAT_BAR_BUTTON_HEIGHT_MAX, colorBars);
	ChatBar_UpdateValueRowButtons(panel.ButtonPaddingRow, ChatBar_ButtonPadding, CHAT_BAR_BUTTON_PADDING_MIN, CHAT_BAR_BUTTON_PADDING_MAX, true);
	ChatBar_UpdateValueRowButtons(panel.ColorBarBorderRow, ChatBar_ColorBarBorderSize, CHAT_BAR_COLORBAR_BORDER_MIN, CHAT_BAR_COLORBAR_BORDER_MAX, colorBars);
	ChatBar_UpdateValueRowButtons(panel.ButtonTextSizeRow, ChatBar_ButtonTextSize, CHAT_BAR_BUTTON_TEXT_SIZE_MIN, CHAT_BAR_BUTTON_TEXT_SIZE_MAX, textSizeEnabled);
	ChatBar_UpdateValueRowButtons(panel.TextGapRow, ChatBar_TextGap, CHAT_BAR_TEXT_GAP_MIN, CHAT_BAR_TEXT_GAP_MAX, textGapEnabled);

	ChatBar_SetCheckButtonEnabled(panel.BarBorder, barBorderEnabled);
	ChatBar_SetCheckButtonEnabled(panel.ShowButtonText, not forcedText);
	ChatBar_SetCheckButtonEnabled(panel.TextOnButtons, textOnButtonsEnabled);
	ChatBar_SetCheckButtonEnabled(panel.ReverseTextPosition, reverseTextEnabled);
	ChatBar_SetCheckButtonEnabled(panel.ChannelNumbers, channelIdEnabled);
	ChatBar_SetCheckButtonEnabled(panel.HoverText, hoverTextEnabled);

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

	panel.ResetButton:SetText(CHATBAR_MENU_MAIN_RESET);
	panel.AppearanceTab:SetText(CHATBAR_OPTIONS_TAB_APPEARANCE or "Skin");
	panel.TextTab:SetText(CHATBAR_OPTIONS_TAB_TEXT or "Text");
	panel.BehaviorTab:SetText(CHATBAR_OPTIONS_TAB_BEHAVIOR or "Behavior");
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

	panel.SkinHeader = ChatBar_CreateOptionsSectionHeader(panel.AppearancePage, panel:GetName() .. "SkinHeader",
		CHATBAR_OPTIONS_SECTION_SKIN or "Skin");

	panel.AltArtDropDownHolder = CreateFrame("Frame", panel:GetName() .. "AltArtDropDownHolder", panel.AppearancePage);
	panel.AltArtDropDownHolder:SetWidth(288);
	panel.AltArtDropDownHolder:SetHeight(32);

	panel.AltArtDropDown = CreateFrame("Frame", panel:GetName() .. "AltArtDropDown", panel.AltArtDropDownHolder, "UIDropDownMenuTemplate");
	panel.AltArtDropDown:SetPoint("TOPLEFT", panel.AltArtDropDownHolder, "TOPLEFT", -16, 0);
	UIDropDownMenu_SetWidth(180, panel.AltArtDropDown);
	UIDropDownMenu_Initialize(panel.AltArtDropDown, ChatBar_InitializeAltArtDropDown);

	panel.SizeHeader = ChatBar_CreateOptionsSectionHeader(panel.AppearancePage, panel:GetName() .. "SizeHeader",
		CHATBAR_OPTIONS_SECTION_SIZE or "Size");

	panel.ButtonWidthRow = ChatBar_CreateOptionsValueRow(panel.AppearancePage, panel:GetName() .. "ButtonWidthRow", CHATBAR_MENU_MAIN_BUTTONWIDTH);
	panel.ButtonWidthRow.Minus.actionFunc = ChatBar_DecreaseButtonWidth;
	panel.ButtonWidthRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonWidthRow.Plus.actionFunc = ChatBar_IncreaseButtonWidth;
	panel.ButtonWidthRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ButtonHeightRow = ChatBar_CreateOptionsValueRow(panel.AppearancePage, panel:GetName() .. "ButtonHeightRow", CHATBAR_MENU_MAIN_BUTTONHEIGHT);
	panel.ButtonHeightRow.Minus.actionFunc = ChatBar_DecreaseButtonHeight;
	panel.ButtonHeightRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonHeightRow.Plus.actionFunc = ChatBar_IncreaseButtonHeight;
	panel.ButtonHeightRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.SpacingHeader = ChatBar_CreateOptionsSectionHeader(panel.AppearancePage, panel:GetName() .. "SpacingHeader",
		CHATBAR_OPTIONS_SECTION_SPACING or "Spacing and Border");

	panel.ButtonPaddingRow = ChatBar_CreateOptionsValueRow(panel.AppearancePage, panel:GetName() .. "ButtonPaddingRow", CHATBAR_MENU_MAIN_BUTTONPADDING);
	panel.ButtonPaddingRow.Minus.actionFunc = ChatBar_DecreaseButtonPadding;
	panel.ButtonPaddingRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonPaddingRow.Plus.actionFunc = ChatBar_IncreaseButtonPadding;
	panel.ButtonPaddingRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ColorBarBorderRow = ChatBar_CreateOptionsValueRow(panel.AppearancePage, panel:GetName() .. "ColorBarBorderRow",
		CHATBAR_MENU_MAIN_COLORBARBORDER or "Color Bar Border");
	panel.ColorBarBorderRow.Minus.actionFunc = ChatBar_DecreaseColorBarBorderSize;
	panel.ColorBarBorderRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ColorBarBorderRow.Plus.actionFunc = ChatBar_IncreaseColorBarBorderSize;
	panel.ColorBarBorderRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.BarBorder = ChatBar_CreateOptionsCheckButton(panel.AppearancePage, panel:GetName() .. "BarBorder", CHATBAR_MENU_MAIN_BARBORDER);
	panel.BarBorder.optionFunc = ChatBar_Toggle_BarBorder;
	panel.BarBorder:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ShowButtonText = ChatBar_CreateOptionsCheckButton(panel.TextPage, panel:GetName() .. "ShowButtonText", CHATBAR_MENU_MAIN_SHOWTEXT);
	panel.ShowButtonText.optionFunc = ChatBar_Toggle_ButtonText;
	panel.ShowButtonText:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ButtonTextSizeRow = ChatBar_CreateOptionsValueRow(panel.TextPage, panel:GetName() .. "ButtonTextSizeRow", CHATBAR_MENU_MAIN_TEXTSIZE);
	panel.ButtonTextSizeRow.Minus.actionFunc = ChatBar_DecreaseButtonTextSize;
	panel.ButtonTextSizeRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.ButtonTextSizeRow.Plus.actionFunc = ChatBar_IncreaseButtonTextSize;
	panel.ButtonTextSizeRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.ChannelNumbers = ChatBar_CreateOptionsCheckButton(panel.TextPage, panel:GetName() .. "ChannelNumbers", CHATBAR_MENU_MAIN_CHANNELID);
	panel.ChannelNumbers.optionFunc = ChatBar_Toggle_TextChannelNumbers;
	panel.ChannelNumbers:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.TextOnButtons = ChatBar_CreateOptionsCheckButton(panel.TextPage, panel:GetName() .. "TextOnButtons", CHATBAR_MENU_MAIN_TEXTONBUTTONS);
	panel.TextOnButtons.optionFunc = ChatBar_Toggle_TextOrientation;
	panel.TextOnButtons:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ReverseTextPosition = ChatBar_CreateOptionsCheckButton(panel.TextPage, panel:GetName() .. "ReverseTextPosition", CHATBAR_MENU_MAIN_REVERSETEXT);
	panel.ReverseTextPosition.optionFunc = ChatBar_Toggle_ReverseTextPosition;
	panel.ReverseTextPosition:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.TextGapRow = ChatBar_CreateOptionsValueRow(panel.TextPage, panel:GetName() .. "TextGapRow",
		CHATBAR_MENU_MAIN_TEXTGAP or "Text Spacing");
	panel.TextGapRow.Minus.actionFunc = ChatBar_DecreaseTextGap;
	panel.TextGapRow.Minus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);
	panel.TextGapRow.Plus.actionFunc = ChatBar_IncreaseTextGap;
	panel.TextGapRow.Plus:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.HoverText = ChatBar_CreateOptionsCheckButton(panel.TextPage, panel:GetName() .. "HoverText", CHATBAR_MENU_MAIN_HOVERTEXT);
	panel.HoverText.optionFunc = ChatBar_Toggle_HoverText;
	panel.HoverText:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.LayoutHeader = ChatBar_CreateOptionsSectionHeader(panel.BehaviorPage, panel:GetName() .. "LayoutHeader",
		CHATBAR_OPTIONS_SECTION_LAYOUT or "Layout");

	panel.VerticalButtons = ChatBar_CreateOptionsCheckButton(panel.BehaviorPage, panel:GetName() .. "VerticalButtons", CHATBAR_MENU_MAIN_VERTICAL);
	panel.VerticalButtons.optionFunc = ChatBar_Toggle_VerticalButtonOrientationSlide;
	panel.VerticalButtons:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ReverseButtons = ChatBar_CreateOptionsCheckButton(panel.BehaviorPage, panel:GetName() .. "ReverseButtons", CHATBAR_MENU_MAIN_REVERSE);
	panel.ReverseButtons.optionFunc = ChatBar_Toggle_AlternateButtonOrientationSlide;
	panel.ReverseButtons:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.ResetButton = ChatBar_CreateOptionsActionButton(panel.BehaviorPage, panel:GetName() .. "ResetButton", 130, CHATBAR_MENU_MAIN_RESET);
	panel.ResetButton.actionFunc = ChatBar_Reset;
	panel.ResetButton:SetScript("OnClick", ChatBar_OptionsActionButton_OnClick);

	panel.FeedbackHeader = ChatBar_CreateOptionsSectionHeader(panel.BehaviorPage, panel:GetName() .. "FeedbackHeader",
		CHATBAR_OPTIONS_SECTION_FEEDBACK or "Feedback");

	panel.ButtonFlashing = ChatBar_CreateOptionsCheckButton(panel.BehaviorPage, panel:GetName() .. "ButtonFlashing", CHATBAR_MENU_MAIN_BUTTONFLASHING);
	panel.ButtonFlashing.optionFunc = ChatBar_Toggle_ButtonFlashing;
	panel.ButtonFlashing:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

	panel.FadeEffect = ChatBar_CreateOptionsCheckButton(panel.BehaviorPage, panel:GetName() .. "FadeEffect", CHATBAR_MENU_MAIN_FADE);
	panel.FadeEffect.optionFunc = ChatBar_Toggle_FadeEffect;
	panel.FadeEffect:SetScript("OnClick", ChatBar_OptionsCheckButton_OnClick);

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
	panel.ChannelScrollFrame:SetHeight(310);

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
	ChatBar_UpdateOptionsPanel();
end