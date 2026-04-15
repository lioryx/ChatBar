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

CHAT_BAR_BUTTON_SIZE = 16; -- default height/width of each button
CHAT_BAR_BUTTON_TEXT_SIZE = 12;
CHAT_BAR_BUTTON_PADDING = 0;
CHAT_BAR_EDGE_SIZE = 10;   -- amount of space that the bar extends past the first/last button
CHAT_BAR_MAX_BUTTONS = 21;
CHAT_BAR_UPDATE_DELAY = 30;
CHAT_BAR_BUTTON_SIZE_MIN = 12;
CHAT_BAR_BUTTON_SIZE_MAX = 32;
CHAT_BAR_BUTTON_SIZE_STEP = 2;
CHAT_BAR_BUTTON_TEXT_SIZE_MIN = 8;
CHAT_BAR_BUTTON_TEXT_SIZE_MAX = 18;
CHAT_BAR_BUTTON_TEXT_SIZE_STEP = 1;
CHAT_BAR_BUTTON_PADDING_MIN = 0;
CHAT_BAR_BUTTON_PADDING_MAX = 10;
CHAT_BAR_BUTTON_PADDING_STEP = 1;
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
ChatBar_AltArtDirs = { "SkinSolid", "SkinSquares", "TextOnly", "SkinOctagon" };
ChatBar_ButtonScale = 1;
ChatBar_ButtonSize = CHAT_BAR_BUTTON_SIZE;
ChatBar_ButtonTextSize = CHAT_BAR_BUTTON_TEXT_SIZE;
ChatBar_ButtonPadding = CHAT_BAR_BUTTON_PADDING;

function ChatBar_IsTextOnlyArt()
	return ChatBar_AltArtDirs[ChatBar_AltArt] == "TextOnly";
end

function ChatBar_IsOctagonArt()
	return ChatBar_AltArtDirs[ChatBar_AltArt] == "SkinOctagon";
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
	ChatBar_ButtonTextSize = ChatBar_NormalizeSizeSetting(ChatBar_ButtonTextSize, CHAT_BAR_BUTTON_TEXT_SIZE,
		CHAT_BAR_BUTTON_TEXT_SIZE_MIN, CHAT_BAR_BUTTON_TEXT_SIZE_MAX, CHAT_BAR_BUTTON_TEXT_SIZE_STEP);
	ChatBar_ButtonPadding = ChatBar_NormalizeSizeSetting(ChatBar_ButtonPadding, CHAT_BAR_BUTTON_PADDING,
		CHAT_BAR_BUTTON_PADDING_MIN, CHAT_BAR_BUTTON_PADDING_MAX, CHAT_BAR_BUTTON_PADDING_STEP);
	ChatBar_ButtonScale = nil;
end

function ChatBar_GetBarSizeForCount(buttonCount)
	local spacing = 0;
	local minSize = CHAT_BAR_EDGE_SIZE * 2;
	if (ChatBar_ButtonSize > minSize) then
		minSize = ChatBar_ButtonSize;
	end
	if (buttonCount <= 0) then
		return minSize;
	end
	if (buttonCount > 1) then
		spacing = (buttonCount - 1) * ChatBar_ButtonPadding;
	end
	return (buttonCount * ChatBar_ButtonSize) + spacing + (CHAT_BAR_EDGE_SIZE * 2);
end

function ChatBar_GetCollapsedBarSize()
	return ChatBar_ButtonSize;
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
	local dir = ChatBar_AltArtDirs[ChatBar_AltArt] or ChatBar_AltArtDirs[1];
	return "Interface\\AddOns\\ChatBar\\" .. dir .. "\\ChanButton_Center";
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