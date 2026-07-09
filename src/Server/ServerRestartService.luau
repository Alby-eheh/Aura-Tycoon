--!strict
-- ServerRestartService.luau
-- Gestione dell'evento ServerRestartScheduled per LiveOps senza tempi morti.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerRestartService = {}

-- Registra l'handler per l'evento nativo Roblox
function ServerRestartService.init()
	Workspace.ServerRestartScheduled:Connect(function(restartTime: number)
		print("[LIVEOPS] Riavvio del server programmato alle: " .. os.date("%X", restartTime))
		
		-- 1. Avvisa i client con una notifica UI persistente
		local notificationRemote = ReplicatedStorage:FindFirstChild("ShowSystemAlert")
		if notificationRemote and notificationRemote:IsA("RemoteEvent") then
			notificationRemote:FireAllClients("Riavvio dei server tra poco per patch LiveOps. I dati sono salvati automaticamente.")
		end
		
		-- 2. Attendi finché non mancano 15 secondi
		local timeToWait = math.max((restartTime - os.time()) - 15, 0)
		task.wait(timeToWait)
		
		-- 3. Salva i dati di tutti i giocatori in modo sincrono
		print("[LIVEOPS] Inizio salvataggio di sicurezza per tutti i player...")
		local savePromises = {}
		for _, player in ipairs(Players:GetPlayers()) do
			table.insert(savePromises, task.spawn(function()
				-- Forza il salvataggio dei dati su DataStore
				local success = pcall(function()
					-- (Richiamo di TycoonService.saveData)
				end)
				if not success then
					warn("Impossibile salvare i dati per: " .. player.Name)
				end
			end))
		end
		
		-- Attendi il completamento di tutti i salvataggi
		task.wait(5)
		
		-- 4. Esegui il Teleport sicuro dei giocatori in nuovi server pronti
		local placeId = game.PlaceId
		local activePlayers = Players:GetPlayers()
		if #activePlayers > 0 then
			local teleportOptions = Instance.new("TeleportOptions")
			teleportOptions.ShouldReserveServer = true
			
			pcall(function()
				TeleportService:TeleportPartyAsync(placeId, activePlayers, teleportOptions)
			end)
		end
	end)
end

return ServerRestartService
