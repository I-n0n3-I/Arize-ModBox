--|| Roblox Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService: TweenService = game:GetService("TweenService")

--<>--

--|| Dependencies ||--
local _Packages = ReplicatedStorage.Packages
local Trove = require(_Packages.Trove)
local GoodSignal = require(_Packages.GoodSignal)

--<>--

--|| Defining Types ||--
export type object_Grabbed_t = {}
export type GrabbedObjectListofPlayer_t = {
	[string]: object_Grabbed_t,
}

--<>--

--|| Functions ||--

--<>--

--|| Module ||--
local System = {
	_Name = "GrabSystem",
	_MadeBy = "Davidrifat", -- Roblox Username
	_Version = "1.1.0",
}
System.__index = System

local class_Grabbed = {}
class_Grabbed.__index = class_Grabbed

local Grabbed_Object_Lists: GrabbedObjectListofPlayer_t = {}

function class_Grabbed._new(User: Player, Target: Instance)
	local self = setmetatable({}, class_Grabbed)
	self.Grabber = User.UserId
	self.Target = Target

	return self
end

function System:GrabTarget(User: Player, Target: Instance) end

function System:FindandGrab() end

function System:FindandGrabUntilFound() end

--<>--
