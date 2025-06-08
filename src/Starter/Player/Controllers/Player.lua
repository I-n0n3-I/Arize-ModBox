--|| Defining types ||--

---------------------------------------------------------------------------------------------------------

--|| Roblox Services ||--
local Players = game:GetService("Players")
local _RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------------------------------------------------------

--|| Dependencies & Functions ||--
local _Comms = ReplicatedStorage:WaitForChild("_Comm")

---------------------------------------------------------------------------------------------------------

--|| Controller ||--

local Controller = {
	Player = Players.LocalPlayer :: Player,
	Camera = workspace.CurrentCamera :: Camera,

	Name = "PlayerController",
	Description = "This controller manages the player's actions and interactions within the game.",

	Bridge = _Comms._Bridge :: RemoteEvent,
	Gateway = _Comms._Gateway :: RemoteFunction,
	ClientChannel = _Comms._ClientChannel :: BindableEvent,
	Request = _Comms._Request :: BindableFunction,
}
Controller.__index = Controller

function Controller:GameInit()
	-- This function is called when the game initializes.
	workspace:WaitForChild("Dev"):Destroy()
	local Character: Model = self.Player.Character or self.Player.CharacterAdded:Wait()
	local _RootPart = Character:WaitForChild("HumanoidRootPart") :: Part
end

return Controller

---------------------------------------------------------------------------------------------------------
