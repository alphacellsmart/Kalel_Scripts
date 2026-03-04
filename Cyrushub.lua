--[[
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║              C Y R U S   H U B   v3.0                        ║
║           Script Universal — Tema Roxo Púrpura               ║
║                                                               ║
║  SETUP GITHUB (faça isso antes de distribuir):               ║
║  1. Crie um repositório público no GitHub                     ║
║  2. Crie o arquivo "keys.txt" com o formato:                  ║
║       CYRUS-XXXX-XXXX|12h                                    ║
║       CYRUS-YYYY-YYYY|24h                                     ║
║       CYRUS-ZZZZ-ZZZZ|premium                                ║
║  3. Crie o arquivo "news.txt" com seus avisos                 ║
║  4. Substitua KEYS_URL e NEWS_URL abaixo pelo raw do GitHub  ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
--]]

-- ================================================================
--  CONFIGURAÇÃO — EDITE AQUI
-- ================================================================
local KEYS_URL    = "https://raw.githubusercontent.com/SEU_USER/SEU_REPO/main/keys.txt"
local NEWS_URL    = "https://raw.githubusercontent.com/SEU_USER/SEU_REPO/main/news.txt"
local DISCORD_URL = "https://discord.gg/seupremium"
local VERSION     = "v3.0"

-- Links do encurtador para obter keys
local LINK_12H      = "https://seuencurtador.com/cyrus12h"
local LINK_24H      = "https://seuencurtador.com/cyrus24h"
local LINK_PREMIUM  = "https://discord.gg/seupremium"

-- Keys de teste LOCAL (remova quando tiver o GitHub configurado)
local LOCAL_KEYS = {
    ["CYRUS-TEST-12H0"] = "12h",
    ["CYRUS-TEST-24H0"] = "24h",
    ["CYRUS-PREM-0001"] = "premium",
}

-- ================================================================
--  SERVIÇOS
-- ================================================================
local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local HttpService   = game:GetService("HttpService")
local RunService    = game:GetService("RunService")

local player        = Players.LocalPlayer
local gui           = player:WaitForChild("PlayerGui")

-- Limpar instâncias antigas
for _, name in ipairs({"CyrusHubUI", "CyrusHub"}) do
    if gui:FindFirstChild(name) then
        gui[name]:Destroy()
    end
end

-- ================================================================
--  CORES — TEMA CYRUS
-- ================================================================
local C = {
    BG          = Color3.fromRGB(10,  10,  14),
    BG2         = Color3.fromRGB(16,  16,  22),
    BG3         = Color3.fromRGB(22,  22,  30),
    BG4         = Color3.fromRGB(28,  28,  38),
    PURPLE      = Color3.fromRGB(140,  0, 255),
    PURPLE_DARK = Color3.fromRGB( 90,  0, 180),
    PURPLE_GLOW = Color3.fromRGB(180, 80, 255),
    ACCENT      = Color3.fromRGB(180, 80, 255),
    TEXT        = Color3.fromRGB(240, 240, 255),
    TEXT2       = Color3.fromRGB(160, 160, 180),
    TEXT3       = Color3.fromRGB(100, 100, 120),
    GREEN       = Color3.fromRGB( 80, 255, 140),
    RED         = Color3.fromRGB(255,  80,  80),
    YELLOW      = Color3.fromRGB(255, 210,  60),
    BLUE        = Color3.fromRGB( 40, 160, 255),
    ORANGE      = Color3.fromRGB(255, 120,  30),
}

-- ================================================================
--  HELPERS
-- ================================================================
local function corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 10)
    return c
end

local function stroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color     = col or C.PURPLE
    s.Thickness = th  or 1.5
    return s
end

local function gradient(p, c0, c1, rot)
    local g = Instance.new("UIGradient", p)
    g.Color    = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    return g
end

local function padding(p, l, r, t, b)
    local pd = Instance.new("UIPadding", p)
    if l then pd.PaddingLeft   = UDim.new(0, l) end
    if r then pd.PaddingRight  = UDim.new(0, r) end
    if t then pd.PaddingTop    = UDim.new(0, t) end
    if b then pd.PaddingBottom = UDim.new(0, b) end
end

local function tw(obj, t, props, style, dir)
    local ti = TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw2 = TweenService:Create(obj, ti, props)
    tw2:Play()
    return tw2
end

local function notify(title, text, duration)
    spawn(function()
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {
                Title = title, Text = text, Duration = duration or 3
            })
        end)
    end)
end

-- Drag helper (Delta-safe: usa eventos do próprio objeto)
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = target.Position
        end
    end)
    handle.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    handle.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = inp.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- ================================================================
--  VALIDAÇÃO DE KEY (GitHub + fallback local)
-- ================================================================
local function validarKey(key)
    key = key:upper():gsub("%s", "")

    -- Tenta GitHub primeiro
    local ok, result = pcall(function()
        return game:HttpGet(KEYS_URL)
    end)

    if ok and result and #result > 5 then
        for linha in result:gmatch("[^\n]+") do
            linha = linha:gsub("\r", ""):gsub("%s", "")
            local k, tipo = linha:match("^(.+)|(.+)$")
            if k and k:upper() == key then
                return true, tipo
            end
        end
        return false, nil
    end

    -- Fallback local
    if LOCAL_KEYS[key] then
        return true, LOCAL_KEYS[key]
    end

    return false, nil
end

local function buscarNoticias()
    local ok, result = pcall(function()
        return game:HttpGet(NEWS_URL)
    end)
    if ok and result and #result > 0 then
        return result
    end
    return "🔥 Bem-vindo ao Cyrus Hub!\n⚡ Novos scripts em breve!\n💎 Premium: acesso a scripts exclusivos"
end

-- ================================================================
--  SCREENGUI RAIZ
-- ================================================================
local sg = Instance.new("ScreenGui")
sg.Name           = "CyrusHubUI"
sg.ResetOnSpawn   = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = gui

-- Overlay de fundo
local overlay = Instance.new("Frame", sg)
overlay.Size                   = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3       = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.45
overlay.BorderSizePixel        = 0
overlay.ZIndex                 = 1

-- ================================================================
--  PAINEL DE LOGIN
-- ================================================================
local loginPanel = Instance.new("Frame", sg)
loginPanel.Size             = UDim2.new(0, 320, 0, 345)
loginPanel.Position         = UDim2.new(0.5, -160, 0.5, -172)
loginPanel.BackgroundColor3 = C.BG2
loginPanel.BorderSizePixel  = 0
loginPanel.ZIndex           = 10
corner(loginPanel, 16)
stroke(loginPanel, C.PURPLE, 2)

-- Faixa roxa no topo do login
local loginTop = Instance.new("Frame", loginPanel)
loginTop.Size             = UDim2.new(1, 0, 0, 48)
loginTop.BackgroundColor3 = C.BG3
loginTop.BorderSizePixel  = 0
loginTop.ZIndex           = 11
corner(loginTop, 16)
gradient(loginTop, C.PURPLE_DARK, C.BG3, 90)
makeDraggable(loginTop, loginPanel)

-- Ícone + título no header
local loginIcon = Instance.new("TextLabel", loginTop)
loginIcon.Size               = UDim2.new(0, 30, 0, 30)
loginIcon.Position           = UDim2.new(0, 12, 0.5, -15)
loginIcon.BackgroundColor3   = C.PURPLE
loginIcon.Text               = "◆"
loginIcon.TextColor3         = Color3.new(1, 1, 1)
loginIcon.Font               = Enum.Font.GothamBold
loginIcon.TextSize           = 14
loginIcon.BorderSizePixel    = 0
loginIcon.ZIndex             = 12
corner(loginIcon, 8)

local loginTitle = Instance.new("TextLabel", loginTop)
loginTitle.Size               = UDim2.new(1, -60, 1, 0)
loginTitle.Position           = UDim2.new(0, 50, 0, 0)
loginTitle.BackgroundTransparency = 1
loginTitle.Text               = "CYRUS HUB  " .. VERSION
loginTitle.TextColor3         = C.TEXT
loginTitle.Font               = Enum.Font.GothamBold
loginTitle.TextSize           = 15
loginTitle.TextXAlignment     = Enum.TextXAlignment.Left
loginTitle.ZIndex             = 12

-- Subtítulo
local loginSub = Instance.new("TextLabel", loginPanel)
loginSub.Size               = UDim2.new(1, 0, 0, 20)
loginSub.Position           = UDim2.new(0, 0, 0, 54)
loginSub.BackgroundTransparency = 1
loginSub.Text               = "Insira sua key para continuar"
loginSub.TextColor3         = C.TEXT3
loginSub.Font               = Enum.Font.Gotham
loginSub.TextSize           = 11
loginSub.ZIndex             = 11

-- Input da key
local keyInput = Instance.new("TextBox", loginPanel)
keyInput.Size              = UDim2.new(1, -28, 0, 42)
keyInput.Position          = UDim2.new(0, 14, 0, 80)
keyInput.BackgroundColor3  = C.BG4
keyInput.BorderSizePixel   = 0
keyInput.Text              = ""
keyInput.PlaceholderText   = "🔑  Ex: CYRUS-XXXX-XXXX"
keyInput.TextColor3        = C.TEXT
keyInput.PlaceholderColor3 = C.TEXT3
keyInput.Font              = Enum.Font.Gotham
keyInput.TextSize          = 13
keyInput.ClearTextOnFocus  = false
keyInput.ZIndex            = 11
corner(keyInput, 9)
stroke(keyInput, C.BG4, 1.5)
padding(keyInput, 12)

-- Botão Validar
local btnValidar = Instance.new("TextButton", loginPanel)
btnValidar.Size             = UDim2.new(1, -28, 0, 42)
btnValidar.Position         = UDim2.new(0, 14, 0, 130)
btnValidar.BackgroundColor3 = C.PURPLE
btnValidar.BorderSizePixel  = 0
btnValidar.Text             = "✓   VALIDAR KEY"
btnValidar.TextColor3       = Color3.new(1, 1, 1)
btnValidar.Font             = Enum.Font.GothamBold
btnValidar.TextSize         = 13
btnValidar.ZIndex           = 11
corner(btnValidar, 9)
gradient(btnValidar, C.PURPLE, C.PURPLE_DARK, 90)

-- Status
local statusLbl = Instance.new("TextLabel", loginPanel)
statusLbl.Size               = UDim2.new(1, -28, 0, 18)
statusLbl.Position           = UDim2.new(0, 14, 0, 178)
statusLbl.BackgroundTransparency = 1
statusLbl.Text               = ""
statusLbl.TextColor3         = C.TEXT
statusLbl.Font               = Enum.Font.Gotham
statusLbl.TextSize           = 11
statusLbl.ZIndex             = 11

-- Divisor "Obter Key"
local divFrame = Instance.new("Frame", loginPanel)
divFrame.Size             = UDim2.new(1, -28, 0, 1)
divFrame.Position         = UDim2.new(0, 14, 0, 204)
divFrame.BackgroundColor3 = C.BG4
divFrame.BorderSizePixel  = 0
divFrame.ZIndex           = 11

local divLbl = Instance.new("TextLabel", loginPanel)
divLbl.Size             = UDim2.new(0, 80, 0, 16)
divLbl.Position         = UDim2.new(0.5, -40, 0, 196)
divLbl.BackgroundColor3 = C.BG2
divLbl.Text             = " OBTER KEY "
divLbl.TextColor3       = C.TEXT3
divLbl.Font             = Enum.Font.GothamBold
divLbl.TextSize         = 9
divLbl.BorderSizePixel  = 0
divLbl.ZIndex           = 12

-- Botões obter key
local function criarBtnKey(texto, y, cor, link, etapas)
    local btn = Instance.new("TextButton", loginPanel)
    btn.Size             = UDim2.new(1, -28, 0, 30)
    btn.Position         = UDim2.new(0, 14, 0, y)
    btn.BackgroundColor3 = cor
    btn.BorderSizePixel  = 0
    btn.Text             = texto
    btn.TextColor3       = Color3.new(1, 1, 1)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 11
    btn.ZIndex           = 11
    corner(btn, 8)

    -- Badge de etapas
    local badge = Instance.new("TextLabel", btn)
    badge.Size             = UDim2.new(0, 52, 0, 16)
    badge.Position         = UDim2.new(1, -58, 0.5, -8)
    badge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    badge.BackgroundTransparency = 0.4
    badge.Text             = etapas .. " etapas"
    badge.TextColor3       = Color3.new(1, 1, 1)
    badge.Font             = Enum.Font.Gotham
    badge.TextSize         = 9
    badge.BorderSizePixel  = 0
    badge.ZIndex           = 12
    corner(badge, 5)

    btn.MouseButton1Click:Connect(function()
        pcall(setclipboard, link)
        statusLbl.Text       = "📋  Link copiado! Cole no navegador."
        statusLbl.TextColor3 = C.GREEN
    end)
    return btn
end

criarBtnKey("🎁  Key 12H — Grátis",    218, C.BG4,   LINK_12H,     "4")
criarBtnKey("⏰  Key 24H",              256, C.BG4,   LINK_24H,     "6")
criarBtnKey("💎  Premium 30D — R$10",  294, C.ORANGE, LINK_PREMIUM, "VIP")

-- ================================================================
--  ANIMAÇÃO "VAZIO ROXO" (Satoru Gojo - Hollow Purple)
-- ================================================================
local function AnimacaoVazioRoxo(callback)
    spawn(function()
        -- Frame de animação sobre tudo
        local anim = Instance.new("Frame", sg)
        anim.Size                   = UDim2.new(1, 0, 1, 0)
        anim.BackgroundColor3       = Color3.new(0, 0, 0)
        anim.BackgroundTransparency = 0.05
        anim.BorderSizePixel        = 0
        anim.ZIndex                 = 100

        -- === BOLA AZUL (esquerda) ===
        local blue = Instance.new("Frame", anim)
        blue.Size             = UDim2.new(0, 80, 0, 80)
        blue.Position         = UDim2.new(0, -120, 0.5, -40)
        blue.BackgroundColor3 = C.BLUE
        blue.BorderSizePixel  = 0
        blue.ZIndex           = 103
        corner(blue, 40)

        -- Brilho azul externo
        local blueGlow = Instance.new("Frame", anim)
        blueGlow.Size             = UDim2.new(0, 130, 0, 130)
        blueGlow.Position         = UDim2.new(0, -145, 0.5, -65)
        blueGlow.BackgroundColor3 = C.BLUE
        blueGlow.BackgroundTransparency = 0.6
        blueGlow.BorderSizePixel  = 0
        blueGlow.ZIndex           = 102
        corner(blueGlow, 65)

        local blueGlow2 = Instance.new("Frame", anim)
        blueGlow2.Size             = UDim2.new(0, 180, 0, 180)
        blueGlow2.Position         = UDim2.new(0, -170, 0.5, -90)
        blueGlow2.BackgroundColor3 = C.BLUE
        blueGlow2.BackgroundTransparency = 0.85
        blueGlow2.BorderSizePixel  = 0
        blueGlow2.ZIndex           = 101
        corner(blueGlow2, 90)

        -- === BOLA VERMELHA (direita) ===
        local red = Instance.new("Frame", anim)
        red.Size             = UDim2.new(0, 80, 0, 80)
        red.Position         = UDim2.new(1, 120, 0.5, -40)
        red.BackgroundColor3 = C.RED
        red.BorderSizePixel  = 0
        red.ZIndex           = 103
        corner(red, 40)

        local redGlow = Instance.new("Frame", anim)
        redGlow.Size             = UDim2.new(0, 130, 0, 130)
        redGlow.Position         = UDim2.new(1, 95, 0.5, -65)
        redGlow.BackgroundColor3 = C.RED
        redGlow.BackgroundTransparency = 0.6
        redGlow.BorderSizePixel  = 0
        redGlow.ZIndex           = 102
        corner(redGlow, 65)

        local redGlow2 = Instance.new("Frame", anim)
        redGlow2.Size             = UDim2.new(0, 180, 0, 180)
        redGlow2.Position         = UDim2.new(1, 70, 0.5, -90)
        redGlow2.BackgroundColor3 = C.RED
        redGlow2.BackgroundTransparency = 0.85
        redGlow2.BorderSizePixel  = 0
        redGlow2.ZIndex           = 101
        corner(redGlow2, 90)

        -- Texto de energia
        local energyTxt = Instance.new("TextLabel", anim)
        energyTxt.Size               = UDim2.new(1, 0, 0, 40)
        energyTxt.Position           = UDim2.new(0, 0, 0.65, 0)
        energyTxt.BackgroundTransparency = 1
        energyTxt.Text               = ""
        energyTxt.TextColor3         = C.PURPLE_GLOW
        energyTxt.Font               = Enum.Font.GothamBold
        energyTxt.TextSize           = 18
        energyTxt.ZIndex             = 110

        -- FASE 1: Pulsar e mostrar texto
        local pulsando = true
        spawn(function()
            while pulsando do
                tw(blue,      0.35, {Size = UDim2.new(0, 96, 0, 96)},  Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(blueGlow,  0.35, {Size = UDim2.new(0, 148, 0, 148)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(blueGlow2, 0.35, {Size = UDim2.new(0, 200, 0, 200)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(red,       0.35, {Size = UDim2.new(0, 96, 0, 96)},  Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(redGlow,   0.35, {Size = UDim2.new(0, 148, 0, 148)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(redGlow2,  0.35, {Size = UDim2.new(0, 200, 0, 200)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                wait(0.35)
                tw(blue,      0.35, {Size = UDim2.new(0, 80, 0, 80)},  Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(blueGlow,  0.35, {Size = UDim2.new(0, 130, 0, 130)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(blueGlow2, 0.35, {Size = UDim2.new(0, 180, 0, 180)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(red,       0.35, {Size = UDim2.new(0, 80, 0, 80)},  Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(redGlow,   0.35, {Size = UDim2.new(0, 130, 0, 130)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(redGlow2,  0.35, {Size = UDim2.new(0, 180, 0, 180)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                wait(0.35)
            end
        end)

        energyTxt.Text = "CONVERGINDO ENERGIAS..."
        wait(1.0)

        -- FASE 2: Mover ao centro
        energyTxt.Text = "VAZIO..."
        local moveInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

        TweenService:Create(blue,      moveInfo, {Position = UDim2.new(0.5, -40, 0.5, -40)}):Play()
        TweenService:Create(blueGlow,  moveInfo, {Position = UDim2.new(0.5, -65, 0.5, -65)}):Play()
        TweenService:Create(blueGlow2, moveInfo, {Position = UDim2.new(0.5, -90, 0.5, -90)}):Play()
        TweenService:Create(red,       moveInfo, {Position = UDim2.new(0.5, -40, 0.5, -40)}):Play()
        TweenService:Create(redGlow,   moveInfo, {Position = UDim2.new(0.5, -65, 0.5, -65)}):Play()
        TweenService:Create(redGlow2,  moveInfo, {Position = UDim2.new(0.5, -90, 0.5, -90)}):Play()
        wait(1.2)

        -- FASE 3: Impacto
        pulsando = false
        energyTxt.Text = ""
        pcall(function() blue:Destroy()      end)
        pcall(function() blueGlow:Destroy()  end)
        pcall(function() blueGlow2:Destroy() end)
        pcall(function() red:Destroy()       end)
        pcall(function() redGlow:Destroy()   end)
        pcall(function() redGlow2:Destroy()  end)

        -- Ondas de choque roxas
        for i = 1, 5 do
            spawn(function()
                wait(i * 0.06)
                local sz   = 60 + i * 8
                local onda =
