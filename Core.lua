local addonName, ns = ...

-- Expose internal namespace table for modularity
_G[addonName] = ns

-- Persistent configuration defaults
local defaultDB = {
    enabled = false,       -- WorldMap filtering toggle (solo seleccionados)
    filterMinimap = false, -- Minimap filtering toggle (solo seleccionados)
    hideAllMap = false,    -- WorldMap: hide all pins
    hideAllMini = false,   -- Minimap: hide all pins
}

-- Runtime state and caches
local isInitialized = false
local isRefreshing = false
local inOpenMapRefill = false
local cachedAllowedIDs = nil
local cachedResourceNames = nil
local cachedSelectionCount = 0

-------------------------------------------------------------------------------
-- Database & Initialization
-------------------------------------------------------------------------------
local function InitDB()
    if not GatherLiteSelectedOnlyDB then
        GatherLiteSelectedOnlyDB = {}
    end
    for k, v in pairs(defaultDB) do
        if GatherLiteSelectedOnlyDB[k] == nil then
            GatherLiteSelectedOnlyDB[k] = v
        end
    end
    ns.db = GatherLiteSelectedOnlyDB
end

-------------------------------------------------------------------------------
-- Cache Invalidation & Safe Refresh
-------------------------------------------------------------------------------
function ns:InvalidateCache()
    cachedAllowedIDs = nil
    cachedResourceNames = nil
    cachedSelectionCount = 0
end

-- Refresh with recursion guard & next-tick deferral (Adjustment #2)
function ns:TriggerRefresh()
    if isRefreshing then return end
    isRefreshing = true

    C_Timer.After(0, function()
        isRefreshing = false
        ns:InvalidateCache()

        if _G.GatherLite and type(GatherLite.Trigger) == "function" then
            GatherLite:Trigger("settings:update")
        end

        local fishing = _G.GatherLite and _G.GatherLite.plugins and _G.GatherLite.plugins.Fishing
        if fishing and type(fishing.Refresh) == "function" then
            fishing:Refresh()
        end

        if ns.UpdateUI then
            ns:UpdateUI()
        end
    end)
end

-------------------------------------------------------------------------------
-- Active Selection & Allowed Objects Detection
-------------------------------------------------------------------------------
local function GetResourceDisplayName(obj)
    if not obj or type(obj) ~= "table" then return nil end
    if obj.type == "fish" or obj.objects then
        return obj.name
    end
    if obj.name then
        if _G.GatherLite and type(GatherLite.translate) == "function" then
            local ok, tr = pcall(GatherLite.translate, GatherLite, "node." .. tostring(obj.name))
            if ok and tr and tr ~= ("node." .. tostring(obj.name)) then
                return tr
            end
        end
        return obj.name
    end
    return nil
end

local function CollectObjectIDs(obj, targetTable, seenNames)
    if not obj or type(obj) ~= "table" then return end

    -- If this is a composite/combined selection (e.g. created by Routes:Combine),
    -- expand each child resource object directly and avoid treating the container as a node.
    if type(obj.objects) == "table" then
        for i = 1, #obj.objects do
            CollectObjectIDs(obj.objects[i], targetTable, seenNames)
        end
        return
    end

    -- Extract translated/display name safely for individual resource
    local name = GetResourceDisplayName(obj)
    if name and seenNames and not seenNames[name] then
        seenNames[name] = true
        table.insert(cachedResourceNames, name)
    end

    -- Direct array of IDs (standard GatherLite object structure)
    if type(obj.id) == "table" then
        for i = 1, #obj.id do
            local id = obj.id[i]
            if type(id) == "number" then
                targetTable[id] = true
            end
        end
    elseif type(obj.id) == "number" then
        targetTable[obj.id] = true
    end

    -- Item ID (e.g. fish catches)
    if type(obj.itemID) == "number" then
        targetTable[obj.itemID] = true
    end
end

function ns:GetAllowedObjectIDs()
    if cachedAllowedIDs then
        return cachedAllowedIDs, cachedSelectionCount, cachedResourceNames
    end

    local allowed = {}
    local seenNames = {}
    cachedResourceNames = {}

    local GL = _G.GatherLite
    if not GL then
        cachedAllowedIDs = allowed
        cachedSelectionCount = 0
        return allowed, 0, cachedResourceNames
    end

    -- 1. Check WorldMap Sidebar selection
    local sidebar = GL.modules and GL.modules.worldMapSidebar
    if sidebar then
        local selection = nil
        if type(sidebar.GetSelection) == "function" then
            local ok, res = pcall(sidebar.GetSelection, sidebar)
            if ok and type(res) == "table" then
                selection = res
            end
        end
        if not selection and type(sidebar.selection) == "table" then
            selection = sidebar.selection
        end

        if type(selection) == "table" then
            for _, obj in ipairs(selection) do
                CollectObjectIDs(obj, allowed, seenNames)
            end
        end
    end

    -- 2. Check Routes plugin (active route & route object)
    local routes = GL.plugins and GL.plugins.Routes
    if routes then
        if routes.object then
            CollectObjectIDs(routes.object, allowed, seenNames)
        end
        if routes.active and type(routes.active.points) == "table" then
            for i = 1, #routes.active.points do
                local pt = routes.active.points[i]
                if pt and type(pt.object) == "number" then
                    allowed[pt.object] = true
                end
            end
        end
    end

    -- 3. Check Fishing plugin (selected fish catches)
    local fishing = GL.plugins and GL.plugins.Fishing
    if fishing and fishing.object then
        CollectObjectIDs(fishing.object, allowed, seenNames)
    end

    -- 4. Check captured object from Standalone /gather window
    if ns.capturedWindowObject then
        CollectObjectIDs(ns.capturedWindowObject, allowed, seenNames)
    end

    -- 5. Fallback: SavedVariables from character session (active/saved route)
    if GL.db and GL.db.char then
        if type(GL.db.char.routeObjects) == "table" then
            for _, id in ipairs(GL.db.char.routeObjects) do
                if type(id) == "number" then
                    allowed[id] = true
                    if seenNames and type(GL.GetNodeObject) == "function" then
                        local nodeObj = GL:GetNodeObject(id)
                        local name = GetResourceDisplayName(nodeObj)
                        if name and not seenNames[name] then
                            seenNames[name] = true
                            table.insert(cachedResourceNames, name)
                        end
                    end
                end
            end
        end
        if type(GL.db.char.routeObject) == "number" then
            local id = GL.db.char.routeObject
            allowed[id] = true
            if seenNames and type(GL.GetNodeObject) == "function" then
                local nodeObj = GL:GetNodeObject(id)
                local name = GetResourceDisplayName(nodeObj)
                if name and not seenNames[name] then
                    seenNames[name] = true
                    table.insert(cachedResourceNames, name)
                end
            end
        end
        if type(GL.db.char.fishItem) == "number" then
            allowed[GL.db.char.fishItem] = true
        end
    end

    -- Count total unique allowed object IDs
    local count = 0
    for _ in pairs(allowed) do
        count = count + 1
    end

    cachedAllowedIDs = allowed
    cachedSelectionCount = count

    return allowed, count, cachedResourceNames
end

function ns:HasActiveSelection()
    local _, count = ns:GetAllowedObjectIDs()
    return count > 0
end

-------------------------------------------------------------------------------
-- Filter State Accessors & Toggles
-------------------------------------------------------------------------------
function ns:IsWorldMapFilterActive()
    return ns.db and ns.db.enabled == true
end

function ns:IsMinimapFilterActive()
    return ns.db and ns.db.filterMinimap == true
end

function ns:IsHideAllMapActive()
    return ns.db and ns.db.hideAllMap == true
end

function ns:IsHideAllMiniActive()
    return ns.db and ns.db.hideAllMini == true
end

function ns:ToggleWorldMapFilter()
    if not ns.db then return end
    ns.db.enabled = not ns.db.enabled
    ns:TriggerRefresh()
    return ns.db.enabled
end

function ns:ToggleMinimapFilter()
    if not ns.db then return end
    ns.db.filterMinimap = not ns.db.filterMinimap
    ns:TriggerRefresh()
    return ns.db.filterMinimap
end

function ns:ToggleHideAllMap()
    if not ns.db then return end
    ns.db.hideAllMap = not ns.db.hideAllMap
    ns:TriggerRefresh()
    return ns.db.hideAllMap
end

function ns:ToggleHideAllMini()
    if not ns.db then return end
    ns.db.hideAllMini = not ns.db.hideAllMini
    ns:TriggerRefresh()
    return ns.db.hideAllMini
end

-------------------------------------------------------------------------------
-- Hooks Implementation
-------------------------------------------------------------------------------
local function SetupHooks()
    local GL = _G.GatherLite
    if not GL then return end

    -- Hook 1: GatherLite:GetWorldMapNodesForRect (Standard WorldMap with neighbors)
    if type(GL.GetWorldMapNodesForRect) == "function" and not GL._glso_GetWorldMapNodesForRect then
        GL._glso_GetWorldMapNodesForRect = GL.GetWorldMapNodesForRect
        GL.GetWorldMapNodesForRect = function(self, kind, mapID, left, right, bottom, top)
            if ns:IsHideAllMapActive() then
                return {}
            end
            local nodes = GL._glso_GetWorldMapNodesForRect(self, kind, mapID, left, right, bottom, top)
            if ns:IsWorldMapFilterActive() then
                local allowed = ns:GetAllowedObjectIDs()
                local filtered = {}
                if nodes and type(nodes) == "table" then
                    for i = 1, #nodes do
                        local n = nodes[i]
                        if n and n.object and allowed[n.object] then
                            filtered[#filtered + 1] = n
                        end
                    end
                end
                return filtered
            end
            return nodes
        end
    end

    -- Hook 2: GatherLite:GetNodesForMapRect (Standard WorldMap without neighbors & OpenMap rect queries)
    if type(GL.GetNodesForMapRect) == "function" and not GL._glso_GetNodesForMapRect then
        GL._glso_GetNodesForMapRect = GL.GetNodesForMapRect
        GL.GetNodesForMapRect = function(self, typeKind, mapID, left, right, bottom, top)
            if ns:IsHideAllMapActive() then
                return {}
            end
            local nodes = GL._glso_GetNodesForMapRect(self, typeKind, mapID, left, right, bottom, top)
            if ns:IsWorldMapFilterActive() then
                local allowed = ns:GetAllowedObjectIDs()
                local filtered = {}
                if nodes and type(nodes) == "table" then
                    for i = 1, #nodes do
                        local n = nodes[i]
                        if n and n.object and allowed[n.object] then
                            filtered[#filtered + 1] = n
                        end
                    end
                end
                return filtered
            end
            return nodes
        end
    end

    -- Hook 3: GatherLite:GetNearbyZoneNodes (Minimap node discovery)
    if type(GL.GetNearbyZoneNodes) == "function" and not GL._glso_GetNearbyZoneNodes then
        GL._glso_GetNearbyZoneNodes = GL.GetNearbyZoneNodes
        GL.GetNearbyZoneNodes = function(self, kind, mapID, instanceID, posX, posY, range)
            if ns:IsHideAllMiniActive() then
                return {}
            end
            local nodes = GL._glso_GetNearbyZoneNodes(self, kind, mapID, instanceID, posX, posY, range)
            if ns:IsMinimapFilterActive() then
                local allowed = ns:GetAllowedObjectIDs()
                local filtered = {}
                if nodes and type(nodes) == "table" then
                    for i = 1, #nodes do
                        local n = nodes[i]
                        if n and n.object and allowed[n.object] then
                            filtered[#filtered + 1] = n
                        end
                    end
                end
                return filtered
            end
            return nodes
        end
    end

    -- Hook 4: OpenMap:Refill & GatherLite:IsIgnored wrapper (Adjustment #1)
    -- Wrap OpenMap:Refill to set inOpenMapRefill flag only during its execution
    local function tryHookOpenMap(OpenMap)
        if OpenMap and type(OpenMap.Refill) == "function" and not OpenMap._glso_Refill then
            OpenMap._glso_Refill = OpenMap.Refill
            OpenMap.Refill = function(self, bounds, options, keepExisting)
                inOpenMapRefill = true
                local ok, err = pcall(OpenMap._glso_Refill, self, bounds, options, keepExisting)
                inOpenMapRefill = false
                if not ok and err then
                    geterrorhandler()(err)
                end
            end
        end
    end

    local OpenMap = (GL.plugins and (GL.plugins.OpenMap or GL.plugins.openmap))
        or (GL.modules and (GL.modules.OpenMap or GL.modules.openmap))
        or GL.OpenMap
    tryHookOpenMap(OpenMap)

    -- Hook GatherLite:IsIgnored to filter ONLY when inOpenMapRefill is active (Adjustment #1)
    if type(GL.IsIgnored) == "function" and not GL._glso_IsIgnored then
        GL._glso_IsIgnored = GL.IsIgnored
        GL.IsIgnored = function(self, objectID)
            if inOpenMapRefill and (ns:IsHideAllMapActive() or ns:IsWorldMapFilterActive()) then
                if ns:IsHideAllMapActive() then
                    return true -- treat as ignored so OpenMap:Refill skips all nodes
                end
                local allowed = ns:GetAllowedObjectIDs()
                if not allowed[objectID] then
                    return true -- treat as ignored so OpenMap:Refill skips it
                end
            end
            return GL._glso_IsIgnored(self, objectID)
        end
    end

    -- Hook 5: Synchronization hooks on user selection changes
    local sidebar = GL.modules and GL.modules.worldMapSidebar
    if sidebar and type(sidebar.ToggleResource) == "function" and not sidebar._glso_Hooked then
        sidebar._glso_Hooked = true
        hooksecurefunc(sidebar, "ToggleResource", function()
            ns:TriggerRefresh()
        end)
    end

    local routes = GL.plugins and GL.plugins.Routes
    if routes then
        if type(routes.Generate) == "function" and not routes._glso_GenerateHooked then
            routes._glso_GenerateHooked = true
            hooksecurefunc(routes, "Generate", function()
                ns:TriggerRefresh()
            end)
        end
        if type(routes.Clear) == "function" and not routes._glso_ClearHooked then
            routes._glso_ClearHooked = true
            hooksecurefunc(routes, "Clear", function()
                ns:TriggerRefresh()
            end)
        end
        if type(routes.DrawOnCanvas) == "function" and not routes._glso_DrawHooked then
            routes._glso_DrawHooked = true
            hooksecurefunc(routes, "DrawOnCanvas", function(self, frame, map, object)
                if object and type(object) == "table" and (object.id or object.objects) then
                    if ns.capturedWindowObject ~= object then
                        ns.capturedWindowObject = object
                        ns:InvalidateCache()
                    end
                end
            end)
        end
    end

    -- Hook 6: GatherLite.plugins.Fishing:Refresh (Catch locations filtering)
    local fishing = GL.plugins and GL.plugins.Fishing
    if fishing then
        if type(fishing.Select) == "function" and not fishing._glso_SelectHooked then
            fishing._glso_SelectHooked = true
            hooksecurefunc(fishing, "Select", function()
                ns:TriggerRefresh()
            end)
        end

        if type(fishing.Refresh) == "function" and not fishing._glso_Refresh then
            fishing._glso_Refresh = fishing.Refresh
            fishing.Refresh = function(self)
                local isHideMap = ns:IsHideAllMapActive()
                local isHideMini = ns:IsHideAllMiniActive()
                local isWorldMapOn = ns:IsWorldMapFilterActive()
                local isMiniOn = ns:IsMinimapFilterActive()

                -- If no filters are active at all, run vanilla refresh
                if not isHideMap and not isHideMini and not isWorldMapOn and not isMiniOn then
                    return fishing._glso_Refresh(self)
                end

                -- Determine if any fish itemID is currently allowed
                local allowed = ns:GetAllowedObjectIDs()
                local hasAllowedFish = false
                if self.object and self.object.itemID and allowed[self.object.itemID] then
                    hasAllowedFish = true
                elseif allowed and GL.db and GL.db.char and GL.db.char.fishItem and allowed[GL.db.char.fishItem] then
                    hasAllowedFish = true
                end

                local allowWorld = true
                if isHideMap then
                    allowWorld = false
                elseif isWorldMapOn then
                    allowWorld = hasAllowedFish
                end

                local allowMini = true
                if isHideMini then
                    allowMini = false
                elseif isMiniOn then
                    allowMini = hasAllowedFish
                end

                -- If fishing is suppressed on both maps, clear pins and return immediately
                if not allowWorld and not allowMini then
                    self:ClearPins()
                    return
                end

                -- Temporarily override tracking flags during refresh so only permitted maps get pins
                local origGetTracking = GL.GetNodeTracking
                GL.GetNodeTracking = function(caller, target, nodeType)
                    if nodeType == "fishing" or nodeType == "fish" then
                        if target == "worldmap" and not allowWorld then
                            return false
                        end
                        if target == "minimap" and not allowMini then
                            return false
                        end
                    end
                    return origGetTracking(caller, target, nodeType)
                end

                -- If a fish was selected in self.object but is not allowed on worldmap, temporarily suppress
                local savedObject = self.object
                if not hasAllowedFish then
                    self.object = nil
                end

                local ok, err = pcall(fishing._glso_Refresh, self)

                self.object = savedObject
                GL.GetNodeTracking = origGetTracking

                if not ok and err then
                    geterrorhandler()(err)
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Event Handling & Addon Lifecycle
-------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
    elseif event == "PLAYER_LOGIN" then
        if not _G.GatherLite then
            local msg = (ns.L and ns.L.GATHERLITE_MISSING) or "GatherLite not detected. The addon will remain inactive."
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[GatherLite_SelectedOnly]|r " .. msg)
            return
        end

        InitDB()
        SetupHooks()
        isInitialized = true

        -- Trigger initial UI update
        if ns.CreateWorldMapButton then
            ns:CreateWorldMapButton()
        end
        if ns.UpdateUI then
            ns:UpdateUI()
        end
    end
end)
