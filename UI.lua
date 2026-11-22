local addonName, ns = ...
local L = ns.L or {}

local buttonFrame = nil
local tooltipOwner = nil

-------------------------------------------------------------------------------
-- WorldMap Button Creation & Updating
-------------------------------------------------------------------------------
local function UpdateButtonVisuals()
    if not buttonFrame then return end

    local isHideMap = ns:IsHideAllMapActive()
    local isWorldMapOn = ns:IsWorldMapFilterActive()

    if isHideMap then
        -- Hide All Pins mode: reddish tinted spyglass to indicate clean map state
        if buttonFrame.icon.SetDesaturated then
            buttonFrame.icon:SetDesaturated(false)
        end
        buttonFrame.icon:SetVertexColor(1.0, 0.35, 0.35)
    elseif isWorldMapOn then
        -- Active state: original natural colors (no tint)
        if buttonFrame.icon.SetDesaturated then
            buttonFrame.icon:SetDesaturated(false)
        end
        buttonFrame.icon:SetVertexColor(1.0, 1.0, 1.0)
    else
        -- Inactive state: dimmed and desaturated
        if buttonFrame.icon.SetDesaturated then
            buttonFrame.icon:SetDesaturated(true)
        end
        buttonFrame.icon:SetVertexColor(0.45, 0.45, 0.45)
    end

    -- If the tooltip is currently open for this button, refresh it live
    if tooltipOwner == buttonFrame and GameTooltip:IsOwned(buttonFrame) then
        local onEnter = buttonFrame:GetScript("OnEnter")
        if onEnter then onEnter(buttonFrame) end
    end
end

local lastAnchorPeer = nil
local lastTargetLevel = nil

local function AnchorButton()
    if not buttonFrame or not WorldMapFrame then return end

    local peer = _G.GatherLiteWorldmapButton
    local viewport = WorldMapFrame.ScrollContainer or WorldMapFrame

    -- Always keep high strata and level above map canvas and scroll container
    local targetLevel = 9250
    if viewport and viewport.GetFrameLevel then
        targetLevel = math.min(viewport:GetFrameLevel() + 9005, 9250)
    end
    if lastTargetLevel ~= targetLevel then
        lastTargetLevel = targetLevel
        buttonFrame:SetFrameStrata("HIGH")
        buttonFrame:SetFrameLevel(targetLevel)
    end

    local currentAnchor = (peer and (peer:IsShown() or peer:GetLeft())) and peer or viewport
    if lastAnchorPeer ~= currentAnchor then
        lastAnchorPeer = currentAnchor
        buttonFrame:ClearAllPoints()
        if currentAnchor == peer then
            buttonFrame:SetPoint("LEFT", peer, "RIGHT", 4, 0)
        elseif viewport then
            buttonFrame:SetPoint("TOPLEFT", viewport, "TOPLEFT", 38, -32)
        end
    end

    if WorldMapFrame:IsShown() and not buttonFrame:IsShown() then
        buttonFrame:Show()
    end
end

function ns:CreateWorldMapButton()
    if buttonFrame then return buttonFrame end
    if not WorldMapFrame then return end

    local button = CreateFrame("Button", "GatherLiteSelectedOnlyButton", WorldMapFrame)
    buttonFrame = button

    button:SetSize(32, 32)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(9250)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetHighlightTexture(136477) -- "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"

    -- Background texture
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetTexture(136467) -- "Interface\\Minimap\\UI-Minimap-Background"
    bg:SetPoint("TOPLEFT", 7, -5)
    button.bg = bg

    -- Main Icon (natural spyglass)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetTexture("Interface\\Icons\\inv_misc_spyglass_03")
    icon:SetPoint("TOPLEFT", 7, -6)
    button.icon = icon

    -- Tracking border frame
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture(136430) -- "Interface\\Minimap\\MiniMap-TrackingBorder"
    border:SetPoint("TOPLEFT", 0, 0)
    button.border = border

    -- Scripts: Left/Right Click + Shift-Click Toggle
    button:SetScript("OnClick", function(self, btn)
        local isShift = IsShiftKeyDown and IsShiftKeyDown()

        if isShift then
            if btn == "LeftButton" then
                local isHide = ns:ToggleHideAllMap()
                local msg = isHide and ("|cFFFF3333" .. L.STATUS_ALL_HIDDEN .. "|r") or ("|cFF00FF00" .. L.STATUS_RESTORED .. "|r")
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.STATUS_MAP .. " " .. msg)
            elseif btn == "RightButton" then
                local isHide = ns:ToggleHideAllMini()
                local msg = isHide and ("|cFFFF3333" .. L.STATUS_ALL_HIDDEN .. "|r") or ("|cFF00FF00" .. L.STATUS_RESTORED .. "|r")
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.STATUS_MINI .. " " .. msg)
            end
        else
            if btn == "LeftButton" then
                local newState = ns:ToggleWorldMapFilter()
                local msg = newState and ("|cFF00FF00" .. L.STATUS_ACTIVE .. "|r") or ("|cFFFF3333" .. L.STATUS_DISABLED .. "|r")
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.STATUS_MAP .. " " .. msg)
            elseif btn == "RightButton" then
                local newState = ns:ToggleMinimapFilter()
                local msg = newState and ("|cFF00FF00" .. L.STATUS_ACTIVE .. "|r") or ("|cFFFF3333" .. L.STATUS_DISABLED .. "|r")
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.STATUS_MINI .. " " .. msg)
            end
        end
        UpdateButtonVisuals()
    end)

    button:SetScript("OnEnter", function(self)
        tooltipOwner = self
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cFFFFD100" .. L.TITLE .. "|r")

        local isMapOn = ns:IsWorldMapFilterActive()
        local isMiniOn = ns:IsMinimapFilterActive()
        local isHideMap = ns:IsHideAllMapActive()
        local isHideMini = ns:IsHideAllMiniActive()

        if isHideMap then
            GameTooltip:AddDoubleLine(L.STATUS_MAP, "|cFFFF3333" .. L.STATUS_ALL_HIDDEN .. "|r")
        else
            GameTooltip:AddDoubleLine(L.STATUS_MAP, isMapOn and ("|cFF00FF00" .. L.FILTER_ACTIVE .. "|r") or ("|cFFFF3333" .. L.FILTER_NORMAL .. "|r"))
        end

        if isHideMini then
            GameTooltip:AddDoubleLine(L.STATUS_MINI, "|cFFFF3333" .. L.STATUS_ALL_HIDDEN .. "|r")
        else
            GameTooltip:AddDoubleLine(L.STATUS_MINI, isMiniOn and ("|cFF00FF00" .. L.FILTER_ACTIVE .. "|r") or ("|cFFFF3333" .. L.FILTER_NORMAL .. "|r"))
        end
        GameTooltip:AddLine(" ")

        local allowed, count, names = ns:GetAllowedObjectIDs()
        if isHideMap then
            GameTooltip:AddLine("|cFFFF3333" .. L.HIDE_ALL_TOOLTIP .. "|r")
            GameTooltip:AddLine(L.HIDE_ALL_RESTORE_HINT, 0.8, 0.8, 0.8, true)
        elseif count > 0 then
            GameTooltip:AddLine(string.format("|cFF00FF00" .. L.RESOURCES_DETECTED .. "|r", #names > 0 and #names or count))
            local maxNames = 8
            for i = 1, math.min(#names, maxNames) do
                GameTooltip:AddLine(" • " .. names[i], 1, 1, 1)
            end
            if #names > maxNames then
                GameTooltip:AddLine(string.format(" |cFF888888" .. L.AND_MORE .. "|r", #names - maxNames))
            end
        else
            if isMapOn or isMiniOn then
                GameTooltip:AddLine("|cFFFF9900" .. L.NO_SELECTION_ACTIVE .. "|r")
                GameTooltip:AddLine(L.NO_SELECTION_DESC, 0.8, 0.8, 0.8, true)
            else
                GameTooltip:AddLine("|cFF888888" .. L.NO_SELECTION_NONE .. "|r")
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFFFFD100" .. L.TOOLTIP_LEFT .. "|r " .. L.TOOLTIP_LEFT_DESC, 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cFFFFD100" .. L.TOOLTIP_RIGHT .. "|r " .. L.TOOLTIP_RIGHT_DESC, 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cFFFF8800" .. L.TOOLTIP_SHIFT_LEFT .. "|r " .. L.TOOLTIP_SHIFT_LEFT_DESC, 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cFFFF8800" .. L.TOOLTIP_SHIFT_RIGHT .. "|r " .. L.TOOLTIP_SHIFT_RIGHT_DESC, 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        if tooltipOwner == self then
            tooltipOwner = nil
        end
        GameTooltip:Hide()
    end)

    button:SetScript("OnShow", function(self)
        AnchorButton()
        UpdateButtonVisuals()
    end)

    -- Hook WorldMapFrame OnShow to ensure re-anchoring when the map opens
    WorldMapFrame:HookScript("OnShow", function()
        AnchorButton()
        UpdateButtonVisuals()
    end)

    AnchorButton()
    UpdateButtonVisuals()
    button:Show()

    return button
end

-- Continuous monitor frame on UIParent that ensures anchor tracking even if GatherLite shifts its button
local monitorFrame = CreateFrame("Frame", "GatherLiteSelectedOnlyMonitor", UIParent)
local elapsed = 0
monitorFrame:SetScript("OnUpdate", function(self, delta)
    if WorldMapFrame and WorldMapFrame:IsVisible() then
        elapsed = elapsed + delta
        if elapsed >= 0.5 then
            elapsed = 0
            if not InCombatLockdown() then
                AnchorButton()
            end
        end
    end
end)

function ns:UpdateUI()
    UpdateButtonVisuals()
end

-------------------------------------------------------------------------------
-- Slash Commands (/glonly) & Diagnostic Audit
-------------------------------------------------------------------------------
SLASH_GATHERLITE_SELECTEDONLY1 = "/glonly"
SLASH_GATHERLITE_SELECTEDONLY2 = "/glselectedonly"

SlashCmdList["GATHERLITE_SELECTEDONLY"] = function(msg)
    local text = msg or ""
    local cmd = (strtrim and strtrim(text) or (string.trim and string.trim(text)) or text:match("^%s*(.-)%s*$")):lower()

    if cmd == "minimap" or cmd == "mini" then
        local newState = ns:ToggleMinimapFilter()
        local stateText = newState and ("|cFF00FF00" .. L.STATUS_ACTIVE .. "|r") or ("|cFFFF3333" .. L.STATUS_DISABLED .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.STATUS_MINI .. " " .. stateText)

    elseif cmd == "map" or cmd == "world" or cmd == "mapa" then
        local newState = ns:ToggleWorldMapFilter()
        local stateText = newState and ("|cFF00FF00" .. L.STATUS_ACTIVE .. "|r") or ("|cFFFF3333" .. L.STATUS_DISABLED .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.STATUS_MAP .. " " .. stateText)

    elseif cmd == "hideall" or cmd == "hide" or cmd == "clear" or cmd == "ocultar" or cmd == "limpiar" then
        local isHide = ns:ToggleHideAllMap()
        local stateText = isHide and ("|cFFFF3333" .. L.STATUS_ALL_HIDDEN .. "|r") or ("|cFF00FF00" .. L.STATUS_RESTORED .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.STATUS_MAP .. " " .. stateText)

    elseif cmd == "hideall mini" or cmd == "hide mini" or cmd == "clear mini" or cmd == "ocultar mini" or cmd == "limpiar mini" then
        local isHide = ns:ToggleHideAllMini()
        local stateText = isHide and ("|cFFFF3333" .. L.STATUS_ALL_HIDDEN .. "|r") or ("|cFF00FF00" .. L.STATUS_RESTORED .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.STATUS_MINI .. " " .. stateText)

    elseif cmd == "status" or cmd == "estado" then
        local mapState = ns:IsHideAllMapActive() and ("|cFFFF3333" .. L.STATUS_ALL_HIDDEN .. "|r")
            or (ns:IsWorldMapFilterActive() and ("|cFF00FF00" .. L.FILTER_ACTIVE .. "|r") or ("|cFFFF8800" .. L.FILTER_NORMAL .. "|r"))
        local miniState = ns:IsHideAllMiniActive() and ("|cFFFF3333" .. L.STATUS_ALL_HIDDEN .. "|r")
            or (ns:IsMinimapFilterActive() and ("|cFF00FF00" .. L.FILTER_ACTIVE .. "|r") or ("|cFFFF8800" .. L.FILTER_NORMAL .. "|r"))
        local allowed, count, names = ns:GetAllowedObjectIDs()

        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.CMD_AUDIT_HEADER)
        DEFAULT_CHAT_FRAME:AddMessage(" • " .. L.STATUS_MAP .. " " .. mapState)
        DEFAULT_CHAT_FRAME:AddMessage(" • " .. L.STATUS_MINI .. " " .. miniState)
        DEFAULT_CHAT_FRAME:AddMessage(" • " .. L.CMD_ALLOWED_IDS .. tostring(count))

        if #names > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(" • " .. L.CMD_SELECTED_RESOURCES, #names) .. "|cFF00FF00" .. table.concat(names, ", ") .. "|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage(string.format(" • " .. L.CMD_SELECTED_RESOURCES, 0) .. "|cFFFF8800" .. L.CMD_NONE .. "|r")
        end

        local peer = _G.GatherLiteWorldmapButton
        if peer then
            local pShown = peer:IsShown() and ("|cFF00FF00" .. L.CMD_VISIBLE .. "|r") or ("|cFFFF8800" .. L.CMD_HIDDEN .. "|r")
            local pLeft = peer:GetLeft() and string.format("%.1f", peer:GetLeft()) or "nil"
            local pTop = peer:GetTop() and string.format("%.1f", peer:GetTop()) or "nil"
            DEFAULT_CHAT_FRAME:AddMessage(" • " .. L.CMD_ANCHOR_PEER .. pShown .. " (Pos: " .. pLeft .. ", " .. pTop .. ")")
        else
            DEFAULT_CHAT_FRAME:AddMessage(" • " .. L.CMD_ANCHOR_PEER .. "|cFFFF3333" .. L.CMD_NOT_FOUND .. "|r")
        end

        if buttonFrame then
            local bShown = buttonFrame:IsShown() and ("|cFF00FF00" .. L.CMD_VISIBLE .. "|r") or ("|cFFFF8800" .. L.CMD_HIDDEN .. "|r")
            local bLeft = buttonFrame:GetLeft() and string.format("%.1f", buttonFrame:GetLeft()) or "nil"
            local bTop = buttonFrame:GetTop() and string.format("%.1f", buttonFrame:GetTop()) or "nil"
            DEFAULT_CHAT_FRAME:AddMessage(" • " .. L.CMD_BUTTON_STATE .. bShown .. " (Pos: " .. bLeft .. ", " .. bTop .. ")")
        end

    elseif cmd == "reset" or cmd == "reiniciar" then
        ns:InvalidateCache()
        if _G.GatherLite and type(GatherLite.Trigger) == "function" then
            GatherLite:Trigger("settings:update")
        end
        AnchorButton()
        UpdateButtonVisuals()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.CMD_CACHE_RESET)

    elseif cmd == "help" or cmd == "ayuda" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.CMD_HELP_HEADER)
        DEFAULT_CHAT_FRAME:AddMessage(" " .. L.CMD_HELP_MAIN)
        DEFAULT_CHAT_FRAME:AddMessage(" " .. L.CMD_HELP_MINI)
        DEFAULT_CHAT_FRAME:AddMessage(" " .. L.CMD_HELP_HIDE)
        DEFAULT_CHAT_FRAME:AddMessage(" " .. L.CMD_HELP_HIDE_MINI)
        DEFAULT_CHAT_FRAME:AddMessage(" " .. L.CMD_HELP_STATUS)
        DEFAULT_CHAT_FRAME:AddMessage(" " .. L.CMD_HELP_RESET)
    else
        -- Default: toggle world map
        local newState = ns:ToggleWorldMapFilter()
        local stateText = newState and ("|cFF00FF00" .. L.STATUS_ACTIVE .. "|r") or ("|cFFFF3333" .. L.STATUS_DISABLED .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[GatherLite_SelectedOnly]|r " .. L.STATUS_MAP .. " " .. stateText)
    end

    UpdateButtonVisuals()
end
