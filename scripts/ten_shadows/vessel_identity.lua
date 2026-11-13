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
