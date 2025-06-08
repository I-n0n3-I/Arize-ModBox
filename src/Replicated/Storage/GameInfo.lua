--|| Defining Types ||--

---------------------------------------------------------------------------------------------------------

--|| Roblox Services ||--
local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService: RunService = game:GetService("RunService")
local _HttpService: HttpService = game:GetService("HttpService")

---------------------------------------------------------------------------------------------------------

--|| Infos ||--
-- This module contains the game information and configuration.
-- It is designed to be used on the server side only, preventing client-side modifications.
local ThisGame = {} -- The module itself.
local Info = {
	-- ||Core Game information||
	_version = game.PlaceVersion or "0.0.0",
	_name = "Unnamed",
	_id = game.GameId,
	_ownerid = game.CreatorId,
	_community = "https://www.roblox.com/community/_",
	_communityDiscord = "https://discord.gg/_",
	_communityYouTube = "https://www.youtube.com/_",
	_communityGitHub = "https://github.com/_",
}

---------------------------------------------------------------------------------------------------------

setmetatable(ThisGame, {
	__index = function(_, key)
		return rawget(Info, key) -- Redirect reads to the Config table
	end,
	__tostring = function(_)
		return string.format("Game: %s | Version %s", rawget(Info, "_name"), rawget(Info, "_version")) -- Returns the basic info of the game
	end,

	__newindex = function(_, key, value)
		if RunService:IsClient() then
			error("Attempt to modify GameInfo on the client. This is not allowed.", 2) -- Prevent modification on the client side
		end

		if rawget(Info, key) ~= nil then -- Check if the key exists in the Info table
			if type(rawget(Info, key)) ~= typeof(value) then
				error("Attempt to set a different type than " .. typeof(rawget(Info, key)), 2) -- Ensure the type matches
			end
			rawset(Info, key, value) -- Redirect writes to the Config table
		else
			error(string.format("Attempt to set a non-existent property '%s' in GameInfo", key), 2)
		end
	end,
})

return ThisGame
