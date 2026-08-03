--------------------------------------------------
-- ChatBarExtras.lua
-- Plugin shortcuts, emote menu, ready check, countdown
-- Ported from S_ChatBar260720
--------------------------------------------------

local function ChatBar_ExtrasAddonLoaded(name)
	return IsAddOnLoaded(name);
end

local function ChatBar_ExtrasHidden(label)
	return ChatBar_HiddenButtons[label];
end

local function ChatBar_ExtrasShowIfAddon(addonName, label)
	return ChatBar_ExtrasAddonLoaded(addonName) and (not ChatBar_ExtrasHidden(label));
end

local function ChatBar_ExtrasShowAlways(label)
	return (not ChatBar_ExtrasHidden(label));
end

local function ChatBar_ExtrasToggleFrame(frame)
	if (not frame) then
		return;
	end
	if (frame:IsShown()) then
		frame:Hide();
	else
		frame:Show();
	end
end

--------------------------------------------------
-- Emote menu
--------------------------------------------------

local ChatBar_EmoteData = {
	{
		text = "常用表情",
		menuList = {
			{ text = "跳舞", command = "/dance" },
			{ text = "特殊跳舞", command = "/dancespecial" },
			{ text = "好的", command = "/yes" },
			{ text = "不", command = "/no" },
			{ text = "否决", command = "/veto" },
			{ text = "大笑", command = "/laugh" },
			{ text = "咯咯笑", command = "/cackle" },
			{ text = "哭泣", command = "/cry" },
			{ text = "挥手", command = "/wave" },
			{ text = "鞠躬", command = "/bow" },
			{ text = "感谢", command = "/thank" },
			{ text = "问候", command = "/hi" },
			{ text = "性感", command = "/sexy" },
			{ text = "法力不足", command = "/oom" },
			{ text = "敌人", command = "/incoming" },
			{ text = "开火", command = "/openfire" },
			{ text = "再见", command = "/bye" },
			{ text = "胜利", command = "/victory" },
			{ text = "祝贺", command = "/cong" }
		}
	},
	{
		text = "社交表情",
		menuList = {
			{ text = "欢呼", command = "/cheer" },
			{ text = "敬礼", command = "/salute" },
			{ text = "问候", command = "/greet" },
			{ text = "亲吻", command = "/kiss" },
			{ text = "舔", command = "/lick" },
			{ text = "咚", command = "/doh" },
			{ text = "糊涂", command = "/confused" },
			{ text = "鼓掌", command = "/applaud" },
			{ text = "拥抱", command = "/hug" },
			{ text = "按摩", command = "/massage" },
			{ text = "欢迎", command = "/welcome" },
			{ text = "赞扬", command = "/commend" },
			{ text = "乞求", command = "/beg" },
			{ text = "轻拍", command = "/pat" },
			{ text = "小猫", command = "/cat" },
			{ text = "眨眼", command = "/blink" }
		}
	},
	{
		text = "负面表情",
		menuList = {
			{ text = "生气", command = "/angry" },
			{ text = "放屁", command = "/fart" },
			{ text = "耳光", command = "/slap" },
			{ text = "哈欠", command = "/yawn" },
			{ text = "嘲笑", command = "/mock" },
			{ text = "威胁", command = "/threaten" },
			{ text = "侮辱", command = "/rude" },
			{ text = "咆哮", command = "/roar" },
			{ text = "皱眉", command = "/frown" },
			{ text = "叹气", command = "/sigh" },
			{ text = "撕咬", command = "/bite" },
			{ text = "退缩", command = "/cower" },
			{ text = "嘲讽", command = "/taunt" },
			{ text = "咳嗽", command = "/cough" },
			{ text = "幸灾乐祸", command = "/gloat" },
			{ text = "凌辱", command = "/insult" },
			{ text = "哀悼", command = "/mourn" },
			{ text = "打嗝", command = "/burp" }
		}
	},
	{
		text = "其他表情",
		menuList = {
			{ text = "坐下", command = "/sit" },
			{ text = "卑微", command = "/peon" },
			{ text = "站立", command = "/stand" },
			{ text = "睡觉", command = "/sleep" },
			{ text = "吃东西", command = "/eat" },
			{ text = "喝酒", command = "/drink" },
			{ text = "工作", command = "/work" },
			{ text = "失落", command = "/flop" },
			{ text = "火车", command = "/train" },
			{ text = "屁股", command = "/moon" },
			{ text = "强壮", command = "/strong" },
			{ text = "臭味", command = "/stink" },
			{ text = "压关节", command = "/knuckles" },
			{ text = "小鸡", command = "/chicken" }
		}
	}
};

local function ChatBar_CreateEmoteMenu(level)
	if (not level) then
		return;
	end

	local info;
	local i;
	local category;
	local emote;

	if (level == 1) then
		for i = 1, table.getn(ChatBar_EmoteData) do
			category = ChatBar_EmoteData[i];
			info = {};
			info.text = category.text;
			info.notCheckable = 1;
			info.hasArrow = 1;
			info.value = category;
			UIDropDownMenu_AddButton(info, level);
		end
	elseif (level == 2) then
		category = UIDROPDOWNMENU_MENU_VALUE;
		if (category and category.menuList) then
			for i = 1, table.getn(category.menuList) do
				emote = category.menuList[i];
				info = {};
				info.text = emote.text;
				info.notCheckable = 1;
				info.func = function()
					local editBox = ChatFrame1.editBox;
					if (editBox) then
						editBox:SetText(emote.command);
						ChatEdit_SendText(editBox, 0);
					elseif (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox) then
						DEFAULT_CHAT_FRAME.editBox:SetText(emote.command);
						ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0);
					end
				end;
				UIDropDownMenu_AddButton(info, level);
			end
		end
	end
end

local ChatBar_EmoteDropdown = CreateFrame("Frame", "ChatBar_EmoteDropdown", UIParent, "UIDropDownMenuTemplate");

function ChatBar_EmoteButtonClick(button)
	UIDropDownMenu_Initialize(ChatBar_EmoteDropdown, ChatBar_CreateEmoteMenu, "MENU");
	ToggleDropDownMenu(1, nil, ChatBar_EmoteDropdown, this, 0, 0);
end

--------------------------------------------------
-- Ready check / Countdown
--------------------------------------------------

function ChatBar_ReadyCheckButtonClick(button)
	if (DoReadyCheck) then
		DoReadyCheck();
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000当前客户端不支持就位确认功能|r");
	end
end

local ChatBar_CountdownFrame = CreateFrame("Frame", "ChatBar_CountdownFrame");
ChatBar_CountdownFrame:Hide();
local ChatBar_CountdownRemaining = 0;
local ChatBar_CountdownElapsed = 0;

local function ChatBar_SendCountdownMessage(msg)
	local isRaidLeader = IsRaidLeader and (IsRaidLeader() == 1);
	local isRaidOfficer = IsRaidOfficer and (IsRaidOfficer() == 1);
	if (GetNumRaidMembers() > 0) and (isRaidLeader or isRaidOfficer) then
		SendChatMessage(msg, "RAID_WARNING");
	elseif (GetNumRaidMembers() > 0) then
		SendChatMessage(msg, "RAID");
	elseif (GetNumPartyMembers() > 0) then
		SendChatMessage(msg, "PARTY");
	else
		SendChatMessage(msg, "SAY");
	end
end

ChatBar_CountdownFrame:SetScript("OnUpdate", function()
	ChatBar_CountdownElapsed = ChatBar_CountdownElapsed + arg1;
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

function ChatBar_CountdownButtonClick(button)
	if (button == "LeftButton") then
		ChatBar_StartCountdown(ChatBar_CountdownLen or 6);
	else
		ChatBar_StopCountdown();
	end
end

--------------------------------------------------
-- Plugin shortcut clicks
--------------------------------------------------

function ChatBar_MeetingButtonClick(button)
	if (button == "LeftButton") then
		if (Meeting and Meeting.Toggle) then
			Meeting:Toggle();
		end
	elseif (button == "RightButton") then
		if (LFT_Toggle) then
			LFT_Toggle();
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000LFT功能未加载|r");
		end
	end
end

function ChatBar_RaidProgressButtonClick(button)
	if (RealTableUI and RealTableUI.Show) then
		if (RealTableUI.IsVisible and RealTableUI.IsVisible()) then
			RealTableUI.Hide();
		else
			RealTableUI.Show();
		end
	elseif (RaidProgressUI and RaidProgressUI.mainFrame) then
		if (RaidProgressUI.mainFrame:IsShown()) then
			RaidProgressUI:HideCombinedInfo();
		else
			RaidProgressUI:ShowCombinedInfo();
		end
	else
		ChatFrame_OpenChat("/rp", DEFAULT_CHAT_FRAME);
	end
end

function ChatBar_XyTrackerButtonClick(button)
	if (XyTrackerFrame) then
		if (not XyTrackerFrame:IsShown()) then
			if (XyTracker_ShowXyWindow) then
				XyTracker_ShowXyWindow();
			else
				XyTrackerFrame:Show();
			end
		else
			if (XyTracker_HideXyWindow) then
				XyTracker_HideXyWindow();
			else
				XyTrackerFrame:Hide();
			end
		end
	end
end

function ChatBar_AtlasLootButtonClick(button)
	if (button == "LeftButton") then
		if (ChatBar_ExtrasAddonLoaded("AtlasLoot") and AtlasLootDefaultFrame) then
			ChatBar_ExtrasToggleFrame(AtlasLootDefaultFrame);
		elseif (ChatBar_ExtrasAddonLoaded("Atlas-CFM") and AtlasCFMFrame) then
			ChatBar_ExtrasToggleFrame(AtlasCFMFrame);
		elseif (ChatBar_ExtrasAddonLoaded("InstanceJournal") and IJ_InstanceJournalFrame) then
			ChatBar_ExtrasToggleFrame(IJ_InstanceJournalFrame);
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到 AtlasLoot / Atlas-CFM / InstanceJournal 插件|r");
		end
	elseif (button == "RightButton") then
		if (ChatBar_ExtrasAddonLoaded("InstanceJournal") and IJ_InstanceJournalFrame) then
			ChatBar_ExtrasToggleFrame(IJ_InstanceJournalFrame);
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000InstanceJournal 插件未加载或界面不存在|r");
		end
	end
end

function ChatBar_SuperMacroButtonClick(button)
	if (SuperMacroFrame) then
		ChatBar_ExtrasToggleFrame(SuperMacroFrame);
	elseif (MacroFrame) then
		ChatBar_ExtrasToggleFrame(MacroFrame);
	end
end

function ChatBar_ActionBarProfilesButtonClick(button)
	if (ABP_SlashCommand and ABP_DropDownMenu) then
		ToggleDropDownMenu(1, nil, ABP_DropDownMenu, this, 0, 0);
	end
end

function ChatBar_OutfitterButtonClick(button)
	if (OutfitterMinimapButton) then
		if (OutfitterMinimapDropDown_OnLoad) then
			OutfitterMinimapDropDown_OnLoad();
		end
		this.ChangedValueFunc = OutfitterMinimapButton_ItemSelected;
		if (OutfitterMinimapDropDown_Initialize) then
			UIDropDownMenu_Initialize(this, OutfitterMinimapDropDown_Initialize);
		end
		ToggleDropDownMenu(1, nil, this, this, 0, 0);
		if (OutfitterMinimapDropDown_AdjustScreenPosition) then
			OutfitterMinimapDropDown_AdjustScreenPosition(this);
		end
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Outfitter 小地图按钮未找到|r");
	end
end

function ChatBar_TrinketMenuButtonClick(button)
	ChatBar_ExtrasToggleFrame(TrinketMenu_OptFrame);
end

function ChatBar_RaidCheckButtonClick(button)
	if (RC_MainFrame) then
		ChatBar_ExtrasToggleFrame(RC_MainFrame);
	else
		ChatFrame_OpenChat("/RC ", DEFAULT_CHAT_FRAME);
	end
end

function ChatBar_SpiritSenseRecButtonClick(button)
	ChatBar_ExtrasToggleFrame(SpiritSenseRecMainFrame);
end

function ChatBar_BetterCharacterStatsButtonClick(button)
	if (button == "LeftButton") then
		if (BCS and BCS.PropertiesPanel and BCS.PropertiesPanel.mainFrame) then
			ChatBar_ExtrasToggleFrame(BCS.PropertiesPanel.mainFrame);
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000属性面板模块未加载|r");
		end
	elseif (button == "RightButton") then
		if (BCS and BCS.PropertiesPanel and BCS.PropertiesPanel.GetPropertiesForChat) then
			local propertiesText = BCS.PropertiesPanel:GetPropertiesForChat();
			local targetName = UnitName("target");
			if (targetName) then
				SendChatMessage(propertiesText, "WHISPER", nil, targetName);
			elseif (WIM_EditBoxInFocus) then
				WIM_EditBoxInFocus:SetText(propertiesText);
				WIM_EditBoxInFocus:HighlightText();
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000属性面板: 没有选择目标且WIM未加载|r");
			end
			if (BCS.PropertiesPanel.mainFrame) then
				BCS.PropertiesPanel.mainFrame:Hide();
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000属性面板模块未加载|r");
		end
	end
end

function ChatBar_AutoMarkerButtonClick(button)
	ChatBar_ExtrasToggleFrame(AutoMarkerUIFrame);
end

function ChatBar_AutomatonexButtonClick(button)
	if (Automaton and Automaton.OnClick) then
		Automaton.OnClick();
	else
		ChatFrame_OpenChat("/AUTO ", DEFAULT_CHAT_FRAME);
	end
end

function ChatBar_TrackingButtonClick(button)
	if (button == "LeftButton") then
		if (TrackingFrame and TrackingFrame.InitMenu) then
			TrackingFrame:InitMenu();
			ToggleDropDownMenu(1, nil, TrackingFrame.menu, this, 0, 0);
		end
	elseif (button == "RightButton") then
		if (ChatBar_TrackingMode == "native") then
			ChatBar_TrackingMode = "modern";
			DEFAULT_CHAT_FRAME:AddMessage("|cffffff00追踪按钮模式: 现代 (modern)|r");
		elseif (ChatBar_TrackingMode == "modern") then
			ChatBar_TrackingMode = "hide";
			DEFAULT_CHAT_FRAME:AddMessage("|cffffff00追踪按钮模式: 隐藏 (hide)|r");
		else
			ChatBar_TrackingMode = "native";
			DEFAULT_CHAT_FRAME:AddMessage("|cffffff00追踪按钮模式: 原生 (native)|r");
		end

		if (ChatBar_TrackingMode == "native") then
			if (TrackingFrame) then TrackingFrame:Hide(); end
			if (MiniMapTrackingFrame) then MiniMapTrackingFrame:Show(); end
		elseif (ChatBar_TrackingMode == "modern") then
			if (TrackingFrame) then TrackingFrame:Show(); end
			if (MiniMapTrackingFrame) then MiniMapTrackingFrame:Hide(); end
		else
			if (TrackingFrame) then TrackingFrame:Hide(); end
			if (MiniMapTrackingFrame) then MiniMapTrackingFrame:Hide(); end
		end
	end
end

function ChatBar_SilverDragonRadarButtonClick(button)
	if (button == "LeftButton") then
		if (SunRadar_MainFrame) then
			ChatBar_ExtrasToggleFrame(SunRadar_MainFrame);
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到 SunRadar_MainFrame，请确认 SunRadar 插件已正确加载|r");
		end
	end
end

local function ChatBar_AtlasLootAddonLoaded()
	return ChatBar_ExtrasAddonLoaded("AtlasLoot")
		or ChatBar_ExtrasAddonLoaded("InstanceJournal")
		or ChatBar_ExtrasAddonLoaded("Atlas-CFM");
end

--------------------------------------------------
-- Register extras into ChatBar_ChatTypes
--------------------------------------------------

local function ChatBar_RegisterExtra(entry)
	table.insert(ChatBar_ChatTypes, entry);
end

ChatBar_RegisterExtra({
	type = "CB_MEETING",
	shortText = function() return CHATBAR_MEETING_ABRV; end,
	text = function() return CHATBAR_MEETING; end,
	click = ChatBar_MeetingButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("Meeting", CHATBAR_MEETING); end,
	colorType = "SYSTEM",
	customColor = { r = 1, g = 165 / 255, b = 0 }
});

ChatBar_RegisterExtra({
	type = "CB_RAIDPROGRESS",
	shortText = function() return CHATBAR_RAIDPROGRESS_ABRV; end,
	text = function() return CHATBAR_RAIDPROGRESS; end,
	click = ChatBar_RaidProgressButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("RaidProgress", CHATBAR_RAIDPROGRESS); end,
	colorType = "SYSTEM",
	customColor = { r = 1, g = 1, b = 0 }
});

ChatBar_RegisterExtra({
	type = "CB_XYTRACKER",
	shortText = function() return CHATBAR_XYTRACKER_ABRV; end,
	text = function() return CHATBAR_XYTRACKER; end,
	click = ChatBar_XyTrackerButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("XyTracker", CHATBAR_XYTRACKER); end,
	colorType = "SYSTEM",
	customColor = { r = 147 / 255, g = 112 / 255, b = 219 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_ATLASLOOT",
	shortText = function() return CHATBAR_ATLASLOOT_ABRV; end,
	text = function() return CHATBAR_ATLASLOOT; end,
	click = ChatBar_AtlasLootButtonClick,
	show = function()
		return ChatBar_AtlasLootAddonLoaded() and (not ChatBar_ExtrasHidden(CHATBAR_ATLASLOOT));
	end,
	colorType = "SYSTEM",
	customColor = { r = 180 / 255, g = 160 / 255, b = 230 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_SUPERMACRO",
	shortText = function() return CHATBAR_SUPERMACRO_ABRV; end,
	text = function() return CHATBAR_SUPERMACRO; end,
	click = ChatBar_SuperMacroButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("SuperMacro", CHATBAR_SUPERMACRO); end,
	colorType = "SYSTEM",
	customColor = { r = 120 / 255, g = 160 / 255, b = 230 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_ACTIONBARPROFILES",
	shortText = function() return CHATBAR_ACTIONBARPROFILES_ABRV; end,
	text = function() return CHATBAR_ACTIONBARPROFILES; end,
	click = ChatBar_ActionBarProfilesButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("ActionBarProfiles", CHATBAR_ACTIONBARPROFILES); end,
	colorType = "SYSTEM",
	customColor = { r = 200 / 255, g = 160 / 255, b = 230 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_OUTFITTER",
	shortText = function() return CHATBAR_OUTFITTER_ABRV; end,
	text = function() return CHATBAR_OUTFITTER; end,
	click = ChatBar_OutfitterButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("Outfitter", CHATBAR_OUTFITTER); end,
	colorType = "SYSTEM",
	customColor = { r = 200 / 255, g = 180 / 255, b = 100 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_TRINKETMENU",
	shortText = function() return CHATBAR_TRINKETMENU_ABRV; end,
	text = function() return CHATBAR_TRINKETMENU; end,
	click = ChatBar_TrinketMenuButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("TrinketMenu", CHATBAR_TRINKETMENU); end,
	colorType = "SYSTEM",
	customColor = { r = 120 / 255, g = 200 / 255, b = 200 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_RAIDCHECK",
	shortText = function() return CHATBAR_RAIDCHECK_ABRV; end,
	text = function() return CHATBAR_RAIDCHECK; end,
	click = ChatBar_RaidCheckButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("RaidCheck", CHATBAR_RAIDCHECK); end,
	colorType = "SYSTEM",
	customColor = { r = 1, g = 1, b = 0 }
});

ChatBar_RegisterExtra({
	type = "CB_SPIRITSENSEREC",
	shortText = function() return CHATBAR_SPIRITSENSEREC_ABRV; end,
	text = function() return CHATBAR_SPIRITSENSEREC; end,
	click = ChatBar_SpiritSenseRecButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("SpiritSenseRec", CHATBAR_SPIRITSENSEREC); end,
	colorType = "SYSTEM",
	customColor = { r = 60 / 255, g = 160 / 255, b = 250 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_BETTERCHARACTERSTATS",
	shortText = function() return CHATBAR_BETTERCHARACTERSTATS_ABRV; end,
	text = function() return CHATBAR_BETTERCHARACTERSTATS; end,
	click = ChatBar_BetterCharacterStatsButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("BetterCharacterStats", CHATBAR_BETTERCHARACTERSTATS); end,
	colorType = "SYSTEM",
	customColor = { r = 180 / 255, g = 160 / 255, b = 230 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_AUTOMARKER",
	shortText = function() return CHATBAR_AUTOMARKER_ABRV; end,
	text = function() return CHATBAR_AUTOMARKER; end,
	click = ChatBar_AutoMarkerButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("AutoMarker", CHATBAR_AUTOMARKER); end,
	colorType = "SYSTEM",
	customColor = { r = 60 / 255, g = 160 / 255, b = 250 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_AUTOMATONEX",
	shortText = function() return CHATBAR_AUTOMATONEX_ABRV; end,
	text = function() return CHATBAR_AUTOMATONEX; end,
	click = ChatBar_AutomatonexButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("Automatonex", CHATBAR_AUTOMATONEX); end,
	colorType = "SYSTEM",
	customColor = { r = 1, g = 0.8, b = 0.6 }
});

ChatBar_RegisterExtra({
	type = "CB_TRACKING",
	shortText = function() return CHATBAR_TRACKING_ABRV; end,
	text = function() return CHATBAR_TRACKING; end,
	click = ChatBar_TrackingButtonClick,
	show = function() return ChatBar_ExtrasShowAlways(CHATBAR_TRACKING); end,
	colorType = "SYSTEM",
	customColor = { r = 60 / 255, g = 160 / 255, b = 250 / 255 }
});

ChatBar_RegisterExtra({
	type = "CB_SILVERDRAGONRADAR",
	shortText = function() return CHATBAR_SILVERDRAGONRADAR_ABRV; end,
	text = function() return CHATBAR_SILVERDRAGONRADAR; end,
	click = ChatBar_SilverDragonRadarButtonClick,
	show = function() return ChatBar_ExtrasShowIfAddon("SilverDragonRadar", CHATBAR_SILVERDRAGONRADAR); end,
	colorType = "SYSTEM",
	customColor = { r = 1, g = 215 / 255, b = 0 }
});

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
