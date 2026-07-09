--!strict
-- TycoonClient.luau
-- Logica Client: HUD Glassmorphism, Shop Gacha, Corsa Ctrl, Combattimento PvP con Animator e Scambi P2P.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Helper per convertire il livello del difensore in nome visuale
local function getDefenderName(tier: number): string
	if tier == 0 then return "Nessuno" end
	if tier == 1 then return "Incel" end
	if tier == 2 then return "Goat" end
	if tier == 3 then return "Sigma" end
	return "Aura CEO"
end

-- Attende che leaderstats sia caricato
local leaderstats = player:WaitForChild("leaderstats") :: Folder
local shecklesVal = leaderstats:WaitForChild("Sheckles") :: IntValue
local generatorVal = leaderstats:WaitForChild("Generator") :: IntValue
local storageVal = leaderstats:WaitForChild("Storage") :: IntValue
local defenderVal = leaderstats:WaitForChild("Defender") :: IntValue

-- Creazione procedurale della ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AuraTycoonHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- ==========================================
-- 1. PANNELLO HUD PRINCIPALE (A SINISTRA)
-- ==========================================
local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUDFrame"
hudFrame.Size = UDim2.new(0, 220, 0, 210)
hudFrame.Position = UDim2.new(0, 20, 0.25, 0)
hudFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
hudFrame.BackgroundTransparency = 0.35
hudFrame.BorderSizePixel = 0
hudFrame.Parent = screenGui

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 12)
hudCorner.Parent = hudFrame

local hudStroke = Instance.new("UIStroke")
hudStroke.Color = Color3.fromRGB(0, 240, 255)
hudStroke.Thickness = 1.5
hudStroke.Transparency = 0.4
hudStroke.Parent = hudFrame

local hudTitle = Instance.new("TextLabel")
hudTitle.Size = UDim2.new(1, 0, 0, 35)
hudTitle.BackgroundTransparency = 1
hudTitle.Text = "AURA TYCOON 2026"
hudTitle.TextColor3 = Color3.fromRGB(0, 240, 255)
hudTitle.TextSize = 16
hudTitle.Font = Enum.Font.SourceSansBold
hudTitle.Parent = hudFrame

local walletLabel = Instance.new("TextLabel")
walletLabel.Size = UDim2.new(1, -20, 0, 30)
walletLabel.Position = UDim2.new(0, 10, 0, 40)
walletLabel.BackgroundTransparency = 1
walletLabel.Text = "Portafoglio: " .. shecklesVal.Value .. " $"
walletLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
walletLabel.TextSize = 14
walletLabel.TextXAlignment = Enum.TextXAlignment.Left
walletLabel.Font = Enum.Font.SourceSans
walletLabel.Parent = hudFrame

local genLabel = Instance.new("TextLabel")
genLabel.Size = UDim2.new(1, -20, 0, 30)
genLabel.Position = UDim2.new(0, 10, 0, 70)
genLabel.BackgroundTransparency = 1
genLabel.Text = "Generatore: Lvl " .. generatorVal.Value
genLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
genLabel.TextSize = 14
genLabel.TextXAlignment = Enum.TextXAlignment.Left
genLabel.Font = Enum.Font.SourceSans
genLabel.Parent = hudFrame

local storageLabel = Instance.new("TextLabel")
storageLabel.Size = UDim2.new(1, -20, 0, 30)
storageLabel.Position = UDim2.new(0, 10, 0, 100)
storageLabel.BackgroundTransparency = 1
storageLabel.Text = "Cassa Lotto: " .. storageVal.Value .. " $"
storageLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
storageLabel.TextSize = 14
storageLabel.TextXAlignment = Enum.TextXAlignment.Left
storageLabel.Font = Enum.Font.SourceSans
storageLabel.Parent = hudFrame

local defenderLabel = Instance.new("TextLabel")
defenderLabel.Size = UDim2.new(1, -20, 0, 30)
defenderLabel.Position = UDim2.new(0, 10, 0, 130)
defenderLabel.BackgroundTransparency = 1
defenderLabel.Text = "Difensore: " .. getDefenderName(defenderVal.Value)
defenderLabel.TextColor3 = Color3.fromRGB(255, 196, 0)
defenderLabel.TextSize = 14
defenderLabel.TextXAlignment = Enum.TextXAlignment.Left
defenderLabel.Font = Enum.Font.SourceSans
defenderLabel.Parent = hudFrame

local openMenuBtn = Instance.new("TextButton")
openMenuBtn.Size = UDim2.new(1, -20, 0, 30)
openMenuBtn.Position = UDim2.new(0, 10, 0, 165)
openMenuBtn.BackgroundColor3 = Color3.fromRGB(189, 0, 255)
openMenuBtn.Text = "MENU GIOCO / SCAMBI"
openMenuBtn.TextColor3 = Color3.new(1, 1, 1)
openMenuBtn.Font = Enum.Font.SourceSansBold
openMenuBtn.TextSize = 14
openMenuBtn.Parent = hudFrame

Instance.new("UICorner", openMenuBtn).CornerRadius = UDim.new(0, 6)

shecklesVal.Changed:Connect(function(val) walletLabel.Text = "Portafoglio: " .. val .. " $" end)
generatorVal.Changed:Connect(function(val) genLabel.Text = "Generatore: Lvl " .. val end)
storageVal.Changed:Connect(function(val) storageLabel.Text = "Cassa Lotto: " .. val .. " $" end)
defenderVal.Changed:Connect(function(val) defenderLabel.Text = "Difensore: " .. getDefenderName(val) end)


-- ==========================================
-- 2. PANNELLO MENU PRINCIPALE (CENTRO CON TABS)
-- ==========================================
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 440, 0, 340)
menuFrame.Position = UDim2.new(0.5, -220, 0.5, -170)
menuFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
menuFrame.BackgroundTransparency = 0.2
menuFrame.Visible = false
menuFrame.Parent = screenGui

Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 12)
local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(189, 0, 255)
menuStroke.Thickness = 1.5
menuStroke.Transparency = 0.4
menuStroke.Parent = menuFrame

-- Pulsante Chiudi
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 0, 85)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 18
closeBtn.Parent = menuFrame

-- Azioni di apertura e chiusura del menu
openMenuBtn.MouseButton1Click:Connect(function()
	menuFrame.Visible = not menuFrame.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
	menuFrame.Visible = false
end)

-- Navigation Tabs
local tabShopBtn = Instance.new("TextButton")
tabShopBtn.Size = UDim2.new(0, 180, 0, 35)
tabShopBtn.Position = UDim2.new(0, 15, 0, 10)
tabShopBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
tabShopBtn.Text = "SHOP & GACHA"
tabShopBtn.TextColor3 = Color3.new(1, 1, 1)
tabShopBtn.Font = Enum.Font.SourceSansBold
tabShopBtn.TextSize = 13
tabShopBtn.Parent = menuFrame
Instance.new("UICorner", tabShopBtn).CornerRadius = UDim.new(0, 6)

local tabTradeBtn = Instance.new("TextButton")
tabTradeBtn.Size = UDim2.new(0, 180, 0, 35)
tabTradeBtn.Position = UDim2.new(0, 205, 0, 10)
tabTradeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
tabTradeBtn.Text = "COMMERCIA (P2P)"
tabTradeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
tabTradeBtn.Font = Enum.Font.SourceSansBold
tabTradeBtn.TextSize = 13
tabTradeBtn.Parent = menuFrame
Instance.new("UICorner", tabTradeBtn).CornerRadius = UDim.new(0, 6)

-- CONTENITORE TAB SHOP
local shopTabFrame = Instance.new("Frame")
shopTabFrame.Size = UDim2.new(1, -20, 1, -60)
shopTabFrame.Position = UDim2.new(0, 10, 0, 50)
shopTabFrame.BackgroundTransparency = 1
shopTabFrame.Parent = menuFrame

-- CONTENITORE TAB TRADE
local tradeTabFrame = Instance.new("Frame")
tradeTabFrame.Size = UDim2.new(1, -20, 1, -60)
tradeTabFrame.Position = UDim2.new(0, 10, 0, 50)
tradeTabFrame.BackgroundTransparency = 1
tradeTabFrame.Visible = false
tradeTabFrame.Parent = menuFrame

-- Switch Tabs Logic
tabShopBtn.MouseButton1Click:Connect(function()
	shopTabFrame.Visible = true
	tradeTabFrame.Visible = false
	tabShopBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	tabShopBtn.TextColor3 = Color3.new(1, 1, 1)
	tabTradeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	tabTradeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
end)
tabTradeBtn.MouseButton1Click:Connect(function()
	shopTabFrame.Visible = false
	tradeTabFrame.Visible = true
	tabTradeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	tabTradeBtn.TextColor3 = Color3.new(1, 1, 1)
	tabShopBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	tabShopBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
end)

-- ----------------------------------------------------
-- ELEMENTI TAB SHOP (GACHA & UPGRADES)
-- ----------------------------------------------------
local gachaBtn = Instance.new("TextButton")
gachaBtn.Size = UDim2.new(0, 180, 0, 40)
gachaBtn.Position = UDim2.new(0, 10, 0, 20)
gachaBtn.BackgroundColor3 = Color3.fromRGB(189, 0, 255)
gachaBtn.Text = "ROLL GACHA (20 $)"
gachaBtn.TextColor3 = Color3.new(1, 1, 1)
gachaBtn.Font = Enum.Font.SourceSansBold
gachaBtn.TextSize = 14
gachaBtn.Parent = shopTabFrame
Instance.new("UICorner", gachaBtn).CornerRadius = UDim.new(0, 6)

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(0, 180, 0, 30)
resultLabel.Position = UDim2.new(0, 10, 0, 65)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = "Nessun roll effettuato"
resultLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
resultLabel.TextSize = 13
resultLabel.Font = Enum.Font.SourceSansItalic
resultLabel.Parent = shopTabFrame

local upgradeDefBtn = Instance.new("TextButton")
upgradeDefBtn.Size = UDim2.new(0, 180, 0, 50)
upgradeDefBtn.Position = UDim2.new(0, 10, 0, 110)
upgradeDefBtn.BackgroundColor3 = Color3.fromRGB(255, 196, 0)
upgradeDefBtn.Text = "POTENZIA DIFENSORE\n(Costo: Incel 100 $)"
upgradeDefBtn.TextColor3 = Color3.fromRGB(15, 15, 25)
upgradeDefBtn.Font = Enum.Font.SourceSansBold
upgradeDefBtn.TextSize = 13
upgradeDefBtn.Parent = shopTabFrame
Instance.new("UICorner", upgradeDefBtn).CornerRadius = UDim.new(0, 6)

local function updateDefenderButtonText()
	local currentTier = defenderVal.Value
	if currentTier == 0 then
		upgradeDefBtn.Text = "POTENZIA DIFENSORE\n(Costo Incel: 100 $)"
	elseif currentTier == 1 then
		upgradeDefBtn.Text = "POTENZIA A GOAT\n(Costo: 250 $)"
	elseif currentTier == 2 then
		upgradeDefBtn.Text = "POTENZIA A SIGMA\n(Costo: 500 $)"
	elseif currentTier == 3 then
		upgradeDefBtn.Text = "POTENZIA A AURA CEO\n(Costo: 1000 $)"
	else
		upgradeDefBtn.Text = "DIFENSORE AL MASSIMO\n(Aura CEO Attivo)"
	end
end
defenderVal.Changed:Connect(updateDefenderButtonText)
updateDefenderButtonText()

local listTitle = Instance.new("TextLabel")
listTitle.Size = UDim2.new(0, 180, 0, 20)
listTitle.Position = UDim2.new(0, 210, 0, 15)
listTitle.BackgroundTransparency = 1
listTitle.Text = "I tuoi Cosmetici:"
listTitle.TextColor3 = Color3.new(1, 1, 1)
listTitle.TextSize = 14
listTitle.Font = Enum.Font.SourceSansBold
listTitle.TextXAlignment = Enum.TextXAlignment.Left
listTitle.Parent = shopTabFrame

local inventoryScroll = Instance.new("ScrollingFrame")
inventoryScroll.Size = UDim2.new(0, 190, 0, 200)
inventoryScroll.Position = UDim2.new(0, 210, 0, 40)
inventoryScroll.BackgroundTransparency = 0.8
inventoryScroll.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
inventoryScroll.BorderSizePixel = 0
inventoryScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
inventoryScroll.Parent = shopTabFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.Parent = inventoryScroll

local function refreshInventoryUI()
	for _, child in ipairs(inventoryScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local inventory = player:GetAttribute("Inventory") or ""
	if inventory == "" then
		local empty = Instance.new("TextButton")
		empty.Size = UDim2.new(1, 0, 0, 30)
		empty.BackgroundTransparency = 1
		empty.Text = "Nessun cosmetico"
		empty.TextColor3 = Color3.fromRGB(100, 100, 100)
		empty.Font = Enum.Font.SourceSansItalic
		empty.TextSize = 12
		empty.Parent = inventoryScroll
		return
	end
	local items = string.split(inventory, ",")
	for _, itemName in ipairs(items) do
		if itemName == "" then continue end
		local itemBtn = Instance.new("TextButton")
		itemBtn.Size = UDim2.new(1, -10, 0, 28)
		itemBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
		itemBtn.Text = itemName
		itemBtn.TextColor3 = string.find(itemName, "★") and Color3.fromRGB(255, 196, 0) or Color3.fromRGB(255, 255, 255)
		itemBtn.Font = Enum.Font.SourceSansBold
		itemBtn.TextSize = 12
		itemBtn.Parent = inventoryScroll
		Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 4)
		
		itemBtn.MouseButton1Click:Connect(function()
			local equipCosmeticRemote = ReplicatedStorage:WaitForChild("EquipCosmeticRemote") :: RemoteEvent
			equipCosmeticRemote:FireServer(itemName)
			itemBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
			task.wait(0.2)
			itemBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
		end)
	end
end

gachaBtn.MouseButton1Click:Connect(function()
	if not gachaBtn.Active then return end
	gachaBtn.Active = false
	local initialText = gachaBtn.Text
	local initialPosition = gachaBtn.Position
	local initialColor = gachaBtn.BackgroundColor3
	
	task.spawn(function()
		local endTime = os.clock() + 1.2
		while os.clock() < endTime do
			gachaBtn.Position = initialPosition + UDim2.new(0, math.random(-6, 6), 0, math.random(-4, 4))
			gachaBtn.BackgroundColor3 = Color3.fromRGB(math.random(120, 255), math.random(0, 80), math.random(180, 255))
			task.wait(0.04)
		end
		gachaBtn.Position = initialPosition
		gachaBtn.BackgroundColor3 = initialColor
	end)
	
	gachaBtn.Text = "UNBOXING..."
	resultLabel.Text = "Estrazione in corso..."
	resultLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	resultLabel.TextSize = 13
	
	local startTime = os.clock()
	local openGachaRemote = ReplicatedStorage:WaitForChild("OpenGachaRemote") :: RemoteFunction
	local result = openGachaRemote:InvokeServer()
	
	local elapsed = os.clock() - startTime
	if elapsed < 1.2 then task.wait(1.2 - elapsed) end
	
	gachaBtn.Active = true
	gachaBtn.Text = initialText
	
	if result and result.Success then
		resultLabel.Text = "Sbloccato: " .. result.Item
		resultLabel.TextColor3 = result.Rarity == "legendary" and Color3.fromRGB(255, 196, 0) or 
		                         result.Rarity == "rare" and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(200, 200, 200)
		resultLabel.TextTransparency = 1
		resultLabel.TextSize = 22
		TweenService:Create(resultLabel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextTransparency = 0, TextSize = 14}):Play()
		player:SetAttribute("Inventory", result.Inventory)
		refreshInventoryUI()
	else
		resultLabel.Text = result and result.Error or "Errore di connessione"
		resultLabel.TextColor3 = Color3.fromRGB(255, 0, 85)
		resultLabel.TextTransparency = 1
		TweenService:Create(resultLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	end
end)

player:GetAttributeChangedSignal("Inventory"):Connect(refreshInventoryUI)
refreshInventoryUI()


-- ----------------------------------------------------
-- ELEMENTI TAB SCAMBI (P2P TRADING)
-- ----------------------------------------------------
local tradeTitle = Instance.new("TextLabel")
tradeTitle.Size = UDim2.new(0, 200, 0, 20)
tradeTitle.Position = UDim2.new(0, 10, 0, 10)
tradeTitle.BackgroundTransparency = 1
tradeTitle.Text = "Giocatori nel Server:"
tradeTitle.TextColor3 = Color3.new(1, 1, 1)
tradeTitle.TextSize = 14
tradeTitle.Font = Enum.Font.SourceSansBold
tradeTitle.TextXAlignment = Enum.TextXAlignment.Left
tradeTitle.Parent = tradeTabFrame

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Size = UDim2.new(0, 190, 0, 210)
playersScroll.Position = UDim2.new(0, 10, 0, 35)
playersScroll.BackgroundTransparency = 0.8
playersScroll.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
playersScroll.BorderSizePixel = 0
playersScroll.Parent = tradeTabFrame
Instance.new("UIListLayout", playersScroll).Padding = UDim.new(0, 5)

-- Interfaccia di negoziazione attiva
local activeTradePanel = Instance.new("Frame")
activeTradePanel.Size = UDim2.new(0, 190, 0, 210)
activeTradePanel.Position = UDim2.new(0, 210, 0, 35)
activeTradePanel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
activeTradePanel.BackgroundTransparency = 0.5
activeTradePanel.Visible = false
activeTradePanel.Parent = tradeTabFrame
Instance.new("UICorner", activeTradePanel).CornerRadius = UDim.new(0, 8)

local activeTradeTitle = Instance.new("TextLabel")
activeTradeTitle.Size = UDim2.new(1, 0, 0, 30)
activeTradeTitle.BackgroundTransparency = 1
activeTradeTitle.Text = "Trattativa Attiva"
activeTradeTitle.TextColor3 = Color3.fromRGB(0, 240, 255)
activeTradeTitle.TextSize = 13
activeTradeTitle.Font = Enum.Font.SourceSansBold
activeTradeTitle.Parent = activeTradePanel

local selectedAuraLabel = Instance.new("TextLabel")
selectedAuraLabel.Size = UDim2.new(1, -20, 0, 30)
selectedAuraLabel.Position = UDim2.new(0, 10, 0, 35)
selectedAuraLabel.BackgroundTransparency = 1
selectedAuraLabel.Text = "Tua Offerta: Seleziona..."
selectedAuraLabel.TextColor3 = Color3.new(1, 1, 1)
selectedAuraLabel.TextSize = 11
selectedAuraLabel.Font = Enum.Font.SourceSans
selectedAuraLabel.Parent = activeTradePanel

local partnerOfferLabel = Instance.new("TextLabel")
partnerOfferLabel.Size = UDim2.new(1, -20, 0, 30)
partnerOfferLabel.Position = UDim2.new(0, 10, 0, 65)
partnerOfferLabel.BackgroundTransparency = 1
partnerOfferLabel.Text = "Offerta Partner: In attesa..."
partnerOfferLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
partnerOfferLabel.TextSize = 11
partnerOfferLabel.Font = Enum.Font.SourceSansItalic
partnerOfferLabel.Parent = activeTradePanel

local selectAuraBtn = Instance.new("TextButton")
selectAuraBtn.Size = UDim2.new(1, -20, 0, 30)
selectAuraBtn.Position = UDim2.new(0, 10, 0, 105)
selectAuraBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
selectAuraBtn.Text = "SCEGLI DALL'INV"
selectAuraBtn.TextColor3 = Color3.new(1, 1, 1)
selectAuraBtn.Font = Enum.Font.SourceSansBold
selectAuraBtn.TextSize = 11
selectAuraBtn.Parent = activeTradePanel
Instance.new("UICorner", selectAuraBtn).CornerRadius = UDim.new(0, 4)

local acceptTradeBtn = Instance.new("TextButton")
acceptTradeBtn.Size = UDim2.new(1, -20, 0, 35)
acceptTradeBtn.Position = UDim2.new(0, 10, 0, 150)
acceptTradeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
acceptTradeBtn.Text = "CONFERMA SCAMBIO"
acceptTradeBtn.TextColor3 = Color3.new(1, 1, 1)
acceptTradeBtn.Font = Enum.Font.SourceSansBold
acceptTradeBtn.TextSize = 12
acceptTradeBtn.Parent = activeTradePanel
Instance.new("UICorner", acceptTradeBtn).CornerRadius = UDim.new(0, 6)

local currentTradeOffer = ""

-- Rinfresca la lista dei giocatori commerciabili
local function refreshPlayersList()
	for _, child in ipairs(playersScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p == player then continue end
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -10, 0, 32)
		btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		btn.Text = "Scambia con: " .. p.Name
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.SourceSansBold
		btn.TextSize = 12
		btn.Parent = playersScroll
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		
		btn.MouseButton1Click:Connect(function()
			-- Invia invito di scambio via server
			local tradeInviteRemote = ReplicatedStorage:WaitForChild("TradeInviteRemote") :: RemoteEvent
			tradeInviteRemote:FireServer(p)
			btn.Text = "INVITO INVIATO!"
			btn.BackgroundColor3 = Color3.fromRGB(189, 0, 255)
			
			activeTradePanel.Visible = true
			selectedAuraLabel.Text = "Tua Offerta: Vuota/Seleziona..."
			partnerOfferLabel.Text = "Offerta Partner: In attesa..."
			currentTradeOffer = ""
		end)
	end
end
tabTradeBtn.MouseButton1Click:Connect(refreshPlayersList)
refreshPlayersList()

-- Selettore Aura per Scambio
selectAuraBtn.MouseButton1Click:Connect(function()
	-- Prende la prima aura nell'inventario per lo scambio rapido di test
	local inventory = player:GetAttribute("Inventory") or ""
	local items = string.split(inventory, ",")
	for _, item in ipairs(items) do
		if item ~= "" then
			currentTradeOffer = item
			selectedAuraLabel.Text = "Tua Offerta: " .. item
			break
		end
	end
	if currentTradeOffer == "" then
		selectedAuraLabel.Text = "Nessuna aura da offrire!"
	end
end)

-- Invia conferma dello scambio
acceptTradeBtn.MouseButton1Click:Connect(function()
	local tradeConfirmRemote = ReplicatedStorage:WaitForChild("TradeConfirmRemote") :: RemoteFunction
	acceptTradeBtn.Text = "CONFERMATO! ATTENDO..."
	acceptTradeBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
	
	local result = tradeConfirmRemote:InvokeServer("Confirm", currentTradeOffer)
	
	if result and result.Success then
		if result.Status == "Completed" then
			acceptTradeBtn.Text = "CONFERMA SCAMBIO"
			acceptTradeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
			activeTradePanel.Visible = false
			player:SetAttribute("Inventory", result.NewInventory)
			refreshInventoryUI()
			
			-- Mostra notifica di successo
			local popup = Instance.new("Frame")
			popup.Size = UDim2.new(0, 200, 0, 50)
			popup.Position = UDim2.new(0.5, -100, 0.4, 0)
			popup.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
			popup.Parent = screenGui
			Instance.new("UICorner", popup)
			
			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(1,0,1,0)
			l.Text = "SCAMBIO COMPLETATO!"
			l.TextColor3 = Color3.new(1,1,1)
			l.Font = Enum.Font.SourceSansBold
			l.BackgroundTransparency = 1
			l.Parent = popup
			task.delay(3, function() popup:Destroy() end)
		end
	else
		acceptTradeBtn.Text = "ERRORE SCAMBIO"
		acceptTradeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 85)
		task.wait(1.5)
		acceptTradeBtn.Text = "CONFERMA SCAMBIO"
		acceptTradeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	end
end)

-- Gestione inviti entranti da altri player
local tradeInviteRemote = ReplicatedStorage:WaitForChild("TradeInviteRemote") :: RemoteEvent
tradeInviteRemote.OnClientEvent:Connect(function(partnerPlayer, status, extraData)
	if status == "Success" then
		-- Scambio completato, chiudi e rinfresca
		activeTradePanel.Visible = false
		refreshInventoryUI()
		return
	end
	
	if status == "Confirmed" then
		-- Partner ha offerto qualcosa
		partnerOfferLabel.Text = "Offerta Partner: " .. (extraData or "Vuota")
		partnerOfferLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
		return
	end
	
	if partnerPlayer == nil then
		-- Chiusura/annullamento scambio
		activeTradePanel.Visible = false
		acceptTradeBtn.Text = "CONFERMA SCAMBIO"
		acceptTradeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		return
	end
	
	-- Invito di scambio ricevuto
	local invitePanel = Instance.new("Frame")
	invitePanel.Size = UDim2.new(0, 260, 0, 100)
	invitePanel.Position = UDim2.new(0.5, -130, 0.4, 0)
	invitePanel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	invitePanel.Parent = screenGui
	Instance.new("UICorner", invitePanel)
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Text = "Scambio da " .. partnerPlayer.Name .. "?\nVuoi commerciare?"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.SourceSansBold
	title.BackgroundTransparency = 1
	title.TextSize = 13
	title.Parent = invitePanel
	
	local acceptBtn = Instance.new("TextButton")
	acceptBtn.Size = UDim2.new(0, 100, 0, 30)
	acceptBtn.Position = UDim2.new(0, 20, 0, 55)
	acceptBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	acceptBtn.Text = "ACCETTA"
	acceptBtn.TextColor3 = Color3.new(1,1,1)
	acceptBtn.Font = Enum.Font.SourceSansBold
	acceptBtn.Parent = invitePanel
	Instance.new("UICorner", acceptBtn)
	
	local declineBtn = Instance.new("TextButton")
	declineBtn.Size = UDim2.new(0, 100, 0, 30)
	declineBtn.Position = UDim2.new(0, 140, 0, 55)
	declineBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 85)
	declineBtn.Text = "DECLINA"
	declineBtn.TextColor3 = Color3.new(1,1,1)
	declineBtn.Font = Enum.Font.SourceSansBold
	declineBtn.Parent = invitePanel
	Instance.new("UICorner", declineBtn)
	
	acceptBtn.MouseButton1Click:Connect(function()
		invitePanel:Destroy()
		-- Accetta sul server (simula rispondendo con invito reciproco)
		tradeInviteRemote:FireServer(partnerPlayer)
		
		-- Apri pannello commerci
		menuFrame.Visible = true
		tabTradeBtn:Click() -- Simula il click
		activeTradePanel.Visible = true
		selectedAuraLabel.Text = "Tua Offerta: Vuota/Seleziona..."
		partnerOfferLabel.Text = "Offerta Partner: In attesa..."
		currentTradeOffer = ""
	end)
	
	declineBtn.MouseButton1Click:Connect(function()
		invitePanel:Destroy()
		local tradeConfirmRemoteObj = ReplicatedStorage:WaitForChild("TradeConfirmRemote") :: RemoteFunction
		tradeConfirmRemoteObj:InvokeServer("Decline", "")
	end)
end)


-- ==========================================
-- 3. LOGICA DI SPRINT VELOCE (CTRL E BOTTONE MOBILE)
-- ==========================================
local sprintBtn = Instance.new("TextButton")
sprintBtn.Name = "SprintButton"
sprintBtn.Size = UDim2.new(0, 60, 0, 60)
sprintBtn.Position = UDim2.new(0.85, -20, 0.75, -20)
sprintBtn.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
sprintBtn.BackgroundTransparency = 0.4
sprintBtn.Text = "RUN"
sprintBtn.TextColor3 = Color3.fromRGB(15, 15, 25)
sprintBtn.Font = Enum.Font.SourceSansBold
sprintBtn.TextSize = 14
sprintBtn.Parent = screenGui

local sprintCorner = Instance.new("UICorner")
sprintCorner.CornerRadius = UDim.new(0.5, 0)
sprintCorner.Parent = sprintBtn

local sprintStroke = Instance.new("UIStroke")
sprintStroke.Color = Color3.fromRGB(255, 255, 255)
sprintStroke.Thickness = 1.5
sprintStroke.Transparency = 0.5
sprintStroke.Parent = sprintBtn

local function getHumanoid(): Humanoid?
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

local function setSprintActive(active: boolean)
	local humanoid = getHumanoid()
	if humanoid then
		if active then
			humanoid.WalkSpeed = 36
			sprintBtn.BackgroundColor3 = Color3.fromRGB(255, 196, 0)
			sprintBtn.BackgroundTransparency = 0.2
		else
			humanoid.WalkSpeed = 16
			sprintBtn.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
			sprintBtn.BackgroundTransparency = 0.4
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		setSprintActive(true)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		setSprintActive(false)
	end
end)

sprintBtn.MouseButton1Down:Connect(function() setSprintActive(true) end)
sprintBtn.MouseButton1Up:Connect(function() setSprintActive(false) end)
sprintBtn.MouseLeave:Connect(function() setSprintActive(false) end)


-- ==========================================
-- 4. CAMERA SHAKE ED EFFETTI KNOCKBACK DI TIER
-- ==========================================
local GnomeTriggerRemote = ReplicatedStorage:WaitForChild("GnomeTriggerRemote")
GnomeTriggerRemote.OnClientEvent:Connect(function(attacker, defenderTier)
	local tier = defenderTier or 1
	print("[Client] Knockback da difensore Tier " .. tier .. "! Avvio camera shake...")
	
	local shakeIntensity = 0.2
	local shakeDuration = 0.4
	local velocityVec = Vector3.new(0, 50, -35)
	
	if tier == 2 then
		shakeIntensity = 0.45
		shakeDuration = 0.5
		velocityVec = Vector3.new(0, 80, -60)
	elseif tier == 3 then
		shakeIntensity = 0.8
		shakeDuration = 0.65
		velocityVec = Vector3.new(0, 110, -90)
	elseif tier == 4 then
		shakeIntensity = 1.4
		shakeDuration = 0.95
		velocityVec = Vector3.new(0, 160, -145)
	end
	
	local camera = game:GetService("Workspace").CurrentCamera
	if camera then
		local endTime = os.clock() + shakeDuration
		task.spawn(function()
			while os.clock() < endTime do
				local shakeOffset = CFrame.new(
					(math.random() - 0.5) * shakeIntensity,
					(math.random() - 0.5) * shakeIntensity,
					(math.random() - 0.5) * shakeIntensity
				) * CFrame.Angles(
					(math.random() - 0.5) * (shakeIntensity * 0.1),
					(math.random() - 0.5) * (shakeIntensity * 0.1),
					(math.random() - 0.5) * (shakeIntensity * 0.1)
				)
				camera.CFrame = camera.CFrame * shakeOffset
				task.wait(0.01)
			end
		end)
	end
	
	local character = player.Character
	if character then
		local hrp = character:WaitForChild("HumanoidRootPart")
		if hrp then
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = velocityVec
			bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
			bodyVelocity.Parent = hrp
			task.wait(0.35)
			bodyVelocity:Destroy()
		end
	end
end)

-- Moments API Trigger locale
local promptMomentRemote = ReplicatedStorage:WaitForChild("PromptMomentCapture")
promptMomentRemote.OnClientEvent:Connect(function(actionType, score)
	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0, 300, 0, 60)
	popup.Position = UDim2.new(0.5, -150, 0.8, 0)
	popup.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
	popup.Parent = screenGui
	Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 8)

	local popupLabel = Instance.new("TextLabel")
	popupLabel.Size = UDim2.new(1, 0, 1, 0)
	popupLabel.BackgroundTransparency = 1
	popupLabel.Text = "RAPINA EPICA DA +" .. score .. " COINS!\nCondividi Moment su Roblox Moments?"
	popupLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	popupLabel.Font = Enum.Font.SourceSansBold
	popupLabel.TextSize = 14
	popupLabel.Parent = popup
	
	task.wait(4)
	popup:Destroy()
end)


-- ==========================================
-- 5. LOGICA DI COMBATTIMENTO PVP (SCHIAFFO CON ANIMATOR)
-- ==========================================
local slapBtn = Instance.new("TextButton")
slapBtn.Name = "SlapButton"
slapBtn.Size = UDim2.new(0, 60, 0, 60)
slapBtn.Position = UDim2.new(0.85, -20, 0.75, -90)
slapBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 85)
slapBtn.BackgroundTransparency = 0.4
slapBtn.Text = "SLAP"
slapBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
slapBtn.Font = Enum.Font.SourceSansBold
slapBtn.TextSize = 14
slapBtn.Parent = screenGui

local slapCorner = Instance.new("UICorner")
slapCorner.CornerRadius = UDim.new(0.5, 0)
slapCorner.Parent = slapBtn

local slapStroke = Instance.new("UIStroke")
slapStroke.Color = Color3.fromRGB(255, 255, 255)
slapStroke.Thickness = 1.5
slapStroke.Transparency = 0.5
slapStroke.Parent = slapBtn

local lastSlapTime = 0
local SLAP_COOLDOWN_CLIENT = 0.5

-- Esegue l'animazione di swing nativa sul personaggio tramite un Tool temporaneo con Handle invisibile (Replicazione e attivazione garantita)
local function playSwingAnimation()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		print("[playSwingAnimation] Generazione Tool temporaneo con Handle per lo schiaffo...")
		local tool = Instance.new("Tool")
		tool.Name = "Slap"
		tool.RequiresHandle = true -- Richiede Handle fisico per attivare l'animazione di swing del braccio
		
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.2, 0.2, 0.2)
		handle.Transparency = 1 -- Completamente invisibile
		handle.CanCollide = false
		handle.Massless = true
		handle.Parent = tool
		
		-- Da client, l'equipaggiamento si esegue impostando direttamente il Parent sul Character
		tool.Parent = char
		
		task.spawn(function()
			task.wait() -- Attendi un frame per la stabilità del joint
			tool:Activate()
			task.wait(0.25)
			if tool.Parent == char then
				local backpack = player:FindFirstChild("Backpack")
				if backpack then
					tool.Parent = backpack
				end
			end
			tool:Destroy()
			print("[playSwingAnimation] Tool e Handle distrutti con successo.")
		end)
	end
end

local function triggerSlapAttack()
	local nowTime = os.clock()
	if nowTime - lastSlapTime < SLAP_COOLDOWN_CLIENT then return end
	lastSlapTime = nowTime
	
	playSwingAnimation()
	
	local slapSwingRemote = ReplicatedStorage:FindFirstChild("SlapSwingRemote") :: RemoteEvent
	if slapSwingRemote then
		slapSwingRemote:FireServer()
	end
	
	slapBtn.BackgroundTransparency = 0.15
	task.spawn(function()
		task.wait(0.15)
		slapBtn.BackgroundTransparency = 0.4
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		triggerSlapAttack()
	end
end)

slapBtn.MouseButton1Click:Connect(triggerSlapAttack)

return {}
