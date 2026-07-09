--!strict
-- MapService.luau
-- Generatore procedurale di lotti, pulsanti fisici, audio spaziale, particelle e tabellone centrale 3D.

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

-- Riferimenti ai TextLabel del tabellone centrale per gli aggiornamenti a caldo
local momentsLabelFront: TextLabel? = nil
local momentsLabelBack: TextLabel? = nil

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
	
	-- 1. Base del Lotto
	local base = Instance.new("Part")
	base.Name = "PlotBase_" .. plotNumber
	base.Size = Vector3.new(60, 1, 60)
	base.Position = center
	base.Anchored = true
	base.Color = color
	base.Material = Enum.Material.Concrete
	base.Parent = mapFolder

	-- 2. Claim Pad (Neon Verde) per incassare monete
	local claimPad = Instance.new("Part")
	claimPad.Name = "ClaimPad"
	claimPad.Size = Vector3.new(6, 0.4, 6)
	claimPad.Position = center + Vector3.new(-20, 0.5, -20)
	claimPad.Anchored = true
	claimPad.Color = Color3.fromRGB(0, 255, 100)
	claimPad.Material = Enum.Material.Neon
	claimPad.Parent = mapFolder
	createFloatingLabel(claimPad, "CLAIM COINS\n(Passaci Sopra)", Color3.fromRGB(0, 255, 100))

	-- Crea suono Claim locale spaziale
	local claimSound = Instance.new("Sound")
	claimSound.Name = "ClaimSound"
	claimSound.SoundId = COIN_SOUND_ID
	claimSound.Volume = 0.8
	claimSound.Parent = claimPad

	-- 3. Upgrade Pad (Neon Ciano) per potenziare il generatore
	local upgradePad = Instance.new("Part")
	upgradePad.Name = "UpgradePad"
	upgradePad.Size = Vector3.new(6, 0.4, 6)
	upgradePad.Position = center + Vector3.new(20, 0.5, -20)
	upgradePad.Anchored = true
	upgradePad.Color = Color3.fromRGB(0, 240, 255)
	upgradePad.Material = Enum.Material.Neon
	upgradePad.Parent = mapFolder
	createFloatingLabel(upgradePad, "UPGRADE GEN\n(Costo: Dinamico)", Color3.fromRGB(0, 240, 255))

	-- 4. Gnome Shield Pad (Neon Giallo) per comprare/potenziare il difensore
	local gnomePad = Instance.new("Part")
	gnomePad.Name = "GnomePad"
	gnomePad.Size = Vector3.new(6, 0.4, 6)
	gnomePad.Position = center + Vector3.new(0, 0.5, -20)
	gnomePad.Anchored = true
	gnomePad.Color = Color3.fromRGB(255, 196, 0)
	gnomePad.Material = Enum.Material.Neon
	gnomePad.Parent = mapFolder
	createFloatingLabel(gnomePad, "UPGRADE DEFENDER\n(Costo: Dinamico)", Color3.fromRGB(255, 196, 0))

	-- 5. Raid Portal (Neon Rosso) per avviare raid
	local raidPortal = Instance.new("Part")
	raidPortal.Name = "RaidPortal"
	raidPortal.Size = Vector3.new(8, 0.4, 8)
	raidPortal.Position = center + Vector3.new(0, 0.5, 20)
	raidPortal.Anchored = true
	raidPortal.Color = Color3.fromRGB(255, 0, 85)
	raidPortal.Material = Enum.Material.Neon
	raidPortal.Parent = mapFolder
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
				local TycoonService = require(ServerScriptService.TycoonService)
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
				local TycoonService = require(ServerScriptService.TycoonService)
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
				local TycoonService = require(ServerScriptService.TycoonService)
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
		PlotPart = base,
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

-- Inizializza i lotti e crea il Tabellone Moments 3D centrale
function MapService.init()
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "HostileTycoonMap"
	mapFolder.Parent = Workspace
	
	print("[MapService] Generazione procedurale dei lotti e del monumento centrale...")
	
	-- Genera i 4 lotti
	for i = 1, 4 do
		generatePlot(i)
	end
	
	-- 1. Genera pilastro del tabellone centrale
	local pillar = Instance.new("Part")
	pillar.Name = "BillboardPillar"
	pillar.Size = Vector3.new(4, 15, 4)
	pillar.Position = Vector3.new(0, 7.5, 0)
	pillar.Color = Color3.fromRGB(60, 60, 70)
	pillar.Material = Enum.Material.Concrete
	pillar.Anchored = true
	pillar.Parent = mapFolder

	-- 2. Genera pannello schermo del tabellone
	local display = Instance.new("Part")
	display.Name = "BillboardDisplay"
	display.Size = Vector3.new(26, 11, 1.2)
	display.Position = Vector3.new(0, 16.5, 0)
	display.Color = Color3.fromRGB(15, 15, 25)
	display.Material = Enum.Material.SmoothPlastic
	display.Anchored = true
	display.Parent = mapFolder

	-- 3. SurfaceGui sul FRONTE dello schermo
	local sgFront = Instance.new("SurfaceGui")
	sgFront.Name = "FeedFront"
	sgFront.Face = Enum.NormalId.Front
	sgFront.SizingMode = Enum.SurfaceGuiSizingMode.Pixels
	sgFront.Parent = display

	local textFront = Instance.new("TextLabel")
	textFront.Size = UDim2.new(1, 0, 1, 0)
	textFront.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	textFront.BackgroundTransparency = 0.05
	textFront.Text = "\n★ LIVE FEED MOMENTS ★\n\nNessun raid registrato per ora."
	textFront.TextColor3 = Color3.fromRGB(0, 240, 255)
	textFront.TextSize = 20
	textFront.Font = Enum.Font.SourceSansBold
	textFront.TextWrapped = true
	textFront.Parent = sgFront
	momentsLabelFront = textFront

	-- 4. SurfaceGui sul RETRO dello schermo
	local sgBack = Instance.new("SurfaceGui")
	sgBack.Name = "FeedBack"
	sgBack.Face = Enum.NormalId.Back
	sgBack.SizingMode = Enum.SurfaceGuiSizingMode.Pixels
	sgBack.Parent = display

	local textBack = Instance.new("TextLabel")
	textBack.Size = UDim2.new(1, 0, 1, 0)
	textBack.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	textBack.BackgroundTransparency = 0.05
	textBack.Text = "\n★ LIVE FEED MOMENTS ★\n\nNessun raid registrato per ora."
	textBack.TextColor3 = Color3.fromRGB(0, 240, 255)
	textBack.TextSize = 20
	textBack.Font = Enum.Font.SourceSansBold
	textBack.TextWrapped = true
	textBack.Parent = sgBack
	momentsLabelBack = textBack

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

return MapService
