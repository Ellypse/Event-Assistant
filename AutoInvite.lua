local EventAssistant = LibStub("AceAddon-3.0"):NewAddon("EventAssistant", "AceConsole-3.0");

local function Print(text)
	print("|cffD4C26A[Event Assistant]|r: " .. text );
end

local MAIN_ICON = "Interface\\ICONS\\Achievement_Character_Gnome_Female"
local today = date("*t");

-- Use rainbow icon in June, for the Running of the Trolls
if today.month == 6 then
	MAIN_ICON = "Interface\\ICONS\\Achievement_DoubleRainbow"
end

function EventAssistant:OnEnable()
	
	local strsub = strsub;
	local strlen = strlen;
	local max = max;
	local pairs = pairs;
	local strsplit = strsplit;
	local IsModifiedClick = IsModifiedClick;
	local GetRealmName = GetRealmName;
	local UnitName = UnitName;
	local IsShiftKeyDown = IsShiftKeyDown;
	local GuildInvite = GuildInvite;
	local CanGuildRemove = CanGuildRemove;
	local GetNumGuildMembers = GetNumGuildMembers;
	local GetGuildInfo = GetGuildInfo;
	local GetGuildRosterInfo = GetGuildRosterInfo;
	local GuildUninvite = GuildUninvite;
	local ShowUIPanel = ShowUIPanel;
	local HideUIPanel = HideUIPanel;
	local After = C_Timer.After;
	local refreshWindowUI;

	local MAX_GUILD_MEMBERS = 1000;
	
	local userName, userRealm = UnitFullName("player");
	userName = userName .. "-" .. userRealm;
	
	local function tableSize(table, ifValue)
		local count = 0;
		for _, value in pairs(table) do
			if not ifValue or value == ifValue then
				count = count + 1;
			end
		end
		return count;
	end
	
	local modIsInInvitationMode = false;
	EventAssistantPlayersTable = {};

	local function openUI()
		local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
		if guildName then
			if not EventAssistantMainFrame:IsVisible() then
				refreshWindowUI();
				ShowUIPanel(EventAssistantMainFrame);
			else
				HideUIPanel(EventAssistantMainFrame)
			end
		else
			Print("|cffff0000You don't have a guild. You need a guild in order to use EventAssisant to invite people to your event guild|r");
		end
	end

	self:RegisterChatCommand("eva", openUI);

	local EventAssistantLDB = LibStub("LibDataBroker-1.1"):NewDataObject("EventAssistant", {
		type = "launcher",
		label = "Event Assistant",
		icon = MAIN_ICON,
		OnClick = openUI,
		tocname = "EventAssistant";
		---@param tooltip GameTooltip
		OnTooltipShow = function(tooltip)
			tooltip:SetText("Event Assistant", 1, 1, 1,1)
			tooltip:AddLine("Click to open")
			tooltip:AddLine("Drag and drop to move")
			tooltip:AddLine(" ")
			tooltip:AddLine("Invite queue (" .. tableSize(EventAssistantPlayersTable, 1) .. ")");
		end
	})
	local icon = LibStub("LibDBIcon-1.0")

	self.db = LibStub("AceDB-3.0"):New("EventAssistantConfig", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})
	icon:Register("EventAssistant", EventAssistantLDB, self.db.profile.minimap)

	---@type Frame
	local MMButton = icon:GetMinimapButton("EventAssistant");

	---@type Texture
	local Highlight = MMButton:CreateTexture(nil, "OVERLAY")
	Highlight:Hide();
	Highlight:SetAlpha(0);
	Highlight:SetBlendMode("ADD")
	Highlight:SetAtlas("groupfinder-eye-highlight")
	Highlight:SetAllPoints()
	MMButton.Highlight = Highlight;

	---@type AnimationGroup
	local AnimationGroup = MMButton:CreateAnimationGroup()
	AnimationGroup:SetToFinalAlpha(true)
	AnimationGroup:SetLooping("REPEAT")


	---@type Alpha
	AnimationGroup.Highlight = AnimationGroup:CreateAnimation("Alpha");
	AnimationGroup.Highlight:SetStartDelay(0.1)
	AnimationGroup.Highlight:SetSmoothing("NONE")
	AnimationGroup.Highlight:SetDuration(1.0)
	AnimationGroup.Highlight:SetOrder(1)
	AnimationGroup.Highlight:SetFromAlpha(1)
	AnimationGroup.Highlight:SetToAlpha(0)
	AnimationGroup.Highlight:SetTarget(MMButton.Highlight)

	MMButton.EyeHighlightAnim = AnimationGroup

	MMButton.glowLocks = {};

	local function flashMinimap()
		if tableSize(EventAssistantPlayersTable, 1) > 0 then
			Highlight:SetShown(true);
			AnimationGroup:Play()
			FlashClientIcon()
		else
			Highlight:SetShown(false);
			AnimationGroup:Stop()
		end
	end
	
	local function startInvitationMode()
		modIsInInvitationMode = true;
	end
	
	local function willEndInvitationMode()
		After(1, function()
			modIsInInvitationMode = false;
		end)
		flashMinimap()
	end
	
	local function invitePlayerToGuild(playerFullName)
		GuildInvite(playerFullName);
		EventAssistantPlayersTable[playerFullName] = 2;
	end
	
	--- Invite target on shift-click
	TargetFrame:HookScript("OnClick", function()
		if IsShiftKeyDown() then
			local targetName, targetRealm = UnitName("target");
			if not targetRealm then
				targetRealm = userRealm;
			end
			startInvitationMode();
			invitePlayerToGuild(targetName .. "-" .. targetRealm);
			Print("You have sent a guild invitation to " .. targetName);
			willEndInvitationMode();
		end
	end)
	
	hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
		if ( strsub(link, 1, 6) == "player" ) then
			local namelink, isGMLink;
			if ( strsub(link, 7, 8) == "GM" ) then
				namelink = strsub(link, 10);
				isGMLink = true;
			else
				namelink = strsub(link, 8);
			end
			local name, lineID, chatType, chatTarget = strsplit(":", namelink);
			if ( name and (strlen(name) > 0) ) then
				if ( IsModifiedClick("CHATLINK") ) then
					startInvitationMode();
					invitePlayerToGuild(name);
					Print("You have sent a guild invitation to " .. name);
					willEndInvitationMode();
				end
			end
		end
	
	end)
	
	Print("|cffDDDDDDShift-click on a name in chat or on a target frame to invite players to guild.|r");
	
	UIPanelWindows["EventAssistantMainFrame"] = { area = "left", pushable = 3, whileDead = 1 };
	
	SetPortraitToTexture(EventAssistantMainFrame.portrait, MAIN_ICON);
	
	function refreshWindowUI()
		local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
		local totalMembers, onlineMembers, onlineAndMobileMembers = GetNumGuildMembers();
		
		EventAssistantMainFrame.InnerText.guildMembersOnline:SetText("Guild members online: " .. onlineMembers);
		EventAssistantMainFrame.InnerText.guildMembersOffline:SetText("Guild members offline: " .. (totalMembers - onlineMembers));
		EventAssistantMainFrame.InnerText.guildMembersAvailable:SetText("Remaining guild spots: " .. (MAX_GUILD_MEMBERS - totalMembers));
		EventAssistantMainFrame.InnerText.addedWithEventAssistant:SetText("Guild members added via EventAssistant: " .. tableSize(EventAssistantPlayersTable, 2));
		
		local queueSize = tableSize(EventAssistantPlayersTable, 1);
		if queueSize > 0 then
			EventAssistantMainFrame.InviteAll:SetText("Invite queue (" .. tableSize(EventAssistantPlayersTable, 1) .. ")");
			EventAssistantMainFrame.InviteAll:Enable();
		else
			EventAssistantMainFrame.InviteAll:SetText("No invitations queued");
			EventAssistantMainFrame.InviteAll:Disable();
		end
		EventAssistantMainFrame.InviteAll:SetWidth(max(116, EventAssistantMainFrame.InviteAll:GetTextWidth() + 24));
		EventAssistantMainFrame.guildName:SetText(guildName);
	end
	
	EventAssistantMainFrame.InnerText.removeOfflineGuildMembers:SetScript("OnClick", function()
		local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
		if not CanGuildRemove() then
			Print("You do not have the rights to remove players from your guild.");
		end
		local totalMembers, onlineMembers, onlineAndMobileMembers = GetNumGuildMembers();
		for i = 1, totalMembers do
			local fullName, rank, rankIndex, level, class, zone, note, officernote, online, isAway, classFileName, achievementPoints, achievementRank, isMobile, canSoR, repStanding = GetGuildRosterInfo(i);
			if not online then
				if rankIndex < guildRankIndex + 1 then
					Print("Could not remove " .. fullName .. " because your rank is lower than theirs.");
				else
					GuildUninvite(fullName);
				end
			end
		end
	end)
	
	EventAssistantMainFrame.InnerText.removeOfflineGuildMembers:SetScript("OnEnter", function(self)
		local totalMembers, onlineMembers, onlineAndMobileMembers = GetNumGuildMembers();
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:AddLine("Remove offline guild members", 1, 1, 1);
		GameTooltip:AddLine("This button will try to remove " .. (totalMembers - onlineMembers) .. " offline people from the guild!", 1, nil, nil, nil, true);
		GameTooltip:AddLine("(Guild members with a higher rank than you cannot be removed.)", 1, 1, 0);
		GameTooltip:Show();
	end);
	EventAssistantMainFrame.InnerText.removeOfflineGuildMembers:SetScript("OnLeave", function()
		GameTooltip:Hide();
	end);
	
	
	EventAssistantMainFrame.InviteAll:SetScript("OnEnter", function(self)
		local queueSize = tableSize(EventAssistantPlayersTable, 1);
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:AddLine("Invite the " .. queueSize .. " player(s) that asked for an invitation", 1, 1, 1);
		GameTooltip:AddLine("Queue:", nil, nil, nil, nil, true);
		local index = 1;
		for playerName, status in pairs(EventAssistantPlayersTable) do
			if status == 1 then
				GameTooltip:AddLine(playerName, nil, nil, nil, nil, true);
			end
			index = index + 1;
			if index == 10 then
				break;
			end
		end
		if queueSize > index then
			GameTooltip:AddLine("And " .. (queueSize - index) .. " more...", 0.5, 1, 0);
		end
		GameTooltip:Show();
	end);
	EventAssistantMainFrame.InviteAll:SetScript("OnLeave", function()
		GameTooltip:Hide();
	end);
	
	EventAssistantMainFrame.InviteAll:SetScript("OnClick", function()
		startInvitationMode();
		local queueSize = tableSize(EventAssistantPlayersTable, 1);
		for playerName, status in pairs(EventAssistantPlayersTable) do
			if status == 1 then
				invitePlayerToGuild(playerName);
			end
		end
		Print("You have sent " .. queueSize .. " guild invitation(s).");
		willEndInvitationMode();
		flashMinimap();
	end)
	
	for _, channel in pairs({
		"CHAT_MSG_SAY",
		"CHAT_MSG_YELL",
		"CHAT_MSG_CHANNEL",
		"CHAT_MSG_WHISPER",
	}) do
		EventAssistantMainFrame:RegisterEvent(channel);
	end
	
	
	EventAssistantMainFrame:SetScript("OnEvent", function(frame, ...)
		local playerName = ({ ... })[3];
		local message = ({ ... })[2];
		if playerName
			and message:lower():find("invit")
		then
			if not playerName:find("-") then
				playerName = playerName .. "-" .. userRealm;
			end
			if EventAssistantPlayersTable[playerName] or playerName == userName then return end
			
			EventAssistantPlayersTable[playerName] = 1;
		end

		flashMinimap();
	end)
	
	EventAssistantMainFrame:SetScript("OnUpdate", function(self, elapsed)
		self.TimeSinceLastUpdate = (self.TimeSinceLastUpdate or 0) + elapsed;
		
		if (self.TimeSinceLastUpdate > 1) then
			refreshWindowUI();
			self.TimeSinceLastUpdate = 0;
			flashMinimap();
		end
	end)
	
	ChatFrame_AddMessageEventFilter( "CHAT_MSG_SYSTEM", function( self, event, msg )
		return modIsInInvitationMode
	end )

end