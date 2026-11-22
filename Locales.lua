local addonName, ns = ...

local locale = GetLocale and GetLocale() or "enUS"

-------------------------------------------------------------------------------
-- Master Base Table: English (enUS / enGB & Global Fallback)
-- All clients (koKR, ruRU, deDE, frFR, zhCN, etc.) will use these strings.
-------------------------------------------------------------------------------
local enUS = {
    TITLE = "GatherLite: Selected Only",
    GATHERLITE_MISSING = "GatherLite not detected. The addon will remain inactive.",
    STATUS_MAP = "World Map:",
    STATUS_MINI = "Minimap:",
    STATUS_ACTIVE = "ACTIVE (Selected Only)",
    STATUS_DISABLED = "DISABLED",
    STATUS_ALL_HIDDEN = "ALL PINS HIDDEN",
    STATUS_RESTORED = "PINS RESTORED",
    FILTER_ACTIVE = "SELECTED ONLY",
    FILTER_NORMAL = "NORMAL (ALL)",
    RESOURCES_DETECTED = "Active resources filtered (%d):",
    AND_MORE = "... and %d more",
    NO_SELECTION_ACTIVE = "No active selection:",
    NO_SELECTION_DESC = "Hiding all nodes until you select a resource in GatherLite or generate a route.",
    NO_SELECTION_NONE = "No resources currently selected in GatherLite.",
    HIDE_ALL_TOOLTIP = "Hide All mode is active on the map.",
    HIDE_ALL_RESTORE_HINT = "Press Shift + Left Click to restore pins.",

    TOOLTIP_LEFT = "Left Click:",
    TOOLTIP_LEFT_DESC = "Toggle 'Selected Only' (World Map)",
    TOOLTIP_RIGHT = "Right Click:",
    TOOLTIP_RIGHT_DESC = "Toggle 'Selected Only' (Minimap)",
    TOOLTIP_SHIFT_LEFT = "Shift + Left Click:",
    TOOLTIP_SHIFT_LEFT_DESC = "Hide/Restore ALL pins (World Map)",
    TOOLTIP_SHIFT_RIGHT = "Shift + Right Click:",
    TOOLTIP_SHIFT_RIGHT_DESC = "Hide/Restore ALL pins (Minimap)",

    CMD_AUDIT_HEADER = "--- Status Audit ---",
    CMD_ALLOWED_IDS = "Total allowed node IDs: ",
    CMD_SELECTED_RESOURCES = "Selected resources (%d): ",
    CMD_NONE = "None",
    CMD_ANCHOR_PEER = "GatherLite anchor button: ",
    CMD_BUTTON_STATE = "SelectedOnly button: ",
    CMD_VISIBLE = "Visible",
    CMD_HIDDEN = "Hidden",
    CMD_NOT_FOUND = "Not found in _G (using fallback position)",
    CMD_CACHE_RESET = "Cache invalidated and map pins refreshed.",
    CMD_HELP_HEADER = "Available slash commands:",
    CMD_HELP_MAIN = "• |cFFFFFF00/glonly|r : Toggle 'Selected Only' filter on World Map.",
    CMD_HELP_MINI = "• |cFFFFFF00/glonly minimap|r : Toggle 'Selected Only' filter on Minimap.",
    CMD_HELP_HIDE = "• |cFFFFFF00/glonly hide|r : Toggle Hide All pins on World Map.",
    CMD_HELP_HIDE_MINI = "• |cFFFFFF00/glonly hide mini|r : Toggle Hide All pins on Minimap.",
    CMD_HELP_STATUS = "• |cFFFFFF00/glonly status|r : Show full diagnostic audit.",
    CMD_HELP_RESET = "• |cFFFFFF00/glonly reset|r : Force cache purge and map reload.",
}

-------------------------------------------------------------------------------
-- Spanish Localization Overrides (esES & esMX)
-------------------------------------------------------------------------------
local esES = {
    TITLE = "GatherLite: Solo Seleccionados",
    GATHERLITE_MISSING = "GatherLite no detectado. El addon permanecerá inactivo.",
    STATUS_MAP = "Mapa del Mundo:",
    STATUS_MINI = "Minimapa:",
    STATUS_ACTIVE = "ACTIVADO (Solo Seleccionados)",
    STATUS_DISABLED = "DESACTIVADO",
    STATUS_ALL_HIDDEN = "TODOS LOS PINES OCULTOS",
    STATUS_RESTORED = "PINES RESTAURADOS",
    FILTER_ACTIVE = "SOLO SELECCIONADOS",
    FILTER_NORMAL = "NORMAL (TODOS)",
    RESOURCES_DETECTED = "Recursos activos detectados (%d):",
    AND_MORE = "... y %d más",
    NO_SELECTION_ACTIVE = "Sin selección activa:",
    NO_SELECTION_DESC = "Ocultando todos los nodos hasta que selecciones un recurso en GatherLite o generes una ruta.",
    NO_SELECTION_NONE = "Ningún recurso seleccionado en GatherLite.",
    HIDE_ALL_TOOLTIP = "Modo 'Ocultar Todo' activo en el mapa.",
    HIDE_ALL_RESTORE_HINT = "Presiona Shift + Clic Izquierdo para restaurar los pines.",

    TOOLTIP_LEFT = "Clic Izquierdo:",
    TOOLTIP_LEFT_DESC = "Alternar 'Solo seleccionados' (Mapa)",
    TOOLTIP_RIGHT = "Clic Derecho:",
    TOOLTIP_RIGHT_DESC = "Alternar 'Solo seleccionados' (Minimapa)",
    TOOLTIP_SHIFT_LEFT = "Shift + Clic Izq:",
    TOOLTIP_SHIFT_LEFT_DESC = "Ocultar/Restaurar TODOS los pines (Mapa)",
    TOOLTIP_SHIFT_RIGHT = "Shift + Clic Der:",
    TOOLTIP_SHIFT_RIGHT_DESC = "Ocultar/Restaurar TODOS los pines (Minimapa)",

    CMD_AUDIT_HEADER = "--- Auditoría de Estado ---",
    CMD_ALLOWED_IDS = "Total IDs de nodos permitidos: ",
    CMD_SELECTED_RESOURCES = "Recursos seleccionados (%d): ",
    CMD_NONE = "Ninguno",
    CMD_ANCHOR_PEER = "Botón GatherLite ancla: ",
    CMD_BUTTON_STATE = "Botón SelectedOnly: ",
    CMD_VISIBLE = "Visible",
    CMD_HIDDEN = "Oculto",
    CMD_NOT_FOUND = "No encontrado en _G (usando posición fallback)",
    CMD_CACHE_RESET = "Caché invalidada y mapa refrescado forzosamente.",
    CMD_HELP_HEADER = "Comandos disponibles:",
    CMD_HELP_MAIN = "• |cFFFFFF00/glonly|r : Alterna el filtro 'Solo seleccionados' (Mapa).",
    CMD_HELP_MINI = "• |cFFFFFF00/glonly minimap|r : Alterna el filtro 'Solo seleccionados' (Minimapa).",
    CMD_HELP_HIDE = "• |cFFFFFF00/glonly hide|r : Alterna ocultar TODOS los pines (Mapa).",
    CMD_HELP_HIDE_MINI = "• |cFFFFFF00/glonly hide mini|r : Alterna ocultar TODOS los pines (Minimapa).",
    CMD_HELP_STATUS = "• |cFFFFFF00/glonly status|r : Muestra auditoría completa del estado y recursos.",
    CMD_HELP_RESET = "• |cFFFFFF00/glonly reset|r : Fuerza un refresco de caché y pines.",
}

-------------------------------------------------------------------------------
-- Active Table Resolution with Guaranteed English Fallback
-------------------------------------------------------------------------------
local L = {}

if locale == "esES" or locale == "esMX" then
    -- Copy Spanish overrides
    for k, v in pairs(esES) do
        L[k] = v
    end
end

-- Fallback mechanism:
-- 1. If key exists in L (e.g. Spanish override), return it.
-- 2. Otherwise, fall back to Master English (enUS).
-- 3. If missing in enUS, return raw key string as ultimate safeguard.
setmetatable(L, {
    __index = function(t, k)
        return enUS[k] or k
    end
})

ns.L = L
