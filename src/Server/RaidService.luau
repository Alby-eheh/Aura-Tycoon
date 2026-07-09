--!strict
-- RaidService.luau
-- Logica Server Authoritative per i Raid dei Giocatori e le Difese Gnomi.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RaidService = {}

local GNOME_COOLDOWN = 600 -- 10 minuti in secondi
local raidRemote = Instance.new("RemoteEvent")
raidRemote.Name = "ExecuteRaidRemote"
raidRemote.Parent = ReplicatedStorage

-- Gestisce la richiesta di un raid da parte del client
raidRemote.OnServerEvent:Connect(function(player: Player, targetPlayer: Player)
	local playerPlot = player:GetAttribute("PlotId")
	local targetPlot = targetPlayer:GetAttribute("PlotId")
	
	if not playerPlot or not targetPlot then return end
	
	-- 1. Verifica Server-Authoritative della distanza fisica tra i plot
	local character = player.Character
	local targetCharacter = targetPlayer.Character
	if not character or not targetCharacter then return end
	
	local distance = (character.PrimaryPart.Position - targetCharacter.PrimaryPart.Position).Magnitude
	if distance > 150 then
		warn("[SERVER AUTHORITY] Raid respinto: Giocatore troppo lontano. Sospetto Exploit.")
		return
	end
	
	-- 2. Controllo presenza Gnomo Difensivo sul plot rivale
	local targetGnomeActive = targetPlayer:GetAttribute("GnomeActiveUntil") or 0
	local now = os.time()
	
	if now < targetGnomeActive then
		-- GNOMO ATTIVO: Respinge il raider
		print("[RaidService] Gnome protettivo scattato per " .. targetPlayer.Name)
		
		-- Attiva effetti audio e particelle nel Workspace (richiamo locale per evitare dipendenza circolare)
		local ServerScriptService = game:GetService("ServerScriptService")
		local MapService = require(ServerScriptService:WaitForChild("MapService"))
		MapService.playGnomeDefenseEffect(targetPlayer)
		
		-- Penalizzazione del raider e lancio fisico sul client
		player:SetAttribute("Stunned", true)
		
		-- Sottrae Sheckles al raider e li dona al difensore
		local raiderStats = player:FindFirstChild("leaderstats")
		local targetStats = targetPlayer:FindFirstChild("leaderstats")
		if raiderStats and targetStats then
			local raiderCoins = raiderStats:FindFirstChild("Sheckles")
			local targetCoins = targetStats:FindFirstChild("Sheckles")
			if raiderCoins and targetCoins then
				local penalty = math.min(raiderCoins.Value, 500)
				raiderCoins.Value = raiderCoins.Value - penalty
				targetCoins.Value = targetCoins.Value + penalty
			end
		end
		
		-- Invia segnale Client per applicare BodyVelocity di lancio e camera shake
		local defenseTriggerRemote = ReplicatedStorage:FindFirstChild("GnomeTriggerRemote")
		if defenseTriggerRemote and defenseTriggerRemote:IsA("RemoteEvent") then
			defenseTriggerRemote:FireClient(player, targetPlayer)
		end
	else
		-- RAID RIUSCITO: Ruba le monete accumulatesi nella cassa
		local targetStats = targetPlayer:FindFirstChild("leaderstats")
		local raiderStats = player:FindFirstChild("leaderstats")
		if targetStats and raiderStats then
			local targetStorage = targetStats:FindFirstChild("Storage")
			local raiderCoins = raiderStats:FindFirstChild("Sheckles")
			if targetStorage and raiderCoins then
				local stolenAmount = targetStorage.Value
				targetStorage.Value = 0
				raiderCoins.Value = raiderCoins.Value + stolenAmount
				
				-- Trigger Moments API sul client del raider
				local momentsRemote = ReplicatedStorage:FindFirstChild("PromptMomentCapture")
				if momentsRemote and momentsRemote:IsA("RemoteEvent") then
					momentsRemote:FireClient(player, "SuccessfulRaid", stolenAmount)
				end
			end
		end
	end
end)

return RaidService
