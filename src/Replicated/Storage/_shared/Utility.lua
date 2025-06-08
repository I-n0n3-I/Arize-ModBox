--|| Defining types ||--

---------------------------------------------------------------------------------------------------------

--|| Roblox Services ||--
local _RunService = game:GetService("RunService")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------------------------------------------------------

--|| Dependencies & Functions ||--

---------------------------------------------------------------------------------------------------------

--|| Utility ||--
local Utility = {
    -- Module Name
    Name = "Utility";

    -- Module description
    Description = "Provides utility functions for the game.";
}
Utility.__index = Utility

function Utility:GetRandom_Instance(Instances: {Instance})
    assert(#Instances > 0, "Instances table cannot be empty.")
    assert(type(Instances) == "table", "Instances must be a table of Instance objects.")

    return Instances[math.random(1, #Instances)]
end

function Utility:deepCloneTable(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = self:deepCloneTable(v) -- Recursively clone tables
        else
            copy[k] = v
        end
    end
    return copy
end

return Utility

---------------------------------------------------------------------------------------------------------

