--!strict
--$kit
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local HandyNet = require(script.Parent.pesdePackages.handynet)
local DataStoreLight = require(script.Parent:WaitForChild('datastore-light'))

local changePacket = HandyNet.defineNamespace('userconfig-client-change', function() 
	return {
		onChange = HandyNet.definePacket(
			"client->server",
			HandyNet.struct { 
				values = HandyNet.unknown,
				rawValues = HandyNet.unknown,
				discardValues = HandyNet.unknown,
			}
		)
	}
end)

local serverChangePacket = HandyNet.defineNamespace('userconfig-server-change', function() 
	return {
		response = HandyNet.definePacket(
			"server->client",
			HandyNet.struct { }
		)
	}
end)

local clientGetDataStore = HandyNet.defineNamespace('userconfig-clientGetDataStore', function() 
	return {
		get = HandyNet.definePacket(
			"client->server",
			HandyNet.struct { 
				id = HandyNet.unknown,
			}
		)
	}
end)

local serverGetDataStore = HandyNet.defineNamespace('userconfig-serverGetDataStore', function() 
	return {
		get = HandyNet.definePacket(
			"server->client",
			HandyNet.struct { 
				data = HandyNet.unknown,
			}
		)
	}
end)

type UserConfigImpl<T={[string]: any}> = {
    __index: UserConfigImpl<T>,
	new: <T>(T & { [string]: any }, configName: string) -> ConfigImpl<T>,
}

type ConfigImpl<T={[string]:any}> = {
	__index: ConfigImpl<T>;
	saveChanges: (self: ConfigImpl<T>, player: Player)->();
	getChanges: (self: ConfigImpl<T>, call: (self: T,player: Player)->())->();
	discardChanges: (self: ConfigImpl<T>)->();
	reset: (self: ConfigImpl<T>)->();
	rawSet: (self: ConfigImpl<T>, value: { [string]:any })->();
	rawGet: (self: ConfigImpl<T>)->(T);
    saveChangesToServer: (self:ConfigImpl<T>)->();
	values: T;
	rawValues: T;
	discardValues: T;
	configName: string;
	datastore: typeof(DataStoreLight.new(0 :: any));
}

local config = {} :: ConfigImpl
config.__index = config

function config.saveChanges(self, player)
	if not self.values then 
		return
	end
	
	self.datastore:save()
end

function config.getChanges(self, call)
	changePacket.onChange.event:connect(function(values: { [string]:any }, player: Player)
		local result = {
			values = values.values,
			rawValues = values.rawValues,
			discardValues = values.discardValues,
		}
		self.values = values.values
		self.rawValues = values.rawValues
		self.discardValues = values.discardValues
		self.datastore:set(self.configName, result)
		serverChangePacket.response.send{}
		call(values.values, player)
	end)
end

function config.discardChanges(self)
	self.values = self.discardValues
end

function config.reset(self)
	self.values = self.rawValues
end

function config.rawSet(self, value)
	for k, v in value do
		if self.rawValues[k] then
			self.rawValues[k] = v
		end
	end
end

function config.rawGet(self)
	return self.rawValues
end

function config.saveChangesToServer(self)
	local onEvent = false
	local function sendToServer()
		changePacket.onChange.send(self)
		task.spawn(function() 
			task.wait(1)
			if not onEvent then
				sendToServer()
			end
		end)
	end
	sendToServer()
	serverChangePacket.response.event:connect(function()
		onEvent = true
	end)
end

local userConfig = {} :: UserConfigImpl
userConfig.__index = userConfig

function userConfig.new(configs, configName)
	local cloenConfig = setmetatable({} :: any, config)
	cloenConfig.configName = configName
	if RunService:IsClient() then
		local onEvent = false
		local function sendToServer()
			clientGetDataStore.get.send({ id = Players.LocalPlayer.UserId })
			task.spawn(function() 
				task.wait(1)
				if not onEvent then
					sendToServer()
				end
			end)
		end
		sendToServer()
		serverGetDataStore.get.event:connect(function(values:{ data: unknown })
			onEvent = true
			cloenConfig.values = (values.data :: any).values :: any
			cloenConfig.rawValues = (values.data :: any).rawValues :: any
			cloenConfig.discardValues = (values.data :: any).discardValues :: any
			cloenConfig.datastore = DataStoreLight.new(Players.LocalPlayer.UserId)
		end)
	else
		clientGetDataStore.get.event:connect(function(values: { id: unknown })
			local newDataStore = DataStoreLight.new(values.id :: number)
			local getData = newDataStore:get(configName)
			local newData = if getData == {} or not getData then { 
				values = configs,
				rawValues = configs,
				discardValues = configs,
			} else getData
			cloenConfig.values = newData.values
			cloenConfig.rawValues = newData.rawValues
			cloenConfig.discardValues = newData.discardValues
			serverGetDataStore.get.send({ data = cloenConfig }, Players:GetPlayerByUserId(values.id))
			cloenConfig.datastore = newDataStore
		end)
	end

	while task.wait(.5) do
		if cloenConfig.values then
			break
		end
	end

	return cloenConfig :: ConfigImpl<typeof(configs)>
end

return userConfig