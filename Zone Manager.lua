--[[
	ZoneManager.lua
	Converts a world Position into a named zone (e.g. "Storage Room B"),
	so the adaptive learning system in AnimatronicAI can say "players keep
	hiding in Storage Room B" instead of just raw coordinates.

	Setup expected in Studio:
	- A folder in workspace named "Zones", containing Part regions
	  (invisible blocks) for every named area of the map. Each part's
	  Name is used as the zone name, e.g. workspace.Zones["Storage Room B"].

	Usage:
		local ZoneManager = require(ReplicatedStorage.Modules.ZoneManager)
		local zoneName = ZoneManager.GetZoneAt(somePosition)
]]

local ZoneManager = {}

local zoneParts = {} -- array of { name = string, part = BasePart }
local initialized = false

local function initialize()
	if initialized then return end
	initialized = true

	local zonesFolder = workspace:FindFirstChild("Zones")
	if not zonesFolder then
		warn("[ZoneManager] No 'Zones' folder found in workspace. " ..
			"Zone lookups will return nil until you add one.")
		return
	end

	for _, part in ipairs(zonesFolder:GetChildren()) do
		if part:IsA("BasePart") then
			table.insert(zoneParts, { name = part.Name, part = part })
		end
	end
end

-- Returns the zone name containing `position`, or nil if it's not inside
-- any defined zone. Uses simple AABB (bounding box) containment, which is
-- fine for room-shaped zone volumes.

function ZoneManager.GetZoneAt(position)
	initialize()

	for _, zone in ipairs(zoneParts) do
		local part = zone.part
		local relative = part.CFrame:PointToObjectSpace(position)
		local size = part.Size

		if math.abs(relative.X) <= size.X / 2
			and math.abs(relative.Y) <= size.Y / 2
			and math.abs(relative.Z) <= size.Z / 2 then
			return zone.name
		end
	end

	return nil
end

-- Call once at server start if you add/remove zones at runtime; otherwise
-- initialization happens automatically on first GetZoneAt call.

function ZoneManager.Refresh()
	zoneParts = {}
	initialized = false
	initialize()
end

return ZoneManager
