--!strict
-- MapService.luau
-- Generatore procedurale di lotti, pulsanti fisici, audio spaziale e particelle.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

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

	-- 4. Gnome Shield Pad (Neon Giallo) per comprare lo Gnomo
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
		
		-- Verifica che sia il proprietario di questo lotto
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
				claimSound:Play() -- riusa suono moneta
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
					
					-- Esegui l'evento del raid sul server
					local RaidService = require(ServerScriptService.RaidService)
					-- Simula l'evento lanciando la chiamata sul server
					local remote = game:GetService("ReplicatedStorage"):FindFirstChild("ExecuteRaidRemote")
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
			
			-- Teletrasporta il personaggio sul suo lotto base
			local char = player.Character or player.CharacterAdded:Wait()
			local hrp = char:WaitForChild("HumanoidRootPart")
			if hrp then
				task.wait(0.5) -- Attendi caricamento
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

-- Inizializza i 4 lotti fisici nel Workspace
function MapService.init()
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "HostileTycoonMap"
	mapFolder.Parent = Workspace
	
	print("[MapService] Generazione procedurale dei 4 Plot...")
	for i = 1, 4 do
		generatePlot(i)
	end
	
	-- Gestisci i giocatori correnti ed entranti
	Players.PlayerAdded:Connect(assignPlotToPlayer)
	Players.PlayerRemoving:Connect(releasePlot)
	
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(assignPlotToPlayer, player)
	end
end

-- Spawna o rimuove graficamente la statuetta del Difensore Aura nel lotto del giocatore
function MapService.setDefenderVisual(player: Player, tier: number, active: boolean)
	local plotId = player:GetAttribute("PlotId")
	if not plotId then return end
	
	local plotData = activePlots[plotId]
	if not plotData then return end
	
	-- Pulisci difensore precedente se attivo
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
		
		-- Prova a clonare dall'Assets Folder in ReplicatedStorage
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
			-- Fallback procedurale se l'utente non ha ancora compilato gli Assets o in offline test
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
		
		-- Aggiungi l'etichetta 3D fluttuante sul modello/part
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
	
	-- Spawna suono di molla spaziale
	local sound = Instance.new("Sound")
	sound.SoundId = BOING_SOUND_ID
	sound.Volume = 1.0
	sound.Parent = plotData.PlotPart
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
	
	-- Spawna effetto particelle esplosione dorata
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 2, 0)
	attachment.Parent = plotData.PlotPart
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)) -- Oro
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
