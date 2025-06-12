--|| Roblox Services ||--
local TweenService: TweenService = game:GetService("TweenService")

--<>--

--|| Infos ||--

-- Key: Grabber's character model. Value: Grabbed enemy's character model.
local GrabbedList: { [Model]: Model } = {} -- A table to keep track of which character is grabbing which enemy.

local FakeHitbox_Lifetime: number = 0.4 -- How long the hitbox visualization should last in seconds.
-- Default parameters for welds and hitboxes if none are provided.
local Default = {
	Weld = {
		-- The CFrame offset for the grabbing character (Part0).
		["C0"] = CFrame.new(0, 0, -2.8) * CFrame.Angles(0, math.rad(-180), 0) :: CFrame,
		-- The CFrame offset for the grabbed character (Part1).
		["C1"] = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0) :: CFrame,
	},

	Hitbox = {
		-- The size of the grab hitbox. If nil, it's calculated based on the character's size.
		["Size"] = nil :: Vector3?,
		-- The CFrame of the grab hitbox. If nil, it's calculated based on the character's position.
		["CFrame"] = nil :: CFrame?,
	},
}

--<>--

--|| Functions ||--
-- Creates a temporary visual part to represent the hitbox for debugging.
local function HitboxVisualizer(Hitbox_CFrame: CFrame, Hitbox_Size: Vector3)
	local FakeHitbox: Part = Instance.new("Part")
	FakeHitbox.Name = "FakeGrabHitbox"
	FakeHitbox.Size = Hitbox_Size
	FakeHitbox.CFrame = Hitbox_CFrame
	FakeHitbox.Color = Color3.fromRGB(250, 73, 73)
	FakeHitbox.Transparency = 0.5
	FakeHitbox.Material = Enum.Material.Neon
	FakeHitbox.Anchored = true
	FakeHitbox.CanCollide = false
	FakeHitbox.Parent = workspace

	-- Create a tween to fade out the hitbox.
	local Info_Tween: TweenInfo = TweenInfo.new(FakeHitbox_Lifetime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local Goal = {
		Transparency = 1,
	}
	local Fade_Tween: Tween = TweenService:Create(FakeHitbox, Info_Tween, Goal)
	Fade_Tween:Play()
	-- Destroy the visual part after the fade-out animation is complete.
	Fade_Tween.Completed:Once(function()
		FakeHitbox:Destroy()
	end)
end

-- Creates a Weld to connect two parts.
local function CreateWeld(Part0: Part, Part1: Part, ParentTo: Instance, WeldParams: { C0: CFrame?, C1: CFrame? }?): Weld
	local GrabWeld = Instance.new("Weld")
	GrabWeld.Name = "GrabWed"
	-- Use provided weld parameters or fall back to the default values.
	GrabWeld.C0 = WeldParams and WeldParams.C0 or Default.Weld.C0
	GrabWeld.C1 = WeldParams and WeldParams.C1 or Default.Weld.C1
	GrabWeld.Part0 = Part0
	GrabWeld.Part1 = Part1
	GrabWeld.Parent = ParentTo

	return GrabWeld
end

-- Safely destroys a weld.
local function RemoveWeld(WeldToRemove: Weld): boolean
	local Success: boolean, Err: string = pcall(
		function() -- Use a protected call to prevent errors if the weld is already destroyed.
			WeldToRemove.Part0 = nil
			WeldToRemove.Part1 = nil
			WeldToRemove:Destroy()
		end
	)
	if not Success then
		warn(`Error removing weld: {Err}`) -- If removal fails, report the error.
	end
	return Success
end

-- Finds an enemy character within a specified box-shaped area (hitbox).
local function GetEnemy(User_Character: Model, Hitbox_CFrame: CFrame, Hitbox_Size: Vector3): Model
	local Blacklists: OverlapParams = OverlapParams.new()
	Blacklists.FilterType = Enum.RaycastFilterType.Exclude
	Blacklists.FilterDescendantsInstances = { User_Character } -- Ensure the grabber doesn't grab themselves.

	local Enemy: Model
	local Hits: { BasePart } = workspace:GetPartBoundsInBox(Hitbox_CFrame, Hitbox_Size, Blacklists)

	-- Loop through all parts detected in the hitbox.
	for _, Hit: BasePart in ipairs(Hits) do
		-- Check if Hit is a basepart and if it has a parent and if that parent is a model and if it also has a rootpart.
		if Hit:IsA("BasePart") and Hit.Parent and Hit.Parent:IsA("Model") and Hit.Parent:FindFirstChild("Humanoid") then -- Check if the hit part belongs to a character (has a Humanoid).
			Enemy = Hit.Parent
			break -- Found an enemy, no need to check further.
		end
	end

	return Enemy
end

-- Checks if a character is alive based on its Humanoid's health.
local function IsAlive(Character: Model)
	assert(Character, "Character is not provided.")
	assert(Character:IsA("Model"), "Character is not a Model.")

	local Humanoid = Character:FindFirstChild("Humanoid") :: Humanoid
	assert(Humanoid, "Humanoid was not found.")
	return Humanoid.Health > 0
end

--<>--

--|| Module ||--
local System = {
	Name = "GrabSystem",
	MadeBy = "Davidrifat",
}

-- Main function to perform the grab action.
function System:Grab(
	User_Character: Model,
	Grab_Duration: number,
	HitboxParams: { ["Size"]: Vector3?, ["CFrame"]: CFrame? }?,
	WeldParams: { ["C0"]: CFrame?, ["C1"]: CFrame? }?,
	ShowHitbox: boolean?
): (boolean, Model?)
	local Grabbed: boolean
	local UserRootPart = User_Character:FindFirstChild("HumanoidRootPart") :: Part
	assert(UserRootPart, `HumanoidRootPart not found in {User_Character.Name}.`)

	-- Determine the hitbox size. Use provided params, default, or the character's bounding box size.
	local Hitbox_Size = HitboxParams and HitboxParams["Size"] or Default.Hitbox.Size or User_Character:GetExtentsSize()
	-- Determine the hitbox CFrame. Use provided params, default, or calculate a position in front of the character.
	local Hitbox_CFrame = HitboxParams and HitboxParams["CFrame"]
		or Default.Hitbox.CFrame
		or UserRootPart.CFrame * CFrame.new(0, 0, ((Hitbox_Size.Z / 2) + 0.5) * -1)

	-- If requested, show a visual representation of the hitbox.
	if ShowHitbox then
		HitboxVisualizer(Hitbox_CFrame, Hitbox_Size)
	end
	-- Attempt to find an enemy within the hitbox.
	local Enemy_Character = GetEnemy(User_Character, Hitbox_CFrame, Hitbox_Size) :: Model?

	if Enemy_Character then
		-- Check if both the user and the enemy are alive before grabbing.
		if not IsAlive(Enemy_Character) or not IsAlive(User_Character) then
			Grabbed = false
		else
			local Enemy_RootPart = Enemy_Character:FindFirstChild("HumanoidRootPart") :: Part
			assert(Enemy_RootPart, `HumanoidRootPart not found in {Enemy_Character.Name}.`)

			local GrabWeld: Weld = CreateWeld(UserRootPart, Enemy_RootPart, Enemy_RootPart, WeldParams) -- Weld the enemy to the user.
			GrabbedList[User_Character] = Enemy_Character -- Register the grab in the GrabbedList.
			Grabbed = true

			task.delay(Grab_Duration or 1, function()
				if not GrabWeld then
					return
				end

				RemoveWeld(GrabWeld)
				GrabbedList[User_Character] = nil -- Remove the entry from the grab list.
			end)

			--print("Enemy found: " .. Enemy_Character.Name)
		end
	else
		-- No enemy was found in the hitbox.
		Grabbed = false
	end

	-- Return whether the grab was successful and the enemy that was grabbed.
	return Grabbed, Enemy_Character
end

-- Returns the enemy that the specified character is currently grabbing.
function System:GetGrabbedEnemy(User_Character: Model)
	return GrabbedList[User_Character]
end

-- Returns the weld instance for a grab initiated by the specified character.
function System:GetEnemy_GrabWeld(User_Character: Model)
	local Enemy: Model? = self:GetGrabbedEnemy(User_Character)
	assert(Enemy, `No enemy was grabbed by {User_Character.Name}`)

	return Enemy:FindFirstChild("GrabWeld", true) -- Find the weld, which is parented to the enemy.
end

return System

--<>--
