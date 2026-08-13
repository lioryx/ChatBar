--------------------------------------------------------------------------
-- ChatBar.lua
--------------------------------------------------------------------------
--[[
ChatBar

Author: AnduinLothar KarlKFI@cosmosui.org
Graphics: Vynn

-Button Bar for openning chat messages of each type.
]] --

--------------------------------------------------
-- Globals
--------------------------------------------------

CHAT_BAR_BUTTON_SIZE = 16; -- legacy default (square); migrated into width/height
CHAT_BAR_BUTTON_WIDTH = 16;
CHAT_BAR_BUTTON_HEIGHT = 16;
CHAT_BAR_BUTTON_TEXT_SIZE = 12;
CHAT_BAR_BUTTON_PADDING = 0;
CHAT_BAR_EDGE_SIZE = 10;   -- amount of space that the bar extends past the first/last button
CHAT_BAR_MAX_BUTTONS = 45;
CHAT_BAR_UPDATE_DELAY = 30;
CHAT_BAR_BUTTON_SIZE_MIN = 12;
CHAT_BAR_BUTTON_SIZE_MAX = 32;
CHAT_BAR_BUTTON_SIZE_STEP = 2;
CHAT_BAR_BUTTON_WIDTH_MIN = 4;
CHAT_BAR_BUTTON_WIDTH_MAX = 200;
CHAT_BAR_BUTTON_WIDTH_STEP = 2;
CHAT_BAR_BUTTON_HEIGHT_MIN = 2;
CHAT_BAR_BUTTON_HEIGHT_MAX = 64;
CHAT_BAR_BUTTON_HEIGHT_STEP = 2;
CHAT_BAR_BUTTON_TEXT_SIZE_MIN = 8;
CHAT_BAR_BUTTON_TEXT_SIZE_MAX = 18;
CHAT_BAR_BUTTON_TEXT_SIZE_STEP = 1;
CHAT_BAR_BUTTON_PADDING_MIN = 0;
CHAT_BAR_BUTTON_PADDING_MAX = 10;
CHAT_BAR_BUTTON_PADDING_STEP = 1;
CHAT_BAR_COLORBAR_BORDER = 2;   -- default border size for ColorBars skin
CHAT_BAR_COLORBAR_BORDER_MIN = 0;
CHAT_BAR_COLORBAR_BORDER_MAX = 10;
CHAT_BAR_COLORBAR_BORDER_STEP = 1;
CHAT_BAR_COLORBAR_WIDTH = 38;   -- default width when entering ColorBars skin
CHAT_BAR_COLORBAR_HEIGHT = 4;   -- default height when entering ColorBars skin
ChatBar_VerticalDisplay = false;
ChatBar_AlternateOrientation = false;
ChatBar_TextOnButtonDisplay = false;
ChatBar_ButtonFlashing = true;
ChatBar_BarBorder = true;
ChatBar_ButtonText = true;
ChatBar_ReverseTextPosition = false;
ChatBar_TextChannelNumbers = false;
ChatBar_VerticalDisplay_Sliding = false;
ChatBar_AlternateDisplay_Sliding = false;
ChatBar_LastTell = nil;
ChatBar_StoredStickies = {};
ChatBar_HiddenButtons = {};
ChatBar_AltArtDirs = { "SkinSolid", "SkinSquares", "TextOnly", "SkinOctagon", "ColorBars" };
ChatBar_ButtonScale = 1;
ChatBar_ButtonSize = CHAT_BAR_BUTTON_SIZE;
ChatBar_ButtonWidth = CHAT_BAR_BUTTON_WIDTH;
ChatBar_ButtonHeight = CHAT_BAR_BUTTON_HEIGHT;
ChatBar_ButtonTextSize = CHAT_BAR_BUTTON_TEXT_SIZE;
ChatBar_ButtonPadding = CHAT_BAR_BUTTON_PADDING;
ChatBar_ColorBarBorderSize = CHAT_BAR_COLORBAR_BORDER;
ChatBar_CountdownLen = 6;
ChatBar_TrackingMode = "modern";
ChatBar_ChannelSort = "number";
ChatBar_ButtonOrder = nil;
ChatBar_DragSourceButton = nil;
ChatBar_PluginDefaultsInitialized = false;

CHAT_BAR_ALPHA_HIDDEN = 0.0;
CHAT_BAR_ALPHA_SHOWN = 1.0;
CHAT_BAR_ALPHA_FADE_TIME = 0.3;
CHAT_BAR_HOVER_DELAY = 0.2;
CHAT_BAR_HOVER_ZONE_EXTEND = 20;
CHAT_BAR_TEXTFADE_TIME = 0.2;
ChatBar_FadeEnabled = true;
ChatBar_IsHovering = false;
ChatBar_FadeTimer = 0;
ChatBar_TargetAlpha = CHAT_BAR_ALPHA_SHOWN;
ChatBar_CurrentAlpha = CHAT_BAR_ALPHA_SHOWN;
ChatBar_HoverTimer = 0;
ChatBar_IsFading = false;
ChatBar_ManualShow = false;
ChatBar_ManualShowUntil = 0;
ChatBar_HoverTextEnabled = true;
ChatBar_TextFadeAlpha = 0.0;
ChatBar_TextFadeTarget = 0.0;
ChatBar_TextFadeTimer = 0;
ChatBar_TextFadeIsFading = false;
ChatBar_HoveredButton = nil;

function ChatBar_IsTextOnlyArt()
	return ChatBar_AltArtDirs[ChatBar_AltArt] == "TextOnly";
end

function ChatBar_IsOctagonArt()
	return ChatBar_AltArtDirs[ChatBar_AltArt] == "SkinOctagon";
end

function ChatBar_IsColorBarArt()
	return ChatBar_AltArtDirs[ChatBar_AltArt] == "ColorBars";
end

function ChatBar_GetButtonSpacing()
	local spacing = ChatBar_ButtonPadding;
	if (ChatBar_IsColorBarArt()) then
		-- 彩色条形模式下边框框体在按钮两侧各向外延伸 ChatBar_ColorBarBorderSize 像素，
		-- 相邻按钮的边框共占 2 倍边框宽度，间距必须加上这个大小才不会重叠
		spacing = spacing + (ChatBar_ColorBarBorderSize * 2);
	end
	return spacing;
end

function ChatBar_ShouldCenterButtonText()
	return ChatBar_TextOnButtonDisplay or ChatBar_IsTextOnlyArt() or ChatBar_IsOctagonArt();
end

function ChatBar_ShouldShowButtonText()
	return ChatBar_ButtonText or ChatBar_IsTextOnlyArt() or ChatBar_IsOctagonArt();
end

function ChatBar_NormalizeSizeSetting(value, defaultValue, minValue, maxValue, step)
	if (type(value) ~= "number") then
		value = defaultValue;
	end

	value = math.floor((value / step) + 0.5) * step;
	if (value < minValue) then
		value = minValue;
	elseif (value > maxValue) then
		value = maxValue;
	end

	return value;
end

function ChatBar_InitializePluginDefaults()
	if (ChatBar_PluginDefaultsInitialized) then
		return;
	end
	ChatBar_PluginDefaultsInitialized = true;
	if (not ChatBar_ChatTypes) then
		return;
	end

	-- 默认隐藏所有插件频道按钮（CB_ 开头的扩展条目）
	local i = 1;
	while (ChatBar_ChatTypes[i]) do
		local entry = ChatBar_ChatTypes[i];
		if (string.sub(entry.type, 1, 3) == "CB_") then
			ChatBar_HiddenButtons[entry.text()] = true;
		end
		i = i + 1;
	end

	-- ROLL 按钮必须始终存在，清除历史隐藏状态
	ChatBar_HiddenButtons[CHATBAR_ROLL] = nil;
end

function ChatBar_InitializeSizeSettings()
	local migratedButtonSize = nil;

	if (type(ChatBar_ButtonScale) == "number") and (ChatBar_ButtonScale ~= 1) then
		migratedButtonSize = math.floor((CHAT_BAR_BUTTON_SIZE * ChatBar_ButtonScale) + 0.5);
	end

	if (type(ChatBar_ButtonSize) ~= "number") then
		ChatBar_ButtonSize = migratedButtonSize or CHAT_BAR_BUTTON_SIZE;
	elseif (migratedButtonSize and ChatBar_ButtonSize == CHAT_BAR_BUTTON_SIZE) then
		ChatBar_ButtonSize = migratedButtonSize;
	end

	ChatBar_ButtonSize = ChatBar_NormalizeSizeSetting(ChatBar_ButtonSize, CHAT_BAR_BUTTON_SIZE,
		CHAT_BAR_BUTTON_SIZE_MIN, CHAT_BAR_BUTTON_SIZE_MAX, CHAT_BAR_BUTTON_SIZE_STEP);

	if (type(ChatBar_ButtonWidth) ~= "number") then
		ChatBar_ButtonWidth = ChatBar_ButtonSize;
	end
	if (type(ChatBar_ButtonHeight) ~= "number") then
		ChatBar_ButtonHeight = ChatBar_ButtonSize;
	end

	ChatBar_SyncButtonSizeToMode();
	ChatBar_ButtonTextSize = ChatBar_NormalizeSizeSetting(ChatBar_ButtonTextSize, CHAT_BAR_BUTTON_TEXT_SIZE,
		CHAT_BAR_BUTTON_TEXT_SIZE_MIN, CHAT_BAR_BUTTON_TEXT_SIZE_MAX, CHAT_BAR_BUTTON_TEXT_SIZE_STEP);
	ChatBar_ButtonPadding = ChatBar_NormalizeSizeSetting(ChatBar_ButtonPadding, CHAT_BAR_BUTTON_PADDING,
		CHAT_BAR_BUTTON_PADDING_MIN, CHAT_BAR_BUTTON_PADDING_MAX, CHAT_BAR_BUTTON_PADDING_STEP);
	ChatBar_ColorBarBorderSize = ChatBar_NormalizeSizeSetting(ChatBar_ColorBarBorderSize, CHAT_BAR_COLORBAR_BORDER,
		CHAT_BAR_COLORBAR_BORDER_MIN, CHAT_BAR_COLORBAR_BORDER_MAX, CHAT_BAR_COLORBAR_BORDER_STEP);

	if (type(ChatBar_CountdownLen) ~= "number") then
		ChatBar_CountdownLen = 6;
	end
	if (type(ChatBar_TrackingMode) ~= "string") then
		ChatBar_TrackingMode = "modern";
	end
	if (ChatBar_ChannelSort ~= "name") and (ChatBar_ChannelSort ~= "name_desc") then
		ChatBar_ChannelSort = "number";
	end

	ChatBar_ButtonScale = nil;
end

-- 非彩色条形：宽高保持一致（正方形）；彩色条形：宽高可独立设置
function ChatBar_SyncButtonSizeToMode()
	local squareMin;
	local squareMax;

	if (ChatBar_IsColorBarArt()) then
		ChatBar_ButtonWidth = ChatBar_NormalizeSizeSetting(ChatBar_ButtonWidth, CHAT_BAR_BUTTON_WIDTH,
			CHAT_BAR_BUTTON_WIDTH_MIN, CHAT_BAR_BUTTON_WIDTH_MAX, CHAT_BAR_BUTTON_WIDTH_STEP);
		ChatBar_ButtonHeight = ChatBar_NormalizeSizeSetting(ChatBar_ButtonHeight, CHAT_BAR_BUTTON_HEIGHT,
			CHAT_BAR_BUTTON_HEIGHT_MIN, CHAT_BAR_BUTTON_HEIGHT_MAX, CHAT_BAR_BUTTON_HEIGHT_STEP);
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

	ChatBar_ButtonWidth = ChatBar_NormalizeSizeSetting(ChatBar_ButtonWidth, CHAT_BAR_BUTTON_WIDTH,
		squareMin, squareMax, CHAT_BAR_BUTTON_WIDTH_STEP);
	ChatBar_ButtonHeight = ChatBar_ButtonWidth;
end

function ChatBar_GetPrimaryButtonExtent()
	if (ChatBar_VerticalDisplay) then
		return ChatBar_ButtonHeight;
	end
	return ChatBar_ButtonWidth;
end

function ChatBar_GetSecondaryButtonExtent()
	if (ChatBar_VerticalDisplay) then
		return ChatBar_ButtonWidth;
	end
	return ChatBar_ButtonHeight;
end

function ChatBar_GetBarSizeForCount(buttonCount)
	local spacing = 0;
	local buttonExtent = ChatBar_GetPrimaryButtonExtent();
	local minSize = CHAT_BAR_EDGE_SIZE * 2;
	if (buttonExtent > minSize) then
		minSize = buttonExtent;
	end
	if (buttonCount <= 0) then
		return minSize;
	end
	if (buttonCount > 1) then
		spacing = (buttonCount - 1) * ChatBar_GetButtonSpacing();
	end
	return (buttonCount * buttonExtent) + spacing + (CHAT_BAR_EDGE_SIZE * 2);
end

function ChatBar_GetCollapsedBarSize()
	return ChatBar_GetPrimaryButtonExtent();
end

function ChatBar_GetFirstCharacter(text)
	if (type(text) ~= "string") or (text == "") then
		return text;
	end

	local firstByte = string.byte(text, 1);
	local byteCount = 1;
	if (firstByte >= 240) then
		byteCount = 4;
	elseif (firstByte >= 224) then
		byteCount = 3;
	elseif (firstByte >= 192) then
		byteCount = 2;
	end

	return string.sub(text, 1, byteCount);
end

function ChatBar_FormatButtonText(text)
	if (type(text) == "string") then
		return string.upper(text);
	end
	return text;
end

function ChatBar_GetButtonCenterTexturePath()
	if (ChatBar_IsColorBarArt()) then
		return nil;
	end
	local dir = ChatBar_AltArtDirs[ChatBar_AltArt] or ChatBar_AltArtDirs[1];
	return "Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChanButton_Center";
end

function ChatBar_GetChatTypeColor(chatTypeInfo)
	if (not chatTypeInfo) then
		return ChatTypeInfo["SYSTEM"];
	end
	if (chatTypeInfo.customColor) then
		return chatTypeInfo.customColor;
	end
	return ChatTypeInfo[chatTypeInfo.type] or ChatTypeInfo[chatTypeInfo.colorType] or ChatTypeInfo["SYSTEM"];
end

-- 始终固定在末尾的按钮（如 ROLL）不能拖拽，且始终排在最后
function ChatBar_IsPinnedEntry(entryIndex)
	local chatTypeInfo = entryIndex and ChatBar_ChatTypes[entryIndex];
	return chatTypeInfo and chatTypeInfo.alwaysShow;
end

function ChatBar_GetFirstWord(s)
	local firstWord, count = gsub(s, "%s.*", "");
	return firstWord;
end

function ChatBar_Print(text)
	local color = ChatTypeInfo["SYSTEM"];
	local frame = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME;
	frame:AddMessage(text, color.r, color.g, color.b);
end

--------------------------------------------------
-- Hover fade (show on hover over chat window, hide otherwise)
--------------------------------------------------

function ChatBar_SetAlpha(alpha, instant)
	if (not ChatBarFrame) then
		return;
	end
	if (instant) then
		ChatBarFrame:SetAlpha(alpha);
		ChatBar_CurrentAlpha = alpha;
		ChatBar_IsFading = false;
	else
		ChatBar_TargetAlpha = alpha;
		ChatBar_IsFading = true;
		ChatBar_FadeTimer = 0;
	end
end

function ChatBar_ForceShow()
	if (not ChatBar_FadeEnabled) then
		return;
	end
	ChatBar_ManualShow = true;
	ChatBar_ManualShowUntil = GetTime() + 10;
	ChatBar_SetAlpha(CHAT_BAR_ALPHA_SHOWN, true);
end

function ChatBar_ForceHide()
	if (not ChatBar_FadeEnabled) then
		return;
	end
	ChatBar_ManualShow = false;
	ChatBar_SetAlpha(CHAT_BAR_ALPHA_HIDDEN, true);
end

function ChatBar_Toggle_FadeEffect()
	ChatBar_FadeEnabled = not ChatBar_FadeEnabled;
	if (ChatBar_FadeEnabled) then
		if (not ChatBar_IsHovering) and (not ChatBar_ManualShow) then
			ChatBar_SetAlpha(CHAT_BAR_ALPHA_HIDDEN, true);
		end
	else
		ChatBar_SetAlpha(CHAT_BAR_ALPHA_SHOWN, true);
	end
	local status = ChatBar_FadeEnabled and CHATBAR_FADE_ON or CHATBAR_FADE_OFF;
	DEFAULT_CHAT_FRAME:AddMessage("ChatBar: " .. (CHATBAR_MENU_MAIN_FADE or "Auto-hide") .. " " .. status, 1, 1, 0);
end

function ChatBar_InitializeFade()
	if (not ChatBarFrame) then
		return;
	end
	ChatBarFrame:Show();
	if (ChatBar_FadeEnabled == nil) then
		ChatBar_FadeEnabled = true;
	end
	ChatBarFrame.lastHoverCheck = 0;
	ChatBar_SetAlpha(CHAT_BAR_ALPHA_SHOWN, true);
	if (ChatBar_FadeEnabled) then
		ChatBar_SetAlpha(CHAT_BAR_ALPHA_HIDDEN, true);
	end
end

function ChatBar_IsMouseOverFrame(frame)
	if (not frame) or (not frame:IsVisible()) then
		return false;
	end
	if (not frame.GetLeft) or (not frame.GetRight) or (not frame.GetTop) or (not frame.GetBottom) then
		return false;
	end

	local scale = 1.0;
	if (UIParent and UIParent.GetScale) then
		scale = UIParent:GetScale() or 1.0;
	end

	local x, y = GetCursorPosition();
	if (not x) or (not y) then
		return false;
	end
	x = x / scale;
	y = y / scale;

	local left, right, top, bottom;
	local success = pcall(function()
		left = frame:GetLeft();
		right = frame:GetRight();
		top = frame:GetTop();
		bottom = frame:GetBottom();
	end);
	if (not success) or (not left) or (not right) or (not top) or (not bottom) then
		return false;
	end

	local hoverExtend = CHAT_BAR_HOVER_ZONE_EXTEND;
	left = left - hoverExtend;
	right = right + hoverExtend;
	bottom = bottom - hoverExtend;
	top = top + hoverExtend;

	return (x >= left) and (x <= right) and (y >= bottom) and (y <= top);
end

-- 返回当前鼠标下方可见按钮的编号（1..N），用于拖拽排序的落点检测
function ChatBar_GetButtonIndexAtCursor()
	local scale = 1.0;
	if (UIParent and UIParent.GetScale) then
		scale = UIParent:GetScale() or 1.0;
	end
	local x, y = GetCursorPosition();
	if (not x) or (not y) then
		return nil;
	end
	x = x / scale;
	y = y / scale;

	local i;
	for i = 1, CHAT_BAR_MAX_BUTTONS do
		local button = getglobal("ChatBarFrameButton" .. i);
		if (button and button:IsVisible() and button.ChatID) then
			local left = button:GetLeft();
			local right = button:GetRight();
			local bottom = button:GetBottom();
			local top = button:GetTop();
			if (left and right and bottom and top) then
				if (x >= left) and (x <= right) and (y >= bottom) and (y <= top) then
					return i;
				end
			end
		end
	end
	return nil;
end

function ChatBar_GetChatFrameFullArea()
	local frames = {};
	local i;
	for i = 1, 10 do
		local chatFrame = getglobal("ChatFrame" .. i);
		if (chatFrame and chatFrame:IsVisible()) then
			table.insert(frames, chatFrame);
		end
	end

	for i = 1, 10 do
		local chatFrame = getglobal("ChatFrame" .. i);
		if (chatFrame and chatFrame.editBox and chatFrame.editBox:IsVisible()) then
			table.insert(frames, chatFrame.editBox);
		end
	end

	local chatBackground = getglobal("ChatFrame1Background");
	if (chatBackground and chatBackground:IsVisible()) then
		table.insert(frames, chatBackground);
	end

	local chatContainer = getglobal("ChatFrame1ButtonFrame");
	if (chatContainer and chatContainer:IsVisible()) then
		table.insert(frames, chatContainer);
	end

	if (DEFAULT_CHAT_FRAME) then
		local parent = DEFAULT_CHAT_FRAME:GetParent();
		if (parent and parent:IsVisible() and parent ~= UIParent) then
			table.insert(frames, parent);
		end
	end

	return frames;
end

function ChatBar_CheckMouseOverChatArea()
	if (ChatBarFrame and ChatBar_IsMouseOverFrame(ChatBarFrame)) then
		return true;
	end

	local i;
	for i = 1, CHAT_BAR_MAX_BUTTONS do
		local button = getglobal("ChatBarFrameButton" .. i);
		if (button and button:IsVisible() and ChatBar_IsMouseOverFrame(button)) then
			return true;
		end
	end

	local chatFrames = ChatBar_GetChatFrameFullArea();
	for _, frame in ipairs(chatFrames) do
		if (ChatBar_IsMouseOverFrame(frame)) then
			return true;
		end
	end

	return false;
end

function ChatBar_FadeOnUpdate(elapsed)
	if (ChatBar_IsFading) and (ChatBar_CurrentAlpha ~= ChatBar_TargetAlpha) then
		ChatBar_FadeTimer = ChatBar_FadeTimer + elapsed;
		local progress = ChatBar_FadeTimer / CHAT_BAR_ALPHA_FADE_TIME;
		if (progress > 1) then
			progress = 1;
		end
		local newAlpha = ChatBar_CurrentAlpha + (ChatBar_TargetAlpha - ChatBar_CurrentAlpha) * progress;
		if (ChatBarFrame) then
			ChatBarFrame:SetAlpha(newAlpha);
		end
		ChatBar_CurrentAlpha = newAlpha;
		if (progress >= 1) then
			ChatBar_IsFading = false;
		end
	end

	if (not ChatBar_FadeEnabled) then
		return;
	end

	if (ChatBar_ManualShow) and (GetTime() >= ChatBar_ManualShowUntil) then
		ChatBar_ManualShow = false;
	end

	if (not ChatBarFrame.lastHoverCheck) or ((GetTime() - ChatBarFrame.lastHoverCheck) > 0.05) then
		ChatBarFrame.lastHoverCheck = GetTime();
		local isOverChatArea = ChatBar_CheckMouseOverChatArea();
		if (isOverChatArea) then
			ChatBar_IsHovering = true;
			ChatBar_HoverTimer = 0;
			if (ChatBar_CurrentAlpha < CHAT_BAR_ALPHA_SHOWN) then
				ChatBar_SetAlpha(CHAT_BAR_ALPHA_SHOWN, false);
			end
		else
			if (not ChatBar_ManualShow) then
				if (ChatBar_IsHovering) then
					ChatBar_IsHovering = false;
					ChatBar_HoverTimer = GetTime();
				end
				local timePassed = GetTime() - ChatBar_HoverTimer;
				if (timePassed >= CHAT_BAR_HOVER_DELAY) then
					if (ChatBar_CurrentAlpha > CHAT_BAR_ALPHA_HIDDEN) then
						ChatBar_SetAlpha(CHAT_BAR_ALPHA_HIDDEN, false);
					end
				end
			end
		end
	end
end

--------------------------------------------------
-- 文字渐隐：悬停按钮时淡入按钮短文字，移开后淡出
--------------------------------------------------

function ChatBar_TextFadeIn(button)
	local prevButton = ChatBar_HoveredButton;
	if (prevButton and prevButton ~= button and prevButton.Text) then
		prevButton.Text:SetAlpha(0);
		prevButton.Text:Hide();
	end
	ChatBar_HoveredButton = button;
	if (button.Text) then
		button.Text:Show();
		button.Text:SetAlpha(ChatBar_TextFadeAlpha);
	end
	ChatBar_TextFadeTarget = 1.0;
	ChatBar_TextFadeTimer = 0;
	ChatBar_TextFadeIsFading = true;
end

function ChatBar_TextFadeOut()
	if (not ChatBar_HoveredButton) then
		return;
	end
	ChatBar_TextFadeTarget = 0.0;
	ChatBar_TextFadeTimer = 0;
	ChatBar_TextFadeIsFading = true;
end

function ChatBar_TextFadeOnUpdate(elapsed)
	if (not ChatBar_TextFadeIsFading) then
		return;
	end
	ChatBar_TextFadeTimer = ChatBar_TextFadeTimer + elapsed;
	local progress = ChatBar_TextFadeTimer / CHAT_BAR_TEXTFADE_TIME;
	if (progress > 1) then
		progress = 1;
	end
	local newAlpha = ChatBar_TextFadeAlpha + (ChatBar_TextFadeTarget - ChatBar_TextFadeAlpha) * progress;
	ChatBar_TextFadeAlpha = newAlpha;
	local button = ChatBar_HoveredButton;
	if (button and button.Text) then
		button.Text:SetAlpha(newAlpha);
	end
	if (progress >= 1) then
		ChatBar_TextFadeIsFading = false;
		if (ChatBar_TextFadeTarget <= 0) then
			if (button and button.Text) then
				button.Text:Hide();
			end
			ChatBar_HoveredButton = nil;
		end
	end
end

function ChatBar_Toggle_HoverText()
	ChatBar_HoverTextEnabled = not ChatBar_HoverTextEnabled;
	ChatBar_HoveredButton = nil;
	ChatBar_TextFadeIsFading = false;
	if (ChatBar_HoverTextEnabled) then
		ChatBar_TextFadeAlpha = 0.0;
	else
		ChatBar_TextFadeAlpha = 1.0;
	end
	ChatBar_UpdateButtonText();
end

--------------------------------------------------
-- Slash commands
--------------------------------------------------

SLASH_CHATBAR1 = "/chatbar";
SLASH_CHATBAR2 = "/cb";
SlashCmdList["CHATBAR"] = function(msg)
	if (msg == "fade") then
		ChatBar_Toggle_FadeEffect();
	elseif (msg == "show") then
		ChatBar_ForceShow();
		DEFAULT_CHAT_FRAME:AddMessage("ChatBar: " .. (CHATBAR_FADE_ON or "shown") .. " (10s)", 1, 1, 0);
	elseif (msg == "hide") then
		ChatBar_ForceHide();
		DEFAULT_CHAT_FRAME:AddMessage("ChatBar: " .. (CHATBAR_FADE_OFF or "hidden"), 1, 1, 0);
	elseif (msg == "config") or (msg == "options") then
		ChatBar_ShowOptionsPanel();
	else
		DEFAULT_CHAT_FRAME:AddMessage("ChatBar: /cb config - " .. (CHATBAR_MENU_MAIN_TITLE or "options"), 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("ChatBar: /cb fade - " .. (CHATBAR_MENU_MAIN_FADE or "auto-hide"), 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("ChatBar: /cb show - show 10s, /cb hide - hide", 1, 1, 0);
	end
end