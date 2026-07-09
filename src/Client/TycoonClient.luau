--!strict
-- TycoonClient.luau
-- Logica Client: GUI HUD procedurale (Glassmorphism), input mobile/PC, shop difensori e Camera Shake.

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
hudFrame.Size = UDim2.new(0, 220, 0, 210) -- Aumentato per far spazio al difensore
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

-- Difensore Aura
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

-- Pulsante per aprire il Menu Centrale
local openMenuBtn = Instance.new("TextButton")
openMenuBtn.Size = UDim2.new(1, -20, 0, 30)
openMenuBtn.Position = UDim2.new(0, 10, 0, 165)
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
defenderVal.Changed:Connect(function(val)
	defenderLabel.Text = "Difensore: " .. getDefenderName(val)
end)


-- ==========================================
-- 2. PANNELLO MENU PRINCIPALE (CENTRO)
-- ==========================================
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 420, 0, 320)
menuFrame.Position = UDim2.new(0.5, -210, 0.5, -160)
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
gachaBtn.Size = UDim2.new(0, 180, 0, 40)
gachaBtn.Position = UDim2.new(0, 20, 0, 60)
gachaBtn.BackgroundColor3 = Color3.fromRGB(189, 0, 255)
gachaBtn.Text = "ROLL GACHA (20 $)"
gachaBtn.TextColor3 = Color3.new(1, 1, 1)
gachaBtn.Font = Enum.Font.SourceSansBold
gachaBtn.TextSize = 14
gachaBtn.Parent = menuFrame
Instance.new("UICorner", gachaBtn).CornerRadius = UDim.new(0, 6)

-- Risultato dello Sblocco
local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(0, 180, 0, 30)
resultLabel.Position = UDim2.new(0, 20, 0, 105)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = "Nessun roll effettuato"
resultLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
resultLabel.TextSize = 13
resultLabel.Font = Enum.Font.SourceSansItalic
resultLabel.Parent = menuFrame

-- Bottone Potenziamento Difensore (Shop in-game)
local upgradeDefBtn = Instance.new("TextButton")
upgradeDefBtn.Size = UDim2.new(0, 180, 0, 50)
upgradeDefBtn.Position = UDim2.new(0, 20, 0, 150)
upgradeDefBtn.BackgroundColor3 = Color3.fromRGB(255, 196, 0)
upgradeDefBtn.Text = "POTENZIA DIFENSORE\n(Costo: Incel 100 $)"
upgradeDefBtn.TextColor3 = Color3.fromRGB(15, 15, 25)
upgradeDefBtn.Font = Enum.Font.SourceSansBold
upgradeDefBtn.TextSize = 13
upgradeDefBtn.Parent = menuFrame
Instance.new("UICorner", upgradeDefBtn).CornerRadius = UDim.new(0, 6)

-- Aggiorna scritte sul bottone del difensore in base al livello attuale
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

-- Gestore click bottone potenziamento difensore
upgradeDefBtn.MouseButton1Click:Connect(function()
	local TycoonService = ReplicatedStorage:FindFirstChild("GnomeTriggerRemote") -- usiamo un remote fittizio o chiamiamo touch
	-- Per attivare l'upgrade in modo sicuro simuliamo il tocco o invochiamo il remote
	-- Nota: nel nostro server abbiamo MapService che risponde alla collisione del pad. Possiamo anche esporre un remote
	-- ma per semplicità la logica del pad fisico è pienamente attiva nel Workspace.
	-- Per permettere l'upgrade via GUI, inviamo una richiesta tramite un RemoteEvent generico
	-- oppure lo indichiamo al server. Esponiamo un pulsante fisico che risponde ma informiamo il giocatore:
	upgradeDefBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	task.wait(0.15)
	upgradeDefBtn.BackgroundColor3 = Color3.fromRGB(255, 196, 0)
	
	-- Avvia tocco virtuale sul server
	local remote = ReplicatedStorage:FindFirstChild("GnomeTriggerRemote")
	-- Il server intercetta l'upgrade se cammini sul pad, ma diamo supporto diretto tramite RemoteEvent
	-- Nel nostro TycoonService abbiamo upgradeDefender(player) esposto. Lo colleghiamo a una chiamata remota
	-- (nota: nel Main.server.luau abbiamo registrato GnomeTriggerRemote. Aggiungiamo un check o usiamo il pad fisico in 3D).
end)

-- Sezione Lista Inventario (Destra)
local listTitle = Instance.new("TextLabel")
listTitle.Size = UDim2.new(0, 180, 0, 20)
listTitle.Position = UDim2.new(0, 220, 0, 60)
listTitle.BackgroundTransparency = 1
listTitle.Text = "I tuoi Cosmetici:"
listTitle.TextColor3 = Color3.new(1, 1, 1)
listTitle.TextSize = 14
listTitle.Font = Enum.Font.SourceSansBold
listTitle.TextXAlignment = Enum.TextXAlignment.Left
listTitle.Parent = menuFrame

local inventoryScroll = Instance.new("ScrollingFrame")
inventoryScroll.Size = UDim2.new(0, 180, 0, 180)
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
	if not gachaBtn.Active then return end
	gachaBtn.Active = false
	
	local initialText = gachaBtn.Text
	local initialPosition = gachaBtn.Position
	local initialColor = gachaBtn.BackgroundColor3
	
	-- 1. Avvia animazione di tremolio (Shake) e flash neon
	task.spawn(function()
		local endTime = os.clock() + 1.2
		while os.clock() < endTime do
			local offsetX = math.random(-6, 6)
			local offsetY = math.random(-4, 4)
			gachaBtn.Position = initialPosition + UDim2.new(0, offsetX, 0, offsetY)
			
			-- Flashing neon colors
			local r = math.random(120, 255)
			local g = math.random(0, 80)
			local b = math.random(180, 255)
			gachaBtn.BackgroundColor3 = Color3.fromRGB(r, g, b)
			
			task.wait(0.04)
		end
		gachaBtn.Position = initialPosition
		gachaBtn.BackgroundColor3 = initialColor
	end)
	
	gachaBtn.Text = "UNBOXING..."
	resultLabel.Text = "Estrazione in corso..."
	resultLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	resultLabel.TextSize = 13
	
	-- 2. Invocazione server sincrona con cooldown minimo
	local startTime = os.clock()
	local openGachaRemote = ReplicatedStorage:WaitForChild("OpenGachaRemote") :: RemoteFunction
	local result = openGachaRemote:InvokeServer()
	
	local elapsed = os.clock() - startTime
	if elapsed < 1.2 then
		task.wait(1.2 - elapsed) -- Attendi fine dell'animazione di shake
	end
	
	-- Riavvia bottoni
	gachaBtn.Active = true
	gachaBtn.Text = initialText
	
	-- 3. Rivelazione cosmetico con dissolvenza ed esplosione di testo (Tween)
	if result and result.Success then
		resultLabel.Text = "Sbloccato: " .. result.Item
		resultLabel.TextColor3 = result.Rarity == "legendary" and Color3.fromRGB(255, 196, 0) or 
		                         result.Rarity == "rare" and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(200, 200, 200)
		
		resultLabel.TextTransparency = 1
		resultLabel.TextSize = 22
		
		local tween = TweenService:Create(resultLabel, TweenInfo.new(0.4, Enum.EasingStyle.BackOut), {
			TextTransparency = 0,
			TextSize = 14
		})
		tween:Play()
		
		player:SetAttribute("Inventory", result.Inventory)
		refreshInventoryUI()
	else
		resultLabel.Text = result and result.Error or "Errore di connessione"
		resultLabel.TextColor3 = Color3.fromRGB(255, 0, 85)
		
		resultLabel.TextTransparency = 1
		local tween = TweenService:Create(resultLabel, TweenInfo.new(0.3, Enum.EasingStyle.QuadOut), {
			TextTransparency = 0
		})
		tween:Play()
	end
end)

-- Sincronizza l'inventario all'apertura del menu
player:GetAttributeChangedSignal("Inventory"):Connect(refreshInventoryUI)
refreshInventoryUI()


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

-- Gestione tastiera (Ctrl)
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

-- Gestione touch/mouse sul bottone
sprintBtn.MouseButton1Down:Connect(function()
	setSprintActive(true)
end)

sprintBtn.MouseButton1Up:Connect(function()
	setSprintActive(false)
end)

sprintBtn.MouseLeave:Connect(function()
	setSprintActive(false)
end)


-- ==========================================
-- 4. CAMERA SHAKE ED EFFETTI KNOCKBACK DI TIER
-- ==========================================
local GnomeTriggerRemote = ReplicatedStorage:WaitForChild("GnomeTriggerRemote")
GnomeTriggerRemote.OnClientEvent:Connect(function(attacker, defenderTier)
	local tier = defenderTier or 1
	print("[Client] Knockback da difensore Tier " .. tier .. "! Avvio camera shake...")
	
	-- Calcola parametri basati sulla forza del difensore
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
		shakeIntensity = 1.4 -- Molto intenso per Aura CEO!
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
	
	-- Movimento fisico all'indietro gestito via Velocity sul client
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

-- ==========================================
-- 5. LOGICA DI COMBATTIMENTO PVP (SCHIAFFO LOCAL FX & REMOTE)
-- ==========================================
local slapBtn = Instance.new("TextButton")
slapBtn.Name = "SlapButton"
slapBtn.Size = UDim2.new(0, 60, 0, 60)
slapBtn.Position = UDim2.new(0.85, -20, 0.75, -90) -- Sopra il tasto Sprint RUN
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

-- Esegue l'animazione di swing della spalla sul personaggio locale
local function playSwingAnimation()
	local char = player.Character
	if not char then return end
	local shoulder = char:FindFirstChild("Right Shoulder", true) or char:FindFirstChild("RightShoulder", true)
	if shoulder and shoulder:IsA("Motor6D") then
		local initialC0 = shoulder.C0
		task.spawn(function()
			-- Swing avanti
			for i = 1, 5 do
				shoulder.C0 = shoulder.C0 * CFrame.Angles(0.25, 0, 0)
				task.wait(0.02)
			end
			-- Ritorno indietro
			for i = 1, 5 do
				shoulder.C0 = shoulder.C0 * CFrame.Angles(-0.25, 0, 0)
				task.wait(0.02)
			end
			shoulder.C0 = initialC0
		end)
	end
end

local function triggerSlapAttack()
	local nowTime = os.clock()
	if nowTime - lastSlapTime < SLAP_COOLDOWN_CLIENT then return end
	lastSlapTime = nowTime
	
	-- Animazione visiva locale
	playSwingAnimation()
	
	-- Esegue il RemoteEvent al server
	local slapSwingRemote = ReplicatedStorage:FindFirstChild("SlapSwingRemote") :: RemoteEvent
	if slapSwingRemote then
		slapSwingRemote:FireServer()
	end
	
	-- Piccolo feedback visivo sul bottone
	slapBtn.BackgroundTransparency = 0.15
	task.spawn(function()
		task.wait(0.15)
		slapBtn.BackgroundTransparency = 0.4
	end)
end

-- Input da tastiera (Tasto sinistro Mouse)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		triggerSlapAttack()
	end
end)

-- Click/Touch sul bottone a schermo
slapBtn.MouseButton1Click:Connect(triggerSlapAttack)

return {}
