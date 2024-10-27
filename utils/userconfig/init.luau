--!strict
--$kit
local RunService = game:GetService('RunService')

local HandyNet = require(script.Parent.pesdePackages.handynet)
local DataStoreLight = require(script.Parent:WaitForChild('datastore-light'))

local changePacket = HandyNet.defineNamespace('onChanged', function() 
	return {
		onChange = HandyNet.definePacket(
			"client->server",
			HandyNet.struct { 
				configs = HandyNet.array,
			}
		)
	}
end)

type UserConfigImpl<T={[string]: any}> = {
    __index: UserConfigImpl<T>,
	new: <T>(T & { [string]: any }) -> ConfigImpl<T>,
}

type ConfigImpl<T={[string]:any}> = {
	__index:ConfigImpl<T>;
	SaveChanges:(self:ConfigImpl<T>)->();
	GetChanges:(self:ConfigImpl<T>, call: (self:T,player:Player)->())->();
	DiscardChanges:(self:ConfigImpl<T>)->();
	Reset:(self:ConfigImpl<T>)->();
	RawSet:(self:ConfigImpl<T>, value:{[string]:any})->();
	RawGet:(self:ConfigImpl<T>)->(T);
    saveChangesToServer:(self:ConfigImpl<T>)->();
	values: T;
	rawValues: T;
	discardValues: T;
}
local config = {} :: ConfigImpl
config.__index = config

function config.SaveChanges(self)
	
end

function config.GetChanges(self, call)
	changePacket.onChange.event:connect(function(values: { [string]:any }, player: Player)
		call(self, player)
	end)
end

function config.DiscardChanges(self)
	self.values = self.discardValues
end

function config.Reset(self)
	self.values = self.rawValues
end

function config.RawSet(self, value)
	for k, v in value do
		if self.rawValues[k] then
			self.rawValues[k] = v
		end
	end
end

function config.RawGet(self)
	return self.rawValues
end

function config.saveChangesToServer(self)
	print(self.values)
	changePacket.onChange.send(self.values)
end

local userConfig = {} :: UserConfigImpl
userConfig.__index = userConfig

function userConfig.new(configs)
	local cloenConfig = setmetatable(configs :: any, config)
	cloenConfig.values = configs
	cloenConfig.rawValues = configs
	cloenConfig.discardValues = configs
	return cloenConfig :: ConfigImpl<typeof(configs)>
end

return userConfig