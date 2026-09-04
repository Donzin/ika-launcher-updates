-- IKA Reforge Visibility v0.6.4
if IKAForge and IKAForge.__commerceLoaded then return end
-- IKA Gaming - Forjador IKA
-- Cliente WoW TBC 2.4.3 (Interface 20400)

IKAForge = IKAForge or {}

local Forge = IKAForge
Forge.__commerceLoaded = true
Forge.reforgeCache = Forge.reforgeCache or {}
Forge.tooltipPending = Forge.tooltipPending or {}
Forge.dragSource = nil
Forge.cursorSource = nil
local GOLD = { 0.88, 0.67, 0.25 }
local GOLD_BRIGHT = { 1.00, 0.84, 0.38 }
local GREEN = { 0.60, 0.94, 0.30 }
local MUTED = { 0.62, 0.58, 0.49 }
local FORGE_NPC_NAME = "Forjador IKA"
local IKA_BLESSING_ITEM_ENTRY = 900102
local IKA_BLESSING_BONUS_BASIS_POINTS = 500
local IKA_BLESSING_COLOR = "|cffa335ee"
local IKA_BLESSING_ICON = "Interface\\Icons\\INV_Misc_Gem_Amethyst_02"
local IKA_WRATH_ITEM_ENTRY = 900103
local IKA_WRATH_COLOR = "|cffa335ee"
local IKA_WRATH_ICON = "Interface\\Icons\\INV_Misc_Gem_Bloodstone_02"
local SERVER_ROOT_BAG = 255
local SERVER_BACKPACK_START = 23
local SERVER_BAG_START = 19

local SLOT_NAMES = {
    [0] = "Cabeça",
    [1] = "Pescoço",
    [2] = "Ombros",
    [3] = "Camisa",
    [4] = "Peitoral",
    [5] = "Cintura",
    [6] = "Pernas",
    [7] = "Pés",
    [8] = "Pulsos",
    [9] = "Mãos",
    [10] = "Anel 1",
    [11] = "Anel 2",
    [12] = "Berloque 1",
    [13] = "Berloque 2",
    [14] = "Costas",
    [15] = "Mão principal",
    [16] = "Mão secundária",
    [17] = "Distância",
    [18] = "Tabardo",
}

local STAT_NAMES = {
    [0] = "Mana",
    [1] = "Vida",
    [3] = "Agilidade",
    [4] = "Força",
    [5] = "Intelecto",
    [6] = "Espírito",
    [7] = "Vigor",
    [12] = "Defesa",
    [13] = "Esquiva",
    [14] = "Aparo",
    [15] = "Bloqueio",
    [16] = "Acerto corpo a corpo",
    [17] = "Acerto à distância",
    [18] = "Acerto mágico",
    [19] = "Crítico corpo a corpo",
    [20] = "Crítico à distância",
    [21] = "Crítico mágico",
    [31] = "Resiliência",
    [32] = "Aceleração corpo a corpo",
    [33] = "Aceleração à distância",
    [34] = "Aceleração mágica",
    [35] = "Acerto",
    [36] = "Crítico",
    [37] = "Resiliência",
}

local ERROR_TEXT = {
    INVALID_SLOT = "Slot de equipamento inválido.",
    NOT_AT_FORGE = "Fale com o Forjador IKA para usar esta janela.",
    NO_ITEM = "Não existe equipamento neste slot.",
    NOT_ELIGIBLE = "Este item não pode ser reforjado.",
    MAX_LEVEL = "Este item já alcançou o nível máximo +10.",
    MAX_IKA_GOD = "Itens do pacote IKA GOD podem ser reforjados somente até +3.",
    NO_TIER = "A configuração deste nível não foi encontrada.",
    NOT_ENOUGH_GOLD = "Você não possui ouro suficiente.",
    NOT_ENOUGH_MATERIAL = "Você não possui os materiais necessários.",
    NOT_ENOUGH_BLESSING = "Você não possui uma Bênção de IKA.",
    NOT_ENOUGH_WRATH = "Você não possui uma Ira de IKA.",
    WRATH_NOT_NEEDED = "A Ira de IKA só pode proteger itens a partir do nível +1.",
    INVALID_SOCKET = "O encaixe selecionado é inválido.",
    SOCKETS_LOCKED = "Os três encaixes IKA são liberados somente no nível +10.",
    NO_GEM = "Não foi possível localizar a gema na bolsa.",
    NOT_GEM = "Arraste uma gema TBC comum para o encaixe.",
    META_NOT_ALLOWED = "Meta-gemas não podem ser usadas nos encaixes prismáticos IKA.",
    UNIQUE_GEM = "As regras de gema única impedem este encaixe.",
    DATABASE = "O servidor não conseguiu registrar a tentativa.",
}

local function CreateGoldPanel(parent, name)
    local panel = CreateFrame("Frame", name, parent)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    -- v0.5.2: ferro escovado escuro. Mantem o contraste do tema classico
    -- sem transformar os paineis em blocos totalmente pretos.
    panel:SetBackdropColor(0.055, 0.052, 0.047, 1.00)
    panel:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.95)

    local shade = panel:CreateTexture(nil, "BACKGROUND")
    shade:SetTexture(0.025, 0.026, 0.025, 0.64)
    shade:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, -5)
    shade:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -5, 5)
    panel.ikaShade = shade
    return panel
end

local function CreateText(parent, fontObject, text, size)
    local label = parent:CreateFontString(nil, "OVERLAY", fontObject)
    if size then
        label:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    end
    label:SetText(text or "")
    return label
end

local function CreateDivider(parent, width)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture(0.70, 0.48, 0.16, 0.65)
    line:SetWidth(width)
    line:SetHeight(1)
    return line
end

local function FormatBasisPoints(value)
    value = tonumber(value) or 0
    local formatted = string.format("%.2f", value / 100)
    return string.gsub(formatted, "%.", ",") .. "%"
end

local function FormatMoney(copper)
    copper = tonumber(copper) or 0
    if copper == 0 then
        return "|cff79e85aGratuito no MVP|r"
    end

    local gold = math.floor(copper / 10000)
    -- O cliente TBC 2.4.3 nao expoe math.mod. O operador de modulo do
    -- proprio Lua 5.1 preserva o mesmo calculo sem depender dessa funcao.
    local silver = math.floor((copper % 10000) / 100)
    local bronze = copper % 100
    return string.format("%d ouro, %d prata, %d cobre", gold, silver, bronze)
end

local function GetItemName(link)
    if not link then
        return "Nenhum equipamento"
    end
    return string.match(link, "|h%[(.-)%]|h") or link
end

local function PositionKey(serverBag, serverSlot)
    return tostring(serverBag) .. ":" .. tostring(serverSlot)
end

local function IsEquipmentLink(link)
    if not link then
        return false
    end

    local equipLocation = select(9, GetItemInfo(link))
    return equipLocation and equipLocation ~= "" and equipLocation ~= "INVTYPE_BAG"
end

local function FormatNumber(value)
    value = tonumber(value) or 0
    return tostring(math.floor(value + 0.5))
end

local function FormatSigned(value)
    value = tonumber(value) or 0
    if value >= 0 then
        return "+" .. FormatNumber(value)
    end
    return FormatNumber(value)
end

local function FormatDamage(minimum, maximum)
    minimum = (tonumber(minimum) or 0) / 100
    maximum = (tonumber(maximum) or 0) / 100
    return string.gsub(string.format("%.1f–%.1f", minimum, maximum), "%.", ",")
end

local function SplitProtocol(message)
    local fields = {}
    for value in string.gmatch(message, "([^|]+)") do
        table.insert(fields, value)
    end
    return fields
end

local function SetButtonEnabled(button, enabled)
    if enabled then
        button:Enable()
        button:GetFontString():SetTextColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
        button:SetAlpha(1)
    else
        button:Disable()
        button:GetFontString():SetTextColor(MUTED[1], MUTED[2], MUTED[3])
        button:SetAlpha(0.62)
    end
end

local function StyleIkaForgeButton(button)
    -- Texturas proprias evitam que o UIPanelButtonTemplate volte a desenhar
    -- a arte preta/vermelha quando o estado do botao muda.
    local function CreateStateTexture(red, green, blue, alpha)
        local texture = button:CreateTexture(nil, "BACKGROUND")
        texture:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
        texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
        texture:SetTexture(red, green, blue, alpha)
        return texture
    end

    local normal = CreateStateTexture(0.018, 0.30, 0.060, 1.00)
    local pushed = CreateStateTexture(0.010, 0.17, 0.035, 1.00)
    local disabled = CreateStateTexture(0.025, 0.12, 0.040, 0.92)
    local highlight = CreateStateTexture(0.10, 0.42, 0.090, 0.50)
    highlight:SetBlendMode("ADD")

    button:SetNormalTexture(normal)
    button:SetPushedTexture(pushed)
    button:SetDisabledTexture(disabled)
    button:SetHighlightTexture(highlight)

    button:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    button:SetBackdropColor(0, 0, 0, 0)
    button:SetBackdropBorderColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3], 0.95)
    button:GetFontString():SetTextColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
end

function Forge:CreateUI()
    if self.frame then
        return
    end

    local frame = CreateGoldPanel(UIParent, "IKAForgeFrame")
    -- v0.5.1: acabamento Classico Refinado. A janela ganhou respiro
    -- horizontal e vertical para manter todos os textos dentro dos paineis.
    frame:SetWidth(900)
    frame:SetHeight(650)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 18)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        if IsAltKeyDown() then
            this:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()
    self.frame = frame
    table.insert(UISpecialFrames, "IKAForgeFrame")

    local vignette = frame:CreateTexture(nil, "BACKGROUND")
    vignette:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
    vignette:SetAllPoints(frame)
    vignette:SetVertexColor(0.18, 0.18, 0.17, 0.18)

    local emblem = CreateFrame("Button", nil, frame)
    emblem:SetWidth(62)
    emblem:SetHeight(62)
    emblem:SetPoint("TOP", frame, "TOP", 0, 30)
    local emblemRing = emblem:CreateTexture(nil, "BACKGROUND")
    emblemRing:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    emblemRing:SetAllPoints(emblem)
    emblemRing:SetVertexColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
    local emblemIcon = emblem:CreateTexture(nil, "ARTWORK")
    emblemIcon:SetTexture("Interface\\Icons\\Trade_BlackSmithing")
    emblemIcon:SetPoint("TOPLEFT", emblem, "TOPLEFT", 13, -13)
    emblemIcon:SetPoint("BOTTOMRIGHT", emblem, "BOTTOMRIGHT", -13, 13)

    local title = CreateText(frame, "GameFontNormalLarge", "FORJADOR IKA")
    title:SetFont("Fonts\\MORPHEUS.TTF", 28, "OUTLINE")
    title:SetTextColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
    title:SetPoint("TOP", frame, "TOP", 0, -31)

    local subtitle = CreateText(frame, "GameFontNormal", "APERFEIÇOAMENTO DE EQUIPAMENTO", 13)
    subtitle:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)

    local headerLine = CreateDivider(frame, 820)
    headerLine:SetPoint("TOP", subtitle, "BOTTOM", 0, -14)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -7, -7)
    close:SetScript("OnClick", function() Forge:Close() end)

    local left = CreateGoldPanel(frame)
    left:SetWidth(260)
    left:SetHeight(280)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -105)
    self.leftPanel = left

    local leftTitle = CreateText(left, "GameFontNormal", "ITEM PARA REFORJAR", 14)
    leftTitle:SetTextColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
    leftTitle:SetPoint("TOP", left, "TOP", 0, -18)

    local itemButton = CreateFrame("Button", "IKAForgeItemButton", left)
    itemButton:SetWidth(94)
    itemButton:SetHeight(94)
    itemButton:SetPoint("TOP", left, "TOP", 0, -52)
    itemButton:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    itemButton:SetBackdropColor(0.01, 0.01, 0.01, 1)
    itemButton:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
    local itemIcon = itemButton:CreateTexture(nil, "ARTWORK")
    itemIcon:SetPoint("TOPLEFT", itemButton, "TOPLEFT", 9, -9)
    itemIcon:SetPoint("BOTTOMRIGHT", itemButton, "BOTTOMRIGHT", -9, 9)
    itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    itemButton.icon = itemIcon
    itemButton:SetScript("OnEnter", function()
        Forge:ShowSelectedTooltip(this)
    end)
    itemButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    itemButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    itemButton:RegisterForDrag("LeftButton")
    itemButton:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            Forge:ClearSelection()
        elseif CursorHasItem() then
            Forge:AcceptCursorItem()
        else
            Forge:SelectNext(1)
        end
    end)
    itemButton:SetScript("OnReceiveDrag", function()
        Forge:AcceptCursorItem()
    end)
    self.itemButton = itemButton

    local previous = CreateFrame("Button", nil, left, "UIPanelButtonTemplate")
    previous:SetWidth(34)
    previous:SetHeight(24)
    previous:SetText("<")
    previous:SetPoint("RIGHT", itemButton, "LEFT", -10, 0)
    previous:SetScript("OnClick", function() Forge:SelectNext(-1) end)
    StyleIkaForgeButton(previous)

    local nextButton = CreateFrame("Button", nil, left, "UIPanelButtonTemplate")
    nextButton:SetWidth(34)
    nextButton:SetHeight(24)
    nextButton:SetText(">")
    nextButton:SetPoint("LEFT", itemButton, "RIGHT", 10, 0)
    nextButton:SetScript("OnClick", function() Forge:SelectNext(1) end)
    StyleIkaForgeButton(nextButton)

    local itemName = CreateText(left, "GameFontNormal", "Nenhum equipamento", 13)
    itemName:SetTextColor(0.72, 0.42, 0.90)
    itemName:SetWidth(232)
    itemName:SetHeight(38)
    itemName:SetJustifyH("CENTER")
    itemName:SetPoint("TOP", itemButton, "BOTTOM", 0, -12)
    self.itemName = itemName

    local slotName = CreateText(left, "GameFontHighlightSmall", "", 11)
    slotName:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    slotName:SetPoint("TOP", itemName, "BOTTOM", 0, -3)
    self.slotName = slotName

    local socketLabel = CreateText(left, "GameFontHighlightSmall", "ENCAIXES IKA · +10", 10)
    socketLabel:SetTextColor(0.72, 0.66, 0.54)
    socketLabel:SetPoint("BOTTOM", left, "BOTTOM", 0, 48)

    self.socketButtons = {}
    for index = 1, 3 do
        local socket = CreateFrame("Button", nil, left)
        socket:SetWidth(30)
        socket:SetHeight(30)
        socket:SetPoint("BOTTOM", left, "BOTTOM", (index - 2) * 38, 12)
        socket:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 11,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        socket:SetBackdropColor(0.01, 0.01, 0.01, 1)
        socket:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.80)
        local icon = socket:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", socket, "TOPLEFT", 5, -5)
        icon:SetPoint("BOTTOMRIGHT", socket, "BOTTOMRIGHT", -5, 5)
        icon:SetTexture("Interface\\Icons\\INV_Misc_Lockbox_1")
        socket.icon = icon
        socket.socketIndex = index - 1
        socket:RegisterForClicks("LeftButtonUp")
        socket:RegisterForDrag("LeftButton")
        socket:SetScript("OnClick", function()
            if CursorHasItem() then
                Forge:AcceptSocketGem(this.socketIndex)
            end
        end)
        socket:SetScript("OnReceiveDrag", function()
            Forge:AcceptSocketGem(this.socketIndex)
        end)
        socket:SetScript("OnEnter", function()
            Forge:ShowSocketTooltip(this)
        end)
        socket:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.socketButtons[index] = socket
    end

    local center = CreateGoldPanel(frame)
    center:SetWidth(280)
    center:SetHeight(280)
    center:SetPoint("TOPLEFT", left, "TOPRIGHT", 10, 0)
    self.centerPanel = center

    local rune = center:CreateTexture(nil, "BACKGROUND")
    rune:SetTexture("Interface\\SpellShadow\\Spell-Shadow-Acceptable")
    rune:SetWidth(190)
    rune:SetHeight(190)
    rune:SetPoint("CENTER", center, "CENTER", 0, 8)
    rune:SetVertexColor(0.52, 0.34, 0.07, 0.40)
    rune:SetBlendMode("ADD")

    local currentLevel = CreateText(center, "GameFontNormalLarge", "+0")
    currentLevel:SetFont("Fonts\\MORPHEUS.TTF", 36, "OUTLINE")
    currentLevel:SetTextColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
    currentLevel:SetPoint("CENTER", center, "CENTER", -82, 18)
    self.currentLevelText = currentLevel

    local arrow = CreateText(center, "GameFontNormalLarge", "→")
    arrow:SetFont("Fonts\\FRIZQT__.TTF", 42, "OUTLINE")
    arrow:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
    arrow:SetPoint("CENTER", center, "CENTER", 0, 18)

    local targetLevel = CreateText(center, "GameFontNormalLarge", "+1")
    targetLevel:SetFont("Fonts\\MORPHEUS.TTF", 36, "OUTLINE")
    targetLevel:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
    targetLevel:SetPoint("CENTER", center, "CENTER", 82, 18)
    self.targetLevelText = targetLevel

    local chanceLabel = CreateText(center, "GameFontNormal", "CHANCE DE SUCESSO", 12)
    chanceLabel:SetTextColor(0.86, 0.80, 0.67)
    chanceLabel:SetPoint("BOTTOM", center, "BOTTOM", -18, 41)
    local chanceValue = CreateText(center, "GameFontNormalLarge", "—")
    chanceValue:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    chanceValue:SetTextColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
    chanceValue:SetPoint("LEFT", chanceLabel, "RIGHT", 8, 0)
    self.chanceText = chanceValue

    local right = CreateGoldPanel(frame)
    right:SetWidth(280)
    right:SetHeight(280)
    right:SetPoint("TOPLEFT", center, "TOPRIGHT", 10, 0)
    self.rightPanel = right

    local rightTitle = CreateText(right, "GameFontNormal", "PRÉVIA DO REFORÇO", 14)
    rightTitle:SetTextColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
    rightTitle:SetPoint("TOP", right, "TOP", 0, -18)

    local rowLabels = { "Poder total", "Atributo", "Chance", "Falha" }
    local rowDefaults = { "100,00%  →  110,60%", "—", "100,00%", "Nível cai em 1" }
    self.previewLabels = {}
    self.previewValues = {}
    for index = 1, 4 do
        local y = -50 - ((index - 1) * 52)
        local rowLabel = CreateText(right, "GameFontHighlightSmall", rowLabels[index], 11)
        rowLabel:SetTextColor(0.82, 0.77, 0.68)
        rowLabel:SetPoint("TOPLEFT", right, "TOPLEFT", 18, y)
        rowLabel:SetWidth(244)
        rowLabel:SetJustifyH("LEFT")
        self.previewLabels[index] = rowLabel
        local rowValue = CreateText(right, "GameFontNormal", rowDefaults[index], 11)
        rowValue:SetTextColor(index == 4 and GREEN[1] or 0.95, index == 4 and GREEN[2] or 0.92, index == 4 and GREEN[3] or 0.78)
        rowValue:SetWidth(244)
        rowValue:SetHeight(18)
        rowValue:SetJustifyH("LEFT")
        rowValue:SetPoint("TOPLEFT", right, "TOPLEFT", 18, y - 18)
        self.previewValues[index] = rowValue
        if index < 4 then
            local rowLine = CreateDivider(right, 238)
            rowLine:SetPoint("TOP", right, "TOP", 0, y - 42)
            rowLine:SetAlpha(0.28)
        end
    end

    local rail = CreateGoldPanel(frame)
    rail:SetWidth(68)
    rail:SetHeight(430)
    rail:SetPoint("TOPLEFT", frame, "TOPRIGHT", 6, -105)
    -- O trilho tecnico continua disponivel internamente, mas fica oculto no
    -- tema classico para concentrar a leitura no item e na previa do reforco.
    rail:Hide()
    self.rail = rail

    local railTitle = CreateText(rail, "GameFontNormalSmall", "NÍVEL", 10)
    railTitle:SetTextColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
    railTitle:SetPoint("TOP", rail, "TOP", 0, -12)

    self.nodes = {}
    for level = 0, 10 do
        local node = CreateFrame("Frame", nil, rail)
        node:SetWidth(52)
        node:SetHeight(34)
        node:SetPoint("TOP", rail, "TOP", 0, -34 - (level * 36))
        local dot = node:CreateTexture(nil, "ARTWORK")
        dot:SetTexture("Interface\\BUTTONS\\UI-RadioButton")
        dot:SetWidth(22)
        dot:SetHeight(22)
        dot:SetPoint("LEFT", node, "LEFT", 2, 0)
        dot:SetTexCoord(0, 0.25, 0, 1)
        dot:SetVertexColor(0.55, 0.47, 0.31)
        local text = CreateText(node, "GameFontNormalSmall", "+" .. level, 11)
        text:SetPoint("LEFT", dot, "RIGHT", 1, 0)
        text:SetTextColor(0.68, 0.62, 0.50)
        node.dot = dot
        node.text = text
        self.nodes[level] = node
    end

    -- Painel inferior em tres colunas: Bencao, Ira e custo.
    local materials = CreateGoldPanel(frame)
    materials:SetWidth(840)
    materials:SetHeight(104)
    materials:SetPoint("TOPLEFT", left, "BOTTOMLEFT", 0, -10)
    self.materialsPanel = materials

    local materialsTitle = CreateText(materials, "GameFontNormal", "MATERIAIS OPCIONAIS", 13)
    materialsTitle:SetTextColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
    materialsTitle:SetPoint("TOP", materials, "TOP", 0, -12)

    local materialButton = CreateFrame("Button", nil, materials)
    materialButton:SetWidth(44)
    materialButton:SetHeight(44)
    materialButton:SetPoint("BOTTOMLEFT", materials, "BOTTOMLEFT", 18, 16)
    materialButton:SetNormalTexture(IKA_BLESSING_ICON)
    materialButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    materialButton:SetScript("OnClick", function() Forge:ToggleBlessing() end)
    materialButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. IKA_BLESSING_ITEM_ENTRY .. ":0:0:0:0:0:0:0")
        GameTooltip:Show()
    end)
    materialButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.materialButton = materialButton
    self.materialIcon = materialButton:GetNormalTexture()

    local materialText = CreateText(materials, "GameFontNormal", "Bênção de IKA  0/1", 12)
    materialText:SetPoint("LEFT", materialButton, "RIGHT", 10, 7)
    materialText:SetWidth(190)
    materialText:SetJustifyH("LEFT")
    materialText:SetTextColor(0.64, 0.21, 0.93)
    self.materialText = materialText

    local materialDescription = CreateText(materials, "GameFontHighlightSmall", "+5 pontos percentuais\nConsome 1 por tentativa", 10)
    materialDescription:SetPoint("TOPLEFT", materialText, "BOTTOMLEFT", 0, -3)
    materialDescription:SetWidth(190)
    materialDescription:SetHeight(28)
    materialDescription:SetJustifyH("LEFT")
    materialDescription:SetTextColor(0.82, 0.77, 0.68)
    self.materialDescription = materialDescription

    local wrathButton = CreateFrame("Button", nil, materials)
    wrathButton:SetWidth(44)
    wrathButton:SetHeight(44)
    wrathButton:SetPoint("BOTTOMLEFT", materials, "BOTTOMLEFT", 302, 16)
    wrathButton:SetNormalTexture(IKA_WRATH_ICON)
    wrathButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    wrathButton:SetScript("OnClick", function() Forge:ToggleWrath() end)
    wrathButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. IKA_WRATH_ITEM_ENTRY .. ":0:0:0:0:0:0:0")
        GameTooltip:Show()
    end)
    wrathButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.wrathButton = wrathButton
    self.wrathIcon = wrathButton:GetNormalTexture()

    local wrathText = CreateText(materials, "GameFontNormal", "Ira de IKA  0/1", 12)
    wrathText:SetPoint("LEFT", wrathButton, "RIGHT", 10, 7)
    wrathText:SetWidth(190)
    wrathText:SetJustifyH("LEFT")
    wrathText:SetTextColor(0.86, 0.20, 0.16)
    self.wrathText = wrathText

    local wrathDescription = CreateText(materials, "GameFontHighlightSmall", "Protege o nível\nConsome somente na falha", 10)
    wrathDescription:SetPoint("TOPLEFT", wrathText, "BOTTOMLEFT", 0, -3)
    wrathDescription:SetWidth(190)
    wrathDescription:SetHeight(28)
    wrathDescription:SetJustifyH("LEFT")
    wrathDescription:SetTextColor(0.82, 0.77, 0.68)
    self.wrathDescription = wrathDescription

    local costLabel = CreateText(materials, "GameFontHighlightSmall", "Custo", 11)
    costLabel:SetPoint("TOPRIGHT", materials, "TOPRIGHT", -24, -34)
    costLabel:SetTextColor(0.82, 0.77, 0.68)
    local costText = CreateText(materials, "GameFontNormal", "Gratuito no MVP", 13)
    costText:SetPoint("TOPRIGHT", materials, "TOPRIGHT", -24, -52)
    costText:SetWidth(230)
    costText:SetHeight(32)
    costText:SetJustifyH("RIGHT")
    costText:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
    self.costText = costText

    local blessingCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    blessingCheck:SetWidth(26)
    blessingCheck:SetHeight(26)
    blessingCheck:SetPoint("TOPLEFT", materials, "BOTTOMLEFT", 8, -9)
    blessingCheck:SetScript("OnClick", function()
        Forge:SetBlessingSelected(this:GetChecked() and true or false)
    end)
    self.blessingCheck = blessingCheck
    local blessingCheckText = CreateText(frame, "GameFontHighlightSmall", "Usar Bênção de IKA nesta tentativa", 11)
    blessingCheckText:SetTextColor(0.72, 0.40, 0.96)
    blessingCheckText:SetWidth(280)
    blessingCheckText:SetJustifyH("LEFT")
    blessingCheckText:SetPoint("LEFT", blessingCheck, "RIGHT", 0, 0)
    self.blessingCheckText = blessingCheckText

    local wrathCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    wrathCheck:SetWidth(26)
    wrathCheck:SetHeight(26)
    wrathCheck:SetPoint("TOPLEFT", materials, "BOTTOMLEFT", 430, -9)
    wrathCheck:SetScript("OnClick", function()
        Forge:SetWrathSelected(this:GetChecked() and true or false)
    end)
    self.wrathCheck = wrathCheck
    local wrathCheckText = CreateText(frame, "GameFontHighlightSmall", "Usar Ira de IKA como proteção", 11)
    wrathCheckText:SetTextColor(0.96, 0.30, 0.22)
    wrathCheckText:SetWidth(280)
    wrathCheckText:SetJustifyH("LEFT")
    wrathCheckText:SetPoint("LEFT", wrathCheck, "RIGHT", 0, 0)
    self.wrathCheckText = wrathCheckText

    local forgeButton = CreateFrame("Button", "IKAForgeActionButton", frame, "UIPanelButtonTemplate")
    forgeButton:SetWidth(320)
    forgeButton:SetHeight(46)
    forgeButton:SetPoint("BOTTOM", frame, "BOTTOM", -70, 18)
    forgeButton:SetText("REFORJAR")
    forgeButton:GetFontString():SetFont("Fonts\\MORPHEUS.TTF", 21, "OUTLINE")
    forgeButton:SetScript("OnClick", function() Forge:TryReforge() end)
    StyleIkaForgeButton(forgeButton)
    self.forgeButton = forgeButton

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetWidth(138)
    closeButton:SetHeight(35)
    closeButton:SetPoint("LEFT", forgeButton, "RIGHT", 18, 0)
    closeButton:SetText("FECHAR")
    closeButton:SetScript("OnClick", function() Forge:Close() end)
    StyleIkaForgeButton(closeButton)

    local status = CreateText(frame, "GameFontNormal", "", 12)
    status:SetWidth(820)
    status:SetHeight(28)
    status:SetPoint("BOTTOM", forgeButton, "TOP", 0, 5)
    status:SetJustifyH("CENTER")
    self.statusText = status

    SetButtonEnabled(forgeButton, false)
    self:HookContainerButtons()
end

function Forge:GetLinkForChoice(choice)
    if not choice then
        return nil
    end

    if choice.kind == "equipped" then
        return GetInventoryItemLink("player", choice.clientSlot)
    end
    return GetContainerItemLink(choice.clientBag, choice.clientSlot)
end

function Forge:GetTextureForChoice(choice)
    if not choice then
        return nil
    end

    if choice.kind == "equipped" then
        return GetInventoryItemTexture("player", choice.clientSlot)
    end

    return GetContainerItemInfo(choice.clientBag, choice.clientSlot)
end

function Forge:BuildItemChoices()
    self.itemChoices = {}

    for slot = 0, 18 do
        local link = GetInventoryItemLink("player", slot + 1)
        if link and IsEquipmentLink(link) then
            table.insert(self.itemChoices, {
                kind = "equipped",
                serverBag = SERVER_ROOT_BAG,
                serverSlot = slot,
                clientSlot = slot + 1,
                label = SLOT_NAMES[slot] or ("Equipado " .. slot),
            })
        end
    end

    for clientSlot = 1, GetContainerNumSlots(0) do
        local link = GetContainerItemLink(0, clientSlot)
        if link and IsEquipmentLink(link) then
            table.insert(self.itemChoices, {
                kind = "bag",
                serverBag = SERVER_ROOT_BAG,
                serverSlot = SERVER_BACKPACK_START + clientSlot - 1,
                clientBag = 0,
                clientSlot = clientSlot,
                label = "Mochila · espaço " .. clientSlot,
            })
        end
    end

    for clientBag = 1, 4 do
        for clientSlot = 1, GetContainerNumSlots(clientBag) do
            local link = GetContainerItemLink(clientBag, clientSlot)
            if link and IsEquipmentLink(link) then
                table.insert(self.itemChoices, {
                    kind = "bag",
                    serverBag = SERVER_BAG_START + clientBag - 1,
                    serverSlot = clientSlot - 1,
                    clientBag = clientBag,
                    clientSlot = clientSlot,
                    label = "Bolsa " .. clientBag .. " · espaço " .. clientSlot,
                })
            end
        end
    end
end

function Forge:CreateBagChoice(clientBag, clientSlot)
    clientBag = tonumber(clientBag)
    clientSlot = tonumber(clientSlot)
    if clientBag == nil or not clientSlot then
        return nil
    end

    if clientBag == 0 then
        return {
            kind = "bag",
            serverBag = SERVER_ROOT_BAG,
            serverSlot = SERVER_BACKPACK_START + clientSlot - 1,
            clientBag = clientBag,
            clientSlot = clientSlot,
            label = "Mochila · espaço " .. clientSlot,
        }
    end

    if clientBag >= 1 and clientBag <= 4 then
        return {
            kind = "bag",
            serverBag = SERVER_BAG_START + clientBag - 1,
            serverSlot = clientSlot - 1,
            clientBag = clientBag,
            clientSlot = clientSlot,
            label = "Bolsa " .. clientBag .. " · espaço " .. clientSlot,
        }
    end

    return nil
end

function Forge:RememberBagDragSource(button, mouseButton)
    if mouseButton and mouseButton ~= "LeftButton" then
        return
    end
    if not button or CursorHasItem() then
        return
    end

    local parent = button:GetParent()
    local clientBag = parent and parent:GetID()
    local clientSlot = button:GetID()
    local link = clientBag ~= nil and clientSlot and
        GetContainerItemLink(clientBag, clientSlot) or nil

    if not link then
        self.dragSource = nil
        self.cursorSource = nil
        return
    end

    local source = {
        clientBag = clientBag,
        clientSlot = clientSlot,
        link = link,
        itemId = tonumber(string.match(link, "item:(%d+)")),
        capturedAt = GetTime(),
        exactSource = true,
    }
    self.cursorSource = source
    self.dragSource = IsEquipmentLink(link) and source or nil
end

function Forge:RememberCursorPickup(clientBag, clientSlot)
    clientBag = tonumber(clientBag)
    clientSlot = tonumber(clientSlot)
    if clientBag == nil or not clientSlot or
            clientBag < 0 or clientBag > 4 or not CursorHasItem() then
        return
    end

    local cursorType, cursorItemId, cursorLink = GetCursorInfo()
    local link = cursorLink or
        GetContainerItemLink(clientBag, clientSlot) or
        select(2, GetItemInfo(cursorItemId or 0))
    if cursorType ~= "item" or not link then
        return
    end

    local source = {
        clientBag = clientBag,
        clientSlot = clientSlot,
        link = link,
        itemId = tonumber(cursorItemId) or
            tonumber(string.match(link, "item:(%d+)")),
        capturedAt = GetTime(),
        exactSource = true,
    }
    self.cursorSource = source
    self.dragSource = IsEquipmentLink(link) and source or nil
end

function Forge:HookContainerButtons()
    local frameCount = NUM_CONTAINER_FRAMES or 12
    local itemCount = MAX_CONTAINER_ITEMS or 36

    for frameIndex = 1, frameCount do
        for itemIndex = 1, itemCount do
            local button = getglobal(
                "ContainerFrame" .. frameIndex .. "Item" .. itemIndex)
            if button and not button.ikaForgeDragHooked and button.HookScript then
                button:HookScript("OnMouseDown", function()
                    Forge:RememberBagDragSource(this, arg1)
                end)
                button.ikaForgeDragHooked = true
            end
        end
    end
end

-- Itens totalmente personalizados nao existem no Item.dbc do cliente 2.4.3.
-- Mesmo com um displayid valido no banco do mundo, o cliente desenha um
-- ponto de interrogacao. Este hotfix altera somente a textura dos materiais
-- personalizados nos botoes de bolsa; nenhum item, slot ou evento e alterado.
function Forge:RefreshMaterialBagIcons()
    local frameCount = NUM_CONTAINER_FRAMES or 12

    for frameIndex = 1, frameCount do
        local container = getglobal("ContainerFrame" .. frameIndex)
        if container and container:IsShown() then
            local clientBag = container:GetID()
            local containerName = container:GetName()
            local slotCount = container.size or
                (clientBag ~= nil and GetContainerNumSlots(clientBag)) or 0

            for itemIndex = 1, slotCount do
                local button = getglobal(containerName .. "Item" .. itemIndex)
                if button then
                    local clientSlot = button:GetID()
                    local link = clientBag ~= nil and clientSlot and
                        GetContainerItemLink(clientBag, clientSlot) or nil
                    local itemEntry = link and
                        tonumber(string.match(link, "item:(%d+)")) or nil

                    local customIcon
                    if itemEntry == IKA_BLESSING_ITEM_ENTRY then
                        customIcon = IKA_BLESSING_ICON
                    elseif itemEntry == IKA_WRATH_ITEM_ENTRY then
                        customIcon = IKA_WRATH_ICON
                    end

                    if customIcon then
                        local icon = getglobal(button:GetName() .. "IconTexture")
                        if icon then
                            icon:SetTexture(customIcon)
                        end
                    end
                end
            end
        end
    end
end

function Forge:AcceptCursorItem()
    if not CursorHasItem() then
        return
    end

    local cursorType, cursorItemId, cursorLink = GetCursorInfo()
    local source = self.dragSource
    local recent = source and source.capturedAt and
        (GetTime() - source.capturedAt) <= 8
    local sameItem = false

    if source and source.exactSource and cursorType == "item" then
        if cursorItemId and source.itemId then
            sameItem = tonumber(cursorItemId) == source.itemId
        elseif cursorLink and source.link then
            sameItem = cursorLink == source.link
        else
            sameItem = true
        end
    end

    ClearCursor()
    self.dragSource = nil
    self.cursorSource = nil

    if not recent or not sameItem then
        self:SetStatus(
            "Arraste o equipamento diretamente de uma das suas bolsas.",
            { 0.95, 0.34, 0.28 })
        return
    end

    local restoredLink = GetContainerItemLink(
        source.clientBag,
        source.clientSlot)
    if restoredLink and not IsEquipmentLink(restoredLink) then
        self:SetStatus(
            "Não foi possível confirmar o espaço original do equipamento.",
            { 0.95, 0.34, 0.28 })
        return
    end

    self.selectedItem = self:CreateBagChoice(
        source.clientBag,
        source.clientSlot)
    self:UpdateLocalItem()
    self:SetStatus("Equipamento da bolsa selecionado.", GOLD_BRIGHT)
    self:RequestStatus()
end

function Forge:AcceptSocketGem(socketIndex)
    if not CursorHasItem() or not self.selectedItem then
        return
    end

    if not self.currentData or not self.currentData.socketUnlocked then
        ClearCursor()
        self.cursorSource = nil
        self:SetStatus(
            "Os três encaixes IKA são liberados somente no nível +10.",
            { 0.95, 0.64, 0.24 })
        return
    end

    local cursorType, cursorItemId, cursorLink = GetCursorInfo()
    local source = self.cursorSource
    local recent = source and source.capturedAt and
        (GetTime() - source.capturedAt) <= 8
    local sameItem = false
    if source and source.exactSource and cursorType == "item" then
        if cursorItemId and source.itemId then
            sameItem = tonumber(cursorItemId) == source.itemId
        elseif cursorLink and source.link then
            sameItem = cursorLink == source.link
        else
            sameItem = true
        end
    end

    ClearCursor()
    self.cursorSource = nil
    self.dragSource = nil
    if not recent or not sameItem then
        self:SetStatus(
            "Arraste a gema diretamente de uma das suas bolsas.",
            { 0.95, 0.34, 0.28 })
        return
    end

    local gemChoice = self:CreateBagChoice(source.clientBag, source.clientSlot)
    if not gemChoice then
        self:SetStatus("Não foi possível confirmar o espaço da gema.", { 0.95, 0.34, 0.28 })
        return
    end

    self.requestPending = true
    self:SetStatus("Aplicando gema no encaixe IKA...", GOLD_BRIGHT)
    self:RefreshActionState()
    SendChatMessage(
        ".reforge ui socket " ..
        self.selectedItem.serverBag .. " " .. self.selectedItem.serverSlot .. " " ..
        socketIndex .. " " .. gemChoice.serverBag .. " " .. gemChoice.serverSlot,
        "SAY")
end

function Forge:ClearSelection()
    self.selectedItem = nil
    self.currentItemLink = nil
    self.currentEligible = false
    self.requestPending = false
    self:UpdateSocketDisplay(nil)
    self:UpdateLocalItem()
    self:SetStatus(
        "Slot liberado. Arraste outro equipamento ou use as setas.",
        MUTED)
end

function Forge:FindSelectedIndex()
    if not self.itemChoices or not self.selectedItem then
        return nil
    end

    local selectedKey = PositionKey(
        self.selectedItem.serverBag,
        self.selectedItem.serverSlot)
    for index = 1, table.getn(self.itemChoices) do
        local choice = self.itemChoices[index]
        if PositionKey(choice.serverBag, choice.serverSlot) == selectedKey then
            return index
        end
    end
    return nil
end

function Forge:SelectNext(direction)
    self:BuildItemChoices()
    local count = table.getn(self.itemChoices)
    if count == 0 then
        self.selectedItem = nil
        self:UpdateLocalItem()
        return
    end

    local index = self:FindSelectedIndex() or 1
    index = index + direction
    if index < 1 then
        index = count
    elseif index > count then
        index = 1
    end

    self.selectedItem = self.itemChoices[index]
    self:UpdateLocalItem()
    self:RequestStatus()
end

function Forge:UpdateLocalItem()
    if not self.selectedItem then
        self.itemButton.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.itemName:SetText("Nenhum equipamento")
        self.slotName:SetText("")
        self.currentItemLink = nil
        self:UpdateSocketDisplay(nil)
        SetButtonEnabled(self.forgeButton, false)
        return
    end

    local link = self:GetLinkForChoice(self.selectedItem)
    local texture = self:GetTextureForChoice(self.selectedItem)
    self:UpdateSocketDisplay(nil)
    self.itemButton.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.itemName:SetText(GetItemName(link))
    self.slotName:SetText(self.selectedItem.label or "Equipamento")
    self.currentItemLink = link
end

function Forge:ShowSocketTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if button.gemEntry and button.gemEntry > 0 then
        GameTooltip:SetHyperlink("item:" .. button.gemEntry .. ":0:0:0:0:0:0:0")
    elseif button.socketUnlocked then
        GameTooltip:AddLine("Encaixe IKA prismático", GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
        GameTooltip:AddLine("Arraste uma gema TBC comum para este espaço.", 0.82, 0.77, 0.68, true)
        GameTooltip:AddLine("A gema anterior será substituída.", 0.95, 0.48, 0.24, true)
    else
        GameTooltip:AddLine("Encaixe IKA bloqueado", 0.68, 0.64, 0.56)
        GameTooltip:AddLine("Alcance o nível de reforja +10 para liberar.", 0.82, 0.77, 0.68, true)
    end
    GameTooltip:Show()
end

function Forge:UpdateSocketDisplay(data)
    if not self.socketButtons then
        return
    end

    local unlocked = data and data.socketUnlocked
    for index = 1, 3 do
        local button = self.socketButtons[index]
        local gemEntry = data and data.socketGems and data.socketGems[index] or 0
        button.socketUnlocked = unlocked and true or false
        button.gemEntry = gemEntry or 0
        if gemEntry and gemEntry > 0 then
            local texture = select(10, GetItemInfo(gemEntry))
            button.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_Gem_Variety_01")
            button.icon:SetVertexColor(1, 1, 1)
            button:SetAlpha(1)
        elseif unlocked then
            button.icon:SetTexture("Interface\\Icons\\INV_Misc_Gem_Variety_01")
            button.icon:SetVertexColor(0.78, 0.68, 0.40)
            button:SetAlpha(0.72)
        else
            button.icon:SetTexture("Interface\\Icons\\INV_Misc_Lockbox_1")
            button.icon:SetVertexColor(0.55, 0.52, 0.46)
            button:SetAlpha(0.50)
        end
    end
end

function Forge:GetBlessingCount()
    return GetItemCount(IKA_BLESSING_ITEM_ENTRY) or 0
end

function Forge:GetWrathCount()
    return GetItemCount(IKA_WRATH_ITEM_ENTRY) or 0
end

function Forge:GetEffectiveChance(baseChance)
    local chance = tonumber(baseChance) or 0
    if self.useBlessing and chance > 0 then
        chance = math.min(10000, chance + IKA_BLESSING_BONUS_BASIS_POINTS)
    end
    return chance
end

function Forge:RefreshActionState()
    if not self.forgeButton then
        return
    end

    local hasBlessing = not self.useBlessing or self:GetBlessingCount() > 0
    local hasWrath = not self.useWrath or
        ((self.currentLevel or 0) > 0 and self:GetWrathCount() > 0)
    local enabled = self.selectedItem and self.currentEligible and
        (self.currentLevel or 0) < (self.currentMaxLevel or 10) and not self.requestPending and
        hasBlessing and hasWrath
    SetButtonEnabled(self.forgeButton, enabled and true or false)
end

function Forge:UpdateBlessingDisplay()
    if not self.materialText then
        return
    end

    local owned = self:GetBlessingCount()
    if owned < 1 then
        self.useBlessing = false
    end

    self.materialText:SetText(
        IKA_BLESSING_COLOR .. "Bênção de IKA|r  " .. owned .. "/1")
    self.materialText:SetTextColor(1, 1, 1)
    self.materialIcon:SetTexture(IKA_BLESSING_ICON)
    self.materialButton:SetAlpha(owned > 0 and 1 or 0.48)
    self.blessingCheck:SetChecked(self.useBlessing and true or false)

    if owned > 0 then
        self.blessingCheck:Enable()
        self.blessingCheck:SetAlpha(1)
    else
        self.blessingCheck:Disable()
        self.blessingCheck:SetAlpha(0.48)
    end

    local effectiveChance = self:GetEffectiveChance(self.baseChance)
    if self.chanceText and self.baseChance then
        self.chanceText:SetText(
            effectiveChance > 0 and FormatBasisPoints(effectiveChance) or "—")
    end
    if self.currentData then
        self.currentData.displayChance = effectiveChance
        self:UpdatePreviewRows(self.currentData)
    end
    self:RefreshActionState()
end

function Forge:SetBlessingSelected(selected)
    if selected and self:GetBlessingCount() < 1 then
        self.useBlessing = false
        self:SetStatus("Você não possui uma Bênção de IKA.", { 0.95, 0.34, 0.28 })
    else
        self.useBlessing = selected and true or false
        if self.useBlessing then
            self:SetStatus("Bênção de IKA ativada: +5 pontos percentuais.", { 0.72, 0.40, 0.96 })
        elseif self.currentEligible then
            self:SetStatus("Bênção de IKA desativada para esta tentativa.", MUTED)
        end
    end
    self:UpdateBlessingDisplay()
end

function Forge:ToggleBlessing()
    self:SetBlessingSelected(not self.useBlessing)
end

function Forge:UpdateWrathDisplay()
    if not self.wrathText then
        return
    end

    local owned = self:GetWrathCount()
    local canProtect = (self.currentLevel or 0) > 0
    if owned < 1 or not canProtect then
        self.useWrath = false
    end

    self.wrathText:SetText(
        IKA_WRATH_COLOR .. "Ira de IKA|r  " .. owned .. "/1")
    self.wrathText:SetTextColor(1, 1, 1)
    self.wrathIcon:SetTexture(IKA_WRATH_ICON)
    self.wrathButton:SetAlpha(owned > 0 and canProtect and 1 or 0.48)
    self.wrathCheck:SetChecked(self.useWrath and true or false)

    if owned > 0 and canProtect then
        self.wrathCheck:Enable()
        self.wrathCheck:SetAlpha(1)
    else
        self.wrathCheck:Disable()
        self.wrathCheck:SetAlpha(0.48)
    end

    if self.currentData then
        self:UpdatePreviewRows(self.currentData)
    end
    self:RefreshActionState()
end

function Forge:SetWrathSelected(selected)
    if selected and (self.currentLevel or 0) <= 0 then
        self.useWrath = false
        self:SetStatus(
            "A Ira de IKA só é necessária a partir do nível +1.",
            { 0.95, 0.64, 0.24 })
    elseif selected and self:GetWrathCount() < 1 then
        self.useWrath = false
        self:SetStatus("Você não possui uma Ira de IKA.", { 0.95, 0.34, 0.28 })
    else
        self.useWrath = selected and true or false
        if self.useWrath then
            self:SetStatus(
                "Ira de IKA ativada: o nível será protegido em caso de falha.",
                { 0.96, 0.30, 0.22 })
        elseif self.currentEligible then
            self:SetStatus("Ira de IKA desativada para esta tentativa.", MUTED)
        end
    end
    self:UpdateWrathDisplay()
end

function Forge:ToggleWrath()
    self:SetWrathSelected(not self.useWrath)
end

function Forge:Open()
    self:CreateUI()
    self:HookContainerButtons()
    self:BuildItemChoices()

    local preferred = PositionKey(SERVER_ROOT_BAG, 15)
    local foundPreferred = false
    for index = 1, table.getn(self.itemChoices) do
        local choice = self.itemChoices[index]
        if PositionKey(choice.serverBag, choice.serverSlot) == preferred then
            foundPreferred = true
            self.selectedItem = choice
            break
        end
    end

    if not foundPreferred and table.getn(self.itemChoices) > 0 then
        self.selectedItem = self.itemChoices[1]
    else
        if not foundPreferred then
            self.selectedItem = nil
        end
    end

    self.useBlessing = false
    self.useWrath = false
    self.baseChance = nil
    self.currentData = nil
    self.frame:Show()
    self:UpdateLocalItem()
    self:UpdateBlessingDisplay()
    self:UpdateWrathDisplay()
    self:SetStatus("Selecione um equipamento para começar.", MUTED)
    self:RequestStatus()
end

function Forge:Close()
    if self.frame then
        self.frame:Hide()
    end
    self.requestPending = false
end

function Forge:SetStatus(text, color)
    color = color or GOLD_BRIGHT
    self.statusText:SetText(text or "")
    self.statusText:SetTextColor(color[1], color[2], color[3])
end

function Forge:RequestStatus()
    if not self.frame or not self.frame:IsShown() or not self.selectedItem then
        return
    end
    self.requestPending = true
    SetButtonEnabled(self.forgeButton, false)
    SendChatMessage(
        ".reforge ui status " ..
        self.selectedItem.serverBag .. " " .. self.selectedItem.serverSlot,
        "SAY")
end

function Forge:TryReforge()
    if not self.selectedItem or self.requestPending or not self.currentEligible then
        return
    end
    if self.useBlessing and self:GetBlessingCount() < 1 then
        self:SetBlessingSelected(false)
        self:SetStatus("Você não possui uma Bênção de IKA.", { 0.95, 0.34, 0.28 })
        return
    end
    if self.useWrath and ((self.currentLevel or 0) <= 0 or self:GetWrathCount() < 1) then
        self:SetWrathSelected(false)
        self:SetStatus("A proteção Ira de IKA não está disponível.", { 0.95, 0.34, 0.28 })
        return
    end
    self.requestPending = true
    SetButtonEnabled(self.forgeButton, false)
    self:SetStatus("O Forjador IKA está trabalhando...", GOLD_BRIGHT)
    SendChatMessage(
        ".reforge ui try " ..
        self.selectedItem.serverBag .. " " .. self.selectedItem.serverSlot .. " " ..
        (self.useBlessing and "1" or "0") .. " " ..
        (self.useWrath and "1" or "0"),
        "SAY")
end

function Forge:ApplyReforgeTooltip(tooltip, data)
    if not tooltip or not data or not data.level or data.level <= 0 then
        return
    end

    local stamp = data.key .. ":" .. data.level .. ":" ..
        table.concat(data.socketGems or {}, ",") .. ":" .. (data.link or "")
    if tooltip.ikaReforgeStamp == stamp then
        return
    end
    tooltip.ikaReforgeStamp = stamp

    local title = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
    if title and not string.find(title, " %+%d+$") then
        GameTooltipTextLeft1:SetText(title .. " +" .. data.level)
    end

    tooltip:AddLine(" ")
    tooltip:AddLine(
        "IKA Reforge +" .. data.level,
        GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
    tooltip:AddDoubleLine(
        "Poder do equipamento",
        FormatBasisPoints(data.power),
        0.82, 0.77, 0.68,
        GREEN[1], GREEN[2], GREEN[3])

    if data.socketUnlocked then
        local filled = 0
        for index = 1, 3 do
            if data.socketGems[index] and data.socketGems[index] > 0 then
                filled = filled + 1
            end
        end
        tooltip:AddDoubleLine(
            "Encaixes IKA",
            filled .. "/3 preenchidos",
            0.82, 0.77, 0.68,
            GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
        for index = 1, 3 do
            local gemEntry = data.socketGems[index]
            if gemEntry and gemEntry > 0 then
                local gemName, gemLink = GetItemInfo(gemEntry)
                tooltip:AddLine(
                    "  " .. (gemLink or gemName or ("Gema " .. gemEntry)),
                    0.88, 0.88, 0.88)
            end
        end
    end

    if data.damageMaxBase > 0 then
        tooltip:AddDoubleLine(
            "Dano",
            FormatDamage(data.damageMinBase, data.damageMaxBase) ..
                "  →  " ..
                FormatDamage(data.damageMinCurrent, data.damageMaxCurrent),
            0.84, 0.80, 0.72,
            GREEN[1], GREEN[2], GREEN[3])
    end

    if data.armorBase > 0 then
        tooltip:AddDoubleLine(
            "Armadura",
            data.armorBase .. "  →  " .. data.armorCurrent,
            0.84, 0.80, 0.72,
            GREEN[1], GREEN[2], GREEN[3])
    end

    for index = 1, table.getn(data.stats) do
        local stat = data.stats[index]
        if stat and stat.base ~= 0 then
            tooltip:AddDoubleLine(
                STAT_NAMES[stat.type] or ("Atributo " .. stat.type),
                FormatSigned(stat.base) .. "  →  " .. FormatSigned(stat.current),
                0.84, 0.80, 0.72,
                GREEN[1], GREEN[2], GREEN[3])
        end
    end

    if data.resistanceBase > 0 then
        tooltip:AddDoubleLine(
            "Resistências totais",
            data.resistanceBase .. "  →  " .. data.resistanceCurrent,
            0.84, 0.80, 0.72,
            GREEN[1], GREEN[2], GREEN[3])
    end

    if data.blockBase > 0 then
        tooltip:AddDoubleLine(
            "Valor de bloqueio",
            data.blockBase .. "  →  " .. data.blockCurrent,
            0.84, 0.80, 0.72,
            GREEN[1], GREEN[2], GREEN[3])
    end

    tooltip:AddLine(
        "Bônus aplicado pelo servidor ao equipar.",
        0.62, 0.78, 1.00)
    tooltip:Show()
end

function Forge:ShowSelectedTooltip(owner)
    if not self.selectedItem then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip.ikaReforgePositionKey = PositionKey(
        self.selectedItem.serverBag,
        self.selectedItem.serverSlot)
    GameTooltip.ikaReforgeStamp = nil
    if self.selectedItem.kind == "equipped" then
        GameTooltip:SetInventoryItem("player", self.selectedItem.clientSlot)
    else
        GameTooltip:SetBagItem(
            self.selectedItem.clientBag,
            self.selectedItem.clientSlot)
    end

    local key = PositionKey(
        self.selectedItem.serverBag,
        self.selectedItem.serverSlot)
    self:ApplyReforgeTooltip(GameTooltip, self.reforgeCache[key])
    GameTooltip:Show()
end

function Forge:GetCurrentLinkAt(serverBag, serverSlot)
    if serverBag == SERVER_ROOT_BAG then
        if serverSlot < 19 then
            return GetInventoryItemLink("player", serverSlot + 1)
        end
        if serverSlot >= SERVER_BACKPACK_START and
                serverSlot < SERVER_BACKPACK_START + GetContainerNumSlots(0) then
            return GetContainerItemLink(
                0,
                serverSlot - SERVER_BACKPACK_START + 1)
        end
        return nil
    end

    if serverBag >= SERVER_BAG_START and serverBag < SERVER_BAG_START + 4 then
        return GetContainerItemLink(
            serverBag - SERVER_BAG_START + 1,
            serverSlot + 1)
    end
    return nil
end

function Forge:InvalidateReforgePositionCache()
    -- Server reforge state belongs to the immutable item GUID, not to a bag
    -- position.  TBC item links do not expose that GUID, so every inventory
    -- or equipment move must invalidate the position-indexed presentation
    -- cache before another tooltip is drawn.
    self.reforgeCache = {}
    self.tooltipPending = {}

    if GameTooltip then
        GameTooltip.ikaReforgePositionKey = nil
        GameTooltip.ikaReforgeStamp = nil
    end
end

function Forge:RequestTooltipStatus(serverBag, serverSlot, link)
    local key = PositionKey(serverBag, serverSlot)
    local cached = self.reforgeCache[key]
    if cached and cached.link == link then
        self:ApplyReforgeTooltip(GameTooltip, cached)
        return
    end

    if self.tooltipPending[key] == link then
        return
    end

    self.tooltipPending[key] = link
    SendChatMessage(
        ".reforge ui status " .. serverBag .. " " .. serverSlot,
        "SAY")
end

function Forge:UpdatePreviewRows(data)
    local mainLabel = "Poder total"
    local mainValue =
        FormatBasisPoints(data.currentPower) ..
        "  →  " ..
        FormatBasisPoints(data.targetPower)

    if data.damageMaxBase > 0 then
        mainLabel = "Dano"
        mainValue =
            FormatDamage(data.damageMinCurrent, data.damageMaxCurrent) ..
            "  →  " ..
            FormatDamage(data.damageMinTarget, data.damageMaxTarget)
    elseif data.armorBase > 0 then
        mainLabel = "Armadura"
        mainValue =
            data.armorCurrent .. "  →  " .. data.armorTarget
    end

    local secondaryLabel = "Poder total"
    local secondaryValue =
        FormatBasisPoints(data.currentPower) ..
        "  →  " ..
        FormatBasisPoints(data.targetPower)

    for index = 1, table.getn(data.stats) do
        local stat = data.stats[index]
        if stat and stat.base ~= 0 then
            secondaryLabel = STAT_NAMES[stat.type] or ("Atributo " .. stat.type)
            secondaryValue =
                FormatSigned(stat.current) ..
                "  →  " ..
                FormatSigned(stat.target)
            break
        end
    end

    self.previewLabels[1]:SetText(mainLabel)
    self.previewValues[1]:SetText(mainValue)
    self.previewLabels[2]:SetText(secondaryLabel)
    self.previewValues[2]:SetText(secondaryValue)
    self.previewLabels[3]:SetText("Chance")
    self.previewValues[3]:SetText(
        (data.displayChance or data.chance) > 0 and
            FormatBasisPoints(data.displayChance or data.chance) or "—")
    self.previewLabels[4]:SetText("Falha")
    if (data.level or 0) <= 0 then
        self.previewValues[4]:SetText("Sem perda no nível +0")
        self.previewValues[4]:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
    elseif self.useWrath then
        self.previewValues[4]:SetText("Ira protege: permanece +" .. data.level)
        self.previewValues[4]:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
    else
        self.previewValues[4]:SetText(
            "Nível cai: +" .. data.level .. " → +" .. (data.level - 1))
        self.previewValues[4]:SetTextColor(0.95, 0.42, 0.26)
    end
end

function Forge:UpdateNodes(currentLevel, targetLevel)
    for level = 0, 10 do
        local node = self.nodes[level]
        if level <= currentLevel then
            node.dot:SetVertexColor(GREEN[1], GREEN[2], GREEN[3])
            node.text:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
        elseif level == targetLevel then
            node.dot:SetVertexColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
            node.text:SetTextColor(GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
        else
            node.dot:SetVertexColor(0.36, 0.33, 0.27)
            node.text:SetTextColor(0.50, 0.47, 0.40)
        end
    end
end

function Forge:HandleStatus(fields)
    local bag = tonumber(fields[3])
    local slot = tonumber(fields[4])
    if not bag or not slot then
        return
    end

    local currentLevel = tonumber(fields[5]) or 0
    local currentPower = tonumber(fields[6]) or 10000
    local eligible = tonumber(fields[7]) == 1
    local targetLevel = tonumber(fields[8]) or currentLevel
    local chance = tonumber(fields[9]) or 0
    local targetPower = tonumber(fields[10]) or currentPower
    local goldCost = tonumber(fields[11]) or 0
    local materialItem = tonumber(fields[12]) or 0
    local materialCount = tonumber(fields[13]) or 0
    local key = PositionKey(bag, slot)

    local data = {
        key = key,
        bag = bag,
        slot = slot,
        link = self:GetCurrentLinkAt(bag, slot),
        entry = tonumber(fields[14]) or 0,
        level = currentLevel,
        power = currentPower,
        eligible = eligible,
        targetLevel = targetLevel,
        chance = chance,
        currentPower = currentPower,
        targetPower = targetPower,
        goldCost = goldCost,
        materialItem = materialItem,
        materialCount = materialCount,
        armorBase = tonumber(fields[15]) or 0,
        armorCurrent = tonumber(fields[16]) or 0,
        armorTarget = tonumber(fields[17]) or 0,
        damageMinBase = tonumber(fields[18]) or 0,
        damageMaxBase = tonumber(fields[19]) or 0,
        damageMinCurrent = tonumber(fields[20]) or 0,
        damageMaxCurrent = tonumber(fields[21]) or 0,
        damageMinTarget = tonumber(fields[22]) or 0,
        damageMaxTarget = tonumber(fields[23]) or 0,
        stats = {},
        resistanceBase = tonumber(fields[64]) or 0,
        resistanceCurrent = tonumber(fields[65]) or 0,
        resistanceTarget = tonumber(fields[66]) or 0,
        blockBase = tonumber(fields[67]) or 0,
        blockCurrent = tonumber(fields[68]) or 0,
        blockTarget = tonumber(fields[69]) or 0,
        socketUnlocked = tonumber(fields[70]) == 1,
        socketGems = {
            tonumber(fields[71]) or 0,
            tonumber(fields[72]) or 0,
            tonumber(fields[73]) or 0,
        },
        maxLevel = tonumber(fields[74]) or 10,
    }

    for index = 1, 10 do
        local field = 24 + ((index - 1) * 4)
        table.insert(data.stats, {
            type = tonumber(fields[field]) or 0,
            base = tonumber(fields[field + 1]) or 0,
            current = tonumber(fields[field + 2]) or 0,
            target = tonumber(fields[field + 3]) or 0,
        })
    end

    self.reforgeCache[key] = data
    self.tooltipPending[key] = nil

    if GameTooltip and GameTooltip:IsShown() and
            GameTooltip.ikaReforgePositionKey == key then
        self:ApplyReforgeTooltip(GameTooltip, data)
    end

    if not self.selectedItem or
            bag ~= self.selectedItem.serverBag or
            slot ~= self.selectedItem.serverSlot or
            not self.frame or not self.frame:IsShown() then
        return
    end

    self.currentEligible = eligible
    self.currentLevel = currentLevel
    self.currentMaxLevel = data.maxLevel
    self.targetLevel = targetLevel
    self.baseChance = chance
    self.currentData = data
    data.displayChance = self:GetEffectiveChance(chance)
    self.requestPending = false
    self:UpdateSocketDisplay(data)

    self.currentLevelText:SetText("+" .. currentLevel)
    self.targetLevelText:SetText("+" .. targetLevel)
    self.chanceText:SetText(
        data.displayChance > 0 and FormatBasisPoints(data.displayChance) or "—")
    self:UpdatePreviewRows(data)
    self.costText:SetText(FormatMoney(goldCost))

    local reforgedSuffix = currentLevel > 0 and (" +" .. currentLevel) or ""
    self.itemName:SetText(GetItemName(self.currentItemLink) .. reforgedSuffix)

    self:UpdateBlessingDisplay()
    self:UpdateWrathDisplay()

    self:UpdateNodes(currentLevel, targetLevel)

    if self.lastResultText then
        self:SetStatus(self.lastResultText, self.lastResultColor)
        self.lastResultText = nil
        self.lastResultColor = nil
        self:RefreshActionState()
    elseif not eligible then
        self:SetStatus("Este item não pode ser reforjado.", { 0.95, 0.34, 0.28 })
        SetButtonEnabled(self.forgeButton, false)
    elseif currentLevel >= data.maxLevel then
        if data.maxLevel == 3 then
            self:SetStatus("Limite IKA GOD +3 alcançado.", GREEN)
        else
            self:SetStatus("Nível máximo +" .. data.maxLevel .. " alcançado.", GREEN)
        end
        SetButtonEnabled(self.forgeButton, false)
    else
        self:SetStatus("Pronto para tentar +" .. targetLevel .. ".", GOLD_BRIGHT)
        self:RefreshActionState()
    end
end

function Forge:HandleSocketResult(fields)
    local result = fields[3]
    local bag = tonumber(fields[4])
    local slot = tonumber(fields[5])
    local socketIndex = tonumber(fields[6]) or 0
    if not self.selectedItem or
            bag ~= self.selectedItem.serverBag or
            slot ~= self.selectedItem.serverSlot then
        return
    end

    self.requestPending = false
    if result == "SUCCESS" then
        self.lastResultText =
            "Gema aplicada com sucesso no encaixe " .. (socketIndex + 1) .. "."
        self.lastResultColor = GREEN
        PlaySound("QUESTCOMPLETED")
    end
    self:RequestStatus()
end

function Forge:HandleResult(fields)
    local result = fields[3]
    local bag = tonumber(fields[4])
    local slot = tonumber(fields[5])
    if not self.selectedItem or
            bag ~= self.selectedItem.serverBag or
            slot ~= self.selectedItem.serverSlot then
        return
    end

    local level = tonumber(fields[6]) or 0
    local blessingUsed = tonumber(fields[9]) == 1
    local wrathSelected = tonumber(fields[10]) == 1
    local wrathConsumed = tonumber(fields[11]) == 1
    local previousLevel = tonumber(fields[12]) or level
    self.requestPending = false

    if blessingUsed then
        self.useBlessing = false
        if self.blessingCheck then
            self.blessingCheck:SetChecked(false)
        end
    end

    if wrathConsumed then
        self.useWrath = false
        if self.wrathCheck then
            self.wrathCheck:SetChecked(false)
        end
    end

    if result == "SUCCESS" then
        self.lastResultText = "SUCESSO! O equipamento alcançou +" .. level .. "."
        self.lastResultColor = GREEN
        PlaySound("QUESTCOMPLETED")
    else
        if wrathSelected and wrathConsumed then
            self.lastResultText =
                "A Ira de IKA protegeu o equipamento. Ele permaneceu em +" .. level .. "."
            self.lastResultColor = { 0.96, 0.52, 0.24 }
        elseif level < previousLevel then
            self.lastResultText =
                "FALHA! O equipamento caiu de +" .. previousLevel .. " para +" .. level .. "."
            self.lastResultColor = { 0.95, 0.24, 0.18 }
        else
            self.lastResultText = "A tentativa falhou. O item permaneceu em +" .. level .. "."
            self.lastResultColor = { 0.95, 0.42, 0.26 }
        end
        PlaySound("igQuestFailed")
    end

    self:RequestStatus()
end

function Forge:HandleError(fields)
    local code = fields[3] or "UNKNOWN"
    local bag = tonumber(fields[4])
    local slot = tonumber(fields[5])
    local key = bag and slot and PositionKey(bag, slot) or nil
    if key then
        self.tooltipPending[key] = nil
    end

    if not self.selectedItem or
            (bag and bag ~= self.selectedItem.serverBag) or
            (slot and slot ~= self.selectedItem.serverSlot) then
        return
    end

    self.requestPending = false
    self:SetStatus(ERROR_TEXT[code] or ("Erro do Forjador IKA: " .. code), { 0.95, 0.34, 0.28 })
    SetButtonEnabled(self.forgeButton, false)
end

function Forge:HandleProtocol(message)
    if string.sub(message or "", 1, 7) ~= "IKA_RF|" then
        return false
    end

    local fields = SplitProtocol(message)
    if fields[2] == "STATUS" then
        self:HandleStatus(fields)
    elseif fields[2] == "RESULT" then
        self:HandleResult(fields)
    elseif fields[2] == "SOCKET_RESULT" then
        self:HandleSocketResult(fields)
    elseif fields[2] == "ERROR" then
        self:HandleError(fields)
    end
    return true
end

local eventFrame = CreateFrame("Frame", "IKAForgeEventFrame")
eventFrame:RegisterEvent("GOSSIP_SHOW")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:SetScript("OnEvent", function()
    if event == "GOSSIP_SHOW" then
        if UnitName("npc") == FORGE_NPC_NAME then
            if GossipFrame and GossipFrame:IsShown() then
                GossipFrame:Hide()
            end
            Forge:Open()
        end
    elseif event == "CHAT_MSG_SYSTEM" then
        Forge:HandleProtocol(arg1)
    elseif event == "PLAYER_ENTERING_WORLD" then
        Forge.requestPending = false
        Forge:InvalidateReforgePositionCache()
        Forge:HookContainerButtons()
        Forge:RefreshMaterialBagIcons()
    elseif event == "BAG_UPDATE" then
        Forge:InvalidateReforgePositionCache()
        Forge:HookContainerButtons()
        Forge:RefreshMaterialBagIcons()
        if Forge.frame and Forge.frame:IsShown() then
            Forge:UpdateBlessingDisplay()
            Forge:UpdateWrathDisplay()
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        Forge:InvalidateReforgePositionCache()
    end
end)

if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, message)
        if string.sub(message or "", 1, 7) == "IKA_RF|" then
            return true
        end
        return false
    end)
end

if hooksecurefunc and GameTooltip then
    hooksecurefunc(GameTooltip, "SetInventoryItem", function(tooltip, unit, inventorySlot)
        if tooltip ~= GameTooltip or unit ~= "player" or not inventorySlot then
            return
        end

        local link = GetInventoryItemLink("player", inventorySlot)
        if not IsEquipmentLink(link) then
            tooltip.ikaReforgePositionKey = nil
            tooltip.ikaReforgeStamp = nil
            return
        end

        local serverBag = SERVER_ROOT_BAG
        local serverSlot = inventorySlot - 1
        tooltip.ikaReforgePositionKey = PositionKey(serverBag, serverSlot)
        tooltip.ikaReforgeStamp = nil
        Forge:RequestTooltipStatus(serverBag, serverSlot, link)
    end)

    hooksecurefunc(GameTooltip, "SetBagItem", function(tooltip, clientBag, clientSlot)
        if tooltip ~= GameTooltip or clientBag == nil or not clientSlot then
            return
        end

        local link = GetContainerItemLink(clientBag, clientSlot)
        if not IsEquipmentLink(link) then
            tooltip.ikaReforgePositionKey = nil
            tooltip.ikaReforgeStamp = nil
            return
        end

        local serverBag
        local serverSlot
        if clientBag == 0 then
            serverBag = SERVER_ROOT_BAG
            serverSlot = SERVER_BACKPACK_START + clientSlot - 1
        elseif clientBag >= 1 and clientBag <= 4 then
            serverBag = SERVER_BAG_START + clientBag - 1
            serverSlot = clientSlot - 1
        else
            return
        end

        tooltip.ikaReforgePositionKey = PositionKey(serverBag, serverSlot)
        tooltip.ikaReforgeStamp = nil
        Forge:RequestTooltipStatus(serverBag, serverSlot, link)
    end)
end

if hooksecurefunc and PickupContainerItem then
    hooksecurefunc("PickupContainerItem", function(clientBag, clientSlot)
        Forge:RememberCursorPickup(clientBag, clientSlot)
    end)
end

-- ContainerFrame_Update reposiciona/reutiliza os botoes sempre que uma bolsa
-- e aberta. Rodar depois dele garante o icone correto sem usar OnUpdate.
if hooksecurefunc and ContainerFrame_Update then
    hooksecurefunc("ContainerFrame_Update", function()
        Forge:RefreshMaterialBagIcons()
    end)
end

SLASH_IKAFORGE1 = "/ikaforge"
SlashCmdList["IKAFORGE"] = function()
    Forge:Open()
end

-- IKA Reforge Commerce 0.6.0. No item-name or item-entry cache: native row + revision.
do
    local C = { pages = {}, lastViews = {}, nonce = 0, ready = false }
    Forge.commerce = C
    Forge.commerceVersion = "0.6.4"
    local contexts = { list = 1, owner = 2, bidder = 3 }
    local function nextNonce()
        C.nonce = C.nonce + 1
        if C.nonce >= 2147483647 then C.nonce = 1 end
        return C.nonce
    end
    local function split(message)
        local fields = {}
        for part in string.gmatch(message .. "|", "(.-)|") do
            table.insert(fields, part)
        end
        return fields
    end
    local function clearHover()
        C.hover = nil
        if GameTooltip then
            GameTooltip.ikaReforgePositionKey = nil
            GameTooltip.ikaReforgeStamp = nil
        end
    end
    local function invalidate(context)
        C.pages[context] = nil
        C.lastViews[context] = nil
        if C.hover and C.hover.context == context then
            -- Discard the native tooltip too: its old lines may already contain +N.
            clearHover()
            if GameTooltip then GameTooltip:Hide() end
        end
    end
    local function itemLink(context, a, b)
        if context <= 3 then
            local kinds = { "list", "owner", "bidder" }
            return GetAuctionItemLink and GetAuctionItemLink(kinds[context], a)
        elseif context == 4 then
            return GetInboxItemLink and GetInboxItemLink(a, b)
        elseif context == 5 then
            return GetTradePlayerItemLink and GetTradePlayerItemLink(a)
        elseif context == 6 then
            return GetTradeTargetItemLink and GetTradeTargetItemLink(a)
        elseif context == 7 then
            return GetInventoryItemLink and GetInventoryItemLink(a, b)
        end
    end
    local function auctionFingerprint(context, index, link)
        if not GetAuctionItemInfo then return nil end
        local kinds = { "list", "owner", "bidder" }
        local name, texture, count, quality, usable, level, minBid, increment, buyout, bid, highBidder, owner =
            GetAuctionItemInfo(kinds[context], index)
        if not owner or not count or not minBid or not increment or not buyout or not bid then return nil end
        local raw = string.match(link or "", "item:([^|]+)")
        if not raw then return nil end
        local numbers = {}
        for value in string.gmatch(raw .. ":", "(.-):") do
            numbers[#numbers+1] = tonumber(value) or 0
        end
        -- Eight link fields in 8606; suffix factor can be printed signed.
        for i = 1, 8 do numbers[i] = numbers[i] or 0 end
        if numbers[8] < 0 then numbers[8] = numbers[8] + 4294967296 end
        local parts = {}
        for i = 1, 8 do parts[i] = tostring(numbers[i]) end
        return table.concat(parts, ":") .. "|" .. count .. "|" .. minBid .. "|" ..
            increment .. "|" .. buyout .. "|" .. bid .. "|" .. owner
    end
    local function request(hover)
        local page = C.pages[hover.context]
        if not C.ready then return end
        if not page then
            if hover.context == 4 and CheckInbox and
                (not C.lastInboxRefresh or GetTime() - C.lastInboxRefresh > 3) then
                C.lastInboxRefresh = GetTime()
                CheckInbox()
            end
            return
        end
        local serverIndex = hover.index
        if hover.context <= 3 then
            if not page.complete then return end
            local fingerprint = auctionFingerprint(hover.context, hover.a, hover.link)
            local match, matchingLevel
            for index, row in pairs(page.rows) do
                if fingerprint and row.fingerprint == fingerprint then
                    if matchingLevel and matchingLevel ~= row.level then
                        GameTooltip:AddLine("IKA Reforge: ofertas idênticas com reforjas diferentes.", 1, 0.6, 0.2)
                        GameTooltip:AddLine("Não foi possível identificar esta oferta com segurança.", 1, 0.6, 0.2)
                        GameTooltip:Show()
                        hover.ambiguous = true
                        return
                    end
                    match, matchingLevel = index, row.level
                end
            end
            if not match then return end
            serverIndex = match
            hover.fingerprint = fingerprint
        end
        if serverIndex < 1 or serverIndex > page.count then return end
        hover.revision = page.revision
        hover.nonce = nextNonce()
        SendChatMessage(".reforge ui view " .. hover.context .. " " ..
            page.revision .. " " .. serverIndex .. " " .. hover.nonce, "SAY")
    end
    local function beginHover(tooltip, context, index, a, b)
        if tooltip ~= GameTooltip or not context or not index then return end
        clearHover()
        local link = itemLink(context, a, b)
        if not link or not IsEquipmentLink(link) then return end
        local page = C.pages[context]
        local previous = C.lastViews[context]
        if previous and page and previous.context == context and previous.a == a and
            previous.b == b and previous.link == link and previous.revision == page.revision then
            -- The native auction tooltip redraws itself repeatedly. Reattach the
            -- same request instead of replacing its nonce before the reply arrives.
            C.hover = previous
            if previous.data then
                tooltip.ikaReforgeStamp = nil
                Forge:ApplyReforgeTooltip(tooltip, previous.data)
                previous.applied = true
            elseif previous.ambiguous then
                tooltip:AddLine("IKA Reforge: ofertas idênticas com reforjas diferentes.", 1, 0.6, 0.2)
                tooltip:AddLine("Não foi possível identificar esta oferta com segurança.", 1, 0.6, 0.2)
                tooltip:Show()
            end
            return
        end
        C.hover = { context = context, index = index, a = a, b = b, link = link }
        C.lastViews[context] = C.hover
        request(C.hover)
    end
    local function parseData(fields, hover)
        local data = {
            key = "view:" .. hover.context .. ":" .. hover.revision .. ":" .. fields[4],
            link = hover.link, level = tonumber(fields[5]), power = tonumber(fields[6]),
            entry = tonumber(fields[14]), stats = {},
            armorBase = tonumber(fields[15]), armorCurrent = tonumber(fields[16]),
            damageMinBase = tonumber(fields[18]), damageMaxBase = tonumber(fields[19]),
            damageMinCurrent = tonumber(fields[20]), damageMaxCurrent = tonumber(fields[21]),
            resistanceBase = tonumber(fields[64]), resistanceCurrent = tonumber(fields[65]),
            blockBase = tonumber(fields[67]), blockCurrent = tonumber(fields[68]),
            socketUnlocked = tonumber(fields[70]) == 1,
            socketGems = { tonumber(fields[71]) or 0, tonumber(fields[72]) or 0,
                tonumber(fields[73]) or 0 },
            maxLevel = tonumber(fields[74]) or 10,
        }
        for i = 1, 10 do
            local f = 24 + (i - 1) * 4
            table.insert(data.stats, { type = tonumber(fields[f]), base = tonumber(fields[f+1]),
                current = tonumber(fields[f+2]), target = tonumber(fields[f+3]) })
        end
        return data
    end
    function C:Message(message)
        if type(message) ~= "string" or string.sub(message, 1, 7) ~= "IKA_RV|" then return end
        local f = split(message)
        if f[2] == "HELLO" then
            self.ready = tonumber(f[3]) == 1 and tonumber(f[4]) == self.helloNonce
        elseif f[2] == "PAGE" then
            local context, revision, count = tonumber(f[3]), tonumber(f[4]), tonumber(f[5])
            if not context or context < 1 or context > 7 or not revision or
                not count or count < 0 or count > 4096 then return end
            self.pages[context] = { revision = revision, count = count, rows = {}, complete = context > 3 }
            if self.hover and self.hover.context == context and GameTooltip:IsShown() then
                if self.hover.applied then
                    clearHover()
                    GameTooltip:Hide()
                    return
                end
                request(self.hover)
            end
        elseif f[2] == "ROW" then
            local context, revision, index, level = tonumber(f[3]), tonumber(f[4]), tonumber(f[5]), tonumber(f[6])
            local page = context and self.pages[context]
            if #f ~= 13 or not page or page.revision ~= revision or not index or
                index < 1 or index > page.count or not level then return end
            page.rows[index] = { level = level, fingerprint = table.concat(f, "|", 7, 13) }
            if context <= 3 then self.lastViews[context] = nil end
        elseif f[2] == "DONE" then
            local context, revision = tonumber(f[3]), tonumber(f[4])
            local page = context and self.pages[context]
            if not page or page.revision ~= revision then return end
            page.complete = true
            if self.hover and self.hover.context == context and GameTooltip:IsShown() then request(self.hover) end
        elseif f[2] == "DATA" then
            local hover = self.hover
            if #f ~= 74 or not hover or tonumber(f[3]) ~= hover.nonce or
                not GameTooltip:IsShown() then return end
            local page = self.pages[hover.context]
            if not page or page.revision ~= hover.revision or
                itemLink(hover.context, hover.a, hover.b) ~= hover.link then return end
            if hover.context <= 3 and
                auctionFingerprint(hover.context, hover.a, hover.link) ~= hover.fingerprint then return end
            local data = parseData(f, hover)
            if data.entry ~= tonumber(string.match(hover.link, "item:(%d+)")) or
                not data.level or data.level < 0 or data.level > 10 or not data.power then return end
            -- Level zero is a valid result, not a stale +N carried from another item.
            hover.data = data
            Forge:ApplyReforgeTooltip(GameTooltip, data)
            hover.applied = true
        elseif f[2] == "ERROR" then
            if self.hover and tonumber(f[3]) == self.hover.nonce and GameTooltip:IsShown() then
                GameTooltip:AddLine("IKA Reforge: atualize a lista e passe o mouse novamente.", 1, 0.7, 0.2)
                GameTooltip:Show()
            end
        end
    end
    local frame = CreateFrame("Frame")
    C.eventFrame = frame
    local events = {
        "PLAYER_ENTERING_WORLD", "CHAT_MSG_SYSTEM", "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED",
        "AUCTION_ITEM_LIST_UPDATE", "AUCTION_OWNED_LIST_UPDATE", "AUCTION_BIDDER_LIST_UPDATE",
        "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "TRADE_SHOW", "TRADE_CLOSED",
        "TRADE_PLAYER_ITEM_CHANGED", "TRADE_TARGET_ITEM_CHANGED", "PLAYER_TARGET_CHANGED",
    }
    -- Feature-tolerant registration: older clients may omit a redundant event.
    for _, name in ipairs(events) do pcall(frame.RegisterEvent, frame, name) end
    frame:SetScript("OnEvent", function(_, eventName, message)
        eventName = eventName or event
        message = message or arg1
        if eventName == "PLAYER_ENTERING_WORLD" then
            clearHover()
            C.pages = {}
            C.lastViews = {}
            C.ready = false
            C.helloNonce = nextNonce()
            SendChatMessage(".reforge ui view 0 0 0 " .. C.helloNonce, "SAY")
        elseif eventName == "CHAT_MSG_SYSTEM" then
            C:Message(message)
        elseif eventName == "AUCTION_ITEM_LIST_UPDATE" or eventName == "AUCTION_OWNED_LIST_UPDATE" or
            eventName == "AUCTION_BIDDER_LIST_UPDATE" then
            -- Also fired for purely client-side sorting: public fingerprints stay valid.
            -- A fresh server page gets a fresh revision and rejects old queries.
            for context = 1, 3 do C.lastViews[context] = nil end
            if C.hover and C.hover.context <= 3 then clearHover(); GameTooltip:Hide() end
        elseif eventName == "AUCTION_HOUSE_SHOW" or eventName == "AUCTION_HOUSE_CLOSED" then
            for context = 1, 3 do invalidate(context) end
        elseif eventName == "MAIL_SHOW" or eventName == "MAIL_CLOSED" or eventName == "MAIL_INBOX_UPDATE" then
            invalidate(4)
        elseif eventName == "TRADE_SHOW" or eventName == "TRADE_CLOSED" then
            invalidate(5); invalidate(6)
        elseif eventName == "TRADE_PLAYER_ITEM_CHANGED" then invalidate(5)
        elseif eventName == "TRADE_TARGET_ITEM_CHANGED" then invalidate(6)
        elseif eventName == "PLAYER_TARGET_CHANGED" then invalidate(7)
        end
    end)
    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipCleared", clearHover)
        GameTooltip:HookScript("OnHide", clearHover)
    end
    local function hook(method, callback)
        if hooksecurefunc and GameTooltip and GameTooltip[method] then
            hooksecurefunc(GameTooltip, method, callback)
        end
    end
    hook("SetAuctionItem", function(tooltip, kind, index)
        beginHover(tooltip, contexts[kind], index, index)
    end)
    hook("SetInboxItem", function(tooltip, mailIndex, attachmentIndex)
        attachmentIndex = attachmentIndex or 1
        if mailIndex then
            beginHover(tooltip, 4, (mailIndex - 1) * 12 + attachmentIndex, mailIndex, attachmentIndex)
        end
    end)
    hook("SetTradePlayerItem", function(tooltip, index) beginHover(tooltip, 5, index, index) end)
    hook("SetTradeTargetItem", function(tooltip, index) beginHover(tooltip, 6, index, index) end)
    hook("SetInventoryItem", function(tooltip, unit, inventorySlot)
        if unit and unit ~= "player" and inventorySlot then
            beginHover(tooltip, 7, inventorySlot, unit, inventorySlot)
        end
    end)
    if ChatFrame_AddMessageEventFilter then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(a, b, c)
            -- TBC uses globals; compatibility addons may pass modern arguments.
            for _, value in pairs({ a, b, c, arg1 }) do
                if type(value) == "string" and
                    (string.sub(value, 1, 7) == "IKA_RV|" or string.sub(value, 1, 7) == "IKA_RF|") then
                    return true
                end
            end
            return false
        end)
    end
end

-- Links de chat do cliente 2.4.3 não carregam o GUID da instância. O núcleo
-- acrescenta +N ao nome somente quando consegue identificar o item do remetente
-- sem ambiguidade. Ao clicar, repetimos apenas nível e poder (dados determinísticos),
-- sem inventar atributos específicos que não viajaram no hyperlink nativo.
do
    local powers = {
        [1] = 11060, [2] = 12120, [3] = 13180, [4] = 14240, [5] = 15300,
        [6] = 16360, [7] = 17420, [8] = 18480, [9] = 19540, [10] = 20600,
    }
    local function decorateChatReference(link, text)
        if not ItemRefTooltip or type(link) ~= "string" or
            string.sub(link, 1, 5) ~= "item:" then return end
        local level = tonumber(string.match(text or "", "%+(%d+)%]")) or
            tonumber(string.match(text or "", " %+(%d+)$"))
        if not level or not powers[level] then return end
        local stamp = link .. ":" .. level
        if ItemRefTooltip.ikaReforgeChatStamp == stamp then return end
        ItemRefTooltip.ikaReforgeChatStamp = stamp

        local title = getglobal and getglobal(ItemRefTooltip:GetName() .. "TextLeft1")
        if title and title:GetText() and not string.find(title:GetText(), " %+%d+$") then
            title:SetText(title:GetText() .. " +" .. level)
        end
        ItemRefTooltip:AddLine(" ")
        ItemRefTooltip:AddLine(
            "IKA Reforge +" .. level,
            GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3])
        ItemRefTooltip:AddDoubleLine(
            "Poder do equipamento", FormatBasisPoints(powers[level]),
            0.82, 0.77, 0.68, GREEN[1], GREEN[2], GREEN[3])
        ItemRefTooltip:Show()
    end
    if hooksecurefunc and SetItemRef and ItemRefTooltip then
        hooksecurefunc("SetItemRef", decorateChatReference)
        if ItemRefTooltip.HookScript then
            ItemRefTooltip:HookScript("OnTooltipCleared", function()
                ItemRefTooltip.ikaReforgeChatStamp = nil
            end)
            ItemRefTooltip:HookScript("OnHide", function()
                ItemRefTooltip.ikaReforgeChatStamp = nil
            end)
        end
    end
end
