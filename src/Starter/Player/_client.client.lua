--|| Roblox Services ||--
local _Players = game:GetService("Players")
local _RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------------------------------------------------------------------------------------------

--|| Dependencies ||--
local GameInfo = require(ReplicatedStorage.GameInfo)

local Controllers = script.Parent.Controllers :: Folder
local Comms = ReplicatedStorage:WaitForChild("_Comm")

local Bridge: RemoteEvent = Comms:WaitForChild("_Bridge")
local Gateway: RemoteFunction = Comms:WaitForChild("_Gateway")
local ClientChannel: BindableEvent = Comms:WaitForChild("_ClientChannel")
local Request: BindableFunction = Comms:WaitForChild("_Request")

local function _InvokeFunction(Module_Instance: ModuleScript, FunctionName: string, ...)
	-- This function is used to invoke a function from a specific system.
	assert(Module_Instance, "Module_Instance must be provided.")
	assert(FunctionName, "FunctionName must be provided.")

	local Module = require(Module_Instance):: any?
	if Module and Module[FunctionName] then
		return Module[FunctionName](Module, ...) or nil
	else
		warn("System or function not found:", Module_Instance.Name, FunctionName)
	end
	return nil
end

local function InvokeAllControllers(FunctionName: string, ...)
    -- This function invokes a function from all controllers from all players.
    for _, Controller: ModuleScript in Controllers:GetChildren() do
        if Controller:IsA("ModuleScript") then
            _InvokeFunction(Controller, FunctionName, ...)
        else
            warn("Skipping non-module script: ", Controller.Name)
        end
    end
end

--------------------------------------------------------------------------------------------------------------------

--|| Debugging ||--
print(GameInfo) -- Print game information for debugging

--------------------------------------------------------------------------------------------------------------------

--|| Initialize Controllers ||--
InvokeAllControllers("GameInit")

-------------------------------------------------------------------------------------------------------------

--|| Signal Handling Functions ||--
local function OnSignal(Receiver: string, SignalName: string, ...: any)
	-- This function handles signals sent from the client to the server.
	-- It can be used to trigger specific actions or events based on the signal received.
	print("Received signal by", Receiver, ":", SignalName)

	if Receiver == "Bridge" then
		-- Handle RemoteEvent signals
		if SignalName == "MapLoaded" then
            InvokeAllControllers(SignalName, ...)
        end

	elseif Receiver == "ClientChannel" then
		-- Handle BindableEvent signals
		if SignalName == "MapLoaded" then
			InvokeAllControllers("MapLoaded", ...)
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
	return OnSignal(receiver, ...)
end

-- RemoteEvent
Bridge.OnClientEvent:Connect(function(...)
	BindSignal("Bridge", ...)
end)

-- BindableEvent
ClientChannel.Event:Connect(function(...)
	BindSignal("ClientChannel", ...)
end)

-- RemoteFunction
Gateway.OnClientInvoke = function(...)
	return BindSignal("Gateway", ...)
end

-- BindableFunction
Request.OnInvoke = function(...)
	return BindSignal("Request", ...)
end

--------------------------------------------------------------------------------------------------------------------