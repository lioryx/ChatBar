--------------------------------------------------
-- UI Creation And Button Logic
--------------------------------------------------

local function ChatBar_CreateNamedTexture(frame, name, layer, texturePath, blendMode, hidden)
	local texture = frame:CreateTexture(name, layer);
	texture:SetAllPoints(frame);
	texture:SetTexture(texturePath);
	if (blendMode) then
		texture:SetBlendMode(blendMode);
	end
	if (hidden) then
		texture:Hide();
	end
	return texture;
end

function ChatBar_InitializeFrame(frame)
	frame:RegisterEvent("UPDATE_CHAT_COLOR");
	frame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");
	frame:RegisterEvent("GROUP_ROSTER_UPDATE");
	frame:RegisterEvent("PLAYER_GUILD_UPDATE");
	frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	frame:RegisterEvent("ADDON_LOADED");
	frame:RegisterEvent("VARIABLES_LOADED");
	frame:RegisterForDrag("LeftButton");
	frame.velocity = 0;
	frame.count = 0;
end

function ChatBar_InitializeButton(button)
	button.Text = _G[button:GetName() .. "Text"];
	button.ChatID = button:GetID();

	_G[button:GetName() .. "Highlight"]:SetAlpha(.75);
	_G[button:GetName() .. "UpTex_Spec"]:SetAlpha(.75);
	_G[button:GetName() .. "UpTex_Shad"]:SetAlpha(.75);
	_G[button:GetName() .. "DownTex_Shad"]:SetAlpha(1);

	button:SetFrameLevel(button:GetFrameLevel() + 1);
	button:RegisterForClicks("LeftButtonUp", "RightButtonDown");
	button:RegisterForDrag("LeftButton");
end

function ChatBar_InitializeDropDown(dropDown)
	UIDropDownMenu_Initialize(dropDown, ChatBar_LoadDropDownMenu, "MENU");
end

function ChatBar_Button_OnMouseDown(self)
	_G[self:GetName() .. "UpTex_Spec"]:Hide();
	_G[self:GetName() .. "DownTex_Spec"]:Show();
end

function ChatBar_Button_OnMouseUp(self)
	_G[self:GetName() .. "UpTex_Spec"]:Show();
	_G[self:GetName() .. "DownTex_Spec"]:Hide();
end

function ChatBar_Button_OnDragStart(self)
	-- Ctrl+拖动用于移动整个按钮条，这里不处理按钮排序
	if (IsControlKeyDown()) then
		return;
	end
	if (ChatBar_IsPinnedEntry(self.ChatID)) then
		return;
	end
	ChatBar_DragSourceButton = self:GetID();
	self:SetAlpha(0.5);
end

function ChatBar_Button_OnDragStop(self)
	if (not ChatBar_DragSourceButton) then
		return;
	end
	local sourceButton = ChatBar_DragSourceButton;
	ChatBar_DragSourceButton = nil;

	local sourceFrame = _G["ChatBarFrameButton" .. sourceButton];
	if (sourceFrame) then
		sourceFrame:SetAlpha(1);
	end

	local targetButton = ChatBar_GetButtonIndexAtCursor();
	if (targetButton) and (targetButton ~= sourceButton) then
		ChatBar_MoveButtonToPosition(sourceButton, targetButton);
	end
end

function ChatBar_Button_OnClick(self, button)
	if (not self.ChatID) or (not ChatBar_ChatTypes[self.ChatID]) then
		return;
	end
	ChatBar_ChatTypes[self.ChatID].click(button, self);
end

function ChatBar_Button_OnShow(self)
	if (self.Shadow) and (ChatBar_IsColorBarArt()) and (self.ChatID) then
		self.Shadow:Show();
	end
end

function ChatBar_Button_OnHide(self)
	if (self.Shadow) then
		self.Shadow:Hide();
	end
end

function ChatBar_Button_OnEnter(self)
	if (self.ChatID) and (ChatBar_IsButtonTextHoverFadeActive()) then
		ChatBar_TextFadeIn(self);
	end
end

function ChatBar_Button_OnLeave(self)
	if (ChatBar_IsButtonTextHoverFadeActive()) then
		ChatBar_TextFadeOut();
	end
end

function ChatBar_OnMouseDown(self, button)
	if (button == "RightButton") then
		ChatBar_ToggleOptionsPanel(self);
	else
		local scale = 1.0;
		if (UIParent and UIParent.GetScale) then
			scale = UIParent:GetScale() or 1.0;
		end
		local x, y = GetCursorPosition();
		self.xOffset = (x / scale) - self:GetLeft();
		self.yOffset = (y / scale) - self:GetBottom();
	end
end

function ChatBar_OnDragStart(self)
	if (not IsControlKeyDown()) then
		return;
	end
	if (not self.isSliding) then
		local scale = 1.0;
		if (UIParent and UIParent.GetScale) then
			scale = UIParent:GetScale() or 1.0;
		end
		local x, y = GetCursorPosition();
		self:ClearAllPoints();
		self:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", (x / scale) - self.xOffset, (y / scale) - self.yOffset);
		self:StartMoving();
		self.isMoving = true;
	end
end

function ChatBar_OnDragStop(self)
	if (not self.isMoving) then
		return;
	end
	self:StopMovingOrSizing();
	self.isMoving = false;
	ChatBar_UpdateOrientationPoint(true);
end

function ChatBar_CreateButton(parent, id)
	local buttonName = parent:GetName() .. "Button" .. id;
	local button = CreateFrame("Button", buttonName, parent);
	button:SetID(id);
	button:SetWidth(ChatBar_ButtonWidth);
	button:SetHeight(ChatBar_ButtonHeight);

	local text = button:CreateFontString(buttonName .. "Text", "OVERLAY", "GameFontNormalSmall");
	text:SetWidth(ChatBar_ButtonWidth + 8);
	text:SetHeight(ChatBar_ButtonTextSize + 4);
	text:SetJustifyH("CENTER");
	text:SetPoint("BOTTOM", button, "TOP", 0, 0);

	local shadow = CreateFrame("Frame", buttonName .. "Shadow", parent, "BackdropTemplate");
	shadow:SetPoint("TOPLEFT", button, "TOPLEFT", -ChatBar_ColorBarBorderSize, ChatBar_ColorBarBorderSize);
	shadow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", ChatBar_ColorBarBorderSize, -ChatBar_ColorBarBorderSize);
	shadow:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	});
	shadow:SetBackdropColor(0, 0, 0, 0.8);
	shadow:SetBackdropBorderColor(0, 0, 0, 0.5);
	shadow:Hide();
	button.Shadow = shadow;

	ChatBar_CreateNamedTexture(button, buttonName .. "UpTex_Spec", "OVERLAY",
		"Interface\\AddOns\\ChatBar\\SkinSolid\\ChanButton_Up_Spec");
	ChatBar_CreateNamedTexture(button, buttonName .. "DownTex_Spec", "OVERLAY",
		"Interface\\AddOns\\ChatBar\\SkinSolid\\ChanButton_Down_Spec", nil, true);
	ChatBar_CreateNamedTexture(button, buttonName .. "Flash", "OVERLAY",
		"Interface\\AddOns\\ChatBar\\SkinSolid\\ChanButton_Glow_Alpha", "ADD", true);
	ChatBar_CreateNamedTexture(button, buttonName .. "Center", "ARTWORK",
		"Interface\\AddOns\\ChatBar\\SkinSolid\\ChanButton_Center");
	ChatBar_CreateNamedTexture(button, buttonName .. "Background", "BORDER",
		"Interface\\AddOns\\ChatBar\\SkinSolid\\ChanButton_BG");

	local normalTexture = ChatBar_CreateNamedTexture(button, buttonName .. "UpTex_Shad", "OVERLAY",
		"Interface\\AddOns\\ChatBar\\SkinSolid\\ChanButton_Up_Shad");
	button:SetNormalTexture(normalTexture);

	local pushedTexture = ChatBar_CreateNamedTexture(button, buttonName .. "DownTex_Shad", "OVERLAY",
		"Interface\\AddOns\\ChatBar\\SkinSolid\\ChanButton_Down_Shad");
	button:SetPushedTexture(pushedTexture);

	local highlightTexture = ChatBar_CreateNamedTexture(button, buttonName .. "Highlight", "OVERLAY",
		"Interface\\AddOns\\ChatBar\\SkinSolid\\ChanButton_Glow_Alpha", "ADD");
	button:SetHighlightTexture(highlightTexture);

	button:SetScript("OnEnter", ChatBar_Button_OnEnter);
	button:SetScript("OnLeave", ChatBar_Button_OnLeave);
	button:SetScript("OnClick", ChatBar_Button_OnClick);
	button:SetScript("OnShow", ChatBar_Button_OnShow);
	button:SetScript("OnHide", ChatBar_Button_OnHide);
	button:SetScript("OnMouseDown", ChatBar_Button_OnMouseDown);
	button:SetScript("OnMouseUp", ChatBar_Button_OnMouseUp);
	button:SetScript("OnDragStart", ChatBar_Button_OnDragStart);
	button:SetScript("OnDragStop", ChatBar_Button_OnDragStop);

	if (id == 1) then
		button:SetPoint("LEFT", parent, "LEFT", CHAT_BAR_EDGE_SIZE, 0);
	else
		button:SetPoint("LEFT", parent:GetName() .. "Button" .. (id - 1), "RIGHT", ChatBar_GetButtonSpacing(), 0);
	end

	ChatBar_InitializeButton(button);
	if (button.Shadow) then
		button.Shadow:SetFrameLevel(button:GetFrameLevel() - 1);
	end
	return button;
end

function ChatBar_CreateUI()
	if (ChatBarFrame) then
		return;
	end

	local frame = CreateFrame("Frame", "ChatBarFrame", UIParent);
	frame:EnableMouse(true);
	frame:SetMovable(true);
	frame:SetWidth(ChatBar_ButtonWidth);
	frame:SetHeight(ChatBar_ButtonHeight);
	frame:SetPoint("BOTTOMLEFT", "ChatFrame1", "TOPLEFT", 0, 30);
	frame:SetScript("OnEvent", ChatBar_OnEvent);
	frame:SetScript("OnUpdate", ChatBar_OnUpdate);
	frame:SetScript("OnMouseDown", ChatBar_OnMouseDown);
	frame:SetScript("OnDragStart", ChatBar_OnDragStart);
	frame:SetScript("OnDragStop", ChatBar_OnDragStop);

	local background = CreateFrame("Frame", frame:GetName() .. "Background", frame, "BackdropTemplate");
	background:SetAllPoints(frame);
	background:SetBackdrop({
		edgeFile = "Interface\\AddOns\\ChatBar\\SkinSolid\\ChatBarBorder",
		bgFile = "Interface\\AddOns\\ChatBar\\SkinSolid\\BlackBg",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	});

	for i = 1, CHAT_BAR_MAX_BUTTONS do
		ChatBar_CreateButton(frame, i);
	end

	local dropDown = CreateFrame("Frame", "ChatBar_DropDown", UIParent, "UIDropDownMenuTemplate");
	dropDown:SetID(1);
	dropDown:SetWidth(10);
	dropDown:SetHeight(10);
	dropDown:SetPoint("TOP", UIParent, "TOP", -10, -50);
	dropDown:Hide();

	ChatBar_CreateOptionsPanel();

	ChatBar_InitializeFrame(frame);
	ChatBar_InitializeDropDown(dropDown);
	ChatBar_UpdateButtons();

	-- 登录加载阶段先隐藏：此时 SavedVariables 尚未加载，按钮数量和尺寸仍是默认值，
	-- 直接显示会出现一个很长的错误尺寸长条；待 VARIABLES_LOADED 完成初始化后再显示。
	ChatBar_SetAlpha(CHAT_BAR_ALPHA_HIDDEN, true);
	frame:Hide();
end

hooksecurefunc("SendChatMessage", function(text, chatType, language, target)
	if (chatType == "WHISPER") then
		ChatBar_LastTell = target;
	end
end);

local function ChatBar_GetActiveChatFrame()
	local chatFrame = SELECTED_DOCK_FRAME;
	if (not chatFrame) then
		chatFrame = DEFAULT_CHAT_FRAME;
	end
	return chatFrame;
end

function ChatBar_StandardButtonClick(button, buttonFrame)
	ChatBar_ForceShow();
	local chatFrame = ChatBar_GetActiveChatFrame();
	if (button == "RightButton") then
		ToggleDropDownMenu(1, buttonFrame.ChatID, ChatBar_DropDown, buttonFrame, 10, 0, "TOPRIGHT");
		return;
	end
	local chatType = ChatBar_ChatTypes[buttonFrame.ChatID].type;
	local editBox = ChatBar_GetEditBox(chatFrame);
	local currentType = ChatBar_ReadChatType(editBox);
	if (currentType == chatType) then
		ChatFrame_OpenChat("", chatFrame);
	else
		ChatBar_ActivateChatType(editBox, chatType);
	end
end

function ChatBar_WhisperButtonClick(button, buttonFrame)
	ChatBar_ForceShow();
	local chatFrame = ChatBar_GetActiveChatFrame();
	if (button == "RightButton") then
		ToggleDropDownMenu(1, buttonFrame.ChatID, ChatBar_DropDown, buttonFrame, 10, 0, "TOPRIGHT");
		return;
	end
	local chatType = ChatBar_ChatTypes[buttonFrame.ChatID].type;
	local editBox = ChatBar_GetEditBox(chatFrame);
	local currentType = ChatBar_ReadChatType(editBox);
	if (currentType == chatType) then
		ChatFrame_OpenChat("", chatFrame);
	else
		if (ChatFrame_ReplyTell) then
			ChatFrame_ReplyTell(chatFrame);
		end
		editBox = ChatBar_GetEditBox(chatFrame);
		currentType = ChatBar_ReadChatType(editBox);
		if (not editBox) or (not editBox:IsVisible()) or (currentType ~= chatType) then
			ChatFrame_OpenChat("/w ", chatFrame);
		end
	end
end

function ChatBar_ChannelShortText(index)
	local channelNum, channelName = GetChannelName(index);
	if (channelNum ~= 0) then
		if (ChatBar_TextChannelNumbers) then
			return channelNum;
		else
			return ChatBar_GetFirstCharacter(channelName);
		end
	end
end

function ChatBar_ChannelText(index)
	local channelNum, channelName = GetChannelName(index);
	if (channelNum ~= 0) then
		return channelNum .. ") " .. channelName;
	end
	return "";
end

function ChatBar_ChannelClick(button, index, buttonFrame)
	ChatBar_ForceShow();
	if (not index) then
		index = 1;
	end
	local chatFrame = ChatBar_GetActiveChatFrame();
	if (button == "RightButton") then
		ToggleDropDownMenu(1, buttonFrame.ChatID, ChatBar_DropDown, buttonFrame, 10, 0, "TOPRIGHT");
		return;
	end
	local editBox = ChatBar_GetEditBox(chatFrame);
	local currentType, currentChannel = ChatBar_ReadChatType(editBox);
	if (currentType == "CHANNEL") and (currentChannel == index) then
		ChatFrame_OpenChat("", chatFrame);
	else
		ChatBar_ActivateChatType(editBox, "CHANNEL", index);
	end
end

function ChatBar_RollButtonClick(button, buttonFrame)
	ChatBar_ForceShow();
	if (button == "RightButton") then
		ChatBar_ToggleOptionsPanel(buttonFrame);
	else
		RandomRoll(1, 100);
	end
end

function ChatBar_ChannelShow(index)
	local channelNum, channelName = GetChannelName(index);
	if (channelNum ~= 0) then
		return (not ChatBar_HiddenButtons[ChatBar_GetFirstWord(channelName)]);
	end
end

ChatBar_ChatTypes = {
	{
		type = "WHISPER",
		shortText = function() return CHATBAR_WHISPER_ABRV; end,
		text = function() return CHAT_MSG_WHISPER_INFORM; end,
		click = ChatBar_WhisperButtonClick,
		show = function()
			return (not ChatBar_HiddenButtons[CHAT_MSG_WHISPER_INFORM]);
		end
	},
	{
		type = "SAY",
		shortText = function() return CHATBAR_SAY_ABRV; end,
		text = function() return CHAT_MSG_SAY; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return (not ChatBar_HiddenButtons[CHAT_MSG_SAY]);
		end
	},
	{
		type = "YELL",
		shortText = function() return CHATBAR_YELL_ABRV; end,
		text = function() return CHAT_MSG_YELL; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return (not ChatBar_HiddenButtons[CHAT_MSG_YELL]);
		end
	},
	{
		type = "EMOTE",
		shortText = function() return CHATBAR_EMOTE_ABRV; end,
		text = function() return CHAT_MSG_EMOTE; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return (not ChatBar_HiddenButtons[CHAT_MSG_EMOTE]);
		end
	},
	{
		type = "PARTY",
		shortText = function() return CHATBAR_PARTY_ABRV; end,
		text = function() return CHAT_MSG_PARTY; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return IsInGroup() and (not IsInRaid()) and (not ChatBar_HiddenButtons[CHAT_MSG_PARTY]);
		end
	},
	{
		type = "RAID",
		shortText = function() return CHATBAR_RAID_ABRV; end,
		text = function() return CHAT_MSG_RAID; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return IsInRaid() and (not ChatBar_HiddenButtons[CHAT_MSG_RAID]);
		end
	},
	{
		type = "RAID_WARNING",
		shortText = function() return CHATBAR_RAID_WARNING_ABRV; end,
		text = function() return CHAT_MSG_RAID_WARNING; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and
			(not ChatBar_HiddenButtons[CHAT_MSG_RAID_WARNING]);
		end
	},
	{
		type = "INSTANCE_CHAT",
		shortText = function() return CHATBAR_BATTLEGROUND_ABRV; end,
		text = function() return CHAT_MSG_INSTANCE_CHAT or CHATBAR_BATTLEGROUND_ABRV; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return ChatBar_IsInBattleground() and (not ChatBar_HiddenButtons[CHAT_MSG_INSTANCE_CHAT or CHATBAR_BATTLEGROUND_ABRV]);
		end
	},
	{
		type = "GUILD",
		shortText = function() return CHATBAR_GUILD_ABRV; end,
		text = function() return CHAT_MSG_GUILD; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return IsInGuild() and (not ChatBar_HiddenButtons[CHAT_MSG_GUILD]);
		end
	},
	{
		type = "OFFICER",
		shortText = function() return CHATBAR_OFFICER_ABRV; end,
		text = function() return CHAT_MSG_OFFICER; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return ChatBar_CanUseOfficerChat() and (not ChatBar_HiddenButtons[CHAT_MSG_OFFICER]);
		end
	},
	{
		type = "CHANNEL1",
		shortText = function() return ChatBar_ChannelShortText(1); end,
		text = function() return ChatBar_ChannelText(1); end,
		click = function(button, buttonFrame) ChatBar_ChannelClick(button, 1, buttonFrame); end,
		show = function() return ChatBar_ChannelShow(1); end
	},
	{
		type = "CHANNEL2",
		shortText = function() return ChatBar_ChannelShortText(2); end,
		text = function() return ChatBar_ChannelText(2); end,
		click = function(button, buttonFrame) ChatBar_ChannelClick(button, 2, buttonFrame); end,
		show = function() return ChatBar_ChannelShow(2); end
	},
	{
		type = "CHANNEL3",
		shortText = function() return ChatBar_ChannelShortText(3); end,
		text = function() return ChatBar_ChannelText(3); end,
		click = function(button, buttonFrame) ChatBar_ChannelClick(button, 3, buttonFrame); end,
		show = function() return ChatBar_ChannelShow(3); end
	},
	{
		type = "CHANNEL4",
		shortText = function() return ChatBar_ChannelShortText(4); end,
		text = function() return ChatBar_ChannelText(4); end,
		click = function(button, buttonFrame) ChatBar_ChannelClick(button, 4, buttonFrame); end,
		show = function() return ChatBar_ChannelShow(4); end
	},
	{
		type = "CHANNEL5",
		shortText = function() return ChatBar_ChannelShortText(5); end,
		text = function() return ChatBar_ChannelText(5); end,
		click = function(button, buttonFrame) ChatBar_ChannelClick(button, 5, buttonFrame); end,
		show = function() return ChatBar_ChannelShow(5); end
	},
	{
		type = "CHANNEL6",
		shortText = function() return ChatBar_ChannelShortText(6); end,
		text = function() return ChatBar_ChannelText(6); end,
		click = function(button, buttonFrame) ChatBar_ChannelClick(button, 6, buttonFrame); end,
		show = function() return ChatBar_ChannelShow(6); end
	},
	{
		type = "CHANNEL7",
		shortText = function() return ChatBar_ChannelShortText(7); end,
		text = function() return ChatBar_ChannelText(7); end,
		click = function(button, buttonFrame) ChatBar_ChannelClick(button, 7, buttonFrame); end,
		show = function() return ChatBar_ChannelShow(7); end
	},
	{
		type = "CHANNEL8",
		shortText = function() return ChatBar_ChannelShortText(8); end,
		text = function() return ChatBar_ChannelText(8); end,
		click = function(button, buttonFrame) ChatBar_ChannelClick(button, 8, buttonFrame); end,
		show = function() return ChatBar_ChannelShow(8); end
	},
	{
		type = "CHANNEL9",
		shortText = function() return ChatBar_ChannelShortText(9); end,
		text = function() return ChatBar_ChannelText(9); end,
		click = function(button, buttonFrame) ChatBar_ChannelClick(button, 9, buttonFrame); end,
		show = function() return ChatBar_ChannelShow(9); end
	},
	{
		type = "CHANNEL10",
		shortText = function() return ChatBar_ChannelShortText(10); end,
		text = function() return ChatBar_ChannelText(10); end,
		click = function(button, buttonFrame) ChatBar_ChannelClick(button, 10, buttonFrame); end,
		show = function() return ChatBar_ChannelShow(10); end
	},
	{
		type = "ROLL",
		shortText = function() return CHATBAR_ROLL_ABRV; end,
		text = function() return CHATBAR_ROLL; end,
		click = ChatBar_RollButtonClick,
		show = function()
			return true;
		end,
		alwaysShow = true,
		colorType = "SYSTEM"
	}
};

ChatBar_BarTypes = {};