--!strict
-- TradingService.luau
-- Servizio server per la coordinazione e validazione autorevole degli scambi P2P.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local TradingModule = require(Shared:WaitForChild("TradingModule"))

local TradingService = {}

-- Stato attivo degli scambi correnti: PlayerA -> { Partner: PlayerB, OfferItem: string, Accepted: boolean }
local activeTrades = {}

-- Helper per rimuovere un elemento specifico da una lista CSV dell'inventario
local function removeItemFromCSV(csv: string, itemToRemove: string): string
	local items = string.split(csv, ",")
	local newItems = {}
	local found = false
	for _, item in ipairs(items) do
		if item == itemToRemove and not found then
			found = true -- Rimuove solo la prima occorrenza
		else
			if item ~= "" then
				table.insert(newItems, item)
			end
		end
	end
	return table.concat(newItems, ",")
end

-- Helper per aggiungere un elemento ad una lista CSV dell'inventario
local function addItemToCSV(csv: string, itemToAdd: string): string
	if csv == "" then
		return itemToAdd
	end
	return csv .. "," .. itemToAdd
end

function TradingService.init()
	local tradeInviteRemote = ReplicatedStorage:WaitForChild("TradeInviteRemote") :: RemoteEvent
	local tradeConfirmRemote = ReplicatedStorage:WaitForChild("TradeConfirmRemote") :: RemoteFunction
	
	-- 1. Ricezione dell'invito di scambio
	tradeInviteRemote.OnServerEvent:Connect(function(player: Player, targetPlayer: Player)
		if not targetPlayer or targetPlayer == player then return end
		
		-- Invia l'invito a schermo al destinatario
		tradeInviteRemote:FireClient(targetPlayer, player)
		print("[TradingService] Invito inviato da " .. player.Name .. " a " .. targetPlayer.Name)
		
		-- Registra lo scambio iniziale fittizio
		activeTrades[player] = { Partner = targetPlayer, OfferItem = "", Accepted = false }
		activeTrades[targetPlayer] = { Partner = player, OfferItem = "", Accepted = false }
	end)
	
	-- 2. Gestione della conferma di scambio bilaterale
	tradeConfirmRemote.OnServerInvoke = function(player: Player, action: string, offerItem: string)
		local tradeState = activeTrades[player]
		if not tradeState then return {Success = false, Error = "Nessuno scambio attivo."} end
		
		local partner = tradeState.Partner
		local partnerState = activeTrades[partner]
		if not partnerState then
			activeTrades[player] = nil
			return {Success = false, Error = "Il partner si è disconnesso dallo scambio."}
		end
		
		if action == "Decline" then
			-- Annulla lo scambio per entrambi
			activeTrades[player] = nil
			activeTrades[partner] = nil
			tradeInviteRemote:FireClient(partner, nil) -- Segnala chiusura al partner
			print("[TradingService] Scambio rifiutato da " .. player.Name)
			return {Success = true, Status = "Declined"}
		end
		
		if action == "Confirm" then
			-- Salva l'offerta di questo giocatore
			tradeState.OfferItem = offerItem
			tradeState.Accepted = true
			
			print("[TradingService] " .. player.Name .. " offre: " .. offerItem .. " e attende il partner.")
			
			-- Se entrambi hanno confermato l'offerta, esegui lo scambio!
			if partnerState.Accepted then
				local itemA = tradeState.OfferItem
				local itemB = partnerState.OfferItem
				
				-- Validazione formale tramite TradingModule condiviso
				local offer: TradingModule.TradeOffer = {
					Sender = player,
					Receiver = partner,
					SenderItems = {itemA},
					ReceiverItems = {itemB}
				}
				
				local success, errMessage = TradingModule.validateTrade(offer)
				if not success then
					-- Resetta stati in caso di fallimento
					activeTrades[player] = nil
					activeTrades[partner] = nil
					tradeInviteRemote:FireClient(partner, nil)
					return {Success = false, Error = errMessage}
				end
				
				-- Esegui lo SWAP sicuro negli inventari
				local invA = player:GetAttribute("Inventory") or ""
				local invB = partner:GetAttribute("Inventory") or ""
				
				-- Sottrai offerti e inserisci ricevuti
				if itemA ~= "" then
					invA = removeItemFromCSV(invA, itemA)
					invB = addItemToCSV(invB, itemA)
				end
				
				if itemB ~= "" then
					invB = removeItemFromCSV(invB, itemB)
					invA = addItemToCSV(invA, itemB)
				end
				
				-- Salva i nuovi inventari negli attributi
				player:SetAttribute("Inventory", invA)
				partner:SetAttribute("Inventory", invB)
				
				-- Gestisci disequipaggiamento in caso di cessione dell'oggetto equipaggiato
				if itemA ~= "" and player:GetAttribute("EquippedCosmetic") == itemA then
					player:SetAttribute("EquippedCosmetic", "")
					-- Rimuovi effetti dal personaggio
					local char = player.Character
					if char then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp then
							for _, child in ipairs(hrp:GetChildren()) do
								if child.Name == "CosmeticAura" or child.Name == "CosmeticTag" then
									child:Destroy()
								end
							end
						end
					end
				end
				if itemB ~= "" and partner:GetAttribute("EquippedCosmetic") == itemB then
					partner:SetAttribute("EquippedCosmetic", "")
					local char = partner.Character
					if char then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp then
							for _, child in ipairs(hrp:GetChildren()) do
								if child.Name == "CosmeticAura" or child.Name == "CosmeticTag" then
									child:Destroy()
								end
							end
						end
					end
				end
				
				-- Pulisci sessione di scambio
				activeTrades[player] = nil
				activeTrades[partner] = nil
				
				-- Invia notifica di successo al partner per chiudere la GUI
				tradeInviteRemote:FireClient(partner, player, "Success")
				
				print("[TradingService] Scambio completato con successo tra " .. player.Name .. " e " .. partner.Name)
				return {Success = true, Status = "Completed", NewInventory = invA}
			else
				-- Notifica il partner che questo player ha accettato per aggiornare la sua UI
				tradeInviteRemote:FireClient(partner, player, "Confirmed", offerItem)
				return {Success = true, Status = "Waiting"}
			end
		end
		
		return {Success = false, Error = "Azione non riconosciuta."}
	end
	
	-- Pulisci in caso di disconnessione
	Players.PlayerRemoving:Connect(function(player)
		local tradeState = activeTrades[player]
		if tradeState then
			local partner = tradeState.Partner
			activeTrades[partner] = nil
			tradeInviteRemote:FireClient(partner, nil) -- Segnala interruzione
		end
		activeTrades[player] = nil
	end)
end

return TradingService
