--------------------------------------------------
-- ChatBarExtras.lua
-- Built-in tools: emote menu, ready check, countdown
--------------------------------------------------

local function ChatBar_ExtrasHidden(label)
	return ChatBar_HiddenButtons[label];
end

local function ChatBar_ExtrasShowAlways(label)
	return (not ChatBar_ExtrasHidden(label));
end

--------------------------------------------------
-- Emote menu
--------------------------------------------------

local ChatBar_EmoteData = {
	{
		text = "常用表情",
		menuList = {
			{ text = "跳舞", token = "DANCE" },
			{ text = "特殊跳舞", token = "DANCESPECIAL" },
			{ text = "好的", token = "YES" },
			{ text = "不", token = "NO" },
			{ text = "否决", token = "VETO" },
			{ text = "大笑", token = "LAUGH" },
			{ text = "咯咯笑", token = "CACKLE" },
			{ text = "哭泣", token = "CRY" },
			{ text = "挥手", token = "WAVE" },
			{ text = "鞠躬", token = "BOW" },
			{ text = "感谢", token = "THANK" },
			{ text = "问候", token = "HELLO" },
			{ text = "性感", token = "SEXY" },
			{ text = "法力不足", token = "OOM" },
			{ text = "敌人", token = "INCOMING" },
			{ text = "开火", token = "OPENFIRE" },
			{ text = "再见", token = "BYE" },
			{ text = "胜利", token = "VICTORY" },
			{ text = "祝贺", token = "CONGRATULATE" }
		}
	},
	{
		text = "社交表情",
		menuList = {
			{ text = "欢呼", token = "CHEER" },
			{ text = "敬礼", token = "SALUTE" },
			{ text = "问候", token = "GREET" },
			{ text = "亲吻", token = "KISS" },
			{ text = "舔", token = "LICK" },
			{ text = "咚", token = "DOH" },
			{ text = "糊涂", token = "CONFUSED" },
			{ text = "鼓掌", token = "APPLAUD" },
			{ text = "拥抱", token = "HUG" },
			{ text = "按摩", token = "MASSAGE" },
			{ text = "欢迎", token = "WELCOME" },
			{ text = "赞扬", token = "COMMEND" },
			{ text = "乞求", token = "BEG" },
			{ text = "轻拍", token = "PAT" },
			{ text = "小猫", token = "CAT" },
			{ text = "眨眼", token = "BLINK" }
		}
	},
	{
		text = "负面表情",
		menuList = {
			{ text = "生气", token = "ANGRY" },
			{ text = "放屁", token = "FART" },
			{ text = "耳光", token = "SLAP" },
			{ text = "哈欠", token = "YAWN" },
			{ text = "嘲笑", token = "MOCK" },
			{ text = "威胁", token = "THREATEN" },
			{ text = "侮辱", token = "RUDE" },
			{ text = "咆哮", token = "ROAR" },
			{ text = "皱眉", token = "FROWN" },
			{ text = "叹气", token = "SIGH" },
			{ text = "撕咬", token = "BITE" },
			{ text = "退缩", token = "COWER" },
			{ text = "嘲讽", token = "TAUNT" },
			{ text = "咳嗽", token = "COUGH" },
			{ text = "幸灾乐祸", token = "GLOAT" },
			{ text = "凌辱", token = "INSULT" },
			{ text = "哀悼", token = "MOURN" },
			{ text = "打嗝", token = "BURP" }
		}
	},
	{
		text = "其他表情",
		menuList = {
			{ text = "坐下", token = "SIT" },
			{ text = "卑微", token = "PEON" },
			{ text = "站立", token = "STAND" },
			{ text = "睡觉", token = "SLEEP" },
			{ text = "吃东西", token = "EAT" },
			{ text = "喝酒", token = "DRINK" },
			{ text = "工作", token = "WORK" },
			{ text = "失落", token = "FLOP" },
			{ text = "火车", token = "TRAIN" },
			{ text = "屁股", token = "MOON" },
			{ text = "强壮", token = "STRONG" },
			{ text = "臭味", token = "STINK" },
			{ text = "压关节", token = "KNUCKLES" },
			{ text = "小鸡", token = "CHICKEN" }
		}
	}
};

local function ChatBar_CreateEmoteMenu(frame, level, menuList)
	-- 旧调用只传 level；Forever 传 (dropdown, level, menuList)
	if (type(frame) == "number") and (level == nil) then
		level = frame;
		frame = nil;
	end
	if (not level) then
		level = 1;
	end

	local info;
	local i;
	local category;
	local emote;

	if (level == 1) then
		for i = 1, #(ChatBar_EmoteData) do
			category = ChatBar_EmoteData[i];
			info = {};
			info.text = category.text;
			info.notCheckable = 1;
			info.hasArrow = 1;
			info.value = category;
			UIDropDownMenu_AddButton(info, level);
		end
	elseif (level == 2) then
		category = menuList or UIDROPDOWNMENU_MENU_VALUE;
		if (category and category.menuList) then
			for i = 1, #(category.menuList) do
				emote = category.menuList[i];
				info = {};
				info.text = emote.text;
				info.notCheckable = 1;
				info.func = function()
					if (emote.token) and (DoEmote) then
						pcall(DoEmote, emote.token);
					end
				end;
				UIDropDownMenu_AddButton(info, level);
			end
		end
	end
end

local ChatBar_EmoteDropdown = CreateFrame("Frame", "ChatBar_EmoteDropdown", UIParent, "UIDropDownMenuTemplate");

function ChatBar_EmoteButtonClick(button, buttonFrame)
	UIDropDownMenu_Initialize(ChatBar_EmoteDropdown, ChatBar_CreateEmoteMenu, "MENU");
	ToggleDropDownMenu(1, nil, ChatBar_EmoteDropdown, buttonFrame, 0, 0);
end

--------------------------------------------------
-- Ready check / Countdown
--------------------------------------------------

function ChatBar_ReadyCheckButtonClick(button, buttonFrame)
	if (not DoReadyCheck) then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000当前客户端不支持就位确认功能|r");
		return;
	end
	if (not IsInGroup()) or ((not UnitIsGroupLeader("player")) and (not UnitIsGroupAssistant("player"))) then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000只有队长或助理可以发起就位确认|r");
		return;
	end
	DoReadyCheck();
end

local ChatBar_CountdownFrame = CreateFrame("Frame", "ChatBar_CountdownFrame");
ChatBar_CountdownFrame:Hide();
local ChatBar_CountdownRemaining = 0;
local ChatBar_CountdownElapsed = 0;

local function ChatBar_SendCountdownMessage(msg)
	local isLeader = UnitIsGroupLeader("player");
	local isAssistant = UnitIsGroupAssistant("player");
	if (IsInRaid()) and (isLeader or isAssistant) then
		SendChatMessage(msg, "RAID_WARNING");
	elseif (IsInRaid()) then
		SendChatMessage(msg, "RAID");
	elseif (IsInGroup()) then
		SendChatMessage(msg, "PARTY");
	else
		SendChatMessage(msg, "SAY");
	end
end

ChatBar_CountdownFrame:SetScript("OnUpdate", function(self, elapsed)
	ChatBar_CountdownElapsed = ChatBar_CountdownElapsed + elapsed;
	if (ChatBar_CountdownElapsed >= 1) then
		ChatBar_CountdownElapsed = ChatBar_CountdownElapsed - 1;
		ChatBar_CountdownRemaining = ChatBar_CountdownRemaining - 1;
		if (ChatBar_CountdownRemaining > 0) then
			ChatBar_SendCountdownMessage("倒计时 " .. ChatBar_CountdownRemaining);
		elseif (ChatBar_CountdownRemaining == 0) then
			ChatBar_SendCountdownMessage(">> 开怪 <<");
			ChatBar_CountdownFrame:Hide();
		end
	end
end);

local function ChatBar_StartCountdown(seconds)
	if (ChatBar_CountdownFrame:IsShown()) then
		return;
	end
	seconds = seconds or ChatBar_CountdownLen or 6;
	ChatBar_CountdownRemaining = seconds;
	ChatBar_CountdownElapsed = 0;
	ChatBar_SendCountdownMessage("倒计时 " .. seconds);
	ChatBar_CountdownFrame:Show();
end

local function ChatBar_StopCountdown()
	if (ChatBar_CountdownFrame:IsShown()) then
		ChatBar_CountdownFrame:Hide();
		ChatBar_SendCountdownMessage("倒计时取消");
	end
end

local function ChatBar_UseNativeCountdown()
	return (C_PartyInfo) and (C_PartyInfo.DoCountdown) and (IsInGroup());
end

function ChatBar_CountdownButtonClick(button, buttonFrame)
	local seconds = ChatBar_CountdownLen or 6;
	if (button == "LeftButton") then
		if (ChatBar_UseNativeCountdown()) then
			C_PartyInfo.DoCountdown(seconds);
		else
			ChatBar_StartCountdown(seconds);
		end
	else
		if (ChatBar_UseNativeCountdown()) then
			C_PartyInfo.DoCountdown(0);
		else
			ChatBar_StopCountdown();
		end
	end
end

--------------------------------------------------
-- Register extras into ChatBar_ChatTypes
--------------------------------------------------

local function ChatBar_RegisterExtra(entry)
	table.insert(ChatBar_ChatTypes, entry);
end

ChatBar_RegisterExtra({
	type = "CB_READYCHECK",
	shortText = function() return CHATBAR_READYCHECK_ABRV; end,
	text = function() return CHATBAR_READYCHECK; end,
	click = ChatBar_ReadyCheckButtonClick,
	show = function() return ChatBar_ExtrasShowAlways(CHATBAR_READYCHECK); end,
	colorType = "SYSTEM",
	customColor = { r = 100 / 255, g = 230 / 255, b = 100 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_COUNTDOWN",
	shortText = function() return CHATBAR_COUNTDOWN_ABRV; end,
	text = function() return CHATBAR_COUNTDOWN; end,
	click = ChatBar_CountdownButtonClick,
	show = function() return ChatBar_ExtrasShowAlways(CHATBAR_COUNTDOWN); end,
	colorType = "SYSTEM",
	customColor = { r = 1, g = 200 / 255, b = 80 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_EMOTEMENU",
	shortText = function() return CHATBAR_EMOTEMENU_ABRV; end,
	text = function() return CHATBAR_EMOTEMENU; end,
	click = ChatBar_EmoteButtonClick,
	show = function() return ChatBar_ExtrasShowAlways(CHATBAR_EMOTEMENU); end,
	colorType = "SYSTEM",
	customColor = { r = 0.906, g = 0.298, b = 0.475 }
});
