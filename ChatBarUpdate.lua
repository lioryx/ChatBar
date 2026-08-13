--------------------------------------------------
-- Frame Scripts And Update Functions
--------------------------------------------------

local function ChatBar_UpdateButtonFace(buttonIndex)
	local button = getglobal("ChatBarFrameButton" .. buttonIndex);
	local text = getglobal("ChatBarFrameButton" .. buttonIndex .. "Text");
	local center = getglobal("ChatBarFrameButton" .. buttonIndex .. "Center");
	local background = getglobal("ChatBarFrameButton" .. buttonIndex .. "Background");
	local chatTypeInfo = button and button.ChatID and ChatBar_ChatTypes[button.ChatID];
	local colorInfo = ChatBar_GetChatTypeColor(chatTypeInfo);
	local colorBars = ChatBar_IsColorBarArt();

	if (ChatBar_IsOctagonArt()) then
		background:SetTexture("Interface\\AddOns\\ChatBar\\SkinOctagon\\BG");
		background:SetVertexColor(1, 1, 1);
		background:SetAlpha(1);
	elseif (colorBars) then
		background:SetTexture(nil);
		background:SetAlpha(0);
	else
		background:SetAlpha(ChatBar_IsTextOnlyArt() and 0 or 1);
	end

	if (ChatBar_IsOctagonArt()) then
		center:SetTexture(nil);
		center:SetAlpha(0);
	elseif (colorBars) then
		center:SetTexture(1, 1, 1);
		center:SetAlpha(1);
	else
		center:SetTexture(ChatBar_GetButtonCenterTexturePath());
		center:SetAlpha(ChatBar_IsTextOnlyArt() and 0 or 1);
	end

	if (colorInfo and not ChatBar_IsOctagonArt()) then
		center:SetVertexColor(colorInfo.r, colorInfo.g, colorInfo.b);
	else
		center:SetVertexColor(1, 1, 1);
	end

	if (chatTypeInfo) then
		text:SetText(ChatBar_FormatButtonText(chatTypeInfo.shortText()));
	else
		text:SetText("");
	end

	if (ChatBar_ShouldShowButtonText() and chatTypeInfo) then
		if (ChatBar_HoverTextEnabled) and (not ChatBar_ShouldCenterButtonText()) then
			if (button == ChatBar_HoveredButton) then
				text:Show();
				text:SetAlpha(ChatBar_TextFadeAlpha);
			else
				text:Hide();
			end
		else
			text:Show();
			text:SetAlpha(1);
		end
	else
		text:Hide();
	end

	if (button and button.Shadow) then
		if (colorBars and chatTypeInfo) then
			button.Shadow:Show();
		else
			button.Shadow:Hide();
		end
	end
end

local function ChatBar_UpdateButtonTextColors()
	local defaultR, defaultG, defaultB = 1, .82, 0;
	if (NORMAL_FONT_COLOR) then
		defaultR = NORMAL_FONT_COLOR.r;
		defaultG = NORMAL_FONT_COLOR.g;
		defaultB = NORMAL_FONT_COLOR.b;
	end

	for i = 1, CHAT_BAR_MAX_BUTTONS do
		local button = getglobal("ChatBarFrameButton" .. i);
		local text = getglobal("ChatBarFrameButton" .. i .. "Text");
		local chatTypeInfo = button and button.ChatID and ChatBar_ChatTypes[button.ChatID];
		local colorInfo = ChatBar_GetChatTypeColor(chatTypeInfo);

		if ((ChatBar_IsTextOnlyArt() or ChatBar_IsOctagonArt()) and colorInfo) then
			text:SetTextColor(colorInfo.r, colorInfo.g, colorInfo.b);
		else
			text:SetTextColor(defaultR, defaultG, defaultB);
		end
	end
end

function ChatBar_OnLoad()
	ChatBar_InitializeFrame(this);
end

function ChatBar_ShowIf()
	return ChatBarFrame.isSliding or ChatBarFrame.isMoving or (type(ChatBarFrame.count) == "number") or
	((UIDROPDOWNMENU_OPEN_MENU == "ChatBar_DropDown" and (MouseIsOver(DropDownList1) or (UIDROPDOWNMENU_MENU_LEVEL == 2 and MouseIsOver(DropDownList2)))) == 1);
end

function ChatBar_OnEvent(event)
	if (event == "UPDATE_CHAT_COLOR") then
		ChatBarFrame.count = 0;
	elseif (event == "CHAT_MSG_CHANNEL_NOTICE") then
		ChatBarFrame.count = 0;
	elseif (event == "PARTY_MEMBERS_CHANGED") then
		ChatBarFrame.count = 0;
	elseif (event == "RAID_ROSTER_UPDATE") then
		ChatBarFrame.count = 0;
	elseif (event == "PLAYER_GUILD_UPDATE") then
		ChatBarFrame.count = 0;
	elseif (event == "CHAT_MSG_CHANNEL") and (type(arg8) == "number") then
		if (ChatBar_BarTypes["CHANNEL" .. arg8]) then
			UIFrameFlash(getglobal("ChatBarFrameButton" .. ChatBar_BarTypes["CHANNEL" .. arg8] .. "Flash"), .5, .5, 1.1);
		end
	elseif (event == "VARIABLES_LOADED") then
		ChatBar_InitializeSizeSettings();
		ChatBar_InitializePluginDefaults();
		ChatBar_InitializeFade();
		ChatBar_UpdateArt();
		ChatBar_UpdateButtonOrientation();
		ChatBar_UpdateButtonSizes();
		ChatBar_UpdateButtonFlashing();
		ChatBar_UpdateBarBorder();
		ChatBar_UpdateButtonText();
		ChatBarFrame.count = 0;

		for chatType, enabled in ChatBar_StoredStickies do
			if (enabled) then
				ChatTypeInfo[chatType].sticky = enabled;
			end
		end
	else
		if (ChatBar_BarTypes[strsub(event, 10)]) then
			UIFrameFlash(getglobal("ChatBarFrameButton" .. ChatBar_BarTypes[strsub(event, 10)] .. "Flash"), .5, .5, 1.1);
		end
	end
end

ConstantVelocityModifier = 1.25;
ConstantJerk = 3 * ConstantVelocityModifier;
ConstantSnapLimit = 2;

function ChatBar_OnUpdate(elapsed)
	if (this.slidingEnabled) and (this.isSliding) and (this.velocity) and (this.endsize) then
		local currSize = ChatBar_GetSize();
		if (math.abs(currSize - this.endsize) < ConstantSnapLimit) then
			ChatBar_SetSize(this.endsize);
			currSize = ChatBar_GetSize();
			ChatBarFrame.isSliding = nil;
			this.velocity = 0;
			if (ChatBar_VerticalDisplay_Sliding or ChatBar_AlternateDisplay_Sliding) and
				(this:GetWidth() <= (ChatBar_ButtonWidth + 1)) and
				(this:GetHeight() <= (ChatBar_ButtonHeight + 1)) then
				if (ChatBar_VerticalDisplay_Sliding) then
					ChatBar_VerticalDisplay_Sliding = nil;
					ChatBar_Toggle_VerticalButtonOrientation();
				elseif (ChatBar_AlternateDisplay_Sliding) then
					ChatBar_AlternateDisplay_Sliding = nil;
					ChatBar_Toggle_AlternateButtonOrientation();
				end
				ChatBar_UpdateOrientationPoint();
			else
				ChatBar_UpdateOrientationPoint(true);
			end
		else
			local desiredVelocity = ConstantVelocityModifier * (this.endsize - currSize);
			local acceleration = ConstantJerk * (desiredVelocity - this.velocity);
			this.velocity = this.velocity + acceleration * elapsed;
			ChatBar_SetSize(currSize + this.velocity * elapsed);
			currSize = ChatBar_GetSize();
		end
		for i = 1, CHAT_BAR_MAX_BUTTONS do
			local frame = getglobal("ChatBarFrameButton" .. i);
			if (currSize >= (ChatBar_GetBarSizeForCount(i) - 2)) then
				frame:Show();
			else
				frame:Hide();
			end
		end
	elseif (this.count) then
		if (this.count > CHAT_BAR_UPDATE_DELAY) then
			this.count = nil;
			ChatBarFrame.slidingEnabled = true;
			ChatBar_UpdateButtons();
		else
			this.count = this.count + 1;
		end
	end

	ChatBar_FadeOnUpdate(elapsed);
	ChatBar_TextFadeOnUpdate(elapsed);
end

function ChatBar_GetSize()
	if (ChatBar_VerticalDisplay) then
		return ChatBarFrame:GetHeight();
	else
		return ChatBarFrame:GetWidth();
	end
end

function ChatBar_SetSize(size)
	if (ChatBar_VerticalDisplay) then
		ChatBarFrame:SetHeight(size);
	else
		ChatBarFrame:SetWidth(size);
	end
end

local function ChatBar_GetChannelNumberFromType(typeString)
	local _, _, channelIndex = string.find(typeString, "^CHANNEL(%d+)$");
	if (channelIndex) then
		return tonumber(channelIndex);
	end
	return nil;
end

local function ChatBar_CompareChannelTypes(typeA, typeB)
	local numA = ChatBar_GetChannelNumberFromType(typeA) or 0;
	local numB = ChatBar_GetChannelNumberFromType(typeB) or 0;
	if (ChatBar_ChannelSort == "name") or (ChatBar_ChannelSort == "name_desc") then
		local _, nameA = GetChannelName(numA);
		local _, nameB = GetChannelName(numB);
		if (not nameA) then
			nameA = "";
		end
		if (not nameB) then
			nameB = "";
		end
		if (nameA ~= nameB) then
			if (ChatBar_ChannelSort == "name_desc") then
				return nameA > nameB;
			end
			return nameA < nameB;
		end
	end
	return numA < numB;
end

local function ChatBar_SortChannelEntries(entries)
	local sorted = {};
	local i;
	for i = 1, table.getn(entries) do
		sorted[i] = entries[i];
	end
	table.sort(sorted, function(a, b)
		return ChatBar_CompareChannelTypes(ChatBar_ChatTypes[a].type, ChatBar_ChatTypes[b].type);
	end);
	return sorted;
end

-- 默认顺序：非频道条目保持原位，频道组按 ChatBar_ChannelSort 排序
local function ChatBar_GetBaseDisplayOrder()
	local order = {};
	local channelEntries = {};
	local firstChannelIndex = nil;
	local lastChannelIndex = nil;
	local i;
	local count = table.getn(ChatBar_ChatTypes);

	for i = 1, count do
		if (ChatBar_GetChannelNumberFromType(ChatBar_ChatTypes[i].type)) then
			if (not firstChannelIndex) then
				firstChannelIndex = i;
			end
			lastChannelIndex = i;
			table.insert(channelEntries, i);
		end
	end

	if (not firstChannelIndex) then
		for i = 1, count do
			table.insert(order, i);
		end
		return order;
	end

	for i = 1, firstChannelIndex - 1 do
		table.insert(order, i);
	end

	local sorted = ChatBar_SortChannelEntries(channelEntries);
	for i = 1, table.getn(sorted) do
		table.insert(order, sorted[i]);
	end

	for i = lastChannelIndex + 1, count do
		table.insert(order, i);
	end

	return order;
end

local function ChatBar_GetEntryIndexByType(typeString)
	local i;
	local count = table.getn(ChatBar_ChatTypes);
	for i = 1, count do
		if (ChatBar_ChatTypes[i].type == typeString) then
			return i;
		end
	end
	return nil;
end

function ChatBar_GetDisplayOrder()
	local baseOrder = ChatBar_GetBaseDisplayOrder();
	local order = {};
	local seen = {};
	local i;

	-- 1. 用户拖拽出来的手动顺序（跳过固定末尾的条目）
	if (type(ChatBar_ButtonOrder) == "table") then
		for i = 1, table.getn(ChatBar_ButtonOrder) do
			local entryIndex = ChatBar_GetEntryIndexByType(ChatBar_ButtonOrder[i]);
			if (entryIndex) and (not ChatBar_IsPinnedEntry(entryIndex)) and (not seen[entryIndex]) then
				table.insert(order, entryIndex);
				seen[entryIndex] = true;
			end
		end
	end

	-- 2. 其余未手动排序的条目按默认顺序补齐
	for i = 1, table.getn(baseOrder) do
		local entryIndex = baseOrder[i];
		if (not seen[entryIndex]) and (not ChatBar_IsPinnedEntry(entryIndex)) then
			table.insert(order, entryIndex);
			seen[entryIndex] = true;
		end
	end

	-- 3. 固定末尾的条目（ROLL）永远排在最后
	for i = 1, table.getn(baseOrder) do
		local entryIndex = baseOrder[i];
		if (ChatBar_IsPinnedEntry(entryIndex)) then
			table.insert(order, entryIndex);
		end
	end

	return order;
end

-- 把可见按钮 sourceButton 拖到 targetButton 的位置，并保存为手动顺序
function ChatBar_MoveButtonToPosition(sourceButton, targetButton)
	local visibleTypes = {};
	local i;
	for i = 1, CHAT_BAR_MAX_BUTTONS do
		local button = getglobal("ChatBarFrameButton" .. i);
		if (button and button:IsVisible() and button.ChatID) then
			table.insert(visibleTypes, ChatBar_ChatTypes[button.ChatID].type);
		else
			break;
		end
	end

	if (not visibleTypes[sourceButton]) or (not visibleTypes[targetButton]) then
		return;
	end

	local moved = visibleTypes[sourceButton];
	table.remove(visibleTypes, sourceButton);
	table.insert(visibleTypes, targetButton, moved);

	-- 保存时去掉固定末尾条目，GetDisplayOrder 会再把它们追加到最后
	local savedOrder = {};
	for i = 1, table.getn(visibleTypes) do
		local typeString = visibleTypes[i];
		local entryIndex = ChatBar_GetEntryIndexByType(typeString);
		if (entryIndex) and (not ChatBar_IsPinnedEntry(entryIndex)) then
			table.insert(savedOrder, typeString);
		end
	end
	ChatBar_ButtonOrder = savedOrder;
	ChatBar_UpdateButtons();
end

-- 频道排序下拉框变化时，重新排序手动顺序里的频道条目
function ChatBar_ApplyChannelSortToManualOrder()
	if (type(ChatBar_ButtonOrder) ~= "table") then
		return;
	end
	local channelTypes = {};
	local i;
	for i = 1, table.getn(ChatBar_ButtonOrder) do
		local typeString = ChatBar_ButtonOrder[i];
		if (ChatBar_GetChannelNumberFromType(typeString)) then
			table.insert(channelTypes, typeString);
		end
	end
	if (table.getn(channelTypes) <= 1) then
		return;
	end

	table.sort(channelTypes, function(a, b)
		return ChatBar_CompareChannelTypes(a, b);
	end);

	local newOrder = {};
	local channelIndex = 1;
	for i = 1, table.getn(ChatBar_ButtonOrder) do
		local typeString = ChatBar_ButtonOrder[i];
		if (ChatBar_GetChannelNumberFromType(typeString)) then
			table.insert(newOrder, channelTypes[channelIndex]);
			channelIndex = channelIndex + 1;
		else
			table.insert(newOrder, typeString);
		end
	end
	ChatBar_ButtonOrder = newOrder;
end

-- 重置排序：按预设顺序排列所有按钮（ROLL 固定最后）
function ChatBar_ResetButtonOrder()
	local order = {};
	local seen = {};
	local i;
	local count = table.getn(ChatBar_ChatTypes);
	local coreTypes = {
		"SAY", "YELL", "WHISPER", "GUILD", "OFFICER", "HARDCORE",
		"PARTY", "RAID", "RAID_WARNING", "BATTLEGROUND",
	};

	ChatBar_ChannelSort = "number";

	local function addType(typeName)
		local entryIndex = ChatBar_GetEntryIndexByType(typeName);
		if (entryIndex) and (not seen[entryIndex]) then
			table.insert(order, typeName);
			seen[entryIndex] = true;
		end
	end

	-- 1. 固定核心聊天类型（按指定顺序）
	for i = 1, table.getn(coreTypes) do
		addType(coreTypes[i]);
	end

	-- 2. 其余核心类型（如 EMOTE）按原表顺序补齐
	for i = 1, count do
		local chatTypeInfo = ChatBar_ChatTypes[i];
		local typeName = chatTypeInfo.type;
		if (not ChatBar_IsPinnedEntry(i)) and (not ChatBar_GetChannelNumberFromType(typeName)) and
			(string.sub(typeName, 1, 3) ~= "CB_") and (not seen[i]) then
			table.insert(order, typeName);
			seen[i] = true;
		end
	end

	-- 3. 动态频道（按编号顺序）
	for i = 1, count do
		local chatTypeInfo = ChatBar_ChatTypes[i];
		local typeName = chatTypeInfo.type;
		if (ChatBar_GetChannelNumberFromType(typeName)) and (not seen[i]) then
			table.insert(order, typeName);
			seen[i] = true;
		end
	end

	-- 4. 插件频道（按原表顺序）
	for i = 1, count do
		local chatTypeInfo = ChatBar_ChatTypes[i];
		local typeName = chatTypeInfo.type;
		if (string.sub(typeName, 1, 3) == "CB_") and (not seen[i]) then
			table.insert(order, typeName);
			seen[i] = true;
		end
	end

	ChatBar_ButtonOrder = order;
	ChatBar_UpdateButtons();
end

function ChatBar_UpdateButtons()
	ChatBar_BarTypes = {};
	local buttonIndex = 1;
	local displayOrder = ChatBar_GetDisplayOrder();
	local i;
	for i = 1, table.getn(displayOrder) do
		if (buttonIndex > CHAT_BAR_MAX_BUTTONS) then
			break;
		end
		local entryIndex = displayOrder[i];
		local chatTypeInfo = ChatBar_ChatTypes[entryIndex];
		if (chatTypeInfo.show()) then
			local info = ChatBar_GetChatTypeColor(chatTypeInfo);
			ChatBar_BarTypes[chatTypeInfo.type] = buttonIndex;
			getglobal("ChatBarFrameButton" .. buttonIndex .. "Highlight"):SetVertexColor(info.r, info.g, info.b);
			getglobal("ChatBarFrameButton" .. buttonIndex .. "Flash"):SetVertexColor(info.r, info.g, info.b);
			getglobal("ChatBarFrameButton" .. buttonIndex).ChatID = entryIndex;
			getglobal("ChatBarFrameButton" .. buttonIndex):Show();
			ChatBar_UpdateButtonFace(buttonIndex);
			buttonIndex = buttonIndex + 1;
		end
	end
	local size = ChatBar_GetBarSizeForCount(buttonIndex - 1);
	if (ChatBar_VerticalDisplay) then
		ChatBarFrame:SetWidth(ChatBar_ButtonWidth);
		if (ChatBarFrame.slidingEnabled and ChatBarFrame:GetTop()) then
			ChatBar_StartSlidingTo(size);
		else
			ChatBarFrame:SetHeight(size);
		end
	else
		ChatBarFrame:SetHeight(ChatBar_ButtonHeight);
		if (ChatBarFrame.slidingEnabled and ChatBarFrame:GetRight()) then
			ChatBar_StartSlidingTo(size);
		else
			ChatBarFrame:SetWidth(size);
		end
	end
	while (buttonIndex <= CHAT_BAR_MAX_BUTTONS) do
		getglobal("ChatBarFrameButton" .. buttonIndex).ChatID = nil;
		ChatBar_UpdateButtonFace(buttonIndex);
		buttonIndex = buttonIndex + 1;
	end
	ChatBar_UpdateButtonTextColors();
end

function ChatBar_StartSlidingTo(size)
	ChatBarFrame.endsize = size;
	ChatBarFrame.isSliding = true;
end

function ChatBar_UpdateButtonSizes()
	for i = 1, CHAT_BAR_MAX_BUTTONS do
		local button = getglobal("ChatBarFrameButton" .. i);
		local text = getglobal("ChatBarFrameButton" .. i .. "Text");
		button:SetScale(1);
		button:SetWidth(ChatBar_ButtonWidth);
		button:SetHeight(ChatBar_ButtonHeight);
		text:SetWidth(ChatBar_ButtonWidth + 8);
		text:SetHeight(ChatBar_ButtonTextSize + 4);
		text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", ChatBar_ButtonTextSize);
		if (button.Shadow) then
			button.Shadow:SetPoint("TOPLEFT", button, "TOPLEFT", -ChatBar_ColorBarBorderSize, ChatBar_ColorBarBorderSize);
			button.Shadow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", ChatBar_ColorBarBorderSize, -ChatBar_ColorBarBorderSize);
		end
	end
end

local function ChatBar_SetButtonTextPoint(button)
	if (ChatBar_ShouldCenterButtonText()) then
		button.Text:SetPoint("CENTER", button);
	elseif (ChatBar_VerticalDisplay) then
		if (ChatBar_ReverseTextPosition) then
			button.Text:SetPoint("LEFT", button, "RIGHT", 0, 0);
		else
			button.Text:SetPoint("RIGHT", button, "LEFT", 0, 0);
		end
	else
		if (ChatBar_ReverseTextPosition) then
			button.Text:SetPoint("TOP", button, "BOTTOM", 0, 0);
		else
			button.Text:SetPoint("BOTTOM", button, "TOP", 0, 0);
		end
	end
end

function ChatBar_UpdateButtonOrientation()
	local button = ChatBarFrameButton1;
	button:ClearAllPoints();
	button.Text:ClearAllPoints();
	if (ChatBar_VerticalDisplay) then
		if (ChatBar_AlternateOrientation) then
			button:SetPoint("TOP", "ChatBarFrame", "TOP", 0, -CHAT_BAR_EDGE_SIZE);
		else
			button:SetPoint("BOTTOM", "ChatBarFrame", "BOTTOM", 0, CHAT_BAR_EDGE_SIZE);
		end
		ChatBar_SetButtonTextPoint(button);
	else
		if (ChatBar_AlternateOrientation) then
			button:SetPoint("RIGHT", "ChatBarFrame", "RIGHT", -CHAT_BAR_EDGE_SIZE, 0);
		else
			button:SetPoint("LEFT", "ChatBarFrame", "LEFT", CHAT_BAR_EDGE_SIZE, 0);
		end
		ChatBar_SetButtonTextPoint(button);
	end
	for i = 2, CHAT_BAR_MAX_BUTTONS do
		button = getglobal("ChatBarFrameButton" .. i);
		button:ClearAllPoints();
		button.Text:ClearAllPoints();
		if (ChatBar_VerticalDisplay) then
			if (ChatBar_AlternateOrientation) then
				button:SetPoint("TOP", "ChatBarFrameButton" .. (i - 1), "BOTTOM", 0, -ChatBar_GetButtonSpacing());
			else
				button:SetPoint("BOTTOM", "ChatBarFrameButton" .. (i - 1), "TOP", 0, ChatBar_GetButtonSpacing());
			end
			ChatBar_SetButtonTextPoint(button);
		else
			if (ChatBar_AlternateOrientation) then
				button:SetPoint("RIGHT", "ChatBarFrameButton" .. (i - 1), "LEFT", -ChatBar_GetButtonSpacing(), 0);
			else
				button:SetPoint("LEFT", "ChatBarFrameButton" .. (i - 1), "RIGHT", ChatBar_GetButtonSpacing(), 0);
			end
			ChatBar_SetButtonTextPoint(button);
		end
	end
end

function ChatBar_UpdateButtonFlashing()
	local frame = ChatBarFrame;
	if (ChatBar_ButtonFlashing) then
		frame:RegisterEvent("CHAT_MSG_SAY");
		frame:RegisterEvent("CHAT_MSG_YELL");
		frame:RegisterEvent("CHAT_MSG_PARTY");
		frame:RegisterEvent("CHAT_MSG_RAID");
		frame:RegisterEvent("CHAT_MSG_RAID_WARNING");
		frame:RegisterEvent("CHAT_MSG_BATTLEGROUND");
		frame:RegisterEvent("CHAT_MSG_GUILD");
		frame:RegisterEvent("CHAT_MSG_OFFICER");
		frame:RegisterEvent("CHAT_MSG_WHISPER");
		frame:RegisterEvent("CHAT_MSG_EMOTE");
		frame:RegisterEvent("CHAT_MSG_CHANNEL");
		frame:RegisterEvent("CHAT_MSG_HARDCORE");
	else
		frame:UnregisterEvent("CHAT_MSG_SAY");
		frame:UnregisterEvent("CHAT_MSG_YELL");
		frame:UnregisterEvent("CHAT_MSG_PARTY");
		frame:UnregisterEvent("CHAT_MSG_RAID");
		frame:UnregisterEvent("CHAT_MSG_RAID_WARNING");
		frame:UnregisterEvent("CHAT_MSG_BATTLEGROUND");
		frame:UnregisterEvent("CHAT_MSG_GUILD");
		frame:UnregisterEvent("CHAT_MSG_OFFICER");
		frame:UnregisterEvent("CHAT_MSG_WHISPER");
		frame:UnregisterEvent("CHAT_MSG_EMOTE");
		frame:UnregisterEvent("CHAT_MSG_CHANNEL");
		frame:UnregisterEvent("CHAT_MSG_HARDCORE");
	end
end

function ChatBar_UpdateBarBorder()
	if (ChatBar_BarBorder and not ChatBar_IsTextOnlyArt() and not ChatBar_IsOctagonArt() and not ChatBar_IsColorBarArt()) then
		ChatBarFrameBackground:Show();
	else
		ChatBarFrameBackground:Hide();
	end
end

function ChatBar_Reset()
	ChatBarFrame:ClearAllPoints();
	ChatBarFrame:SetPoint("BOTTOMLEFT", "ChatFrame1", "TOPLEFT", 0, 30);
	ChatBarFrame:SetUserPlaced(0);
end

function ChatBar_UpdateArt()
	if type(ChatBar_AltArt) == "boolean" or ChatBar_AltArt == nil or not ChatBar_AltArtDirs[ChatBar_AltArt] then
		ChatBar_AltArt = 1;
	end
	local dir = ChatBar_AltArtDirs[ChatBar_AltArt];
	local textOnly = ChatBar_IsTextOnlyArt();
	local octagon = ChatBar_IsOctagonArt();
	local colorBars = ChatBar_IsColorBarArt();
	if (textOnly or octagon) then
		ChatBar_TextOnButtonDisplay = true;
		ChatBar_ButtonText = true;
	end

	if (colorBars) then
		-- 进入条形皮肤：保存正方形尺寸，并应用条形宽高（可独立调节，不会在每次 UpdateArt 时重置）
		if (not ChatBar_StoredColorBarOverrides) or (not ChatBar_StoredColorBarOverrides.active) then
			local rememberedWidth = nil;
			local rememberedHeight = nil;
			local squareWidth = ChatBar_ButtonWidth;

			if (ChatBar_StoredColorBarOverrides) then
				if (ChatBar_StoredColorBarOverrides.colorWidth) then
					rememberedWidth = ChatBar_StoredColorBarOverrides.colorWidth;
					rememberedHeight = ChatBar_StoredColorBarOverrides.colorHeight;
				elseif (ChatBar_StoredColorBarOverrides.width) then
					-- 兼容旧格式：width/height 记录的是进入条形前的正方形尺寸
					squareWidth = ChatBar_StoredColorBarOverrides.width;
					if (squareWidth == CHAT_BAR_COLORBAR_WIDTH) then
						squareWidth = CHAT_BAR_BUTTON_WIDTH;
					end
				end
			end

			ChatBar_StoredColorBarOverrides = {
				active = true,
				squareWidth = squareWidth,
			};

			if (rememberedWidth) and (rememberedHeight) then
				ChatBar_ButtonWidth = rememberedWidth;
				ChatBar_ButtonHeight = rememberedHeight;
			else
				ChatBar_ButtonWidth = CHAT_BAR_COLORBAR_WIDTH;
				ChatBar_ButtonHeight = CHAT_BAR_COLORBAR_HEIGHT;
			end
		end
	elseif (ChatBar_StoredColorBarOverrides) and (ChatBar_StoredColorBarOverrides.active) then
		-- 离开条形皮肤：记住条形宽高，并恢复为正方形
		local squareWidth = ChatBar_StoredColorBarOverrides.squareWidth or CHAT_BAR_BUTTON_WIDTH;
		ChatBar_StoredColorBarOverrides = {
			colorWidth = ChatBar_ButtonWidth,
			colorHeight = ChatBar_ButtonHeight,
		};
		ChatBar_ButtonWidth = squareWidth;
		ChatBar_ButtonHeight = squareWidth;
	else
		-- 其它皮肤：高度始终与宽度保持一致
		ChatBar_ButtonHeight = ChatBar_ButtonWidth;
	end

	ChatBar_SyncButtonSizeToMode();

	for i = 1, CHAT_BAR_MAX_BUTTONS do
		local upTexSpec = getglobal("ChatBarFrameButton" .. i .. "UpTex_Spec");
		local downTexSpec = getglobal("ChatBarFrameButton" .. i .. "DownTex_Spec");
		local flash = getglobal("ChatBarFrameButton" .. i .. "Flash");
		local center = getglobal("ChatBarFrameButton" .. i .. "Center");
		local background = getglobal("ChatBarFrameButton" .. i .. "Background");
		local upTexShad = getglobal("ChatBarFrameButton" .. i .. "UpTex_Shad");
		local downTexShad = getglobal("ChatBarFrameButton" .. i .. "DownTex_Shad");
		local highlight = getglobal("ChatBarFrameButton" .. i .. "Highlight");
		local button = getglobal("ChatBarFrameButton" .. i);

		if (octagon) then
			center:SetTexture(nil);
			background:SetTexture("Interface\\AddOns\\ChatBar\\SkinOctagon\\BG");
			background:SetVertexColor(1, 1, 1);
			upTexSpec:SetTexture(nil);
			downTexSpec:SetTexture(nil);
			flash:SetTexture(nil);
			upTexShad:SetTexture(nil);
			downTexShad:SetTexture(nil);
			highlight:SetTexture(nil);
		elseif (colorBars) then
			center:SetTexture(1, 1, 1);
			background:SetTexture(nil);
			upTexSpec:SetTexture(nil);
			downTexSpec:SetTexture(nil);
			flash:SetTexture(nil);
			upTexShad:SetTexture(nil);
			downTexShad:SetTexture(nil);
			highlight:SetTexture(nil);
		elseif (not textOnly) then
			upTexSpec:SetTexture("Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChanButton_Up_Spec");
			downTexSpec:SetTexture("Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChanButton_Down_Spec");
			flash:SetTexture("Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChanButton_Glow_Alpha");
			center:SetTexture("Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChanButton_Center");
			background:SetTexture("Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChanButton_BG");
			upTexShad:SetTexture("Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChanButton_Up_Shad");
			downTexShad:SetTexture("Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChanButton_Down_Shad");
			highlight:SetTexture("Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChanButton_Glow_Alpha");
		end

		upTexSpec:SetAlpha((textOnly or octagon or colorBars) and 0 or .75);
		downTexSpec:SetAlpha((textOnly or octagon or colorBars) and 0 or 1);
		flash:SetAlpha((textOnly or octagon or colorBars) and 0 or 1);
		center:SetAlpha((textOnly and 0) or 1);
		background:SetAlpha((textOnly or colorBars) and 0 or 1);
		upTexShad:SetAlpha((textOnly or octagon or colorBars) and 0 or .75);
		downTexShad:SetAlpha((textOnly or octagon or colorBars) and 0 or 1);
		highlight:SetAlpha((textOnly or octagon or colorBars) and 0 or .75);
		if (button and button.Shadow) then
			if (colorBars) then
				button.Shadow:Show();
			else
				button.Shadow:Hide();
			end
		end
		ChatBar_UpdateButtonFace(i);
	end

	if (not textOnly and not octagon and not colorBars) then
		ChatBarFrameBackground:SetBackdrop({
			edgeFile = "Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChatBarBorder",
			bgFile = "Interface\\AddOns\\ChatBar\\" .. dir .. "\\BlackBg",
			tile = true,
			tileSize = 8,
			edgeSize = 8,
			insets = { left = 8, right = 8, top = 8, bottom = 8 },
		});
	end

	ChatBar_UpdateButtonSizes();
	ChatBar_UpdateButtonOrientation();
	ChatBar_UpdateBarBorder();
	ChatBar_UpdateButtonText();
	ChatBar_UpdateButtonTextColors();
	ChatBar_UpdateButtons();
end

function ChatBar_Toggle_VerticalButtonOrientationSlide()
	if (not ChatBarFrame.isMoving) then
		ChatBar_VerticalDisplay_Sliding = true;
		ChatBar_StartSlidingTo(ChatBar_GetCollapsedBarSize());
	end
end

function ChatBar_Toggle_AlternateButtonOrientationSlide()
	if (not ChatBarFrame.isMoving) then
		ChatBar_AlternateDisplay_Sliding = true;
		ChatBar_StartSlidingTo(ChatBar_GetCollapsedBarSize());
	end
end

function ChatBar_Toggle_VerticalButtonOrientation()
	if (ChatBar_VerticalDisplay) then
		ChatBar_VerticalDisplay = false;
	else
		ChatBar_VerticalDisplay = true;
	end
	ChatBar_UpdateButtonOrientation();
	ChatBar_UpdateButtons();
	ChatBar_UpdateOptionsPanel();
end

function ChatBar_UpdateOrientationPoint(expanded)
	local x, y;
	if (ChatBarFrame:IsUserPlaced()) then
		if (expanded) then
			if (ChatBar_AlternateOrientation) then
				x = ChatBarFrame:GetRight();
				y = ChatBarFrame:GetTop();
				ChatBarFrame:ClearAllPoints();
				ChatBarFrame:SetPoint("TOPRIGHT", "UIParent", "BOTTOMLEFT", x, y);
			else
				x = ChatBarFrame:GetLeft();
				y = ChatBarFrame:GetBottom();
				ChatBarFrame:ClearAllPoints();
				ChatBarFrame:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", x, y);
			end
		else
			if (ChatBar_AlternateOrientation) then
				x = ChatBarFrame:GetLeft() + ChatBar_ButtonWidth;
				y = ChatBarFrame:GetBottom() + ChatBar_ButtonHeight;
				ChatBarFrame:ClearAllPoints();
				ChatBarFrame:SetPoint("TOPRIGHT", "UIParent", "BOTTOMLEFT", x, y);
			else
				x = ChatBarFrame:GetRight() - ChatBar_ButtonWidth;
				y = ChatBarFrame:GetTop() - ChatBar_ButtonHeight;
				ChatBarFrame:ClearAllPoints();
				ChatBarFrame:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", x, y);
			end
		end
	else
		if (ChatBar_AlternateOrientation) then
			ChatBarFrame:ClearAllPoints();
			ChatBarFrame:SetPoint("TOPRIGHT", "ChatFrame1", "TOPLEFT", 16, 46);
		else
			ChatBarFrame:ClearAllPoints();
			ChatBarFrame:SetPoint("BOTTOMLEFT", "ChatFrame1", "TOPLEFT", 0, 30);
		end
	end
end

function ChatBar_Toggle_AlternateButtonOrientation()
	ChatBar_AlternateOrientation = not ChatBar_AlternateOrientation;
	ChatBar_UpdateButtonOrientation();
	ChatBar_UpdateButtons();
	ChatBar_UpdateOptionsPanel();
end

function ChatBar_Toggle_TextOrientation()
	ChatBar_TextOnButtonDisplay = not ChatBar_TextOnButtonDisplay;
	ChatBar_UpdateButtonOrientation();
end

function ChatBar_Toggle_ReverseTextPosition()
	ChatBar_ReverseTextPosition = not ChatBar_ReverseTextPosition;
	ChatBar_UpdateButtonOrientation();
end

function ChatBar_Toggle_ButtonFlashing()
	ChatBar_ButtonFlashing = not ChatBar_ButtonFlashing;
	ChatBar_UpdateButtonFlashing();
end

function ChatBar_Toggle_BarBorder()
	ChatBar_BarBorder = not ChatBar_BarBorder;
	ChatBar_UpdateBarBorder();
end

function ChatBar_UpdateButtonText()
	for i = 1, CHAT_BAR_MAX_BUTTONS do
		ChatBar_UpdateButtonFace(i);
	end
end

function ChatBar_Toggle_ButtonText()
	ChatBar_ButtonText = not ChatBar_ButtonText;
	ChatBar_UpdateButtonText();
end

function ChatBar_Toggle_TextChannelNumbers()
	ChatBar_TextChannelNumbers = not ChatBar_TextChannelNumbers;
	ChatBar_UpdateButtons();
end

ChatBar_CreateUI();