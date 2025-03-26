local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local ESPEnabled = true
local TeamCheck = false
local ShowBox = false
local ShowName = true
local ShowHealth = true
local ShowTracer = true
local TracerThickness = 1
local MenuVisible = true

-- Кэш для ESP объектов
local ESPCache = {}
local ActiveESP = true -- Флаг активности ESP

-- Цвета в стиле Neverlose
local Colors = {
    Background = Color3.fromRGB(20, 20, 30),
    Header = Color3.fromRGB(30, 30, 45),
    Button = Color3.fromRGB(40, 40, 60),
    ButtonHover = Color3.fromRGB(50, 50, 75),
    ButtonActive = Color3.fromRGB(35, 35, 55),
    Text = Color3.fromRGB(220, 220, 220),
    ToggleOn = Color3.fromRGB(80, 180, 80),
    ToggleOff = Color3.fromRGB(180, 60, 60),
    CloseButton = Color3.fromRGB(180, 60, 60),
    CloseButtonHover = Color3.fromRGB(200, 70, 70),
    DestroyButton = Color3.fromRGB(180, 60, 60),
    DestroyButtonHover = Color3.fromRGB(200, 70, 70),
    Tooltip = Color3.fromRGB(40, 40, 50)
}

-- Полное удаление всех следов скрипта
local function FullDestroy()
    ActiveESP = false -- Отключаем ESP перед удалением
    
    -- Удаляем все ESP элементы
    for _, player in pairs(Players:GetPlayers()) do
        if ESPCache[player] then
            if ESPCache[player].Box and ESPCache[player].Box.Remove then ESPCache[player].Box:Remove() end
            if ESPCache[player].Name and ESPCache[player].Name.Remove then ESPCache[player].Name:Remove() end
            if ESPCache[player].Health and ESPCache[player].Health.Remove then ESPCache[player].Health:Remove() end
            if ESPCache[player].Tracer and ESPCache[player].Tracer.Remove then ESPCache[player].Tracer:Remove() end
            ESPCache[player] = nil
        end
    end
    
    -- Удаляем меню
    if game.CoreGui:FindFirstChild("ESPMenu") then
        game.CoreGui.ESPMenu:Destroy()
    end
end

-- Создаем Drawing объекты
local function CreateESP(player)
    if ESPCache[player] then return ESPCache[player] end
    
    local esp = {
        Box = Drawing.new("Quad"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Connections = {}
    }
    
    -- Настройка Box
    esp.Box.Thickness = 1
    esp.Box.Filled = false
    esp.Box.ZIndex = 10
    esp.Box.Visible = false
    
    -- Настройка Name
    esp.Name.Size = 14
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.ZIndex = 11
    esp.Name.Visible = false
    
    -- Настройка Health
    esp.Health.Size = 12
    esp.Health.Center = true
    esp.Health.Outline = true
    esp.Health.ZIndex = 11
    esp.Health.Visible = false
    
    -- Настройка Tracer
    esp.Tracer.Thickness = TracerThickness
    esp.Tracer.ZIndex = 9
    esp.Tracer.Visible = false
    
    -- Подключаем обработчики для нового игрока
    esp.Connections.CharacterAdded = player.CharacterAdded:Connect(function(character)
        if not ActiveESP then return end
        task.wait(1) -- Ждем полной загрузки персонажа
        UpdateESP(player)
    end)
    
    esp.Connections.PlayerRemoving = player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(game) then
            RemoveESP(player)
        end
    end)
    
    ESPCache[player] = esp
    return esp
end

-- Полное удаление ESP для игрока
local function RemoveESP(player)
    local esp = ESPCache[player]
    if not esp then return end
    
    -- Отключаем все подключения
    for _, conn in pairs(esp.Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    
    -- Удаляем Drawing объекты
    if esp.Box and esp.Box.Remove then esp.Box:Remove() end
    if esp.Name and esp.Name.Remove then esp.Name:Remove() end
    if esp.Health and esp.Health.Remove then esp.Health:Remove() end
    if esp.Tracer and esp.Tracer.Remove then esp.Tracer:Remove() end
    
    ESPCache[player] = nil
end

-- Обновление ESP для конкретного игрока
local function UpdateESP(player)
    local esp = ESPCache[player] or CreateESP(player)
    
    -- Сначала скрываем все элементы
    esp.Box.Visible = false
    esp.Name.Visible = false
    esp.Health.Visible = false
    esp.Tracer.Visible = false
    
    -- Проверяем условия отображения
    if not ActiveESP or not ESPEnabled then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Проверка команды
    if TeamCheck and player.Team == LocalPlayer.Team then return end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then return end
    
    -- Цвет для врагов
    local color = Color3.new(1, 0, 0)
    
    -- Размеры Box
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
    local boxSize = Vector2.new(2000 / distance, 3000 / distance)
    local boxPosition = Vector2.new(screenPos.X, screenPos.Y)
    
    -- Обновляем элементы в зависимости от настроек
    if ShowBox then
        esp.Box.PointA = Vector2.new(boxPosition.X - boxSize.X/2, boxPosition.Y - boxSize.Y/2)
        esp.Box.PointB = Vector2.new(boxPosition.X + boxSize.X/2, boxPosition.Y - boxSize.Y/2)
        esp.Box.PointC = Vector2.new(boxPosition.X + boxSize.X/2, boxPosition.Y + boxSize.Y/2)
        esp.Box.PointD = Vector2.new(boxPosition.X - boxSize.X/2, boxPosition.Y + boxSize.Y/2)
        esp.Box.Color = color
        esp.Box.Visible = true
    else
        esp.Box.Visible = false
    end
    
    if ShowName then
        esp.Name.Text = player.Name
        esp.Name.Color = color
        esp.Name.Position = Vector2.new(boxPosition.X, boxPosition.Y - boxSize.Y/2 - 20)
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end
    
    if ShowHealth then
        esp.Health.Text = math.floor(humanoid.Health).."/"..math.floor(humanoid.MaxHealth)
        esp.Health.Color = Color3.new(1, humanoid.Health/humanoid.MaxHealth, humanoid.Health/humanoid.MaxHealth)
        esp.Health.Position = Vector2.new(boxPosition.X, boxPosition.Y - boxSize.Y/2 - 5)
        esp.Health.Visible = true
    else
        esp.Health.Visible = false
    end
    
    if ShowTracer then
        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        esp.Tracer.To = Vector2.new(boxPosition.X, boxPosition.Y)
        esp.Tracer.Color = color
        esp.Tracer.Thickness = TracerThickness
        esp.Tracer.Visible = true
    else
        esp.Tracer.Visible = false
    end
end

-- Обновление всех ESP
local function UpdateAllESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            UpdateESP(player)
        end
    end
end

-- Применение настроек
local function ApplySettings()
    for _, esp in pairs(ESPCache) do
        if esp.Tracer then
            esp.Tracer.Thickness = TracerThickness
        end
    end
    UpdateAllESP()
end

-- Создаем подсказку
local function CreateTooltip(parent, text)
    local Tooltip = Instance.new("TextLabel")
    Tooltip.Name = "Tooltip"
    Tooltip.Size = UDim2.new(1.5, 0, 0, 20)
    Tooltip.Position = UDim2.new(0, 0, 1, 5)
    Tooltip.BackgroundColor3 = Colors.Tooltip
    Tooltip.TextColor3 = Colors.Text
    Tooltip.Text = text
    Tooltip.Font = Enum.Font.GothamMedium
    Tooltip.TextSize = 12
    Tooltip.Visible = false
    Tooltip.ZIndex = 9999
    Tooltip.Parent = parent
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Tooltip
    
    parent.MouseEnter:Connect(function()
        Tooltip.Visible = true
    end)
    
    parent.MouseLeave:Connect(function()
        Tooltip.Visible = false
    end)
    
    return Tooltip
end

-- Анимация кнопок
local function ButtonHoverEffect(button, hoverColor, normalColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = hoverColor}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = normalColor}):Play()
    end)
end

-- Создаем меню в стиле Neverlose
local function CreateMenu()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ESPMenu"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 220, 0, 280)
    MainFrame.Position = UDim2.new(0.5, -110, 0.5, -140)
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ZIndex = 100
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = MainFrame

    -- Тень
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 10, 1, 10)
    Shadow.Position = UDim2.new(0, -5, 0, -5)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageColor3 = Color3.new(0, 0, 0)
    Shadow.ImageTransparency = 0.8
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.ZIndex = 99
    Shadow.Parent = MainFrame

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.BackgroundColor3 = Colors.Header
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 101
    TopBar.Parent = MainFrame

    local UICornerTop = Instance.new("UICorner")
    UICornerTop.CornerRadius = UDim.new(0, 6)
    UICornerTop.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "NEVERLOSE ESP"
    Title.TextColor3 = Colors.Text
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 102
    Title.Parent = TopBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0, 0)
    CloseButton.BackgroundColor3 = Colors.CloseButton
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Colors.Text
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 16
    CloseButton.ZIndex = 102
    CloseButton.Parent = TopBar

    local UICornerClose = Instance.new("UICorner")
    UICornerClose.CornerRadius = UDim.new(0, 6)
    UICornerClose.Parent = CloseButton

    -- Подсказка для кнопки закрытия
    CreateTooltip(CloseButton, "Закрыть меню")

    -- Контейнер настроек
    local SettingsFrame = Instance.new("Frame")
    SettingsFrame.Size = UDim2.new(1, -10, 1, -80)
    SettingsFrame.Position = UDim2.new(0, 5, 0, 35)
    SettingsFrame.BackgroundTransparency = 1
    SettingsFrame.ZIndex = 101
    SettingsFrame.Parent = MainFrame

    local SettingsScroller = Instance.new("ScrollingFrame")
    SettingsScroller.Size = UDim2.new(1, 0, 1, 0)
    SettingsScroller.BackgroundTransparency = 1
    SettingsScroller.BorderSizePixel = 0
    SettingsScroller.ScrollBarThickness = 4
    SettingsScroller.CanvasSize = UDim2.new(0, 0, 0, 450)
    SettingsScroller.ZIndex = 101
    SettingsScroller.Parent = SettingsFrame

    -- Функция создания переключателей с подсказками
    local yOffset = 5
    local function CreateToggle(name, configKey, value, tooltip)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
        ToggleFrame.Position = UDim2.new(0, 0, 0, yOffset)
        ToggleFrame.BackgroundTransparency = 1
        ToggleFrame.ZIndex = 101
        ToggleFrame.Parent = SettingsScroller

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = name
        Label.TextColor3 = Colors.Text
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 101
        Label.Parent = ToggleFrame

        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Size = UDim2.new(0.3, -5, 0, 25)
        ToggleButton.Position = UDim2.new(0.7, 0, 0.5, -12)
        ToggleButton.BackgroundColor3 = value and Colors.ToggleOn or Colors.ToggleOff
        ToggleButton.Text = value and "ON" or "OFF"
        ToggleButton.TextColor3 = Colors.Text
        ToggleButton.Font = Enum.Font.GothamBold
        ToggleButton.TextSize = 12
        ToggleButton.ZIndex = 101
        ToggleButton.Parent = ToggleFrame

        local UICornerToggle = Instance.new("UICorner")
        UICornerToggle.CornerRadius = UDim.new(0, 4)
        UICornerToggle.Parent = ToggleButton

        -- Добавляем подсказку
        CreateTooltip(ToggleButton, tooltip)

        yOffset = yOffset + 35
        return ToggleButton
    end

    -- Создаем переключатели с подсказками
    local ESPToggle = CreateToggle("ESP Включен", "ESP", ESPEnabled, "Включает/выключает весь ESP")
    local TeamToggle = CreateToggle("Проверка команды", "Team", TeamCheck, "Скрывает игроков своей команды")
    local BoxToggle = CreateToggle("Рамки", "Box", ShowBox, "Показывает рамки вокруг игроков")
    local NameToggle = CreateToggle("Имена", "Name", ShowName, "Показывает имена игроков")
    local HealthToggle = CreateToggle("Здоровье", "Health", ShowHealth, "Показывает здоровье игроков")
    local TracerToggle = CreateToggle("Трейсеры", "Tracer", ShowTracer, "Линии от центра экрана к игрокам")

    -- Настройка толщины трейсера
    local ThicknessFrame = Instance.new("Frame")
    ThicknessFrame.Size = UDim2.new(1, 0, 0, 30)
    ThicknessFrame.Position = UDim2.new(0, 0, 0, yOffset)
    ThicknessFrame.BackgroundTransparency = 1
    ThicknessFrame.ZIndex = 101
    ThicknessFrame.Parent = SettingsScroller

    local ThicknessLabel = Instance.new("TextLabel")
    ThicknessLabel.Size = UDim2.new(0.7, 0, 1, 0)
    ThicknessLabel.BackgroundTransparency = 1
    ThicknessLabel.Text = "Толщина трейсеров"
    ThicknessLabel.TextColor3 = Colors.Text
    ThicknessLabel.Font = Enum.Font.GothamMedium
    ThicknessLabel.TextSize = 13
    ThicknessLabel.TextXAlignment = Enum.TextXAlignment.Left
    ThicknessLabel.ZIndex = 101
    ThicknessLabel.Parent = ThicknessFrame

    local ThicknessBox = Instance.new("TextBox")
    ThicknessBox.Size = UDim2.new(0.3, -5, 0, 25)
    ThicknessBox.Position = UDim2.new(0.7, 0, 0.5, -12)
    ThicknessBox.BackgroundColor3 = Colors.Button
    ThicknessBox.TextColor3 = Colors.Text
    ThicknessBox.Text = tostring(TracerThickness)
    ThicknessBox.Font = Enum.Font.GothamBold
    ThicknessBox.TextSize = 12
    ThicknessBox.ZIndex = 101
    ThicknessBox.Parent = ThicknessFrame

    local UICornerThickness = Instance.new("UICorner")
    UICornerThickness.CornerRadius = UDim.new(0, 4)
    UICornerThickness.Parent = ThicknessBox

    -- Подсказка для толщины трейсеров
    CreateTooltip(ThicknessBox, "Установите толщину трейсеров (1-10)")

    -- Кнопка FULL CLOSE
    local DestroyButton = Instance.new("TextButton")
    DestroyButton.Size = UDim2.new(0.9, 0, 0, 30)
    DestroyButton.Position = UDim2.new(0.05, 0, 1, -35)
    DestroyButton.BackgroundColor3 = Colors.DestroyButton
    DestroyButton.Text = "ПОЛНОЕ УДАЛЕНИЕ"
    DestroyButton.TextColor3 = Colors.Text
    DestroyButton.Font = Enum.Font.GothamBold
    DestroyButton.TextSize = 12
    DestroyButton.ZIndex = 101
    DestroyButton.Parent = MainFrame

    local UICornerDestroy = Instance.new("UICorner")
    UICornerDestroy.CornerRadius = UDim.new(0, 4)
    UICornerDestroy.Parent = DestroyButton

    -- Подсказка для кнопки удаления
    CreateTooltip(DestroyButton, "Полностью удаляет ESP из игры")

    -- Анимации кнопок
    ButtonHoverEffect(CloseButton, Colors.CloseButtonHover, Colors.CloseButton)
    ButtonHoverEffect(DestroyButton, Colors.DestroyButtonHover, Colors.DestroyButton)
    ButtonHoverEffect(ThicknessBox, Colors.ButtonHover, Colors.Button)

    -- Обработчики событий
    ESPToggle.MouseButton1Click:Connect(function()
        ESPEnabled = not ESPEnabled
        ESPToggle.Text = ESPEnabled and "ON" or "OFF"
        ESPToggle.BackgroundColor3 = ESPEnabled and Colors.ToggleOn or Colors.ToggleOff
        UpdateAllESP()
    end)

    TeamToggle.MouseButton1Click:Connect(function()
        TeamCheck = not TeamCheck
        TeamToggle.Text = TeamCheck and "ON" or "OFF"
        TeamToggle.BackgroundColor3 = TeamCheck and Colors.ToggleOn or Colors.ToggleOff
        UpdateAllESP()
    end)

    BoxToggle.MouseButton1Click:Connect(function()
        ShowBox = not ShowBox
        BoxToggle.Text = ShowBox and "ON" or "OFF"
        BoxToggle.BackgroundColor3 = ShowBox and Colors.ToggleOn or Colors.ToggleOff
        UpdateAllESP()
    end)

    NameToggle.MouseButton1Click:Connect(function()
        ShowName = not ShowName
        NameToggle.Text = ShowName and "ON" or "OFF"
        NameToggle.BackgroundColor3 = ShowName and Colors.ToggleOn or Colors.ToggleOff
        UpdateAllESP()
    end)

    HealthToggle.MouseButton1Click:Connect(function()
        ShowHealth = not ShowHealth
        HealthToggle.Text = ShowHealth and "ON" or "OFF"
        HealthToggle.BackgroundColor3 = ShowHealth and Colors.ToggleOn or Colors.ToggleOff
        UpdateAllESP()
    end)

    TracerToggle.MouseButton1Click:Connect(function()
        ShowTracer = not ShowTracer
        TracerToggle.Text = ShowTracer and "ON" or "OFF"
        TracerToggle.BackgroundColor3 = ShowTracer and Colors.ToggleOn or Colors.ToggleOff
        UpdateAllESP()
    end)

    ThicknessBox.FocusLost:Connect(function()
        local num = tonumber(ThicknessBox.Text)
        if num and num > 0 and num <= 10 then
            TracerThickness = num
            ApplySettings()
        else
            ThicknessBox.Text = tostring(TracerThickness)
        end
    end)

    -- Анимация открытия/закрытия
    MainFrame.Size = UDim2.new(0, 220, 0, 0)
    MainFrame.Position = UDim2.new(0.5, -110, 0.5, 0)
    local openTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 220, 0, 280), Position = UDim2.new(0.5, -110, 0.5, -140)})
    openTween:Play()

    CloseButton.MouseButton1Click:Connect(function()
        local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 220, 0, 0), Position = UDim2.new(0.5, -110, 0.5, 0)})
        closeTween:Play()
        closeTween.Completed:Wait()
        MenuVisible = false
        MainFrame.Visible = false
    end)

    DestroyButton.MouseButton1Click:Connect(FullDestroy)

    return ScreenGui
end

-- Инициализация ESP для всех игроков
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

-- Обработка новых игроков
Players.PlayerAdded:Connect(function(player)
    if ActiveESP then
        CreateESP(player)
    end
end)

-- Основной цикл обновления (вставьте вместо старого кода)
RunService.RenderStepped:Connect(function()
    if not ActiveESP then return end
    UpdateAllESP() -- Обновляем каждый кадр (60 FPS+)
end)

-- Создаем меню
local menu = CreateMenu()

-- Горячая клавиша для меню (K)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.K then
        MenuVisible = not MenuVisible
        if MenuVisible then
            menu.MainFrame.Visible = true
            local openTween = TweenService:Create(menu.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 220, 0, 280), Position = UDim2.new(0.5, -110, 0.5, -140)})
            openTween:Play()
        else
            local closeTween = TweenService:Create(menu.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 220, 0, 0), Position = UDim2.new(0.5, -110, 0.5, 0)})
            closeTween:Play()
            closeTween.Completed:Wait()
            menu.MainFrame.Visible = false
        end
    end
end)

-- Первоначальное обновление
UpdateAllESP()