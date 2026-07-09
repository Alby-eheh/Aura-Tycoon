--!strict
-- Main.server.luau
-- Script di bootstrap principale che inizializza tutti i servizi sul Server.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local TycoonService = require(ServerScriptService:WaitForChild("TycoonService"))
local RaidService = require(ServerScriptService:WaitForChild("RaidService"))
local ServerRestartService = require(ServerScriptService:WaitForChild("ServerRestartService"))
local MonetizationService = require(ServerScriptService:WaitForChild("MonetizationService"))

-- 1. Inizializzazione Servizi
MonetizationService.init()
ServerRestartService.init()

-- 2. Hook per PlayerAdded/PlayerRemoving per caricare/scaricare i dati
Players.PlayerAdded:Connect(function(player)
	TycoonService.loadData(player)
	MonetizationService.trackPlaytime(player)
	
	-- Configura attributi dimostrativi
	player:SetAttribute("PlotId", player.UserId)
	player:SetAttribute("GnomeActiveUntil", 0)
	player:SetAttribute("IsActiveSpender", true) -- Per test dei Creator Rewards
end)

-- Carica dati per i giocatori già presenti (in caso di caricamento tardivo in Studio)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		TycoonService.loadData(player)
		MonetizationService.trackPlaytime(player)
		player:SetAttribute("PlotId", player.UserId)
		player:SetAttribute("GnomeActiveUntil", 0)
		player:SetAttribute("IsActiveSpender", true)
	end)
end

print("[SERVER BOOTSTRAP] Hostile Tycoon Server Services Started successfully!")
