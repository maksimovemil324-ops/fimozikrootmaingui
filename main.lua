local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/source.lua", true))()

local Window = Luna:CreateWindow({
    Name = "FIMO HUB",
    Subtitle = "by Fimozikroot | t.me/fimozikroot",
    LogoID = "100217590927128",
    LoadingEnabled = true,
    LoadingTitle = "FIMO HUB",
    LoadingSubtitle = "by Fimozikroot",
    ConfigSettings = { RootFolder = nil, ConfigFolder = "FimoHub" },
    KeySystem = true,
    KeySettings = {
        Title = "FIMO HUB Key",
        Subtitle = "Verification",
        Note = "Key is: fimozikroot",
        SaveInRoot = false,
        SaveKey = true,
        Key = {"fimozikroot"},
        SecondAction = { Enabled = false, Type = "Link", Parameter = "" }
    }
})

Window:CreateHomeTab({ SupportedExecutors = {"Wave","Delta","Codex","Hydrogen","Solara","Macsploit","Real"}, DiscordInvite = "fimozikroot", Icon = 1 })

local SelectTab = Window:CreateTab({ Name = "Select Game", Icon = "games", ImageSource = "Material", ShowTitle = true })

local BASE = "https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/"

local function LoadMode(mode)
    local url = BASE .. mode .. ".lua"
    local ok, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if not ok then
        Luna:Notification({Title = "Error", Content = "Failed to load " .. mode .. ": " .. tostring(err), Icon = "error", ImageSource = "Material"})
    end
end

SelectTab:CreateButton({ Name = "Universal", Description = "Works in all games", Callback = function() LoadMode("universal") end })
SelectTab:CreateButton({ Name = "Block Strike", Description = "ESP + Aimbot + Bhop", Callback = function() LoadMode("blockstrike") end })
SelectTab:CreateButton({ Name = "Rust Lite", Description = "Drops + Sleepers + Guards", Callback = function() LoadMode("rustlite") end })
SelectTab:CreateButton({ Name = "UAV Strike", Description = "Drone ESP + Aimlock", Callback = function() LoadMode("uavstrike") end })
SelectTab:CreateButton({ Name = "Minesweeper", Description = "Auto Solver & ESP", Callback = function() LoadMode("minesweeper") end })
