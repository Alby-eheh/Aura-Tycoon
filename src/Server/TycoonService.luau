--!strict
-- TycoonService.luau
-- Gestisce la generazione idle di risorse sul server e il salvataggio dei dati.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonDataStore = nil
local successDataStore, err = pcall(function()
	TycoonDataStore = DataStoreService:GetDataStore("TycoonSaveSystem_2026")
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
	
	if savedData then
		plots[userId] = {
			Owner = player,
			GeneratorLevel = savedData.GeneratorLevel or 1,
			Storage = savedData.Storage or 0,
			GnomeActiveUntil = savedData.GnomeActiveUntil or 0
		}
	else
		-- Dati default se nuovo utente o fallimento DataStore
		plots[userId] = {
			Owner = player,
			GeneratorLevel = 1,
			Storage = 0,
			GnomeActiveUntil = 0
		}
	end
	print("[TycoonService] Dati caricati per: " .. player.Name)
end

-- Ciclo Idle Autorevole sul Server
task.spawn(function()
	while true do
		task.wait(INCOME_TICK_RATE)
		for userId, plot in pairs(plots) do
			if plot.Owner and plot.Owner.Parent then
				-- Guadagno base basato sul livello del generatore
				local income = plot.GeneratorLevel * 10
				plot.Storage = plot.Storage + income
				
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
	if plot and TycoonDataStore then
		pcall(function()
			TycoonDataStore:SetAsync(tostring(userId), {
				GeneratorLevel = plot.GeneratorLevel,
				Storage = plot.Storage,
				GnomeActiveUntil = plot.GnomeActiveUntil
			})
		end)
	end
	plots[userId] = nil
end)

return TycoonService
