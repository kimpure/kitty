--[[
	The file that contains the function for handling and creating namespaces.
	Namespaces aren't really anything special, they are just an encapsulation to make it easier to manage packets and structs.

	Dependency management is fun!
]]

local RunService = game:GetService("RunService")

local values = require(script.Parent.Parent.replicated.values)
local types = require(script.Parent.Parent.types)
local namespacesDependencies = require(script.Parent.namespacesDependencies)
local packetIDs = require(script.Parent.packetIDs)

local runContext: "server" | "client" = if RunService:IsServer() then "server" else "client"

local count = 0

return function(
	name: string,
	input: () -> {
		[string]: any,
	}
)
	local namespaceReplicator = values.access(name)

	namespacesDependencies.start(name)
	type packets = {
		[string]: ((id: number) -> any) | packets
	}
	local packets: packets = input()
	local structs = namespacesDependencies.empty()

	local result = {}

	if runContext == "server" then
		local constructedNamespace = {
			structs = {},
			packets = {},
		}

		local function registerRecursive(tbl: packets, currentResult: {}, namespacePackets: {})
			for key, value in tbl do
				if type(value) == "function" then
					count += 1
					namespacePackets[key] = count
					currentResult[key] = value(count)

					packetIDs.set(count, currentResult[key])
				elseif type(value) == "table" then
					currentResult[key] = {}
					namespacePackets[key] = {}
					registerRecursive(value, currentResult[key], namespacePackets[key])
				end
			end
		end

		registerRecursive(packets, result, constructedNamespace.packets)

		for index, value in structs do
			constructedNamespace.structs[index] = value
		end

		namespaceReplicator:write(constructedNamespace)
	elseif runContext == "client" then
		-- yes, this means that packets technically don't need to be defined on the client
		-- we do it anyway for typechecking and perf shortcuts
		local namespaceData = namespaceReplicator:read() :: types.namespaceData

		local function registerRecursive(tbl: packets, currentResult: {}, namespacePackets: {})
			for key, value in tbl do
				if type(value) == "function" then
					currentResult[key] = value(namespacePackets[key])

					packetIDs.set(namespacePackets[key], currentResult[key])
				elseif type(value) == "table" then
					currentResult[key] = {}
					registerRecursive(value, currentResult[key], namespacePackets[key])
				end
			end
		end

		registerRecursive(packets, result, namespaceData.packets)
	end

	return result
end
