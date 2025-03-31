-- Ultimate Blood Debt ESP (Полная версия)
getgenv().Toggle = true

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Точные названия оружия (обновленные)
local MURDERER_WEAPONS = {
    "Sawn-off",
    "RR-LightCompactPistolS",
    "K1911",
 "Ry's GG-17",
"AT's KAR15",
"JS2-Derringy"
}

local SHERIFF_WEAPONS = {
    "RR-Snubby",
    "GG-17",
    "IZVEKH-412"
}

-- Улучшенный поиск оружия
local function getPlayerWeapons(player)
    local weapons = {}
    
    -- Проверка трех мест: в руках, инвентарь, модель персонажа
    local checkLocations = {
        player.Character and player.Character:FindFirstChildOfClass("Humanoid"),
        player:FindFirstChild("Backpack"),
        player.Character
    }
    
    for _, location in ipairs(checkLocations) do
        if location then
            for _, item in ipairs(location:GetDescendants()) do
                if item:IsA("Tool") then
                    table.insert(weapons, item.Name)
                end
            end
        end
    end
    
    return weapons
end

-- Определение роли с приоритетом шерифов
local function getPlayerRole(player)
    local weapons = getPlayerWeapons(player)
    
    -- Сначала проверяем шерифов (высший приоритет)
    for _, weapon in ipairs(weapons) do
        for _, sheriffWeapon in ipairs(SHERIFF_WEAPONS) do
            if weapon == sheriffWeapon then
                return "sheriff"
            end
        end
    end
    
    -- Затем убийц
    for _, weapon in ipairs(weapons) do
        for _, murdererWeapon in ipairs(MURDERER_WEAPONS) do
            if weapon == murdererWeapon then
                return "murderer"
            end
        end
    end
    
    return "civilian"
end

-- Создание ESP с улучшенной графикой
local function updateESP(player)
    if not player.Character then return end
    
    -- Удаление старого ESP
    if player.Character:FindFirstChild("FinalESP") then
        player.Character.FinalESP:Destroy()
    end

    -- Настройки подсветки
    local role = getPlayerRole(player)
    local highlight = Instance.new("Highlight")
    highlight.Name = "FinalESP"
    highlight.Parent = player.Character
    highlight.Adornee = player.Character
    highlight.OutlineTransparency = 0
    
    if role == "murderer" then
        highlight.FillColor = Color3.fromRGB(255, 60, 60)  -- Ярко-красный
        highlight.OutlineColor = Color3.fromRGB(150, 0, 0) -- Темно-красная обводка
    elseif role == "sheriff" then
        highlight.FillColor = Color3.fromRGB(100, 150, 255) -- Светло-синий
        highlight.OutlineColor = Color3.fromRGB(0, 50, 150) -- Темно-синяя обводка
    else
        highlight.FillColor = Color3.fromRGB(60, 255, 60)  -- Ярко-зеленый
        highlight.OutlineColor = Color3.fromRGB(0, 100, 0) -- Темно-зеленая обводка
    end
    
    highlight.FillTransparency = 0.3
end

-- Оптимизированный главный цикл
local function ESPLoop()
    while getgenv().Toggle do
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                pcall(updateESP, player)
            end
        end
        task.wait(0.15) -- Оптимальная частота обновления
    end
end

-- Автозапуск
coroutine.wrap(ESPLoop)()

-- Информационное уведомление
local weaponInfo = string.format(
    "🔴 Убийцы: %s\n🔵 Шерифы: %s",
    table.concat(MURDERER_WEAPONS, ", "),
    table.concat(SHERIFF_WEAPONS, ", ")
)

game.StarterGui:SetCore("SendNotification", {
    Title = "ESP Активирован",
    Text = weaponInfo,
    Duration = 10,
    Button1 = "OK"
})

-- Функция остановки
function stopESP()
    getgenv().Toggle = false
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("FinalESP") then
            player.Character.FinalESP:Destroy()
        end
    end
end
