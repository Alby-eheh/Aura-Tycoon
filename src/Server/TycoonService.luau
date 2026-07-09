--!strict
-- TycoonService.luau
-- Gestisce la generazione idle di risorse sul server, leaderstats e azioni fisiche.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TycoonDataStore = nil
local successDataStore, err = pcall(function()
	TycoonDataStore = DataStoreService:GetDataStore("TycoonSaveSystem_2026_v2")
end)

if not successDataStore or not TycoonDataStore then
	warn("[TycoonService] DataStore inaccessibile (il gioco potrebbe non essere pubblicato o l'accesso alle API non è abilitato). Verrà usata la memoria locale fittizia.")
end

local TycoonService = {}
local plots = {} -- Mappa UserId -> Plot
local INCOME_TICK_RATE = 1.0 -- Secondi

-- Carica o inizializza i dati del Tycoon del giocatore
function TycoonService.loadData(player: Player)
	local userId = player.UserId
	local savedData = nil
	
	if TycoonDataStore then
		local success, result = pcall(function()
			return TycoonDataStore:GetAsync(tostring(userId))
		end)
		if success then
			savedData = result
		end
	end
	
	local genLvl = 1
	local storageCoins = 0
	local walletCoins = 100 -- Partenza
	local gnomeTime = 0
	
	if savedData then
		genLvl = savedData.GeneratorLevel or 1
		storageCoins = savedData.Storage or 0
		walletCoins = savedData.Sheckles or 100
		gnomeTime = savedData.GnomeActiveUntil or 0
	end
	
	plots[userId] = {
		Owner = player,
		GeneratorLevel = genLvl,
		Storage = storageCoins,
		GnomeActiveUntil = gnomeTime
	}
	
	-- Inizializza i leaderstats visibili per Roblox Studio
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local sheckles = Instance.new("IntValue")
	sheckles.Name = "Sheckles"
	sheckles.Value = walletCoins
	sheckles.Parent = leaderstats

	local generator = Instance.new("IntValue")
	generator.Name = "Generator"
	generator.Value = genLvl
	generator.Parent = leaderstats

	local storageVal = Instance.new("IntValue")
	storageVal.Name = "Storage"
	storageVal.Value = storageCoins
	storageVal.Parent = leaderstats
	
	-- Se il caricamento rileva uno Gnomo ancora attivo
	if gnomeTime > os.time() then
		player:SetAttribute("GnomeActiveUntil", gnomeTime)
		task.spawn(function()
			local MapService = require(ServerScriptService:WaitForChild("MapService"))
			MapService.setGnomeVisual(player, true)
			task.wait(gnomeTime - os.time())
			if player.Parent then
				MapService.setGnomeVisual(player, false)
			end
		end)
	end
	
	print("[TycoonService] Dati caricati per: " .. player.Name)
end

-- Riscuote le monete accumulate nella cassa (Claim)
function TycoonService.claimStorage(player: Player)
	local userId = player.UserId
	local plot = plots[userId]
	if not plot then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local sheckles = leaderstats:FindFirstChild("Sheckles")
		local storageVal = leaderstats:FindFirstChild("Storage")
		if sheckles and storageVal then
			sheckles.Value = sheckles.Value + plot.Storage
			plot.Storage = 0
			storageVal.Value = 0
			print("[TycoonService] " .. player.Name .. " ha incassato " .. sheckles.Value .. " Sheckles.")
		end
	end
end

-- Potenzia il generatore di monete
function TycoonService.upgradeGenerator(player: Player)
	local userId = player.UserId
	local plot = plots[userId]
	if not plot then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local sheckles = leaderstats:FindFirstChild("Sheckles")
		local generatorVal = leaderstats:FindFirstChild("Generator")
		if sheckles and generatorVal then
			local cost = plot.GeneratorLevel * 50
			if sheckles.Value >= cost then
				sheckles.Value = sheckles.Value - cost
				plot.GeneratorLevel = plot.GeneratorLevel + 1
				generatorVal.Value = plot.GeneratorLevel
				print("[TycoonService] Generatore potenziato a Lvl " .. plot.GeneratorLevel .. " per " .. player.Name)
			else
				warn("[TycoonService] Soldi insufficienti per " .. player.Name)
			end
		end
	end
end

-- Acquista lo Gnomo Difensivo
function TycoonService.buyGnome(player: Player)
	local userId = player.UserId
	local plot = plots[userId]
	if not plot then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local sheckles = leaderstats:FindFirstChild("Sheckles")
		if sheckles then
			local cost = 95
			if sheckles.Value >= cost then
				sheckles.Value = sheckles.Value - cost
				
				-- Imposta lo Gnomo per 10 minuti (600 secondi)
				local duration = 600
				plot.GnomeActiveUntil = os.time() + duration
				player:SetAttribute("GnomeActiveUntil", plot.GnomeActiveUntil)
				
				-- Aggiorna la fisica nel Workspace
				local MapService = require(ServerScriptService:WaitForChild("MapService"))
				MapService.setGnomeVisual(player, true)
				
				task.spawn(function()
					task.wait(duration)
					if player.Parent then
						local now = os.time()
						if now >= (player:GetAttribute("GnomeActiveUntil") or 0) then
							MapService.setGnomeVisual(player, false)
						end
					end
				end)
				
				print("[TycoonService] Gnomo piazzato per " .. player.Name)
			else
				warn("[TycoonService] Sheckles insufficienti per lo Gnomo: " .. player.Name)
			end
		end
	end
end

-- Ciclo Idle Autorevole sul Server
task.spawn(function()
	while true do
		task.wait(INCOME_TICK_RATE)
		for userId, plot in pairs(plots) do
			if plot.Owner and plot.Owner.Parent then
				-- Incremento cassa in base al livello del generatore
				local income = plot.GeneratorLevel * 5
				plot.Storage = plot.Storage + income
				
				-- Aggiorna i leaderstats
				local leaderstats = plot.Owner:FindFirstChild("leaderstats")
				if leaderstats then
					local storageVal = leaderstats:FindFirstChild("Storage")
					if storageVal then
						storageVal.Value = plot.Storage
					end
				end
				
				-- Notifica il client del nuovo bilancio storage
				local remote = ReplicatedStorage:FindFirstChild("UpdateStorageRemote")
				if remote and remote:IsA("RemoteEvent") then
					remote:FireClient(plot.Owner, plot.Storage)
				end
			else
				plots[userId] = nil
			end
		end
	end
end)

-- Salva i dati alla disconnessione
Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	local plot = plots[userId]
	
	local leaderstats = player:FindFirstChild("leaderstats")
	local walletCoins = 100
	if leaderstats then
		local sheckles = leaderstats:FindFirstChild("Sheckles")
		if sheckles then
			walletCoins = sheckles.Value
		end
	end
	
	if plot and TycoonDataStore then
		pcall(function()
			TycoonDataStore:SetAsync(tostring(userId), {
				GeneratorLevel = plot.GeneratorLevel,
				Storage = plot.Storage,
				Sheckles = walletCoins,
				GnomeActiveUntil = plot.GnomeActiveUntil
			})
		end)
	end
	plots[userId] = nil
end)

return TycoonService
