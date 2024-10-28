--!strict
--$kit
local RunService = game:GetService('RunService')

local HandyNet = require(script.Parent.pesdePackages.handynet)
local DataStoreLight = require(script.Parent:WaitForChild('datastore-light'))

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
	packet: typeof(HandyNet.defineNamespace('onChanged', function() 
		return {
			onChange = (0 :: any) :: typeof(HandyNet.definePacket(table.unpack({} :: any)))
		}
	end));
	values: T;
	rawValues: T;
	discardValues: T;
}
local config = {} :: ConfigImpl
config.__index = config

function config.SaveChanges(self)
	
end

function config.GetChanges(self, call)
	local function getPacketTable(typeTable: { [string]: any })
		local result = {} :: { [string]: any }
		for k, v in self.values :: { [string]: any } do
			local valueType = typeof(v)
			if valueType == 'number' then
				local absNumber = math.abs(v :: number) 
				local i = v == absNumber
				if absNumber <= 127 then
					result[k] = if i then HandyNet.u8 else HandyNet.i8
				elseif absNumber <= 32767 then
					result[k] = if i then HandyNet.u16 else HandyNet.i16
				elseif absNumber <= 2147483647 then
					result[k] = if i then HandyNet.u32 else HandyNet.i32
				else
					error('number max is 2147483647')
				end
			elseif valueType == 'string' then
				result[k] = HandyNet.string(string.len(v :: string))
			elseif valueType == 'boolean' then
				result[k] = HandyNet.boolean
			elseif valueType == 'table' then
				getPacketTable(v :: { [string]: any })
			else
				error('config type is only string, boolean, number, table')
			end
		end
		return result
	end	
	self.packet = HandyNet.defineNamespace('onChanged', function() 
		return {
			onChange = HandyNet.definePacket(
				"client->server",
				HandyNet.struct { 
					configs = getPacketTable(self.values),
				}
			)
		}
	end)
	self.packet.onChange.event:connect(function(values: { [string]:any }, player)
		call(values, player)
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
	self.packet.onChange.send(self.values)
end

local userConfig = {} :: UserConfigImpl
userConfig.__index = userConfig

function userConfig.new(configs)
	local cloenConfig = setmetatable({} :: any, config)
	
	cloenConfig.values = configs
	cloenConfig.rawValues = configs
	cloenConfig.discardValues = configs
	return cloenConfig :: ConfigImpl<typeof(configs)>
end

return userConfig