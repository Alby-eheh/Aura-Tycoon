--!strict
-- TycoonClient.luau
-- Logica Client: GUI HUD procedurale (Glassmorphism), input mobile/PC e Camera Shake.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Disabilita la GUI di default se necessario (facoltativo)
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
end)

-- Attende che leaderstats sia caricato
local leaderstats = player:WaitForChild("leaderstats", 10) :: Folder
assert(leaderstats, "Leaderstats non caricati in tempo!")

local shecklesVal = leaderstats:WaitForChild("Sheckles", 10) :: IntValue
local generatorVal = leaderstats:WaitForChild("Generator", 10) :: IntValue
local storageVal = leaderstats:WaitForChild("Storage", 10) :: IntValue

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
hudFrame.Size = UDim2.new(0, 220, 0, 180)
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

-- Wallet Sheckles
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

-- Livello Generatore
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

-- Storage accumulato
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

-- Pulsante per aprire il Menu Centrale
local openMenuBtn = Instance.new("TextButton")
openMenuBtn.Size = UDim2.new(1, -20, 0, 30)
openMenuBtn.Position = UDim2.new(0, 10, 0, 135)
openMenuBtn.BackgroundColor3 = Color3.fromRGB(189, 0, 255)
openMenuBtn.Text = "APRI SHOP & GACHA"
openMenuBtn.TextColor3 = Color3.new(1, 1, 1)
openMenuBtn.Font = Enum.Font.SourceSansBold
openMenuBtn.TextSize = 14
openMenuBtn.Parent = hudFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = openMenuBtn

-- Aggiorna i valori in tempo reale legati agli IntValues
shecklesVal.Changed:Connect(function(val)
	walletLabel.Text = "Portafoglio: " .. val .. " $"
end)
generatorVal.Changed:Connect(function(val)
	genLabel.Text = "Generatore: Lvl " .. val
end)
storageVal.Changed:Connect(function(val)
	storageLabel.Text = "Cassa Lotto: " .. val .. " $"
end)


-- ==========================================
-- 2. PANNELLO MENU PRINCIPALE (CENTRO)
-- ==========================================
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 400, 0, 300)
menuFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
menuFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
menuFrame.BackgroundTransparency = 0.2
menuFrame.Visible = false
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 12)
menuCorner.Parent = menuFrame

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(189, 0, 255)
menuStroke.Thickness = 1.5
menuStroke.Transparency = 0.4
menuStroke.Parent = menuFrame

-- Titolo Menu
local menuTitle = Instance.new("TextLabel")
menuTitle.Size = UDim2.new(1, 0, 0, 40)
menuTitle.BackgroundTransparency = 1
menuTitle.Text = "SHOP COSMETICI & UNBOXING"
menuTitle.TextColor3 = Color3.fromRGB(189, 0, 255)
menuTitle.TextSize = 16
menuTitle.Font = Enum.Font.SourceSansBold
menuTitle.Parent = menuFrame

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

-- Bottone Gacha Unbox
local gachaBtn = Instance.new("TextButton")
gachaBtn.Size = UDim2.new(0, 180, 0, 50)
gachaBtn.Position = UDim2.new(0, 20, 0, 70)
gachaBtn.BackgroundColor3 = Color3.fromRGB(189, 0, 255)
gachaBtn.Text = "APRI CASSA\n(Costo: 20 Sheckles)"
gachaBtn.TextColor3 = Color3.new(1, 1, 1)
gachaBtn.Font = Enum.Font.SourceSansBold
gachaBtn.TextSize = 14
gachaBtn.Parent = menuFrame
Instance.new("UICorner", gachaBtn).CornerRadius = UDim.new(0, 6)

-- Risultato dello Sblocco
local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(0, 180, 0, 40)
resultLabel.Position = UDim2.new(0, 20, 0, 130)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = "Nessun roll effettuato"
resultLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
resultLabel.TextSize = 13
resultLabel.Font = Enum.Font.SourceSansItalic
resultLabel.Parent = menuFrame

-- Sezione Lista Inventario (Destra)
local listTitle = Instance.new("TextLabel")
listTitle.Size = UDim2.new(0, 160, 0, 20)
listTitle.Position = UDim2.new(0, 220, 0, 60)
listTitle.BackgroundTransparency = 1
listTitle.Text = "I tuoi Cosmetici:"
listTitle.TextColor3 = Color3.new(1, 1, 1)
listTitle.TextSize = 14
listTitle.Font = Enum.Font.SourceSansBold
listTitle.TextXAlignment = Enum.TextXAlignment.Left
listTitle.Parent = menuFrame

local inventoryScroll = Instance.new("ScrollingFrame")
inventoryScroll.Size = UDim2.new(0, 160, 0, 180)
inventoryScroll.Position = UDim2.new(0, 220, 0, 85)
inventoryScroll.BackgroundTransparency = 0.8
inventoryScroll.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
inventoryScroll.BorderSizePixel = 0
inventoryScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
inventoryScroll.Parent = menuFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.Parent = inventoryScroll

-- Interazione per visualizzare/chiudere il menu
openMenuBtn.MouseButton1Click:Connect(function()
	menuFrame.Visible = not menuFrame.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
	menuFrame.Visible = false
end)

-- Funzione per rinfrescare l'inventario grafico
local function refreshInventoryUI()
	-- Pulisci lista precedente
	for _, child in ipairs(inventoryScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local inventory = player:GetAttribute("Inventory") or ""
	if inventory == "" then
		local empty = Instance.new("TextButton") -- usiamo un bottone disattivato per visualizzazione
		empty.Size = UDim2.new(1, 0, 0, 30)
		empty.BackgroundTransparency = 1
		empty.Text = "Nessun cosmetico"
		empty.TextColor3 = Color3.fromRGB(100, 100, 100)
		empty.Font = Enum.Font.SourceSansItalic
		empty.TextSize = 12
		empty.Parent = inventoryScroll
		return
	end
	
	-- Popola gli elementi
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
			-- Equipaggia l'oggetto sul server
			local equipCosmeticRemote = ReplicatedStorage:WaitForChild("EquipCosmeticRemote") :: RemoteEvent
			equipCosmeticRemote:FireServer(itemName)
			
			-- Segnala equipaggiamento visivo locale
			itemBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
			task.wait(0.2)
			itemBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
		end)
	end
end

-- Gestione del Bottone di Roll Gacha
gachaBtn.MouseButton1Click:Connect(function()
	local openGachaRemote = ReplicatedStorage:WaitForChild("OpenGachaRemote") :: RemoteFunction
	local result = openGachaRemote:InvokeServer()
	
	if result and result.Success then
		resultLabel.Text = "Sbloccato: " .. result.Item
		resultLabel.TextColor3 = result.Rarity == "legendary" and Color3.fromRGB(255, 196, 0) or 
		                         result.Rarity == "rare" and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(200, 200, 200)
		
		-- Aggiorna attributi locali ed inventario GUI
		player:SetAttribute("Inventory", result.Inventory)
		refreshInventoryUI()
	else
		resultLabel.Text = result and result.Error or "Errore di connessione"
		resultLabel.TextColor3 = Color3.fromRGB(255, 0, 85)
	end
end)

-- Sincronizza l'inventario all'apertura del menu
player:GetAttributeChangedSignal("Inventory"):Connect(refreshInventoryUI)
refreshInventoryUI()


-- ==========================================
-- 3. LOGICA DI INPUT PARITÀ MOBILE / CONTROLLER
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonA then
		print("[TycoonClient] Input touch o controller registrato.")
	end
end)


-- ==========================================
-- 4. CAMERA SHAKE ED EFFETTI KNOCKBACK
-- ==========================================
local GnomeTriggerRemote = ReplicatedStorage:WaitForChild("GnomeTriggerRemote")
GnomeTriggerRemote.OnClientEvent:Connect(function(attacker)
	print("[Client] Knockback rilevato! Avvio camera shake...")
	
	local camera = game:GetService("Workspace").CurrentCamera
	if camera then
		local endTime = os.clock() + 0.5
		task.spawn(function()
			while os.clock() < endTime do
				local shakeOffset = CFrame.new(
					(math.random() - 0.5) * 0.4,
					(math.random() - 0.5) * 0.4,
					(math.random() - 0.5) * 0.4
				) * CFrame.Angles(
					(math.random() - 0.5) * 0.04,
					(math.random() - 0.5) * 0.04,
					(math.random() - 0.5) * 0.04
				)
				camera.CFrame = camera.CFrame * shakeOffset
				task.wait(0.01)
			end
		end)
	end
	
	-- Movimento fisico all'indietro gestito via Velocity sul client
	local character = player.Character
	if character then
		local hrp = character:WaitForChild("HumanoidRootPart")
		if hrp then
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, 75, -50)
			bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
			bodyVelocity.Parent = hrp
			task.wait(0.35)
			bodyVelocity:Destroy()
		end
	end
end)

-- Moments API Trigger locale (simula pop-up in-game)
local promptMomentRemote = ReplicatedStorage:WaitForChild("PromptMomentCapture")
promptMomentRemote.OnClientEvent:Connect(function(actionType, score)
	-- Mostra notifica momentanea a schermo
	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0, 300, 0, 60)
	popup.Position = UDim2.new(0.5, -150, 0.8, 0)
	popup.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
	popup.Parent = screenGui
	
	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 8)
	popupCorner.Parent = popup

	local popupLabel = Instance.new("TextLabel")
	popupLabel.Size = UDim2.new(1, 0, 1, 0)
	popupLabel.BackgroundTransparency = 1
	popupLabel.Text = "RAPINA EPICA DA +" .. score .. " COINS!\nCondividi Moment su Roblox Moments?"
	popupLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	popupLabel.Font = Enum.Font.SourceSansBold
	popupLabel.TextSize = 14
	popupLabel.Parent = popup
	
	-- Chiudi dopo 4 secondi con una transizione fittizia
	task.wait(4)
	popup:Destroy()
end)
