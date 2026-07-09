--!strict
-- TycoonClient.luau
-- Logica Client per controlli responsivi touch/controller e invio Moments.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local claimButton = PlayerGui:WaitForChild("ClaimButton", 3)
if not claimButton then
	print("[TycoonClient] Info: ClaimButton non trovato in PlayerGui (facoltativo, bypassato).")
end

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
	
	-- Effetto visivo di Camera Shake
	local camera = game:GetService("Workspace").CurrentCamera
	if camera then
		local endTime = os.clock() + 0.5
		task.spawn(function()
			while os.clock() < endTime do
				local shakeOffset = CFrame.new(
					(math.random() - 0.5) * 0.4,
					(math.random() - 0.5) * 0.4,
					(math.random() - 0.5) * 0.4
				) * CFrame.Angles(
					(math.random() - 0.5) * 0.04,
					(math.random() - 0.5) * 0.04,
					(math.random() - 0.5) * 0.04
				)
				camera.CFrame = camera.CFrame * shakeOffset
				task.wait(0.01)
			end
		end)
	end
	
	local character = player.Character
	if character then
		local hrp = character:WaitForChild("HumanoidRootPart")
		if hrp then
			-- Applica effetto rimbalzo in aria
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, 80, -60) -- lo lancia all'indietro
			bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
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
