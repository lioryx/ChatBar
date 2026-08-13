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
	frame:RegisterEvent("PARTY_MEMBERS_CHANGED");
	frame:RegisterEvent("RAID_ROSTER_UPDATE");
	frame:RegisterEvent("PLAYER_GUILD_UPDATE");
	frame:RegisterEvent("VARIABLES_LOADED");
	frame:RegisterForDrag("LeftButton");
	frame.velocity = 0;
	frame.count = 0;
	if (Eclipse) then
		Eclipse.registerForVisibility({
			name = "ChatBarFrame",
			uiname = "ChatBar",
			slashcom = { "chatbar", "cb" },
			reqs = { var = ChatBar_ShowIf, val = true, show = true },
		});
	end
end

function ChatBar_InitializeButton(button)
	button.Text = getglobal(button:GetName() .. "Text");
	button.ChatID = button:GetID();

	getglobal(button:GetName() .. "Highlight"):SetAlpha(.75);
	getglobal(button:GetName() .. "UpTex_Spec"):SetAlpha(.75);
	getglobal(button:GetName() .. "UpTex_Shad"):SetAlpha(.75);
	getglobal(button:GetName() .. "DownTex_Shad"):SetAlpha(1);

	button:SetFrameLevel(button:GetFrameLevel() + 1);
	button:RegisterForClicks("LeftButtonUp", "RightButtonDown");
	button:RegisterForDrag("LeftButton");
end

function ChatBar_InitializeDropDown(dropDown)
	UIDropDownMenu_Initialize(dropDown, ChatBar_LoadDropDownMenu, "MENU");
end

function ChatBar_Button_OnMouseDown()
	getglobal(this:GetName() .. "UpTex_Spec"):Hide();
	getglobal(this:GetName() .. "DownTex_Spec"):Show();
end

function ChatBar_Button_OnMouseUp()
	getglobal(this:GetName() .. "UpTex_Spec"):Show();
	getglobal(this:GetName() .. "DownTex_Spec"):Hide();
end

function ChatBar_Button_OnDragStart()
	-- Ctrl+拖动用于移动整个按钮条，这里不处理按钮排序
	if (IsControlKeyDown()) then
		return;
	end
	if (ChatBar_IsPinnedEntry(this.ChatID)) then
		return;
	end
	ChatBar_DragSourceButton = this:GetID();
	this:SetAlpha(0.5);
end

function ChatBar_Button_OnDragStop()
	if (not ChatBar_DragSourceButton) then
		return;
	end
	local sourceButton = ChatBar_DragSourceButton;
	ChatBar_DragSourceButton = nil;

	local sourceFrame = getglobal("ChatBarFrameButton" .. sourceButton);
	if (sourceFrame) then
		sourceFrame:SetAlpha(1);
	end

	local targetButton = ChatBar_GetButtonIndexAtCursor();
	if (targetButton) and (targetButton ~= sourceButton) then
		ChatBar_MoveButtonToPosition(sourceButton, targetButton);
	end
end

function ChatBar_Button_OnLoad()
	ChatBar_InitializeButton(this);
end

function ChatBar_Button_OnClick()
	ChatBar_ChatTypes[this.ChatID].click(arg1);
end

function ChatBar_Button_OnEnter()
	if (this.ChatID) and (ChatBar_HoverTextEnabled) and (ChatBar_ShouldShowButtonText()) and (not ChatBar_ShouldCenterButtonText()) then
		ChatBar_TextFadeIn(this);
	end
end

function ChatBar_Button_OnLeave()
	if (ChatBar_HoverTextEnabled) and (not ChatBar_ShouldCenterButtonText()) then
		ChatBar_TextFadeOut();
	end
end

function ChatBar_OnMouseDown(button)
	if (button == "RightButton") then
		ChatBar_ToggleOptionsPanel(this);
	else
		local x, y = GetCursorPosition();
		this.xOffset = x - this:GetLeft();
		this.yOffset = y - this:GetBottom();
	end
end

function ChatBar_OnDragStart()
	if (not IsControlKeyDown()) then
		return;
	end
	if (not this.isSliding) then
		local x, y = GetCursorPosition();
		this:ClearAllPoints();
		this:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", x - this.xOffset, y - this.yOffset);
		this:StartMoving();
		this.isMoving = true;
	end
end

function ChatBar_OnDragStop()
	if (not this.isMoving) then
		return;
	end
	this:StopMovingOrSizing();
	this.isMoving = false;
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

	local shadow = CreateFrame("Frame", buttonName .. "Shadow", parent);
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
	frame:SetScript("OnEvent", function()
		ChatBar_OnEvent(event);
	end);
	frame:SetScript("OnUpdate", function()
		ChatBar_OnUpdate(arg1);
	end);
	frame:SetScript("OnMouseDown", function()
		ChatBar_OnMouseDown(arg1);
	end);
	frame:SetScript("OnDragStart", ChatBar_OnDragStart);
	frame:SetScript("OnDragStop", ChatBar_OnDragStop);

	local background = CreateFrame("Frame", frame:GetName() .. "Background", frame);
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

local SendChatMessage_orig = SendChatMessage;
function ChatBar_SendChatMessage(text, type, language, target)
	SendChatMessage_orig(text, type, language, target);
	if (type == "WHISPER") then
		ChatBar_LastTell = target;
	end
end

SendChatMessage = ChatBar_SendChatMessage;

function ChatBar_StandardButtonClick(button)
	ChatBar_ForceShow();
	local chatFrame = SELECTED_DOCK_FRAME;
	if (not chatFrame) then
		chatFrame = DEFAULT_CHAT_FRAME;
	end
	if (button == "RightButton") then
		ToggleDropDownMenu(1, this.ChatID, ChatBar_DropDown, this:GetName(), 10, 0, "TOPRIGHT");
	else
		local chatType = ChatBar_ChatTypes[this.ChatID].type;
		chatFrame.editBox:Show();
		if (chatFrame.editBox.chatType == chatType) then
			ChatFrame_OpenChat("", chatFrame);
		else
			chatFrame.editBox.chatType = chatType;
		end
		ChatEdit_UpdateHeader(chatFrame.editBox);
	end
end

function ChatBar_WhisperButtonClick(button)
	ChatBar_ForceShow();
	local chatFrame = SELECTED_DOCK_FRAME;
	if (not chatFrame) then
		chatFrame = DEFAULT_CHAT_FRAME;
	end
	if (button == "RightButton") then
		ToggleDropDownMenu(1, this.ChatID, ChatBar_DropDown, this:GetName(), 10, 0, "TOPRIGHT");
	else
		local chatType = ChatBar_ChatTypes[this.ChatID].type;
		if (chatFrame.editBox.chatType == chatType) then
			ChatFrame_OpenChat("", chatFrame);
		else
			ChatFrame_ReplyTell(chatFrame);
			if (not chatFrame.editBox:IsVisible()) or (chatFrame.editBox.chatType ~= chatType) then
				ChatFrame_OpenChat("/w ", chatFrame);
			end
		end
	end
end

function ChatBar_HardcoreButtonClick(button)
	ChatBar_ForceShow();
	local chatFrame = SELECTED_DOCK_FRAME;
	if (not chatFrame) then
		chatFrame = DEFAULT_CHAT_FRAME;
	end
	if (button == "RightButton") then
		ToggleDropDownMenu(1, this.ChatID, ChatBar_DropDown, this:GetName(), 10, 0, "TOPRIGHT");
	else
		-- TurtleWoW 硬核频道：优先走原生 HARDCORE 类型，否则回退到 /h
		if (ChatTypeInfo and ChatTypeInfo["HARDCORE"]) then
			chatFrame.editBox:Show();
			if (chatFrame.editBox.chatType == "HARDCORE") then
				ChatFrame_OpenChat("", chatFrame);
			else
				chatFrame.editBox.chatType = "HARDCORE";
			end
			ChatEdit_UpdateHeader(chatFrame.editBox);
		else
			ChatFrame_OpenChat("/h ", chatFrame);
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

function ChatBar_ChannelClick(button, index)
	ChatBar_ForceShow();
	if (not index) then
		index = 1;
	end
	local chatFrame = SELECTED_DOCK_FRAME;
	if (not chatFrame) then
		chatFrame = DEFAULT_CHAT_FRAME;
	end
	if (button == "RightButton") then
		ToggleDropDownMenu(1, this.ChatID, ChatBar_DropDown, this:GetName(), 10, 0, "TOPRIGHT");
	else
		chatFrame.editBox:Show();
		if (chatFrame.editBox.chatType == "CHANNEL") and (chatFrame.editBox.channelTarget == index) then
			ChatFrame_OpenChat("", chatFrame);
		else
			chatFrame.editBox.chatType = "CHANNEL";
			chatFrame.editBox.channelTarget = index;
			ChatEdit_UpdateHeader(chatFrame.editBox);
		end
	end
end

function ChatBar_RollButtonClick(button)
	ChatBar_ForceShow();
	if (button == "RightButton") then
		ChatBar_ToggleOptionsPanel(this);
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
			return UnitExists("party1") and (not ChatBar_HiddenButtons[CHAT_MSG_PARTY]);
		end
	},
	{
		type = "RAID",
		shortText = function() return CHATBAR_RAID_ABRV; end,
		text = function() return CHAT_MSG_RAID; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return (GetNumRaidMembers() > 0) and (not ChatBar_HiddenButtons[CHAT_MSG_RAID]);
		end
	},
	{
		type = "RAID_WARNING",
		shortText = function() return CHATBAR_RAID_WARNING_ABRV; end,
		text = function() return CHAT_MSG_RAID_WARNING; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return (GetNumRaidMembers() > 0) and (IsRaidLeader() or IsRaidOfficer()) and
			(not ChatBar_HiddenButtons[CHAT_MSG_RAID_WARNING]);
		end
	},
	{
		type = "BATTLEGROUND",
		shortText = function() return CHATBAR_BATTLEGROUND_ABRV; end,
		text = function() return CHAT_MSG_BATTLEGROUND; end,
		click = ChatBar_StandardButtonClick,
		show = function()
			return (GetZoneText() == CHATBAR_WSG or GetZoneText() == CHATBAR_AB or GetZoneText() == CHATBAR_AV) and
			(not ChatBar_HiddenButtons[CHAT_MSG_BATTLEGROUND]);
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
			return CanEditOfficerNote() and (not ChatBar_HiddenButtons[CHAT_MSG_OFFICER]);
		end
	},
	{
		type = "HARDCORE",
		shortText = function() return CHATBAR_HARDCORE_ABRV; end,
		text = function() return CHAT_MSG_HARDCORE or CHATBAR_HARDCORE; end,
		click = ChatBar_HardcoreButtonClick,
		show = function()
			return (not ChatBar_HiddenButtons[CHAT_MSG_HARDCORE or CHATBAR_HARDCORE]);
		end,
		customColor = { r = 1, g = 0.5, b = 0.25 }
	},
	{
		type = "CHANNEL1",
		shortText = function() return ChatBar_ChannelShortText(1); end,
		text = function() return ChatBar_ChannelText(1); end,
		click = function(button) ChatBar_ChannelClick(button, 1); end,
		show = function() return ChatBar_ChannelShow(1); end
	},
	{
		type = "CHANNEL2",
		shortText = function() return ChatBar_ChannelShortText(2); end,
		text = function() return ChatBar_ChannelText(2); end,
		click = function(button) ChatBar_ChannelClick(button, 2); end,
		show = function() return ChatBar_ChannelShow(2); end
	},
	{
		type = "CHANNEL3",
		shortText = function() return ChatBar_ChannelShortText(3); end,
		text = function() return ChatBar_ChannelText(3); end,
		click = function(button) ChatBar_ChannelClick(button, 3); end,
		show = function() return ChatBar_ChannelShow(3); end
	},
	{
		type = "CHANNEL4",
		shortText = function() return ChatBar_ChannelShortText(4); end,
		text = function() return ChatBar_ChannelText(4); end,
		click = function(button) ChatBar_ChannelClick(button, 4); end,
		show = function() return ChatBar_ChannelShow(4); end
	},
	{
		type = "CHANNEL5",
		shortText = function() return ChatBar_ChannelShortText(5); end,
		text = function() return ChatBar_ChannelText(5); end,
		click = function(button) ChatBar_ChannelClick(button, 5); end,
		show = function() return ChatBar_ChannelShow(5); end
	},
	{
		type = "CHANNEL6",
		shortText = function() return ChatBar_ChannelShortText(6); end,
		text = function() return ChatBar_ChannelText(6); end,
		click = function(button) ChatBar_ChannelClick(button, 6); end,
		show = function() return ChatBar_ChannelShow(6); end
	},
	{
		type = "CHANNEL7",
		shortText = function() return ChatBar_ChannelShortText(7); end,
		text = function() return ChatBar_ChannelText(7); end,
		click = function(button) ChatBar_ChannelClick(button, 7); end,
		show = function() return ChatBar_ChannelShow(7); end
	},
	{
		type = "CHANNEL8",
		shortText = function() return ChatBar_ChannelShortText(8); end,
		text = function() return ChatBar_ChannelText(8); end,
		click = function(button) ChatBar_ChannelClick(button, 8); end,
		show = function() return ChatBar_ChannelShow(8); end
	},
	{
		type = "CHANNEL9",
		shortText = function() return ChatBar_ChannelShortText(9); end,
		text = function() return ChatBar_ChannelText(9); end,
		click = function(button) ChatBar_ChannelClick(button, 9); end,
		show = function() return ChatBar_ChannelShow(9); end
	},
	{
		type = "CHANNEL10",
		shortText = function() return ChatBar_ChannelShortText(10); end,
		text = function() return ChatBar_ChannelText(10); end,
		click = function(button) ChatBar_ChannelClick(button, 10); end,
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