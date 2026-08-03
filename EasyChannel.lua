-- EasyChannel: Tab cycle channels + whisper history
-- Ported from S_ChatBar260720 (Lua 5.0 safe)

local whisperHistory = {}
local MAX_WHISPER_HISTORY = 10

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_WHISPER")
f:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
f:SetScript("OnEvent", function()
	if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
		for i = table.getn(whisperHistory), 1, -1 do
			if whisperHistory[i] == arg2 then
				table.remove(whisperHistory, i)
			end
		end

		table.insert(whisperHistory, 1, arg2)
		while table.getn(whisperHistory) > MAX_WHISPER_HISTORY do
			table.remove(whisperHistory)
		end
	end
end)

local battlegroundZones = {
	["奥特兰克山谷"] = true,
	["战歌峡谷"] = true,
	["阿拉希盆地"] = true,
	["阳光林地"] = true,
	["血环竞技场"] = true,
	["荆棘峡谷"] = true,
	["Alterac Valley"] = true,
	["Warsong Gulch"] = true,
	["Arathi Basin"] = true,
}

local function IsInBattleground()
	local zoneName = GetZoneText()
	return battlegroundZones[zoneName]
end

function processString(input)
	if (type(input) ~= "string") or (input == "") then
		return input or ""
	end

	-- Lua 5.0: use string.find, not string.match
	if not string.find(input, "^/") then
		return input
	end

	if string.find(input, "^/w ") then
		local firstSpace = string.find(input, " ", 3)
		if firstSpace then
			local secondSpace = string.find(input, " ", firstSpace + 1)
			if secondSpace then
				return string.sub(input, secondSpace + 1)
			end
		end
		return ""
	else
		local firstSpace = string.find(input, " ")
		if firstSpace then
			return string.sub(input, firstSpace + 1)
		end
	end
	return ""
end

ChatFrameEditBox:SetScript("OnTabPressed", function()
	if not ChatFrameEditBox:IsVisible() then return end
	local chatFrame = SELECTED_DOCK_FRAME
	if (not chatFrame) then
		chatFrame = DEFAULT_CHAT_FRAME;
	end

	-- 密语频道特殊处理
	if chatFrame.editBox.chatType == "WHISPER" then
		local currentTarget = chatFrame.editBox.tellTarget
		local foundIndex = 0
		local historyCount = table.getn(whisperHistory)

		for i = 1, historyCount do
			if whisperHistory[i] == currentTarget then
				foundIndex = i
				break
			end
		end

		local newTarget
		if historyCount > 0 then
			newTarget = whisperHistory[math.mod(foundIndex, historyCount) + 1]
		end

		if newTarget then
			chatFrame.editBox.tellTarget = newTarget
			chatFrame.editBox:SetText("/w " .. newTarget .. " ")
		end
		return
	end

	local channel = { ["世界频道"] = 0, ["世界"] = 0, ["中国"] = 0, ["World"] = 0, ["China"] = 0 }
	local keys = { "世界频道", "世界", "中国", "World", "China" }
	local JoinedChannel = false
	for channelName, channelID in pairs(channel) do
		local id = GetChannelName(channelName)
		if id > 0 then
			JoinedChannel = true
			channel[channelName] = id
		end
	end

	table.sort(keys, function(a, b)
		return channel[a] > channel[b]
	end)

	-- 说 --> 战场 --> 队伍 --> 团队 --> 公会 --> 自定义频道
	if (chatFrame.editBox.chatType == "SAY") then
		if IsInBattleground() then
			chatFrame.editBox.chatType = "BATTLEGROUND";
		elseif (GetNumPartyMembers() > 0) then
			chatFrame.editBox.chatType = "PARTY";
		elseif (GetNumRaidMembers() > 0) then
			chatFrame.editBox.chatType = "RAID";
		elseif (IsInGuild()) then
			chatFrame.editBox.chatType = "GUILD";
		elseif JoinedChannel then
			for i = 4, 1, -1 do
				if channel[keys[i]] > 0 then
					chatFrame.editBox.chatType = "CHANNEL"
					chatFrame.editBox.channelTarget = channel[keys[i]]
					break
				end
			end
		end
	elseif (chatFrame.editBox.chatType == "BATTLEGROUND") then
		if (IsInGuild()) then
			chatFrame.editBox.chatType = "GUILD";
		elseif JoinedChannel then
			for i = 4, 1, -1 do
				if channel[keys[i]] > 0 then
					chatFrame.editBox.chatType = "CHANNEL"
					chatFrame.editBox.channelTarget = channel[keys[i]]
					break
				end
			end
		else
			chatFrame.editBox.chatType = "SAY";
		end
	elseif (chatFrame.editBox.chatType == "PARTY") then
		if (GetNumRaidMembers() > 0) then
			chatFrame.editBox.chatType = "RAID";
		elseif (IsInGuild()) then
			chatFrame.editBox.chatType = "GUILD";
		elseif JoinedChannel then
			for i = 4, 1, -1 do
				if channel[keys[i]] > 0 then
					chatFrame.editBox.chatType = "CHANNEL"
					chatFrame.editBox.channelTarget = channel[keys[i]]
					break
				end
			end
		else
			chatFrame.editBox.chatType = "SAY";
		end
	elseif (chatFrame.editBox.chatType == "RAID") then
		if (IsInGuild()) then
			chatFrame.editBox.chatType = "GUILD";
		elseif JoinedChannel then
			for i = 4, 1, -1 do
				if channel[keys[i]] > 0 then
					chatFrame.editBox.chatType = "CHANNEL"
					chatFrame.editBox.channelTarget = channel[keys[i]]
					break
				end
			end
		else
			chatFrame.editBox.chatType = "SAY";
		end
	elseif (chatFrame.editBox.chatType == "GUILD") then
		if JoinedChannel then
			for i = 4, 1, -1 do
				if channel[keys[i]] > 0 then
					chatFrame.editBox.chatType = "CHANNEL"
					chatFrame.editBox.channelTarget = channel[keys[i]]
					break
				end
			end
		else
			chatFrame.editBox.chatType = "SAY";
		end
	elseif (chatFrame.editBox.chatType == "CHANNEL") then
		local currentChannelId = GetChannelName(chatFrame.editBox.channelTarget);
		local found = false
		for i = 4, 1, -1 do
			if channel[keys[i]] > currentChannelId then
				chatFrame.editBox.chatType = "CHANNEL"
				chatFrame.editBox.channelTarget = channel[keys[i]]
				found = true
				break
			end
		end
		if not found then
			chatFrame.editBox.chatType = "SAY";
		end
	else
		chatFrame.editBox.chatType = "SAY";
	end
	ChatEdit_UpdateHeader(chatFrame.editBox);

	local text = this:GetText();
	text = processString(text)
	chatFrame.editBox:SetText(text)
end)
