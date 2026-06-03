if getgenv().CustomUILibraryLoaded then return getgenv().CustomUILibraryLoaded end

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local GuiParent        = (gethui and gethui()) or game:GetService("CoreGui")

local SessionTag = "UI_" .. HttpService:GenerateGUID(false):sub(1,8)

local CFG = {
    PanelW = 840,
    PanelH = 560,
    SidebarW = 208,
    HeaderH = 38,

    C_BG = Color3.fromRGB(18, 20, 24),
    C_PANEL = Color3.fromRGB(24, 26, 31),
    C_PANEL2 = Color3.fromRGB(31, 34, 40),
    C_PANEL3 = Color3.fromRGB(39, 43, 51),
    C_BORDER = Color3.fromRGB(61, 68, 80),
    C_BORDER_SOFT = Color3.fromRGB(47, 52, 61),
    C_TEXT = Color3.fromRGB(232, 236, 241),
    C_MUTED = Color3.fromRGB(160, 168, 182),
    C_DIM = Color3.fromRGB(117, 125, 139),
    C_ACCENT = Color3.fromRGB(74, 158, 255),
}

local U = {}
function U.New(cls, props)
    local ok, obj = pcall(Instance.new, cls)
    if not ok then return nil end
    props = props or {}
    for k,v in pairs(props) do
        if k ~= "Parent" then pcall(function() obj[k] = v end) end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end
function U.Stroke(parent, c, t)
    return U.New("UIStroke", {ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Color=c or CFG.C_BORDER, Thickness=t or 1, Parent=parent})
end
function U.Pad(parent, t, r, b, l)
    return U.New("UIPadding", {
        PaddingTop=UDim.new(0,t or 0), PaddingRight=UDim.new(0,r or 0),
        PaddingBottom=UDim.new(0,b or 0), PaddingLeft=UDim.new(0,l or 0), Parent=parent
    })
end
function U.List(parent, dir, ha, va, pad)
    return U.New("UIListLayout", {
        FillDirection=dir or Enum.FillDirection.Vertical,
        HorizontalAlignment=ha or Enum.HorizontalAlignment.Left,
        VerticalAlignment=va or Enum.VerticalAlignment.Top,
        Padding=UDim.new(0,pad or 0), SortOrder=Enum.SortOrder.LayoutOrder, Parent=parent
    })
end
function U.Tween(obj, dur, props, style, dir)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
end
function U.Label(props)
    local x = Instance.new("TextLabel")
    x.BackgroundTransparency = 1
    x.TextColor3 = CFG.C_TEXT
    x.TextWrapped = true
    x.RichText = true
    x.TextXAlignment = Enum.TextXAlignment.Left
    x.Font = Enum.Font.RobotoMono
    x.TextSize = 13
    x.AutomaticSize = Enum.AutomaticSize.Y
    x.Size = UDim2.new(1,0,0,0)
    props = props or {}
    for k,v in pairs(props) do if k ~= "Parent" then pcall(function() x[k]=v end) end end
    if props.Parent then x.Parent = props.Parent end
    return x
end
function U.Button(props)
    local x = Instance.new("TextButton")
    x.AutoButtonColor = false
    x.BackgroundColor3 = CFG.C_PANEL3
    x.TextColor3 = CFG.C_TEXT
    x.Font = Enum.Font.RobotoMono
    x.TextSize = 13
    x.Size = UDim2.fromOffset(90, 30)
    props = props or {}
    for k,v in pairs(props) do if k ~= "Parent" then pcall(function() x[k]=v end) end end
    if props.Parent then x.Parent = props.Parent end
    return x
end

local Library = {}

function Library.CreateWindow(titleText)
    local Window = {
        CurrentTab = nil,
        Tabs = {},
        HUDOpen = true,
        LastPanelPosition = UDim2.new(0,30,0.5,-CFG.PanelH/2)
    }

    local Gui = U.New("ScreenGui", {
        DisplayOrder = 9999998,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Name = SessionTag .. "_GUI",
        Parent = GuiParent,
    })

    local Panel = U.New("Frame", {
        BackgroundColor3 = CFG.C_PANEL,
        Position = Window.LastPanelPosition,
        Size = UDim2.fromOffset(CFG.PanelW, CFG.PanelH),
        ClipsDescendants = true,
        Parent = Gui,
    })
    U.Stroke(Panel, CFG.C_BORDER, 1)

    -- Draggable Panel Logic
    local dragging, dragStart, panelStart = false, nil, nil
    Panel.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            panelStart = Panel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            if Window.HUDOpen then
                local newPos = UDim2.new(panelStart.X.Scale, panelStart.X.Offset + d.X, panelStart.Y.Scale, panelStart.Y.Offset + d.Y)
                Panel.Position = newPos
                Window.LastPanelPosition = newPos
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local Topbar = U.New("Frame", {
        BackgroundColor3 = CFG.C_PANEL2,
        Size = UDim2.new(1,0,0,CFG.HeaderH),
        Parent = Panel,
    })
    U.New("Frame", {BackgroundColor3=CFG.C_PANEL2, BorderSizePixel=0, Position=UDim2.new(0,0,0.5,0), Size=UDim2.new(1,0,0.5,0), Parent=Topbar})

    local ActivityBar = U.New("Frame", {BackgroundColor3=Color3.fromRGB(43,43,43), Position=UDim2.new(0,0,0,0), Size=UDim2.new(0,48,1,0), Parent=Panel})
    U.New("Frame", {BackgroundColor3=CFG.C_BORDER_SOFT, BorderSizePixel=0, Position=UDim2.new(1,-1,0,0), Size=UDim2.new(0,1,1,0), Parent=ActivityBar})

    local GlyphExplorer = U.New("TextButton", {BackgroundTransparency=1, Text="⚙", Font=Enum.Font.RobotoMono, TextSize=18, TextColor3=CFG.C_TEXT, Position=UDim2.new(0,0,0,42), Size=UDim2.new(1,0,0,42), Parent=ActivityBar})
    U.New("Frame", {BackgroundColor3=CFG.C_ACCENT, BorderSizePixel=0, Position=UDim2.new(0,0,0,8), Size=UDim2.new(0,2,0,26), Parent=GlyphExplorer})

    U.Label({
        Text=titleText or "UI Library Console",
        Font=Enum.Font.RobotoMono,
        TextSize=14,
        TextColor3=CFG.C_TEXT,
        Position=UDim2.new(0,60,0,9),
        Size=UDim2.new(0,180,0,18),
        AutomaticSize=Enum.AutomaticSize.None,
        Parent=Topbar,
    })

    local MinBtn = U.Button({Text="-", Position=UDim2.new(1,-66,0.5,-11), Size=UDim2.fromOffset(24,22), BackgroundColor3=CFG.C_PANEL3, Parent=Topbar})
    local CloseBtn = U.Button({Text="x", Position=UDim2.new(1,-36,0.5,-11), Size=UDim2.fromOffset(24,22), BackgroundColor3=Color3.fromRGB(90,30,36), TextColor3=CFG.C_TEXT, Parent=Topbar})

    local Sidebar = U.New("Frame", {
        BackgroundColor3 = Color3.fromRGB(37,37,38),
        Position = UDim2.new(0,48,0,CFG.HeaderH),
        Size = UDim2.new(0,CFG.SidebarW,1,-CFG.HeaderH),
        Parent = Panel,
    })
    U.New("Frame", {BackgroundColor3=CFG.C_BORDER_SOFT, BorderSizePixel=0, Position=UDim2.new(1,-1,0,0), Size=UDim2.new(0,1,1,0), Parent=Sidebar})
    U.Pad(Sidebar, 10, 10, 10, 10)

    local SideWrap = U.New("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Parent=Sidebar})
    U.List(SideWrap, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, 8)

    U.Label({Text="CATEGORIES", TextSize=11, TextColor3=CFG.C_MUTED, AutomaticSize=Enum.AutomaticSize.None, Size=UDim2.new(1,0,0,14), Parent=SideWrap})

    local Main = U.New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0,48+CFG.SidebarW,0,CFG.HeaderH),
        Size = UDim2.new(1,-(48+CFG.SidebarW),1,-CFG.HeaderH),
        Parent = Panel,
    })

    local EditorTabs = U.New("Frame", {BackgroundColor3=CFG.C_PANEL2, Size=UDim2.new(1,0,0,34), Parent=Main})
    U.New("Frame", {BackgroundColor3=CFG.C_BORDER_SOFT, BorderSizePixel=0, Position=UDim2.new(0,0,1,-1), Size=UDim2.new(1,0,0,1), Parent=EditorTabs})
    local EditorTabRow = U.New("Frame", {BackgroundTransparency=1, Position=UDim2.new(0,8,0,4), Size=UDim2.new(1,-16,1,-8), Parent=EditorTabs})
    U.List(EditorTabRow, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center, 6)

    local Content = U.New("Frame", {BackgroundTransparency=1, Position=UDim2.new(0,0,0,34), Size=UDim2.new(1,0,1,-34), Parent=Main})

    -- Minimized Icon Layout Setup
    local MinimizedIcon = U.New("ImageButton", {
        BackgroundColor3 = CFG.C_PANEL2,
        Visible = false,
        Position = UDim2.new(0,30,0.5,-18),
        Size = UDim2.fromOffset(36, 36),
        Image = "rbxassetid://137790715671194",
        ScaleType = Enum.ScaleType.Fit,
        Parent = Gui,
    })
    U.Stroke(MinimizedIcon, CFG.C_BORDER, 1)

    local minDragging, minDragStart, minIconStart = false, nil, nil
    MinimizedIcon.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            minDragging = true
            minDragStart = i.Position
            minIconStart = MinimizedIcon.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if minDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - minDragStart
            if not Window.HUDOpen then
                MinimizedIcon.Position = UDim2.new(minIconStart.X.Scale, minIconStart.X.Offset + d.X, minIconStart.Y.Scale, minIconStart.Y.Offset + d.Y)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then minDragging = false end
    end)

    local function SetHUDVisible(v)
        Window.HUDOpen = v
        if v then
            MinimizedIcon.Visible = false
            Panel.Position = Window.LastPanelPosition
            Panel.Visible = true
            U.Tween(Panel, 0.2, {BackgroundTransparency = 0, Size = UDim2.fromOffset(CFG.PanelW, CFG.PanelH)})
        else
            U.Tween(Panel, 0.16, {BackgroundTransparency = 1, Size = UDim2.fromOffset(CFG.PanelW, 0)})
            task.delay(0.18, function()
                if not Window.HUDOpen then
                    Panel.Visible = false
                    MinimizedIcon.Visible = true
                end
            end)
        end
    end

    MinimizedIcon.MouseButton1Click:Connect(function() SetHUDVisible(true) end)
    MinBtn.MouseButton1Click:Connect(function() SetHUDVisible(false) end)
    CloseBtn.MouseButton1Click:Connect(function() SetHUDVisible(false) end)

    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.K then SetHUDVisible(not Window.HUDOpen) end
    end)

    -- Tab Selection Visual Synchronization Routine
    local function UpdateNavigation()
        for _, tab in ipairs(Window.Tabs) do
            local isCurrent = (Window.CurrentTab == tab)
            tab.PageFrame.Visible = isCurrent
            
            U.Tween(tab.NavButton, 0.15, {
                BackgroundColor3 = isCurrent and Color3.fromRGB(26,39,59) or CFG.C_PANEL3,
                TextColor3 = isCurrent and CFG.C_ACCENT or CFG.C_TEXT,
            })
            U.Tween(tab.TopFile, 0.15, {
                BackgroundColor3 = isCurrent and Color3.fromRGB(26,39,59) or CFG.C_PANEL3,
            })
        end
    end

    -- Create Tab Method
    function Window:CreateTab(tabName)
        local Tab = {
            Controls = {}
        }

        -- Sidebar Navigation Button
        Tab.NavButton = U.Button({
            Text = "›  " .. tabName,
            Size = UDim2.new(1,0,0,30),
            BackgroundColor3 = CFG.C_PANEL3,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = SideWrap,
        })
        U.Pad(Tab.NavButton, 0, 0, 0, 12)

        -- Top File Visual Layout Node
        Tab.TopFile = U.New("Frame", {BackgroundColor3=CFG.C_PANEL3, Size=UDim2.fromOffset(130,22), Parent=EditorTabRow})
        U.Stroke(Tab.TopFile, CFG.C_BORDER_SOFT, 1)
        U.Label({Text=tabName:lower()..".cfg", Font=Enum.Font.Code, TextSize=11, TextXAlignment=Enum.TextXAlignment.Center, Size=UDim2.new(1,0,1,0), AutomaticSize=Enum.AutomaticSize.None, Parent=Tab.TopFile})

        -- Page Workspace Canvas View
        Tab.PageFrame = U.New("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,1,0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = CFG.C_DIM,
            BorderSizePixel = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            Visible = false,
            Parent = Content,
        })
        U.List(Tab.PageFrame, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, 8)
        U.Pad(Tab.PageFrame, 12, 14, 12, 12)

        -- Page Switch Bindings
        Tab.NavButton.MouseButton1Click:Connect(function()
            Window.CurrentTab = Tab
            UpdateNavigation()
        end)

        -- Create Toggle Functionality component
        function Tab:CreateToggle(title, initial, callback)
            local box = U.New("Frame", {BackgroundColor3=CFG.C_PANEL2, Size=UDim2.new(1,0,0,54), Parent=Tab.PageFrame})
            U.Stroke(box, CFG.C_BORDER_SOFT, 1)
            
            U.Label({Text=title, Font=Enum.Font.Code, TextSize=13, Position=UDim2.new(0,14,0,10), Size=UDim2.new(0.7,0,0,16), AutomaticSize=Enum.AutomaticSize.None, Parent=box})
            U.Label({Text="Boolean toggle control option configuration setting", Font=Enum.Font.Code, TextSize=10, TextColor3=CFG.C_MUTED, Position=UDim2.fromOffset(14, 28), Size=UDim2.new(0.7,0,0,14), AutomaticSize=Enum.AutomaticSize.None, Parent=box})

            local track = U.New("Frame", {BackgroundColor3=initial and CFG.C_ACCENT or CFG.C_BORDER, Position=UDim2.new(1,-60,0.5,-11), Size=UDim2.fromOffset(44,22), Parent=box})
            local knob = U.New("Frame", {BackgroundColor3=Color3.fromRGB(245,248,255), Position=UDim2.new(0,initial and 23 or 3,0.5,-8), Size=UDim2.fromOffset(16,16), Parent=track})
            local hit = U.New("TextButton", {BackgroundTransparency=1, Text="", Size=UDim2.new(1,0,1,0), Parent=box})

            local state = initial
            local function apply(v)
                state = v
                U.Tween(track, 0.15, {BackgroundColor3 = state and CFG.C_ACCENT or CFG.C_BORDER})
                U.Tween(knob, 0.15, {Position = UDim2.new(0, state and 23 or 3, 0.5, -8)})
                if callback then pcall(callback, state) end
            end
            hit.MouseButton1Click:Connect(function() apply(not state) end)
            return box
        end

        -- Create Slider Functionality Component
        function Tab:CreateSlider(title, min, max, initial, callback)
            local box = U.New("Frame", {BackgroundColor3=CFG.C_PANEL2, Size=UDim2.new(1,0,0,64), Parent=Tab.PageFrame})
            U.Stroke(box, CFG.C_BORDER_SOFT, 1)

            U.Label({Text=title, Font=Enum.Font.Code, TextSize=13, Position=UDim2.new(0,14,0,10), Size=UDim2.new(0.5,0,0,16), AutomaticSize=Enum.AutomaticSize.None, Parent=box})
            local valLabel = U.Label({Text=tostring(initial), Font=Enum.Font.Code, TextSize=13, TextColor3=CFG.C_ACCENT, TextXAlignment=Enum.TextXAlignment.Right, Position=UDim2.new(1,-120,0,10), Size=UDim2.new(0,104,0,16), AutomaticSize=Enum.AutomaticSize.None, Parent=box})

            local slideBar = U.New("Frame", {BackgroundColor3=CFG.C_PANEL3, Position=UDim2.new(0,14,1,-22), Size=UDim2.new(1,-28,0,6), Parent=box})
            U.Stroke(slideBar, CFG.C_BORDER_SOFT, 1)
            local fill = U.New("Frame", {BackgroundColor3=CFG.C_ACCENT, Size=UDim2.fromScale(0,1), BorderSizePixel=0, Parent=slideBar})
            local sliderHit = U.New("TextButton", {BackgroundTransparency=1, Text="", Size=UDim2.new(1,0,1,0), Parent=slideBar})

            local value = math.clamp(initial, min, max)
            
            local function updateSlider(inputPosition)
                local percentage = math.clamp((inputPosition.X - slideBar.AbsolutePosition.X) / slideBar.AbsoluteSize.X, 0, 1)
                value = math.round(min + (max - min) * percentage)
                fill.Size = UDim2.fromScale(percentage, 1)
                valLabel.Text = tostring(value)
                if callback then pcall(callback, value) end
            end

            local sliding = false
            sliderHit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = true
                    updateSlider(input.Position)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input.Position)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = false
                end
            end)

            -- Initialize initial value layout state positioning percentages
            local initPercent = (value - min) / (max - min)
            fill.Size = UDim2.fromScale(initPercent, 1)

            return box
        end

        -- Auto-select first initialization entry target dynamically
        if #Window.Tabs == 0 then
            Window.CurrentTab = Tab
            Tab.PageFrame.Visible = true
        end
        
        table.insert(Window.Tabs, Tab)
        UpdateNavigation()
        return Tab
    end

    return Window
end

getgenv().CustomUILibraryLoaded = Library
return Library
