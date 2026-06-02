local LOADER_URL = "https://www.kynoxhub.pro/wl/loader.lua"

local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled
    and (not UserInputService.KeyboardEnabled or UserInputService.PreferredInput == Enum.PreferredInput.Touch)

local requestFn = (syn and syn.request)
    or (http and http.request)
    or request
    or http_request

local function cacheBust(url)
    local sep = string.find(url, "?", 1, true) and "&" or "?"
    return url
        .. sep
        .. "t="
        .. tostring(math.floor(tick() * 1000))
        .. "&p="
        .. (isMobile and "mobile" or "desktop")
end

local function bodyFromResponse(res)
    if type(res) ~= "table" then
        return nil
    end
    return res.Body or res.body or res.Data or res.data
end

local function fetchRequest(url)
    if not requestFn then
        return nil
    end
    local ok, res = pcall(function()
        return requestFn({
            Url = url,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                ["Accept"] = "text/plain,*/*",
                ["Cache-Control"] = "no-cache",
                ["Pragma"] = "no-cache",
            },
        })
    end)
    if ok then
        return bodyFromResponse(res)
    end
    return nil
end

local function fetchHttpGet(url)
    local ok, body = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and type(body) == "string" and #body > 100 then
        return body
    end
    ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and #body > 100 then
        return body
    end
    return nil
end

local function fetchLoader()
    local url = cacheBust(LOADER_URL)
    if isMobile then
        return fetchRequest(url) or fetchHttpGet(url)
    end
    return fetchHttpGet(url) or fetchRequest(url)
end

local source = fetchLoader()
if type(source) ~= "string" or #source < 100 then
    error("[Kynox] Failed to download loader (" .. (isMobile and "mobile" or "desktop") .. ")")
end

local chunk, compileErr = loadstring(source)
if not chunk then
    error("[Kynox] Loader compile: " .. tostring(compileErr))
end

local ok, runErr = pcall(chunk)
if not ok then
    error("[Kynox] Loader run: " .. tostring(runErr))
end
