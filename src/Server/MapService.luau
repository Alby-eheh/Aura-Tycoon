--!strict
-- MapService.luau
-- Generatore procedurale di lotti, pulsanti fisici, audio spaziale, particelle e tabelloni 3D (Moments & Classifica Ricchi).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapService = {}
local mapFolder: Folder

local PLOT_COORDINATES = {
	[1] = Vector3.new(-80, 0, -80), -- Lotto 1
	[2] = Vector3.new(80, 0, -80),  -- Lotto 2
	[3] = Vector3.new(-80, 0, 80),  -- Lotto 3
	[4] = Vector3.new(80, 0, 80)    -- Lotto 4
}

local PLOT_COLORS = {
	[1] = Color3.fromRGB(0, 162, 232),  -- Ciano
	[2] = Color3.fromRGB(163, 73, 164), -- Viola
	[3] = Color3.fromRGB(255, 127, 39),  -- Arancio
	[4] = Color3.fromRGB(34, 177, 76)   -- Verde
}

local COIN_SOUND_ID = "rbxassetid://12221967"
local ALARM_SOUND_ID = "rbxassetid://12222030"
local BOING_SOUND_ID = "rbxassetid://12221946"

local activePlots = {} -- Mappa PlotNumber -> { Owner: Player, PlotPart: Part, GnomePart: Part? }
local debounces = {} -- Mappa Player -> boolean

-- Riferimenti ai TextLabel per aggiornamenti in tempo reale
local momentsLabelFront: TextLabel? = nil
local momentsLabelBack: TextLabel? = nil
local richLeaderboardLabel: TextLabel? = nil

-- Crea un'etichetta 3D fluttuante (BillboardGui) per i pad
local function createFloatingLabel(parent: Part, text: string, color: Color3)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 150, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = 16
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard
	
	return label
end

-- Helper per gestire i debounces del tocco
local function runWithDebounce(player: Player, callback: () -> ())
	if debounces[player] then return end
	debounces[player] = true
	task.spawn(function()
		callback()
		task.wait(1.0) -- Cooldown di 1 secondo
		debounces[player] = nil
	end)
end

-- Genera un singolo Lotto (Plot) fisico con i suoi pulsanti
local function generatePlot(plotNumber: number)
	local center = PLOT_COORDINATES[plotNumber]
	local color = PLOT_COLORS[plotNumber]
	
	-- 1. Base del Lotto Arrotondata (Stile Toy Block Pastello)
	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plot_" .. plotNumber
	plotFolder.Parent = mapFolder
	
	local pastelGreen = Color3.fromRGB(115, 175, 120) -- Verde pastello salvia
	local bevelRadius = 3
	local baseHeight = 1
	
	local function createBasePart(name: string, size: Vector3, pos: Vector3)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = pos
		part.Color = pastelGreen
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.Parent = plotFolder
		return part
	end
	
	-- Crea la croce di riempimento centrale
	createBasePart("BaseCenter", Vector3.new(60 - bevelRadius * 2, baseHeight, 60 - bevelRadius * 2), center)
	createBasePart("BaseNS", Vector3.new(60 - bevelRadius * 2, baseHeight, 60), center)
	createBasePart("BaseEW", Vector3.new(60, baseHeight, 60 - bevelRadius * 2), center)
	
	-- 4 Cilindri d'angolo per l'arrotondamento (Bevel)
	local function createCornerCylinder(offset: Vector3)
		local cyl = Instance.new("Part")
		cyl.Name = "BaseCorner"
		cyl.Shape = Enum.PartType.Cylinder
		cyl.Size = Vector3.new(baseHeight, bevelRadius * 2, bevelRadius * 2)
		cyl.CFrame = CFrame.new(center + offset) * CFrame.Angles(0, 0, math.rad(90))
		cyl.Color = pastelGreen
		cyl.Material = Enum.Material.SmoothPlastic
		cyl.Anchored = true
		cyl.Parent = plotFolder
	end
	
	local inset = 30 - bevelRadius
	createCornerCylinder(Vector3.new(-inset, 0, -inset))
	createCornerCylinder(Vector3.new(inset, 0, -inset))
	createCornerCylinder(Vector3.new(-inset, 0, inset))
	createCornerCylinder(Vector3.new(inset, 0, inset))
	
	-- Piattaforma del bordo colorata (identificatore del lotto del giocatore)
	local ring = Instance.new("Part")
	ring.Name = "PlotOwnerBorder"
	ring.Size = Vector3.new(12, 0.4, 12)
	ring.Position = center + Vector3.new(0, 0.3, 0)
	ring.Color = color
	ring.Material = Enum.Material.SmoothPlastic
	ring.Anchored = true
	ring.Parent = plotFolder
	Instance.new("UICorner", ring) -- Rende il bordo un cerchio liscio

	-- 2. Claim Pad (Neon Verde Circolare)
	local claimPad = Instance.new("Part")
	claimPad.Name = "ClaimPad"
	claimPad.Shape = Enum.PartType.Cylinder
	claimPad.Size = Vector3.new(0.4, 6, 6)
	claimPad.CFrame = CFrame.new(center + Vector3.new(-18, 0.2, -18)) * CFrame.Angles(math.rad(90), 0, 0)
	claimPad.Anchored = true
	claimPad.Color = Color3.fromRGB(0, 255, 100)
	claimPad.Material = Enum.Material.Neon
	claimPad.Parent = plotFolder
	createFloatingLabel(claimPad, "CLAIM COINS\n(Passaci Sopra)", Color3.fromRGB(0, 255, 100))

	-- Crea suono Claim locale spaziale
	local claimSound = Instance.new("Sound")
	claimSound.Name = "ClaimSound"
	claimSound.SoundId = COIN_SOUND_ID
	claimSound.Volume = 0.8
	claimSound.Parent = claimPad

	-- 3. Upgrade Pad (Neon Ciano Circolare)
	local upgradePad = Instance.new("Part")
	upgradePad.Name = "UpgradePad"
	upgradePad.Shape = Enum.PartType.Cylinder
	upgradePad.Size = Vector3.new(0.4, 6, 6)
	upgradePad.CFrame = CFrame.new(center + Vector3.new(18, 0.2, -18)) * CFrame.Angles(math.rad(90), 0, 0)
	upgradePad.Anchored = true
	upgradePad.Color = Color3.fromRGB(0, 240, 255)
	upgradePad.Material = Enum.Material.Neon
	upgradePad.Parent = plotFolder
	createFloatingLabel(upgradePad, "UPGRADE GEN\n(Costo: Dinamico)", Color3.fromRGB(0, 240, 255))

	-- 4. Gnome Shield Pad (Neon Giallo Circolare)
	local gnomePad = Instance.new("Part")
	gnomePad.Name = "GnomePad"
	gnomePad.Shape = Enum.PartType.Cylinder
	gnomePad.Size = Vector3.new(0.4, 6, 6)
	gnomePad.CFrame = CFrame.new(center + Vector3.new(0, 0.2, -18)) * CFrame.Angles(math.rad(90), 0, 0)
	gnomePad.Anchored = true
	gnomePad.Color = Color3.fromRGB(255, 196, 0)
	gnomePad.Material = Enum.Material.Neon
	gnomePad.Parent = plotFolder
	createFloatingLabel(gnomePad, "UPGRADE DEFENDER\n(Costo: Dinamico)", Color3.fromRGB(255, 196, 0))

	-- 5. Raid Portal (Neon Rosso Circolare)
	local raidPortal = Instance.new("Part")
	raidPortal.Name = "RaidPortal"
	raidPortal.Shape = Enum.PartType.Cylinder
	raidPortal.Size = Vector3.new(0.4, 8, 8)
	raidPortal.CFrame = CFrame.new(center + Vector3.new(0, 0.2, 18)) * CFrame.Angles(math.rad(90), 0, 0)
	raidPortal.Anchored = true
	raidPortal.Color = Color3.fromRGB(255, 0, 85)
	raidPortal.Material = Enum.Material.Neon
	raidPortal.Parent = plotFolder
	createFloatingLabel(raidPortal, "RAID PORTAL\n(Attacca Lotto Adiacente)", Color3.fromRGB(255, 0, 85))

	-- Crea suono allarme raid
	local raidSound = Instance.new("Sound")
	raidSound.Name = "RaidSound"
	raidSound.SoundId = ALARM_SOUND_ID
	raidSound.Volume = 0.7
	raidSound.Parent = raidPortal

	-- Configura le collisioni fisiche (Touched Events)
	claimPad.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		
		local plotData = activePlots[plotNumber]
		if plotData and plotData.Owner == player then
			runWithDebounce(player, function()
				local TycoonService = require(ServerScriptService:WaitForChild("TycoonService"))
				TycoonService.claimStorage(player)
				claimSound:Play()
				
				-- Spawna particelle verdi al Claim
				local attachment = Instance.new("Attachment")
				attachment.Position = Vector3.new(0, 1, 0)
				attachment.Parent = claimPad
				
				local emitter = Instance.new("ParticleEmitter")
				emitter.Color = ColorSequence.new(Color3.fromRGB(0, 255, 100))
				emitter.Size = NumberSequence.new(0.5, 1.2)
				emitter.Speed = NumberRange.new(5, 15)
				emitter.Rate = 50
				emitter.Lifetime = NumberRange.new(0.4, 0.6)
				emitter.Parent = attachment
				
				task.wait(0.2)
				emitter.Enabled = false
				task.wait(0.6)
				attachment:Destroy()
			end)
		end
	end)

	upgradePad.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		
		local plotData = activePlots[plotNumber]
		if plotData and plotData.Owner == player then
			runWithDebounce(player, function()
				local TycoonService = require(ServerScriptService:WaitForChild("TycoonService"))
				TycoonService.upgradeGenerator(player)
				claimSound:Play()
			end)
		end
	end)

	gnomePad.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		
		local plotData = activePlots[plotNumber]
		if plotData and plotData.Owner == player then
			runWithDebounce(player, function()
				local TycoonService = require(ServerScriptService:WaitForChild("TycoonService"))
				TycoonService.upgradeDefender(player)
			end)
		end
	end)

	raidPortal.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		
		local plotData = activePlots[plotNumber]
		if plotData and plotData.Owner == player then
			runWithDebounce(player, function()
				local targetPlotNum = (plotNumber % 4) + 1
				local targetPlotData = activePlots[targetPlotNum]
				
				if targetPlotData and targetPlotData.Owner then
					local targetPlayer = targetPlotData.Owner
					print("[MapService] Avvio raid da " .. player.Name .. " verso " .. targetPlayer.Name)
					
					raidSound:Play()
					
					local remote = ReplicatedStorage:FindFirstChild("ExecuteRaidRemote")
					if remote and remote:IsA("RemoteEvent") then
						remote:FireServer(targetPlayer)
					end
				else
					print("[MapService] Lotto bersaglio #" .. targetPlotNum .. " non occupato.")
				end
			end)
		end
	end)

	activePlots[plotNumber] = {
		Owner = nil,
		PlotPart = baseCenter,
		GnomePart = nil
	}
end

-- Assegna un lotto disponibile a un giocatore entrante
local function assignPlotToPlayer(player: Player)
	for i = 1, 4 do
		local plotData = activePlots[i]
		if plotData and plotData.Owner == nil then
			plotData.Owner = player
			player:SetAttribute("PlotId", i)
			print("[MapService] Lotto #" .. i .. " assegnato a " .. player.Name)
			
			local char = player.Character or player.CharacterAdded:Wait()
			local hrp = char:WaitForChild("HumanoidRootPart")
			if hrp then
				task.wait(0.5)
				hrp.CFrame = CFrame.new(PLOT_COORDINATES[i] + Vector3.new(0, 4, 0))
			end
			break
		end
	end
end

-- Rilascia il lotto alla disconnessione
local function releasePlot(player: Player)
	for i = 1, 4 do
		local plotData = activePlots[i]
		if plotData and plotData.Owner == player then
			plotData.Owner = nil
			if plotData.GnomePart then
				plotData.GnomePart:Destroy()
				plotData.GnomePart = nil
			end
			print("[MapService] Lotto #" .. i .. " liberato.")
			break
		end
	end
end

-- Automazione completa dell'illuminazione e degli effetti post-processing per un look premium
local function configureLighting()
	local Lighting = game:GetService("Lighting")
	
	-- Pulisci eventuali vecchi effetti
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("Atmosphere") or child:IsA("SunRaysEffect") or child:IsA("DepthOfFieldEffect") then
			child:Destroy()
		end
	end
	
	-- Impostazioni generali Lighting per look pastello stilizzato (Stile Grow a Garden)
	pcall(function()
		-- La tecnologia a volte è protetta in scrittura o richiede Studio restart, ma proviamo ad assegnarla
		(Lighting :: any).Technology = Enum.Technology.ShadowMap
	end)
	Lighting.ClockTime = 14.5 -- Sole pomeridiano dorato alto ma angolato
	Lighting.Brightness = 3.0
	Lighting.Ambient = Color3.fromRGB(110, 105, 125) -- Ombre violacee morbide
	Lighting.OutdoorAmbient = Color3.fromRGB(135, 125, 140)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 245, 230) -- Luce solare calda
	Lighting.ColorShift_Bottom = Color3.fromRGB(200, 210, 225) -- Luce riflessa azzurra
	Lighting.ShadowSoftness = 0.1
	
	-- 1. Bloom Effect (Bagliore soffuso controllato)
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "AutoBloom"
	bloom.Size = 16
	bloom.Intensity = 0.8
	bloom.Threshold = 0.9
	bloom.Parent = Lighting
	
	-- 2. Color Correction (Colori vivaci e caldi ma non bruciati)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "AutoColorCorrection"
	cc.Contrast = 0.05
	cc.Saturation = 0.18
	cc.TintColor = Color3.fromRGB(255, 252, 245) -- Filtro caldo pastello
	cc.Parent = Lighting
	
	-- 3. Atmosphere (Nebbia stilizzata calda all'orizzonte)
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "AutoAtmosphere"
	atmosphere.Density = 0.1
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(190, 210, 225)
	atmosphere.Decay = Color3.fromRGB(240, 180, 190) -- Orizzonte rosato pastello
	atmosphere.Glare = 0.2
	atmosphere.Haze = 0.5
	atmosphere.Parent = Lighting
	
	-- 4. SunRays (Raggi solari volumetrici diurni)
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "AutoSunRays"
	sunRays.Intensity = 0.15
	sunRays.Spread = 0.7
	sunRays.Parent = Lighting
	
	-- 5. DepthOfField (Sfocatura dello sfondo lontano tipo cinema/fotografia)
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "AutoDepthOfField"
	dof.FocusDistance = 25
	dof.InFocusRadius = 15
	dof.NearIntensity = 0.05
	dof.FarIntensity = 0.35
	dof.Parent = Lighting
	
	print("[MapService] Illuminazione e Post-Processing configurati automaticamente!")
end

-- Inizializza lotti, Moments Billboard e Classifica Ricchi 3D
function MapService.init()
	configureLighting()
	
	-- Ciclo di scorrimento ombre solari lento (oscilla lentamente tra le 13.8 e le 15.2 per ombre vive ma sempre soleggiate)
	task.spawn(function()
		local Lighting = game:GetService("Lighting")
		local cycle = 0
		while true do
			task.wait(1.0)
			cycle = cycle + 0.012
			-- Oscilla sinusoidalmente l'orario del sole pomeridiano
			Lighting.ClockTime = 14.5 + math.sin(cycle) * 0.7
		end
	end)
	
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "HostileTycoonMap"
	mapFolder.Parent = Workspace
	
	print("[MapService] Generazione procedurale dei lotti e delle strutture centrali...")
	
	-- Genera i 4 lotti
	for i = 1, 4 do
		generatePlot(i)
	end
	
	-- ----------------------------------------------------
	-- 1. TABELLONE MOMENTS CENTRALE
	-- ----------------------------------------------------
	local pillar = Instance.new("Part")
	pillar.Name = "BillboardPillar"
	pillar.Size = Vector3.new(4, 15, 4)
	pillar.Position = Vector3.new(0, 7.5, 10)
	pillar.Color = Color3.fromRGB(60, 60, 70)
	pillar.Material = Enum.Material.Concrete
	pillar.Anchored = true
	pillar.Parent = mapFolder

	local display = Instance.new("Part")
	display.Name = "BillboardDisplay"
	display.Size = Vector3.new(26, 11, 1.2)
	display.Position = Vector3.new(0, 16.5, 10)
	display.Color = Color3.fromRGB(15, 15, 25)
	display.Material = Enum.Material.SmoothPlastic
	display.Anchored = true
	display.Parent = mapFolder

	-- SurfaceGui sul FRONTE
	local sgFront = Instance.new("SurfaceGui")
	sgFront.Name = "FeedFront"
	sgFront.Face = Enum.NormalId.Front
	sgFront.Parent = display

	local textFront = Instance.new("TextLabel")
	textFront.Size = UDim2.new(1, 0, 1, 0)
	textFront.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	textFront.BackgroundTransparency = 0.05
	textFront.Text = "\n★ LIVE FEED MOMENTS ★\n\nNessun raid registrato per ora."
	textFront.TextColor3 = Color3.fromRGB(255, 0, 150) -- Fucsia
	textFront.TextSize = 20
	textFront.Font = Enum.Font.SourceSansBold
	textFront.TextWrapped = true
	textFront.Parent = sgFront
	momentsLabelFront = textFront

	-- SurfaceGui sul RETRO
	local sgBack = Instance.new("SurfaceGui")
	sgBack.Name = "FeedBack"
	sgBack.Face = Enum.NormalId.Back
	sgBack.Parent = display

	local textBack = Instance.new("TextLabel")
	textBack.Size = UDim2.new(1, 0, 1, 0)
	textBack.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	textBack.BackgroundTransparency = 0.05
	textBack.Text = "\n★ LIVE FEED MOMENTS ★\n\nNessun raid registrato per ora."
	textBack.TextColor3 = Color3.fromRGB(255, 0, 150)
	textBack.TextSize = 20
	textBack.Font = Enum.Font.SourceSansBold
	textBack.TextWrapped = true
	textBack.Parent = sgBack
	momentsLabelBack = textBack

	-- ----------------------------------------------------
	-- 2. TABELLONE CLASSIFICA RICCHI 3D
	-- ----------------------------------------------------
	local richPillar = Instance.new("Part")
	richPillar.Name = "RichPillar"
	richPillar.Size = Vector3.new(3, 14, 3)
	richPillar.Position = Vector3.new(-30, 7, -10)
	richPillar.Color = Color3.fromRGB(50, 50, 55)
	richPillar.Material = Enum.Material.Concrete
	richPillar.Anchored = true
	richPillar.Parent = mapFolder

	local richDisplay = Instance.new("Part")
	richDisplay.Name = "RichDisplay"
	richDisplay.Size = Vector3.new(18, 10, 1.2)
	richDisplay.Position = Vector3.new(-30, 15.5, -10)
	richDisplay.Color = Color3.fromRGB(15, 20, 15) -- Vetro scuro verdastro
	richDisplay.Material = Enum.Material.SmoothPlastic
	richDisplay.Anchored = true
	richDisplay.Parent = mapFolder

	local sgRich = Instance.new("SurfaceGui")
	sgRich.Name = "RichGui"
	sgRich.Face = Enum.NormalId.Front
	sgRich.Parent = richDisplay

	local textRich = Instance.new("TextLabel")
	textRich.Size = UDim2.new(1, 0, 1, 0)
	textRich.BackgroundColor3 = Color3.fromRGB(10, 20, 15)
	textRich.BackgroundTransparency = 0.05
	textRich.Text = "\n★ CLASSIFICA RICCHI ★\n\nCalcolo in corso..."
	textRich.TextColor3 = Color3.fromRGB(0, 255, 100) -- Verde neon
	textRich.TextSize = 18
	textRich.Font = Enum.Font.SourceSansBold
	textRich.TextWrapped = true
	textRich.Parent = sgRich
	richLeaderboardLabel = textRich

	-- 3. Ciclo di aggiornamento classifica Ricchi sul server (ogni 10 secondi)
	task.spawn(function()
		while true do
			task.wait(10.0)
			local pList = Players:GetPlayers()
			
			-- Ordina i player in base ai Sheckles
			table.sort(pList, function(a, b)
				local aCoins = 0
				local bCoins = 0
				local aStats = a:FindFirstChild("leaderstats")
				local bStats = b:FindFirstChild("leaderstats")
				if aStats then
					local val = aStats:FindFirstChild("Sheckles")
					if val and val:IsA("IntValue") then aCoins = val.Value end
				end
				if bStats then
					local val = bStats:FindFirstChild("Sheckles")
					if val and val:IsA("IntValue") then bCoins = val.Value end
				end
				return aCoins > bCoins
			end)
			
			local text = "\n★ TOP RICH PLAYERS ★\n"
			for rank, p in ipairs(pList) do
				if rank > 5 then break end
				local coins = 0
				local stats = p:FindFirstChild("leaderstats")
				if stats then
					local val = stats:FindFirstChild("Sheckles")
					if val and val:IsA("IntValue") then coins = val.Value end
				end
				text = text .. "\n#" .. rank .. " " .. p.Name .. " - " .. coins .. " $"
			end
			
			if #pList == 0 then
				text = text .. "\nNessun player attivo."
			end
			
			if richLeaderboardLabel then
				richLeaderboardLabel.Text = text
			end
		end
	end)

	-- Gestisci i giocatori correnti ed entranti
	Players.PlayerAdded:Connect(assignPlotToPlayer)
	Players.PlayerRemoving:Connect(releasePlot)
	
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(assignPlotToPlayer, player)
	end
end

-- Aggiorna la scritta sul tabellone centrale visibile in 3D
function MapService.updateBillboardFeed(text: string)
	local formattedText = "\n★ LIVE FEED MOMENTS ★\n\n" .. text
	if momentsLabelFront then
		momentsLabelFront.Text = formattedText
	end
	if momentsLabelBack then
		momentsLabelBack.Text = formattedText
	end
	
	-- Invia segnale a tutti i client per notificare
	local remote = ReplicatedStorage:FindFirstChild("UpdateMomentsBillboard")
	if remote and remote:IsA("RemoteEvent") then
		remote:FireAllClients(text)
	end
end

-- Spawna o rimuove graficamente la statuetta del Difensore Aura nel lotto del giocatore
function MapService.setDefenderVisual(player: Player, tier: number, active: boolean)
	local plotId = player:GetAttribute("PlotId")
	if not plotId then return end
	
	local plotData = activePlots[plotId]
	if not plotData then return end
	
	if plotData.GnomePart then
		plotData.GnomePart:Destroy()
		plotData.GnomePart = nil
	end
	
	if active and tier > 0 then
		local defenderName = "Incel"
		local labelText = "INCEL DEFENDER"
		local labelColor = Color3.fromRGB(139, 69, 19)
		
		if tier == 2 then
			defenderName = "Goat"
			labelText = "GOAT DEFENDER"
			labelColor = Color3.fromRGB(240, 240, 240)
		elseif tier == 3 then
			defenderName = "Sigma"
			labelText = "SIGMA DEFENDER"
			labelColor = Color3.fromRGB(0, 240, 255)
		elseif tier == 4 then
			defenderName = "AuraCEO"
			labelText = "AURA CEO DEFENDER"
			labelColor = Color3.fromRGB(255, 196, 0)
		end
		
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local defendersFolder = assets and assets:FindFirstChild("Defenders")
		local targetTemplate = defendersFolder and defendersFolder:FindFirstChild(defenderName)
		
		local cloneInstance = nil
		if targetTemplate then
			cloneInstance = targetTemplate:Clone()
			if cloneInstance:IsA("PVInstance") then
				cloneInstance:PivotTo(CFrame.new(PLOT_COORDINATES[plotId] + Vector3.new(0, 2, 0)))
			end
			cloneInstance.Parent = mapFolder
			print("[MapService] Spawnato difensore reale da Assets: " .. defenderName)
		else
			local fallbackPart = Instance.new("Part")
			fallbackPart.Name = defenderName
			fallbackPart.Size = tier == 4 and Vector3.new(2.5, 3.5, 2.5) or Vector3.new(2, 3, 2)
			fallbackPart.Position = PLOT_COORDINATES[plotId] + Vector3.new(0, 2, 0)
			fallbackPart.Anchored = true
			fallbackPart.CanCollide = true
			
			if tier == 1 then
				fallbackPart.Color = Color3.fromRGB(139, 69, 19)
				fallbackPart.Material = Enum.Material.Wood
			elseif tier == 2 then
				fallbackPart.Color = Color3.fromRGB(245, 245, 245)
				fallbackPart.Material = Enum.Material.Marble
			elseif tier == 3 then
				fallbackPart.Color = Color3.fromRGB(192, 192, 192)
				fallbackPart.Material = Enum.Material.Metal
			elseif tier == 4 then
				fallbackPart.Color = Color3.fromRGB(255, 215, 0)
				fallbackPart.Material = Enum.Material.Neon
			end
			
			fallbackPart.Parent = mapFolder
			cloneInstance = fallbackPart
			print("[MapService] Spawnato difensore fallback procedurale: " .. defenderName)
		end
		
		plotData.GnomePart = cloneInstance
		
		local labelPart = cloneInstance:IsA("Model") and (cloneInstance.PrimaryPart or cloneInstance:FindFirstChildWhichIsA("BasePart")) or cloneInstance
		if labelPart and labelPart:IsA("Part") then
			createFloatingLabel(labelPart, labelText, labelColor)
		end
	end
end

-- Esegue l'effetto di rimbalzo ed esplosione dello Gnomo
function MapService.playGnomeDefenseEffect(player: Player)
	local plotId = player:GetAttribute("PlotId")
	if not plotId then return end
	local plotData = activePlots[plotId]
	if not plotData or not plotData.PlotPart then return end
	
	local sound = Instance.new("Sound")
	sound.SoundId = BOING_SOUND_ID
	sound.Volume = 1.0
	sound.Parent = plotData.PlotPart
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
	
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 2, 0)
	attachment.Parent = plotData.PlotPart
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	emitter.Size = NumberSequence.new(1.5, 3.5)
	emitter.Speed = NumberRange.new(15, 35)
	emitter.Rate = 120
	emitter.Lifetime = NumberRange.new(0.4, 0.7)
	emitter.Parent = attachment
	
	task.wait(0.2)
	emitter.Enabled = false
	task.wait(1.0)
	attachment:Destroy()
end

MapService.PLOT_COORDINATES = PLOT_COORDINATES

return MapService
