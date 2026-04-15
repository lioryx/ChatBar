--------------------------------------------------
-- Frame Scripts And Update Functions
--------------------------------------------------

local function ChatBar_UpdateButtonFace(buttonIndex)
	local button = getglobal("ChatBarFrameButton" .. buttonIndex);
	local text = getglobal("ChatBarFrameButton" .. buttonIndex .. "Text");
	local center = getglobal("ChatBarFrameButton" .. buttonIndex .. "Center");
	local background = getglobal("ChatBarFrameButton" .. buttonIndex .. "Background");
	local chatTypeInfo = button and button.ChatID and ChatBar_ChatTypes[button.ChatID];
	local colorInfo = chatTypeInfo and (ChatTypeInfo[chatTypeInfo.type] or ChatTypeInfo[chatTypeInfo.colorType] or ChatTypeInfo["SYSTEM"]);

	if (ChatBar_IsOctagonArt()) then
		background:SetTexture("Interface\\AddOns\\ChatBar\\SkinOctagon\\BG");
		background:SetVertexColor(1, 1, 1);
		background:SetAlpha(1);
	else
		background:SetAlpha(ChatBar_IsTextOnlyArt() and 0 or 1);
	end

	if (ChatBar_IsOctagonArt()) then
		center:SetTexture(nil);
		center:SetAlpha(0);
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
		text:Show();
	else
		text:Hide();
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
		local colorInfo = chatTypeInfo and (ChatTypeInfo[chatTypeInfo.type] or ChatTypeInfo[chatTypeInfo.colorType] or ChatTypeInfo["SYSTEM"]);

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
		ChatBar_UpdateArt();
		ChatBar_UpdateButtonOrientation();
		ChatBar_UpdateButtonSizes();
		ChatBar_UpdateButtonFlashing();
		ChatBar_UpdateBarBorder();
		ChatBar_UpdateButtonText();

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
				(this:GetWidth() <= (ChatBar_GetCollapsedBarSize() + 1)) and
				(this:GetHeight() <= (ChatBar_GetCollapsedBarSize() + 1)) then
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

function ChatBar_UpdateButtons()
	ChatBar_BarTypes = {};
	local i = 1;
	local buttonIndex = 1;
	while (ChatBar_ChatTypes[i]) and (buttonIndex <= CHAT_BAR_MAX_BUTTONS) do
		if (ChatBar_ChatTypes[i].show()) then
			local chatTypeInfo = ChatBar_ChatTypes[i];
			local info = ChatTypeInfo[chatTypeInfo.type] or ChatTypeInfo[chatTypeInfo.colorType] or ChatTypeInfo["SYSTEM"];
			ChatBar_BarTypes[ChatBar_ChatTypes[i].type] = buttonIndex;
			getglobal("ChatBarFrameButton" .. buttonIndex .. "Highlight"):SetVertexColor(info.r, info.g, info.b);
			getglobal("ChatBarFrameButton" .. buttonIndex .. "Flash"):SetVertexColor(info.r, info.g, info.b);
			getglobal("ChatBarFrameButton" .. buttonIndex).ChatID = i;
			getglobal("ChatBarFrameButton" .. buttonIndex):Show();
			ChatBar_UpdateButtonFace(buttonIndex);
			buttonIndex = buttonIndex + 1;
		end
		i = i + 1;
	end
	local size = ChatBar_GetBarSizeForCount(buttonIndex - 1);
	if (ChatBar_VerticalDisplay) then
		ChatBarFrame:SetWidth(ChatBar_ButtonSize);
		if (ChatBarFrame.slidingEnabled and ChatBarFrame:GetTop()) then
			ChatBar_StartSlidingTo(size);
		else
			ChatBarFrame:SetHeight(size);
		end
	else
		ChatBarFrame:SetHeight(ChatBar_ButtonSize);
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
		button:SetWidth(ChatBar_ButtonSize);
		button:SetHeight(ChatBar_ButtonSize);
		text:SetWidth(ChatBar_ButtonSize + 8);
		text:SetHeight(ChatBar_ButtonTextSize + 4);
		text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", ChatBar_ButtonTextSize);
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
		if (ChatBar_ShouldCenterButtonText()) then
			button.Text:SetPoint("CENTER", button);
		else
			button.Text:SetPoint("RIGHT", button, "LEFT", 0, 0);
		end
	else
		if (ChatBar_AlternateOrientation) then
			button:SetPoint("RIGHT", "ChatBarFrame", "RIGHT", -CHAT_BAR_EDGE_SIZE, 0);
		else
			button:SetPoint("LEFT", "ChatBarFrame", "LEFT", CHAT_BAR_EDGE_SIZE, 0);
		end
		if (ChatBar_ShouldCenterButtonText()) then
			button.Text:SetPoint("CENTER", button);
		else
			button.Text:SetPoint("BOTTOM", button, "TOP");
		end
	end
	for i = 2, CHAT_BAR_MAX_BUTTONS do
		button = getglobal("ChatBarFrameButton" .. i);
		button:ClearAllPoints();
		button.Text:ClearAllPoints();
		if (ChatBar_VerticalDisplay) then
			if (ChatBar_AlternateOrientation) then
				button:SetPoint("TOP", "ChatBarFrameButton" .. (i - 1), "BOTTOM", 0, -ChatBar_ButtonPadding);
			else
				button:SetPoint("BOTTOM", "ChatBarFrameButton" .. (i - 1), "TOP", 0, ChatBar_ButtonPadding);
			end
			if (ChatBar_ShouldCenterButtonText()) then
				button.Text:SetPoint("CENTER", button);
			else
				button.Text:SetPoint("RIGHT", button, "LEFT");
			end
		else
			if (ChatBar_AlternateOrientation) then
				button:SetPoint("RIGHT", "ChatBarFrameButton" .. (i - 1), "LEFT", -ChatBar_ButtonPadding, 0);
			else
				button:SetPoint("LEFT", "ChatBarFrameButton" .. (i - 1), "RIGHT", ChatBar_ButtonPadding, 0);
			end
			if (ChatBar_ShouldCenterButtonText()) then
				button.Text:SetPoint("CENTER", button);
			else
				button.Text:SetPoint("BOTTOM", button, "TOP");
			end
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
	end
end

function ChatBar_UpdateBarBorder()
	if (ChatBar_BarBorder and not ChatBar_IsTextOnlyArt() and not ChatBar_IsOctagonArt()) then
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
	if (textOnly or octagon) then
		ChatBar_TextOnButtonDisplay = true;
		ChatBar_ButtonText = true;
	end

	for i = 1, CHAT_BAR_MAX_BUTTONS do
		local upTexSpec = getglobal("ChatBarFrameButton" .. i .. "UpTex_Spec");
		local downTexSpec = getglobal("ChatBarFrameButton" .. i .. "DownTex_Spec");
		local flash = getglobal("ChatBarFrameButton" .. i .. "Flash");
		local center = getglobal("ChatBarFrameButton" .. i .. "Center");
		local background = getglobal("ChatBarFrameButton" .. i .. "Background");
		local upTexShad = getglobal("ChatBarFrameButton" .. i .. "UpTex_Shad");
		local downTexShad = getglobal("ChatBarFrameButton" .. i .. "DownTex_Shad");
		local highlight = getglobal("ChatBarFrameButton" .. i .. "Highlight");

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

		upTexSpec:SetAlpha((textOnly or octagon) and 0 or .75);
		downTexSpec:SetAlpha((textOnly or octagon) and 0 or 1);
		flash:SetAlpha((textOnly or octagon) and 0 or 1);
		center:SetAlpha(textOnly and 0 or 1);
		background:SetAlpha(textOnly and 0 or 1);
		upTexShad:SetAlpha((textOnly or octagon) and 0 or .75);
		downTexShad:SetAlpha((textOnly or octagon) and 0 or 1);
		highlight:SetAlpha((textOnly or octagon) and 0 or .75);
		ChatBar_UpdateButtonFace(i);
	end

	if (not textOnly and not octagon) then
		ChatBarFrameBackground:SetBackdrop({
			edgeFile = "Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChatBarBorder",
			bgFile = "Interface\\AddOns\\ChatBar\\" .. dir .. "\\BlackBg",
			tile = true,
			tileSize = 8,
			edgeSize = 8,
			insets = { left = 8, right = 8, top = 8, bottom = 8 },
		});
	end

	ChatBar_UpdateButtonOrientation();
	ChatBar_UpdateBarBorder();
	ChatBar_UpdateButtonText();
	ChatBar_UpdateButtonTextColors();
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
				x = ChatBarFrame:GetLeft() + ChatBar_ButtonSize;
				y = ChatBarFrame:GetBottom() + ChatBar_ButtonSize;
				ChatBarFrame:ClearAllPoints();
				ChatBarFrame:SetPoint("TOPRIGHT", "UIParent", "BOTTOMLEFT", x, y);
			else
				x = ChatBarFrame:GetRight() - ChatBar_ButtonSize;
				y = ChatBarFrame:GetTop() - ChatBar_ButtonSize;
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
end

function ChatBar_Toggle_TextOrientation()
	ChatBar_TextOnButtonDisplay = not ChatBar_TextOnButtonDisplay;
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