--!strict
-- Main.server.luau
-- Script di bootstrap principale che inizializza tutti i servizi sul Server.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Inizializza automaticamente i RemoteEvents necessari se mancanti
local function ensureRemoteEvent(name: string): RemoteEvent
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		local newRemote = Instance.new("RemoteEvent")
		newRemote.Name = name
		newRemote.Parent = ReplicatedStorage
		print("[SERVER BOOTSTRAP] Creato RemoteEvent: " .. name)
		return newRemote
	end
	return remote :: RemoteEvent
end

local function ensureRemoteFunction(name: string): RemoteFunction
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		local newRemote = Instance.new("RemoteFunction")
		newRemote.Name = name
		newRemote.Parent = ReplicatedStorage
		print("[SERVER BOOTSTRAP] Creato RemoteFunction: " .. name)
		return newRemote
	end
	return remote :: RemoteFunction
end

ensureRemoteEvent("UpdateStorageRemote")
ensureRemoteEvent("ExecuteRaidRemote")
ensureRemoteEvent("GnomeTriggerRemote")
ensureRemoteEvent("PromptMomentCapture")
ensureRemoteEvent("UpdateMomentsBillboard")
ensureRemoteEvent("ShowSystemAlert")
ensureRemoteFunction("OpenGachaRemote")
ensureRemoteEvent("EquipCosmeticRemote")
ensureRemoteEvent("SlapSwingRemote")
ensureRemoteEvent("TradeInviteRemote")
ensureRemoteFunction("TradeConfirmRemote")

local TycoonService = require(ServerScriptService:WaitForChild("TycoonService"))
local RaidService = require(ServerScriptService:WaitForChild("RaidService"))
local ServerRestartService = require(ServerScriptService:WaitForChild("ServerRestartService"))
local MonetizationService = require(ServerScriptService:WaitForChild("MonetizationService"))
local MapService = require(ServerScriptService:WaitForChild("MapService"))
local GachaService = require(ServerScriptService:WaitForChild("GachaService"))
local CombatService = require(ServerScriptService:WaitForChild("CombatService"))
local TradingService = require(ServerScriptService:WaitForChild("TradingService"))

-- 1. Inizializzazione Servizi
MonetizationService.init()
ServerRestartService.init()
MapService.init()
GachaService.init()
CombatService.init()
TradingService.init()

-- 2. Hook per PlayerAdded/PlayerRemoving per caricare/scaricare i dati
Players.PlayerAdded:Connect(function(player)
	TycoonService.loadData(player)
	MonetizationService.trackPlaytime(player)
	
	-- Configura attributi dimostrativi
	player:SetAttribute("GnomeActiveUntil", 0)
	player:SetAttribute("IsActiveSpender", true) -- Per test dei Creator Rewards
end)

-- Carica dati per i giocatori già presenti (in caso di caricamento tardivo in Studio)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		TycoonService.loadData(player)
		MonetizationService.trackPlaytime(player)
		player:SetAttribute("GnomeActiveUntil", 0)
		player:SetAttribute("IsActiveSpender", true)
	end)
end

print("[SERVER BOOTSTRAP] Hostile Tycoon Server Services Started successfully!")
