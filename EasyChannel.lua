-- EasyChannel: Tab cycles channels. Name completion stays with the default handler.
-- 大脚世界频道的按钮简称是「世」。还没加入时自动加入。

local whisperHistory = {};
local MAX_WHISPER_HISTORY = 10;
local WORLD_CHANNEL_NAME = "大脚世界频道";
local WORLD_CHANNEL_SHORT = "世";
local ChatBar_WorldChannelNames = { WORLD_CHANNEL_NAME };
local worldChannelJoinPendingUntil = 0;
local worldChannelJoinFailures = 0;
local wasInWorldChannel = false;
local MAX_WORLD_CHANNEL_JOIN_FAILURES = 3;

local originalChannelShortText = ChatBar_ChannelShortText;
function ChatBar_ChannelShortText(index)
	if (not ChatBar_TextChannelNumbers) then
		local channelNum, channelName = GetChannelName(index);
		if (channelNum) and (channelNum ~= 0) and (channelName == WORLD_CHANNEL_NAME) then
			return WORLD_CHANNEL_SHORT;
		end
	end
	if (originalChannelShortText) then
		return originalChannelShortText(index);
	end
end

local whisperFrame = CreateFrame("Frame");
whisperFrame:RegisterEvent("CHAT_MSG_WHISPER");
whisperFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM");
whisperFrame:SetScript("OnEvent", function(self, event, message, sender)
	if (event ~= "CHAT_MSG_WHISPER") and (event ~= "CHAT_MSG_WHISPER_INFORM") then
		return;
	end
	if (not sender) or (sender == "") then
		return;
	end

	local i;
	for i = #whisperHistory, 1, -1 do
		if (whisperHistory[i] == sender) then
			table.remove(whisperHistory, i);
		end
	end

	table.insert(whisperHistory, 1, sender);
	while (#whisperHistory > MAX_WHISPER_HISTORY) do
		table.remove(whisperHistory);
	end
end);

local function ChatBar_MessageBody(input)
	if (type(input) ~= "string") or (input == "") then
		return input or "";
	end
	if (not string.find(input, "^/")) then
		return input;
	end

	if (string.find(input, "^/w ")) then
		local firstSpace = string.find(input, " ", 3);
		if (firstSpace) then
			local secondSpace = string.find(input, " ", firstSpace + 1);
			if (secondSpace) then
				return string.sub(input, secondSpace + 1);
			end
		end
		return "";
	end

	local firstSpace = string.find(input, " ");
	if (firstSpace) then
		return string.sub(input, firstSpace + 1);
	end
	return "";
end

local function ChatBar_JoinedWorldChannels()
	local channels = {};
	local seen = {};
	local i;
	for i = 1, #(ChatBar_WorldChannelNames) do
		local id = GetChannelName(ChatBar_WorldChannelNames[i]);
		if (id) and (id > 0) and (not seen[id]) then
			seen[id] = true;
			table.insert(channels, id);
		end
	end
	table.sort(channels);
	return channels;
end

local function ChatBar_NextWorldChannel(currentId)
	local channels = ChatBar_JoinedWorldChannels();
	local i;
	currentId = currentId or 0;
	for i = 1, #(channels) do
		if (channels[i] > currentId) then
			return channels[i];
		end
	end
	return nil;
end

local function ChatBar_WorldOrSay()
	local nextId = ChatBar_NextWorldChannel(0);
	if (nextId) then
		return "CHANNEL", nextId;
	end
	return "SAY", nil;
end

local function ChatBar_NextChatType(chatType, channelTarget)
	if (chatType == "SAY") then
		if (ChatBar_IsInBattleground()) then
			return "INSTANCE_CHAT", nil;
		elseif (IsInGroup()) and (not IsInRaid()) then
			return "PARTY", nil;
		elseif (IsInRaid()) then
			return "RAID", nil;
		elseif (IsInGuild()) then
			return "GUILD", nil;
		end
		return ChatBar_WorldOrSay();
	elseif (chatType == "INSTANCE_CHAT") then
		if (IsInGuild()) then
			return "GUILD", nil;
		end
		return ChatBar_WorldOrSay();
	elseif (chatType == "PARTY") then
		if (IsInRaid()) then
			return "RAID", nil;
		elseif (IsInGuild()) then
			return "GUILD", nil;
		end
		return ChatBar_WorldOrSay();
	elseif (chatType == "RAID") then
		if (IsInGuild()) then
			return "GUILD", nil;
		end
		return ChatBar_WorldOrSay();
	elseif (chatType == "GUILD") then
		return ChatBar_WorldOrSay();
	elseif (chatType == "CHANNEL") then
		local nextId = ChatBar_NextWorldChannel(channelTarget);
		if (nextId) then
			return "CHANNEL", nextId;
		end
		return "SAY", nil;
	end
	return "SAY", nil;
end

local function ChatBar_ApplyWhisperTarget(editBox, beforeTell, beforeText)
	local historyCount = #whisperHistory;
	if (historyCount == 0) then
		return;
	end
	local foundIndex = 0;
	local i;
	for i = 1, historyCount do
		if (whisperHistory[i] == beforeTell) then
			foundIndex = i;
			break;
		end
	end
	local newTarget = whisperHistory[(foundIndex % historyCount) + 1];
	if (not newTarget) then
		return;
	end
	if (InCombatLockdown) and (InCombatLockdown()) then
		return;
	end
	editBox:SetAttribute("chatType", "WHISPER");
	editBox:SetAttribute("tellTarget", newTarget);
	if (ChatEdit_UpdateHeader) then
		ChatEdit_UpdateHeader(editBox);
	end
	editBox:SetText(ChatBar_MessageBody(beforeText));
end

-- 先跑原生 OnTabPressed（补全名字），只有它没改文字时才换成 ChatBar 的频道顺序。
-- HookScript 发生在原生处理之后，读不到切换前的频道，所以这里包一层脚本。
local function ChatBar_HandleTab(editBox, original)
	local beforeText = editBox:GetText() or "";
	local beforeType, beforeChannel, beforeTell = ChatBar_ReadChatType(editBox);
	if (original) then
		original(editBox);
	end
	if (AutoCompleteBox) and (AutoCompleteBox:IsShown()) then
		return;
	end
	local afterText = editBox:GetText() or "";
	if (afterText ~= beforeText) then
		return;
	end

	if (beforeType == "WHISPER") then
		local _, _, afterTell = ChatBar_ReadChatType(editBox);
		if (afterTell == beforeTell) then
			ChatBar_ApplyWhisperTarget(editBox, beforeTell, beforeText);
		end
		return;
	end

	local newType, newChannel = ChatBar_NextChatType(beforeType, beforeChannel);
	if (not ChatBar_ActivateChatType(editBox, newType, newChannel, true)) then
		return;
	end
	editBox:SetText(ChatBar_MessageBody(beforeText));
end

local function ChatBar_WrapEditBox(editBox)
	if (not editBox) or (editBox.ChatBarTabWrapped) then
		return;
	end
	local original = editBox:GetScript("OnTabPressed");
	if (not original) then
		return;
	end
	editBox.ChatBarTabWrapped = true;
	editBox:SetScript("OnTabPressed", function(self)
		ChatBar_HandleTab(self, original);
	end);
end

local function ChatBar_InstallTabHooks()
	local count = NUM_CHAT_WINDOWS or 10;
	local i;
	for i = 1, count do
		ChatBar_WrapEditBox(_G["ChatFrame" .. i .. "EditBox"]);
	end
end

local tabInstaller = CreateFrame("Frame");
tabInstaller:RegisterEvent("PLAYER_LOGIN");
tabInstaller:SetScript("OnEvent", function(self)
	ChatBar_InstallTabHooks();
end);

if (IsLoggedIn) and (IsLoggedIn()) then
	ChatBar_InstallTabHooks();
end

if (FCF_OpenTemporaryWindow) then
	hooksecurefunc("FCF_OpenTemporaryWindow", function()
		ChatBar_InstallTabHooks();
	end);
end

local function ChatBar_Schedule(delay, callback)
	if (C_Timer) and (C_Timer.After) then
		C_Timer.After(delay, callback);
		return;
	end
	local waiter = CreateFrame("Frame");
	waiter.elapsed = 0;
	waiter:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + elapsed;
		if (self.elapsed < delay) then
			return;
		end
		self:SetScript("OnUpdate", nil);
		callback();
	end);
end

local function ChatBar_InWorldChannel()
	local id = GetChannelName(WORLD_CHANNEL_NAME);
	return (id) and (id > 0);
end

local function ChatBar_AddWorldChannelToDefaultFrame()
	if (ChatFrame_AddChannel) and (DEFAULT_CHAT_FRAME) then
		ChatFrame_AddChannel(DEFAULT_CHAT_FRAME, WORLD_CHANNEL_NAME);
	end
end

local function ChatBar_NoticeMentionsWorldChannel(...)
	local i;
	for i = 2, 9 do
		local value = select(i, ...);
		if (value == WORLD_CHANNEL_NAME) then
			return true;
		end
		if (type(value) == "string") and (string.find(value, WORLD_CHANNEL_NAME, 1, true)) then
			return true;
		end
	end
	return false;
end

local function ChatBar_NoteWorldChannelJoined()
	local justJoined = not wasInWorldChannel;
	wasInWorldChannel = true;
	worldChannelJoinFailures = 0;
	worldChannelJoinPendingUntil = 0;
	ChatBar_AddWorldChannelToDefaultFrame();
	if (justJoined) and (ChatBarFrame) then
		ChatBarFrame.count = 0;
	end
end

local function ChatBar_EnsureWorldChannel()
	if (ChatBar_InWorldChannel()) then
		ChatBar_NoteWorldChannelJoined();
		return;
	end
	wasInWorldChannel = false;
	if (worldChannelJoinFailures >= MAX_WORLD_CHANNEL_JOIN_FAILURES) then
		return;
	end
	local now = 0;
	if (GetTime) then
		now = GetTime();
	end
	if (now < worldChannelJoinPendingUntil) then
		return;
	end
	worldChannelJoinFailures = worldChannelJoinFailures + 1;
	worldChannelJoinPendingUntil = now + 4;

	local frameId = 1;
	if (DEFAULT_CHAT_FRAME) and (DEFAULT_CHAT_FRAME.GetID) then
		frameId = DEFAULT_CHAT_FRAME:GetID() or 1;
	end
	if (JoinPermanentChannel) then
		JoinPermanentChannel(WORLD_CHANNEL_NAME, nil, frameId);
	elseif (JoinChannelByName) then
		JoinChannelByName(WORLD_CHANNEL_NAME, nil, frameId);
	end
end

local function ChatBar_ScheduleWorldChannelJoin()
	worldChannelJoinFailures = 0;
	worldChannelJoinPendingUntil = 0;
	ChatBar_Schedule(2, ChatBar_EnsureWorldChannel);
	ChatBar_Schedule(7, ChatBar_EnsureWorldChannel);
end

local worldChannelFrame = CreateFrame("Frame");
worldChannelFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
worldChannelFrame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");
worldChannelFrame:SetScript("OnEvent", function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		ChatBar_ScheduleWorldChannelJoin();
		return;
	end
	if (event ~= "CHAT_MSG_CHANNEL_NOTICE") then
		return;
	end
	local notice = ...;
	if (not ChatBar_NoticeMentionsWorldChannel(...)) then
		return;
	end
	if (notice == "YOU_JOINED") or (notice == "YOU_CHANGED") then
		ChatBar_NoteWorldChannelJoined();
	elseif (notice == "YOU_LEFT") then
		wasInWorldChannel = false;
		worldChannelJoinPendingUntil = 0;
		ChatBar_Schedule(1, ChatBar_EnsureWorldChannel);
	end
end);

if (IsLoggedIn) and (IsLoggedIn()) then
	ChatBar_ScheduleWorldChannelJoin();
end
