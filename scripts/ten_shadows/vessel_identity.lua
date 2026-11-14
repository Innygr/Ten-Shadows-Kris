local Identity = {}
local DEFAULTS = {name = "Vessel", gender = "unspecified", pronouns = "they/them", presentation = "androgynous"}
local VALID_GENDERS = {male = true, female = true, nonbinary = true, unspecified = true}
local VALID_PRESENTATIONS = {masculine = true, feminine = true, androgynous = true}
local profile
local saved_profile_exists = false

local function cleanText(value, fallback, limit)
    if type(value) ~= "string" then return fallback end
    value = value:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return fallback end
    return value:sub(1, limit)
end

function Identity.normalize(data)
    data = type(data) == "table" and data or {}
    local gender = VALID_GENDERS[data.gender] and data.gender or DEFAULTS.gender
    local presentation = VALID_PRESENTATIONS[data.presentation] and data.presentation or DEFAULTS.presentation
    return {
        name = cleanText(data.name, DEFAULTS.name, 12),
        gender = gender,
        pronouns = cleanText(data.pronouns, DEFAULTS.pronouns, 32),
        presentation = presentation,
    }
end

function Identity.load()
    local data = Kristal.loadData("vessel_identity")
    saved_profile_exists = type(data) == "table"
    profile = Identity.normalize(data)
    return profile
end

function Identity.hasSavedProfile()
    if not profile then Identity.load() end
    return saved_profile_exists
end

function Identity.get()
    if not profile then return Identity.load() end
    return profile
end

function Identity.save(data)
    profile = Identity.normalize(data or Identity.get())
    Kristal.saveData("vessel_identity", profile)
    saved_profile_exists = true
    return profile
end

function Identity.update(changes)
    local updated = {}
    for key, value in pairs(Identity.get()) do updated[key] = value end
    if type(changes) == "table" then
        for key, value in pairs(changes) do
            if DEFAULTS[key] ~= nil then updated[key] = value end
        end
    end
    return Identity.save(updated)
end

local COMMON_PRONOUNS = {
    ["he/him"] = {subject = "he", object = "him", determiner = "his", possessive = "his", reflexive = "himself"},
    ["she/her"] = {subject = "she", object = "her", determiner = "her", possessive = "hers", reflexive = "herself"},
    ["they/them"] = {subject = "they", object = "them", determiner = "their", possessive = "theirs", reflexive = "themself"},
    ["xe/xem"] = {subject = "xe", object = "xem", determiner = "xyr", possessive = "xyrs", reflexive = "xemself"},
    ["it/its"] = {subject = "it", object = "it", determiner = "its", possessive = "its", reflexive = "itself"},
}

function Identity.getPronouns()
    local value = Identity.get().pronouns
    local common = COMMON_PRONOUNS[value:lower()]
    if common then
        local result = {}
        for key, pronoun in pairs(common) do result[key] = pronoun end
        return result
    end

    local subject, object = value:match("^([^/%s]+)/([^/%s]+)$")
    if not subject then
        subject = value
        object = value
    end
    local normalized = subject:lower()
    local determiner
    if normalized == "i" then
        determiner = "my"
    elseif normalized == "you" then
        determiner = "your"
    elseif normalized == "we" then
        determiner = "our"
    elseif normalized == "they" then
        determiner = "their"
    else
        determiner = object .. "s"
    end

    local possessive = determiner
    if normalized == "she" then possessive = "hers" end
    if normalized == "they" then possessive = "theirs" end
    local reflexive = object .. (normalized == "they" and "self" or "self")

    return {
        subject = subject,
        object = object,
        determiner = determiner,
        possessive = possessive,
        reflexive = reflexive,
    }
end

-- Dialogue and flavor text can use {vessel_name}, {vessel_subject},
-- {vessel_object}, {vessel_determiner}, {vessel_possessive}, and
-- {vessel_reflexive}. Pronouns are player-editable and never assumed for Kris.
function Identity.format(text)
    if type(text) ~= "string" then return text end
    local profile = Identity.get()
    local pronouns = Identity.getPronouns()
    local values = {
        vessel_name = profile.name,
        vessel_subject = pronouns.subject,
        vessel_object = pronouns.object,
        vessel_determiner = pronouns.determiner,
        vessel_possessive = pronouns.possessive,
        vessel_reflexive = pronouns.reflexive,
    }
    for key, value in pairs(values) do
        text = text:gsub("{" .. key .. "}", function() return value end)
    end
    return text
end

-- Deltarune stores the creator name on line 1 and the discarded Vessel name
-- on line 2. This mod imports line 2 because it belongs to the Vessel.
function Identity.parseDeltaruneSave(contents)
    if type(contents) ~= "string" or contents == "" then return nil end
    local vessel_name = contents:match("^[^\r\n]*[\r\n]+([^\r\n]*)")
    return cleanText(vessel_name, nil, 12)
end

local function defaultSavePaths()
    local paths = {}
    local local_app_data, home = os.getenv("LOCALAPPDATA"), os.getenv("HOME")
    if local_app_data then paths[#paths + 1] = local_app_data .. "/DELTARUNE" end
    if home then
        paths[#paths + 1] = home .. "/Library/Application Support/com.tobyfox.deltarune"
        paths[#paths + 1] = home .. "/Library/Application Support/DELTARUNE"
        -- Native Linux ports use XDG config storage; .local/share is kept
        -- as a compatibility fallback for older/custom builds.
        paths[#paths + 1] = home .. "/.config/DELTARUNE"
        paths[#paths + 1] = home .. "/.local/share/DELTARUNE"

        local steam_roots = {
            home .. "/.steam/steam",
            home .. "/.local/share/Steam",
            home .. "/.var/app/com.valvesoftware.Steam/.local/share/Steam",
        }
        for _, steam_root in ipairs(steam_roots) do
            for _, app_id in ipairs({"1671210", "1690940"}) do
                paths[#paths + 1] = steam_root .. "/steamapps/compatdata/" .. app_id
                    .. "/pfx/drive_c/users/steamuser/AppData/Local/DELTARUNE"
            end
        end
    end
    return paths
end

function Identity.findDeltaruneName(paths)
    paths = paths or defaultSavePaths()
    -- Slot 9 mirrors the most recently loaded save; regular and completion
    -- slots follow as fallbacks in case no current-save copy exists.
    local slots = {9, 0, 1, 2, 3, 4, 5}
    for chapter = 5, 1, -1 do
        for _, slot in ipairs(slots) do
            local filename = "filech" .. chapter .. "_" .. slot
            for _, directory in ipairs(paths) do
                local path = directory .. "/" .. filename
                local file = io.open(path, "rb")
                if file then
                    local contents = file:read("*a")
                    file:close()
                    local name = Identity.parseDeltaruneSave(contents)
                    if name then return name, path end
                end
            end
        end
    end
    return nil
end

return Identity
