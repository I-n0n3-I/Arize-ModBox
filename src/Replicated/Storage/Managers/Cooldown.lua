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

--[=[
    @type object_Cooldown_t
    Represents an individual cooldown instance.

    Fields:
    - `Name` (string): The name of the cooldown.
    - `Duration` (number): The duration before cooldown expires.
    - `Started` (GoodSignal.Signal<any>): Fires when cooldown starts.
    - `Ended` (GoodSignal.Signal<any>): Fires when cooldown ends.
    - `IsActive(self: object_Cooldown_t) -> boolean`: Returns whether the cooldown is active.
    - `Toggle(self: object_Cooldown_t, Value: boolean | string) -> ()`: Toggles the cooldown on or off.

    Usage Example:
    ```lua
    local sprintCooldown = Manager.newCooldown(player, "Sprint", 5)
    if sprintCooldown:IsActive() then
        print("Cooldown is in effect!")
    end
    ```
]=]
export type object_Cooldown_t = {
	Name: string,
	Duration: number,

	Started: GoodSignal.Signal<any>,
	Ended: GoodSignal.Signal<any>,

	IsActive: (self: object_Cooldown_t) -> boolean,
	Toggle: (self: object_Cooldown_t, Value: boolean | string) -> (),
}

--[=[
    @type CooldownListofPlayer_t
    Stores cooldowns for each player.

    Structure:
    - `{[string]: object_Cooldown_t}`: Maps cooldown names to cooldown instances.

    Usage Example:
    ```lua
    local cooldowns = Manager:GetAll(player)
    for name, cooldown in pairs(cooldowns) do
        print(name, cooldown:IsActive())
    end
    ```
]=]
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

--[=[
    @class CooldownManager
    Handles cooldown tracking for players.
]=]
local Manager = {
	_Name = "CooldownManager",
	_MadeBy = "Davidrifat",
}
Manager.__index = Manager

local class_Cooldown = {}
class_Cooldown.__index = class_Cooldown

local Cooldowns: { [number]: CooldownListofPlayer_t } = {}

--[=[
    @within object_Cooldown_t
    @param Player Player -- The player for whom the cooldown is being created.
    @param cooldownName string -- The name of the cooldown.
    @param cooldownDuration number -- Duration in seconds before cooldown resets.
    @return object_Cooldown_t -- A new cooldown instance.

    Creates a new cooldown object for a player.
]=]
function class_Cooldown._new(Player: Player, cooldownName: string, cooldownDuration: number): object_Cooldown_t
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

--[=[
    @within object_Cooldown_t
    @return boolean -- Returns true if the cooldown is active.
    Determines whether the cooldown is currently in effect.

    Usage Example:
    ```lua
    if cooldown:IsActive() then
        print("Cooldown is running")
    end
    ```
]=]
function class_Cooldown:IsActive(): boolean
	return self._IsActive
end

--[=[
    @within object_Cooldown_t
    @param Value boolean | string -- The value to set the cooldown state.
    @private
    Sets the active state of the cooldown.
]=]
function class_Cooldown:_SetActive(Value: boolean)
	assert(Value ~= nil, "No value was given.")

	self._IsActive = Value
end

--[=[
    @within object_Cooldown_t
    @param Value boolean | string -- The value to toggle the cooldown.
    Toggles the cooldown on or off based on a boolean or string input.
    Valid string values: `"on"` or `"off"` (case insensitive).

    Usage Example:
    ```lua
    cooldown:Toggle("on") -- Starts the cooldown
    cooldown:Toggle(false) -- Stops the cooldown
    ```
]=]
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

--[=[
    @within CooldownManager
    @param Player Player -- The player whose cooldowns are being initialized.
    Initializes the cooldown system for a player.

    Usage Example:
    ```lua
    Manager:Init(player)
    ```
]=]
function Manager:Init(Player: Player)
	assert(Player, "No player was given.")
	assert(not Cooldowns[Player.UserId], "Player cooldowns already initialized.")

	Cooldowns[Player.UserId] = {}
	warn(`Player {Player.Name} cooldowns inittiated.`)
end

--[=[
    @within CooldownManager
    @param Player Player -- The player for whom the cooldown is being created.
    @param cooldownName string -- The name of the cooldown.
    @param cooldownDuration number -- Duration in seconds before cooldown resets.
    @return object_Cooldown_t -- A new cooldown instance.

    Creates a new cooldown for a player.

    Usage Example:
    ```lua
    local sprintCooldown = Manager.newCooldown(player, "Sprint", 5)
    ```
]=]
function Manager.newCooldown(Player: Player, cooldownName: string, cooldownDuration: number): object_Cooldown_t
	assert(Player, "No player was given.")
	assert(cooldownName, "cooldownName must be given.")
	assert(cooldownDuration, "cooldownDuration must be given.")

	return class_Cooldown._new(Player, cooldownName, cooldownDuration)
end

--[=[
    @within CooldownManager
    @param Player Player -- The player whose cooldown is being checked.
    @param cooldownName string -- The name of the cooldown.
    @return boolean -- Whether the cooldown exists.

    Checks if a cooldown exists for a player.

    Usage Example:
    ```lua
    if Manager:DoesCooldownExist(player, "Sprint") then
        print("Cooldown is active")
    end
    ```
]=]
function Manager:DoesCooldownExist(Player: Player, cooldownName: string): boolean
	assert(Player, "No player was given.")
	assert(Cooldowns[Player.UserId], "Player cooldowns not found.")
	assert(cooldownName, "cooldownName must be given.")
	assert(typeof(cooldownName) == "string", "cooldownName must be a string.")

	return Cooldowns[Player.UserId][cooldownName] ~= nil
end

--[=[
    @within CooldownManager
    @param Player Player -- The player whose cooldown is being retrieved.
    @param cooldownName string -- The name of the cooldown.
    @return object_Cooldown_t -- The cooldown object.

    Retrieves a specific cooldown for a player.

    Usage Example:
    ```lua
    local sprintCooldown = Manager:Get(player, "Sprint")
    ```
]=]
function Manager:Get(Player: Player, cooldownName: string): object_Cooldown_t
	assert(Player, "No player was given.")
	assert(cooldownName, "cooldownName must be given.")
	assert(typeof(cooldownName) == "string", "cooldownName must be a string.")
	assert(Cooldowns[Player.UserId], "Player cooldowns not found.")
	assert(Cooldowns[Player.UserId][cooldownName], `{cooldownName} does not exist.`)

	return Cooldowns[Player.UserId][cooldownName]
end

--[=[
    @within CooldownManager
    @param Player Player -- The player whose cooldowns are being retrieved.
    @return CooldownListofPlayer_t -- A list of all cooldowns for the player.

    Gets all cooldowns associated with a player.

    Usage Example:
    ```lua
    local allCooldowns = Manager:GetAll(player)
    ```
]=]
function Manager:GetAll(Player: Player): CooldownListofPlayer_t
	assert(Player, "No player was given.")
	assert(Cooldowns[Player.UserId], "Player cooldowns not found.")
	return Cooldowns[Player.UserId]
end

--[=[
    @within CooldownManager
    @private
    Gets the list of all player cooldowns (internal).
]=]
function Manager:_GetListOfAllPlayerCooldowns(): { [number]: CooldownListofPlayer_t }
	return Cooldowns
end

--[=[
    @within CooldownManager
    @param Player Player -- The player whose cooldown is being removed.
    @param cooldownName string -- The name of the cooldown.
    Removes a specific cooldown instance and cleans up associated signals.

    Usage Example:
    ```lua
    Manager:Remove(player, "Sprint")
    ```
]=]
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

--[=[
    @within CooldownManager
    @param Player Player -- The player whose cooldowns are being cleaned up.
    Removes all cooldowns assigned to a player and releases any associated resources.

    Usage Example:
    ```lua
    Manager:Cleanup(player)
    ```
]=]
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
