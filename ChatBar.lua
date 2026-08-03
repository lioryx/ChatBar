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
ChatBar_PluginDefaultsInitialized = false;

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
	if (ChatBar_IsColorBarArt()) then
		return false;
	end
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

function ChatBar_GetFirstWord(s)
	local firstWord, count = gsub(s, "%s.*", "");
	return firstWord;
end

function ChatBar_Print(text)
	local color = ChatTypeInfo["SYSTEM"];
	local frame = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME;
	frame:AddMessage(text, color.r, color.g, color.b);
end