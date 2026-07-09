--!strict
-- MomentsService.luau
-- Integrazione delle API Roblox Moments, Captures e visualizzazione del feed globale sul tabellone.

local CaptureService = game:GetService("CaptureService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MomentsService = {}
local momentsLeaderboard = {} -- Moments di tendenza nel server

-- Registra e pubblica un Moment se il giocatore accetta il prompt
function MomentsService.promptCapture(player: Player, captureType: string, payload: any)
	-- Sfrutta la nuova API Captures per registrare uno screenshot/video di 30 secondi
	local success, isCaptureSupported = pcall(function()
		return CaptureService:IsCaptureSupportedAsync()
	end)
	
	-- Aggiorna sempre il tabellone centrale 3D a runtime
	local stolenAmount = payload and payload.Amount or 0
	local MapService = require(ServerScriptService:WaitForChild("MapService"))
	MapService.updateBillboardFeed(player.Name .. " ha fatto una rapina epica! Stolen: " .. stolenAmount .. " Sheckles! 💸")

	if success and isCaptureSupported then
		-- Prompt al client per catturare l'immagine o il video di gioco
		task.spawn(function()
			local successPrompt, result = pcall(function()
				return CaptureService:PromptSaveCaptureAsync(player)
			end)
			
			if successPrompt then
				print("[MomentsService] " .. player.Name .. " ha condiviso un Moment! Tipo: " .. captureType)
				
				-- Aggiorna i dati del feed locale
				local newMoment = {
					Creator = player.Name,
					Likes = math.random(10, 50),
					Caption = player.Name .. " ha fatto una rapina incredibile! 💸"
				}
				table.insert(momentsLeaderboard, 1, newMoment)
			end
		end)
	else
		print("[MomentsService] Moments API non supportata localmente, bypassato su questo server.")
	end
end

-- Pubblica un fallimento del raid causato da un difensore sul tabellone
function MomentsService.recordFailedRaid(player: Player, targetPlayer: Player, defenderTier: number)
	local MapService = require(ServerScriptService:WaitForChild("MapService"))
	local defenderName = "Incel"
	if defenderTier == 2 then
		defenderName = "Goat"
	elseif defenderTier == 3 then
		defenderName = "Sigma"
	elseif defenderTier == 4 then
		defenderName = "Aura CEO"
	end
	
	MapService.updateBillboardFeed(player.Name .. " ha provato ad attaccare " .. targetPlayer.Name .. " ma è stato rimbalzato dal difensore: " .. defenderName .. "! 💥")
end

return MomentsService
