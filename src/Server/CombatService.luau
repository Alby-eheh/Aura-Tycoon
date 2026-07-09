--!strict
-- CombatService.luau
-- Servizio server per la gestione del combattimento PvP, knockback, danni, scie armi e damage popup fluttuanti.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local CombatService = {}

local SLAP_DAMAGE = 20
local SLAP_RANGE = 10.0
local SLAP_COOLDOWN = 0.5 -- secondi
local HIT_SOUND_ID = "rbxassetid://12221946"

-- Spawna un'etichetta 3D fluttuante ed animata sopra la testa per indicare i danni o gli effetti
local function spawnDamagePopup(character: Model, text: string, color: Color3)
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamagePopup"
	billboard.Size = UDim2.new(0, 130, 0, 45)
	-- Sfasamento casuale minimo per evitare sovrapposizioni
	billboard.StudsOffset = Vector3.new(math.random(-2, 2), 3, math.random(-1, 1))
	billboard.AlwaysOnTop = true
	billboard.Parent = head
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = 20
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard
	
	-- Anima il popup verso l'alto e dissolvi in dissolvenza
	task.spawn(function()
		local duration = 12
		for i = 1, duration do
			task.wait(0.04)
			billboard.StudsOffset = billboard.StudsOffset + Vector3.new(0, 0.22, 0)
			local transparency = i / duration
			label.TextTransparency = transparency
			label.TextStrokeTransparency = transparency
		end
		billboard:Destroy()
	end)
end

-- Genera una scia luminosa al neon (Trail) che segue la spazzata del braccio
local function spawnSwingTrail(attackerChar: Model, color: Color3)
	-- Cerca il braccio destro (R6: Right Arm, R15: RightLowerArm o RightHand)
	local arm = attackerChar:FindFirstChild("Right Arm") or attackerChar:FindFirstChild("RightLowerArm")
	if not arm or not arm:IsA("BasePart") then return end
	
	local att0 = Instance.new("Attachment")
	att0.Name = "TrailAtt0"
	att0.Position = Vector3.new(0, -arm.Size.Y/2, 0)
	att0.Parent = arm
	
	local att1 = Instance.new("Attachment")
	att1.Name = "TrailAtt1"
	att1.Position = Vector3.new(0, arm.Size.Y/2, 0)
	att1.Parent = arm
	
	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(color)
	trail.LightEmission = 1.0
	trail.LightInfluence = 0
	trail.Lifetime = 0.22
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	trail.Parent = arm
	
	task.delay(0.3, function()
		trail:Destroy()
		att0:Destroy()
		att1:Destroy()
	end)
end

-- Inizializza gli eventi per PlayerAdded per monitorare la salute
function CombatService.init()
	local slapSwingRemote = ReplicatedStorage:WaitForChild("SlapSwingRemote") :: RemoteEvent
	
	slapSwingRemote.OnServerEvent:Connect(function(attacker: Player)
		local attackerChar = attacker.Character
		if not attackerChar then return end
		local attackerHrp = attackerChar:FindFirstChild("HumanoidRootPart") :: Part
		local attackerHum = attackerChar:FindFirstChildOfClass("Humanoid")
		if not attackerHrp or not attackerHum or attackerHum.Health <= 0 then return end
		
		-- 1. Rate-limit (Debounce) sul server
		local now = os.clock()
		local lastSwing = attacker:GetAttribute("LastSlapSwing") or 0
		if now - lastSwing < SLAP_COOLDOWN then return end
		attacker:SetAttribute("LastSlapSwing", now)
		
		-- 2. Colore della scia (Trail) basato sull'Aura equipaggiata
		local cosmetic = attacker:GetAttribute("EquippedCosmetic") or ""
		local trailColor = Color3.fromRGB(255, 255, 255) -- Bianco di default
		if cosmetic == "Aura Grigia" then
			trailColor = Color3.fromRGB(150, 150, 150)
		elseif cosmetic == "Neon Ciano Aura" then
			trailColor = Color3.fromRGB(0, 240, 255)
		elseif cosmetic == "★ Golden Aura" then
			trailColor = Color3.fromRGB(255, 215, 0)
		end
		
		spawnSwingTrail(attackerChar, trailColor)
		print("[CombatService] " .. attacker.Name .. " sferra uno schiaffo.")
		
		-- 3. Ricerca del bersaglio più vicino entro SLAP_RANGE
		local targetPlayer: Player? = nil
		local minDistance = SLAP_RANGE
		
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer == attacker then continue end
			local otherChar = otherPlayer.Character
			if not otherChar then continue end
			local otherHrp = otherChar:FindFirstChild("HumanoidRootPart") :: Part
			local otherHum = otherChar:FindFirstChildOfClass("Humanoid")
			if not otherHrp or not otherHum or otherHum.Health <= 0 then continue end
			
			local dist = (otherHrp.Position - attackerHrp.Position).Magnitude
			if dist < minDistance then
				minDistance = dist
				targetPlayer = otherPlayer
			end
		end
		
		-- 4. Applica il colpo se il bersaglio è valido
		if targetPlayer then
			local targetChar = targetPlayer.Character
			if not targetChar then return end
			local targetHrp = targetChar:FindFirstChild("HumanoidRootPart") :: Part
			local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
			if not targetHrp or not targetHum then return end
			
			-- Applica danno
			targetHum.Health = math.max(targetHum.Health - SLAP_DAMAGE, 0)
			
			-- Spawna popup di danno 3D
			spawnDamagePopup(targetChar, "-" .. SLAP_DAMAGE .. " HP", Color3.fromRGB(255, 0, 50))
			
			-- Riproduci suono di impatto spaziale
			local hitSound = Instance.new("Sound")
			hitSound.SoundId = HIT_SOUND_ID
			hitSound.Volume = 0.9
			hitSound.Parent = targetHrp
			hitSound:Play()
			hitSound.Ended:Connect(function() hitSound:Destroy() end)
			
			-- Crea effetto particellare rosso temporaneo
			local attachment = Instance.new("Attachment")
			attachment.Position = Vector3.new(0, 1, 0)
			attachment.Parent = targetHrp
			
			local hitEmitter = Instance.new("ParticleEmitter")
			hitEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 0, 50))
			hitEmitter.Size = NumberSequence.new(0.4, 0.8)
			hitEmitter.Speed = NumberRange.new(5, 15)
			hitEmitter.Rate = 40
			hitEmitter.Lifetime = NumberRange.new(0.3, 0.5)
			hitEmitter.Parent = attachment
			
			task.spawn(function()
				task.wait(0.15)
				hitEmitter.Enabled = false
				task.wait(0.5)
				attachment:Destroy()
			end)
			
			-- Applica knockback fisico sul server tramite AssemblyLinearVelocity
			local direction = (targetHrp.Position - attackerHrp.Position).Unit
			targetHrp.AssemblyLinearVelocity = direction * 45 + Vector3.new(0, 20, 0)
			
			print("[CombatService] " .. attacker.Name .. " colpisce " .. targetPlayer.Name .. "! HP rimanenti: " .. targetHum.Health)
			
			-- 5. Gestione della sconfitta del bersaglio (HP == 0)
			if targetHum.Health <= 0 then
				CombatService.handleDefeat(targetPlayer, attacker)
			end
		end
	end)
end

-- Gestisce la sconfitta del giocatore, la perdita dei Sheckles e il respawn
function CombatService.handleDefeat(victim: Player, killer: Player)
	print("[CombatService] " .. victim.Name .. " è stato atterrato da " .. killer.Name)
	
	local victimChar = victim.Character
	if victimChar then
		spawnDamagePopup(victimChar, "KO!", Color3.fromRGB(255, 196, 0))
	end
	
	local victimStats = victim:FindFirstChild("leaderstats")
	local sheckles = victimStats and victimStats:FindFirstChild("Sheckles") :: IntValue
	local lossAmount = 0
	
	if sheckles and sheckles.Value > 0 then
		lossAmount = math.floor(sheckles.Value * 0.15)
		sheckles.Value = sheckles.Value - lossAmount
		
		-- Genera un bottino di monete fisiche a terra nel punto di morte
		local char = victim.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				CombatService.spawnLootCoins(hrp.Position, lossAmount)
			end
		end
	end
	
	-- Annuncia la sconfitta sul tabellone centrale
	local ServerScriptService = game:GetService("ServerScriptService")
	local MomentsService = require(ServerScriptService.MomentsService)
	MomentsService.recordFailedRaid(victim, killer, 0) -- riutilizza la logica per aggiornare il cartellone
	
	-- Teletrasporta la vittima al proprio plot di appartenenza e ripristina la salute
	local plotId = victim:GetAttribute("PlotId")
	if plotId then
		task.spawn(function()
			task.wait(2.0) -- Tempo prima del respawn
			local MapService = require(ServerScriptService.MapService)
			
			local victimCharModel = victim.Character or victim.CharacterAdded:Wait()
			local victimHrp = victimCharModel:WaitForChild("HumanoidRootPart") :: Part
			local victimHum = victimCharModel:WaitForChild("Humanoid") :: Humanoid
			
			if victimHrp and victimHum then
				-- Teletrasporto
				if MapService.PLOT_COORDINATES then
					victimHrp.CFrame = CFrame.new(MapService.PLOT_COORDINATES[plotId] + Vector3.new(0, 4, 0))
				end
				-- Ripristino salute
				victimHum.Health = 100
				print("[CombatService] " .. victim.Name .. " respawnato sul suo plot.")
			end
		end)
	end
end

-- Genera un blocco fisico di monete raccoglibile da chiunque
function CombatService.spawnLootCoins(position: Vector3, amount: number)
	if amount <= 0 then return end
	
	local lootPart = Instance.new("Part")
	lootPart.Name = "LootCoins"
	lootPart.Size = Vector3.new(3, 1.2, 3)
	lootPart.Position = position + Vector3.new(0, 1, 0)
	lootPart.Color = Color3.fromRGB(255, 215, 0) -- Oro
	lootPart.Material = Enum.Material.Glass
	lootPart.Anchored = false
	lootPart.CanCollide = true
	lootPart.Parent = Workspace
	
	-- Scritta 3D
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = lootPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+" .. amount .. " Sheckles\n(Raccogli)"
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.TextSize = 14
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0
	label.Parent = billboard
	
	-- Effetto rotazione locale
	local rotation = Instance.new("BodyAngularVelocity")
	rotation.AngularVelocity = Vector3.new(0, 2, 0)
	rotation.MaxTorque = Vector3.new(0, 100000, 0)
	rotation.Parent = lootPart
	
	local claimed = false
	
	lootPart.Touched:Connect(function(otherPart)
		if claimed then return end
		local character = otherPart.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		
		claimed = true
		lootPart:Destroy()
		
		local stats = player:FindFirstChild("leaderstats")
		local sheckles = stats and stats:FindFirstChild("Sheckles") :: IntValue
		if sheckles then
			sheckles.Value = sheckles.Value + amount
			print("[CombatService] " .. player.Name .. " ha raccolto " .. amount .. " Sheckles da terra.")
			
			-- Riproduci suono claim monete
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://12221967"
				sound.Volume = 0.8
				sound.Parent = hrp
				sound:Play()
				sound.Ended:Connect(function() sound:Destroy() end)
			end
		end
	end)
	
	-- Auto-distruzione dopo 60 secondi se non raccolto (garbage collection)
	task.delay(60.0, function()
		if lootPart.Parent then
			lootPart:Destroy()
		end
	end)
end

return CombatService
