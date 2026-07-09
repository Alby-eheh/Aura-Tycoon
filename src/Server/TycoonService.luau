--!strict
-- TycoonService.luau
-- Gestisce la generazione idle di risorse sul server e il salvataggio dei dati.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonDataStore = DataStoreService:GetDataStore("TycoonSaveSystem_2026")
local TycoonService = {}

local plots = {} -- Mappa UserId -> Plot
local INCOME_TICK_RATE = 1.0 -- Secondi

-- Carica o inizializza i dati del Tycoon del giocatore
function TycoonService.loadData(player: Player)
	local userId = player.UserId
	local success, savedData = pcall(function()
		return TycoonDataStore:GetAsync(tostring(userId))
	end)
	
	if success and savedData then
		plots[userId] = {
			Owner = player,
			GeneratorLevel = savedData.GeneratorLevel or 1,
			Storage = savedData.Storage or 0,
			GnomeActiveUntil = savedData.GnomeActiveUntil or 0
		}
	else
		-- Dati default se nuovo utente
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
	if plot then
		pcall(function()
			TycoonDataStore:SetAsync(tostring(userId), {
				GeneratorLevel = plot.GeneratorLevel,
				Storage = plot.Storage,
				GnomeActiveUntil = plot.GnomeActiveUntil
			})
		end)
		plots[userId] = nil
	end
end)

return TycoonService
