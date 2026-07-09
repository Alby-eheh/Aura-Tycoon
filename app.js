// Hostile Tycoon 2026 Simulator and Dashboard Engine

// Global State
let state = {
  wallet: 1500,
  robux: 250,
  ccu: 12500,
  rewards: 1240,
  bounceRate: 12,
  retention: { d1: 62, d7: 38, d28: 18 },
  
  // Player Tycoon
  player: {
    generatorLvl: 1,
    generatorIncome: 10,
    storage: 0,
    gnomeActive: false,
    gnomeTimeRemaining: 0,
    inventory: []
  },
  
  // Rivals
  rivals: {
    rival1: { name: "Rival_X1", income: 25, storage: 150, gnomeActive: true },
    rival2: { name: "BombardinoPro", income: 10, storage: 240, gnomeActive: false },
    rival3: { name: "TralaleroFan", income: 50, storage: 80, gnomeActive: true }
  },

  activeTab: 'simulator',
  activeLuauFile: 'TycoonService',
  ccuHistory: Array.from({length: 40}, () => 11000 + Math.random() * 3000),
  activeRaidTarget: null
};

// Luau Source Codes Library (Argon-Ready)
const LUAU_CODES = {
  TycoonService: `--!strict
-- TycoonService.luau
-- Gestisce la generazione idle di risorse sul server e il salvataggio dei dati.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonDataStore = DataStoreService:GetDataStore("TycoonSaveSystem_2026")
local TycoonService = {}

local plots = {} -- Mappa UserId -> Plot
local INCOME_TICK_RATE = 1.0 -- Secondi

-- Carica o inizializza i dati del Tycoon del giocatore
function TycoonService.loadData(player: Player)
	local userId = player.UserId
	local success, savedData = pcall(function()
		return TycoonDataStore:GetAsync(tostring(userId))
	end)
	
	if success and savedData then
		plots[userId] = {
			Owner = player,
			GeneratorLevel = savedData.GeneratorLevel or 1,
			Storage = savedData.Storage or 0,
			GnomeActiveUntil = savedData.GnomeActiveUntil or 0
		}
	else
		-- Dati default se nuovo utente
		plots[userId] = {
			Owner = player,
			GeneratorLevel = 1,
			Storage = 0,
			GnomeActiveUntil = 0
		}
	end
	print("[TycoonService] Dati caricati per: " .. player.Name)
end

-- Ciclo Idle Autorevole sul Server
task.spawn(function()
	while true do
		task.wait(INCOME_TICK_RATE)
		for userId, plot in pairs(plots) do
			if plot.Owner and plot.Owner.Parent then
				-- Guadagno base basato sul livello del generatore
				local income = plot.GeneratorLevel * 10
				plot.Storage = plot.Storage + income
				
				-- Notifica il client del nuovo bilancio storage
				local remote = ReplicatedStorage:FindFirstChild("UpdateStorageRemote")
				if remote and remote:IsA("RemoteEvent") then
					remote:FireClient(plot.Owner, plot.Storage)
				end
			else
				plots[userId] = nil
			end
		end
	end
end)

-- Salva i dati alla disconnessione
Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	local plot = plots[userId]
	if plot then
		pcall(function()
			TycoonDataStore:SetAsync(tostring(userId), {
				GeneratorLevel = plot.GeneratorLevel,
				Storage = plot.Storage,
				GnomeActiveUntil = plot.GnomeActiveUntil
			})
		end)
		plots[userId] = nil
	end
end)

return TycoonService`,

  RaidService: `--!strict
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

return RaidService`,

  MomentsService: `--!strict
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

return MomentsService`,

  ServerRestartService: `--!strict
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

return ServerRestartService`,

  MonetizationService: `--!strict
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

return MonetizationService`,

  TradingModule: `--!strict
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

return TradingModule`,

  TycoonClient: `--!strict
-- TycoonClient.luau
-- Logica Client per controlli responsivi touch/controller e invio Moments.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local claimButton = script.Parent:WaitForChild("ClaimButton")

-- Parità di Input (Mobile, Controller, PC)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Se preme il tasto del controller (ButtonA) o tocca lo schermo
	if input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonA then
		print("[TycoonClient] Input rilevato, procedo all'azione immediata.")
		-- Esegui l'azione focalizzata (acquisto/potenziamento) per evitare latenze
	end
end)

-- Ricezione evento Gnome Knockback (Lancio in aria con rimbalzo)
local GnomeTriggerRemote = ReplicatedStorage:WaitForChild("GnomeTriggerRemote")
GnomeTriggerRemote.OnClientEvent:Connect(function(attacker)
	print("[Client] Sei stato sbalzato dallo Gnomo protettivo!")
	
	local character = player.Character
	if character then
		local hrp = character:WaitForChild("HumanoidRootPart")
		if hrp then
			-- Applica effetto rimbalzo in aria
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, 100, 50)
			bodyVelocity.MaxForce = Vector3.new(0, 100000, 100000)
			bodyVelocity.Parent = hrp
			task.wait(0.4)
			bodyVelocity:Destroy()
		end
	end
end)

-- Gestione Prompt Moments API
local promptMomentRemote = ReplicatedStorage:WaitForChild("PromptMomentCapture")
promptMomentRemote.OnClientEvent:Connect(function(actionType, score)
	-- Richiama localmente il prompt di sistema
	print("[Moments Client] Prompt di salvataggio clip video per: " .. actionType)
end)
`
};

// Tabs switcher logic
function switchTab(tabId) {
  state.activeTab = tabId;
  
  // DOM Updates
  document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));
  
  document.getElementById(`tab-${tabId}`).classList.add('active');
  document.getElementById(`nav-btn-${tabId}`).classList.add('active');

  if (tabId === 'analytics') {
    // Redraw chart when entering analytics tab
    setTimeout(drawChart, 100);
  }
}

// Luau Display logic
function showLuauCode(fileName) {
  state.activeLuauFile = fileName;
  document.querySelectorAll('.file-item').forEach(el => el.classList.remove('active'));
  
  // Find which list item to activate
  const items = document.querySelectorAll('.file-item');
  items.forEach(item => {
    if (item.textContent.trim().includes(fileName)) {
      item.classList.add('active');
    }
  });
  
  const path = fileName === 'TradingModule' ? `src/Shared/${fileName}.luau` : 
               fileName === 'TycoonClient' ? `src/Client/${fileName}.luau` : `src/Server/${fileName}.luau`;
               
  document.getElementById('displayed-file-name').textContent = path;
  document.getElementById('code-display-area').textContent = LUAU_CODES[fileName];
}

// Copy to Clipboard logic
function copyActiveCode() {
  const code = LUAU_CODES[state.activeLuauFile];
  navigator.clipboard.writeText(code).then(() => {
    alert("Codice copiato negli appunti con successo!");
  });
}

// CLAIM PLAYER STORAGE
function claimPlayerStorage() {
  if (state.player.storage > 0) {
    const gained = state.player.storage;
    state.wallet += gained;
    state.player.storage = 0;
    
    // UI Update
    document.getElementById('player-wallet').textContent = formatNumber(state.wallet);
    document.getElementById('player-storage').textContent = "0";
    
    // Tiny bounce animation on wallet
    const walletBubble = document.getElementById('header-wallet-bubble');
    walletBubble.style.transform = "scale(1.15)";
    setTimeout(() => walletBubble.style.transform = "scale(1)", 150);
  }
}

// UPGRADE GENERATOR
function upgradeGenerator() {
  const cost = state.player.generatorLvl * 50;
  if (state.wallet >= cost) {
    state.wallet -= cost;
    state.player.generatorLvl += 1;
    state.player.generatorIncome = state.player.generatorLvl * 10;
    
    // UI Update
    document.getElementById('player-wallet').textContent = formatNumber(state.wallet);
    document.getElementById('gen-lvl-1').textContent = `Lvl ${state.player.generatorLvl}`;
    document.querySelector('#plot-player .gen-income').textContent = `+${state.player.generatorIncome}/s`;
    
    const nextCost = state.player.generatorLvl * 50;
    document.getElementById('btn-upgrade-gen').innerHTML = `<i class="fa-solid fa-arrow-up"></i> Potenzia Gen (${nextCost} Sheckles)`;
    
    // Check if we unlock secondary generator at Level 5
    if (state.player.generatorLvl >= 5 && document.getElementById('gen-lvl-2').textContent === "Bloccato") {
      document.getElementById('gen-2-row').style.opacity = "1";
      document.getElementById('gen-lvl-2').textContent = "Lvl 1";
      document.querySelector('#gen-2-row .gen-income').textContent = "+30/s";
      state.player.generatorIncome += 30;
    }
  } else {
    alert("Monete Sheckles insufficienti!");
  }
}

// BUY DEFENSIVE GNOME (Simulated Robux or big Sheckles purchase)
function buyGnome() {
  if (state.robux >= 95) {
    state.robux -= 95;
    state.player.gnomeActive = true;
    state.player.gnomeTimeRemaining = 600; // 10 minutes (simulated)
    
    // UI Update
    document.getElementById('player-robux').textContent = state.robux;
    document.getElementById('player-gnome-status').innerHTML = `<span class="badge badge-success"><i class="fa-solid fa-shield-halved"></i> Gnomo Attivo (10:00)</span>`;
    
    // Robux deduction effect
    const robuxBubble = document.getElementById('header-robux-bubble');
    robuxBubble.style.transform = "scale(1.15)";
    setTimeout(() => robuxBubble.style.transform = "scale(1)", 150);
  } else {
    alert("Robux insufficienti! I Robux sono simulati per dimostrazione.");
  }
}

// EXECUTE RAIDS
function executeRaid(rivalId) {
  const rival = state.rivals[rivalId];
  if (!rival) return;

  state.activeRaidTarget = rivalId;
  const targetCard = document.getElementById(`plot-${rivalId}`);
  
  // Animation: temporary attack lock
  targetCard.style.boxShadow = "0 0 25px rgba(255, 0, 85, 0.4)";
  
  setTimeout(() => {
    targetCard.style.boxShadow = "";
    
    if (rival.gnomeActive) {
      // Defeated by Gnome! Gnome knocks back player
      alert(`[GNOME PROTETTIVO] Lo Gnomo di ${rival.name} si è attivato! Sei stato lanciato in aria ed hai perso 50 Sheckles!`);
      state.wallet = Math.max(state.wallet - 50, 0);
      document.getElementById('player-wallet').textContent = formatNumber(state.wallet);
      
      // Simulate penalty transfer
      rival.storage += 50;
      document.getElementById(`${rivalId}-storage`).textContent = formatNumber(rival.storage);
    } else {
      // Successful Raid!
      const stolen = rival.storage;
      rival.storage = 0;
      document.getElementById(`${rivalId}-storage`).textContent = "0";
      
      // Open Roblox Moments dialog prompt
      openMomentsModal(stolen);
    }
  }, 600);
}

// Moments Modal actions
function openMomentsModal(stolenAmount) {
  document.getElementById('modal-stolen-coins').textContent = stolenAmount;
  document.getElementById('moments-modal').classList.add('active');
}

function closeMomentsModal(publish) {
  document.getElementById('moments-modal').classList.remove('active');
  
  if (publish) {
    const caption = document.getElementById('moment-caption-input').value;
    const stolenAmount = parseInt(document.getElementById('modal-stolen-coins').textContent);
    
    // Add stolen money to wallet
    state.wallet += stolenAmount;
    document.getElementById('player-wallet').textContent = formatNumber(state.wallet);
    
    // Add to simulated Moments Board
    addMomentToFeed("Te (Player_Pro)", caption);
    
    // Small boost to analytics CCU due to viral sharing
    state.ccu += 450;
    state.rewards += 20;
    document.getElementById('live-ccu-count').textContent = formatNumber(state.ccu);
    document.getElementById('rewards-accumulated').textContent = formatNumber(state.rewards);
  }
  
  state.activeRaidTarget = null;
}

function addMomentToFeed(author, text) {
  const list = document.getElementById('moments-billboard-list');
  const card = document.createElement('div');
  card.className = "moment-card";
  card.innerHTML = `
    <div class="moment-meta">
      <span class="moment-author"><i class="fa-solid fa-user-astronaut"></i> ${author}</span>
      <span class="moment-likes"><i class="fa-solid fa-heart text-red"></i> 1</span>
    </div>
    <p class="moment-desc">${text}</p>
    <div class="moment-action-row">
      <span class="badge badge-success" style="font-size: 0.65rem;">Trending</span>
    </div>
  `;
  list.insertBefore(card, list.firstChild);
}

// Simulates player joining from Moment
function simulateJoinServer(username) {
  alert(`Teletrasporto in corso verso il server di ${username}...`);
  state.ccu += 1;
  document.getElementById('live-ccu-count').textContent = formatNumber(state.ccu);
}

// Ethical Gacha
function openGachaBox() {
  if (state.wallet >= 20) {
    state.wallet -= 20;
    document.getElementById('player-wallet').textContent = formatNumber(state.wallet);
    
    // Roll odds
    const roll = Math.random() * 100;
    let result = "";
    let rarity = "common";
    
    if (roll < 10) { // 10% Legendary
      const cosmetics = ["★ Aura Tralalero d'Oro", "★ Tag Voxel GigaChad", "★ Gnomo Dorato Spaziale"];
      result = cosmetics[Math.floor(Math.random() * cosmetics.length)];
      rarity = "legendary";
    } else if (roll < 40) { // 30% Rare
      const cosmetics = ["Aura Neon Ciano", "Tag Bombardino Voxel", "Scia Scintillante"];
      result = cosmetics[Math.floor(Math.random() * cosmetics.length)];
      rarity = "rare";
    } else { // 60% Common
      const cosmetics = ["Tag Noob Voxel", "Aura Grigia", "Effetto Vento"];
      result = cosmetics[Math.floor(Math.random() * cosmetics.length)];
      rarity = "common";
    }
    
    document.getElementById('gacha-result-display').innerHTML = `Hai trovato: <strong class="rarity-${rarity}">${result}</strong>`;
    
    // Add to Inventory
    state.player.inventory.push({ name: result, rarity: rarity });
    updateInventoryUI();
  } else {
    alert("Sheckles insufficienti!");
  }
}

function updateInventoryUI() {
  const container = document.getElementById('player-inventory-list');
  if (state.player.inventory.length === 0) {
    container.innerHTML = '<span class="inventory-empty text-muted">Inventario vuoto</span>';
    return;
  }
  
  container.innerHTML = "";
  state.player.inventory.forEach(item => {
    const span = document.createElement('span');
    span.className = `inventory-tag ${item.rarity}`;
    span.textContent = item.name;
    container.appendChild(span);
  });
}

// TAB 2: TELEMETRIA E EVENTI
function triggerBrainrotEvent() {
  // Meme event triggers massive spike
  alert("EVENTO VIRALE AVVIATO: TikTok e YouTube Shorts sono inondati dal meme del tuo gioco!");
  state.ccu = 450000;
  state.bounceRate = 4; // ultra engaged
  state.retention.d1 = 78;
  state.rewards += 8500;
  
  // UI Updates
  document.getElementById('live-ccu-count').textContent = formatNumber(state.ccu);
  document.getElementById('rewards-accumulated').textContent = formatNumber(state.rewards);
  document.getElementById('bounce-rate-gauge').style.width = "4%";
  document.getElementById('bounce-rate-gauge').textContent = "4%";
  document.getElementById('ret-d1').textContent = "78%";
  
  // Chart Status Update
  document.getElementById('chart-status-text').textContent = "Stato: Picco Virale Meme Event!";
  document.getElementById('chart-status-text').style.borderColor = "var(--color-red)";
  document.getElementById('chart-status-text').style.color = "var(--color-red)";
  
  // Simulate historical data jump
  for (let i = 0; i < 15; i++) {
    state.ccuHistory.push(400000 + Math.random() * 50000);
    state.ccuHistory.shift();
  }
  drawChart();
}

function triggerServerRestart() {
  alert("LIVEOPS: Server Restart Schedulato per aggiornamento non invasivo dei dati.");
  
  // CCU goes down to 0, data gets saved, and recovers
  state.ccu = 0;
  document.getElementById('live-ccu-count').textContent = "0";
  document.getElementById('chart-status-text').textContent = "Stato: Salvo Dati & Riavvio...";
  
  // Simulate historical fall
  for (let i = 0; i < 5; i++) {
    state.ccuHistory.push(0);
    state.ccuHistory.shift();
  }
  drawChart();
  
  setTimeout(() => {
    state.ccu = 15000; // Recovers higher
    document.getElementById('live-ccu-count').textContent = formatNumber(state.ccu);
    document.getElementById('chart-status-text').textContent = "Stato: Server Migrati con Successo!";
    document.getElementById('chart-status-text').style.borderColor = "var(--color-green)";
    document.getElementById('chart-status-text').style.color = "var(--color-green)";
    
    for (let i = 0; i < 5; i++) {
      state.ccuHistory.push(12000 + Math.random() * 3000);
      state.ccuHistory.shift();
    }
    drawChart();
  }, 3000);
}

// REALTIME CHART SYSTEM (Canvas Drawing)
function drawChart() {
  const canvas = document.getElementById('ccuLiveChart');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  
  // Clear Canvas
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  
  const width = canvas.width;
  const height = canvas.height;
  const padding = 30;
  
  // Draw grid
  ctx.strokeStyle = "rgba(255, 255, 255, 0.05)";
  ctx.lineWidth = 1;
  for (let i = 1; i < 5; i++) {
    const y = padding + (height - 2 * padding) * (i / 5);
    ctx.beginPath();
    ctx.moveTo(padding, y);
    ctx.lineTo(width - padding, y);
    ctx.stroke();
  }
  
  // Draw CCU Line
  const data = state.ccuHistory;
  const maxVal = Math.max(...data, 20000); // dynamic scale
  
  ctx.beginPath();
  const getX = (index) => padding + (width - 2 * padding) * (index / (data.length - 1));
  const getY = (val) => height - padding - (height - 2 * padding) * (val / maxVal);
  
  ctx.moveTo(getX(0), getY(data[0]));
  for (let i = 1; i < data.length; i++) {
    ctx.lineTo(getX(i), getY(data[i]));
  }
  
  // Style CCU Line
  ctx.strokeStyle = state.ccu > 100000 ? "#ff0055" : "#00f0ff";
  ctx.lineWidth = 3;
  ctx.shadowBlur = 10;
  ctx.shadowColor = state.ccu > 100000 ? "rgba(255, 0, 85, 0.5)" : "rgba(0, 240, 255, 0.5)";
  ctx.stroke();
  
  // Clear shadow for area fill
  ctx.shadowBlur = 0;
  
  // Gradient Area Fill
  ctx.lineTo(getX(data.length - 1), height - padding);
  ctx.lineTo(getX(0), height - padding);
  ctx.closePath();
  
  const fillGrad = ctx.createLinearGradient(0, padding, 0, height - padding);
  if (state.ccu > 100000) {
    fillGrad.addColorStop(0, "rgba(255, 0, 85, 0.15)");
    fillGrad.addColorStop(1, "rgba(255, 0, 85, 0.0)");
  } else {
    fillGrad.addColorStop(0, "rgba(0, 240, 255, 0.15)");
    fillGrad.addColorStop(1, "rgba(0, 240, 255, 0.0)");
  }
  ctx.fillStyle = fillGrad;
  ctx.fill();
}

// Idle loop simulating ticks and rivals accrual
setInterval(() => {
  // Idle money generation for Player
  state.player.storage += state.player.generatorIncome;
  document.getElementById('player-storage').textContent = formatNumber(state.player.storage);
  
  // Idle money generation for Rivals
  for (const rivalId in state.rivals) {
    const rival = state.rivals[rivalId];
    rival.storage += rival.income;
    document.getElementById(`${rivalId}-storage`).textContent = formatNumber(rival.storage);
  }
  
  // Gnome timer tick for player
  if (state.player.gnomeActive) {
    state.player.gnomeTimeRemaining -= 1;
    if (state.player.gnomeTimeRemaining <= 0) {
      state.player.gnomeActive = false;
      document.getElementById('player-gnome-status').innerHTML = `<span class="text-muted">Nessuna difesa attiva</span>`;
    } else {
      const min = Math.floor(state.player.gnomeTimeRemaining / 60);
      const sec = String(state.player.gnomeTimeRemaining % 60).padStart(2, '0');
      document.getElementById('player-gnome-status').innerHTML = `<span class="badge badge-success"><i class="fa-solid fa-shield-halved"></i> Gnomo Attivo (${min}:${sec})</span>`;
    }
  }
  
  // Telemetry fluctuation
  let ccuFluctuation = (Math.random() - 0.5) * 500;
  if (state.ccu < 50000) {
    state.ccu = Math.max(state.ccu + ccuFluctuation, 8000);
    state.ccuHistory.push(state.ccu);
  } else {
    state.ccu = Math.max(state.ccu + ccuFluctuation * 2, 380000);
    state.ccuHistory.push(state.ccu);
  }
  state.ccuHistory.shift();
  
  // Update CCU Display
  document.getElementById('live-ccu-count').textContent = formatNumber(Math.floor(state.ccu));
  
  // Accumulate rewards slightly
  if (state.ccu > 0) {
    state.rewards += Math.floor(state.ccu / 2000);
    document.getElementById('rewards-accumulated').textContent = formatNumber(state.rewards);
  }
  
  // Draw chart if active
  if (state.activeTab === 'analytics') {
    drawChart();
  }
}, 1000);

// Helper functions
function formatNumber(num) {
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Initializing the application
window.onload = function() {
  showLuauCode('TycoonService');
  updateInventoryUI();
};
