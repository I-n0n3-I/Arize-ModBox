--|| Roblox Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService: TweenService = game:GetService("TweenService")
local PlayerService: Players = game:GetService("Players")

--<>--

--|| Dependencies ||--
local _Packages = ReplicatedStorage.Packages
local Trove = require(_Packages.Trove)
local GoodSignal = require(_Packages.GoodSignal)

local Default = {
	Priorities = {
		player_model = 999,
		tool = 3,
		model = 2,
		basepart = 1,
	},

	Joint = {
		Position = {
			atfront = function(User_Model: Model, self: Part)
				return CFrame.new(0, 0, 0)
			end,
			behinduser = function(User_Model: Model, self: Part)
				return CFrame.new(0, 0, 0)
			end,
			atleft = function(User_Model: Model, self: Part)
				return CFrame.new(0, 0, 0)
			end,
			atright = function(User_Model: Model, self: Part)
				return CFrame.new(0, 0, 0)
			end,
			attop = function(User_Model: Model, self: Part)
				return CFrame.new(0, 0, 0)
			end,
			atbottom = function(User_Model: Model, self: Part)
				return CFrame.new(0, 0, 0)
			end,
		},

		Orientation = {
			facinguser = function(User_Model: Model, self: Part)
				return CFrame.new(0, 0, 0)
			end,
			upright = CFrame.Angles(0, 0, 0),
			flatfacingup = CFrame.Angles(math.rad(-90), 0, 0),
			flatfacingdown = CFrame.Angles(math.rad(90), 0, 0),
			sidewaysleft = CFrame.Angles(0, 0, math.rad(-90)),
			sidewaysright = CFrame.Angles(0, 0, math.rad(90)),
			upsidedown = CFrame.Angles(math.rad(180), 0, 0),
		},
	},
}

--<>--

--|| Defining Types ||--
export type object_Grabbed_t = {}
export type GrabbedObjectListofPlayer_t = {
	[string]: object_Grabbed_t,
}
type Joint_InitialCFrame_t = {
	Position: CFrame,
	Orientation: {
		rx: number,
		ry: number,
		rz_local: number,
		rz_arounduser: number,
	},
}

--<>--

--|| Functions ||--
local function _IsModel(part: BasePart): boolean
	if part.Parent == nil then
		return false
	end
	if not part:FindFirstAncestorWhichIsA("Model") then
		return false
	end

	return true
end

local function _IsPlayer(part: BasePart): boolean
	local parent: Instance? = part.Parent
	if not _IsModel(part) then
		return false
	end

	local humanoid: Humanoid? = (parent :: Model):FindFirstChildOfClass("Humanoid")
	local rootPart: Instance? = (parent :: Model):FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		return false
	end

	local player: Player? = PlayerService:GetPlayerFromCharacter(parent :: Model)
	return player ~= nil
end

local function _IsTool(part: BasePart): boolean
	if part.Parent == nil then
		return false
	end
	if not part:FindFirstAncestorWhichIsA("Tool") then
		return false
	end

	return false
end

local function _GetTarget(User_Character: Model, Hitbox_Params: { ["CFrame"]: CFrame, ["Size"]: Vector3 }): Instance
	local OParams: OverlapParams = OverlapParams.new()
	OParams.FilterType = Enum.RaycastFilterType.Exclude
	OParams.CollisionGroup = "grabable"
	OParams.FilterDescendantsInstances = { User_Character }

	local HighestPriority = -math.huge
	local SelectedTarget: Instance?

	local Objects: { BasePart } = workspace:GetPartBoundsInBox(Hitbox_Params.CFrame, Hitbox_Params.Size, OParams)

	for _, Hit: BasePart in ipairs(Objects) do
		if not Hit:IsA("BasePart") then
			continue
		end

		local currentTarget: Instance
		local priority = 0

		if _IsPlayer(Hit) then
			currentTarget = Hit.Parent :: Instance
			priority = Default.Priorities.player_model or 0
		elseif _IsTool(Hit) then
			currentTarget = Hit:FindFirstAncestorWhichIsA("Tool") or Hit
			priority = Default.Priorities.tool or 0
		elseif _IsModel(Hit) then
			currentTarget = Hit:FindFirstAncestorWhichIsA("Model") or Hit
			priority = Default.Priorities.model or 0
		else
			currentTarget = Hit
			priority = Default.Priorities.basepart or 0
		end

		if priority > HighestPriority then
			HighestPriority = priority
			SelectedTarget = currentTarget
		end
	end

	return SelectedTarget :: Instance
end

local function _CreateJoint(
	User_Model: Model,
	Target: Part,
	JointType: string,
	InitialPose: Joint_InitialCFrame_t | string,
	Offset: CFrame
)
	local Joint: Weld | Motor6D
	if string.lower(JointType) == "weld" then
		Joint = Instance.new("Weld")
	else
		Joint = Instance.new("Motor6D")
	end

	--Joint.Part0 = User_Model.PrimaryPart
end

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

	Grabbed_Object_Lists[Target.Name] = self
	return self
end

function System:GrabTarget(User: Player, Target: Instance) end

function System:FindandGrab() end

function System:FindandGrabUntilFound() end

--<>--
