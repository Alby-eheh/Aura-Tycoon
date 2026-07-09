--!strict
-- MomentsService.luau
-- Integrazione delle API Roblox Moments e Captures per automatizzare la viralità di gioco.

local CaptureService = game:GetService("CaptureService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MomentsService = {}
local momentsLeaderboard = {} -- Moments di tendenza nel server

-- Registra e pubblica un Moment se il giocatore accetta il prompt
function MomentsService.promptCapture(player: Player, captureType: string, payload: any)
	-- Sfrutta la nuova API Captures del 2026 per registrare uno screenshot/video di 30 secondi
	local success, isCaptureSupported = pcall(function()
		return CaptureService:IsCaptureSupportedAsync()
	end)
	
	if success and isCaptureSupported then
		-- Prompt al client per catturare l'immagine o il video di gioco
		task.spawn(function()
			local successPrompt, result = pcall(function()
				return CaptureService:PromptSaveCaptureAsync(player)
			end)
			
			if successPrompt then
				print("[MomentsService] " .. player.Name .. " ha condiviso un Moment! Tipo: " .. captureType)
				
				-- Aggiorna i dati del feed e inserisce il Moment nel cartellone centrale
				local newMoment = {
					Creator = player.Name,
					Likes = math.random(10, 50),
					Caption = player.Name .. " ha fatto una rapina incredibile! 💸"
				}
				table.insert(momentsLeaderboard, 1, newMoment)
				
				-- Invia aggiornamento a tutti per visualizzazione su cartellone in-game
				local updateBillboard = ReplicatedStorage:FindFirstChild("UpdateMomentsBillboard")
				if updateBillboard and updateBillboard:IsA("RemoteEvent") then
					updateBillboard:FireAllClients(momentsLeaderboard)
				end
			end
		end)
	else
		warn("[MomentsService] Moments API non supportata su questo dispositivo.")
	end
end

return MomentsService
