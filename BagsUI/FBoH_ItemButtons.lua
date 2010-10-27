local _SafeCall = FBoH._SafeCall;

local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

---------------------------------------------------------------------
-- Local functions and fields
---------------------------------------------------------------------

local _FBoH_GridAltItemButtonID = 1;
local _FBoH_GridBankItemButtonID = 1;
local _FBoH_GridGuildBankItemButtonID = 1;
local _FBoH_GridEmptyItemButtonID = 1;
local _FBoH_GridContainerItemButtonID = 1;

local
function _FBoH_GridItemButton_GetAltItemFrame(self)
	_SafeCall(function()
		if self.altItemFrame == nil then
			local name = "FBoH_GridAltItemButton_" .. _FBoH_GridAltItemButtonID;
			_FBoH_GridAltItemButtonID = _FBoH_GridAltItemButtonID + 1;
		
			local aFrame = CreateFrame("Button", name, self, "FBoH_AltItemButton");
			aFrame:SetPoint("TOPLEFT");
			aFrame:SetPoint("BOTTOMRIGHT");

			aFrame.tex = _G[name .. "IconTexture"];
			aFrame.tex:SetPoint("TOPLEFT", aFrame);
			aFrame.tex:SetPoint("BOTTOMRIGHT", aFrame);
			
			aFrame.normal_tex = aFrame:GetNormalTexture();
			aFrame.normal_tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
			aFrame.normal_tex:SetBlendMode("ADD")
			aFrame.normal_tex:SetAlpha(0.65)
			aFrame.normal_tex:SetPoint("CENTER", aFrame, "CENTER", 1, 0)
			aFrame.normal_tex:Show()
			
			aFrame:Show();
			
			aFrame.highlight = CreateFrame("Model", name .. "Highlighter", aFrame)
			aFrame.highlight:Hide()
			aFrame.highlight:SetModel("Interface\Buttons\UI-AutoCastButton.mdx")
			aFrame.highlight:SetModelScale(1.2)
			aFrame.highlight:SetAllPoints()
			aFrame.highlight:SetSequence(0)
			aFrame.highlight:SetSequenceTime(0, 0)

			self.altItemFrame = aFrame;
		end
	end);
	return self.altItemFrame;
end

local
function _FBoH_GridItemButton_GetBankItemFrame(self)
	_SafeCall(function()
		if self.bankItemFrame == nil then
			local name = "FBoH_GridBankItemButton_" .. _FBoH_GridBankItemButtonID;
			_FBoH_GridBankItemButtonID = _FBoH_GridBankItemButtonID + 1;
		
			local bFrame = CreateFrame("Button", name, self, "FBoH_BankItemButton");
			bFrame:SetPoint("TOPLEFT");
			bFrame:SetPoint("BOTTOMRIGHT");

			bFrame.tex = _G[name .. "IconTexture"];
			bFrame.tex:SetPoint("TOPLEFT", bFrame);
			bFrame.tex:SetPoint("BOTTOMRIGHT", bFrame);
			
			bFrame.normal_tex = bFrame:GetNormalTexture();
			bFrame.normal_tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
			bFrame.normal_tex:SetBlendMode("ADD")
			bFrame.normal_tex:SetAlpha(0.65)
			bFrame.normal_tex:SetPoint("CENTER", bFrame, "CENTER", 1, 0)
			bFrame.normal_tex:Show()
			
			bFrame:Show();
			
			bFrame.highlight = CreateFrame("Model", name .. "Highlighter", bFrame)
			bFrame.highlight:Hide()
			bFrame.highlight:SetModel("Interface\Buttons\UI-AutoCastButton.mdx")
			bFrame.highlight:SetModelScale(1.2)
			bFrame.highlight:SetAllPoints()
			bFrame.highlight:SetSequence(0)
			bFrame.highlight:SetSequenceTime(0, 0)

			self.bankItemFrame = bFrame;
		end
	end);
	return self.bankItemFrame;
end

local
function _FBoH_GridItemButton_SetBankItem(bFrame, item)
	_SafeCall(function()
		local bagID, slotID = FBoH:GetItemBagAndSlotIDs(item);
		
		bFrame.containerID = bagID;
		bFrame.slotID = slotID;
		bFrame.item = item;

		local itemCount = item.itemCount;
		local quality, texture = item.detail.rarity, item.detail.texture;
		local _, _, locked, _, readable = GetContainerItemInfo(bagID, slotID)

		SetItemButtonTexture(bFrame, texture);
		SetItemButtonCount(bFrame, itemCount);
		SetItemButtonDesaturated(bFrame, locked, 0.5, 0.5, 0.5);
		if texture then
			bFrame.hasItem = 1;
		else
			bFrame.hasItem = nil;
		end
		
--	_FBoH_GridItemButton_SetContainerItem(bFrame, item);
--	local itemFrame = bFrame.itemFrame;
		
		if FBoH:IsBankOpen() then
--		if (quality == nil) or (quality < 0) then quality = 0 end
--		local r = FBoH_QualityColors[quality + 1]
			
--		bFrame.normal_tex:SetVertexColor(r[1], r[2], r[3])
			bFrame.normal_tex:SetVertexColor(1, 1, 0)
			bFrame.tex:SetAlpha(1.0);
		else
			bFrame.normal_tex:SetVertexColor(1, 0, 0);
			bFrame.tex:SetAlpha(0.5);
		end
		
		bFrame.readable = readable
	end);
end

local
function _FBoH_GridItemButton_SetAltItem(aFrame, item)
	_SafeCall(function()
		aFrame.item = item;
		
		local itemCount = item.itemCount;
		local quality, texture = nil, nil;
		if item.detail then
			quality, texture = item.detail.rarity, item.detail.texture;
		end
		if (quality == nil) or (texture == nil) then
			if item.itemLink then
				local _, _, q, _, _, _, _, _, _, t = GetItemInfo(item.itemLink)
				quality = quality or q;
				texture = texture or t;
			else
				quality = 0;
			end
		end

		SetItemButtonTexture(aFrame, texture);
		SetItemButtonCount(aFrame, itemCount);
		aFrame.hasItem = nil;
		
		if (quality == nil) or (quality < 0) then quality = 0 end
		local r, g, b = GetItemQualityColor(quality);

		aFrame.normal_tex:SetVertexColor(r, g, b)
		aFrame.normal_tex:SetAlpha(0.5)
		aFrame.tex:SetAlpha(0.5);
	end);
end

local
function _FBoH_GridItemButton_SetGuildBankItem(bFrame, item)
	_SafeCall(function()
	--	local bagID, slotID = FBoH:GetItemBagAndSlotIDs(item);
		
	--	bFrame.containerID = bagID;
	--	bFrame.slotID = slotID;
		bFrame.item = item;

		local itemCount = item.itemCount;
		local quality, texture = item.detail.rarity, item.detail.texture;
	--	local _, _, locked, _, readable = GetContainerItemInfo(bagID, slotID)

		SetItemButtonTexture(bFrame, texture);
		SetItemButtonCount(bFrame, itemCount);
		SetItemButtonDesaturated(bFrame, locked, 0.5, 0.5, 0.5);
		if texture then
			bFrame.hasItem = 1;
		else
			bFrame.hasItem = nil;
		end
		
	--	_FBoH_GridItemButton_SetContainerItem(bFrame, item);
	--	local itemFrame = bFrame.itemFrame;
		
	--	if FBoH:IsBankOpen() then
	--		if (quality == nil) or (quality < 0) then quality = 0 end
	--		local r = FBoH_QualityColors[quality + 1]
			
	--		bFrame.normal_tex:SetVertexColor(r[1], r[2], r[3])
	--		bFrame.normal_tex:SetVertexColor(1, 1, 0)
	--		bFrame.tex:SetAlpha(1.0);
	--	else
			bFrame.normal_tex:SetVertexColor(1, 0, 0);
			bFrame.tex:SetAlpha(0.5);
	--	end
		
	--	bFrame.readable = readable
	end);
end

local
function _FBoH_GridItemButton_SetContainerItem(cFrame, item)
	_SafeCall(function()
		local bagID, slotID = FBoH:GetItemBagAndSlotIDs(item);
			
		local bagFrame = cFrame.bagFrame;
		local itemFrame = cFrame.itemFrame;
		
		bagFrame:SetID(bagID);
		itemFrame:SetID(slotID);

		local itemCount = item.itemCount;
		local quality, texture = item.detail.rarity, item.detail.texture;
		local _, _, locked, _, readable = GetContainerItemInfo(bagID, slotID)
		
		SetItemButtonTexture(itemFrame, texture)
		SetItemButtonCount(itemFrame, itemCount);
		SetItemButtonDesaturated(itemFrame, locked, 0.5, 0.5, 0.5);
		if ( texture ) then
			itemFrame.hasItem = 1
		else
			itemFrame.hasItem = nil
		end

		if (quality == nil) or (quality < 0) then quality = 0 end
		local r, g, b = GetItemQualityColor(quality);	
	
		itemFrame.normal_tex:SetVertexColor(r, g, b)
		itemFrame.tex:SetAlpha(1.0)

		itemFrame.readable = readable
	end);
end

local
function _FBoH_GridItemButton_SetEmptyItem(eFrame, item)
	_SafeCall(function()
		local bagID, slotID = FBoH:GetItemBagAndSlotIDs(item);
		
		eFrame.containerID = bagID;
		eFrame.slotID = slotID;
		eFrame.item = item;
		eFrame.itemRestrictions = nil;
		
		local itemCount = item.itemCount;
--	local quality, texture = item.detail.quality, item.detail.texture;
--	local _, _, locked, _, readable = GetContainerItemInfo(bagID, slotID)

--	SetItemButtonTexture(bFrame, texture);
		SetItemButtonCount(eFrame, itemCount);
--	SetItemButtonDesaturated(bFrame, locked, 0.5, 0.5, 0.5);
--	if texture then
--		bFrame.hasItem = 1;
--	else
			eFrame.hasItem = nil;
--	end
		
--	_FBoH_GridItemButton_SetContainerItem(bFrame, item);
--	local itemFrame = bFrame.itemFrame;
		
--	if FBoH:IsBankOpen() then
--		if (quality == nil) or (quality < 0) then quality = 0 end
--		local r = FBoH_QualityColors[quality + 1]
			
--		bFrame.normal_tex:SetVertexColor(r[1], r[2], r[3])
--		bFrame.tex:SetAlpha(1.0);
--	else
		if item.restrictionCode == 0 then
			eFrame.normal_tex:SetVertexColor(1, 1, 1);
		else
			eFrame.normal_tex:SetVertexColor(1, 0.8, 0.5);
		end
--		eFrame.tex:SetAlpha(0.5);
--	end
		
--	bFrame.readable = readable
	end);
end

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

function FBoH_BankItemButton_DoClick(self, button)
	_SafeCall(function()
		if FBoH:IsBankOpen() == false then return end;

		if ( button == "LeftButton" ) then
			PickupContainerItem(self.containerID, self.slotID);
		else
			UseContainerItem(self.containerID, self.slotID);
		end	
	end);
end

function FBoH_BankItemButton_DoEnter(self)
	_SafeCall(function()
		local x;
		x = self:GetRight();
		if ( x >= ( GetScreenWidth() / 2 ) ) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		end
		
		GameTooltip:SetHyperlink(self.item.itemLink);
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(L["Item in bank"], 1, 0, 0);
		GameTooltip:Show();
		
		CursorUpdate();	
	end);
end

function FBoH_BankItemButton_DoModifiedClick(self, button)
	_SafeCall(function()
		if FBoH:IsBankOpen() == false then return end;

		if(HandleModifiedItemClick(GetContainerItemLink(self.containerID, self.slotID))) then
			return;
		end
		if(IsModifiedClick("SPLITSTACK")) then
			local texture, itemCount, locked = GetContainerItemInfo(self.containerID, self.slotID);
			if not locked then
				OpenStackSplitFrame(itemCount, self, "BOTTOMLEFT", "TOPLEFT");
			end
			return;
		end
	end);
end
--[[
function FBoH_GuildBankItemButton_DoClick(self, button)
	if FBoH:IsBankOpen() == false then return end;

	if ( button == "LeftButton" ) then
		PickupContainerItem(self.containerID, self.slotID);
	else
		UseContainerItem(self.containerID, self.slotID);
	end	
end
]]
function FBoH_GuildBankItemButton_DoEnter(self)
	_SafeCall(function()
		local x;
		x = self:GetRight();
		if ( x >= ( GetScreenWidth() / 2 ) ) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		end
		
		GameTooltip:SetHyperlink(self.item.itemLink);
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(L["Item in guild bank"], 1, 0, 0);
		GameTooltip:Show();
		
		CursorUpdate();	
	end);
end

function FBoH_GuildBankItemButton_DoModifiedClick(self, button)
	_SafeCall(function()
		HandleModifiedItemClick(self.item.itemLink);
	end);
end

function FBoH_EmptyItemButton_DoEnter(self)
	_SafeCall(function()
		local x;
		x = self:GetRight();
		if ( x >= ( GetScreenWidth() / 2 ) ) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		end

		if self.item.restrictionCode == 0 then
			GameTooltip:SetText(tostring(self.item.itemCount) .. " Empty General Slots (" .. self.item.bagType .. ")");
		else
			GameTooltip:SetText(tostring(self.item.itemCount) .. " Empty Restricted Slots (" .. self.item.bagType .. ")");
			GameTooltip:AddLine(" ");
			
			if self.itemRestrictions == nil then
				local ir = {};

				if bit.band(self.item.restrictionCode, 1) > 0 then table.insert(ir, "Arrows") end;
				if bit.band(self.item.restrictionCode, 2) > 0 then table.insert(ir, "Bullets") end;
				if bit.band(self.item.restrictionCode, 4) > 0 then table.insert(ir, "Soul Shards") end;
				if bit.band(self.item.restrictionCode, 8) > 0 then table.insert(ir, "Leatherworking Supplies") end;
				if bit.band(self.item.restrictionCode, 16) > 0 then table.insert(ir, "Unknown 16") end;
				if bit.band(self.item.restrictionCode, 32) > 0 then table.insert(ir, "Herbs") end;
				if bit.band(self.item.restrictionCode, 64) > 0 then table.insert(ir, "Enchanting Supplies") end;
				if bit.band(self.item.restrictionCode, 128) > 0 then table.insert(ir, "Engineering Supplies") end;
				if bit.band(self.item.restrictionCode, 256) > 0 then table.insert(ir, "Keyring") end;
				if bit.band(self.item.restrictionCode, 512) > 0 then table.insert(ir, "Gems") end;
				if bit.band(self.item.restrictionCode, 1024) > 0 then table.insert(ir, "Mining Supplies") end;
				if bit.band(self.item.restrictionCode, 2048) > 0 then table.insert(ir, "Unknown 2048") end;
				if bit.band(self.item.restrictionCode, 4096) > 0 then table.insert(ir, "Vanity Pets") end;		
				if bit.band(self.item.restrictionCode, 4096) > 0 then table.insert(ir, "Vanity Pets") end;		

				self.itemRestrictions = ir;
			end
			
			for _, v in ipairs(self.itemRestrictions) do
				GameTooltip:AddLine(v, 1, 0, 0);
			end
		end
		
		GameTooltip:Show();
		
		CursorUpdate();	
	end);
end

function FBoH_EmptyItemButton_DoClick(self, button)
	_SafeCall(function()
		PickupContainerItem(self.containerID, self.slotID);
	end);
end

--[[
function FBoH_ItemButtonTemplate_OnClick(btn, button)
	_SafeCall(function()
		if ( button == "LeftButton" ) then
			if ( not IsModifierKeyDown() ) then
				if ( SpellCanTargetItem() ) then
					-- Target the spell with the selected item
					UseContainerItem(btn.fbohBagID, btn.fbohSlotID);
				else
					PickupContainerItem(btn.fbohBagID, btn.fbohSlotID);
				end
				StackSplitFrame:Hide();
			end
		else
			if ( MerchantFrame:IsShown() and MerchantFrame.selectedTab == 2 ) then
				-- Don't sell the item if the buyback tab is selected
				return;
			end
			if ( MerchantFrame:IsShown() and IsShiftKeyDown() ) then
				this.SplitStack = function(button, split)
					SplitContainerItem(button.fbohBagID, button.fbohSlotID, split);
					MerchantItemButton_OnClick("LeftButton");
				end
				OpenStackSplitFrame(this.count, this, "BOTTOMRIGHT", "TOPRIGHT");
			else
				-- Shift-click is used for auto-looting and socketing
				UseContainerItem(btn.fbohBagID, btn.fbohSlotID);
				StackSplitFrame:Hide();
			end
		end
	end);
end
--]]
--[[
function FBoH_ItemButtonTemplate_OnEnter(button)
	_SafeCall(function()
		local x;
		x = button:GetRight();
		if ( x >= ( GetScreenWidth() / 2 ) ) then
			GameTooltip:SetOwner(button, "ANCHOR_LEFT");
		else
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
		end

		-- Keyring specific code
		if ( button.fbohBagID == KEYRING_CONTAINER ) then
			GameTooltip:SetInventoryItem("player", KeyRingButtonIDToInvSlotID(button:GetID()));
			CursorUpdate();
			return;
		end

		local hasCooldown, repairCost = GameTooltip:SetBagItem(button.fbohBagID, button.fbohSlotID);
		if ( IsShiftKeyDown() ) then
			GameTooltip_ShowCompareItem();
		end

		if ( hasCooldown ) then
			button.updateTooltip = TOOLTIP_UPDATE_TIME;
		else
			button.updateTooltip = nil;
		end

		if ( InRepairMode() and (repairCost and repairCost > 0) ) then
			GameTooltip:AddLine(REPAIR_COST, "", 1, 1, 1);
			SetTooltipMoney(GameTooltip, repairCost);
			GameTooltip:Show();
		elseif ( IsControlKeyDown() and button.hasItem ) then
			ShowInspectCursor();
		elseif ( MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1 ) then
			ShowContainerSellCursor(button.fbohBagID, button.fbohSlotID);
		elseif ( button.readable ) then
			ShowInspectCursor();
		else
			ResetCursor();
		end
	end);
end
--]]
--[[
function FBoH_ItemButtonTemplate_OnModifiedClick(btn, button)
	_SafeCall(function()
		if ( button == "LeftButton" ) then
			if ( IsControlKeyDown() ) then
				DressUpItemLink(GetContainerItemLink(btn.fbohBagID, btn.fbohSlotID));
			elseif ( IsShiftKeyDown() ) then
				if ( not ChatEdit_InsertLink(GetContainerItemLink(btn.fbohBagID, btn.fbohSlotID)) ) then
					local texture, itemCount, locked = GetContainerItemInfo(btn.fbohBagID, btn.fbohSlotID);
					if ( not locked ) then
						this.SplitStack = function(button, split)
							SplitContainerItem(btn.fbohBagID, btn.fbohSlotID, split);
						end
						OpenStackSplitFrame(this.count, this, "BOTTOMRIGHT", "TOPRIGHT");
					end
				end
			end
		end
	end);
end
--]]
--[[
function FBoH_ItemButtonTemplate_OnUpdate(btn, elapsed)
	_SafeCall(function()
		if ( this.updateTooltip ) then
			this.updateTooltip = this.updateTooltip - elapsed;
			if ( this.updateTooltip > 0 ) then
				return;
			end
		end

		if ( GameTooltip:IsOwned(this) ) then
			btn:DoEnter();
		end
	end);
end
--]]
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

function FBoH_GridItemButton_GetGuildBankItemFrame(self)
	_SafeCall(function()
		if self.guildBankItemFrame == nil then
			local name = "FBoH_GridGuildBankItemButton_" .. _FBoH_GridGuildBankItemButtonID;
			_FBoH_GridGuildBankItemButtonID = _FBoH_GridGuildBankItemButtonID + 1;
		
			local bFrame = CreateFrame("Button", name, self, "FBoH_GuildBankItemButton");
			bFrame:SetPoint("TOPLEFT");
			bFrame:SetPoint("BOTTOMRIGHT");

			bFrame.tex = _G[name .. "IconTexture"];
			bFrame.tex:SetPoint("TOPLEFT", bFrame);
			bFrame.tex:SetPoint("BOTTOMRIGHT", bFrame);
			
			bFrame.normal_tex = bFrame:GetNormalTexture();
			bFrame.normal_tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
			bFrame.normal_tex:SetBlendMode("ADD")
			bFrame.normal_tex:SetAlpha(0.65)
			bFrame.normal_tex:SetPoint("CENTER", bFrame, "CENTER", 1, 0)
			bFrame.normal_tex:Show()
			
			bFrame:Show();
			
			bFrame.highlight = CreateFrame("Model", name .. "Highlighter", bFrame)
			bFrame.highlight:Hide()
			bFrame.highlight:SetModel("Interface\Buttons\UI-AutoCastButton.mdx")
			bFrame.highlight:SetModelScale(1.2)
			bFrame.highlight:SetAllPoints()
			bFrame.highlight:SetSequence(0)
			bFrame.highlight:SetSequenceTime(0, 0)

			self.guildBankItemFrame = bFrame;
		end
	end);
	return self.guildBankItemFrame;
end

function FBoH_GridItemButton_GetContainerItemFrame(self)
	_SafeCall(function()
		if self.containerItemFrame == nil then
			local name = "FBoH_GridContainerItemButton_" .. _FBoH_GridContainerItemButtonID;
			_FBoH_GridContainerItemButtonID = _FBoH_GridContainerItemButtonID + 1;
		
			local cFrame = CreateFrame("Button", name, self);
			cFrame:SetPoint("TOPLEFT", self, "TOPLEFT");
			cFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT");
			
			cFrame.bagFrame = CreateFrame("Button", name, cFrame);
			cFrame.bagFrame:SetPoint("TOPLEFT", cFrame, "TOPLEFT");
			cFrame.bagFrame:SetPoint("BOTTOMRIGHT", cFrame, "BOTTOMRIGHT");
			
			cFrame.itemFrame = CreateFrame("Button", name, cFrame.bagFrame, "ContainerFrameItemButtonTemplate");
			cFrame.itemFrame:SetPoint("TOPLEFT", cFrame.bagFrame, "TOPLEFT");
			cFrame.itemFrame:SetPoint("BOTTOMRIGHT", cFrame.bagFrame, "BOTTOMRIGHT");
			
			cFrame.itemFrame.tex = _G[name .. "IconTexture"]
			cFrame.itemFrame.tex:SetPoint("TOPLEFT", cFrame.itemFrame, "TOPLEFT")
			cFrame.itemFrame.tex:SetPoint("BOTTOMRIGHT", cFrame.itemFrame, "BOTTOMRIGHT")
			
			cFrame.itemFrame.normal_tex = cFrame.itemFrame:GetNormalTexture()
			cFrame.itemFrame.normal_tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
			cFrame.itemFrame.normal_tex:SetBlendMode("ADD")
			cFrame.itemFrame.normal_tex:SetAlpha(0.65)
			cFrame.itemFrame.normal_tex:SetPoint("CENTER", cFrame.itemFrame, "CENTER", 1, 0)
			cFrame.itemFrame.normal_tex:Show()

			cFrame.itemFrame:Show()
			
			cFrame.highlight = CreateFrame("Model", name .. "Highlighter", cFrame)
			cFrame.highlight:Hide()
			cFrame.highlight:SetModel("Interface\Buttons\UI-AutoCastButton.mdx")
			cFrame.highlight:SetModelScale(1.2)
			cFrame.highlight:SetAllPoints()
			cFrame.highlight:SetSequence(0)
			cFrame.highlight:SetSequenceTime(0, 0)
			
			self.containerItemFrame = cFrame;
		end
	end);
	return self.containerItemFrame;
end

function FBoH_GridItemButton_GetEmptyItemFrame(self)
	_SafeCall(function()
		if self.emptyItemFrame == nil then
			local name = "FBoH_GridEmptyItemButton_" .. _FBoH_GridEmptyItemButtonID;
			_FBoH_GridEmptyItemButtonID = _FBoH_GridEmptyItemButtonID + 1;
		
			local eFrame = CreateFrame("Button", name, self, "FBoH_EmptyItemButton");
			eFrame:SetPoint("TOPLEFT");
			eFrame:SetPoint("BOTTOMRIGHT");

			eFrame.tex = _G[name .. "IconTexture"];
			eFrame.tex:SetPoint("TOPLEFT", eFrame);
			eFrame.tex:SetPoint("BOTTOMRIGHT", eFrame);
			
			eFrame.normal_tex = eFrame:GetNormalTexture();
			eFrame.normal_tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
			eFrame.normal_tex:SetBlendMode("ADD")
			eFrame.normal_tex:SetAlpha(0.65)
			eFrame.normal_tex:SetPoint("CENTER", eFrame, "CENTER", 1, 0)
			eFrame.normal_tex:Show()
			
			eFrame:Show();
			
			eFrame.highlight = CreateFrame("Model", name .. "Highlighter", eFrame)
			eFrame.highlight:Hide()
			eFrame.highlight:SetModel("Interface\Buttons\UI-AutoCastButton.mdx")
			eFrame.highlight:SetModelScale(1.2)
			eFrame.highlight:SetAllPoints()
			eFrame.highlight:SetSequence(0)
			eFrame.highlight:SetSequenceTime(0, 0)

			self.emptyItemFrame = eFrame;
		end
	end);
	return self.emptyItemFrame;
end

function FBoH_GridItemButton_HideChildren(self)
	_SafeCall(function()
		local children = { self:GetChildren() };
		for _, v in pairs(children) do
			v:Hide();
		end
	end);
end

function FBoH_GridItemButton_SetItem(self, item)
	_SafeCall(function()
		self:HideChildren();

		local chr = UnitName("player");
		local rlm = GetRealmName();
		
		if item then
			if item.isEmpty == true then
				local eFrame = self:GetEmptyItemFrame();
				if eFrame == nil then return end;
				
				_FBoH_GridItemButton_SetEmptyItem(eFrame, item);
				
				eFrame:Show();
			elseif (chr ~= item.character) or (rlm ~= item.realm) then
				local aFrame = _FBoH_GridItemButton_GetAltItemFrame(self);
				if aFrame == nil then return end;
				
				_FBoH_GridItemButton_SetAltItem(aFrame, item);
				
				aFrame:Show();
			elseif item.bagType == "Bags" or item.bagType == "Keyring" then
				local cFrame = self:GetContainerItemFrame();
				if cFrame == nil then return end;
			
				_FBoH_GridItemButton_SetContainerItem(cFrame, item);
							
				cFrame:Show();
			elseif item.bagType == "Bank" then
				local bFrame = _FBoH_GridItemButton_GetBankItemFrame(self);
				if bFrame == nil then return end;
				
				_FBoH_GridItemButton_SetBankItem(bFrame, item);
				
				bFrame:Show();
			elseif item.bagType == "Guild Bank" then
				local bFrame = self:GetGuildBankItemFrame();
				if bFrame == nil then return end;
				
				_FBoH_GridItemButton_SetGuildBankItem(bFrame, item);
				
				bFrame:Show();
			end
		end
	end);
end

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------


