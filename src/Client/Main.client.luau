--!strict
-- Main.client.luau
-- Script di bootstrap principale che inizializza la logica sul Client.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Trova e avvia il modulo client
local StarterPlayerScripts = player:WaitForChild("PlayerScripts")
local TycoonClient = require(StarterPlayerScripts:WaitForChild("TycoonClient"))

print("[CLIENT BOOTSTRAP] Hostile Tycoon Client Modules loaded successfully!")
