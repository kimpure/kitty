--!strict
type UserConfigImpl = {
    __index: UserConfigImpl,
    __call: (self: UserConfig) -> ({ [string]: any }),
    new: (settings: { [string]: any }) -> (UserConfig),
    saveChangesToServer: (self: UserConfig) -> (),
    onChanged: (self: UserConfig, fn: <T>(...T) -> ()) -> (),
}

export type UserConfig = typeof(setmetatable({} :: {
    _config: { [string]: any },
    packet: any --// net.packet
}, {} :: UserConfigImpl))

local namespace = Net.defineNamespace "userConfigNetworking"
local userconfig = {} :: UserConfigImpl
userconfig.__index = userconfig

function userconfig.__call(self)
    return self._config
end 

function userconfig.new(settings)
    return setmetatable({
        _config=settings,
        packet = namespace:createPacket(
            "client",
            Net.table(),
        )
    }, userconfig) 
end

function userconfig.saveChangesToServer(self)
    self.packet:sendToServer(self._config)
end

function userconfig.onChanged(self, fn)
    self.packet:onReceived:Connect(function(config)
        fn(config)
    end)
end 

return userconfig
