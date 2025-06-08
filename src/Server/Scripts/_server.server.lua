--|| Roblox Services ||--
local _Players = game:GetService("Players")
local _RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--------------------------------------------------------------------------------------------------------------------

--|| Dependencies ||--
local GameInfo = require(ReplicatedStorage.GameInfo)

local Systems = ServerStorage:WaitForChild("Systems")
local Comms = ReplicatedStorage:WaitForChild("_Comm")

local Bridge: RemoteEvent = Comms:WaitForChild("_Bridge")
local Gateway: RemoteFunction = Comms:WaitForChild("_Gateway")
local ServerChannel: BindableEvent = Comms:WaitForChild("_ServerChannel")
local Request: BindableFunction = Comms:WaitForChild("_Request")

local function _InvokeFunction(Module_Instance: ModuleScript, FunctionName: string, ...)
	-- This function is used to invoke a function from a specific system.
	assert(Module_Instance, "Module_Instance must be provided.")
	assert(FunctionName, "FunctionName must be provided.")

	local Module = require(Module_Instance):: any?
	if Module and Module[FunctionName] then
		Module[FunctionName](Module, ...)
	else
		warn("System or function not found:", Module_Instance.Name, FunctionName)
	end
end

local function InvokeAllSystems(FunctionName: string, ...)
    -- This function invokes a function from all systems.
    for _, System: ModuleScript in Systems:GetChildren() do
        if System:IsA("ModuleScript") then
            _InvokeFunction(System, FunctionName, ...)
        else
            warn("Skipping non-module script: ", System.Name)
        end
    end
end

--------------------------------------------------------------------------------------------------------------------

--|| Debugging ||--
print(GameInfo) -- Print game information for debugging

--------------------------------------------------------------------------------------------------------------------

--|| Initialize Systems ||--
InvokeAllSystems("GameInit")

-------------------------------------------------------------------------------------------------------------

--|| Signal Handling Functions ||--
local function OnSignal(Receiver: string, SignalName: string, _LocalPlayer: Player?, ...: any)
	-- This function handles signals sent from the client to the server.
	-- It can be used to trigger specific actions or events based on the signal received.
	print("Received signal by", Receiver, ":", SignalName)

	if Receiver == "Bridge" then
		-- Handle RemoteEvent signals
		print(nil, nil)

	elseif Receiver == "ServerChannel" then
		-- Handle BindableEvent signals
		if SignalName == "MapLoaded" then
			InvokeAllSystems("MapLoaded", ...)
		end

	elseif Receiver == "Gateway" then
		-- Handle RemoteFunction signals
		print()

	elseif Receiver == "Request" then
		-- Handle BindableFunction signals
		print(nil)

	else
		warn("Unknown signal receiver: ", Receiver)
	end
end

-- This function binds the signal to the appropriate receiver.
local function BindSignal(receiver: string, ...: any)
	local args: {any} = {...}
	local _LocalPlayer: Player? = nil
	if typeof(args[1]) == "Player" then
		_LocalPlayer = args[1]
		table.remove(args, 1) -- Remove the player from the arguments
	end
	return OnSignal(receiver, args[1], _LocalPlayer, table.unpack(args))
end

-- RemoteEvent: Player is passed implicitly as the first argument by Roblox
Bridge.OnServerEvent:Connect(function(...)
	BindSignal("Bridge", ...)
end)

-- BindableEvent: Player must be passed explicitly by the sender
ServerChannel.Event:Connect(function(...)
	BindSignal("ServerChannel", ...)
end)

-- RemoteFunction: Player is passed implicitly as the first argument by Roblox
Gateway.OnServerInvoke = function(...)
	return BindSignal("Gateway", ...)
end

-- BindableFunction: Player must be passed explicitly by the invoker
Request.OnInvoke = function(...)
	return BindSignal("Request", ...)
end

--------------------------------------------------------------------------------------------------------------------