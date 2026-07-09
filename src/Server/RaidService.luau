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
		-- GNOMO / DIFENSORE ATTIVO: Respinge il raider
		local targetDefenderTier = targetPlayer:GetAttribute("DefenderTier") or 1
		print("[RaidService] Difensore Aura Lvl " .. targetDefenderTier .. " scattato per " .. targetPlayer.Name)
		
		-- Attiva effetti audio e particelle nel Workspace (richiamo locale per evitare dipendenza circolare)
		local ServerScriptService = game:GetService("ServerScriptService")
		local MapService = require(ServerScriptService:WaitForChild("MapService"))
		MapService.playGnomeDefenseEffect(targetPlayer)
		
		-- Registra il fallimento del raid sul tabellone centrale
		local MomentsService = require(ServerScriptService:WaitForChild("MomentsService"))
		MomentsService.recordFailedRaid(player, targetPlayer, targetDefenderTier)
		
		-- Penalizzazione del raider e lancio fisico sul client
		player:SetAttribute("Stunned", true)
		
		-- Sottrae Sheckles al raider e li dona al difensore (in base al tier)
		local raiderStats = player:FindFirstChild("leaderstats")
		local targetStats = targetPlayer:FindFirstChild("leaderstats")
		if raiderStats and targetStats then
			local raiderCoins = raiderStats:FindFirstChild("Sheckles")
			local targetCoins = targetStats:FindFirstChild("Sheckles")
			if raiderCoins and targetCoins then
				local penaltyAmount = 50
				if targetDefenderTier == 2 then
					penaltyAmount = 150
				elseif targetDefenderTier == 3 then
					penaltyAmount = 300
				elseif targetDefenderTier == 4 then
					penaltyAmount = 600
				end
				
				local penalty = math.min(raiderCoins.Value, penaltyAmount)
				raiderCoins.Value = raiderCoins.Value - penalty
				targetCoins.Value = targetCoins.Value + penalty
			end
		end
		
		-- Invia segnale Client per applicare BodyVelocity di lancio e camera shake (passando il tier)
		local defenseTriggerRemote = ReplicatedStorage:FindFirstChild("GnomeTriggerRemote")
		if defenseTriggerRemote and defenseTriggerRemote:IsA("RemoteEvent") then
			defenseTriggerRemote:FireClient(player, targetPlayer, targetDefenderTier)
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
				
				-- Trigger Moments API sul server (aggiorna tabellone centrale) e sul client (apre notifica)
				local ServerScriptService = game:GetService("ServerScriptService")
				local MomentsService = require(ServerScriptService:WaitForChild("MomentsService"))
				MomentsService.promptCapture(player, "SuccessfulRaid", { Amount = stolenAmount })
				
				local momentsRemote = ReplicatedStorage:FindFirstChild("PromptMomentCapture")
				if momentsRemote and momentsRemote:IsA("RemoteEvent") then
					momentsRemote:FireClient(player, "SuccessfulRaid", stolenAmount)
				end
			end
		end
	end
end)

return RaidService
