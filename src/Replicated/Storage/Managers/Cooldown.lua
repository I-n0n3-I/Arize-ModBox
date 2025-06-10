--|| Roblox Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--<>--

--|| Dependencies ||--
local Trove = require(ReplicatedStorage.Packages.Trove)
local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)

-- Maps string states to boolean values
local StateToBool: { [string]: boolean } = {
	on = true,
	off = false,
}

--<>--

--|| Defining Types ||--
export type object_Cooldown_t = {
	Name: string,
	Duration: number,

	Started: GoodSignal.Signal<any>,
	Ended: GoodSignal.Signal<any>,

	IsActive: (self: object_Cooldown_t) -> boolean,
	Toggle: (self: object_Cooldown_t, Value: boolean | string) -> (),
}

export type CooldownListofPlayer_t = {
	[string]: object_Cooldown_t,
}

--<>--

--|| Functions ||--

-- Starts the cooldown and fires the Started signal
local function Start(Cooldown: object_Cooldown_t)
	(Cooldown :: any):_SetActive(true)
	Cooldown.Started:Fire()
	task.delay(Cooldown.Duration, function()
		if Cooldown:IsActive() == false then
			return
		end
		(Cooldown :: any):_SetActive(false)
		Cooldown.Ended:Fire()
	end)
end

-- Stops the cooldown and fires the Ended signal
local function Stop(Cooldown: object_Cooldown_t)
	(Cooldown :: any):_SetActive(false)
	Cooldown.Ended:Fire()
end

--<>--

--|| Module ||--

local Manager = {
	_Name = "CooldownManager",
	_MadeBy = "Davidrifat",
}
Manager.__index = Manager

local class_Cooldown = {}
class_Cooldown.__index = class_Cooldown

local Cooldowns: { [number]: CooldownListofPlayer_t } = {}

-- Creates a new cooldown object for a player
function class_Cooldown.new(Player: Player, cooldownName: string, cooldownDuration: number): object_Cooldown_t
	local self = setmetatable({}, class_Cooldown)

	self.Name = cooldownName
	self.Duration = cooldownDuration
	self._IsActive = false
	self._Signals = Trove.new() :: Trove.Trove
	self.Started = self._Signals:Add(GoodSignal.new(), "DisconnectAll")
	self.Ended = self._Signals:Add(GoodSignal.new(), "DisconnectAll")

	if not Cooldowns[Player.UserId] then
		self:Init(Player)
	end
	Cooldowns[Player.UserId][cooldownName] = self
	return self
end

-- Returns whether the cooldown is active
function class_Cooldown:IsActive(): boolean
	return self._IsActive
end

-- Sets the active state of the cooldown
function class_Cooldown:_SetActive(Value: boolean)
	assert(Value ~= nil, "No value was given.")

	self._IsActive = Value
end

-- Toggles the cooldown on or off
function class_Cooldown:Toggle(Value: boolean | string)
	assert(Value, "Value must be given.")
	assert(
		typeof(Value) == "boolean" or typeof(Value) == "string",
		`Invalid value type: Expected string or boolean. Received: {typeof(Value)}`
	)

	if typeof(Value) == "string" then
		Value = StateToBool[string.lower(Value)]
		assert(typeof(Value) == "boolean", "Invalid string value for Toggle; must be case-insensitive 'on' or 'off'.")
	end

	if Value == self._IsActive then
		warn(`Cooldown was already {Value}`)
		return
	end

	if Value == true then
		Start(self)
	else
		if self._IsActive == true then
			Stop(self)
		end
	end
end

-- Initializes the cooldown table for a player
function Manager:Init(Player: Player)
	assert(Player, "No player was given.")
	assert(not Cooldowns[Player.UserId], "Player cooldowns already initialized.")

	Cooldowns[Player.UserId] = {}
	warn(`Player {Player.Name} cooldowns inittiated.`)
end

-- Creates a new cooldown for a player
function Manager.newCooldown(Player: Player, cooldownName: string, cooldownDuration: number): object_Cooldown_t
	assert(Player, "No player was given.")
	assert(cooldownName, "cooldownName must be given.")
	assert(cooldownDuration, "cooldownDuration must be given.")

	return class_Cooldown.new(Player, cooldownName, cooldownDuration)
end

-- Checks if a cooldown exists for a player
function Manager:DoesCooldownExist(Player: Player, cooldownName: string): boolean
	assert(Player, "No player was given.")
	assert(Cooldowns[Player.UserId], "Player cooldowns not found.")
	assert(cooldownName, "cooldownName must be given.")
	assert(typeof(cooldownName) == "string", "cooldownName must be a string.")

	return Cooldowns[Player.UserId][cooldownName] ~= nil
end

-- Gets a specific cooldown for a player
function Manager:Get(Player: Player, cooldownName: string): object_Cooldown_t
	assert(Player, "No player was given.")
	assert(cooldownName, "cooldownName must be given.")
	assert(typeof(cooldownName) == "string", "cooldownName must be a string.")
	assert(Cooldowns[Player.UserId], "Player cooldowns not found.")
	assert(Cooldowns[Player.UserId][cooldownName], `{cooldownName} does not exist.`)

	return Cooldowns[Player.UserId][cooldownName]
end

-- Gets all cooldowns for a player
function Manager:GetAll(Player: Player): CooldownListofPlayer_t
	assert(Player, "No player was given.")
	assert(Cooldowns[Player.UserId], "Player cooldowns not found.")
	return Cooldowns[Player.UserId]
end

-- Gets the list of all player cooldowns (internal)
function Manager:_GetListOfAllPlayerCooldowns(): { [number]: CooldownListofPlayer_t }
	return Cooldowns
end

-- Removes a specific cooldown for a player and cleans up signals
function Manager:Remove(Player: Player, cooldownName: string)
	assert(Player, "No player was given.")
	assert(cooldownName, "cooldownName must be given.")
	assert(typeof(cooldownName) == "string", "cooldownName must be a string.")
	assert(Cooldowns[Player.UserId], "Player cooldowns not found.")
	assert(Cooldowns[Player.UserId][cooldownName], `{cooldownName} does not exist.`)

	local CD = Cooldowns[Player.UserId][cooldownName]
	CD._Signals:Clean()
	Cooldowns[Player.UserId][cooldownName] = nil
end

-- Cleans up all cooldowns for a player
function Manager:Cleanup(Player: Player)
	assert(Player, "No player was given.")

	local CDs = Cooldowns[Player.UserId]
	if not CDs then
		warn("Player cooldowns already cleaned up.")
		return
	end
	for CD_Name, CD in CDs do
		self:Remove(Player, CD_Name)
	end
	Cooldowns[Player.UserId] = nil
end

return Manager

--<>--
