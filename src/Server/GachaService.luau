--!strict
-- GachaService.luau
-- Gestisce i cosmetici (Auree, Scie, Tag), l'unboxing ed equipaggiamento nel Workspace.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GachaService = {}

-- Database dei cosmetici disponibili
local COSMETIC_DATABASE = {
	common = {
		"Aura Grigia", "Effetto Vento"
	},
	rare = {
		"Neon Ciano Aura", "Tag Pro Voxel"
	},
	legendary = {
		"★ Golden Aura", "★ Tag GigaChad"
	}
}

-- Configura ed equipaggia l'aurora visiva sul personaggio
local function applyVisualCosmetic(player: Player, cosmeticName: string)
	local character = player.Character
	if not character then return end
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: Part
	if not hrp then return end

	-- 1. Pulisci eventuali cosmetici pregressi
	for _, child in ipairs(hrp:GetChildren()) do
		if child.Name == "CosmeticAura" or child.Name == "CosmeticTag" then
			child:Destroy()
		end
	end
	local head = character:WaitForChild("Head", 5) :: Part
	if head then
		for _, child in ipairs(head:GetChildren()) do
			if child.Name == "CosmeticTag" then
				child:Destroy()
			end
		end
	end

	-- 2. Applica la nuova aurora/tag
	local assetName = nil
	if cosmeticName == "Aura Grigia" then
		assetName = "AuraGrigia"
	elseif cosmeticName == "Neon Ciano Aura" then
		assetName = "NeonCianoAura"
	elseif cosmeticName == "★ Golden Aura" then
		assetName = "GoldenAura"
	end
	
	if assetName then
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local aurasFolder = assets and assets:FindFirstChild("Auras")
		local template = aurasFolder and aurasFolder:FindFirstChild(assetName)
		
		if template then
			local clone = template:Clone()
			-- Assicura colorazioni e parametri dinamici corretti
			if cosmeticName == "Aura Grigia" then
				clone.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150))
				clone.Size = NumberSequence.new(1.5)
			elseif cosmeticName == "Neon Ciano Aura" then
				clone.Color = ColorSequence.new(Color3.fromRGB(0, 240, 255))
				clone.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 2),
					NumberSequenceKeypoint.new(1, 0)
				})
			elseif cosmeticName == "★ Golden Aura" then
				clone.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
				clone.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 2.5),
					NumberSequenceKeypoint.new(1, 0.5)
				})
				clone.SpreadAngle = Vector2.new(10, 10)
			end
			clone.Parent = hrp
			print("[GachaService] Caricato asset aura da cartella Assets: " .. assetName)
		else
			-- Fallback procedurale se l'utente non ha ancora compilato gli Assets o in offline test
			if cosmeticName == "Aura Grigia" then
				local emitter = Instance.new("ParticleEmitter")
				emitter.Name = "CosmeticAura"
				emitter.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150))
				emitter.Size = NumberSequence.new(1.5)
				emitter.Lifetime = NumberRange.new(1.5, 2)
				emitter.Rate = 15
				emitter.Speed = NumberRange.new(2, 4)
				emitter.Parent = hrp
			elseif cosmeticName == "Neon Ciano Aura" then
				local emitter = Instance.new("ParticleEmitter")
				emitter.Name = "CosmeticAura"
				emitter.Color = ColorSequence.new(Color3.fromRGB(0, 240, 255))
				emitter.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 2),
					NumberSequenceKeypoint.new(1, 0)
				})
				emitter.LightEmission = 0.8
				emitter.Lifetime = NumberRange.new(1, 1.5)
				emitter.Rate = 25
				emitter.Speed = NumberRange.new(1, 3)
				emitter.Parent = hrp
			elseif cosmeticName == "★ Golden Aura" then
				local emitter = Instance.new("ParticleEmitter")
				emitter.Name = "CosmeticAura"
				emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
				emitter.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 2.5),
					NumberSequenceKeypoint.new(1, 0.5)
				})
				emitter.LightEmission = 1.0
				emitter.Lifetime = NumberRange.new(1, 2)
				emitter.Rate = 35
				emitter.Speed = NumberRange.new(1, 4)
				emitter.SpreadAngle = Vector2.new(10, 10)
				emitter.Parent = hrp
			end
		end
	elseif cosmeticName == "Tag Pro Voxel" and head then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "CosmeticTag"
		billboard.Size = UDim2.new(0, 120, 0, 30)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = head

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "[ PRO ]"
		label.TextColor3 = Color3.fromRGB(0, 240, 255)
		label.TextSize = 14
		label.Font = Enum.Font.SourceSansBold
		label.TextStrokeTransparency = 0
		label.Parent = billboard

	elseif cosmeticName == "★ Tag GigaChad" and head then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "CosmeticTag"
		billboard.Size = UDim2.new(0, 150, 0, 30)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = head

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "[ ★ GIGACHAD ★ ]"
		label.TextColor3 = Color3.fromRGB(255, 196, 0)
		label.TextSize = 16
		label.Font = Enum.Font.SourceSansBold
		label.TextStrokeTransparency = 0
		label.Parent = billboard
	end
end

function GachaService.init()
	local openGachaRemote = ReplicatedStorage:WaitForChild("OpenGachaRemote") :: RemoteFunction
	local equipCosmeticRemote = ReplicatedStorage:WaitForChild("EquipCosmeticRemote") :: RemoteEvent
	
	-- Gestisce l'unboxing dal client (Spesa: 20 Sheckles)
	openGachaRemote.OnServerInvoke = function(player: Player)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return {Success = false, Error = "No Leaderstats"} end
		
		local sheckles = leaderstats:FindFirstChild("Sheckles") :: IntValue
		if not sheckles or sheckles.Value < 20 then
			return {Success = false, Error = "Sheckles insufficienti!"}
		end
		
		-- Deduce monete
		sheckles.Value = sheckles.Value - 20
		
		-- Calcolo rarità casuale
		local roll = math.random(100)
		local rarity = "common"
		local items = COSMETIC_DATABASE.common
		
		if roll <= 10 then -- 10% Legendary
			rarity = "legendary"
			items = COSMETIC_DATABASE.legendary
		elseif roll <= 40 then -- 30% Rare
			rarity = "rare"
			items = COSMETIC_DATABASE.rare
		end
		
		local selectedItem = items[math.random(#items)]
		
		-- Salva nell'attributo inventario (es: "Aura Grigia,Tag Pro Voxel")
		local currentInv = player:GetAttribute("Inventory") or ""
		local newInv = currentInv == "" and selectedItem or (currentInv .. "," .. selectedItem)
		player:SetAttribute("Inventory", newInv)
		
		print("[GachaService] " .. player.Name .. " ha sbloccato: " .. selectedItem .. " (" .. rarity .. ")")
		return {Success = true, Item = selectedItem, Rarity = rarity, Inventory = newInv}
	end
	
	-- Gestisce la richiesta di equipaggiamento cosmetico
	equipCosmeticRemote.OnServerEvent:Connect(function(player: Player, cosmeticName: string)
		local inventory = player:GetAttribute("Inventory") or ""
		
		-- Verifica che il giocatore possieda l'oggetto nell'inventario
		if string.find(inventory, cosmeticName) or cosmeticName == "" then
			player:SetAttribute("EquippedCosmetic", cosmeticName)
			
			-- Applica l'aurora visiva sul personaggio
			applyVisualCosmetic(player, cosmeticName)
			print("[GachaService] " .. player.Name .. " ha equipaggiato: " .. cosmeticName)
		else
			warn("[GachaService] Tentativo di equipaggiamento abusivo di: " .. cosmeticName .. " da " .. player.Name)
		end
	end)
	
	-- Esegui l'equipaggiamento quando rinasce il personaggio
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			task.wait(1.0) -- Attendi caricamento
			local equipped = player:GetAttribute("EquippedCosmetic") or ""
			if equipped ~= "" then
				applyVisualCosmetic(player, equipped)
			end
		end)
	end)
end

return GachaService
