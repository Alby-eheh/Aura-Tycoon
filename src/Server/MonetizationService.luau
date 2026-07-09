--!strict
-- MonetizationService.luau
-- Gestione dei Creator Rewards e abbonamento Roblox Plus.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local MonetizationService = {}

-- Inizializza i trigger di sessione per catturare le ricompense degli spender
function MonetizationService.init()
	Players.PlayerAdded:Connect(function(player)
		-- Traccia il tempo di sessione
		player:SetAttribute("SessionStartTime", os.time())
		
		-- Controlla se l'utente ha Roblox Plus (abbonamento)
		local success, hasPlus = pcall(function()
			-- API fittizia/simulata 2026
			return player:GetAttribute("IsRobloxPlusSubscriber") or false
		end)
		
		if success and hasPlus then
			print("[Roblox Plus] Abbonato rilevato: " .. player.Name .. ". Fornisco accesso gratuito ai server privati.")
			-- Premio extra per server privato dello sviluppatore (fino a 100 Robux)
			MonetizationService.trackPrivateServerReward(player)
		end
	end)
end

-- Monitora il tempo trascorso per ottenere la ricompensa di 5 Robux Creator Reward
function MonetizationService.trackPlaytime(player: Player)
	task.spawn(function()
		task.wait(600) -- Attendi 10 minuti di gioco
		
		if player and player.Parent then
			-- Verifica se l'utente è un "Active Spender" accreditato
			local isActiveSpender = player:GetAttribute("IsActiveSpender") or false
			if isActiveSpender then
				print("[Creator Rewards] Erogati 5 Robux dallo spender attivo: " .. player.Name)
				-- Incrementa il log interno analytics delle entrate
			end
		end
	end)
end

function MonetizationService.trackPrivateServerReward(player: Player)
	task.spawn(function()
		task.wait(3600) -- 60 minuti nei server privati del clan
		if player and player.Parent and game.PrivateServerId ~= "" then
			print("[Roblox Plus Server Payout] Generati 100 Robux Premium dal server privato del giocatore: " .. player.Name)
		end
	end)
end

return MonetizationService
