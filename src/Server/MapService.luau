--!strict
-- MapService.luau
-- Generatore procedurale di lotti e pulsanti fisici nel Workspace.

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
	createFloatingLabel(gnomePad, "BUY GNOME\n(95 Coins / Robux)", Color3.fromRGB(255, 196, 0))

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
				TycoonService.buyGnome(player)
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
				-- Determina il bersaglio: attacca il lotto successivo (se occupato)
				local targetPlotNum = (plotNumber % 4) + 1
				local targetPlotData = activePlots[targetPlotNum]
				
				if targetPlotData and targetPlotData.Owner then
					local targetPlayer = targetPlotData.Owner
					print("[MapService] Avvio raid da " .. player.Name .. " verso " .. targetPlayer.Name)
					
					-- Esegui l'evento del raid simulando la chiamata client
					local RaidService = require(ServerScriptService.RaidService)
					-- Simula l'evento di rete
					local remote = game:GetService("ReplicatedStorage"):FindFirstChild("ExecuteRaidRemote")
					if remote and remote:IsA("RemoteEvent") then
						remote:FireAllClients() -- per aggiornamenti visivi generici
					end
					-- Esegui direttamente sul server per sicurezza autoritativa
					game:GetService("ReplicatedStorage").ExecuteRaidRemote:FireServer(targetPlayer)
				else
					print("[MapService] Lotto bersaglio #" .. targetPlotNum .. " non occupato da nessun giocatore.")
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

-- Spawna o rimuove graficamente la statuetta dello Gnomo nel lotto del giocatore
function MapService.setGnomeVisual(player: Player, active: boolean)
	local plotId = player:GetAttribute("PlotId")
	if not plotId then return end
	
	local plotData = activePlots[plotId]
	if not plotData then return end
	
	if active then
		-- Se già c'è, non ricrearlo
		if plotData.GnomePart then return end
		
		-- Crea statuetta Gnomo (un piccolo mattoncino rosso con testa verde)
		local gnomeModel = Instance.new("Part")
		gnomeModel.Name = "GnomeDefender"
		gnomeModel.Size = Vector3.new(2, 3, 2)
		gnomeModel.Position = PLOT_COORDINATES[plotId] + Vector3.new(0, 2, 0)
		gnomeModel.Color = Color3.fromRGB(255, 0, 0)
		gnomeModel.Material = Enum.Material.Wood
		gnomeModel.Anchored = true
		gnomeModel.Parent = mapFolder
		
		-- Aggiungi il capello (testa verde conica)
		local hat = Instance.new("Part")
		hat.Name = "GnomeHat"
		hat.Size = Vector3.new(2, 2, 2)
		hat.Position = gnomeModel.Position + Vector3.new(0, 2.5, 0)
		hat.Color = Color3.fromRGB(0, 200, 0)
		hat.Material = Enum.Material.Plastic
		hat.Shape = Enum.PartType.Ball
		hat.Anchored = true
		hat.Parent = mapFolder
		
		-- Raggruppa i riferimenti
		plotData.GnomePart = gnomeModel
		-- Lega la testa per essere distrutti insieme
		gnomeModel.Destroying:Connect(function()
			hat:Destroy()
		end)
		
		createFloatingLabel(gnomeModel, "GNOME SHIELD ACTIVE", Color3.fromRGB(255, 196, 0))
	else
		if plotData.GnomePart then
			plotData.GnomePart:Destroy()
			plotData.GnomePart = nil
		end
	end
end

return MapService
