
local EventAssistant = LibStub("AceAddon-3.0"):NewAddon("EventAssistant", "AceConsole-3.0");

function EventAssistant:OnEnable()
	
	local strsub = strsub;
	local strlen = strlen;
	local strsplit = strsplit;
	local IsModifiedClick = IsModifiedClick;
	local GetRealmName = GetRealmName;
	local UnitName = UnitName;
	local IsShiftKeyDown = IsShiftKeyDown;
	local GuildInvite = GuildInvite;
	
	--- Invite target on shift-click
	TargetFrame:HookScript("OnClick", function()
		if IsShiftKeyDown() then
			local targetName, realm = UnitName("target");
			if not realm then
				realm = GetRealmName();
			end
			GuildInvite(targetName .. "-" .. realm);
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
					GuildInvite(name);
				end
			end
		end
	
	end)
	
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", function(...)
		local playerName = ({...})[4]
		GuildInvite(playerName);
	end)
	
	print("|cffD4C26A[Event Assistant enabled]|r |cffDDDDDDShift-click on a name in chat or on a target frame to invite players to guild.|r");
	
	UIPanelWindows["EventAssistantMainFrame"] =	{ area = "left", pushable = 3, whileDead = 1};
	
	SetPortraitToTexture(EventAssistantMainFrame.portrait, "Interface\\ICONS\\temp");
	
	local playersToInviteQueue = {};
	
	self:RegisterChatCommand("eva", function()
		
		local totalMembers, onlineMembers, onlineAndMobileMembers = GetNumGuildMembers();
		
		EventAssistantMainFrame.guildMembers:SetText("Guild members online: " .. onlineMembers);
		
		ShowUIPanel(EventAssistantMainFrame);
	end);
	
	EventAssistantMainFrame:RegisterEvent("CHAT_MSG_SAY");
	EventAssistantMainFrame:SetScript("OnEvent", function(frame, ...)
		local playerName = ({...})[3];
		if playerName and not playersToInviteQueue[playerName] then
			playersToInviteQueue[playerName] = 1;
		end
	end)
	
end