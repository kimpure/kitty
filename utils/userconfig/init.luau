--!strict
--$kit
local RunService = game:GetService('RunService')

-- local HandyNet = require(script.Parent:WaitForChild('pesdePackages'):WaitForChild('handynet'))
-- local DataStoreLight = require(script.Parent:WaitForChild('datastore-light'))

type UserConfigImpl<T={[string]: any}> = {
    __index: UserConfigImpl<T>,
	new: <T>(T & { [string]: any }) -> ConfigImpl<T>,
}

type ConfigImpl<T={[string]:any}> = {
	__index:ConfigImpl<T>;
	SaveChanges:(self:ConfigImpl<T>)->();
	GetChanges:(self:ConfigImpl<T>, call: (self:T)->())->();
	DiscardChanges:(self:ConfigImpl<T>)->();
	Reset:(self:ConfigImpl<T>)->();
	RawSet:(self:ConfigImpl<T>, value:{[string]:any})->();
	RawGet:(self:ConfigImpl<T>)->(T);
    saveChangesToServer:(self:ConfigImpl<T>)->();
	values: T;
	rawValues: T;
}
local config = {} :: ConfigImpl
config.__index = config

function config.SaveChanges(self)
	
end

function config.GetChanges(self)
	
end

function config.DiscardChanges(self)

end

function config.Reset(self)

end

function config.RawSet(self)

end

function config.RawGet(self)

end

function config.saveChangesToServer(self)

end

local userConfig = {} :: UserConfigImpl
userConfig.__index = userConfig

function userConfig.new(configs)
	return config :: ConfigImpl<typeof(configs)>
end
