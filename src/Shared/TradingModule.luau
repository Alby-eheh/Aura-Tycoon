--!strict
-- TradingModule.luau
-- Modulo di validazione sicuro per scambi peer-to-peer (P2P) di aurore e cosmetici.

local TradingModule = {}

export type TradeOffer = {
	Sender: Player,
	Receiver: Player,
	SenderItems: {string},
	ReceiverItems: {string}
}

-- Verifica la validità etica e formale dello scambio sul server
function TradingModule.validateTrade(offer: TradeOffer): (boolean, string)
	-- 1. Verifica che entrambi i player siano connessi
	if not offer.Sender or not offer.Sender.Parent then
		return false, "Il mittente dello scambio si è disconnesso."
	end
	if not offer.Receiver or not offer.Receiver.Parent then
		return false, "Il destinatario dello scambio si è disconnesso."
	end
	
	-- 2. Previene tentativi di scambio duplicato o auto-scambio
	if offer.Sender == offer.Receiver then
		return false, "Impossibile scambiare oggetti con se stessi."
	end
	
	-- 3. Verifica autorevole dell'inventario sul server (previene exploit client)
	local senderInv = offer.Sender:GetAttribute("Inventory") or ""
	local receiverInv = offer.Receiver:GetAttribute("Inventory") or ""
	
	for _, item in ipairs(offer.SenderItems) do
		if not string.find(senderInv, item) then
			return false, "Il mittente non possiede l'oggetto: " .. item
		end
	end
	
	for _, item in ipairs(offer.ReceiverItems) do
		if not string.find(receiverInv, item) then
			return false, "Il destinatario non possiede l'oggetto: " .. item
		end
	end
	
	return true, "Scambio valido e pronto all'esecuzione."
end

return TradingModule
